from langchain_text_splitters import RecursiveCharacterTextSplitter
from qdrant_client.models import Distance, VectorParams, PointStruct
from sub.ui import UI
from sub.embedder import Embedder
from sub.qdrant import Qdrant
from sub.scraper import Scraper

class Ingestor:
    def __init__(self, collection: str):
        self.collection = collection
        self.embedder = Embedder()
        self.client = Qdrant.client()
        self.splitter = RecursiveCharacterTextSplitter(
            chunk_size=200,
            chunk_overlap=20,
            separators=["。", "\n", "、", ""]
        )

    def run(self, text: str):
        with UI.status("Splitting text into chunks..."):
            chunks = self.splitter.split_text(text)
        print(f"Chunks: {len(chunks)}")

        with UI.status("Creating Qdrant collection..."):
            vector_size = self.embedder.model.get_embedding_dimension()
            self.client.delete_collection(self.collection)
            self.client.create_collection(
                collection_name=self.collection,
                vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
            )

        with UI.status("Embedding chunks..."):
            embeddings = self.embedder.model.encode(chunks)
            points = [
                PointStruct(id=i, vector=embeddings[i].tolist(), payload={"text": chunks[i]})
                for i in range(len(chunks))
            ]
        print(f"Embedded: {len(points)} points")
        
        with UI.status("Saving to Qdrant..."):
            self.client.upsert(collection_name=self.collection, points=points)

        print("Done.")

if __name__ == "__main__":
    url = "https://ja.wikipedia.org/wiki/nintendo"
    with UI.status("Scraper fetch..."):
        text = Scraper(url).fetch(selector="mw-content-text")
    Ingestor(collection="nintendo").run(text)
