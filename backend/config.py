import os
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=str(BASE_DIR / ".env"), env_file_encoding="utf-8")

    openai_api_key: str
    openai_base_url: str
    agent_model: str


settings = Settings()

# Set environment variables BEFORE importing agents
# os.environ["OPENAI_API_KEY"] = settings.openai_api_key
# os.environ["OPENAI_BASE_URL"] = settings.openai_base_url

# NOW import after env is set
from agents import OpenAIResponsesModel, set_default_openai_client, set_tracing_disabled
from openai import AsyncOpenAI

# Create client with custom base_url
openai_client = AsyncOpenAI(
    api_key=settings.openai_api_key,
    base_url=settings.openai_base_url
)


agent_model = OpenAIResponsesModel(
    model=settings.agent_model,
    openai_client=openai_client
)
# Set as default for agents SDK
# set_default_openai_client(openai_client, use_for_tracing=False)

set_tracing_disabled(True)