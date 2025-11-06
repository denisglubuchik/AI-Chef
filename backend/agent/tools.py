from __future__ import annotations

import base64
from typing import Any, Dict, List, Optional

from agents import Tool, function_tool
from agents import OpenAIResponsesModel
from openai import AsyncOpenAI

from backend.agent.config import AgentModelConfig
from backend.agent.schemas import (
    ExtractIngredientsResult,
    RecipeRequest,
    RecipeResult,
    SuggestionRequest,
    SuggestionsResult,
)


def _schema(model_cls) -> Dict[str, Any]:
    """Return the JSON schema used by the OpenAI structured outputs."""

    return {
        "type": "json_schema",
        "json_schema": {
            "name": model_cls.__name__,
            "schema": model_cls.model_json_schema(),
            "strict": True,
        },
    }


def build_tools(client: AsyncOpenAI, model: OpenAIResponsesModel) -> List[Tool]:
    """Construct the list of tools attached to the Holodilnik agent."""

    @function_tool(
        name_override="vision_ingredient_extractor",
        description_override=(
            "Extracts ingredients from a fridge photo and returns structured detection results."
        ),
        strict_mode=True,
    )
    async def _vision_executor(image_base64: str) -> Dict[str, Any]:
        """Extract ingredients detected in the provided fridge photo."""
        # Decode to ensure the payload is valid before sending downstream.
        base64.b64decode(image_base64, validate=True)
        
        response = await client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Extract every edible ingredient you can identify in the image. "
                        "Return structured JSON that matches the ExtractIngredientsResult schema."
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Analyze this fridge photo."},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"},
                        },
                    ],
                },
            ],
            response_format=_schema(ExtractIngredientsResult),
        )
        
        json_text = response.choices[0].message.content
        return ExtractIngredientsResult.model_validate_json(json_text).model_dump()

    @function_tool(
        name_override="dish_suggester",
        description_override=(
            "Creates 3-5 dish suggestions given a list of ingredients and optional preferences."
        ),
        strict_mode=True,
    )
    async def _suggestions_executor(
        ingredients: List[str],
        servings: Optional[int] = None,
        dietary_preferences: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Propose meals that rely on the provided ingredients list."""
        request = SuggestionRequest(
            ingredients=ingredients,
            servings=servings,
            dietary_preferences=dietary_preferences,
        )
        
        response = await client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Suggest between three and five realistic dishes. "
                        "Focus on dishes that primarily use provided ingredients."
                    ),
                },
                {
                    "role": "user",
                    "content": request.model_dump_json(),
                },
            ],
            response_format=_schema(SuggestionsResult),
        )
        
        json_text = response.choices[0].message.content
        return SuggestionsResult.model_validate_json(json_text).model_dump()

    @function_tool(
        name_override="recipe_writer",
        description_override="Expands a selected dish into a detailed recipe.",
        strict_mode=True,
    )
    async def _recipe_executor(
        suggestion_id: str,
        title: str,
        context_summary: Optional[str] = None,
        servings: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Generate a full recipe for the chosen dish suggestion."""
        request = RecipeRequest(
            suggestion_id=suggestion_id,
            title=title,
            context_summary=context_summary,
            servings=servings,
        )
        
        response = await client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "Generate a complete recipe with precise ingredient quantities, "
                        "preparation steps, equipment, and realistic timings."
                    ),
                },
                {
                    "role": "user",
                    "content": request.model_dump_json(),
                },
            ],
            response_format=_schema(RecipeResult),
        )
        
        json_text = response.choices[0].message.content
        return RecipeResult.model_validate_json(json_text).model_dump()

    return [_vision_executor, _suggestions_executor, _recipe_executor]
