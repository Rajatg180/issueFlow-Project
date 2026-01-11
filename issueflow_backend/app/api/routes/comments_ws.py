from __future__ import annotations

from uuid import UUID
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlmodel import Session

from app.db.session import engine
from app.core.ws_auth import get_current_user_ws
from app.services.comment_service import list_comments
from app.websockets.comments_hub import manager

router = APIRouter(tags=["Comments WS"])


def _comment_to_dict(c) -> dict:
    # Convert DB model -> JSON serializable dict
    # (JSON can't directly send UUID/datetime objects, so we stringify/isoformat them)
    return {
        "id": str(c.id),
        "project_id": str(c.project_id),
        "issue_id": str(c.issue_id),
        "author_id": str(c.author_id),
        "author_username": c.author_username,
        "body": c.body,
        "edited": c.edited,
        "created_at": c.created_at.isoformat(),
        "updated_at": c.updated_at.isoformat(),
    }


@router.websocket("/ws/projects/{project_id}/issues/{issue_id}/comments")
async def ws_issue_comments(websocket: WebSocket, project_id: UUID, issue_id: UUID):
    # A room is the group of all clients watching this same issue
    room = (str(project_id), str(issue_id))

    # WebSocket endpoints don't use Depends(get_db) the same way,
    # so we manually create a DB session.
    with Session(engine) as db:
        try:
            # 1) Authenticate user from ?token=ACCESS_JWT
            user = get_current_user_ws(websocket, db)

            # 2) Validate permissions + issue exists by calling list_comments()
            #    (this reuses your existing permission checks)
            existing = list_comments(db=db, project_id=project_id, issue_id=issue_id, user=user)

            # 3) Accept and register socket into the room
            await manager.connect(room, websocket)

            # 4) Send initial snapshot (optional but very useful for UI)
            #    If you prefer "events-only", you can remove this snapshot block.
            await websocket.send_json(
                {
                    "type": "snapshot",
                    "project_id": str(project_id),
                    "issue_id": str(issue_id),
                    "comments": [_comment_to_dict(c) for c in existing],
                }
            )

            # 5) Keep the connection alive.
            #    IMPORTANT: WS is "read-only" in this architecture.
            #    All create/edit/delete happens via HTTP and HTTP broadcasts updates.
            while True:
                data = await websocket.receive_json()
                msg_type = (data.get("type") or "").strip()

                # keep-alive
                if msg_type == "ping":
                    await websocket.send_json({"type": "pong"})
                    continue

                # reject any attempts to write via WS (enforces your scalable pattern)
                await websocket.send_json(
                    {
                        "type": "error",
                        "message": "WebSocket is read-only. Use HTTP for create/edit/delete.",
                    }
                )

        except WebSocketDisconnect:
            # Client closed connection
            await manager.disconnect(room, websocket)
            return

        except ValueError as e:
            # Auth/access/validation error
            # We may not have accepted yet, so accept safely to send the error.
            try:
                await websocket.accept()
                await websocket.send_json({"type": "error", "message": str(e)})
            except Exception:
                pass

            try:
                await websocket.close()
            except Exception:
                pass
            return

        except Exception:
            # Unexpected server error (don't leak details)
            try:
                await websocket.send_json({"type": "error", "message": "Server error"})
            except Exception:
                pass

            await manager.disconnect(room, websocket)
            try:
                await websocket.close()
            except Exception:
                pass
            return
