# from pydantic_settings import BaseSettings
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

# config.py から見た .env の場所を指定
# config.py が src/ にあり、.env が bridge/ 直下にある場合:
ENV_FILE_PATH = Path(__file__).resolve().parent.parent / ".env"

class Settings(BaseSettings):
    voicevox_url: str = "http://localhost:9999"
    langflow_base_url: str = "http://localhost:9999"
    langflow_api_key: str = ""
    langflow_flow_id: str = "chat"
    langflow_state_flow_id: str = "state"
    langflow_timeout_sec: int = 30
    websocket_port: int = 8765

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
