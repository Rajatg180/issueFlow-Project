from __future__ import annotations

from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel

from app.models.issue import IssuePriority, IssueStatus, IssueType


class UserMini(BaseModel):
    id: str
    email: str  # (acts as display name for now)


class IssueMiniResponse(BaseModel):
    id: str
    key: str
    title: str
    description: Optional[str] = None
    type: IssueType
    priority: IssuePriority
    status: IssueStatus
    due_date: Optional[date] = None
    created_at: datetime
    updated_at: datetime
    reporter: UserMini
    assignee: Optional[UserMini] = None


class ProjectWithIssuesResponse(BaseModel):
    id: str
    name: str
    key: str
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    role: str
    issues: List[IssueMiniResponse] = []
