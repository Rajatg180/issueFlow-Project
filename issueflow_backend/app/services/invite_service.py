from __future__ import annotations

import secrets
from datetime import datetime
from typing import List, Tuple
from uuid import UUID

from pydantic import EmailStr
from sqlmodel import Session, select

from app.models.project import Project
from app.models.project_invite import ProjectInvite, InviteStatus
from app.models.project_member import ProjectMember, ProjectRole
from app.models.project_preference import ProjectPreference
from app.models.user import User


def _normalize_emails(emails: List[str | EmailStr]) -> List[str]:
    # trim + lowercase + unique, keep order
    seen = set()
    out: List[str] = []
    for e in emails or []:
        e2 = str(e).strip().lower()
        if not e2 or e2 in seen:
            continue
        seen.add(e2)
        out.append(e2)
    return out


def _new_token() -> str:
    return secrets.token_urlsafe(32)


def _is_member(db: Session, project_id: UUID, user_id: UUID) -> bool:
    m = db.exec(
        select(ProjectMember).where(
            ProjectMember.project_id == project_id,
            ProjectMember.user_id == user_id,
        )
    ).first()
    return m is not None


def invite_members(
    db: Session,
    project: Project,
    inviter: User,
    emails: List[str | EmailStr],
) -> Tuple[int, int]:
    """
    Creates ProjectInvite rows for each email.
    Skip if:
      - already a member (if user exists AND is member)
      - already invited (pending and not expired)
    """
    normalized = _normalize_emails(emails)
    if not normalized:
        return (0, 0)

    invited = 0
    skipped = 0

    for email in normalized:
        # If user exists and already member => skip
        existing_user = db.exec(select(User).where(User.email == email)).first()
        print("Existing user:", existing_user)
        if existing_user and _is_member(db, project.id, existing_user.id):
            print("  is member, skipping")
            skipped += 1
            continue

        # If already invited (pending + not expired) => skip
        existing_inv = db.exec(
            select(ProjectInvite).where(
                ProjectInvite.project_id == project.id,
                ProjectInvite.email == email,
            )
        ).first()

        if existing_inv:
            # if it's pending and still valid -> skip
            if existing_inv.status == InviteStatus.pending and existing_inv.expires_at >= datetime.utcnow():
                skipped += 1
                continue
            # if old one exists but not pending or expired, we can "re-invite" by overwriting it
            existing_inv.token = _new_token()
            existing_inv.status = InviteStatus.pending
            existing_inv.created_at = datetime.utcnow()
            # keep same expires_at behavior: refresh expiry window
            # (simple and clean)
            from datetime import timedelta
            existing_inv.expires_at = datetime.utcnow() + timedelta(days=7)
            existing_inv.invited_by_user_id = inviter.id

            db.add(existing_inv)
            invited += 1
            continue

        inv = ProjectInvite(
            project_id=project.id,
            email=email,
            token=_new_token(),
            status=InviteStatus.pending,
            invited_by_user_id=inviter.id,
            created_at=datetime.utcnow(),
        )
        db.add(inv)
        invited += 1

    db.commit()
    return (invited, skipped)

def list_my_invites(db: Session, user: User) -> List[Tuple[ProjectInvite, Project, User]]:
    now = datetime.utcnow()
    email = user.email.lower().strip()

    # -------------------------
    # 1) Mark expired invites
    # -------------------------
    pending = list(
        db.exec(
            select(ProjectInvite).where(
                ProjectInvite.email == email,
                ProjectInvite.status == InviteStatus.pending,
            )
        ).all()
    )

    changed = False
    for inv in pending:
        if inv.expires_at < now:
            inv.status = InviteStatus.expired
            db.add(inv)
            changed = True

    if changed:
        db.commit()

    # -------------------------
    # 2) Join Project + inviter(User)
    # -------------------------
    rows = db.exec(
        select(ProjectInvite, Project, User)
        .join(Project, Project.id == ProjectInvite.project_id)
        .join(User, User.id == ProjectInvite.invited_by_user_id)
        .where(
            ProjectInvite.email == email,
            ProjectInvite.status == InviteStatus.pending,
            ProjectInvite.expires_at >= now,
        )
        .order_by(ProjectInvite.created_at.desc())
    ).all()

    return list(rows)


def accept_invite(db: Session, token: str, user: User) -> UUID:
    inv = db.exec(select(ProjectInvite).where(ProjectInvite.token == token)).first()
    if not inv:
        raise ValueError("Invite not found")

    if inv.status != InviteStatus.pending:
        raise ValueError(f"Invite is not pending (status={inv.status})")

    if inv.expires_at < datetime.utcnow():
        inv.status = InviteStatus.expired
        db.add(inv)
        db.commit()
        raise ValueError("Invite expired")

    # critical security rule: invite email must match logged-in email
    if inv.email.strip().lower() != user.email.strip().lower():
        raise ValueError("This invite is not for your email")

    # create membership if missing
    member = db.exec(
        select(ProjectMember).where(
            ProjectMember.project_id == inv.project_id,
            ProjectMember.user_id == user.id,
        )
    ).first()

    if not member:
        member = ProjectMember(project_id=inv.project_id, user_id=user.id, role=ProjectRole.member)
        db.add(member)

    # ensure preference row exists for this user+project (optional but consistent with your UX)
    pref = db.exec(
        select(ProjectPreference).where(
            ProjectPreference.user_id == user.id,
            ProjectPreference.project_id == inv.project_id,
        )
    ).first()
    if not pref:
        pref = ProjectPreference(
            user_id=user.id,
            project_id=inv.project_id,
            is_favorite=False,
            is_pinned=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(pref)

    # mark invite accepted
    inv.status = InviteStatus.accepted
    inv.accepted_at = datetime.utcnow()
    inv.accepted_by_user_id = user.id
    db.add(inv)

    db.commit()
    return inv.project_id


def revoke_invite(db: Session, project: Project, owner: User, invite_id: UUID) -> None:
    inv = db.exec(select(ProjectInvite).where(ProjectInvite.id == invite_id)).first()
    if not inv or inv.project_id != project.id:
        raise ValueError("Invite not found")

    # owner-only
    if project.owner_id != owner.id:
        raise ValueError("You do not have access to this project")

    if inv.status != InviteStatus.pending:
        raise ValueError("Only pending invites can be revoked")

    inv.status = InviteStatus.revoked
    db.add(inv)
    db.commit()
