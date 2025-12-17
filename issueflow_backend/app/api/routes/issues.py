from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.issue import IssueCreateRequest, IssueResponse
from app.services.issue_service import create_issue, list_issues

router = APIRouter(prefix="/projects/{project_id}/issues", tags=["Issues"])


@router.post("", response_model=IssueResponse)
def create_in_project(
    project_id: str,
    payload: IssueCreateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        issue = create_issue(
            db=db,
            project_id=project_id,
            reporter=user,
            title=payload.title,
            description=payload.description,
            type_=payload.type,
            priority=payload.priority,
        )

        return IssueResponse(
            id=str(issue.id),
            key=issue.key,
            title=issue.title,
            description=issue.description,
            type=issue.type,
            priority=issue.priority,
            status=issue.status,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("", response_model=list[IssueResponse])
def list_in_project(
    project_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        items = list_issues(db=db, project_id=project_id, current_user=user)
        return [
            IssueResponse(
                id=str(i.id),
                key=i.key,
                title=i.title,
                description=i.description,
                type=i.type,
                priority=i.priority,
                status=i.status,
            )
            for i in items
        ]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
