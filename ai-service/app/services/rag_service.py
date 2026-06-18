"""RAG pipeline using LangChain + Qdrant for academic content retrieval."""

import uuid
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
from app.core.config import get_settings
from app.services.llm_client import BaseLLMClient

# Optional heavy imports — only needed for real embeddings
try:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    from langchain_community.embeddings import HuggingFaceEmbeddings
    _HAS_LANGCHAIN = True
except ImportError:
    _HAS_LANGCHAIN = False


class RAGService:
    """Retrieval-Augmented Generation service for academic textbook content."""

    def __init__(self, qdrant_client: QdrantClient, llm_client: BaseLLMClient):
        self.qdrant = qdrant_client
        self.llm = llm_client
        self.settings = get_settings()
        self.has_embeddings = False

        if _HAS_LANGCHAIN:
            try:
                self.embeddings = HuggingFaceEmbeddings(model_name=self.settings.embedding_model)
                self.text_splitter = RecursiveCharacterTextSplitter(
                    chunk_size=500,
                    chunk_overlap=50,
                    separators=["\n\n", "\n", ". ", " "],
                )
                self.has_embeddings = True
            except Exception:
                pass

    async def ingest_document(self, document_text: str, metadata: dict) -> int:
        """Split and embed a document into Qdrant. Returns number of chunks stored."""
        if not self.has_embeddings:
            raise RuntimeError("LangChain/embeddings not available. Install langchain and sentence-transformers.")

        chunks = self.text_splitter.split_text(document_text)
        vectors = self.embeddings.embed_documents(chunks)
        collection = self.settings.qdrant_collection

        points = []
        for i, (chunk, vector) in enumerate(zip(chunks, vectors)):
            points.append(PointStruct(
                id=str(uuid.uuid4()),
                vector=vector,
                payload={
                    "text": chunk,
                    "chunk_index": i,
                    **metadata,
                },
            ))

        self.qdrant.upsert(collection_name=collection, points=points)
        return len(points)

    async def retrieve(self, query: str, top_k: int = 5) -> list[dict]:
        """Retrieve the most relevant chunks for a query."""
        if not self.has_embeddings:
            return []

        query_vector = self.embeddings.embed_query(query)
        collection = self.settings.qdrant_collection

        results = self.qdrant.search(
            collection_name=collection,
            query_vector=query_vector,
            limit=top_k,
        )

        return [
            {"text": r.payload.get("text", ""), "score": r.score, "payload": r.payload}
            for r in results
        ]

    async def generate_answer(self, query: str, context_chunks: list[dict]) -> str:
        """Generate an answer using retrieved context + LLM."""
        context_text = "\n\n".join(
            [f"[Source {i+1}]: {c['text']}" for i, c in enumerate(context_chunks)]
        )

        prompt = (
            "You are an expert academic tutor for Indonesian university students. "
            "Answer the following question based ONLY on the provided textbook context. "
            "If the context doesn't contain enough information, say so clearly.\n\n"
            f"Context:\n{context_text}\n\n"
            f"Question: {query}\n\n"
            "Provide a clear, structured explanation in Bahasa Indonesia."
        )

        return await self.llm.generate(prompt)

    async def analyze_image(self, image_url: str, context: str | None = None) -> dict:
        """Analyze a textbook image: extract topic, generate explanation, suggest 3D asset."""
        # Step 1: Use LLM to describe the image content
        vision_prompt = (
            "Analyze this textbook image. Identify the academic subject and topic. "
            "Extract any visible text, diagrams, or formulas. "
            "Respond in this exact format:\n"
            "TOPIC: <subject topic>\n"
            "CONTENT: <extracted text or description>\n"
            "3D_HINT: <suggested 3D model name for AR, or 'none'>"
        )
        if context:
            vision_prompt += f"\n\nAdditional context: This is from a {context} course."

        raw_analysis = await self.llm.generate(vision_prompt, image_url=image_url)

        # Parse the LLM output
        topic = "General Academic"
        content = raw_analysis
        asset_hint = None

        for line in raw_analysis.split("\n"):
            line = line.strip()
            if line.startswith("TOPIC:"):
                topic = line.replace("TOPIC:", "").strip()
            elif line.startswith("CONTENT:"):
                content = line.replace("CONTENT:", "").strip()
            elif line.startswith("3D_HINT:"):
                hint = line.replace("3D_HINT:", "").strip()
                asset_hint = hint if hint.lower() != "none" else None

        # Step 2: Retrieve related academic material via RAG (if embeddings available)
        chunks = []
        if self.has_embeddings:
            try:
                chunks = await self.retrieve(content, top_k=3)
            except Exception:
                chunks = []

        # Step 3: Generate comprehensive explanation
        if chunks:
            explanation = await self.generate_answer(content, chunks)
        else:
            explanation = await self.llm.generate(
                f"Explain the following academic topic clearly for a university student:\n\n{content}"
            )

        return {
            "explanation": explanation,
            "subject_topic": topic,
            "confidence": 0.85 if chunks else 0.60,
            "asset_3d_hint": asset_hint,
        }

    async def chat_scoped(self, topic: str, message: str, history: list[dict] = None) -> str:
        """Answer queries while strictly scoping the conversation to the provided topic."""
        history_text = ""
        if history:
            for turn in history:
                role = turn.get("role", "user")
                content = turn.get("content", "")
                history_text += f"{role.upper()}: {content}\n"

        prompt = (
            f"You are a strict academic tutor helping a student with the topic: '{topic}'.\n"
            f"Your instructions:\n"
            f"1. You MUST ONLY answer questions, explain concepts, or discuss matters directly related to the topic: '{topic}'.\n"
            f"2. Under NO circumstances should you discuss, answer, or help the user with any other subject, topic, or task (even general programming, history, math, off-topic requests, or coding help) if it is not directly related to '{topic}'.\n"
            f"3. If the question or message is NOT related to the topic '{topic}', you MUST refuse to answer politely in Bahasa Indonesia, stating that you can only explain and answer questions about '{topic}'.\n\n"
            f"Conversation History:\n{history_text}"
            f"User: {message}\n"
            f"Assistant:"
        )

        return await self.llm.generate(prompt)
"""RAG pipeline using LangChain + Qdrant for academic content retrieval."""
