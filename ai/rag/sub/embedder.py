from sentence_transformers import SentenceTransformer

class Embedder:
    def __init__(self, model_name="intfloat/multilingual-e5-large"):
        self.model = SentenceTransformer(model_name)

    def encode(self, text: str) -> list:
        return self.model.encode(text).tolist()