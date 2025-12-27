from __future__ import annotations
# from select import select
from sqlmodel import select
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.issue import IssueCreateRequest, IssueEditResponse, IssueResponse, IssueUpdateRequest, UserMini
from app.services.issue_service import create_issue, delete_issue_service, delete_issue_service, list_issues, update_issue

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
            due_date=payload.due_date, 
        )

        return IssueResponse(
            id=str(issue.id),
            key=issue.key,
            title=issue.title,
            description=issue.description,
            type=issue.type,
            priority=issue.priority,
            status=issue.status,
            due_date=issue.due_date,  
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
                due_date=i.due_date,
            )
            for i in items
        ]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{issue_id}", response_model=IssueEditResponse)
def edit_issue(
    project_id: str,
    issue_id: str,
    payload: IssueUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        updates = payload.dict(exclude_unset=True)

        issue = update_issue(
            db=db,
            project_id=project_id,
            issue_id=issue_id,
            current_user=user,
            updates=updates,
        )

        reporter = db.exec(select(User).where(User.id == issue.reporter_id)).first()
        assignee = None
        if issue.assignee_id:
            assignee = db.exec(select(User).where(User.id == issue.assignee_id)).first()

        return IssueEditResponse(
            id=str(issue.id),
            key=issue.key,
            title=issue.title,
            description=issue.description,
            type=issue.type,
            priority=issue.priority,
            status=issue.status,
            due_date=issue.due_date,
            reporter=UserMini(id=str(reporter.id), username=reporter.username),
            assignee=(
                UserMini(id=str(assignee.id), username=assignee.username)
                if assignee else None
            ),
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    

@router.delete("/{issue_id}")
def delete_issue(
    project_id: str,
    issue_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        # Placeholder for delete logic
        delete_issue_service(db=db, project_id=project_id, issue_id=issue_id, current_user=user)
        return {"detail": "Issue deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))