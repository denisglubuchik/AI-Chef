from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.core.exceptions import HolodilnikException
from app.core.middleware import holodilnik_exception_handler
from app.api.routes import router
from app.utils.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown logic."""
    settings = get_settings()
    
    # Setup logging
    setup_logging(settings.log_level)
    
    # Startup
    yield
    
    # Shutdown (if needed)


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    settings = get_settings()
    
    app = FastAPI(
        title=settings.app_name,
        description="Kitchen assistant API for ingredient detection and meal suggestions",
        version=settings.app_version,
        debug=settings.debug,
        lifespan=lifespan,
    )
    
    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Add exception handlers
    app.add_exception_handler(HolodilnikException, holodilnik_exception_handler)
    
    # Include routers
    app.include_router(router)
    
    # Health check endpoint
    @app.get("/health")
    async def health_check():
        """Health check endpoint."""
        return {
            "status": "healthy",
            "version": settings.app_version,
        }
    
    return app


app = create_app()

