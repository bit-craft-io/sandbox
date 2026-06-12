# ui.py
from prompt_toolkit import prompt
from prompt_toolkit.history import FileHistory
from rich.console import Console

class UI:
    console = Console()

    @staticmethod
    def input(message="Q: ") -> str:
        return prompt(message, history=FileHistory("../.history"))

    @staticmethod
    def status(message: str):
        return UI.console.status(message, spinner="dots2")