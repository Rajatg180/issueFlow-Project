from app.db.base import Base
from app.db.session import engine

# IMPORTANT: import models so Base.metadata knows about tables
import app.models.user
import app.models.refresh_token 
import app.models.project
import app.models.issue
import app.models.project_member  
import app.models.project_invite
import app.models.issue_comment  

def init_db():
    # Creates tables if they do not exist
    Base.metadata.create_all(bind=engine)
