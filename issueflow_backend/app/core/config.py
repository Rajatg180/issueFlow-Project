from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """
    Settings class reads environment variables and exposes them as attributes.

    Why?
    - Keeps config in one place
    - Avoids hardcoding secrets in code
    - Works for local/dev/prod by just changing env vars
    """

    app_name: str = "IssueFlow API"
    env: str = "dev"

    # DB URL will be read from .env (DATABASE_URL)
    database_url: str

    # JWT config (will be used in auth steps)
    jwt_secret: str
    jwt_algorithm: str = "HS256"

    # Expiry settings
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 14

    class Config:
        # Tells Pydantic where to read env vars from
        env_file = ".env"

# Create a singleton Settings object we can import anywhere
settings = Settings()
