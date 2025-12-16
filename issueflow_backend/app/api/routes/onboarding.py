from fastapi import APIRouter, Depends
from sqlmodel import Session

from app.core.deps import get_current_user
from app.db.session import get_db
from app.models.user import User

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])


@router.post("/complete")
def complete_onboarding(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.has_completed_onboarding = True
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return {"status": "ok", "has_completed_onboarding": True}
