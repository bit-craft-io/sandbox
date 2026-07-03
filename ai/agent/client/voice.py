import os

import pygame
import requests
import speech_recognition as sr

BASE_URL = "http://localhost:8123"
USE_LLM = os.environ.get("USE_LLM", "false").lower() in ("true", "1", "yes")

def init_tts():
    """VOICEVOX移行につき本関数は不要。互換性のため残置。"""
    return None

def speak_text(engine, text):
    print(f"[Output Stream - Audio Playing] {text}")

    query = requests.post(
        "http://localhost:50021/audio_query",
        params={"text": text, "speaker": 1}
    ).json()

    audio = requests.post(
        "http://localhost:50021/synthesis",
        params={"speaker": 1},
        json=query
    )

    with open("/tmp/output.wav", "wb") as f:
        f.write(audio.content)

    pygame.mixer.init()
    pygame.mixer.music.load("/tmp/output.wav")
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy():
        pygame.time.Clock().tick(10)

def test_voice_input():
    # 1. 音声関連オブジェクトの初期化
    recognizer = sr.Recognizer()
    tts_engine = init_tts()

    print("\n================================================================================")
    speak_text(tts_engine, "Ready. Please start speaking after the prompt.")
    print("================================================================================\n")

    # 2. マイクから音声を入力（Speech-to-Text）
    user_text = ""
    with sr.Microphone() as source:
        print("[*] Adjusting for ambient noise... Please wait.")
        recognizer.adjust_for_ambient_noise(source, duration=1)
        print("[Input stream opened] Speak your payload now...")

        try:
            audio = recognizer.listen(source, timeout=5, phrase_time_limit=10)
            print("[*] Processing audio stream via Google STT...")
            # ここは英語環境なら language="en-US"、日本語なら "ja-JP" にしてな
            #user_text = recognizer.recognize_google(audio, language="ja-JP")
            user_text = "ファミコンの名作を教えて。あと、返信の文にアスタリスクとかの記号は不要"
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
        # 1. Fetch active assistant from LangGraph
        print("[*] 1/4: Searching for available assistant deployment...")

        search_payload = {
            "limit": 1,
            "config": {
                "graph_id": "voice"
            }
        }
        assistants_res = requests.post(f"{BASE_URL}/assistants/search", json=search_payload)
        assistants_res.raise_for_status()
        assistants_list = assistants_res.json()

        if not assistants_list:
            print("[-] Error: No active assistant found on the server.")
            return

        real_assistant_id = assistants_list[0]["assistant_id"]
        print(f"[+] Targeted Assistant ID: '{real_assistant_id}'")

        # 2. Initialize thread session
        print("[*] 2/4: Initializing sandboxed execution thread...")
        thread_res = requests.post(f"{BASE_URL}/threads", json={})
        thread_res.raise_for_status()
        thread_id = thread_res.json()["thread_id"]
        print(f"[+] Thread session established: {thread_id}")

        # 3. Trigger execution flow (Wait until END node)
        print("[*] 3/4: Triggering agent runtime flow and awaiting final state...")
        payload = {
            "assistant_id": real_assistant_id,
            "input": {
                "messages": [{"role": "user", "content": user_text}]
            },
            "config": {
                "configurable": {
                    "use_llm": USE_LLM
                }
            }
        }

        run_res = requests.post(f"{BASE_URL}/threads/{thread_id}/runs/wait", json=payload)
        if not run_res.ok:
            print(f"[-] Status: {run_res.status_code}")
            print(f"[-] Response body: {run_res.text}")  # Response内容
        run_res.raise_for_status()
        final_state = run_res.json()

        # 4. Parse payload state dynamically
        print("[*] 4/4: Resolving output message layers...")
        if "messages" in final_state:
            messages = final_state["messages"]
        else:
            messages = final_state.get("values", {}).get("messages", [])

        if messages:
            last_msg = messages[-1]
            agent_response = last_msg.get('content')

            print("\n================================================================================")
            # 5. エージェントの返答テキストを音声合成で再生する（Text-to-Speech）
            speak_text(tts_engine, agent_response)
            #speak_text(tts_engine, "疎通、OK")
            print("================================================================================\n")
        else:
            print("\n[-] Error: Payload extraction failed. Output stream is empty.")

    except requests.exceptions.ConnectionError:
        print(f"\n[-] Network Error: Failed to reach backend service at {BASE_URL}.")
    except Exception as e:
        print(f"\n[-] Runtime Exception: Unexpected failure occurred: {e}")

if __name__ == "__main__":
    test_voice_input()