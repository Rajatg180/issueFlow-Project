from __future__ import annotations

from datetime import datetime
from uuid import UUID, uuid4
from sqlmodel import SQLModel, Field


class IssueComment(SQLModel, table=True):
    __tablename__ = "issue_comments"
    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)
    project_id: UUID = Field(index=True, nullable=False)
    issue_id: UUID = Field(index=True, nullable=False)
    author_id: UUID = Field(index=True, nullable=False)
    author_username: str = Field(nullable=False, max_length=32)
    body: str = Field(nullable=False, max_length=4000)
    edited: bool = Field(default=False, index=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
