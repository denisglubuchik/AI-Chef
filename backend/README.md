# Holodilnik Backend API

Kitchen assistant API for ingredient detection and meal suggestions using OpenAI Agents SDK.

## Architecture

The backend follows a simplified clean architecture pattern:

```
backend/
├── app/
│   ├── main.py              # FastAPI application factory
│   ├── config.py            # Settings and configuration
│   ├── core/                # Core infrastructure
│   │   ├── dependencies.py  # Dependency injection
│   │   ├── exceptions.py    # Custom exceptions
│   │   └── middleware.py    # Error handling middleware
│   ├── models/              # Data models
│   │   ├── api.py          # API request/response schemas
│   │   └── domain.py       # Domain/business models
│   ├── services/            # Business logic
│   │   ├── openai_client.py    # OpenAI client wrapper
│   │   ├── agent_service.py    # Agent orchestration
│   │   └── image_service.py    # Image validation
│   ├── api/                 # API routes
│   │   └── routes.py       # API endpoints
│   └── utils/               # Utilities
│       └── logging.py      # Logging configuration
└── main.py                  # Entry point
```

## Key Features

✅ **Dependency Injection** - No global state, proper DI with FastAPI  
✅ **Error Handling** - Custom exceptions with detailed error responses  
✅ **Logging** - Structured logging throughout the application  
✅ **Validation** - Image validation and request validation  
✅ **Type Safety** - Full type hints with Pydantic models  

## Setup

1. **Install dependencies:**
   ```bash
   cd backend
   uv sync
   ```

2. **Configure environment:**
   Create a `.env` file with:
   ```
   OPENAI_API_KEY=your-key-here
   OPENAI_BASE_URL=https://api.openai.com/v1
   AGENT_MODEL=gpt-4o
   ```

3. **Run the server:**
   ```bash
   # From the backend directory
   uvicorn main:app --reload
   # Or use uv
   uv run uvicorn main:app --reload
   ```

## API Endpoints

### Extract Ingredients
```
POST /api/v1/extract-ingredients
Content-Type: multipart/form-data

- image: file (required)
```

### Suggest Meals
```
POST /api/v1/suggest-meals
Content-Type: application/json

{
  "ingredients": ["томат", "курица", "рис"],
  "servings": 2,
  "dietary_preferences": ["без глютена"]
}
```

### Build Recipe
```
POST /api/v1/build-recipe
Content-Type: application/json

{
  "suggestion_id": "uuid",
  "title": "Куриное ризотто",
  "context_summary": "Легкое блюдо с курицей и овощами",
  "servings": 2
}
```

### Combined Endpoint
```
POST /api/v1/extract-and-suggest
Content-Type: multipart/form-data

- image: file (required)
- servings: int (optional)
- dietary_preferences: string (optional, comma-separated)
```

### Health Check
```
GET /health
```

## Configuration

All configuration is managed through environment variables in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | Required |
| `OPENAI_BASE_URL` | OpenAI API base URL | `https://api.openai.com/v1` |
| `AGENT_MODEL` | Model to use | `gpt-4o` |
| `OPENAI_TIMEOUT` | Request timeout (seconds) | `60` |
| `MAX_IMAGE_SIZE_MB` | Max image size | `20` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `DEBUG` | Debug mode | `false` |

## Development

The architecture is designed for:
- **Testability**: All dependencies are injected, making mocking easy
- **Maintainability**: Clear separation of concerns
- **Scalability**: Easy to add new features or endpoints
- **Type Safety**: Full type coverage with Pydantic

## Error Handling

The API returns structured error responses:

```json
{
  "error": "ImageValidationError",
  "message": "Image too large: 25.3MB (max: 20MB)",
  "details": {
    "size_bytes": 26542080,
    "max_bytes": 20971520
  }
}
```

## Logging

Structured logging is configured automatically. All requests and errors are logged with context:

```
2024-01-15 10:30:45 - app.api.routes - INFO - Extracting ingredients from image: fridge.jpg
2024-01-15 10:30:52 - app.api.routes - INFO - Successfully extracted 12 ingredients
```

