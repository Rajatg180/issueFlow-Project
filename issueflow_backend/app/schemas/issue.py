from __future__ import annotations
from pydantic import BaseModel, Field

from app.models.issue import IssuePriority, IssueStatus, IssueType


class IssueCreateRequest(BaseModel):
    # UI sends these in onboarding step 3 (or later issue create)
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None

    type: IssueType = IssueType.task
    priority: IssuePriority = IssuePriority.medium


class IssueResponse(BaseModel):
    id: str
    key: str
    title: str
    description: str | None
    type: IssueType
    priority: IssuePriority
    status: IssueStatus
