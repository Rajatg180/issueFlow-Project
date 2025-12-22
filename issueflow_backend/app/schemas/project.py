from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ProjectCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    key: str = Field(min_length=2, max_length=10)
    description: Optional[str] = None


class ProjectPreferenceUpdateRequest(BaseModel):
    is_favorite: Optional[bool] = None
    is_pinned: Optional[bool] = None


# ✅ NEW: Edit project request
class ProjectUpdateRequest(BaseModel):
    # allow partial update
    name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    key: Optional[str] = Field(default=None, min_length=2, max_length=10)
    description: Optional[str] = None


class ProjectResponse(BaseModel):
    id: str
    name: str
    key: str
    description: Optional[str] = None
    created_at: datetime

    is_favorite: bool = False
    is_pinned: bool = False

    # you already added this in backend response
    role: Optional[str] = None
