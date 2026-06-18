"""LLM client abstraction supporting Gemini, OpenAI, and mock mode."""

from abc import ABC, abstractmethod
from app.core.config import get_settings


class BaseLLMClient(ABC):
    @abstractmethod
    async def generate(self, prompt: str, image_url: str | None = None) -> str:
        ...


class MockLLMClient(BaseLLMClient):
    """Returns a structured academic response when in mock mode based on keywords."""

    async def generate(self, prompt: str, image_url: str | None = None) -> str:
        text = (image_url or "").lower()
        prompt_lower = prompt.lower()
        
        # 1. First Call: Vision analysis requests TOPIC, CONTENT, 3D_HINT
        if "analyze this textbook image" in prompt_lower:
            if "heart" in text or "anatomy" in text or "jantung" in text:
                return (
                    "TOPIC: Anatomi Jantung Manusia\n"
                    "CONTENT: Struktur internal jantung manusia termasuk atrium kiri/kanan, ventrikel kiri/kanan, katup jantung, dan pembuluh darah utama seperti aorta.\n"
                    "3D_HINT: heart"
                )
            elif "dna" in text or "biology" in text or "genetika" in text:
                return (
                    "TOPIC: Genetika - Helix Ganda DNA\n"
                    "CONTENT: Struktur heliks ganda DNA yang terdiri dari gugus fosfat, gula deoksiribosa, dan pasangan basa nitrogen (A-T, C-G).\n"
                    "3D_HINT: dna_helix"
                )
            elif "h2o" in text or "chemistry" in text or "water" in text:
                return (
                    "TOPIC: Kimia Molekul - H2O (Air)\n"
                    "CONTENT: Ikatan kovalen polar antara satu atom oksigen dan dua atom hidrogen, membentuk geometri molekul bengkok.\n"
                    "3D_HINT: water_molecule"
                )
            else:
                return (
                    "TOPIC: Struktur Dasar Atom\n"
                    "CONTENT: Model atom Rutherford-Bohr yang menunjukkan inti atom dikelilingi elektron pada tingkat lintasan tertentu.\n"
                    "3D_HINT: atom"
                )

        # 2. Second Call: Text explanation generation
        if "explain the following academic topic" in prompt_lower or "jantung" in prompt_lower or "heart" in prompt_lower:
            if "jantung" in prompt_lower or "heart" in prompt_lower:
                return (
                    "### Anatomi Jantung Manusia\n\n"
                    "Jantung adalah organ berongga yang tersusun atas otot jantung (miokardium) khusus, "
                    "berukuran kira-kira sebesar kepalan tangan pemiliknya, dan terletak di rongga dada sebelah kiri.\n\n"
                    "**Bagian Utama Jantung:**\n"
                    "1. **Atrium Kanan & Kiri (Serambi):** Menerima darah kembali ke jantung. Atrium kanan menerima darah kotor (kaya CO2) dari seluruh tubuh, sedangkan atrium kiri menerima darah bersih (kaya O2) dari paru-paru.\n"
                    "2. **Ventrikel Kanan & Kiri (Bilik):** Memompa darah keluar dari jantung. Ventrikel kanan memompa darah ke paru-paru (sirkulasi kecil), sedangkan ventrikel kiri memompa darah ke seluruh tubuh (sirkulasi besar) dengan otot dinding yang lebih tebal.\n"
                    "3. **Katup Jantung (Valvula):** Menjaga agar aliran darah tetap searah dan tidak kembali ke bilik sebelumnya (misalnya Katup Trikuspidal dan Bikuspidal).\n\n"
                    "*Gunakan tombol visualisasi 3D AR di atas untuk memproyeksikan potongan melintang anatomi jantung ini langsung di meja belajar Anda!*"
                )
            elif "dna" in prompt_lower or "genetika" in prompt_lower:
                return (
                    "### Struktur Helix Ganda DNA\n\n"
                    "DNA (Deoxyribonucleic Acid) menyimpan informasi genetik seluruh makhluk hidup. "
                    "Molekul ini berbentuk seperti tangga berpilin ganda (*double helix*) berputar ke arah kanan.\n\n"
                    "**Karakteristik Utama DNA:**\n"
                    "1. **Tulang Punggung Gula-Fosfat:** Bagian samping tangga terbuat dari gugus fosfat dan gula pentosa (deoksiribosa) yang saling berikatan kovalen secara berselang-seling.\n"
                    "2. **Pasangan Basa Nitrogen:** Anak tangga dibentuk oleh basa nitrogen yang dihubungkan oleh ikatan hidrogen lemah:\n"
                    "   - **Adenin (A)** berpasangan dengan **Timin (T)** (dihubungkan oleh 2 ikatan hidrogen).\n"
                    "   - **Guanin (G)** berpasangan dengan **Sitosin (C)** (dihubungkan oleh 3 ikatan hidrogen).\n"
                    "3. **Arah Antiparalel:** Kedua rantai DNA berorientasi berlawanan arah (dari ujung 5' ke 3' dan ujung 3' ke 5').\n\n"
                    "*Aktifkan visualisasi AR untuk memutar model heliks DNA, mengamati pasangan basa nitrogen secara mendalam, dan memvisualisasikan replikasi genetik.*"
                )
            elif "h2o" in prompt_lower or "molekul" in prompt_lower or "air" in prompt_lower:
                return (
                    "### Struktur & Geometri Molekul Air (H2O)\n\n"
                    "Molekul air terdiri dari satu atom Oksigen (O) dan dua atom Hidrogen (H). "
                    "Sifat fisika-kimia air menjadikannya pelarut universal yang unik.\n\n"
                    "**Karakteristik Molekular:**\n"
                    "1. **Ikatan Kovalen Polar:** Atom Oksigen sangat elektronegatif, menarik pasangan elektron ikatan lebih dekat ke dirinya, menghasilkan kutub parsial negatif (δ-) di Oksigen dan parsial positif (δ+) di Hidrogen.\n"
                    "2. **Geometri Sudut Bengkok (Bent Geometry):** Adanya dua pasang elektron bebas (*lone pairs*) pada atom Oksigen menolak ikatan O-H ke bawah, membentuk sudut ikatan spesifik sebesar **104.5°**.\n"
                    "3. **Ikatan Hidrogen:** Karena kepolarannya, antar-molekul air dapat saling tarik-menarik membentuk jaringan ikatan hidrogen yang memberikan sifat kohesi-adhesi yang kuat dan titik didih tinggi.\n\n"
                    "*Proyeksikan model molekul H2O 3D untuk melihat susunan geometri bengkok serta interaksi tarikan polar antar-molekul secara spasial.*"
                )
            else:
                return (
                    "### Struktur Dasar Atom (Model Bohr)\n\n"
                    "Atom adalah unit penyusun terkecil dari materi yang mempertahankan sifat kimia dari unsur tersebut.\n\n"
                    "**Komponen Utama Atom:**\n"
                    "1. **Inti Atom (Nukleus):** Berada di bagian tengah atom, terdiri atas **Proton** (bermuatan positif) dan **Neutron** (netral, tidak bermuatan).\n"
                    "2. **Elektron:** Partikel bermuatan negatif yang mengorbit inti atom pada tingkat energi lintasan (kulit atom) tertentu.\n"
                    "3. **Gaya Tarik Coulomb:** Gaya elektrostatik yang mengikat elektron negatif agar tetap berada dalam lintasan orbit mengitari inti positif.\n\n"
                    "*Gunakan penampil AR untuk memproyeksikan visualisasi interaktif perputaran elektron pada lintasan kulit atom Bohr ini.*"
                )

        return (
            "[Mock LLM Response] Berdasarkan materi buku teks yang dipindai:\n\n"
            "Topik ini mencakup konsep dasar akademik. Anda dapat mengkonfigurasi "
            "GEMINI_API_KEY atau OPENAI_API_KEY di berkas `.env` untuk analisis real-time."
        )


class GeminiClient(BaseLLMClient):
    """Google Gemini multimodal LLM client."""

    def __init__(self):
        import google.generativeai as genai
        settings = get_settings()
        genai.configure(api_key=settings.gemini_api_key)
        self.model = genai.GenerativeModel(settings.gemini_model)

    async def generate(self, prompt: str, image_url: str | None = None) -> str:
        content = [prompt]
        if image_url:
            # For production: download image and pass as PIL.Image or bytes
            content.append(f"[Image reference: {image_url}]")
        response = self.model.generate_content(content)
        return response.text


class OpenAIClient(BaseLLMClient):
    """OpenAI GPT-4o multimodal client."""

    def __init__(self):
        from openai import AsyncOpenAI
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model

    async def generate(self, prompt: str, image_url: str | None = None) -> str:
        messages = []
        content = [{"type": "text", "text": prompt}]
        if image_url:
            content.append({"type": "image_url", "image_url": {"url": image_url}})
        messages.append({"role": "user", "content": content})

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=1024,
        )
        return response.choices[0].message.content


def create_llm_client() -> BaseLLMClient:
    """Factory: creates the appropriate LLM client based on config."""
    settings = get_settings()
    provider = settings.llm_provider.lower()

    if provider == "gemini":
        return GeminiClient()
    elif provider == "openai":
        return OpenAIClient()
    else:
        return MockLLMClient()
