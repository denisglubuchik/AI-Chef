"""FastAPI dependencies for the Holodilnik backend."""

from typing import Annotated

from fastapi import Depends
from openai import AsyncOpenAI

from backend.agent.service import HolodilnikAgentService
from backend.config import agent_model, openai_client, settings


def get_openai_client() -> AsyncOpenAI:
    """
    Dependency that provides a configured OpenAI client.
    
    This allows for easy mocking in tests and centralizes client configuration.
    """
    return openai_client


def get_agent_service(
    client: Annotated[AsyncOpenAI, Depends(get_openai_client)]
) -> HolodilnikAgentService:
    """
    Dependency that provides the Holodilnik agent service.
    
    Args:
        client: OpenAI client injected via dependency
        
    Returns:
        Configured HolodilnikAgentService instance
    """
    return HolodilnikAgentService(
        client=client,
        model=agent_model
    )


# Type alias for convenient use in route handlers
AgentService = Annotated[HolodilnikAgentService, Depends(get_agent_service)]

