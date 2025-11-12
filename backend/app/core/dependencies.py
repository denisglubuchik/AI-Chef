from typing import Annotated
from fastapi import Depends

from app.config import Settings, get_settings
from app.services.openai_client import OpenAIClient
from app.services.agent_service import AgentService
from app.services.image_service import ImageService

# Settings dependency
SettingsDep = Annotated[Settings, Depends(get_settings)]


# OpenAI Client
def get_openai_client(settings: SettingsDep) -> OpenAIClient:
    """Get OpenAI client instance."""
    return OpenAIClient(settings)


OpenAIClientDep = Annotated[OpenAIClient, Depends(get_openai_client)]


# Agent Service
def get_agent_service(openai_client: OpenAIClientDep) -> AgentService:
    """Get agent service instance."""
    return AgentService(openai_client)


AgentServiceDep = Annotated[AgentService, Depends(get_agent_service)]


# Image Service
def get_image_service(settings: SettingsDep) -> ImageService:
    """Get image service instance."""
    return ImageService(settings)


ImageServiceDep = Annotated[ImageService, Depends(get_image_service)]

