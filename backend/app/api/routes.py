import logging
from fastapi import APIRouter, File, Form, UploadFile
from typing import Optional

from app.core.dependencies import AgentServiceDep, ImageServiceDep
from app.models.api import SuggestMealsRequest, BuildRecipeRequest
from app.models.domain import ExtractIngredientsResult, SuggestionsResult, RecipeResult

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["recipes"])


@router.post("/extract-ingredients", response_model=ExtractIngredientsResult)
async def extract_ingredients(
    image: UploadFile = File(..., description="Photo of fridge or ingredients"),
    agent_service: AgentServiceDep = None,
    image_service: ImageServiceDep = None,
) -> ExtractIngredientsResult:
    """
    Extract ingredients from a fridge photo using vision AI.
    
    Args:
        image: Uploaded image file
        agent_service: Injected agent service
        image_service: Injected image service
        
    Returns:
        Structured result with detected ingredients
    """
    logger.info(f"Extracting ingredients from image: {image.filename}")
    
    # Validate and read image
    image_bytes = await image_service.validate_and_read(image)
    
    # Extract ingredients
    result = await agent_service.extract_ingredients(image_bytes)
    
    logger.info(f"Successfully extracted {len(result.ingredients)} ingredients")
    return result


@router.post("/suggest-meals", response_model=SuggestionsResult)
async def suggest_meals(
    request: SuggestMealsRequest,
    agent_service: AgentServiceDep = None,
) -> SuggestionsResult:
    """
    Generate meal suggestions based on available ingredients.
    
    Args:
        request: Request with ingredients and preferences
        agent_service: Injected agent service
        
    Returns:
        List of suggested dishes with descriptions
    """
    logger.info(f"Generating meal suggestions for {len(request.ingredients)} ingredients")
    
    result = await agent_service.suggest_meals(
        ingredients=request.ingredients,
        servings=request.servings,
        dietary_preferences=request.dietary_preferences,
    )
    
    logger.info(f"Successfully generated {len(result.dishes)} suggestions")
    return result


@router.post("/build-recipe", response_model=RecipeResult)
async def build_recipe(
    request: BuildRecipeRequest,
    agent_service: AgentServiceDep = None,
) -> RecipeResult:
    """
    Build a detailed recipe for a selected dish.
    
    Args:
        request: Recipe request with dish details
        agent_service: Injected agent service
        
    Returns:
        Detailed recipe with steps and ingredients
    """
    logger.info(f"Building recipe for: {request.title}")
    
    result = await agent_service.build_recipe(
        suggestion_id=request.suggestion_id,
        title=request.title,
        context_summary=request.context_summary,
        servings=request.servings,
    )
    
    logger.info(f"Successfully built recipe with {len(result.steps)} steps")
    return result


@router.post("/extract-and-suggest")
async def extract_and_suggest(
    image: UploadFile = File(..., description="Photo of fridge or ingredients"),
    servings: Optional[int] = Form(None, ge=1),
    dietary_preferences: Optional[str] = Form(None, description="Comma-separated dietary preferences"),
    agent_service: AgentServiceDep = None,
    image_service: ImageServiceDep = None,
) -> dict:
    """
    Combined endpoint: extract ingredients from photo and immediately suggest meals.
    
    This is a convenience endpoint for mobile clients to reduce round trips.
    
    Args:
        image: Uploaded image file
        servings: Number of servings (optional)
        dietary_preferences: Comma-separated dietary preferences (optional)
        agent_service: Injected agent service
        image_service: Injected image service
        
    Returns:
        Dict with both extraction results and meal suggestions
    """
    logger.info("Processing combined extract-and-suggest request")
    
    # Extract ingredients
    extraction_result = await extract_ingredients(agent_service, image_service, image)
    
    # Parse dietary preferences
    preferences_list = None
    if dietary_preferences:
        preferences_list = [p.strip() for p in dietary_preferences.split(",") if p.strip()]
    
    # Get meal suggestions
    ingredient_names = [ing.name for ing in extraction_result.ingredients]
    suggestions_result = await agent_service.suggest_meals(
        ingredients=ingredient_names,
        servings=servings,
        dietary_preferences=preferences_list,
    )
    
    logger.info("Successfully completed combined extract-and-suggest request")
    
    return {
        "extraction": extraction_result.model_dump(),
        "suggestions": suggestions_result.model_dump(),
    }

