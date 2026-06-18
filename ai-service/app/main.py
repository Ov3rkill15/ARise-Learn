from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.config import get_settings
from app.services.llm_client import create_llm_client
from app.services.rag_service import RAGService
from app.routers import analyze, rag
from app.models.schemas import HealthResponse


def _init_qdrant():
    """Try to connect to Qdrant, fall back to in-memory mode."""
    from app.core.qdrant_client import get_qdrant_client, ensure_collection
    try:
        client = get_qdrant_client()
        client.get_collections()
        ensure_collection(client)
        print("Qdrant connected successfully.")
        return client, True
    except Exception as e:
        print(f"Qdrant not available ({e}). Using in-memory fallback.")
        from qdrant_client import QdrantClient
        return QdrantClient(location=":memory:"), False


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: initialize services."""
    settings = get_settings()

    # Initialize LLM client
    llm_client = create_llm_client()

    # Initialize Qdrant (with fallback)
    qdrant_client, qdrant_connected = _init_qdrant()

    # Initialize RAG service
    rag_svc = RAGService(qdrant_client=qdrant_client, llm_client=llm_client)

    # Wire up routers
    analyze.init_router(rag_svc)
    rag.init_router(rag_svc)

    app.state.llm_provider = settings.llm_provider
    app.state.qdrant_connected = qdrant_connected

    print(f"AI Service ready | LLM={settings.llm_provider} | Qdrant={'connected' if qdrant_connected else 'in-memory'}")
    yield


app = FastAPI(
    title="Edutech AI Service",
    description="Gen-AI powered RAG service for academic content analysis",
    version="0.1.0",
    lifespan=lifespan,
)

# Include routers
app.include_router(analyze.router, prefix="/api/v1", tags=["analyze"])
app.include_router(rag.router, prefix="/api/v1", tags=["rag"])


@app.get("/api/v1/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    return HealthResponse(
        status="ok",
        service="edutech-ai-service",
        llm_provider=app.state.llm_provider,
        qdrant_connected=app.state.qdrant_connected,
    )
from contextlib import asynccontextmanager
