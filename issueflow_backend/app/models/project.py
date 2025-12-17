
from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID , uuid4

from sqlmodel import SQLModel , Field


class Project(SQLModel,table = True):

    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)

    #for version 1 we are adding only one member later we can add mutiple users
    owner_id : UUID = Field(index = True,nullable= False)

    key: str = Field(index=True, unique=True, nullable=False, max_length=10)
    name: str = Field(nullable=False, max_length=120)
    description: Optional[str] = Field(default=None)
    issue_seq: int = Field(default = 0,nullable = False) #basically this is the count of issue for this project to creat the issue key
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

