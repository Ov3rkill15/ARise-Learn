from fastapi import APIRouter, HTTPException
from app.models.schemas import RAGQueryRequest, RAGQueryResponse
from app.services.rag_service import RAGService

router = APIRouter(prefix="/rag")

# Will be set during app startup
rag_service: RAGService | None = None


def init_router(service: RAGService):
    global rag_service
    rag_service = service


@router.post("/query", response_model=RAGQueryResponse)
async def query_rag(request: RAGQueryRequest):
    """Standalone RAG query: ask a question about academic material."""
    if rag_service is None:
        raise HTTPException(status_code=503, detail="RAG service not initialized")

    try:
        chunks = await rag_service.retrieve(request.query, top_k=request.top_k)
        if not chunks:
            return RAGQueryResponse(
                answer="No relevant academic material found in the knowledge base.",
                sources=[],
                confidence=0.0,
            )

        answer = await rag_service.generate_answer(request.query, chunks)
        sources = [c.get("payload", {}).get("source", "unknown") for c in chunks]

        return RAGQueryResponse(
            answer=answer,
            sources=list(set(sources)),
            confidence=0.85,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"RAG query failed: {str(e)}")
