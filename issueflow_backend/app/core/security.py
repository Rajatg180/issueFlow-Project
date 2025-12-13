from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta
from typing import Any, Dict
from jose import jwt , JWTError
from passlib.context import CryptContext


from app.core.config import settings

# Password hashing context (bcrypt).
# This safely converts plain passwords into a one-way hash.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(password: str, hashed_password: str) -> bool:
    """Verify plaintext password against stored bcrypt hash."""
    return pwd_context.verify(password, hashed_password)


def create_access_token(user_id: str) -> str:
    """
    Create short-lived JWT access token.

    We store:
    - sub: user_id (who the token belongs to)
    - type: access (so we can distinguish from refresh later)
    - exp: expiry time
    - iat: issued-at time
    """
    expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)

    payload: Dict[str, Any] = {
        "sub": user_id,
        "type": "access",
        "exp": expire,
        "iat": datetime.utcnow(),
    }

    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def generate_refresh_token() -> str:
    """
    Generate a long random refresh token string.
    This is NOT a JWT. It's just a secure random string.
    """
    return secrets.token_urlsafe(64)


def hash_refresh_token(token: str) -> str:
    """
    Hash refresh token before storing it in DB.
    We store only the hash in DB so even if DB leaks,
    attackers don't get valid refresh tokens.
    """
    key = settings.jwt_secret.encode("utf-8")
    msg = token.encode("utf-8")
    return hmac.new(key, msg, hashlib.sha256).hexdigest()


def decode_token(token: str) -> dict:
    """
    Decode JWT and return payload.
    Raises JWTError if invalid.
    """
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])