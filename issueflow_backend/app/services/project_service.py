from __future__ import annotations
from datetime import datetime
from typing import Optional
from sqlmodel import Session, select
from app.models.project_member import ProjectMember, ProjectRole
from app.models.project_invite import ProjectInvite
from app.models.project import Project
from app.models.project_favorite import ProjectFavorite
from app.models.issue import Issue
from app.models.project import Project
from app.models.project_preference import ProjectPreference
from app.models.user import User


def create_project(db: Session, owner: User, name: str, key: str, description: str | None) -> Project:
    key = key.strip().upper()

    existing = db.exec(select(Project).where(Project.key == key)).first()
    if existing:
        raise ValueError("Project key already exists. Choose another key.")

    p = Project(
        owner_id=owner.id,
        name=name.strip(),
        key=key,
        description=description,
        issue_seq=0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(p)
    db.commit()
    db.refresh(p)

    # ✅ Owner becomes a member (role=owner)
    owner_member = ProjectMember(
        project_id=p.id,
        user_id=owner.id,
        role=ProjectRole.owner,
        created_at=datetime.utcnow(),
    )
    db.add(owner_member)
    db.commit()


    # ✅ Ensure preference row exists (default false/false)
    pref = ProjectPreference(
        user_id=owner.id,
        project_id=p.id,
        is_favorite=False,
        is_pinned=False,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(pref)
    db.commit()

    return p


def list_projects(db: Session, owner: User) -> list[tuple[Project, ProjectPreference | None]]:
    # owner projects
    owned = list(db.exec(select(Project).where(Project.owner_id == owner.id)).all())

    # member projects
    memberships = list(db.exec(select(ProjectMember).where(ProjectMember.user_id == owner.id)).all())
    member_project_ids = [m.project_id for m in memberships]

    member_projects: list[Project] = []
    if member_project_ids:
        member_projects = list(db.exec(select(Project).where(Project.id.in_(member_project_ids))).all())

    # merge unique
    proj_map = {p.id: p for p in owned}
    for p in member_projects:
        proj_map.setdefault(p.id, p)

    projects = list(proj_map.values())
    if not projects:
        return []

    ids = [p.id for p in projects]
    prefs = list(
        db.exec(
            select(ProjectPreference).where(
                ProjectPreference.user_id == owner.id,
                ProjectPreference.project_id.in_(ids),
            )
        ).all()
    )

    pref_map = {pref.project_id: pref for pref in prefs}
    return [(p, pref_map.get(p.id)) for p in projects]



def update_project_preference(
    db: Session,
    owner: User,
    project_id: str,
    is_favorite: bool | None = None,
    is_pinned: bool | None = None,
) -> ProjectPreference:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")


    is_owner = project.owner_id == owner.id
    is_member = db.exec(
        select(ProjectMember).where(
            ProjectMember.project_id == project.id,
            ProjectMember.user_id == owner.id,
        )
    ).first() is not None

    if not (is_owner or is_member):
        raise ValueError("You do not have access to this project")


    pref = db.exec(
        select(ProjectPreference).where(
            ProjectPreference.user_id == owner.id,
            ProjectPreference.project_id == project.id,
        )
    ).first()


    if not pref:
        pref = ProjectPreference(
            user_id=owner.id,
            project_id=project.id,
            is_favorite=False,
            is_pinned=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(pref)
        db.commit()
        db.refresh(pref)

    # ✅ apply updates
    if is_favorite is not None:
        pref.is_favorite = is_favorite
    if is_pinned is not None:
        pref.is_pinned = is_pinned

    pref.updated_at = datetime.utcnow()
    db.add(pref)
    db.commit()
    db.refresh(pref)
    return pref


def delete_project(db: Session, project_id: str, owner: User) -> None:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    if project.owner_id != owner.id:
        raise ValueError("You do not have access to this project")

    # -----------------------------
    # 1) Delete issues + their children (if any)
    # -----------------------------
    issues = list(db.exec(select(Issue).where(Issue.project_id == project.id)).all())

    # If you have issue children tables, delete them first:
    # for issue in issues:
    #     comments = list(db.exec(select(IssueComment).where(IssueComment.issue_id == issue.id)).all())
    #     for c in comments:
    #         db.delete(c)
    #     attachments = list(db.exec(select(IssueAttachment).where(IssueAttachment.issue_id == issue.id)).all())
    #     for a in attachments:
    #         db.delete(a)

    for issue in issues:
        db.delete(issue)

    # -----------------------------
    # 2) Delete project invites
    # -----------------------------
    invites = list(db.exec(select(ProjectInvite).where(ProjectInvite.project_id == project.id)).all())
    for inv in invites:
        db.delete(inv)

    # -----------------------------
    # 3) Delete project members (membership rows)
    # -----------------------------
    members = list(db.exec(select(ProjectMember).where(ProjectMember.project_id == project.id)).all())
    for m in members:
        db.delete(m)

    # -----------------------------
    # 4) Delete preferences (pin/fav etc.)
    #    If your pref table is per-user per-project, delete all rows for project
    # -----------------------------
    prefs = list(
        db.exec(select(ProjectPreference).where(ProjectPreference.project_id == project.id)).all()
    )
    for p in prefs:
        db.delete(p)

    # -----------------------------
    # 5) If you have ProjectFavorite separately, delete those too
    # -----------------------------
    try:
        favs = list(
            db.exec(select(ProjectFavorite).where(ProjectFavorite.project_id == project.id)).all()
        )
        for f in favs:
            db.delete(f)
    except Exception:
        # ignore if table not in your project
        pass

    # -----------------------------
    # 6) Finally delete project
    # -----------------------------
    db.delete(project)
    db.commit()


def update_project(
    db: Session,
    owner: User,
    project_id: str,
    name: Optional[str] = None,
    key: Optional[str] = None,
    description: Optional[str] = None,
) -> Project:
    project = db.exec(select(Project).where(Project.id == project_id)).first()
    if not project:
        raise ValueError("Project not found")

    # ✅ Only owner can edit
    if str(project.owner_id) != str(owner.id):
        raise ValueError("Only project owner can edit the project")

    if name is not None:
        n = name.strip()
        if not n:
            raise ValueError("Name cannot be empty")
        project.name = n

    if key is not None:
        k = key.strip().upper()
        if len(k) < 2 or len(k) > 10:
            raise ValueError("Key must be between 2 and 10 characters")
        project.key = k

    # allow clearing description by passing ""
    if description is not None:
        d = description.strip()
        project.description = d if d else None

    db.add(project)
    db.commit()
    db.refresh(project)
    return project