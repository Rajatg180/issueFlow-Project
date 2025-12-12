from fastapi import FastAPI
from app.core.config import settings

# Create the FastAPI app object
# title shows in Swagger docs (/docs)
app = FastAPI(title=settings.app_name)

@app.get("/health")
def health():
    """
    Health check endpoint:

    Why?
    - Lets you verify server is running
    - Useful for CI/CD + deployment health checks
    """
    return {"status": "ok", "service": settings.app_name}
