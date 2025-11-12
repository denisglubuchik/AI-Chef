from __future__ import annotations

import uuid
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


class DishSummary(BaseModel):
    """Short representation of a suggested dish."""

    suggestion_id: str
    title: str
    short_description: str
    estimated_time_minutes: int = Field(ge=1)
    confidence: float = Field(ge=0.0, le=1.0)


class SuggestionsResult(BaseModel):
    """Structured output from the suggestion tool."""

    dishes: List[DishSummary]

    @classmethod
    def from_agent_result(cls, agent_dishes: list[dict]) -> SuggestionsResult:
        """Convert agent result to API result by adding suggestion_id."""
        dishes_with_ids = [
            DishSummary(
                suggestion_id=str(uuid.uuid4()),
                title=dish["title"],
                short_description=dish["short_description"],
                estimated_time_minutes=dish["estimated_time_minutes"],
                confidence=dish["confidence"],
            )
            for dish in agent_dishes
        ]
        return cls(dishes=dishes_with_ids)


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

    @classmethod
    def from_agent_result(cls, agent_result: dict, suggestion_id: str) -> RecipeResult:
        """Convert agent result to API result by adding suggestion_id from request."""
        return cls(
            suggestion_id=suggestion_id,
            title=agent_result["title"],
            servings=agent_result.get("servings"),
            prep_time_minutes=agent_result["prep_time_minutes"],
            cook_time_minutes=agent_result["cook_time_minutes"],
            ingredients=[RecipeIngredient(**ing) for ing in agent_result["ingredients"]],
            steps=[RecipeStep(**step) for step in agent_result["steps"]],
            equipment=agent_result.get("equipment", []),
        )

