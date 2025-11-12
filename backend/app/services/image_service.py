from fastapi import UploadFile

from app.config import Settings
from app.core.exceptions import ImageValidationError


class ImageService:
    """Handle image validation and processing."""
    
    def __init__(self, settings: Settings):
        """Initialize image service with settings."""
        self.max_size = settings.max_image_size_mb * 1024 * 1024
        self.allowed_types = settings.allowed_image_types
    
    async def validate_and_read(self, file: UploadFile) -> bytes:
        """
        Validate image and return bytes.
        
        Args:
            file: Uploaded image file
            
        Returns:
            Image bytes
            
        Raises:
            ImageValidationError: If validation fails
        """
        # Validate content type
        if not file.content_type or not file.content_type.startswith("image/"):
            raise ImageValidationError(
                f"Invalid file type: {file.content_type}",
                details={"content_type": file.content_type}
            )
        
        # Check if type is allowed
        if file.content_type not in self.allowed_types:
            raise ImageValidationError(
                f"Image type not allowed: {file.content_type}",
                details={
                    "content_type": file.content_type,
                    "allowed_types": self.allowed_types
                }
            )
        
        # Read and validate size
        data = await file.read()
        if len(data) > self.max_size:
            size_mb = len(data) / 1024 / 1024
            max_mb = self.max_size / 1024 / 1024
            raise ImageValidationError(
                f"Image too large: {size_mb:.1f}MB (max: {max_mb:.0f}MB)",
                details={"size_bytes": len(data), "max_bytes": self.max_size}
            )
        
        if len(data) == 0:
            raise ImageValidationError("Image file is empty")
        
        return data

