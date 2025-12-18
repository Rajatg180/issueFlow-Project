from __future__ import annotations

from datetime import datetime, date
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field


class IssueType(str, Enum):
    task = "task"
    bug = "bug"
    feature = "feature"


class IssuePriority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class IssueStatus(str, Enum):
    todo = "todo"
    in_progress = "in_progress"
    done = "done"


class Issue(SQLModel, table=True):
    """
    - key: "IF-1"
    - project_id: belongs to a project
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)
    project_id: UUID = Field(index=True, nullable=False)

    key: str = Field(index=True, unique=True, nullable=False, max_length=32)

    title: str = Field(nullable=False, max_length=200)
    description: Optional[str] = Field(default=None)

    type: IssueType = Field(nullable=False, default=IssueType.task)
    priority: IssuePriority = Field(nullable=False, default=IssuePriority.medium)
    status: IssueStatus = Field(nullable=False, default=IssueStatus.todo)

    due_date: Optional[date] = Field(default=None, index=True)

    reporter_id: UUID = Field(index=True, nullable=False)
    assignee_id: Optional[UUID] = Field(default=None, index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
