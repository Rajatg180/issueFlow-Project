from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from uuid import UUID

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.dashboard import (
    DashboardHomeResponse,
    DashboardProjectResponse,
    DashboardSummary,
    IssueCard,
    ActivityItem,
)
from app.services.dashboard_service import dashboard_home, dashboard_project

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/home", response_model=DashboardHomeResponse)
def home(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    data = dashboard_home(db, user)

    def to_issue_card(i) -> IssueCard:
        return IssueCard(
            id=str(i.id),
            key=i.key,
            title=i.title,
            status=i.status,
            priority=i.priority,
            due_date=i.due_date,
            project_id=str(i.project_id),
        )

    def to_activity(row) -> ActivityItem:
        c, i = row 
        return ActivityItem(
            project_id=str(c.project_id),
            issue_id=str(c.issue_id),
            issue_key=i.key,
            issue_title=i.title,
            author_username=c.author_username,
            body=c.body,
            created_at=c.created_at,
        )


    return DashboardHomeResponse(
        summary=DashboardSummary(
            projects_count=data["projects_count"],
            issues_count=data["issues_count"],
            by_status=data["by_status"],
            by_priority=data["by_priority"],
        ),
        my_assigned=[to_issue_card(i) for i in data["my_assigned"]],
        due_soon=[to_issue_card(i) for i in data["due_soon"]],
        overdue=[to_issue_card(i) for i in data["overdue"]],
        recent_activity=[to_activity(c) for c in data["recent_activity"]],
    )


@router.get("/projects/{project_id}", response_model=DashboardProjectResponse)
def project_view(
    project_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        data = dashboard_project(db, user, project_id)

        def to_activity(row) -> ActivityItem:
            c, i = row
            return ActivityItem(
                project_id=str(c.project_id),
                issue_id=str(c.issue_id),
                issue_key=i.key,
                issue_title=i.title,
                author_username=c.author_username,
                body=c.body,
                created_at=c.created_at,
            )

        return DashboardProjectResponse(
            project_id=str(data["project_id"]),
            summary=DashboardSummary(
                projects_count=1,
                issues_count=data["issues_count"],
                by_status=data["by_status"],
                by_priority=data["by_priority"],
            ),
            recent_activity=[to_activity(c) for c in data["recent_activity"]],
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
