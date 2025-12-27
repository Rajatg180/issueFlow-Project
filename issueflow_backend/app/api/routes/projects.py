from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.schemas.project_issues import ProjectWithIssuesResponse, IssueMiniResponse, UserMini
from app.services.project_issue_service import list_projects_with_issues_and_users
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.project import (
    ProjectCreateRequest,
    ProjectResponse,
    ProjectPreferenceUpdateRequest,
    ProjectUpdateRequest,
)
from app.services.project_service import (
    create_project,
    delete_project,
    list_projects,
    update_project,
    update_project_preference,
)
from app.models.project_member import ProjectRole

router = APIRouter(prefix="/projects", tags=["Projects"])


@router.post("", response_model=ProjectResponse)
def create(
    payload: ProjectCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
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
            role=ProjectRole.owner,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("", response_model=list[ProjectResponse])
def list_all(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = list_projects(db, owner=user)

    def sort_key(item):
        p, pref = item
        is_pinned = (pref.is_pinned if pref else False)
        is_fav = (pref.is_favorite if pref else False)
        return (not is_pinned, not is_fav, -(p.created_at.timestamp() if p.created_at else 0))

    rows.sort(key=sort_key)

    out: list[ProjectResponse] = []
    for p, pref in rows:
        role = ProjectRole.owner if p.owner_id == user.id else ProjectRole.member

        out.append(
            ProjectResponse(
                id=str(p.id),
                name=p.name,
                key=p.key,
                description=p.description,
                created_at=p.created_at,
                is_favorite=(pref.is_favorite if pref else False),
                is_pinned=(pref.is_pinned if pref else False),
                role=role,
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

        from app.models.project import Project
        project = db.exec(select(Project).where(Project.id == project_id)).first()

        role = ProjectRole.owner if project.owner_id == user.id else ProjectRole.member

        return ProjectResponse(
            id=str(project.id),
            name=project.name,
            key=project.key,
            description=project.description,
            created_at=project.created_at,
            is_favorite=pref.is_favorite,
            is_pinned=pref.is_pinned,
            role=role,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    

@router.get("/with-issues", response_model=list[ProjectWithIssuesResponse])
def list_projects_with_all_issues(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        rows = list_projects_with_issues_and_users(db=db, user=user)

        return [
            ProjectWithIssuesResponse(
                id=str(p.id),
                name=p.name,
                key=p.key,
                description=p.description,
                created_at=p.created_at,
                updated_at=p.updated_at,
                role=role,
                issues=[
                    IssueMiniResponse(
                        id=str(i.id),
                        key=i.key,
                        title=i.title,
                        description=i.description,
                        type=i.type,
                        priority=i.priority,
                        status=i.status,
                        due_date=i.due_date,
                        created_at=i.created_at,
                        updated_at=i.updated_at,
                        reporter=UserMini(id=str(reporter.id), username=reporter.username),
                        assignee=(
                            UserMini(id=str(assignee.id), username=assignee.username)
                            if assignee else None
                        ),
                    )
                    for (i, reporter, assignee) in issue_rows
                ],
            )
            for (p, role, issue_rows) in rows
        ]

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{project_id}")
def remove(project_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    try:
        delete_project(db=db, project_id=project_id, owner=user)
        return {"status": "ok"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))



@router.patch("/{project_id}", response_model=ProjectResponse)
def edit_project(
    project_id: str,
    payload: ProjectUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        p = update_project(
            db=db,
            owner=user,
            project_id=project_id,
            name=payload.name,
            key=payload.key,
            description=payload.description,
        )

        # preference info (keep your existing style)
        from app.models.project_preference import ProjectPreference  # if you have it
        pref = db.exec(
            select(ProjectPreference).where(
                ProjectPreference.project_id == p.id,
                ProjectPreference.user_id == user.id,
            )
        ).first()

        role = ProjectRole.owner if str(p.owner_id) == str(user.id) else ProjectRole.member

        return ProjectResponse(
            id=str(p.id),
            name=p.name,
            key=p.key,
            description=p.description,
            created_at=p.created_at,
            is_favorite=(pref.is_favorite if pref else False),
            is_pinned=(pref.is_pinned if pref else False),
            role=role,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

