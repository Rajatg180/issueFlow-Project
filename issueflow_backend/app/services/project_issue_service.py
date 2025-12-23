from __future__ import annotations

from collections import defaultdict
from typing import Dict, List, Tuple
from sqlmodel import Session, select
from sqlalchemy.orm import aliased

from app.models.issue import Issue
from app.models.user import User
from app.services.project_service import list_projects


def list_projects_with_issues_and_users(db: Session, user: User) -> List[Tuple]:
    """
    Returns:
      [
        (project, role_str, [(issue, reporter_user, assignee_user_or_none), ...]),
        ...
      ]

    This keeps the behavior exactly like your current /projects/with-issues
    but enriches each issue with reporter + assignee user info.
    """

    # 1) Accessible projects (owned + member) using your existing logic
    rows = list_projects(db, owner=user)  # [(Project, ProjectPreference|None), ...]
    projects = [p for (p, _pref) in rows]
    if not projects:
        return []

    project_ids = [p.id for p in projects]

    # 2) Join User twice: reporter + assignee
    Reporter = aliased(User)
    Assignee = aliased(User)

    issue_rows = list(
        db.exec(
            select(Issue, Reporter, Assignee)
            .join(Reporter, Reporter.id == Issue.reporter_id)
            .outerjoin(Assignee, Assignee.id == Issue.assignee_id)  # nullable
            .where(Issue.project_id.in_(project_ids))
            .order_by(Issue.created_at.desc())
        ).all()
    )

    # 3) Group issues by project_id
    grouped: Dict = defaultdict(list)
    for (issue, reporter, assignee) in issue_rows:
        grouped[issue.project_id].append((issue, reporter, assignee))

    # 4) Attach role and grouped issues per project
    out = []
    for (p, _pref) in rows:
        role = "owner" if str(p.owner_id) == str(user.id) else "member"
        out.append((p, role, grouped.get(p.id, [])))

    return out
