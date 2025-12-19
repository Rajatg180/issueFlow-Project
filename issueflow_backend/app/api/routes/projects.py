from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.project import (
    ProjectCreateRequest,
    ProjectResponse,
    ProjectPreferenceUpdateRequest,
)
from app.services.project_service import (
    create_project,
    delete_project,
    list_projects,
    update_project_preference,
)

router = APIRouter(prefix="/projects", tags=["Projects"])


@router.post("", response_model=ProjectResponse)
def create(payload: ProjectCreateRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        p = create_project(db, owner=user, name=payload.name, key=payload.key, description=payload.description)
        return ProjectResponse(
            id=str(p.id),
            name=p.name,
            key=p.key,
            description=p.description,
            created_at=p.created_at,
            is_favorite=False,
            is_pinned=False,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("", response_model=list[ProjectResponse])
def list_all(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = list_projects(db, owner=user)

    # Optional Jira-like ordering: pinned first, then favorites, then recent created
    def sort_key(item):
        p, pref = item
        is_pinned = (pref.is_pinned if pref else False)
        is_fav = (pref.is_favorite if pref else False)
        created = p.created_at or 0
        return (not is_pinned, not is_fav, -(created.timestamp() if p.created_at else 0))

    rows.sort(key=sort_key)

    out: list[ProjectResponse] = []
    for p, pref in rows:
        out.append(
            ProjectResponse(
                id=str(p.id),
                name=p.name,
                key=p.key,
                description=p.description,
                created_at=p.created_at,
                is_favorite=(pref.is_favorite if pref else False),
                is_pinned=(pref.is_pinned if pref else False),
            )
        )
    return out


@router.patch("/{project_id}/preference", response_model=ProjectResponse)
def update_preference(
    project_id: str,
    payload: ProjectPreferenceUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        pref = update_project_preference(
            db=db,
            owner=user,
            project_id=project_id,
            is_favorite=payload.is_favorite,
            is_pinned=payload.is_pinned,
        )

        # return updated project view
        # (safe: project exists because service validated)
        # NOTE: if you want, you can fetch project once here; minimal extra query:
        from app.models.project import Project
        project = db.exec(select(Project).where(Project.id == project_id)).first()

        return ProjectResponse(
            id=str(project.id),
            name=project.name,
            key=project.key,
            description=project.description,
            created_at=project.created_at,
            is_favorite=pref.is_favorite,
            is_pinned=pref.is_pinned,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{project_id}")
def remove(project_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        delete_project(db=db, project_id=project_id, owner=user)
        return {"status": "ok"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
