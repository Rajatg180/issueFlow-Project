from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel


class ProjectCreateRequest(BaseModel):
    name: str
    key: str
    description: str | None = None


class ProjectResponse(BaseModel):
    id: str
    name: str
    key: str
    description: str | None = None
    created_at: datetime | None = None

    # ✅ new fields
    is_favorite: bool = False
    is_pinned: bool = False


class ProjectPreferenceUpdateRequest(BaseModel):
    is_favorite: bool | None = None
    is_pinned: bool | None = None
