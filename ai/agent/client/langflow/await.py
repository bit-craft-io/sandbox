# langflow logic
import asyncio
import os
import sys

import requests
import time

from utils.session_manager import SessionManager
from utils.input_write_timer import InputWriteTimer
from utils.input_speak_timer import InputSpeakTimer

BASE_URL = "http://localhost:7860"
API_KEY = os.environ.get("LANGFLOW_API_KEY", "")
# FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "sample")  # Endpoint Name
FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "chat")  # Endpoint Name
USE_LLM = os.environ.get("USE_LLM", "false").lower() in ("true", "1", "yes")

IS_MONITORING = True

session_mgr = SessionManager(timeout=60.0)


async def _monitor_agent_status(status_context: dict, interval_seconds: float = 5.0):
    """裏でn秒毎にAgentの状態を問い合わせ続けるバックグラウンドタスク"""
    try:
        while True:
            if status_context.get("is_monitoring", True):
                payload = _build_payload("", "")
                headers = _build_headers()
                final_state, elapsed_time = _call_flow_api(payload, headers, "state")

                #     try:
                #   message_text = final_state["outputs"][0]["outputs"][0]["results"]["message"]["text"]
                try:
                    message_text = final_state["outputs"][0]["outputs"][0]["outputs"]["message"]["message"]
                except (KeyError, IndexError):
                    message_text = None

                if message_text:
                    print(f"[Status]: {message_text}")
                else:
                    print("\n[-] Error: Payload extraction failed. Output stream is empty.")

            else:
                pass
            # 指定された秒数だけ非同期で待機（他の処理をブロックしない）
            await asyncio.sleep(interval_seconds)
    except asyncio.CancelledError:
        print("[Monitor] Status monitoring stopped.")


def _build_payload(user_text: str, session_id: str) -> dict:
    return {
        "input_value": user_text,
        "input_type": "chat",
        "output_type": "chat",
        "session_id": session_id,
    }


def _build_headers() -> dict:
    return {
        "Content-Type": "application/json",
        "x-api-key": API_KEY,
    }


def _call_flow_api(payload: dict, headers: dict, flow_id: str = FLOW_ID) -> tuple[dict | None, float]:
    """POST実行→(response_json, elapsed_time)。失敗時 response_json=None"""
    start_time = time.time()
    try:
        run_res = requests.post(
            f"{BASE_URL}/api/v1/run/{flow_id}?stream=false",
            json=payload,
            headers=headers,
        )
        elapsed_time = time.time() - start_time

        if not run_res.ok:
            print(f"[-] Status: {run_res.status_code}")
            print(f"[-] Response body: {run_res.text}")
        run_res.raise_for_status()
        return run_res.json(), elapsed_time

    except requests.exceptions.ConnectionError:
        print(f"\n[-] Network Error: Failed to reach backend service at {BASE_URL}.")
        return None, time.time() - start_time

    except Exception as e:
        print(f"\n[-] Runtime Exception: Unexpected failure occurred: {e}")
        return None, time.time() - start_time


def query_agent(user_text: str | None):
    if not user_text:
        print("Input is Empty.\n")
        return

    session_id = session_mgr.get_id()
    print(f"SESSION_ID: {session_id}")
    print(f"[DEBUG] use_llm value: {USE_LLM} (type: {type(USE_LLM)})", flush=True)
    print(f"[+] Session established: {session_id}")

    payload = _build_payload(user_text, session_id)
    headers = _build_headers()

    print("[*] Triggering flow runtime and awaiting response...")
    final_state, elapsed_time = _call_flow_api(payload, headers)

    if final_state is None:
        return

    print("\n--- [RAW BACKEND RESPONSE] ---")
    print(final_state)
    print("-------------------------------\n")
    print(f"[METRIC] execution_time={elapsed_time:.4f}s")

    print("[*] Resolving output message layers...")

    try:
        message_text = final_state["outputs"][0]["outputs"][0]["results"]["message"]["text"]
    except (KeyError, IndexError):
        return None

    if message_text:
        print("\n================================================================================")
        print(f"[Response]: {message_text}")
        print("================================================================================\n")
    else:
        print("\n[-] Error: Payload extraction failed. Output stream is empty.")


async def main():
    loop = asyncio.get_running_loop()
    fd = sys.stdin.fileno()

    status_context = {"is_monitoring": True}
    monitor_task = asyncio.create_task(_monitor_agent_status(status_context, interval_seconds=3.0))

    input_write = InputWriteTimer(timeout=20)
    input_speak = InputSpeakTimer(model_size="small", device="cpu", compute_type="int8")

    try:
        while True:
            print("Press Enter to start execution... (Ctrl+C to exit)\n", end="", flush=True)

            # Enter（改行）を検知するためのイベントを用意
            enter_pressed = asyncio.Event()

            # 🌟 sys.stdin にデータが入ってきたらイベントをセットする関数を登録
            loop.add_reader(fd, lambda: enter_pressed.set())

            try:
                # Enterが押されるのを待つ
                await enter_pressed.wait()
                status_context["is_monitoring"] = False
                # 押された分の入力バッファ（改行コードなど）をクリア
                sys.stdin.readline()
            finally:
                # 🌟 用が済んだら監視を解除（sys.stdin自体は閉じない！）
                loop.remove_reader(fd)

            # 実行
            # await test_string_input()

            user_text = await input_write.ask("[Request] Enter payload for agent : ")
            # TODO 20260709
            # await input_speak.ask("[Request] Enter payload for agent : ")
            query_agent(user_text)

            print()
            # 再開
            status_context["is_monitoring"] = True

    except (KeyboardInterrupt, asyncio.CancelledError):
        print("\n[+] Exited cleanly.")
    finally:
        # 🌟 アプリ終了時に裏のタスクも綺麗にキャンセルする
        monitor_task.cancel()
        await asyncio.gather(monitor_task, return_exceptions=True)
        print("[+] All tasks terminated.")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[+] Exited by user.")
