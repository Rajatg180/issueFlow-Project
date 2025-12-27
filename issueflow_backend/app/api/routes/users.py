from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from uuid import UUID

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import ProjectUsersResponse, UserMiniResponse
from app.services.user_service import list_project_users

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/projects/{project_id}", response_model=ProjectUsersResponse)
def get_project_users(
    project_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        users = list_project_users(db=db, project_id=project_id, current_user=user)

        return ProjectUsersResponse(
            users=[
                UserMiniResponse(
                    id=str(u.id),
                    username=u.username,
                )
                for u in users
            ]
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
