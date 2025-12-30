from __future__ import annotations
from datetime import date, datetime
from typing import Dict, List, Optional
from pydantic import BaseModel

from app.models.issue import IssueStatus, IssuePriority


class IssueCard(BaseModel):
    id: str
    key: str
    title: str
    status: IssueStatus
    priority: IssuePriority
    due_date: Optional[date] = None
    project_id: str


class ActivityItem(BaseModel):
    type: str = "comment"
    project_id: str
    issue_id: str

    # ✅ NEW (for dashboard display)
    issue_key: str
    issue_title: str

    author_username: str
    body: str
    created_at: datetime


class DashboardSummary(BaseModel):
    projects_count: int
    issues_count: int
    by_status: Dict[IssueStatus, int]
    by_priority: Dict[IssuePriority, int]


class DashboardHomeResponse(BaseModel):
    summary: DashboardSummary
    my_assigned: List[IssueCard]
    due_soon: List[IssueCard]
    overdue: List[IssueCard]
    recent_activity: List[ActivityItem]


class DashboardProjectResponse(BaseModel):
    project_id: str
    summary: DashboardSummary
    recent_activity: List[ActivityItem]
