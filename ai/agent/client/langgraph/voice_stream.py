import json
import os
import re
import threading
import queue

import pygame
import requests
import speech_recognition as sr

from langflow.utils.suppress_stderr import SuppressStderr

BASE_URL = "http://localhost:8123"
USE_LLM = os.environ.get("USE_LLM", "false").lower() in ("true", "1", "yes")

if not pygame.mixer.get_init():
    try:
        with SuppressStderr():
            pygame.mixer.init()
    except pygame.error:
        print("[!] Audio device unavailable. Playback disabled.")

def init_tts():
    return None

def synthesize(text, speed=1.5):
    """音声生成のみ(再生しない、バイト列を返す)"""
    query = requests.post(
        "http://localhost:50021/audio_query",
        params={"text": text, "speaker": 1}
    ).json()
    query["speedScale"] = speed

    audio = requests.post(
        "http://localhost:50021/synthesis",
        params={"speaker": 1},
        json=query
    )
    return audio.content


def play_audio_bytes(audio_bytes):
    """再生のみ"""
    with open("/tmp/output.wav", "wb") as f:
        f.write(audio_bytes)
    pygame.mixer.music.load("/tmp/output.wav")
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy():
        pygame.time.Clock().tick(10)


def speak_text(engine, text):
    """従来通りの単発呼び出し用(互換性維持)"""
    if not text.strip():
        return

    print(f"[Output Stream - Audio Playing] {text}")
    play_audio_bytes(synthesize(text))


class SpeechPipeline:
    """文をキューに投げると、裏で生成しつつ順番に再生するパイプライン"""

    def __init__(self, speed=1.5):
        self.text_queue = queue.Queue()
        self.audio_queue = queue.Queue(maxsize=2)
        self.speed = speed
        self._producer_thread = threading.Thread(target=self._produce, daemon=True)
        self._producer_thread.start()

    def _produce(self):
        while True:
            text = self.text_queue.get()
            if text is None:  # 終了シグナル
                self.audio_queue.put(None)
                break
            print(f"[Synthesizing] {text}")
            audio_bytes = synthesize(text, self.speed)
            self.audio_queue.put(audio_bytes)

    def submit(self, text):
        """文が確定したら随時これを呼ぶ(ストリーム受信中に随時呼べる)"""
        if text.strip():
            self.text_queue.put(text)

    def finish_and_play_all(self):
        """入力終了を通知しつつ、生成され次第、再生をブロッキングで進める"""
        self.text_queue.put(None)
        while True:
            audio_bytes = self.audio_queue.get()
            if audio_bytes is None:
                break
            print("[Output Stream - Audio Playing]")
            play_audio_bytes(audio_bytes)

def run_and_speak_stream(thread_id, real_assistant_id, user_text, use_llm):
    payload = {
        "assistant_id": real_assistant_id,
        "input": {"messages": [{"role": "user", "content": user_text}]},
        "config": {"configurable": {"use_llm": use_llm}},
        "stream_mode": "messages-tuple",
    }

    pipeline = SpeechPipeline(speed=1.5)

    buffer = ""
    full_text = ""
    sentence_end_pattern = re.compile(r"[。！？\n]")

    with requests.post(
            f"{BASE_URL}/threads/{thread_id}/runs/stream",
            json=payload,
            stream=True,
    ) as r:
        r.raise_for_status()
        event_type = None
        for raw_line in r.iter_lines(decode_unicode=True):
            if not raw_line:
                event_type = None
                continue
            if raw_line.startswith("event:"):
                event_type = raw_line[len("event:"):].strip()
                continue
            if raw_line.startswith("data:"):
                data_str = raw_line[len("data:"):].strip()
                if not data_str:
                    continue

                if event_type != "messages":
                    continue

                try:
                    event = json.loads(data_str)
                except json.JSONDecodeError:
                    continue

                if isinstance(event, list) and len(event) >= 1:
                    chunk = event[0]
                    content = chunk.get("content", "") if isinstance(chunk, dict) else ""
                else:
                    content = ""

                if not content:
                    continue

                buffer += content
                full_text += content

                match = sentence_end_pattern.search(buffer)
                while match:
                    sentence = buffer[:match.end()]
                    buffer = buffer[match.end():]
                    pipeline.submit(sentence)
                    match = sentence_end_pattern.search(buffer)

    if buffer.strip():
        pipeline.submit(buffer)

    # ここでブロッキング再生開始(生成が終わってる分から順次再生される)
    pipeline.finish_and_play_all()

    return full_text

def test_voice_input():
    recognizer = sr.Recognizer()

    print("\n================================================================================")
    speak_text(None, "Ready. Please start speaking after the prompt.")
    print("================================================================================\n")

    user_text = ""
    with SuppressStderr():
        with sr.Microphone() as source:
            print("[*] Adjusting for ambient noise... Please wait.")
            recognizer.adjust_for_ambient_noise(source, duration=1)
            print("[Input stream opened] Speak your payload now...")

            try:
                audio = recognizer.listen(source, timeout=5, phrase_time_limit=10)
                print("[*] Processing audio stream via Google STT...")
                #user_text = "ファミコンの名作を教えて。あと、返信の文にアスタリスクとかの記号は不要"
                user_text = recognizer.recognize_google(audio, language="ja-JP")
                print(f"[Recognized Text Input]: {user_text}")
            except sr.WaitTimeoutError:
                print("[-] Error: Audio input timeout. No speech detected.")
                return
            except sr.UnknownValueError:
                print("[-] Error: Google STT could not understand the audio.")
                return
            except Exception as e:
                print(f"[-] Error during STT processing: {e}")
                return

    try:
        print("[*] 1/4: Searching for available assistant deployment...")
        search_payload = {"limit": 1, "config": {"graph_id": "voice"}}
        assistants_res = requests.post(f"{BASE_URL}/assistants/search", json=search_payload)
        assistants_res.raise_for_status()
        assistants_list = assistants_res.json()

        if not assistants_list:
            print("[-] Error: No active assistant found on the server.")
            return

        real_assistant_id = assistants_list[0]["assistant_id"]
        print(f"[+] Targeted Assistant ID: '{real_assistant_id}'")

        print("[*] 2/4: Initializing sandboxed execution thread...")
        thread_res = requests.post(f"{BASE_URL}/threads", json={})
        thread_res.raise_for_status()
        thread_id = thread_res.json()["thread_id"]
        print(f"[+] Thread session established: {thread_id}")

        print("[*] 3/4: Streaming agent runtime flow, speaking sentence by sentence...")
        print("\n================================================================================")
        with SuppressStderr():
            full_response = run_and_speak_stream(thread_id, real_assistant_id, user_text, USE_LLM)
        print("================================================================================\n")

        print("[*] 4/4: Done.")
        print(f"[Full Response]: {full_response}")

    except requests.exceptions.ConnectionError:
        print(f"\n[-] Network Error: Failed to reach backend service at {BASE_URL}.")
    except Exception as e:
        print(f"\n[-] Runtime Exception: Unexpected failure occurred: {e}")

if __name__ == "__main__":
    test_voice_input()