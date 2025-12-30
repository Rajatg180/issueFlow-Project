from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field


class CommentCreateRequest(BaseModel):
    body: str = Field(min_length=1, max_length=4000)

class CommentUpdateRequest(BaseModel):
    body: str = Field(min_length=1, max_length=4000)


class CommentResponse(BaseModel):
    id: str
    project_id: str
    issue_id: str
    author_id: str
    author_username: str
    body: str
    edited: bool
    created_at: datetime
    updated_at: datetime
