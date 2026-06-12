class Retriever:
    def __init__(self, client, collection: str, limit: int = 3):
        self.client = client
        self.collection = collection
        self.limit = limit

    def search(self, vector: list) -> str:
        results = self.client.query_points(
            collection_name=self.collection,
            query=vector,
            limit=self.limit,
        )
        return "\n".join([r.payload['text'] for r in results.points])