from datetime import datetime
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field


class User(SQLModel, table=True):
    id: UUID = Field(default_factory=uuid4, primary_key=True, index=True)

    email: str = Field(index=True, unique=True, nullable=False)

    username: str = Field(index=True, unique=True, nullable=False, max_length=32)

    # Email/password users => set this
    # Google/Firebase users => None
    password_hash: Optional[str] = Field(default=None)

    # For Google login via Firebase
    firebase_uid: Optional[str] = Field(default=None, unique=True, index=True)

    has_completed_onboarding: bool = Field(default=False)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
