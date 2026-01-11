from __future__ import annotations

import anyio
from typing import Tuple

from app.websockets.manager import ConnectionManager

RoomKey = Tuple[str, str]

manager = ConnectionManager()


async def broadcast_to_issue(project_id: str, issue_id: str, message: dict) -> None:
    room: RoomKey = (project_id, issue_id)
    await manager.broadcast(room, message)


def broadcast_to_issue_from_http(project_id: str, issue_id: str, message: dict) -> None:
    # Safe bridge: sync HTTP endpoint -> async broadcast
    anyio.from_thread.run(broadcast_to_issue, project_id, issue_id, message)
