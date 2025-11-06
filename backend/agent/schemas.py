from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class DetectedIngredient(BaseModel):
    """Single ingredient detected on a fridge image."""

    name: str
    confidence: float = Field(ge=0.0, le=1.0)
    notes: Optional[str] = None


class ExtractIngredientsResult(BaseModel):
    """Structured response produced by the vision tool."""

    ingredients: List[DetectedIngredient]
    unsure_items: List[str] = Field(default_factory=list)
    spoiled_items: List[str] = Field(default_factory=list)


class SuggestionRequest(BaseModel):
    """Payload passed to the suggestion tool."""

    ingredients: List[str]
    servings: Optional[int] = Field(default=None, ge=1)
    dietary_preferences: Optional[List[str]] = None


class DishSummary(BaseModel):
    """Short representation of a suggested dish used on the mobile client."""

    suggestion_id: str
    title: str
    short_description: str
    estimated_time_minutes: int = Field(ge=1)
    confidence: float = Field(ge=0.0, le=1.0)


class SuggestionsResult(BaseModel):
    """Structured output from the suggestion tool."""

    dishes: List[DishSummary]


class RecipeRequest(BaseModel):
    """Payload describing which dish to expand into a recipe."""

    suggestion_id: str
    title: str
    context_summary: str
    servings: Optional[int] = None


class RecipeIngredient(BaseModel):
    """Single ingredient entry used in the final detailed recipe."""

    ingredient: str
    quantity: str
    preparation: Optional[str] = None


class RecipeStep(BaseModel):
    """Single preparation instruction."""

    number: int = Field(ge=1)
    instruction: str
    tip: Optional[str] = None


class RecipeResult(BaseModel):
    """Structured output returned by the recipe tool."""

    suggestion_id: str
    title: str
    servings: Optional[int] = None
    prep_time_minutes: int = Field(ge=0)
    cook_time_minutes: int = Field(ge=0)
    ingredients: List[RecipeIngredient]
    steps: List[RecipeStep]
    equipment: List[str] = Field(default_factory=list)


def build_recipe_request(
    summary: DishSummary,
    context_summary: str,
    servings: Optional[int],
) -> RecipeRequest:
    """Helper for creating recipe requests from suggestion selections."""

    return RecipeRequest(
        suggestion_id=summary.suggestion_id,
        title=summary.title,
        context_summary=context_summary,
        servings=servings,
    )
