
from fastapi import APIRouter, Depends,HTTPException
from sqlmodel import Session 


from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.project import ProjectCreateRequest, ProjectResponse
from app.services.project_service import create_project, list_projects


router = APIRouter(prefix="/projects",tags=["Projects"])



@router.post("", response_model=ProjectResponse)
def create(payload: ProjectCreateRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        p = create_project(db, owner=user, name=payload.name, key=payload.key, description=payload.description)
        return ProjectResponse(id=str(p.id), name=p.name, key=p.key, description=p.description)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("", response_model=list[ProjectResponse])
def list_all(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    projects = list_projects(db, owner=user)
    return [ProjectResponse(id=str(p.id), name=p.name, key=p.key, description=p.description) for p in projects]
