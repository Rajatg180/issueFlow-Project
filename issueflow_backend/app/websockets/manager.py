from __future__ import annotations

from typing import Dict,Set,Tuple
from fastapi import WebSocket
import asyncio

# here one room is one issue inside one project
RoomKey  = Tuple[str, str]  # (project_id, issue_id)

class ConnectionManager:
    # this is method in python which is called when an instance of the class is created
    def __init__(self) -> None:
        # store all active connections
        # {
        #   ("project1", "issue1"): {wsA, wsB},
        #   ("project1", "issue2"): {wsC},
        # }
        self._rooms: Dict[RoomKey, Set[WebSocket]] = {}
        # multiple peoples can connect / disconnect at the same time , so to avoid race conditions we use a lock
        self._lock = asyncio.Lock() 

    async def connect(self, room:RoomKey , websocket: WebSocket) -> None:
        await websocket.accept() # accept the connection before sending/receiving messages
        async with self._lock:
            # If room doesn't exist yet, create it.
            # Then add this websocket connection to the room.
            self._rooms.setdefault(room, set()).add(websocket)

    async def disconnect(self, room: RoomKey, websocket: WebSocket) -> None:
        # Lock before changing shared state (_rooms).
        async with self._lock:
            if room in self._rooms:
                # Remove this websocket from the room.
                self._rooms[room].discard(websocket)

                # If no one is left in the room, remove the room entirely.
                if not self._rooms[room]:
                    del self._rooms[room]

    async def broadcast(self, room: RoomKey, message: dict) -> None:
        # Copy the connections list while holding lock
        # so it doesn't change while we are iterating.
        async with self._lock:
            targets = list(self._rooms.get(room, set()))

        # Track sockets that are broken/disconnected.
        dead: list[WebSocket] = []

        # Send the message to every connected client in that room.
        for ws in targets:
            try:
                await ws.send_json(message)
            except Exception:
                # If send fails, that socket is dead (client closed etc.)
                dead.append(ws)

        # Cleanup dead sockets from the room.
        if dead:
            async with self._lock:
                for ws in dead:
                    if room in self._rooms:
                        self._rooms[room].discard(ws)

                # If room becomes empty after removing dead sockets, delete it.
                if room in self._rooms and not self._rooms[room]:
                    del self._rooms[room]