from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from uuid import UUID

from app.models.project_invite import InviteStatus


class InviteCreateRequest(BaseModel):
    emails: List[EmailStr] = Field(min_length=1)


class InviteCreateResponse(BaseModel):
    status: str = "ok"
    invited: int
    skipped: int


class MyInviteResponse(BaseModel):
    id: str
    project_id: str
    project_name: str  # ✅ NEW

    email: EmailStr
    token: str
    status: InviteStatus

    invited_by_user_id: str  # ✅ NEW
    invited_by_email: EmailStr  # ✅ NEW

    created_at: datetime
    expires_at: datetime

class MyInvitesListResponse(BaseModel):
    invites: List[MyInviteResponse]


class AcceptInviteResponse(BaseModel):
    status: str = "ok"
    project_id: str
