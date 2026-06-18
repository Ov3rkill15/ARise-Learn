from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    # LLM Provider: "gemini", "openai", or "groq"
    llm_provider: str = "mock"  # "mock" | "gemini" | "openai" | "groq"
    gemini_api_key: str = ""
    openai_api_key: str = ""
    groq_api_key: str = ""
    gemini_model: str = "gemini-1.5-pro"
    openai_model: str = "gpt-4o"
    groq_model: str = "meta-llama/llama-4-scout-17b-16e-instruct"

    # Qdrant
    qdrant_host: str = "localhost"
    qdrant_port: int = 6333
    qdrant_collection: str = "edutech_textbooks"

    # Embedding
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
