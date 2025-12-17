from app.db.base import Base
from app.db.session import engine

# IMPORTANT: import models so Base.metadata knows about tables
import app.models.user  # noqa: F401
import app.models.refresh_token  # noqa: F401
import app.models.project
import app.models.issue


def init_db():
    # Creates tables if they do not exist
    Base.metadata.create_all(bind=engine)
