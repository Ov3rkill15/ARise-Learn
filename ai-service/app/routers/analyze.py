from fastapi import APIRouter, HTTPException
from app.models.schemas import AnalyzeRequest, AnalyzeResponse
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
        )
        return AnalyzeResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
