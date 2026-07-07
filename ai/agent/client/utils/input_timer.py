import asyncio
import time

from prompt_toolkit import PromptSession

class InputTimer:
    @classmethod
    async def ask(cls, prompt: str, timeout: float = 10.0) -> str | None:
        state = {"last_time": time.time(), "last_text": ""}

        session = PromptSession()

        def on_text_changed(buf):
            if buf.text != state["last_text"]:
                state["last_text"] = buf.text
                state["last_time"] = time.time()

        session.default_buffer.on_text_changed += on_text_changed

        async def watchdog():
            while True:
                await asyncio.sleep(0.1)
                elapsed = time.time() - state["last_time"]
                if elapsed >= timeout:
                    current_text = session.default_buffer.text.strip()
                    session.app.exit(result=current_text if current_text else "__TIMEOUT_EMPTY__")
                    break

        watchdog_task = asyncio.create_task(watchdog())

        try:
            result = await session.prompt_async(prompt)
            return None if result == "__TIMEOUT_EMPTY__" else result.strip()
        except (KeyboardInterrupt, Exception):
            return None
        finally:
            if not watchdog_task.done():
                watchdog_task.cancel()