from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from uuid import UUID

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.project import Project
from app.models.user import User
from app.schemas.invite import InviteCreateRequest, InviteCreateResponse
from app.services.invite_service import invite_members, revoke_invite

router = APIRouter(prefix="/projects/{project_id}/invites", tags=["Invites"])


@router.post("", response_model=InviteCreateResponse)
def create_invites(
    project_id: UUID,
    payload: InviteCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # owner-only for v1 (matches your current permission model)
    if project.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Only project owner can invite")

    invited, skipped = invite_members(db=db, project=project, inviter=user, emails=payload.emails)
    return InviteCreateResponse(invited=invited, skipped=skipped)


@router.delete("/{invite_id}")
def delete_invite(
    project_id: UUID,
    invite_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    try:
        revoke_invite(db=db, project=project, owner=user, invite_id=invite_id)
        return {"status": "ok"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
