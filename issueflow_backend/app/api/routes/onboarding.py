from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from datetime import datetime
from app.services.invite_service import invite_members
from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.onboarding import OnboardingSetupRequest, OnboardingSetupResponse
from app.services.project_service import create_project
from app.services.issue_service import create_issue

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])


@router.post("/setup", response_model=OnboardingSetupResponse)
def setup(
    payload: OnboardingSetupRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    1) Create Project
    2) Invite members (we store later; v1 = ignore)
    3) Create first Issue
    Then mark has_completed_onboarding = true
    """
    try:
        # Step 1: create project
        project = create_project(
            db=db,
            owner=user,
            name=payload.project.name,
            key=payload.project.key,
            description=payload.project.description,
        )

        # Step 2: Invite members (NOW REAL)
        if payload.invites:
            invite_members(db=db, project=project, inviter=user, emails=payload.invites)


        # Step 3: create first issue
        first_issue = create_issue(
            db=db,
            project_id=project.id,
            reporter=user,
            title=payload.first_issue.title,
            description=payload.first_issue.description,
            type_=payload.first_issue.type,
            priority=payload.first_issue.priority,
            due_date=payload.first_issue.due_date,
        )

        # Mark onboarding done on the USER (your requirement)
        user.has_completed_onboarding = True
        user.updated_at = datetime.utcnow()
        db.add(user)
        db.commit()
        db.refresh(user)

        return OnboardingSetupResponse(
            project_id=str(project.id),
            project_key=project.key,
            first_issue_id=str(first_issue.id),
            first_issue_key=first_issue.key,
            has_completed_onboarding=user.has_completed_onboarding,
            due_date=first_issue.due_date,  
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        raise HTTPException(status_code=500, detail="Onboarding setup failed")


@router.post("/complete")
def complete(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """
    If user clicks "Skip", you can just mark onboarding true without creating anything.
    """
    user.has_completed_onboarding = True
    user.updated_at = datetime.utcnow()
    db.add(user)
    db.commit()
    return {"has_completed_onboarding": True}
