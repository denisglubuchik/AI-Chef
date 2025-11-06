from __future__ import annotations

import base64
import json
from typing import Iterable, Optional

from agents import Agent, OpenAIResponsesModel, function_tool
from openai import AsyncOpenAI

from backend.agent.schemas import (
    ExtractIngredientsResult,
    RecipeRequest,
    RecipeResult,
    SuggestionRequest,
    SuggestionsResult,
)


class HolodilnikAgentService:
    """Service for ingredient detection and meal suggestions using OpenAI Agents SDK."""

    def __init__(self, client: AsyncOpenAI, model: OpenAIResponsesModel) -> None:
        """
        Initialize the service with custom client and model.
        
        Args:
            client: Configured AsyncOpenAI client with custom base_url
            model: OpenAIResponsesModel with custom client configured
        """
        # Build tools using the custom client
        tools = self._build_tools(client, model)
        
        # Create agent with custom model and tools
        self._agent = Agent(
            name="Holodilnik Kitchen Assistant",
            model=model,
            instructions=(
                "Use the provided tools to analyze fridge photos, craft meal suggestions, "
                "and expand any selected dish into a detailed recipe. "
                "Always return valid JSON that matches the schema expected for the request."
            ),
            tools=tools,
        )

    @staticmethod
    def _encode_image(image_bytes: bytes) -> str:
        return base64.b64encode(image_bytes).decode("utf-8")

    def _build_tools(self, client: AsyncOpenAI, model: OpenAIResponsesModel) -> list:
        """Build tools that use the custom client."""
        # Use the client directly and get model name from model
        model_name = model.model
        
        def _schema(model_cls):
            schema = model_cls.model_json_schema()
            # Add additionalProperties: false to all objects in schema for compatibility
            def add_additional_properties(obj):
                if isinstance(obj, dict):
                    if obj.get("type") == "object":
                        obj["additionalProperties"] = False
                    for value in obj.values():
                        add_additional_properties(value)
                elif isinstance(obj, list):
                    for item in obj:
                        add_additional_properties(item)
            
            add_additional_properties(schema)
            
            return {
                "type": "json_schema",
                "json_schema": {
                    "name": model_cls.__name__,
                    "schema": schema,
                    "strict": False,  # ProxyAPI doesn't support strict mode
                },
            }
        
        @function_tool
        async def vision_ingredient_extractor(image_base64: str) -> dict:
            """Extracts ingredients from a fridge photo and returns structured detection results."""
            base64.b64decode(image_base64, validate=True)
            
            response = await client.chat.completions.create(
                model=model_name,
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
            return ExtractIngredientsResult.model_validate_json(response.choices[0].message.content).model_dump()

        @function_tool
        async def dish_suggester(
            ingredients: list[str],
            servings: Optional[int] = None,
            dietary_preferences: Optional[list[str]] = None,
        ) -> dict:
            """Creates 3-5 dish suggestions given a list of ingredients and optional preferences."""
            request = SuggestionRequest(
                ingredients=ingredients,
                servings=servings,
                dietary_preferences=dietary_preferences,
            )
            
            response = await client.chat.completions.create(
                model=model_name,
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
            return SuggestionsResult.model_validate_json(response.choices[0].message.content).model_dump()

        @function_tool
        async def recipe_writer(
            suggestion_id: str,
            title: str,
            context_summary: Optional[str] = None,
            servings: Optional[int] = None,
        ) -> dict:
            """Expands a selected dish into a detailed recipe."""
            request = RecipeRequest(
                suggestion_id=suggestion_id,
                title=title,
                context_summary=context_summary,
                servings=servings,
            )
            
            response = await client.chat.completions.create(
                model=model_name,
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
            return RecipeResult.model_validate_json(response.choices[0].message.content).model_dump()

        return [vision_ingredient_extractor, dish_suggester, recipe_writer]

    async def extract_from_photo(self, image_bytes: bytes) -> ExtractIngredientsResult:
        """Extract ingredients from fridge photo - calls tool directly."""
        image_base64 = self._encode_image(image_bytes)
        # Call tool directly, bypassing Runner
        tool = self._agent.tools[0]  # vision_ingredient_extractor
        result_dict = await tool.on_invoke_tool(None, json.dumps({"image_base64": image_base64}))
        return ExtractIngredientsResult.model_validate(result_dict)

    async def suggest_meals(
        self,
        ingredients: Iterable[str],
        servings: Optional[int],
        dietary_preferences: Optional[list[str]],
    ) -> SuggestionsResult:
        """Generate meal suggestions - calls tool directly."""
        # Call tool directly, bypassing Runner
        tool = self._agent.tools[1]  # dish_suggester
        args = {
            "ingredients": list(ingredients),
            "servings": servings,
            "dietary_preferences": dietary_preferences,
        }
        result_dict = await tool.on_invoke_tool(None, json.dumps(args))
        return SuggestionsResult.model_validate(result_dict)

    async def build_recipe(self, request: RecipeRequest) -> RecipeResult:
        """Build detailed recipe - calls tool directly."""
        # Call tool directly, bypassing Runner
        tool = self._agent.tools[2]  # recipe_writer
        args = {
            "suggestion_id": request.suggestion_id,
            "title": request.title,
            "context_summary": request.context_summary,
            "servings": request.servings,
        }
        result_dict = await tool.on_invoke_tool(None, json.dumps(args))
        return RecipeResult.model_validate(result_dict)
