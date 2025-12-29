from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from uuid import UUID

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.comment import CommentCreateRequest, CommentResponse
from app.services.comment_service import list_comments, create_comment

router = APIRouter(tags=["Comments"])


@router.get("/projects/{project_id}/issues/{issue_id}/comments", response_model=list[CommentResponse])
def get_issue_comments(
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


@router.post("/projects/{project_id}/issues/{issue_id}/comments", response_model=CommentResponse)
def post_issue_comment(
    project_id: UUID,
    issue_id: UUID,
    payload: CommentCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        c = create_comment(db=db, project_id=project_id, issue_id=issue_id, user=user, body=payload.body)

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
