from datetime import datetime, timedelta, timezone
from langchain_core.runnables import RunnableConfig
from langgraph.graph import StateGraph, MessagesState, START, END
from langchain_openai import ChatOpenAI

JST = timezone(timedelta(hours=+9))

def chatbot(state: MessagesState, config: RunnableConfig):
    print("=== CHATBOT NODE TRIGGERED ===", flush=True)

    use_llm = config.get("configurable", {}).get("use_llm", False)

    #print(f"[DEBUG] use_llm value: {use_llm} (type: {type(use_llm)})", flush=True)

    # if use_llm:
    #     # TODO: model 直打ち
    #     llm = ChatOpenAI(
    #         base_url="http://ollama-proxy:4000",
    #         api_key="dummy",
    #         model="gemma4:e2b",
    #         streaming=True
    #     )
    #     response = llm.invoke(state["messages"])
    #     return {"messages": [response]}

    if use_llm:
        print("[DEBUG] LLM Invoke Started...", flush=True)
        llm = ChatOpenAI(
            base_url="http://ollama-proxy:4000",
            api_key="dummy",
            model="gemma4:e2b",
            streaming=True
        )
        try:
            response = llm.invoke(state["messages"])
            print(f"[DEBUG] LLM Response Raw: {response}", flush=True)
            return {"messages": [response]}
        except Exception as e:
            print(f"[DEBUG] LLM Invoke FAILED: {str(e)}", flush=True)
            raise e

    current_time = datetime.now(JST).strftime("%Y/%m/%d %H:%M:%S")
    return {"messages": [{"role": "assistant", "content": f"Chat Health Check OK ({current_time})"}]}

graph = StateGraph(MessagesState)
graph.add_node("chatbot", chatbot)
graph.add_edge(START, "chatbot")
graph.add_edge("chatbot", END)
graph = graph.compile()
