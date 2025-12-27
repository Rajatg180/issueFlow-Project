from __future__ import annotations

from datetime import date
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field

from app.models.issue import IssuePriority, IssueStatus, IssueType


class IssueCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None

    type: IssueType = IssueType.task
    priority: IssuePriority = IssuePriority.medium

    due_date: date | None = None


class IssueResponse(BaseModel):
    id: str
    key: str
    title: str
    description: str | None
    type: IssueType
    priority: IssuePriority
    status: IssueStatus
    due_date: date | None


class IssueUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    description: Optional[str] = None
    type: Optional[IssueType] = None
    priority: Optional[IssuePriority] = None
    status: Optional[IssueStatus] = None
    due_date: Optional[date] = None
    reporter_id: Optional[UUID] = None
    assignee_id: Optional[UUID] = None

class UserMini(BaseModel):
    id: str
    username: str

class IssueEditResponse(IssueResponse):
    reporter: UserMini
    assignee: Optional[UserMini] = None