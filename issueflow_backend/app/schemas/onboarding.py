from __future__ import annotations
from pydantic import BaseModel
from typing import List, Optional

from app.schemas.project import ProjectCreateRequest
from app.schemas.issue import IssueCreateRequest


class OnboardingSetupRequest(BaseModel):
    # Step 1 data
    project: ProjectCreateRequest

    # Step 2 data (optional)
    invites: Optional[List[str]] = None

    # Step 3 data
    first_issue: IssueCreateRequest


class OnboardingSetupResponse(BaseModel):
    project_id: str
    project_key: str

    first_issue_id: str
    first_issue_key: str

    has_completed_onboarding: bool
