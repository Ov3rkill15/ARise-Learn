from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance
from app.core.config import get_settings


def get_qdrant_client() -> QdrantClient:
    settings = get_settings()
    client = QdrantClient(host=settings.qdrant_host, port=settings.qdrant_port)
    return client


def ensure_collection(client: QdrantClient) -> None:
    """Create the collection if it doesn't exist."""
    settings = get_settings()
    collections = [c.name for c in client.get_collections().collections]
    if settings.qdrant_collection not in collections:
        client.create_collection(
            collection_name=settings.qdrant_collection,
            vectors_config=VectorParams(size=384, distance=Distance.COSINE),
        )
