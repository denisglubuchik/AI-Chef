from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict
from agents import OpenAIResponsesModel
from openai import AsyncOpenAI

BASE_DIR = Path(__file__).resolve().parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=str(BASE_DIR / ".env"), env_file_encoding="utf-8")

    openai_api_key: str
    openai_base_url: str
    agent_model: str


settings = Settings()


openai_client = AsyncOpenAI(
    api_key=settings.openai_api_key,
    base_url=settings.openai_base_url
)


agent_model = OpenAIResponsesModel(
    model=settings.agent_model,
    openai_client=openai_client
)