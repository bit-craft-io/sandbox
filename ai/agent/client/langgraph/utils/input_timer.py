import asyncio
import time
from prompt_toolkit import PromptSession
from prompt_toolkit.formatted_text import HTML

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

                if timeout == 0:
                    # 🌟 timeout=0 の場合は無限待ち（カウントダウン表記を固定）
                    session.message = HTML(f"<style fg='ansiyellow'>[------]</style> {prompt}")
                else:
                    elapsed = time.time() - state["last_time"]
                    remaining = max(0.0, timeout - elapsed)
                    session.message = HTML(f"<style fg='ansiyellow'>[{remaining:>5.1f}s]</style> {prompt}")

                # 🌟 prompt_toolkit の画面を強制的に再描画させて、秒数表示を更新する裏技！
                if session.app:
                    session.app.invalidate()

                if elapsed >= timeout:
                    current_text = session.default_buffer.text.strip()
                    session.app.exit(result=current_text if current_text else "__TIMEOUT_EMPTY__")
                    break

        watchdog_task = asyncio.create_task(watchdog())

        try:
            #session.message = HTML(f"<style fg='ansiyellow'>[{timeout:>5.1f}s]</style> {prompt}")

            result = await session.prompt_async()
            return None if result == "__TIMEOUT_EMPTY__" else result.strip()
        except (KeyboardInterrupt, Exception):
            return None
        finally:
            if not watchdog_task.done():
                watchdog_task.cancel()