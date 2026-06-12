import ollama

class LLM:
    def __init__(self, model="gemma4:12b"):
        self.model = model

    def chat(self, context: str, query: str) -> str:
        response = ollama.chat(
            model=self.model,
            messages=[{
                "role": "user",
                "content": f"以下の情報を元に答えてください\n\n{context}\n\n質問: {query}"
            }]
        )
        return response['message']['content']