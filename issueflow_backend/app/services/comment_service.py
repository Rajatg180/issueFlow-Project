from __future__ import annotations

from datetime import datetime , timezone
from uuid import UUID

from sqlmodel import Session, select

from app.models.project import Project
from app.models.project_member import ProjectMember
from app.models.issue import Issue
from app.models.user import User
from app.models.issue_comment import IssueComment


def _ensure_project_access(db: Session, project_id: UUID, user: User) -> None:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    if project.owner_id == user.id:
        return

    m = db.exec(
        select(ProjectMember).where(
            ProjectMember.project_id == project.id,
            ProjectMember.user_id == user.id,
        )
    ).first()
    if not m:
        raise ValueError("You do not have access to this project")


def _ensure_issue_in_project(db: Session, project_id: UUID, issue_id: UUID) -> None:
    issue = db.exec(
        select(Issue).where(Issue.id == issue_id, Issue.project_id == project_id)
    ).first()
    if not issue:
        raise ValueError("Issue not found")


# get all comments for an issue
def list_comments(db: Session, project_id: UUID, issue_id: UUID, user: User) -> list[IssueComment]:
    _ensure_project_access(db, project_id, user)
    _ensure_issue_in_project(db, project_id, issue_id)

    rows = db.exec(
        select(IssueComment)
        .where(IssueComment.project_id == project_id, IssueComment.issue_id == issue_id)
        .order_by(IssueComment.created_at.asc())
    ).all()
    return list(rows)


# create a new comment for an issue
def create_comment(db: Session, project_id: UUID, issue_id: UUID, user: User, body: str) -> IssueComment:
    _ensure_project_access(db, project_id, user)
    _ensure_issue_in_project(db, project_id, issue_id)

    text = (body or "").strip()
    if not text:
        raise ValueError("Comment body cannot be empty")

    now = datetime.now(timezone.utc)  

    c = IssueComment(
        project_id=project_id,
        issue_id=issue_id,
        author_id=user.id,
        author_username=user.username,
        body=text,
        edited=False,
        created_at=now,
        updated_at=now,
    )
    db.add(c)
    db.commit()
    db.refresh(c)
    return c