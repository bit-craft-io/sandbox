import os
import subprocess
from pathlib import Path
# @note rich cui
from InquirerPy import inquirer

def exec_client():
    env = os.environ.copy()

    check = inquirer.select(
        message="health check",
        choices=[
            "y) yes",
            "n) no",
        ]
    ).execute()
    env["USE_LLM"] = "false" if check.startswith("y") else "true"

    mode = inquirer.select(
        message="chat or voice",
        choices=[
            "c) chat",
            "v) voice",
        ]
    ).execute()
    script = "chat.py" if mode.startswith("c") else "voice_stream.py"

    subprocess.run(
        ["python3", script],
        cwd=Path(__file__).parent,
        env=env
    )
    return None

if __name__ == "__main__":
    exec_client()
