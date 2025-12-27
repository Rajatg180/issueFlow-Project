from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.db.session import get_db
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshRequest,
    UserMeResponse,
    FirebaseLoginRequest,
)
from app.services.auth_service import (
    register_user,
    login_user,
    issue_tokens,
    refresh_access_token,
    revoke_refresh_token,
)
from app.core.deps import get_current_user
from app.models.user import User
from app.services.firebase_service import verify_firebase_id_token

import re
import random

router = APIRouter(prefix="/auth", tags=["Auth"])


def _slug_username(s: str) -> str:
    s = (s or "").strip().lower()
    s = re.sub(r"[^a-z0-9_]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s[:32] if s else "user"


def _unique_username(db: Session, base: str) -> str:
    base = _slug_username(base)
    candidate = base
    while db.exec(select(User).where(User.username == candidate)).first():
        suffix = str(random.randint(1000, 9999))
        candidate = f"{base[: max(0, 32 - 5)]}_{suffix}"  # "_" + 4 digits
    return candidate


@router.post("/register", response_model=TokenResponse)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    try:
        user = register_user(db, payload.email, payload.password, payload.username)
        tokens = issue_tokens(db, user)
        return TokenResponse(**tokens)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    try:
        user = login_user(db, payload.email, payload.password)
        tokens = issue_tokens(db, user)
        return TokenResponse(**tokens)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid email or password")

@router.post("/firebase", response_model=TokenResponse)
def firebase_login(payload: FirebaseLoginRequest, db: Session = Depends(get_db)):
    """
    Flutter sends Firebase ID token (after Google Sign-In / Firebase Auth).
    Backend verifies it with Firebase Admin SDK.
    Then we find or create a local User and return our normal access/refresh tokens.
    """
    try:
        decoded = verify_firebase_id_token(payload.id_token)

        firebase_uid = decoded.get("uid")
        email = decoded.get("email")

        if not firebase_uid:
            raise HTTPException(status_code=401, detail="Invalid Firebase token (no uid)")
        if not email:
            raise HTTPException(status_code=401, detail="Firebase token has no email")

        # Find existing user by firebase_uid OR email
        user = db.exec(select(User).where(User.firebase_uid == firebase_uid)).first()
        if not user:
            user = db.exec(select(User).where(User.email == email)).first()

        if not user:
            # ✅ Create user with generated username (required since username is now non-null + unique)
            uname = _unique_username(db, email.split("@")[0])
            user = User(
                email=email,
                firebase_uid=firebase_uid,
                username=uname,
                password_hash=None,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            # Ensure firebase_uid is saved (if user created earlier via email/pass)
            changed = False

            if user.firebase_uid is None:
                user.firebase_uid = firebase_uid
                changed = True

            # ✅ Ensure username exists (useful for old users after migration/backfill)
            if not getattr(user, "username", None):
                user.username = _unique_username(db, email.split("@")[0])
                changed = True

            if changed:
                db.add(user)
                db.commit()
                db.refresh(user)

        tokens = issue_tokens(db, user)
        return TokenResponse(**tokens)

    except Exception:
        # Don’t leak internal error details to client
        raise HTTPException(status_code=401, detail="Firebase authentication failed")


@router.post("/refresh")
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    try:
        access = refresh_access_token(db, payload.refresh_token)
        return {"access_token": access, "token_type": "bearer"}
    except ValueError:
        raise HTTPException(status_code=401, detail="Refresh token invalid")


@router.post("/logout")
def logout(payload: RefreshRequest, db: Session = Depends(get_db)):
    revoke_refresh_token(db, payload.refresh_token)
    return {"status": "ok"}


# Protected route to get current user info from access token
@router.get("/me", response_model=UserMeResponse)
def me(current_user: User = Depends(get_current_user)):
    return UserMeResponse(
        id=str(current_user.id),
        email=current_user.email,
        username=current_user.username,
        has_completed_onboarding=current_user.has_completed_onboarding,
    )
