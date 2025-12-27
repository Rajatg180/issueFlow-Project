from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.invite import MyInvitesListResponse, MyInviteResponse, AcceptInviteResponse
from app.services.invite_service import list_my_invites, accept_invite

router = APIRouter(tags=["Invites"])


@router.get("/me/invites", response_model=MyInvitesListResponse)
def my_invites(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    rows = list_my_invites(db=db, user=user)

    return MyInvitesListResponse(
        invites=[
            MyInviteResponse(
                id=str(inv.id),
                project_id=str(inv.project_id),
                project_name=project.name,  # ✅ NEW
                email=inv.email,
                token=inv.token,
                status=inv.status,
                invited_by_user_id=str(inv.invited_by_user_id),  # ✅ NEW
                invited_by_username=inviter.username,  # ✅ NEW
                created_at=inv.created_at,
                expires_at=inv.expires_at,
            )
            for (inv, project, inviter) in rows
        ]
    )


@router.post("/invites/{token}/accept", response_model=AcceptInviteResponse)
def accept(
    token: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        project_id = accept_invite(db=db, token=token, user=user)
        return AcceptInviteResponse(project_id=str(project_id))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
