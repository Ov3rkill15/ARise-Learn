# 📋 Update Log — ARise Learn

> Dokumentasi lengkap seluruh perubahan yang dilakukan pada proyek **ARise Learn** (Edutech AR-based Learning Platform).
> 
> **Repository:** [Defen21/ARise-Learn](https://github.com/Defen21/ARise-Learn)  
> **Tanggal Mulai:** 18 Juni 2026  
> **Author:** Defen21

---

## 🏗️ Arsitektur Proyek

```
ARise-Learn/
├── mobile/          → Flutter Web/Mobile App (Dart)
├── backend/         → Go REST API Gateway (Gin)
├── ai-service/      → Python FastAPI AI/RAG Service
├── docker-compose.yml
└── update.md        → File ini
```

| Layer | Teknologi | Port | Deskripsi |
|-------|-----------|------|-----------|
| **Frontend** | Flutter (Dart) | 9999 | Aplikasi web/mobile dengan kamera, 3D viewport, AR viewer |
| **Backend API** | Go (Gin) | 8080 | REST API gateway, file upload, PostgreSQL, proxy ke AI service |
| **AI Service** | Python (FastAPI) | 8000 | Groq LLM, RAG pipeline, Qdrant vector DB, analisis gambar |
| **Database** | PostgreSQL 16 | 5432 | Penyimpanan data scan & user |
| **Vector DB** | Qdrant | 6333 | Embedding dan retrieval dokumen akademik |

---

## 📝 Changelog (Terbaru → Terlama)

---

### 🔧 `7881b1d` — Fix: Improve Groq API Error Handling
**Tanggal:** 18 Juni 2026, 20:23 WIB

**Masalah:**
- Error 500 Internal Server Error saat Groq API menolak base64 image yang invalid (`invalid base64 url`)
- URL gambar tanpa protocol (`http://`) menyebabkan crash pada httpx client

**Perubahan:**

#### `ai-service/app/services/llm_client.py`
- ✅ Menambahkan flag `has_image` untuk melacak apakah gambar berhasil di-load
- ✅ Fallback ke **text-only prompt** jika gambar gagal di-download (menghindari Groq vision API error)
- ✅ **Retry logic** — jika Groq gagal dengan vision request, otomatis retry tanpa gambar
- ✅ Handling untuk `response.choices` kosong
- ✅ Menambahkan `follow_redirects=True` pada httpx client

#### `ai-service/app/routers/analyze.py`
- ✅ Menambahkan **detailed error logging** dengan info `image_url` dan `context` untuk debugging lebih mudah

---

### ✨ `b491239` — Feat: Fullscreen AR Mode + Floating 3D Hotspot Tooltips
**Tanggal:** 18 Juni 2026, 20:05 WIB

**Fitur Baru:**
- Mode AR kamera penuh (fullscreen) dengan overlay model 3D di atas feed webcam
- **Floating tooltip interaktif** — ketika user mengklik bagian model 3D (misalnya nukleus, elektron), muncul penjelasan melayang (callout) langsung di posisi 3D object
- Navigasi dari hasil scan ke mode AR sekarang meneruskan model 3D yang sesuai (bukan hardcoded 'atom')

**Perubahan:**

#### `mobile/lib/screens/ar_viewer_screen.dart`
- ✅ Menambahkan method `_getSelectedPartOffset()` untuk menghitung posisi tooltip berdasarkan koordinat 3D
- ✅ Floating explanation card dengan desain cyberpunk (gradient, glow effect)
- ✅ Arrow pointer yang menunjuk ke bagian 3D yang dipilih
- ✅ Parameter `scanMode: false` pada webcam preview di AR mode (tanpa reticle/shutter)

#### `mobile/lib/screens/scan_result_screen.dart`
- ✅ Tombol "MASUK MODE AR KAMERA PENUH" sekarang meneruskan `result.asset3dUrl` yang benar

#### `mobile/lib/widgets/camera_web.dart`
- ✅ Menambahkan parameter `scanMode` — saat `false`, menyembunyikan elemen scanner HUD

#### `mobile/lib/widgets/camera_stub.dart`
- ✅ Menambahkan parameter `scanMode` untuk konsistensi API

---

### 🔧 `5256832` — Fix: Disable Page Scroll di 3D Viewport
**Tanggal:** 18 Juni 2026, 19:39 WIB

**Masalah:**
- Saat cursor berada di dalam display 3D, scroll wheel/trackpad menggeser halaman alih-alih melakukan zoom pada model 3D

**Solusi:**
- ✅ Mendeteksi posisi cursor — jika di dalam 3D viewport, scroll event diblokir dan dialihkan ke fungsi **pinch/zoom**
- ✅ Jika cursor keluar dari 3D viewport, scroll halaman kembali normal

**File:** `mobile/lib/screens/scan_result_screen.dart`

---

### 🔧 `836ef17` — Fix: Pinch-to-Zoom (Cubit) di 3D Viewport
**Tanggal:** 18 Juni 2026, 19:30 WIB

**Masalah:**
- Gesture pinch (cubit) pada trackpad/touchscreen tidak berfungsi untuk zoom model 3D

**Solusi:**
- ✅ Implementasi gesture recognizer untuk **ScaleGestureRecognizer** (pinch-to-zoom)
- ✅ Scroll wheel juga bisa digunakan untuk zoom

**File:** `mobile/lib/screens/scan_result_screen.dart`

---

### 🔧 `6bb4f2c` — Fix: Black Screen pada Webcam Flutter Web
**Tanggal:** 18 Juni 2026, 19:20 WIB

**Masalah:**
- Kamera menampilkan layar hitam saat dibuka di Flutter Web

**Solusi:**
- ✅ Perbaikan inisialisasi `getUserMedia` dan video element di platform web
- ✅ Menambahkan proper error handling untuk permission denied

**File:** `mobile/lib/widgets/camera_web.dart`

---

### 🔧 `25518ec` — Fix: Update Groq Model + Error Logging
**Tanggal:** 18 Juni 2026, 19:12 WIB

**Perubahan:**
- ✅ Update model Groq ke `meta-llama/llama-4-scout-17b-16e-instruct` yang aktif
- ✅ Menambahkan error logging yang lebih baik

**File:** `ai-service/app/core/config.py`, `ai-service/app/services/llm_client.py`

---

### ✨ `18e3380` — Feat: Groq LLM Provider Integration
**Tanggal:** 18 Juni 2026, 18:53 WIB

**Fitur Baru:**
- Integrasi **Groq API** sebagai LLM provider (menggunakan OpenAI-compatible SDK)
- Support model Llama 4 Scout untuk analisis gambar dan chat

**Perubahan:**

#### `ai-service/app/services/llm_client.py`
- ✅ Class `GroqClient` baru — menggunakan `openai.AsyncOpenAI` dengan base_url Groq
- ✅ Factory function `create_llm_client()` mendukung provider `"groq"`

#### `ai-service/app/core/config.py`
- ✅ Menambahkan field `groq_api_key` dan `groq_model`

#### `ai-service/.env`
- ✅ Konfigurasi: `LLM_PROVIDER=groq`

---

### ✨ `4c6a8d1` — Feat: Real-time Camera Scan + 3D Viewport + Scoped AI Chat
**Tanggal:** 18 Juni 2026, 17:41 WIB

**Fitur Utama:**
- 📸 **Scan kamera real-time** — capture gambar dari webcam/kamera perangkat
- 📤 **Upload gambar** ke backend Go → diteruskan ke AI service untuk analisis
- 🔬 **Inline 3D model viewport** — menampilkan model 3D interaktif sesuai topik yang di-scan (atom, jantung, DNA, H2O)
- 💬 **Scoped AI Chat** — tanya jawab AI yang di-scope ke topik yang di-scan saja (tidak bisa keluar topik)

**File Baru:**
- `mobile/lib/widgets/camera_web.dart` — implementasi webcam untuk Flutter Web
- `mobile/lib/widgets/camera_stub.dart` — stub untuk platform non-web
- `mobile/lib/widgets/live_camera_dialog.dart` — dialog kamera live

**File Dimodifikasi:**
- `mobile/lib/screens/home_screen.dart` — flow scan dari home
- `mobile/lib/screens/scan_result_screen.dart` — tampilan hasil scan + 3D viewport + AI chat
- `mobile/lib/services/api_service.dart` — `uploadScan()`, `askQuestion()`

---

### ✨ `80ce616` — Feat: Camera Capture + Photo Preview
**Tanggal:** 18 Juni 2026, 15:11 WIB

**Fitur:**
- ✅ Fungsionalitas capture foto dari kamera perangkat
- ✅ Preview foto real-time sebelum upload

---

### 🎨 `bf5a0c0` — Style: UI Improvements
**Tanggal:** 18 Juni 2026, 15:08 WIB

**Perubahan:**
- ✅ Toggle **Light/Dark mode** 
- ✅ **3D axes gizmo** — penunjuk sumbu X/Y/Z pada 3D viewport
- ✅ **Spotify-style TTS player** — audio player mockup untuk text-to-speech penjelasan

---

### ✨ `8bf7cef` — Feat: Initial Project Setup + Full Architecture
**Tanggal:** 18 Juni 2026, 14:30 WIB

**Deskripsi:**
Commit awal yang membangun seluruh arsitektur proyek dari nol.

**Komponen yang Dibuat:**

#### 🔹 Flutter Mobile App (`mobile/`)
- Halaman utama (Home Screen) dengan desain premium glassmorphism
- Halaman hasil scan (Scan Result Screen) dengan model 3D interaktif
- Halaman AR Viewer dengan kamera + overlay 3D
- Model data `ScanResult`
- Service layer `ApiService` dengan Dio HTTP client
- 5 model 3D built-in: Atom, Jantung, DNA Helix, Molekul Air, General

#### 🔹 Go Backend API (`backend/`)
- REST API dengan Gin framework
- Routes: `/api/v1/scan`, `/scan/upload`, `/scan/chat`, `/scan/:id`
- PostgreSQL repository layer
- Proxy ke AI service untuk analisis gambar

#### 🔹 Python AI Service (`ai-service/`)
- FastAPI server
- RAG pipeline: LangChain + Qdrant + HuggingFace embeddings
- LLM abstraction: support Mock, Gemini, OpenAI, Groq
- Endpoints: `/api/v1/analyze`, `/api/v1/chat`, `/api/v1/rag/query`

#### 🔹 Infrastructure
- `docker-compose.yml` — orchestrasi seluruh stack
- PostgreSQL 16 + Qdrant vector DB
- Environment variables via `.env`

---

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK (≥ 3.x)
- Go (≥ 1.21)
- Python (≥ 3.11)
- PostgreSQL 16
- Docker & Docker Compose (opsional)

### Quick Start (Development)

```bash
# 1. Clone repo
git clone https://github.com/Defen21/ARise-Learn.git
cd ARise-Learn

# 2. Setup AI Service
cd ai-service
python -m venv venv
.\venv\Scripts\activate  # Windows
pip install -r requirements.txt
cp .env.example .env
# Edit .env → set LLM_PROVIDER dan API key
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 3. Setup Go Backend
cd ../backend
cp .env.example .env
go run cmd/server/main.go

# 4. Setup Flutter App
cd ../mobile
flutter pub get
flutter run -d chrome --web-port 9999
```

### Dengan Docker Compose

```bash
cp .env.example .env
# Edit .env dengan API key yang sesuai
docker-compose up --build
```

---

## 📊 Status Fitur

| Fitur | Status | Catatan |
|-------|--------|---------|
| Scan kamera real-time | ✅ Selesai | Web + Mobile |
| Upload gambar ke AI | ✅ Selesai | Via Go backend proxy |
| Analisis AI (Groq LLM) | ✅ Selesai | Llama 4 Scout |
| Model 3D interaktif | ✅ Selesai | 5 model built-in |
| Pinch-to-zoom 3D | ✅ Selesai | Trackpad + touch |
| Scroll isolation 3D | ✅ Selesai | Cursor di dalam = zoom |
| Mode AR kamera penuh | ✅ Selesai | Fullscreen + overlay |
| Tooltip 3D interaktif | ✅ Selesai | Klik bagian → penjelasan |
| Scoped AI Chat | ✅ Selesai | Terbatas pada topik scan |
| Dark/Light mode | ✅ Selesai | Toggle tersedia |
| RAG (Retrieval) | ⚠️ Parsial | Butuh Qdrant server |
| TTS Audio Guide | 🔲 Mockup | UI ready, perlu TTS API |
| Auth/Login | 🔲 Placeholder | Endpoint tersedia |

---

*Terakhir diperbarui: 18 Juni 2026, 20:31 WIB*
