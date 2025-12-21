
from __future__ import annotations
from datetime import datetime
from enum import Enum
from uuid import UUID, uuid4
from sqlmodel import SQLModel, Field,UniqueConstraint

class ProjectRole(str,Enum):
    owner = "owner"
    member = "member"

class ProjectMember(SQLModel, table=True):
    __tablename__ = "project_members"
    __table_args__ = (
        UniqueConstraint("project_id", "user_id", name="uq_project_member"),
    )
    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)
    project_id: UUID = Field(index=True,nullable=False)
    user_id: UUID = Field(index=True, nullable=False)
    role: ProjectRole = Field(default=ProjectRole.member)
    created_at: datetime = Field(default_factory=datetime.utcnow)
