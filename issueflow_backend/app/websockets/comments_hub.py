from __future__ import annotations

from typing import Tuple

from app.websockets.manager import ConnectionManager
from app.core.redis_pubsub import publish_comment_event

RoomKey = Tuple[str, str]  # (project_id, issue_id)

manager = ConnectionManager()


async def rebroadcast_from_redis(payload: dict) -> None:
    """
    This runs INSIDE EACH INSTANCE when Redis delivers an event.

    Example payload:
      {
        "type": "comment_created",
        "project_id": "...",
        "issue_id": "...",
        "comment": {...}
      }

    We extract the room key and broadcast to local WS clients connected
    to THIS instance.
    """
    project_id = payload.get("project_id")
    issue_id = payload.get("issue_id")

    if not project_id or not issue_id:
        return

    room: RoomKey = (str(project_id), str(issue_id))
    await manager.broadcast(room, payload)


async def publish_and_broadcast(payload: dict) -> None:
    """
    Call this from HTTP routes after DB commit.

    It will:
    1) publish to Redis (so all instances get it)
    2) (optional) also broadcast locally immediately if you want

    NOTE:
    - If you publish to Redis, your own instance will also receive it back
      and rebroadcast via subscriber.
    - So local broadcast here is optional (avoid double-send).
    """
    await publish_comment_event(payload)
