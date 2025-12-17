from __future__ import annotations
from datetime import datetime
from sqlmodel import Session, select

from app.models.project import Project
from app.models.user import User


def create_project(db: Session, owner: User, name: str, key: str, description: str | None) -> Project:
    """
    Create a project for the current user.

    Validations:
    - project key must be unique
    - normalize key to uppercase (Jira-like)
    """
    key = key.strip().upper()

    existing = db.exec(select(Project).where(Project.key == key)).first()
    if existing:
        raise ValueError("Project key already exists. Choose another key.")

    p = Project(
        owner_id=owner.id,
        name=name.strip(),
        key=key,
        description=description,
        issue_seq=0,  # start from 0, first issue becomes KEY-1
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(p)
    db.commit()
    db.refresh(p)
    return p


def list_projects(db: Session, owner: User) -> list[Project]:
    """List projects owned by the current user."""
    return list(db.exec(select(Project).where(Project.owner_id == owner.id)).all())
