import asyncio
import sys
from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client
from mcp.server.stdio import stdio_server
from mcp.server import Server

REMOTE_URL = "http://localhost/mcp/app"

def log(msg):
    print(msg, file=sys.stderr, flush=True)

try:
    async def main():
        log("Starting...")
        log(f"Connecting to remote: {REMOTE_URL}")

        async with streamable_http_client(REMOTE_URL) as (r, w, _):
            async with ClientSession(r, w) as remote_session:
                await remote_session.initialize()
                log("Remote connection established")

                tools = await remote_session.list_tools()
                log(f"Tools loaded: {len(tools.tools)}")

                server = Server("mcp-proxy")

                @server.list_tools()
                async def list_tools():
                    log("list_tools called")
                    return tools.tools

                @server.call_tool()
                async def call_tool(name: str, arguments: dict):
                    log(f"call_tool: {name} args={arguments}")
                    result = await remote_session.call_tool(name, arguments)
                    log(f"call_tool done: {name}")
                    return result.content

                log("Listening on STDIO...")
                async with stdio_server() as (sr, sw):
                    await server.run(sr, sw, server.create_initialization_options())

    if __name__ == "__main__":
        asyncio.run(main())

except KeyboardInterrupt:
    print("\nExiting due to Ctrl + C.")
    sys.exit(0)