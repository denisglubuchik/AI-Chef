from typing import List, Optional
from pydantic import BaseModel, Field


class SuggestMealsRequest(BaseModel):
    """Request body for suggesting meals based on ingredients."""

    ingredients: List[str] = Field(..., min_length=1, description="List of available ingredients")
    servings: Optional[int] = Field(None, ge=1, description="Number of servings")
    dietary_preferences: Optional[List[str]] = Field(None, description="Dietary restrictions or preferences")


class BuildRecipeRequest(BaseModel):
    """Request body for building a detailed recipe."""

    suggestion_id: str = Field(..., description="ID of the selected dish suggestion")
    title: str = Field(..., description="Title of the dish")
    context_summary: str = Field(..., description="Context about the dish selection")
    servings: Optional[int] = Field(None, ge=1, description="Number of servings")

