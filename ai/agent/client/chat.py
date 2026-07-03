import os
import requests

BASE_URL = "http://localhost:8123"
USE_LLM = os.environ.get("USE_LLM", "false").lower() in ("true", "1", "yes")

def test_string_input():
    print("\n================================================================================")
    user_text = input("[Request] Enter payload for agent : ") or "is test."
    print("================================================================================\n")

    try:
        # 1. Fetch active assistant from LangGraph
        print("[*] 1/4: Searching for available assistant deployment...")

        search_payload = {
            "limit": 1,
            "config": {
                "graph_id": "chat"
            }
        }
        assistants_res = requests.post(f"{BASE_URL}/assistants/search", json=search_payload)
        assistants_res.raise_for_status()
        assistants_list = assistants_res.json()

        if not assistants_list:
            print("[-] Error: No active assistant found on the server.")
            return

        real_assistant_id = assistants_list[0]["assistant_id"]
        print(f"[+] Targeted Assistant ID: '{real_assistant_id}'")

        # 2. Initialize thread session
        print("[*] 2/4: Initializing sandboxed execution thread...")
        thread_res = requests.post(f"{BASE_URL}/threads", json={})
        thread_res.raise_for_status()
        thread_id = thread_res.json()["thread_id"]
        print(f"[+] Thread session established: {thread_id}")

        print(f"[DEBUG] use_llm value: {USE_LLM} (type: {type(USE_LLM)})", flush=True)

        # 3. Trigger execution flow (Wait until END node)
        print("[*] 3/4: Triggering agent runtime flow and awaiting final state...")
        payload = {
            "assistant_id": real_assistant_id,
            "input": {
                "messages": [{"role": "user", "content": user_text}]
            },
            "config": {
                "configurable": {
                    "use_llm": USE_LLM
                }
            }
        }

        run_res = requests.post(f"{BASE_URL}/threads/{thread_id}/runs/wait", json=payload)
        if not run_res.ok:
            print(f"[-] Status: {run_res.status_code}")
            print(f"[-] Response body: {run_res.text}")  # Response内容
        run_res.raise_for_status()
        final_state = run_res.json()

        print("\n--- [RAW BACKEND RESPONSE] ---")
        print(final_state)
        print("-------------------------------\n")

        # 4. Parse payload state dynamically
        print("[*] 4/4: Resolving output message layers...")
        if "messages" in final_state:
            messages = final_state["messages"]
        else:
            messages = final_state.get("values", {}).get("messages", [])

        if messages:
            last_msg = messages[-1]
            print("\n================================================================================")
            print(f"[Response]: {last_msg.get('content')}")
            print("================================================================================\n")
        else:
            print("\n[-] Error: Payload extraction failed. Output stream is empty.")

    except requests.exceptions.ConnectionError:
        print(f"\n[-] Network Error: Failed to reach backend service at {BASE_URL}.")
    except Exception as e:
        print(f"\n[-] Runtime Exception: Unexpected failure occurred: {e}")

if __name__ == "__main__":
    test_string_input()