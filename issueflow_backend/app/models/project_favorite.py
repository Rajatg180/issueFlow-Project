from datetime import datetime
from uuid import UUID, uuid4
from sqlmodel import SQLModel, Field


class ProjectFavorite(SQLModel, table=True):
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    user_id: UUID = Field(index=True, nullable=False)
    project_id: UUID = Field(index=True, nullable=False)

    created_at: datetime = Field(default_factory=datetime.utcnow)
