"""OpenAI client wrapper."""

from openai import AsyncOpenAI
from agents import OpenAIResponsesModel

from app.config import Settings


class OpenAIClient:
    """Wrapper around OpenAI client with configuration."""
    
    def __init__(self, settings: Settings):
        """Initialize OpenAI client with settings."""
        self._settings = settings
        self._client = AsyncOpenAI(
            api_key=settings.openai_api_key,
            base_url=settings.openai_base_url,
            timeout=settings.openai_timeout,
            max_retries=settings.openai_max_retries,
        )
        self._model = OpenAIResponsesModel(
            model=settings.agent_model,
            openai_client=self._client
        )
    
    @property
    def client(self) -> AsyncOpenAI:
        """Get the underlying OpenAI client."""
        return self._client
    
    @property
    def model(self) -> OpenAIResponsesModel:
        """Get the OpenAI responses model for agent."""
        return self._model
    
    @property
    def model_name(self) -> str:
        """Get the model name."""
        return self._settings.agent_model

