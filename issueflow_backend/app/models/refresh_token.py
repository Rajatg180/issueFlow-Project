from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field


class RefreshToken(SQLModel, table=True):
    """
    Stores refresh tokens (hashed) for users.

    We store ONLY token_hash in DB (never raw token) so DB leaks are safer.
    """
    id: UUID = Field(default_factory=uuid4, primary_key=True)

    user_id: UUID = Field(index=True, nullable=False)

    # Hash of the raw refresh token (HMAC-SHA256)
    token_hash: str = Field(nullable=False, unique=True, index=True)

    created_at: datetime = Field(default_factory=datetime.utcnow)

    # When this refresh token becomes invalid (e.g., 14 days)
    expires_at: datetime = Field(nullable=False)

    # If set => token is revoked (logout / manual revoke)
    revoked_at: Optional[datetime] = Field(default=None)

    @staticmethod
    def build_expiry(days: int) -> datetime:
        return datetime.utcnow() + timedelta(days=days)
