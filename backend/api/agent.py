"""API routes for the Holodilnik kitchen assistant agent."""

from typing import List, Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

from backend.agent.schemas import (
    ExtractIngredientsResult,
    RecipeResult,
    SuggestionsResult,
)
from backend.api.dependencies import AgentService

router = APIRouter(prefix="/agent", tags=["agent"])


# Request/Response models for API endpoints
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


@router.get("/extract-ingredients", response_model=ExtractIngredientsResult)
async def extract_ingredients(
    agent_service: AgentService,
    image: UploadFile = File(..., description="Photo of fridge or ingredients"),
) -> ExtractIngredientsResult:
    """
    Extract ingredients from a fridge photo using vision AI.
    
    Args:
        agent_service: Injected agent service
        image: Uploaded image file
        
    Returns:
        Structured result with detected ingredients
        
    Raises:
        HTTPException: If image processing fails
    """
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Expected image, got {image.content_type}"
        )
    
    try:
        image_bytes = await image.read()
        
        if len(image_bytes) > 20 * 1024 * 1024:  # 20MB limit
            raise HTTPException(
                status_code=400,
                detail="Image file too large. Maximum size is 20MB."
            )
            
        result = await agent_service.extract_from_photo(image_bytes)
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process image: {str(e)}"
        )


@router.get("/suggest-meals", response_model=SuggestionsResult)
async def suggest_meals(
    request: SuggestMealsRequest,
    agent_service: AgentService,
) -> SuggestionsResult:
    """
    Generate meal suggestions based on available ingredients.
    
    Args:
        request: Request with ingredients and preferences
        agent_service: Injected agent service
        
    Returns:
        List of suggested dishes with descriptions
        
    Raises:
        HTTPException: If suggestion generation fails
    """
    try:
        result = await agent_service.suggest_meals(
            ingredients=request.ingredients,
            servings=request.servings,
            dietary_preferences=request.dietary_preferences,
        )
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate meal suggestions: {str(e)}"
        )


@router.get("/build-recipe", response_model=RecipeResult)
async def build_recipe(
    request: BuildRecipeRequest,
    agent_service: AgentService,
) -> RecipeResult:
    """
    Build a detailed recipe for a selected dish.
    
    Args:
        request: Recipe request with dish details
        agent_service: Injected agent service
        
    Returns:
        Detailed recipe with steps and ingredients
        
    Raises:
        HTTPException: If recipe generation fails
    """
    try:
        from backend.agent.schemas import RecipeRequest
        
        recipe_request = RecipeRequest(
            suggestion_id=request.suggestion_id,
            title=request.title,
            context_summary=request.context_summary,
            servings=request.servings,
        )
        
        result = await agent_service.build_recipe(recipe_request)
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to build recipe: {str(e)}"
        )


# Combined endpoint for mobile app convenience
@router.get("/extract-and-suggest")
async def extract_and_suggest(
    agent_service: AgentService,
    image: UploadFile = File(..., description="Photo of fridge or ingredients"),
    servings: Optional[int] = Form(None, ge=1),
    dietary_preferences: Optional[str] = Form(None, description="Comma-separated dietary preferences"),
) -> dict:
    """
    Combined endpoint: extract ingredients from photo and immediately suggest meals.
    
    This is a convenience endpoint for mobile clients to reduce round trips.
    
    Args:
        agent_service: Injected agent service
        image: Uploaded image file
        servings: Number of servings (optional)
        dietary_preferences: Comma-separated dietary preferences (optional)
        
    Returns:
        Dict with both extraction results and meal suggestions
    """
    # Extract ingredients
    extraction_result = await extract_ingredients(agent_service, image)
    
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
    
    return {
        "extraction": extraction_result.model_dump(),
        "suggestions": suggestions_result.model_dump(),
    }

