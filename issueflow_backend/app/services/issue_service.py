from __future__ import annotations
from datetime import date, datetime
from sqlmodel import Session, select
from app.models.project_member import ProjectMember
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
    due_date : date | None
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
        m = db.exec(
            select(ProjectMember).where(
                ProjectMember.project_id == project.id,
                ProjectMember.user_id == reporter.id,
            )
        ).first()
        if not m:
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
        due_date=due_date,
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
        m = db.exec(
            select(ProjectMember).where(
                ProjectMember.project_id == project.id,
                ProjectMember.user_id == current_user.id,
            )
        ).first()
        if not m:
            raise ValueError("You do not have access to this project")


    return list(db.exec(select(Issue).where(Issue.project_id == project_id)).all())



# ----------------------------
# ✅ NEW HELPERS (edit only)
# ----------------------------
def _ensure_project_access(db: Session, project: Project, user: User) -> None:
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


def _ensure_user_in_project(db: Session, project: Project, user_id: UUID) -> User:
    u = db.exec(select(User).where(User.id == user_id)).first()
    if not u:
        raise ValueError("User not found")

    # must be owner OR member
    if project.owner_id == user_id:
        return u

    m = db.exec(
        select(ProjectMember).where(
            ProjectMember.project_id == project.id,
            ProjectMember.user_id == user_id,
        )
    ).first()
    if not m:
        raise ValueError("User is not in this project")

    return u


#  NEW: used only by PATCH
def update_issue(
    db: Session,
    project_id,
    issue_id,
    current_user: User,
    updates: dict,  # dict from payload.dict(exclude_unset=True)
) -> Issue:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    _ensure_project_access(db, project, current_user)

    issue = db.exec(
        select(Issue).where(Issue.id == issue_id, Issue.project_id == project.id)
    ).first()
    if not issue:
        raise ValueError("Issue not found")

    # title
    if "title" in updates:
        t = (updates.get("title") or "").strip()
        if not t:
            raise ValueError("Title cannot be empty")
        issue.title = t

    # description
    if "description" in updates:
        issue.description = updates.get("description")

    # enums
    if "type" in updates:
        issue.type = updates["type"]

    if "priority" in updates:
        issue.priority = updates["priority"]

    if "status" in updates:
        issue.status = updates["status"]

    # due_date
    if "due_date" in updates:
        issue.due_date = updates.get("due_date")

    # reporter_id (cannot be null)
    if "reporter_id" in updates:
        rid = updates.get("reporter_id")
        if rid is None:
            raise ValueError("reporter_id cannot be null")
        _ensure_user_in_project(db, project, rid)
        issue.reporter_id = rid

    # assignee_id (can be null => unassign)
    if "assignee_id" in updates:
        aid = updates.get("assignee_id")
        if aid is None:
            issue.assignee_id = None  # ✅ unassign
        else:
            _ensure_user_in_project(db, project, aid)
            issue.assignee_id = aid

    issue.updated_at = datetime.utcnow()

    db.add(issue)
    db.commit()
    db.refresh(issue)
    return issue

# delete issue
def delete_issue_service(
    db: Session,
    project_id,
    issue_id,
    current_user: User,
) -> None:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    _ensure_project_access(db, project, current_user)

    issue = db.exec(
        select(Issue).where(Issue.id == issue_id, Issue.project_id == project.id)
    ).first()
    if not issue:
        raise ValueError("Issue not found")

    db.delete(issue)
    db.commit()