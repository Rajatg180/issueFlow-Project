from __future__ import annotations
from datetime import datetime
from sqlmodel import Session, select

from app.models.issue import Issue
from app.models.project import Project
from app.models.project_preference import ProjectPreference
from app.models.user import User


def create_project(db: Session, owner: User, name: str, key: str, description: str | None) -> Project:
    key = key.strip().upper()

    existing = db.exec(select(Project).where(Project.key == key)).first()
    if existing:
        raise ValueError("Project key already exists. Choose another key.")

    p = Project(
        owner_id=owner.id,
        name=name.strip(),
        key=key,
        description=description,
        issue_seq=0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(p)
    db.commit()
    db.refresh(p)

    # ✅ Ensure preference row exists (default false/false)
    pref = ProjectPreference(
        user_id=owner.id,
        project_id=p.id,
        is_favorite=False,
        is_pinned=False,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(pref)
    db.commit()

    return p


def list_projects(db: Session, owner: User) -> list[tuple[Project, ProjectPreference | None]]:
    """
    Return list of (Project, Preference) tuples.
    - If pref missing for old rows, preference will be None.
    """
    projects = list(db.exec(select(Project).where(Project.owner_id == owner.id)).all())

    if not projects:
        return []

    ids = [p.id for p in projects]
    prefs = list(
        db.exec(
            select(ProjectPreference).where(
                ProjectPreference.user_id == owner.id,
                ProjectPreference.project_id.in_(ids),
            )
        ).all()
    )

    pref_map = {pref.project_id: pref for pref in prefs}
    return [(p, pref_map.get(p.id)) for p in projects]


def update_project_preference(
    db: Session,
    owner: User,
    project_id: str,
    is_favorite: bool | None = None,
    is_pinned: bool | None = None,
) -> ProjectPreference:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    if project.owner_id != owner.id:
        raise ValueError("You do not have access to this project")

    pref = db.exec(
        select(ProjectPreference).where(
            ProjectPreference.user_id == owner.id,
            ProjectPreference.project_id == project.id,
        )
    ).first()

    # ✅ handle old projects that don't have pref row yet
    if not pref:
        pref = ProjectPreference(
            user_id=owner.id,
            project_id=project.id,
            is_favorite=False,
            is_pinned=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(pref)
        db.commit()
        db.refresh(pref)

    if is_favorite is not None:
        pref.is_favorite = is_favorite
    if is_pinned is not None:
        pref.is_pinned = is_pinned

    pref.updated_at = datetime.utcnow()
    db.add(pref)
    db.commit()
    db.refresh(pref)
    return pref


def delete_project(db: Session, project_id: str, owner: User) -> None:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    if project.owner_id != owner.id:
        raise ValueError("You do not have access to this project")

    # delete issues
    issues = list(db.exec(select(Issue).where(Issue.project_id == project.id)).all())
    for i in issues:
        db.delete(i)

    pref = db.exec(
        select(ProjectPreference).where(
            ProjectPreference.user_id == owner.id,
            ProjectPreference.project_id == project.id,
        )
    ).first()
    if pref:
        db.delete(pref)

    db.delete(project)
    db.commit()
