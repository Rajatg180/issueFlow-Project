from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Reads environment variables from `.env` and exposes them as attributes.
    """

    app_name: str = "IssueFlow API"
    env: str = "dev"

    # must exist in .env
    database_url: str

    # JWT config (we’ll use later)
    jwt_secret: str
    jwt_algorithm: str = "HS256"

    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 14

    firebase_service_account_file: str | None = None


    class Config:
        env_file = ".env"
        case_sensitive = False  # allows DATABASE_URL or database_url, etc.


settings = Settings()
