from pathlib import Path
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    # OpenAI Configuration
    openai_api_key: str
    openai_base_url: str
    agent_model: str = "gpt-4o-mini"  # Keep old name for compatibility with .env
    openai_timeout: int = 60
    openai_max_retries: int = 3
    
    # Image Processing
    max_image_size_mb: int = 20
    allowed_image_types: list[str] = ["image/jpeg", "image/png", "image/webp", "image/gif"]
    
    # CORS
    cors_origins: list[str] = ["*"]  # In production, specify exact origins
    
    # Application
    app_name: str = "Holodilnik API"
    app_version: str = "0.2.0"
    debug: bool = False
    log_level: str = "INFO"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

