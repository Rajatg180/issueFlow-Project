from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

# Engine is the core SQLAlchemy object that knows how to connect to DB.
# pool_pre_ping=True prevents stale connections in long-running servers.
engine = create_engine(settings.database_url, pool_pre_ping=True)

# SessionLocal is a "factory" to create DB sessions.
# autocommit=False => we manually commit (safer)
# autoflush=False => we control when DB flush happens
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """
    FastAPI Dependency:

    Why?
    - Each request gets its own DB session
    - session is closed after request ends (prevents connection leaks)

    Usage later:
      def route(db: Session = Depends(get_db)):
          ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
