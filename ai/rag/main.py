import sys
from sub.ui import UI
from sub.embedder import Embedder
from sub.retriever import Retriever
from sub.llm import LLM
from sub.qdrant import Qdrant

embedder = Embedder()
retriever = Retriever(client=Qdrant.client(), collection="nintendo")
llm = LLM()

print("* To exit, type '/q' or press 'Ctrl + C'")

try:
    while True:
        query = UI.input("質問: ")
        if query == "/q":
            print("Exiting...")
            break

        with UI.status("Searching Qdrant..."):
            vector = embedder.encode(query)
            context = retriever.search(vector)

        with UI.status("LLM inference..."):
            answer = llm.chat(context, query)

        print(f"\n回答: {answer}\n")

except KeyboardInterrupt:
    print("\nExiting due to Ctrl + C.")
    sys.exit(0)