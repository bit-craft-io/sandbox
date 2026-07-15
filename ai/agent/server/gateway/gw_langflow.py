"""
gw_langflow.py
Unity <-> LangFlow 中継用 FastAPIサーバー
守破離の「守」段階: 最小構成で疎通確認を優先する
"""

import asyncio
import base64
import os
import time

import requests
from contextlib import asynccontextmanager

from fastapi import FastAPI
from pydantic import BaseModel

from utils.session_manager import SessionManager
# from utils.voicevox.output_speak import OutputSpeak  # 音声合成部分は仕様未確定のため一旦保留

# ------------------------------------------------------------
# 設定
# ------------------------------------------------------------
BASE_URL = "http://localhost:7860"
API_KEY = os.environ.get("LANGFLOW_API_KEY", "")
FLOW_ID = os.environ.get("LANGFLOW_FLOW_ID", "chat")
SESSION_TIMEOUT_SEC = 180.0  # 3分で揮発

VOICEVOX_URL = "http://localhost:50021"
VOICEVOX_SPEAKER_ID = int(os.environ.get("VOICEVOX_SPEAKER_ID", "1"))  # デフォルト話者

# ------------------------------------------------------------
# グローバル状態
# ------------------------------------------------------------
session_mgr = SessionManager(timeout=SESSION_TIMEOUT_SEC)

# GET /agent/status 用の最新状態キャッシュ
# _monitor_agent_status が裏で更新し続ける
latest_status: dict = {
    "message": None,
    "updated_at": None,
}

monitor_task: asyncio.Task | None = None


# ------------------------------------------------------------
# リクエスト/レスポンス スキーマ
# ------------------------------------------------------------
class QueryRequest(BaseModel):
    text: str
    session_id: str = ""  # 初回は空文字で送る想定


class QueryResponse(BaseModel):
    message: str | None
    session_id: str
    elapsed: float
    audio_base64: str | None = None  # wav base64、合成失敗時null


# ------------------------------------------------------------
# LangFlow 呼び出し (langflow_agent.py から移植)
# ------------------------------------------------------------
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
        print(f"[-] Network Error: Failed to reach backend service at {BASE_URL}.")
        return None, time.time() - start_time

    except Exception as e:
        print(f"[-] Runtime Exception: Unexpected failure occurred: {e}")
        return None, time.time() - start_time


def _synthesize_voicevox(text: str, speaker: int = VOICEVOX_SPEAKER_ID) -> bytes | None:
    """VOICEVOX標準エンジンAPI(audio_query→synthesis)でwavバイナリ生成"""
    if not text:
        return None
    try:
        query_res = requests.post(
            f"{VOICEVOX_URL}/audio_query",
            params={"text": text, "speaker": speaker},
        )
        query_res.raise_for_status()
        audio_query = query_res.json()

        synth_res = requests.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": speaker},
            json=audio_query,
        )
        synth_res.raise_for_status()
        return synth_res.content  # wavバイナリ

    except requests.exceptions.ConnectionError:
        print(f"[-] Network Error: Failed to reach VOICEVOX engine at {VOICEVOX_URL}.")
        return None

    except Exception as e:
        print(f"[-] VOICEVOX synthesis failed: {e}")
        return None


def _resolve_session_id(session_id: str) -> str:
    """
    SessionManagerはkey別に last_access を見て timeout超なら再発行する設計。
    現状はUnityクライアント1台想定のため固定key("default")で運用。
    (将来 room_id を導入する場合はここをroom_idに差し替えればよい)
    """
    return session_mgr.get_id("default")


# ------------------------------------------------------------
# 裏で回すstamina/state監視タスク (langflow_agent.py _monitor_agent_status 移植)
# ------------------------------------------------------------
async def _monitor_agent_status(interval_seconds: float = 5.0):
    try:
        while True:
            payload = _build_payload("", "")
            headers = _build_headers()
            final_state, _ = await asyncio.get_running_loop().run_in_executor(
                None, _call_flow_api, payload, headers, FLOW_ID
            )

            message_text = None
            if final_state:
                try:
                    message_text = final_state["outputs"][0]["outputs"][0]["outputs"]["message"]["message"]
                except (KeyError, IndexError):
                    message_text = None

            latest_status["message"] = message_text
            latest_status["updated_at"] = time.time()

            await asyncio.sleep(interval_seconds)
    except asyncio.CancelledError:
        print("[Monitor] Status monitoring stopped.")


# ------------------------------------------------------------
# FastAPI ライフサイクル (lifespan方式)
# ------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    global monitor_task
    # startup
    monitor_task = asyncio.create_task(_monitor_agent_status(interval_seconds=3.0))
    yield
    # shutdown
    if monitor_task:
        monitor_task.cancel()
        await asyncio.gather(monitor_task, return_exceptions=True)


app = FastAPI(lifespan=lifespan)


# ------------------------------------------------------------
# エンドポイント
# ------------------------------------------------------------
@app.get("/agent/status")
async def get_status():
    """裏の監視タスクが取得した最新stamina/stateをそのまま返す (polling用)"""
    return latest_status


@app.post("/agent/query", response_model=QueryResponse)
async def query_agent(req: QueryRequest):
    session_id = _resolve_session_id(req.session_id)

    payload = _build_payload(req.text, session_id)
    headers = _build_headers()

    final_state, elapsed_time = await asyncio.get_running_loop().run_in_executor(
        None, _call_flow_api, payload, headers, FLOW_ID
    )

    message_text = None
    if final_state:
        try:
            message_text = final_state["outputs"][0]["outputs"][0]["results"]["message"]["text"]
        except (KeyError, IndexError):
            message_text = None

    audio_bytes = await asyncio.get_running_loop().run_in_executor(
        None, _synthesize_voicevox, message_text
    )
    audio_base64 = base64.b64encode(audio_bytes).decode("ascii") if audio_bytes else None

    return QueryResponse(
        message=message_text,
        session_id=session_id,
        elapsed=elapsed_time,
        audio_base64=audio_base64,
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
