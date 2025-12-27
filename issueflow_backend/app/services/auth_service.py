from datetime import datetime
from uuid import UUID

from sqlmodel import Session, select

from app.core.config import settings
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    generate_refresh_token,
    hash_refresh_token,
)
from app.models.user import User
from app.models.refresh_token import RefreshToken


def register_user(db: Session, email: str, password: str, username: str) -> User:
    email_norm = email.strip().lower()
    username_norm = username.strip()

    existing_email = db.exec(select(User).where(User.email == email_norm)).first()
    if existing_email:
        raise ValueError("Email already registered")

    existing_username = db.exec(select(User).where(User.username == username_norm)).first()
    if existing_username:
        raise ValueError("Username already taken")

    user = User(
        email=email_norm,
        username=username_norm,
        password_hash=hash_password(password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def login_user(db: Session, email: str, password: str) -> User:
    user = db.exec(select(User).where(User.email == email)).first()
    if not user or not user.password_hash:
        raise ValueError("Invalid email or password")

    if not verify_password(password, user.password_hash):
        raise ValueError("Invalid email or password")

    return user


def issue_tokens(db: Session, user: User) -> dict:
    access = create_access_token(str(user.id))

    raw_refresh = generate_refresh_token()
    refresh_hash = hash_refresh_token(raw_refresh)

    rt = RefreshToken(
        user_id=user.id,
        token_hash=refresh_hash,
        expires_at=RefreshToken.build_expiry(settings.refresh_token_expire_days),
    )
    db.add(rt)
    db.commit()

    return {"access_token": access, "refresh_token": raw_refresh}


def refresh_access_token(db: Session, raw_refresh_token: str) -> str:
    token_hash = hash_refresh_token(raw_refresh_token)

    rt = db.exec(select(RefreshToken).where(RefreshToken.token_hash == token_hash)).first()
    if not rt:
        raise ValueError("Invalid refresh token")

    if rt.revoked_at is not None:
        raise ValueError("Refresh token revoked")

    if rt.expires_at < datetime.utcnow():
        raise ValueError("Refresh token expired")

    return create_access_token(str(rt.user_id))


def revoke_refresh_token(db: Session, raw_refresh_token: str) -> None:
    token_hash = hash_refresh_token(raw_refresh_token)

    rt = db.exec(select(RefreshToken).where(RefreshToken.token_hash == token_hash)).first()
    if not rt:
        return

    rt.revoked_at = datetime.utcnow()
    db.add(rt)
    db.commit()
