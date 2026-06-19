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

    @staticmethod
    def _get_style_instructions() -> str:
        """Return concise formatting and style rules for LLM explanations."""
        return (
            "FORMAT RULES:\n"
            "- Use Markdown sub-headers (###) to separate sub-topics.\n"
            "- Use **bold** for key terms and bullet points for lists.\n"
            "- Start with a simple definition, then explain how it works, then why it matters.\n"
            "- Include one everyday analogy (e.g., atom = mini solar system, DNA = building blueprint, heart = automatic water pump).\n"
            "- Keep language simple and friendly for high-school students.\n"
            "- Do NOT output these formatting rules in your answer."
        )

    async def generate_answer(self, query: str, context_chunks: list[dict], language: str = "id") -> str:
        """Generate an answer using retrieved context + LLM."""
        context_text = "\n\n".join(
            [f"[Source {i+1}]: {c['text']}" for i, c in enumerate(context_chunks)]
        )

        lang_instruction = "Provide a clear, structured explanation in Bahasa Indonesia."
        if language == "en":
            lang_instruction = "Provide a clear, structured explanation in English."

        style_rules = self._get_style_instructions()

        prompt = (
            f"You are an expert academic tutor for high-school students.\n"
            f"{style_rules}\n\n"
            f"Explain the topic: '{query}'\n\n"
            f"Use ONLY this textbook context as your source:\n{context_text}\n\n"
            f"{lang_instruction}"
        )

        return await self.llm.generate(prompt)

    # Mapping from asset_hint to canonical topic names
    _ASSET_TOPIC_MAP = {
        "atom": "Struktur Atom (Model Bohr)",
        "heart": "Anatomi Jantung Manusia",
        "dna_helix": "Struktur Heliks Ganda DNA",
        "water_molecule": "Geometri Molekul Air (H₂O)",
    }

    async def analyze_image(self, image_url: str, context: str | None = None, language: str = "id", image_base64: str | None = None, mime_type: str | None = None) -> dict:
        """Analyze a textbook image: extract topic, generate explanation, suggest 3D asset."""

        # Step 1: Use LLM to describe the image content
        vision_prompt = (
            "You are analyzing a photo taken by a student's camera pointed at a textbook, "
            "screen, or educational material about science (physics, chemistry, biology).\n"
            "Focus ONLY on the main academic/science subject visible in the image.\n"
            "Ignore any UI elements, browser chrome, or non-academic content.\n\n"
            "Respond in this EXACT format (one line each):\n"
            "TOPIC: <the main science/academic topic, e.g. 'Atomic Structure', 'DNA', 'Heart Anatomy', 'Water Molecule'>\n"
            "CONTENT: <brief description of the academic content visible>\n"
            "3D_HINT: <one of: 'atom', 'dna_helix', 'heart', 'water_molecule', or 'none'>"
        )
        if context:
            vision_prompt += f"\n\nAdditional context: This is from a {context} course."

        raw_analysis = await self.llm.generate(vision_prompt, image_url=image_url, image_base64=image_base64, mime_type=mime_type)
        print(f"[Vision Step] Raw analysis: {raw_analysis}")

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
                hint = line.replace("3D_HINT:", "").strip().lower()
                if "water" in hint or "h2o" in hint:
                    asset_hint = "water_molecule"
                elif "dna" in hint or "helix" in hint:
                    asset_hint = "dna_helix"
                elif "heart" in hint or "jantung" in hint:
                    asset_hint = "heart"
                elif "atom" in hint or "bohr" in hint:
                    asset_hint = "atom"
                else:
                    asset_hint = hint if hint != "none" else None

        # Step 1b: Cross-validate topic with asset_hint
        # If the 3D hint was detected but topic doesn't match, align the topic
        if asset_hint and asset_hint in self._ASSET_TOPIC_MAP:
            canonical_topic = self._ASSET_TOPIC_MAP[asset_hint]
            topic_lower = topic.lower()
            asset_keywords = {
                "atom": ["atom", "bohr", "elektron", "electron", "proton", "nukleus", "nucleus"],
                "heart": ["heart", "jantung", "cardiac", "cardio", "anatomi"],
                "dna_helix": ["dna", "helix", "genetik", "genetic", "nukleotida"],
                "water_molecule": ["water", "air", "h2o", "molekul", "molecule"],
            }
            keywords = asset_keywords.get(asset_hint, [])
            if not any(kw in topic_lower for kw in keywords):
                print(f"[Topic Fix] Topic '{topic}' doesn't match asset '{asset_hint}', overriding to '{canonical_topic}'")
                topic = canonical_topic

        # Use topic as the primary subject for explanation (not raw content which may be noisy)
        explanation_subject = topic

        # Step 2: Retrieve related academic material via RAG (if embeddings available)
        chunks = []
        if self.has_embeddings:
            try:
                chunks = await self.retrieve(explanation_subject, top_k=3)
            except Exception:
                chunks = []

        # Step 3: Generate explanation driven by TOPIC (not raw content)
        if chunks:
            explanation = await self.generate_answer(explanation_subject, chunks, language=language)
        else:
            lang_instruction = "Provide a clear, structured explanation in Bahasa Indonesia."
            if language == "en":
                lang_instruction = "Provide a clear, structured explanation in English."

            style_rules = self._get_style_instructions()

            prompt = (
                f"You are an expert academic tutor for high-school students.\n"
                f"{style_rules}\n\n"
                f"Explain this science topic thoroughly: '{explanation_subject}'\n\n"
                f"{lang_instruction}"
            )

            explanation = await self.llm.generate(prompt)

        # Step 4: Generate next-topic recommendations
        recommendations = await self._generate_recommendations(topic, explanation_subject, language=language)

        return {
            "explanation": explanation,
            "subject_topic": topic,
            "confidence": 0.85 if chunks else 0.60,
            "asset_3d_hint": asset_hint,
            "recommendations": recommendations,
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

    async def _generate_recommendations(self, topic: str, content: str, language: str = "id") -> list[dict]:
        """Generate 3 next-topic recommendations based on the analyzed topic."""
        import json

        lang_instruction = "Write the title and description in Bahasa Indonesia."
        if language == "en":
            lang_instruction = "Write the title and description in English."

        prompt = (
            f"You are an academic advisor. Based on a student who just studied the topic: '{topic}' "
            f"with content about: '{content[:200]}', "
            f"recommend exactly 3 next topics that would be most effective and relevant to study next.\n\n"
            f"Rules:\n"
            f"- Topics must be academically related and build upon the current topic.\n"
            f"- Order by relevance: the most important topic first.\n"
            f"- First item should have relevance 'Sangat Relevan' (if Indonesian) or 'Highly Relevant' (if English), the rest 'Relevan' or 'Relevant'.\n"
            f"- icon_hint should be one of: 'science', 'biotech', 'chemistry', 'psychology', 'calculate', 'biology', 'medical', 'atom', 'water', 'dna'.\n"
            f"- {lang_instruction}\n\n"
            f"Respond ONLY with a valid JSON array (no markdown, no extra text), like:\n"
            f'[{{"title": "...", "description": "...", "relevance": "Sangat Relevan", "icon_hint": "science"}},'
            f'{{"title": "...", "description": "...", "relevance": "Relevan", "icon_hint": "biology"}},'
            f'{{"title": "...", "description": "...", "relevance": "Relevan", "icon_hint": "chemistry"}}]'
        )

        try:
            raw = await self.llm.generate(prompt)
            # Try to extract JSON array from the response
            raw = raw.strip()
            # Find the JSON array in the response
            start = raw.find('[')
            end = raw.rfind(']')
            if start != -1 and end != -1:
                json_str = raw[start:end + 1]
                recs = json.loads(json_str)
                if isinstance(recs, list):
                    return [
                        {
                            "title": r.get("title", "Topik Terkait"),
                            "description": r.get("description", "Materi lanjutan yang relevan."),
                            "relevance": r.get("relevance", "Relevan"),
                            "icon_hint": r.get("icon_hint", "book"),
                        }
                        for r in recs[:3]
                    ]
        except Exception as e:
            print(f"Warning: Failed to generate recommendations: {e}")

        # Fallback recommendations based on topic keywords and language choice
        return self._fallback_recommendations(topic, language)

    def _fallback_recommendations(self, topic: str, language: str = "id") -> list[dict]:
        """Return sensible fallback recommendations when LLM generation fails."""
        topic_lower = topic.lower()
        is_en = language == "en"

        if "jantung" in topic_lower or "heart" in topic_lower or "sirkulasi" in topic_lower:
            if is_en:
                return [
                    {"title": "Human Respiratory System", "description": "Learn the mechanism of O₂ and CO₂ gas exchange in lung alveoli connected directly with the circulatory system.", "relevance": "Highly Relevant", "icon_hint": "medical"},
                    {"title": "Blood Pressure & Hemodynamics", "description": "Understand how systolic/diastolic pressure works and factors affecting blood flow.", "relevance": "Relevant", "icon_hint": "science"},
                    {"title": "Lymphatic System", "description": "Explore the body drainage system that works in parallel with the blood circulatory system.", "relevance": "Relevant", "icon_hint": "biology"},
                ]
            return [
                {"title": "Sistem Pernapasan Manusia", "description": "Pelajari mekanisme pertukaran gas O₂ dan CO₂ di alveolus paru-paru yang terhubung langsung dengan sistem sirkulasi.", "relevance": "Sangat Relevan", "icon_hint": "medical"},
                {"title": "Tekanan Darah & Hemodinamika", "description": "Pahami bagaimana tekanan sistolik/diastolik bekerja dan faktor yang mempengaruhi aliran darah.", "relevance": "Relevan", "icon_hint": "science"},
                {"title": "Sistem Limfatik", "description": "Eksplorasi sistem drainase tubuh yang bekerja paralel dengan sistem peredaran darah.", "relevance": "Relevan", "icon_hint": "biology"},
            ]
        elif "dna" in topic_lower or "genetik" in topic_lower or "helix" in topic_lower:
            if is_en:
                return [
                    {"title": "Protein Synthesis (Transcription & Translation)", "description": "Learn how genetic information in DNA is translated into functional proteins via mRNA.", "relevance": "Highly Relevant", "icon_hint": "dna"},
                    {"title": "Genetic Mutation & Variation", "description": "Understand types of DNA mutations and their impact on gene expression and evolution.", "relevance": "Relevant", "icon_hint": "biotech"},
                    {"title": "Genetic Engineering Technology (CRISPR)", "description": "Explore modern gene editing technologies and their applications in medicine.", "relevance": "Relevant", "icon_hint": "science"},
                ]
            return [
                {"title": "Sintesis Protein (Transkripsi & Translasi)", "description": "Pelajari bagaimana informasi genetik di DNA diterjemahkan menjadi protein fungsional melalui mRNA.", "relevance": "Sangat Relevan", "icon_hint": "dna"},
                {"title": "Mutasi Genetik & Variasi", "description": "Pahami jenis-jenis mutasi DNA dan dampaknya terhadap ekspresi gen dan evolusi.", "relevance": "Relevan", "icon_hint": "biotech"},
                {"title": "Teknologi Rekayasa Genetika (CRISPR)", "description": "Eksplorasi teknologi penyuntingan gen modern dan aplikasinya dalam kedokteran.", "relevance": "Relevan", "icon_hint": "science"},
            ]
        elif "atom" in topic_lower or "bohr" in topic_lower or "elektron" in topic_lower:
            if is_en:
                return [
                    {"title": "Electron Configuration & Periodic Table", "description": "Learn how electron arrangement determines the chemical properties of elements in the periodic table.", "relevance": "Highly Relevant", "icon_hint": "atom"},
                    {"title": "Chemical Bonding (Ionic, Covalent, Metallic)", "description": "Understand how atoms bond with each other to form molecules and compounds.", "relevance": "Relevant", "icon_hint": "chemistry"},
                    {"title": "Atomic Spectra & Photoelectric Effect", "description": "Explore atomic light emission phenomena and the foundations of quantum mechanics.", "relevance": "Relevant", "icon_hint": "science"},
                ]
            return [
                {"title": "Konfigurasi Elektron & Tabel Periodik", "description": "Pelajari bagaimana susunan elektron menentukan sifat kimia unsur dalam tabel periodik.", "relevance": "Sangat Relevan", "icon_hint": "atom"},
                {"title": "Ikatan Kimia (Ionik, Kovalen, Logam)", "description": "Pahami bagaimana atom-atom saling berikatan membentuk molekul dan senyawa.", "relevance": "Relevan", "icon_hint": "chemistry"},
                {"title": "Spektrum Atom & Efek Fotolistrik", "description": "Eksplorasi fenomena emisi cahaya atom dan dasar mekanika kuantum.", "relevance": "Relevan", "icon_hint": "science"},
            ]
        elif "air" in topic_lower or "h2o" in topic_lower or "water" in topic_lower or "molekul" in topic_lower:
            if is_en:
                return [
                    {"title": "Hydrogen Bonding & Anomalous Properties of Water", "description": "Learn why water has a high boiling point, surface tension, and other unique behaviors.", "relevance": "Highly Relevant", "icon_hint": "water"},
                    {"title": "Electrolyte Solutions & Ion Equilibrium", "description": "Understand how water molecules act in solute dissociation and solubility.", "relevance": "Relevant", "icon_hint": "chemistry"},
                    {"title": "Molecular Geometry (VSEPR Theory)", "description": "Explore molecular shapes and how electron pairs affect bond angles.", "relevance": "Relevant", "icon_hint": "science"},
                ]
            return [
                {"title": "Ikatan Hidrogen & Sifat Anomali Air", "description": "Pelajari mengapa air memiliki titik didih tinggi, tegangan permukaan, dan perilaku unik lainnya.", "relevance": "Sangat Relevan", "icon_hint": "water"},
                {"title": "Larutan Elektrolit & Kesetimbangan Ion", "description": "Pahami bagaimana molekul air berperan dalam disosiasi dan kelarutan zat.", "relevance": "Relevan", "icon_hint": "chemistry"},
                {"title": "Geometri Molekul (Teori VSEPR)", "description": "Eksplorasi bentuk-bentuk molekul dan bagaimana pasangan elektron mempengaruhi sudut ikatan.", "relevance": "Relevan", "icon_hint": "science"},
            ]
        else:
            if is_en:
                return [
                    {"title": "Scientific Method & Critical Thinking", "description": "Learn the steps of the scientific method to analyze and solve academic problems.", "relevance": "Highly Relevant", "icon_hint": "science"},
                    {"title": "Interdisciplinary Applications", "description": "Understand how this topic connects with other fields of science.", "relevance": "Relevant", "icon_hint": "biology"},
                    {"title": "Exercise Questions & Evaluation", "description": "Test your understanding with practice questions related to this material.", "relevance": "Relevant", "icon_hint": "calculate"},
                ]
            return [
                {"title": "Metode Ilmiah & Berpikir Kritis", "description": "Pelajari langkah-langkah metode ilmiah untuk menganalisis dan memecahkan masalah akademik.", "relevance": "Sangat Relevan", "icon_hint": "science"},
                {"title": "Penerapan Interdisipliner", "description": "Pahami bagaimana topik ini terhubung dengan bidang ilmu lain.", "relevance": "Relevan", "icon_hint": "biology"},
                {"title": "Latihan Soal & Evaluasi", "description": "Uji pemahaman Anda dengan latihan soal terkait materi ini.", "relevance": "Relevan", "icon_hint": "calculate"},
            ]

"""RAG pipeline using LangChain + Qdrant for academic content retrieval."""
