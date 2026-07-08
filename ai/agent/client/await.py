# langflow logic
import asyncio
import os
import sys

import requests
import time
import uuid
from utils.input_timer import InputTimer

BASE_URL = "http://localhost:7860"
API_KEY = os.environ.get("LANGFLOW_API_KEY", "")
# FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "sample")  # Endpoint Name
FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "chat")  # Endpoint Name
# FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "state")  # Endpoint Name
USE_LLM = os.environ.get("USE_LLM", "false").lower() in ("true", "1", "yes")

IS_MONITORING = True

async def monitor_agent_status(status_context: dict, interval_seconds: float = 5.0):
    """裏でn秒毎にAgentの状態を問い合わせ続けるバックグラウンドタスク"""
    try:
        while True:
            if status_context.get("is_monitoring", True):
                session_id = str(uuid.uuid4())  # thread_idに相当。会話継続したい場合は固定値で使い回す
                payload = {
                    "input_value": "",
                    "input_type": "chat",
                    "output_type": "chat",
                    "session_id": "",
                }
                headers = {
                    "Content-Type": "application/json",
                    "x-api-key": API_KEY,
                }
                # TODO
                FLOW_ID = "state"
                run_res = requests.post(
                    f"{BASE_URL}/api/v1/run/{FLOW_ID}?stream=false",
                    json=payload,
                    headers=headers,
                )
                if not run_res.ok:
                    print(f"[-] Status: {run_res.status_code}")
                    print(f"[-] Response body: {run_res.text}")
                run_res.raise_for_status()
                final_state = run_res.json()

                try:
                    message_text = final_state["outputs"][0]["outputs"][0]["outputs"]["message"]["message"]
                except (KeyError, IndexError):
                    message_text = None

                if message_text:
                    print(f"[Status]: {message_text}")
                else:
                    print("\n[-] Error: Payload extraction failed. Output stream is empty.")

                # 🌟 ここで Agent の状態を取得するリクエストを送る
                # res = requests.get(f"{BASE_URL}/api/v1/status/...")
                # print(f"\n[Monitor] Fetching agent status... (every {interval_seconds}s)")
            else:
                pass
            # 指定された秒数だけ非同期で待機（他の処理をブロックしない）
            await asyncio.sleep(interval_seconds)
    except asyncio.CancelledError:
        print("[Monitor] Status monitoring stopped.")


async def test_string_input():
    print("\n================================================================================")
    user_text = await InputTimer.ask("[Request] Enter payload for agent : ", timeout=20)
    print("================================================================================\n")

    if user_text == "":
        print("Input is Empty.\n")
        return

    try:
        # 1. Trigger execution flow (LangGraphのassistant検索+thread作成+runは不要、1回のPOSTで完結)
        print("[*] Triggering flow runtime and awaiting response...")

        session_id = str(uuid.uuid4())  # thread_idに相当。会話継続したい場合は固定値で使い回す

        payload = {
            "input_value": user_text,
            "input_type": "chat",
            "output_type": "chat",
            "session_id": session_id,
        }
        headers = {
            "Content-Type": "application/json",
            "x-api-key": API_KEY,
        }

        print(f"[DEBUG] use_llm value: {USE_LLM} (type: {type(USE_LLM)})", flush=True)
        print(f"[+] Session established: {session_id}")

        start_time = time.time()

        run_res = requests.post(
            f"{BASE_URL}/api/v1/run/{FLOW_ID}?stream=false",
            json=payload,
            headers=headers,
        )

        end_time = time.time()
        elapsed_time = end_time - start_time

        if not run_res.ok:
            print(f"[-] Status: {run_res.status_code}")
            print(f"[-] Response body: {run_res.text}")
        run_res.raise_for_status()
        final_state = run_res.json()

        print("\n--- [RAW BACKEND RESPONSE] ---")
        print(final_state)
        print("-------------------------------\n")

        print(f"[METRIC] execution_time={elapsed_time:.4f}s")

        # 2. Parse output (LangFlow独自のレスポンス構造)
        print("[*] Resolving output message layers...")
        try:
            outputs = final_state["outputs"][0]["outputs"][0]
            message_text = outputs["results"]["message"]["text"]
        except (KeyError, IndexError):
            message_text = None

        if message_text:
            print("\n================================================================================")
            print(f"[Response]: {message_text}")
            print("================================================================================\n")
        else:
            print("\n[-] Error: Payload extraction failed. Output stream is empty.")

    except requests.exceptions.ConnectionError:
        print(f"\n[-] Network Error: Failed to reach backend service at {BASE_URL}.")
    except Exception as e:
        print(f"\n[-] Runtime Exception: Unexpected failure occurred: {e}")


# async def main():
#     try:
#         while True:
#             print("\nPress Enter to start execution... (Ctrl+C to exit)")
#             # Enter入力を待ち受け
#             #await asyncio.to_thread(input)
#             await InputTimer.ask("", timeout=0)
#             # 実行
#             await test_string_input()
#     except (KeyboardInterrupt, Exception):
#         return None
async def main():
    loop = asyncio.get_running_loop()
    fd = sys.stdin.fileno()

    status_context = {"is_monitoring": True}
    monitor_task = asyncio.create_task(monitor_agent_status(status_context, interval_seconds=3.0))

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
            await test_string_input()
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
