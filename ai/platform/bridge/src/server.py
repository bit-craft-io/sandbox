import asyncio
import json
import websockets
import time
import requests
import jmespath
from functools import partial

from utils.session_manager import SessionManager
from config import settings

LANGFLOW_BASE_URL = settings.langflow_base_url
LANGFLOW_API_KEY = settings.langflow_api_key
LANGFLOW_FLOW_ID = settings.langflow_flow_id
LANGFLOW_STATE_FLOW_ID = settings.langflow_state_flow_id
LANGFLOW_TIMEOUT_SEC = settings.langflow_timeout_sec
WEBSOCKET_PORT = settings.websocket_port

def _build_payload(user_text: str, session_id: str) -> dict:
    return {
        "input_value": user_text,
        "input_type": "chat",
        "output_type": "chat",
        "session_id": session_id,
    }

def _build_headers() -> dict:
    headers = {"Content-Type": "application/json"}
    if LANGFLOW_API_KEY:
        headers["x-api-key"] = LANGFLOW_API_KEY
    return headers

def _call_flow_api(payload: dict, headers: dict, flow_id: str = LANGFLOW_FLOW_ID) -> tuple[dict | None, float]:
    start_time = time.time()
    try:
        run_res = requests.post(
            f"{LANGFLOW_BASE_URL}/api/v1/run/{flow_id}?stream=false",
            json=payload,
            headers=headers,
            timeout=LANGFLOW_TIMEOUT_SEC,
        )
        elapsed_time = time.time() - start_time

        if not run_res.ok:
            print(f"[-] Status: {run_res.status_code}")
            print(f"[-] Response body: {run_res.text}")
        run_res.raise_for_status()
        return run_res.json(), elapsed_time

    except requests.exceptions.ConnectionError:
        print(f"[-] Network Error: Failed to reach backend service at {LANGFLOW_BASE_URL}.")
        return None, time.time() - start_time

    except Exception as e:
        print(f"[-] Runtime Exception: Unexpected failure occurred: {e}")
        return None, time.time() - start_time

def _extract_message(final_state: dict) -> str | None:
    paths = [
        "outputs[0].outputs[0].results.message.text",
        "outputs[0].outputs[0].outputs.message.message",
    ]
    for path in paths:
        value = jmespath.search(path, final_state)
        if value is not None:
            return value
    return None

def _monitor_agent_status(status_context: dict) -> str | None:
    if not status_context.get("is_monitoring", True):
        return None

    try:
        payload = _build_payload("", "")
        headers = _build_headers()
        final_state, _ = _call_flow_api(payload, headers, LANGFLOW_STATE_FLOW_ID)

        message_text = _extract_message(final_state) if final_state else None
        if not message_text:
            print("\n[-] Error: Payload extraction failed. Output stream is empty.")

        return message_text
    except Exception as e:
        print(f"[-] Error in _monitor_agent_status: {e}")
        return None

class LangflowWSServer:
    def __init__(self, host: str = "0.0.0.0", port: int = WEBSOCKET_PORT):
        self.host = host
        self.port = port
        self.session_mgr = SessionManager(timeout=60.0)
        # 接続中の全クライアントを管理するセットを追加
        self.clients = set()

    async def handler(self, websocket):
        session_id = self.session_mgr.get_id()
        # 接続されたクライアントを登録
        self.clients.add(websocket)
        print(f"[+] Client connected. Session ID: {session_id}")

        try:
            async for message in websocket:
                print(f"[Client -> WS]: {message}")

                loop = asyncio.get_running_loop()
                payload = _build_payload(message, session_id)
                headers = _build_headers()

                final_state, elapsed_time = await loop.run_in_executor(
                    None,
                    partial(_call_flow_api, payload, headers, LANGFLOW_FLOW_ID),
                )

                if final_state:
                    message_text = _extract_message(final_state)
                    res_data = {
                        "status": "success",
                        "response": message_text or "No text message",
                        "elapsed_time": elapsed_time
                    }
                else:
                    res_data = {"status": "error", "message": "Flow execution failed"}

                await websocket.send(json.dumps(res_data, ensure_ascii=False))

        except websockets.exceptions.ConnectionClosedError:
            print("[-] Client disconnected unexpectedly.")
        finally:
            # 切断されたらセットから削除
            self.clients.discard(websocket)
            print(f"[+] Session terminated: {session_id}")

    async def push_loop(self, status_context: dict, interval_seconds: float = 5.0):
        while True:
            # _call_flow_api が同期関数(requests)なので、別スレッドで実行するとブロックしない
            loop = asyncio.get_running_loop()
            message_text = await loop.run_in_executor(
                None, _monitor_agent_status, status_context
            )

            if message_text:
                # print(f"[Status]: {message_text}")

                # message_text が JSON 文字列の場合は辞書に変換する
                try:
                    parsed_message = json.loads(message_text)
                except (json.JSONDecodeError, TypeError):
                    parsed_message = message_text

                data = {
                    "type": "periodic_update",
                    "message": parsed_message
                }

                if self.clients:
                    json_message = json.dumps(data, ensure_ascii=False)
                    websockets.broadcast(self.clients, json_message)
                    # print(f"[Push] Sent status to Unity: {json_message}")

            await asyncio.sleep(interval_seconds)

    async def start(self):
        # push_loop をバックグラウンドタスクとして起動
        status_context = {"is_monitoring": True}
        asyncio.create_task(self.push_loop(status_context, interval_seconds=5.0))

        async with websockets.serve(
                self.handler,
                self.host,
                self.port,
                ping_interval=20,
                ping_timeout=20
        ):
            print(f"[+] WebSocket Server running on ws://{self.host}:{self.port}")
            # 永久ループ
            await asyncio.Future()

if __name__ == "__main__":
    server = LangflowWSServer(host="0.0.0.0", port=WEBSOCKET_PORT)
    try:
        asyncio.run(server.start())
    except KeyboardInterrupt:
        print("\n[+] Exited by user.")