from pydantic import BaseModel, Field
from typing import Optional


class AnalyzeRequest(BaseModel):
    image_url: str = Field(..., description="URL or base64 of the scanned textbook image")
    context: Optional[str] = Field(None, description="Optional subject/course context")


class AnalyzeResponse(BaseModel):
    explanation: str
    subject_topic: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    asset_3d_hint: Optional[str] = None


class RAGQueryRequest(BaseModel):
    query: str = Field(..., description="Natural language query about academic material")
    top_k: int = Field(5, ge=1, le=20)


class RAGQueryResponse(BaseModel):
    answer: str
    sources: list[str] = []
    confidence: float = Field(..., ge=0.0, le=1.0)


class HealthResponse(BaseModel):
    status: str = "ok"
    service: str = "edutech-ai-service"
    llm_provider: str
    qdrant_connected: bool
