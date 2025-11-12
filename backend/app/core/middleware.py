import logging
from fastapi import Request, status
from fastapi.responses import JSONResponse

from app.core.exceptions import HolodilnikException, ImageValidationError, AIServiceError

logger = logging.getLogger(__name__)


async def holodilnik_exception_handler(request: Request, exc: HolodilnikException) -> JSONResponse:
    """
    Handle custom Holodilnik exceptions.
    
    Args:
        request: The request that caused the exception
        exc: The exception instance
        
    Returns:
        JSON response with error details
    """
    logger.error(
        f"Application error: {exc.__class__.__name__}: {exc.message}",
        extra={
            "path": request.url.path,
            "method": request.method,
            "details": exc.details,
        }
    )
    
    # Determine status code based on exception type
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    if isinstance(exc, ImageValidationError):
        status_code = status.HTTP_400_BAD_REQUEST
    elif isinstance(exc, AIServiceError):
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    
    return JSONResponse(
        status_code=status_code,
        content={
            "error": exc.__class__.__name__,
            "message": exc.message,
            "details": exc.details,
        }
    )

