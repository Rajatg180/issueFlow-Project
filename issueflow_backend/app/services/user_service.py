from __future__ import annotations

from typing import List
from uuid import UUID

from sqlmodel import Session, select

from app.models.user import User
from app.models.project import Project
from app.models.project_member import ProjectMember


def list_project_users(db: Session, project_id: UUID, current_user: User) -> List[User]:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    # Access control: owner OR member
    if project.owner_id != current_user.id:
        m = db.exec(
            select(ProjectMember).where(
                ProjectMember.project_id == project.id,
                ProjectMember.user_id == current_user.id,
            )
        ).first()
        if not m:
            raise ValueError("You do not have access to this project")

    # Get all members for that project (owner included because you add owner as ProjectMember)
    member_rows = db.exec(
        select(ProjectMember).where(ProjectMember.project_id == project.id)
    ).all()

    user_ids = [m.user_id for m in member_rows]
    if not user_ids:
        return []

    users = db.exec(
        select(User).where(User.id.in_(user_ids)).order_by(User.username)
    ).all()

    return list(users)
