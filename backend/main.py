from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.api import agent_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager for startup/shutdown logic."""
    # Startup
    yield


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Holodilnik API",
        description="Kitchen assistant API for ingredient detection and meal suggestions",
        version="0.1.0",
        lifespan=lifespan,
    )

    # Configure CORS for Flutter mobile app
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # In production, specify exact origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(agent_router)

    return app


app = create_app()


@app.get("/health")
async def health_check():
    return {"status": "healthy"}