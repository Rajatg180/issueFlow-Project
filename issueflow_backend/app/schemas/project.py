from __future__ import annotations
from pydantic import BaseModel, Field


class ProjectCreateRequest(BaseModel):
    # UI sends these in onboarding 
    name: str = Field(min_length=1, max_length=120)
    key: str = Field(min_length=2, max_length=10)  # e.g. IF
    description: str | None = None


class ProjectResponse(BaseModel):
    id: str
    name: str
    key: str
    description: str | None = None
