"""Custom application exceptions."""


class HolodilnikException(Exception):
    """Base exception for all custom exceptions."""
    
    def __init__(self, message: str, details: dict | None = None):
        self.message = message
        self.details = details or {}
        super().__init__(message)


class ImageValidationError(HolodilnikException):
    """Raised when image validation fails."""
    pass


class AIServiceError(HolodilnikException):
    """Raised when AI service encounters an error."""
    pass

