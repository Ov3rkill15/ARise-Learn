from fastapi import APIRouter, HTTPException
from app.models.schemas import AnalyzeRequest, AnalyzeResponse, ChatRequest, ChatResponse
from app.services.rag_service import RAGService

router = APIRouter()

# Will be set during app startup
rag_service: RAGService | None = None


def init_router(service: RAGService):
    global rag_service
    rag_service = service


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_image(request: AnalyzeRequest):
    """Receive a scanned textbook image and return AI-generated explanation."""
    if rag_service is None:
        raise HTTPException(status_code=503, detail="AI service not initialized")

    try:
        result = await rag_service.analyze_image(
            image_url=request.image_url,
            context=request.context,
            language=request.language,
            image_base64=request.image_base64,
            mime_type=request.mime_type,
        )
        return AnalyzeResponse(**result)
    except Exception as e:
        import traceback
        print(f"\n=== ANALYZE ERROR ===")
        print(f"image_url: {request.image_url[:100]}..." if len(request.image_url) > 100 else f"image_url: {request.image_url}")
        print(f"context: {request.context}")
        traceback.print_exc()
        print(f"=== END ERROR ===\n")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@router.post("/chat", response_model=ChatResponse)
async def chat_scoped(request: ChatRequest):
    """Answer questions while strictly scoping the conversation to the scanned topic."""
    if rag_service is None:
        raise HTTPException(status_code=503, detail="AI service not initialized")

    try:
        reply = await rag_service.chat_scoped(
            topic=request.topic,
            message=request.message,
            history=request.history,
        )
        return ChatResponse(reply=reply)
    except Exception as e:
        import traceback
        print(f"\n=== CHAT ERROR ===")
        print(f"topic: {request.topic}")
        print(f"message: {request.message}")
        traceback.print_exc()
        print(f"=== END ERROR ===\n")
        raise HTTPException(status_code=500, detail=f"Chat failed: {str(e)}")
