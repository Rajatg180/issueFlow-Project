from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from uuid import UUID

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.comment import CommentCreateRequest, CommentUpdateRequest, CommentResponse
from app.services.comment_service import (
    list_comments,
    create_comment,
    edit_comment,
    delete_comment,
)

# ✅ Redis Pub/Sub publisher (instance-safe)
from app.websockets.comments_hub import publish_and_broadcast

router = APIRouter(tags=["Comments"])


def _comment_event_dict(c) -> dict:
    """
    Dict payload for WS events (JSON-serializable).
    """
    return {
        "id": str(c.id),
        "project_id": str(c.project_id),
        "issue_id": str(c.issue_id),
        "author_id": str(c.author_id),
        "author_username": c.author_username,
        "body": c.body,
        "edited": c.edited,
        "created_at": c.created_at.isoformat(),
        "updated_at": c.updated_at.isoformat(),
    }


@router.get(
    "/projects/{project_id}/issues/{issue_id}/comments",
    response_model=list[CommentResponse],
)
async def get_issue_comments(
    project_id: UUID,
    issue_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        rows = list_comments(db=db, project_id=project_id, issue_id=issue_id, user=user)
        return [
            CommentResponse(
                id=str(c.id),
                project_id=str(c.project_id),
                issue_id=str(c.issue_id),
                author_id=str(c.author_id),
                author_username=c.author_username,
                body=c.body,
                edited=c.edited,
                created_at=c.created_at,
                updated_at=c.updated_at,
            )
            for c in rows
        ]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post(
    "/projects/{project_id}/issues/{issue_id}/comments",
    response_model=CommentResponse,
)
async def post_issue_comment(
    project_id: UUID,
    issue_id: UUID,
    payload: CommentCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        c = create_comment(db=db, project_id=project_id, issue_id=issue_id, user=user, body=payload.body)

        # ✅ Publish to Redis (so ALL instances rebroadcast to their WS clients)
        # ✅ Never fail HTTP if Redis publish fails
        try:
            await publish_and_broadcast(
                {
                    "type": "comment_created",
                    "project_id": str(project_id),
                    "issue_id": str(issue_id),
                    "comment": _comment_event_dict(c),
                }
            )
        except Exception:
            pass

        return CommentResponse(
            id=str(c.id),
            project_id=str(c.project_id),
            issue_id=str(c.issue_id),
            author_id=str(c.author_id),
            author_username=c.author_username,
            body=c.body,
            edited=c.edited,
            created_at=c.created_at,
            updated_at=c.updated_at,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch(
    "/projects/{project_id}/issues/{issue_id}/comments/{comment_id}",
    response_model=CommentResponse,
)
async def patch_issue_comment(
    project_id: UUID,
    issue_id: UUID,
    comment_id: UUID,
    payload: CommentUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        c = edit_comment(
            db=db,
            project_id=project_id,
            issue_id=issue_id,
            comment_id=comment_id,
            user=user,
            body=payload.body,
        )

        # ✅ Publish update event to Redis
        try:
            await publish_and_broadcast(
                {
                    "type": "comment_updated",
                    "project_id": str(project_id),
                    "issue_id": str(issue_id),
                    "comment": _comment_event_dict(c),
                }
            )
        except Exception:
            pass

        return CommentResponse(
            id=str(c.id),
            project_id=str(c.project_id),
            issue_id=str(c.issue_id),
            author_id=str(c.author_id),
            author_username=c.author_username,
            body=c.body,
            edited=c.edited,
            created_at=c.created_at,
            updated_at=c.updated_at,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/projects/{project_id}/issues/{issue_id}/comments/{comment_id}")
async def delete_issue_comment(
    project_id: UUID,
    issue_id: UUID,
    comment_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        delete_comment(
            db=db,
            project_id=project_id,
            issue_id=issue_id,
            comment_id=comment_id,
            user=user,
        )

        # ✅ Publish delete event to Redis
        try:
            await publish_and_broadcast(
                {
                    "type": "comment_deleted",
                    "project_id": str(project_id),
                    "issue_id": str(issue_id),
                    "comment_id": str(comment_id),
                }
            )
        except Exception:
            pass

        return {"ok": True}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
