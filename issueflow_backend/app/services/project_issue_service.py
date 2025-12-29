from __future__ import annotations

from collections import defaultdict
from typing import Dict, List, Tuple
from sqlmodel import Session, select
from sqlalchemy.orm import aliased
from sqlalchemy import func

from app.models.issue import Issue
from app.models.user import User
from app.models.issue_comment import IssueComment  # ✅ NEW
from app.services.project_service import list_projects


def list_projects_with_issues_and_users(db: Session, user: User) -> List[Tuple]:
    """
    Returns:
      [
        (project, role_str, [(issue, reporter_user, assignee_user_or_none), ...]),
        ...
      ]

    Same as before, now also supports comments_count lookup
    (we'll use it in the router without changing structure).
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

    # ✅ NEW: build comments_count map: issue_id -> count
    issue_ids = [i.id for (i, _r, _a) in issue_rows]
    comment_count_map: Dict[str, int] = {}

    if issue_ids:
        counts = list(
            db.exec(
                select(IssueComment.issue_id, func.count(IssueComment.id))
                .where(IssueComment.issue_id.in_(issue_ids))
                .group_by(IssueComment.issue_id)
            ).all()
        )
        comment_count_map = {str(issue_id): int(cnt) for (issue_id, cnt) in counts}

    # 3) Group issues by project_id (unchanged structure)
    grouped: Dict = defaultdict(list)
    for (issue, reporter, assignee) in issue_rows:
        grouped[issue.project_id].append((issue, reporter, assignee))

    # 4) Attach role and grouped issues per project
    # ✅ return comment_count_map ALSO but without changing outer structure too much:
    # We'll attach it as the 4th element in tuple => (p, role, issue_rows, comment_count_map)
    out = []
    for (p, _pref) in rows:
        role = "owner" if str(p.owner_id) == str(user.id) else "member"
        out.append((p, role, grouped.get(p.id, []), comment_count_map))

    return out
