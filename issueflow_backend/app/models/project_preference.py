from __future__ import annotations
from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, UniqueConstraint


class ProjectPreference(SQLModel, table=True):
    __tablename__ = "project_preferences"
    __table_args__ = (
        UniqueConstraint("user_id", "project_id", name="uq_user_project_pref"),
    )

    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)

    user_id: UUID = Field(index=True)
    project_id: UUID = Field(index=True)

    is_favorite: bool = Field(default=False, index=True)
    is_pinned: bool = Field(default=False, index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
