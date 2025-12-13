from sqlmodel import create_engine, Session
from app.core.config import settings

# Engine is the DB connection factory
engine = create_engine(settings.database_url, echo=False, pool_pre_ping=True)


def get_db():
    """
    FastAPI dependency: provides one DB session per request.
    """
    with Session(engine) as session:
        yield session
