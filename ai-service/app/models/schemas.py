from pydantic import BaseModel, Field
from typing import Optional


class AnalyzeRequest(BaseModel):
    image_url: str = Field(..., description="URL or base64 of the scanned textbook image")
    image_base64: Optional[str] = Field(None, description="Base64-encoded image data (avoids URL reachability issues)")
    mime_type: Optional[str] = Field(None, description="MIME type of the base64 image, e.g. image/jpeg")
    context: Optional[str] = Field(None, description="Optional subject/course context")
    language: Optional[str] = Field("id", description="Language of explanation: 'id' or 'en'")


class Recommendation(BaseModel):
    title: str
    description: str
    relevance: str = "Relevan"  # "Sangat Relevan" | "Relevan"
    icon_hint: str = "book"  # icon hint for Flutter UI


class AnalyzeResponse(BaseModel):
    explanation: str
    subject_topic: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    asset_3d_hint: Optional[str] = None
    recommendations: list[Recommendation] = []


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


class ChatRequest(BaseModel):
    topic: str
    message: str
    history: Optional[list[dict]] = None


class ChatResponse(BaseModel):
    reply: str
