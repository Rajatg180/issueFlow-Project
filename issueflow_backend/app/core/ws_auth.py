from __future__ import annotations

from fastapi import WebSocket
from jose import JWTError
from sqlmodel import Session, select

from app.core.security import decode_token
from app.models.user import User


def get_current_user_ws(websocket: WebSocket, db: Session) -> User:
    # For WebSockets, FastAPI's HTTPBearer doesn't work.
    # So we pass token like: ws://.../comments?token=JWT
    token = websocket.query_params.get("token")

    # If the client didn't send token => reject connection
    if not token:
        raise ValueError("Missing token")

    # Decode JWT using your existing decode_token() helper
    try:
        payload = decode_token(token)
    except JWTError:
        raise ValueError("Invalid token")

    # Ensure this JWT is an ACCESS token (not refresh)
    if payload.get("type") != "access":
        raise ValueError("Invalid token type")

    # "sub" holds the user id in your JWT
    user_id = payload.get("sub")
    if not user_id:
        raise ValueError("Invalid token payload")

    # Fetch the user from DB
    user = db.exec(select(User).where(User.id == user_id)).first()
    if not user:
        raise ValueError("User not found")

    # Return the authenticated user
    return user
