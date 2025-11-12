from __future__ import annotations

import base64
import json
import logging
from typing import Optional

from agents import Agent, function_tool

from app.services.openai_client import OpenAIClient
from app.models.domain import (
    ExtractIngredientsResult,
    SuggestionsResult,
    RecipeResult,
)
from app.core.exceptions import AIServiceError

logger = logging.getLogger(__name__)


class AgentService:
    """Service for ingredient detection and meal suggestions using OpenAI Agents SDK."""

    def __init__(self, openai_client: OpenAIClient):
        """
        Initialize the service with OpenAI client.
        
        Args:
            openai_client: Configured OpenAI client wrapper
        """
        self.openai_client = openai_client
        self._agent: Agent | None = None
    
    def _get_agent(self) -> Agent:
        """Lazy initialization of agent."""
        if self._agent is None:
            tools = self._build_tools()
            self._agent = Agent(
                name="Holodilnik Kitchen Assistant",
                model=self.openai_client.model,
                instructions=(
                    "Ты - кулинарный помощник для русскоязычных пользователей. "
                    "Используй предоставленные инструменты для анализа фотографий холодильника, создания предложений блюд "
                    "и разработки детального рецепта для любого выбранного блюда. "
                    "Всегда возвращай валидный JSON, соответствующий ожидаемой схеме для запроса. "
                    "ВСЕ тексты в ответах должны быть НА РУССКОМ ЯЗЫКЕ."
                ),
                tools=tools,
            )
        return self._agent
    
    def _build_tools(self) -> list:
        """Build tools that use the OpenAI client."""
        client = self.openai_client.client
        model_name = self.openai_client.model_name
        
        def _schema(model_cls):
            """Generate JSON schema for structured output."""
            schema = model_cls.model_json_schema()
            
            # Add additionalProperties: false to all objects for compatibility
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
            try:
                # Validate base64
                base64.b64decode(image_base64, validate=True)
                
                response = await client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": (
                                "Извлеки все съедобные ингредиенты, которые ты можешь определить на изображении. "
                                "Верни структурированный JSON, соответствующий схеме ExtractIngredientsResult. "
                                "ВАЖНО: Все названия ингредиентов, заметки и описания должны быть НА РУССКОМ ЯЗЫКЕ."
                            ),
                        },
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": "Проанализируй это фото холодильника."},
                                {
                                    "type": "image_url",
                                    "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"},
                                },
                            ],
                        },
                    ],
                    response_format=_schema(ExtractIngredientsResult),
                )
                
                result = ExtractIngredientsResult.model_validate_json(
                    response.choices[0].message.content
                )
                return result.model_dump()
                
            except Exception as e:
                logger.error(f"Vision extraction failed: {e}")
                raise AIServiceError(f"Failed to extract ingredients: {str(e)}")

        @function_tool
        async def dish_suggester(
            ingredients: list[str],
            servings: Optional[int] = None,
            dietary_preferences: Optional[list[str]] = None,
        ) -> dict:
            """Creates 3-5 dish suggestions given a list of ingredients and optional preferences."""
            try:
                request_data = {
                    "ingredients": ingredients,
                    "servings": servings,
                    "dietary_preferences": dietary_preferences,
                }
                
                response = await client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": (
                                "Предложи от трёх до пяти реалистичных блюд. "
                                "Сосредоточься на блюдах, которые в основном используют предоставленные ингредиенты. "
                                "ВАЖНО: Все названия блюд и описания должны быть НА РУССКОМ ЯЗЫКЕ."
                            ),
                        },
                        {
                            "role": "user",
                            "content": json.dumps(request_data),
                        },
                    ],
                    response_format={
                        "type": "json_schema",
                        "json_schema": {
                            "name": "DishSuggestions",
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "dishes": {
                                        "type": "array",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "title": {"type": "string"},
                                                "short_description": {"type": "string"},
                                                "estimated_time_minutes": {"type": "integer"},
                                                "confidence": {"type": "number"},
                                            },
                                            "required": ["title", "short_description", "estimated_time_minutes", "confidence"],
                                            "additionalProperties": False,
                                        },
                                    },
                                },
                                "required": ["dishes"],
                                "additionalProperties": False,
                            },
                            "strict": False,
                        },
                    },
                )
                
                result = json.loads(response.choices[0].message.content)
                return result
                
            except Exception as e:
                logger.error(f"Dish suggestion failed: {e}")
                raise AIServiceError(f"Failed to generate suggestions: {str(e)}")

        @function_tool
        async def recipe_writer(
            title: str,
            context_summary: Optional[str] = None,
            servings: Optional[int] = None,
        ) -> dict:
            """Expands a selected dish into a detailed recipe."""
            try:
                request_data = {
                    "title": title,
                    "context_summary": context_summary,
                    "servings": servings,
                }
                
                response = await client.chat.completions.create(
                    model=model_name,
                    messages=[
                        {
                            "role": "system",
                            "content": (
                                "Сгенерируй полный рецепт с точными количествами ингредиентов, "
                                "шагами приготовления, оборудованием и реалистичным временем. "
                                "ВАЖНО: Весь рецепт (ингредиенты, инструкции, советы, оборудование) должен быть НА РУССКОМ ЯЗЫКЕ."
                            ),
                        },
                        {
                            "role": "user",
                            "content": json.dumps(request_data),
                        },
                    ],
                    response_format={
                        "type": "json_schema",
                        "json_schema": {
                            "name": "Recipe",
                            "schema": {
                                "type": "object",
                                "properties": {
                                    "title": {"type": "string"},
                                    "servings": {"type": ["integer", "null"]},
                                    "prep_time_minutes": {"type": "integer"},
                                    "cook_time_minutes": {"type": "integer"},
                                    "ingredients": {
                                        "type": "array",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "ingredient": {"type": "string"},
                                                "quantity": {"type": "string"},
                                                "preparation": {"type": ["string", "null"]},
                                            },
                                            "required": ["ingredient", "quantity"],
                                            "additionalProperties": False,
                                        },
                                    },
                                    "steps": {
                                        "type": "array",
                                        "items": {
                                            "type": "object",
                                            "properties": {
                                                "number": {"type": "integer"},
                                                "instruction": {"type": "string"},
                                                "tip": {"type": ["string", "null"]},
                                            },
                                            "required": ["number", "instruction"],
                                            "additionalProperties": False,
                                        },
                                    },
                                    "equipment": {"type": "array", "items": {"type": "string"}},
                                },
                                "required": ["title", "prep_time_minutes", "cook_time_minutes", "ingredients", "steps"],
                                "additionalProperties": False,
                            },
                            "strict": False,
                        },
                    },
                )
                
                result = json.loads(response.choices[0].message.content)
                return result
                
            except Exception as e:
                logger.error(f"Recipe generation failed: {e}")
                raise AIServiceError(f"Failed to build recipe: {str(e)}")

        return [vision_ingredient_extractor, dish_suggester, recipe_writer]

    @staticmethod
    def _encode_image(image_bytes: bytes) -> str:
        """Encode image bytes to base64."""
        return base64.b64encode(image_bytes).decode("utf-8")

    async def extract_ingredients(self, image_bytes: bytes) -> ExtractIngredientsResult:
        """
        Extract ingredients from fridge photo.
        
        Args:
            image_bytes: Image data
            
        Returns:
            Extraction result with detected ingredients
            
        Raises:
            AIServiceError: If extraction fails
        """
        try:
            image_base64 = self._encode_image(image_bytes)
            agent = self._get_agent()
            tool = agent.tools[0]  # vision_ingredient_extractor
            result_dict = await tool.on_invoke_tool(None, json.dumps({"image_base64": image_base64}))
            return ExtractIngredientsResult.model_validate(result_dict)
        except AIServiceError:
            raise
        except Exception as e:
            logger.error(f"Ingredient extraction failed: {e}")
            raise AIServiceError(f"Failed to extract ingredients: {str(e)}")

    async def suggest_meals(
        self,
        ingredients: list[str],
        servings: Optional[int] = None,
        dietary_preferences: Optional[list[str]] = None,
    ) -> SuggestionsResult:
        """
        Generate meal suggestions.
        
        Args:
            ingredients: List of available ingredients
            servings: Number of servings
            dietary_preferences: Dietary restrictions
            
        Returns:
            Suggestions with dish summaries
            
        Raises:
            AIServiceError: If suggestion generation fails
        """
        try:
            agent = self._get_agent()
            tool = agent.tools[1]  # dish_suggester
            args = {
                "ingredients": ingredients,
                "servings": servings,
                "dietary_preferences": dietary_preferences,
            }
            result_dict = await tool.on_invoke_tool(None, json.dumps(args))
            return SuggestionsResult.from_agent_result(result_dict["dishes"])
        except AIServiceError:
            raise
        except Exception as e:
            logger.error(f"Meal suggestion failed: {e}")
            raise AIServiceError(f"Failed to generate meal suggestions: {str(e)}")

    async def build_recipe(
        self,
        suggestion_id: str,
        title: str,
        context_summary: str,
        servings: Optional[int] = None,
    ) -> RecipeResult:
        """
        Build detailed recipe.
        
        Args:
            suggestion_id: ID of the selected suggestion
            title: Dish title
            context_summary: Context about the selection
            servings: Number of servings
            
        Returns:
            Detailed recipe with steps
            
        Raises:
            AIServiceError: If recipe generation fails
        """
        try:
            agent = self._get_agent()
            tool = agent.tools[2]  # recipe_writer
            args = {
                "title": title,
                "context_summary": context_summary,
                "servings": servings,
            }
            result_dict = await tool.on_invoke_tool(None, json.dumps(args))
            return RecipeResult.from_agent_result(result_dict, suggestion_id)
        except AIServiceError:
            raise
        except Exception as e:
            logger.error(f"Recipe building failed: {e}")
            raise AIServiceError(f"Failed to build recipe: {str(e)}")

