"""LLM client abstraction supporting Gemini, OpenAI, and mock mode."""

from abc import ABC, abstractmethod
from app.core.config import get_settings


class BaseLLMClient(ABC):
    @abstractmethod
    async def generate(self, prompt: str, image_url: str | None = None, image_base64: str | None = None, mime_type: str | None = None) -> str:
        ...


class MockLLMClient(BaseLLMClient):
    """Returns a structured academic response when in mock mode based on keywords."""

    async def generate(self, prompt: str, image_url: str | None = None, image_base64: str | None = None, mime_type: str | None = None) -> str:
        text = (image_url or "").lower()
        prompt_lower = prompt.lower()
        
        # 1. First Call: Vision analysis requests TOPIC, CONTENT, 3D_HINT
        if "analyze this textbook image" in prompt_lower:
            if "heart" in text or "anatomy" in text or "jantung" in text or "jantung" in prompt_lower or "heart" in prompt_lower:
                return (
                    "TOPIC: Anatomi Jantung Manusia\n"
                    "CONTENT: Struktur internal jantung manusia termasuk atrium kiri/kanan, ventrikel kiri/kanan, katup jantung, dan pembuluh darah utama seperti aorta.\n"
                    "3D_HINT: heart"
                )
            elif "dna" in text or "biology" in text or "genetika" in text or "dna" in prompt_lower or "genetika" in prompt_lower:
                return (
                    "TOPIC: Genetika - Helix Ganda DNA\n"
                    "CONTENT: Struktur heliks ganda DNA yang terdiri dari gugus fosfat, gula deoksiribosa, dan pasangan basa nitrogen (A-T, C-G).\n"
                    "3D_HINT: dna_helix"
                )
            elif "h2o" in text or "chemistry" in text or "water" in text or "h2o" in prompt_lower or "kimia" in prompt_lower or "water" in prompt_lower:
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
            if "jantung" in prompt_lower or "heart" in prompt_lower or "anatomy" in prompt_lower:
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
            elif "h2o" in prompt_lower or "molekul" in prompt_lower or "air" in prompt_lower or "chemistry" in prompt_lower:
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

        # 3. Third Call: Scoped Chat Q&A
        if "strict academic tutor" in prompt_lower:
            topic = "Struktur Dasar Atom"
            if "jantung" in prompt_lower or "heart" in prompt_lower:
                topic = "Anatomi Jantung Manusia"
            elif "dna" in prompt_lower:
                topic = "Genetika - Helix Ganda DNA"
            elif "h2o" in prompt_lower or "air" in prompt_lower:
                topic = "Kimia Molekul - H2O (Air)"
            
            # Check if user message is off-topic
            off_topic_indicators = ["presiden", "politik", "masak", "nasi goreng", "cuaca", "game", "main", "sejarah indonesia", "wisata", "liburan", "offtopic", "outside", "makan", "film", "lagu", "siapa", "dimana"]
            
            user_msg = ""
            if "user:" in prompt_lower:
                user_msg = prompt_lower.split("user:")[-1].split("assistant:")[0].strip()
            
            is_off_topic = any(keyword in user_msg for keyword in off_topic_indicators)
            
            if is_off_topic:
                return (
                    f"Maaf, saya diprogram sebagai asisten akademik khusus untuk topik '{topic}'. "
                    f"Saya tidak dapat menjawab pertanyaan di luar topik tersebut untuk menjaga fokus pembelajaran Anda."
                )
            
            # On-topic mock replies
            if "inti" in user_msg or "nucleus" in user_msg or "nukleus" in user_msg or "proton" in user_msg or "neutron" in user_msg:
                if topic == "Anatomi Jantung Manusia":
                    return "Inti jantung dilindungi oleh perikardium dan tersusun atas otot jantung (miokardium) khusus."
                elif topic == "Genetika - Helix Ganda DNA":
                    return "DNA terletak di dalam nukleus (inti sel) eukariotik dan terikat erat pada protein histon."
                else:
                    return "Inti atom terletak di pusat atom, bermuatan positif, dan berisi proton (+) serta neutron (netral) yang sangat rapat."
            elif "elektron" in user_msg or "orbit" in user_msg or "lintasan" in user_msg:
                return "Elektron bergerak mengelilingi inti atom dalam lintasan stasioner (orbit Bohr) dengan tingkat energi diskret tertentu."
            elif "darah" in user_msg or "katup" in user_msg or "serambi" in user_msg or "bilik" in user_msg:
                return "Katup jantung berfungsi menjaga agar darah bersih dan darah kotor tidak bercampur serta mengalir searah."
            elif "basa" in user_msg or "nitrogen" in user_msg or "pasangan" in user_msg:
                return "Pasangan basa nitrogen pada DNA selalu spesifik: Adenin dengan Timin, dan Guanin dengan Sitosin."
            else:
                return f"Tentu, terkait topik '{topic}', konsep ini sangat penting dalam kurikulum. Apakah ada bagian spesifik seperti komponen, fungsi, atau struktur 3D-nya yang ingin Anda tanyakan?"

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

    async def generate(self, prompt: str, image_url: str | None = None, image_base64: str | None = None, mime_type: str | None = None) -> str:
        content = [prompt]
        if image_base64:
            # Use base64 directly — avoids URL reachability issues
            try:
                import base64 as b64
                from PIL import Image
                import io
                img_data = b64.b64decode(image_base64)
                img = Image.open(io.BytesIO(img_data))
                content.append(img)
            except Exception as e:
                print(f"Error decoding base64 image for Gemini: {e}")
                content.append(f"[Image reference: {image_url}]")
        elif image_url:
            try:
                import httpx
                from PIL import Image
                import io
                async with httpx.AsyncClient() as client:
                    resp = await client.get(image_url, timeout=12.0)
                    if resp.status_code == 200:
                        img = Image.open(io.BytesIO(resp.content))
                        content.append(img)
                    else:
                        content.append(f"[Image reference failed: {image_url}]")
            except Exception as e:
                print(f"Error loading image for Gemini: {e}")
                content.append(f"[Image reference: {image_url}]")
        
        # Run generate_content
        response = self.model.generate_content(content)
        return response.text


class OpenAIClient(BaseLLMClient):
    """OpenAI GPT-4o multimodal client."""

    def __init__(self):
        from openai import AsyncOpenAI
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model

    async def generate(self, prompt: str, image_url: str | None = None, image_base64: str | None = None, mime_type: str | None = None) -> str:
        messages = []
        content = [{"type": "text", "text": prompt}]
        if image_base64:
            # Use base64 directly
            mt = mime_type or "image/jpeg"
            image_data_url = f"data:{mt};base64,{image_base64}"
            content.append({"type": "image_url", "image_url": {"url": image_data_url}})
        elif image_url:
            try:
                import httpx
                import base64
                async with httpx.AsyncClient() as client:
                    resp = await client.get(image_url, timeout=12.0)
                    if resp.status_code == 200:
                        mime_type = resp.headers.get("content-type", "image/jpeg")
                        b64_data = base64.b64encode(resp.content).decode("utf-8")
                        image_data_url = f"data:{mime_type};base64,{b64_data}"
                        content.append({"type": "image_url", "image_url": {"url": image_data_url}})
                    else:
                        content.append({"type": "text", "text": f"[Image reference failed: {image_url}]"})
            except Exception as e:
                print(f"Error loading image for OpenAI: {e}")
                content.append({"type": "text", "text": f"[Image reference: {image_url}]"})
        
        messages.append({"role": "user", "content": content})

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=1024,
        )
        return response.choices[0].message.content

class GroqClient(BaseLLMClient):
    """Groq API client (OpenAI-compatible)."""

    def __init__(self):
        from openai import AsyncOpenAI
        settings = get_settings()
        self.client = AsyncOpenAI(
            api_key=settings.groq_api_key,
            base_url="https://api.groq.com/openai/v1",
        )
        self.model = settings.groq_model or "meta-llama/llama-4-scout-17b-16e-instruct"

    async def generate(self, prompt: str, image_url: str | None = None, image_base64: str | None = None, mime_type: str | None = None) -> str:
        messages = []
        content = [{"type": "text", "text": prompt}]
        has_image = False
        if image_base64:
            # Use base64 directly — no need to fetch URL
            mt = mime_type or "image/jpeg"
            image_data_url = f"data:{mt};base64,{image_base64}"
            content.append({"type": "image_url", "image_url": {"url": image_data_url}})
            has_image = True
        elif image_url:
            try:
                import httpx
                import base64
                async with httpx.AsyncClient(follow_redirects=True) as client:
                    resp = await client.get(image_url, timeout=15.0)
                    if resp.status_code == 200:
                        mime_type = resp.headers.get("content-type", "image/jpeg")
                        b64_data = base64.b64encode(resp.content).decode("utf-8")
                        image_data_url = f"data:{mime_type};base64,{b64_data}"
                        content.append({"type": "image_url", "image_url": {"url": image_data_url}})
                        has_image = True
                    else:
                        print(f"Groq: image fetch returned {resp.status_code} for {image_url}")
                        content.append({"type": "text", "text": f"[Image could not be loaded from: {image_url}]"})
            except Exception as e:
                print(f"Error loading image for Groq: {e}")
                content.append({"type": "text", "text": f"[Image could not be loaded: {image_url}]"})

        # If no image was loaded, simplify content to plain text (avoids Groq vision errors)
        if not has_image:
            messages.append({"role": "user", "content": prompt})
        else:
            messages.append({"role": "user", "content": content})

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=1024,
            )
            if response.choices and response.choices[0].message.content:
                return response.choices[0].message.content
            return "[Groq returned empty response]"
        except Exception as e:
            print(f"Groq API error: {e}")
            # Retry once with text-only if vision call failed
            if has_image:
                print("Retrying Groq without image...")
                try:
                    response = await self.client.chat.completions.create(
                        model=self.model,
                        messages=[{"role": "user", "content": prompt}],
                        max_tokens=1024,
                    )
                    if response.choices and response.choices[0].message.content:
                        return response.choices[0].message.content
                except Exception as retry_e:
                    print(f"Groq retry also failed: {retry_e}")
            raise


def create_llm_client() -> BaseLLMClient:
    """Factory: creates the appropriate LLM client based on config."""
    settings = get_settings()
    provider = settings.llm_provider.lower()

    if provider == "gemini":
        return GeminiClient()
    elif provider == "openai":
        return OpenAIClient()
    elif provider == "groq":
        return GroqClient()
    else:
        return MockLLMClient()
