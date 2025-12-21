from __future__ import annotations

from datetime import datetime, timedelta
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, UniqueConstraint


class InviteStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    revoked = "revoked"
    expired = "expired"


class ProjectInvite(SQLModel, table=True):
    __tablename__ = "project_invites"
    __table_args__ = (
        UniqueConstraint("token", name="uq_project_invite_token"),
        UniqueConstraint("project_id", "email", name="uq_project_invite_project_email"),
    )

    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)

    project_id: UUID = Field(index=True, nullable=False)

    email: str = Field(index=True, nullable=False, max_length=320)

    token: str = Field(index=True, nullable=False, max_length=128)

    status: InviteStatus = Field(default=InviteStatus.pending, index=True)

    invited_by_user_id: UUID = Field(index=True, nullable=False)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime = Field(default_factory=lambda: datetime.utcnow() + timedelta(days=7))

    accepted_at: Optional[datetime] = Field(default=None)
    accepted_by_user_id: Optional[UUID] = Field(default=None, index=True)
