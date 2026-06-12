from qdrant_client import QdrantClient

class Qdrant:
    @staticmethod
    def client() -> QdrantClient | None:
        try:
            c = QdrantClient(host="localhost", port=6333)
            c.get_collections()
            return c
        except Exception:
            return None
