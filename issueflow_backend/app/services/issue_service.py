from __future__ import annotations
from datetime import datetime
from sqlmodel import Session, select

from app.models.issue import Issue, IssuePriority, IssueType
from app.models.project import Project
from app.models.user import User


def _next_issue_key(project: Project) -> str:
    """
    Example:
      project.key = "IF"
      project.issue_seq = 0  -> next = IF-1
      project.issue_seq = 1  -> next = IF-2
    """
    return f"{project.key}-{project.issue_seq + 1}"


def create_issue(
    db: Session,
    project_id,
    reporter: User,
    title: str,
    description: str | None,
    type_: IssueType,
    priority: IssuePriority,
) -> Issue:
    """
    Create an issue inside a project and generate stable issue key (KEY-1, KEY-2...).

    Important part:
    - We must increment project.issue_seq atomically to avoid duplicates
      if two issues are created at the same time.
    """
    # Load project
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    # Optional: enforce owner-only access in v1
    if project.owner_id != reporter.id:
        raise ValueError("You do not have access to this project")

    # Generate issue key
    issue_key = _next_issue_key(project)

    issue = Issue(
        project_id=project.id,
        key=issue_key,
        title=title.strip(),
        description=description,
        type=type_,
        priority=priority,
        reporter_id=reporter.id,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    # Increment project seq so next issue becomes KEY-(n+1)
    project.issue_seq += 1
    project.updated_at = datetime.utcnow()

    db.add(project)
    db.add(issue)
    db.commit()
    db.refresh(issue)
    return issue


def list_issues(db: Session, project_id, current_user: User) -> list[Issue]:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    if project.owner_id != current_user.id:
        raise ValueError("You do not have access to this project")

    return list(db.exec(select(Issue).where(Issue.project_id == project_id)).all())
