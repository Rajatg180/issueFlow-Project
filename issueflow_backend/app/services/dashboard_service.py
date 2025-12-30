from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Dict, List, Set, Tuple
from uuid import UUID

from sqlmodel import Session, select
from sqlalchemy import func

from app.models.project import Project
from app.models.project_member import ProjectMember
from app.models.issue import Issue, IssueStatus, IssuePriority
from app.models.issue_comment import IssueComment
from app.models.user import User


def _accessible_project_ids(db: Session, user: User) -> List[UUID]:
    owned_ids = db.exec(select(Project.id).where(Project.owner_id == user.id)).all()
    member_ids = db.exec(select(ProjectMember.project_id).where(ProjectMember.user_id == user.id)).all()
    # both are lists of UUID
    ids = set(list(owned_ids) + list(member_ids))
    return list(ids)


def _summary_for_projects(db: Session, project_ids: List[UUID]) -> Tuple[int, Dict, Dict]:
    if not project_ids:
        return (0, {}, {})

    total_issues = db.exec(
        select(func.count(Issue.id)).where(Issue.project_id.in_(project_ids))
    ).one()

    # by status
    status_rows = db.exec(
        select(Issue.status, func.count(Issue.id))
        .where(Issue.project_id.in_(project_ids))
        .group_by(Issue.status)
    ).all()
    by_status = {status: int(cnt) for (status, cnt) in status_rows}

    # by priority
    priority_rows = db.exec(
        select(Issue.priority, func.count(Issue.id))
        .where(Issue.project_id.in_(project_ids))
        .group_by(Issue.priority)
    ).all()
    by_priority = {prio: int(cnt) for (prio, cnt) in priority_rows}

    return (int(total_issues), by_status, by_priority)


def dashboard_home(db: Session, user: User):
    project_ids = _accessible_project_ids(db, user)

    projects_count = len(project_ids)
    issues_count, by_status, by_priority = _summary_for_projects(db, project_ids)

    # My assigned issues (limit for dashboard)
    my_assigned_rows = db.exec(
        select(Issue)
        .where(Issue.project_id.in_(project_ids), Issue.assignee_id == user.id)
        .order_by(Issue.updated_at.desc())
        .limit(50)
    ).all()

    today = date.today()
    due_soon_limit = today + timedelta(days=7)

    due_soon_rows = db.exec(
        select(Issue)
        .where(
            Issue.project_id.in_(project_ids),
            Issue.assignee_id == user.id,
            Issue.due_date.is_not(None),
            Issue.due_date >= today,
            Issue.due_date <= due_soon_limit,
            Issue.status != IssueStatus.done,
        )
        .order_by(Issue.due_date.asc())
        .limit(20)
    ).all()

    overdue_rows = db.exec(
        select(Issue)
        .where(
            Issue.project_id.in_(project_ids),
            Issue.assignee_id == user.id,
            Issue.due_date.is_not(None),
            Issue.due_date < today,
            Issue.status != IssueStatus.done,
        )
        .order_by(Issue.due_date.asc())
        .limit(20)
    ).all()

    # Recent activity: last comments across accessible projects
    activity_rows = db.exec(
        select(IssueComment, Issue)
        .join(Issue, Issue.id == IssueComment.issue_id)
        .where(IssueComment.project_id.in_(project_ids))
        .order_by(IssueComment.created_at.desc())
        .limit(20)
    ).all()

    return {
        "projects_count": projects_count,
        "issues_count": issues_count,
        "by_status": by_status,
        "by_priority": by_priority,
        "my_assigned": list(my_assigned_rows),
        "due_soon": list(due_soon_rows),
        "overdue": list(overdue_rows),
        "recent_activity": list(activity_rows),
    }


def dashboard_project(db: Session, user: User, project_id: UUID):
    # ensure access (owner OR member)
    proj = db.exec(select(Project).where(Project.id == project_id)).first()
    if not proj:
        raise ValueError("Project not found")

    if proj.owner_id != user.id:
        m = db.exec(
            select(ProjectMember).where(ProjectMember.project_id == proj.id, ProjectMember.user_id == user.id)
        ).first()
        if not m:
            raise ValueError("You do not have access to this project")

    project_ids = [proj.id]
    issues_count, by_status, by_priority = _summary_for_projects(db, project_ids)

    activity_rows = db.exec(
        select(IssueComment, Issue)
        .join(Issue, Issue.id == IssueComment.issue_id)
        .where(IssueComment.project_id == proj.id)
        .order_by(IssueComment.created_at.desc())
        .limit(20)
    ).all()

    return {
        "project_id": proj.id,
        "issues_count": issues_count,
        "by_status": by_status,
        "by_priority": by_priority,
        "recent_activity": list(activity_rows),  
    }

