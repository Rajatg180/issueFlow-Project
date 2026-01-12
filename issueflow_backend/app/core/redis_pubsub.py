from __future__ import annotations

import asyncio
import json
from typing import Awaitable, Callable, Optional

import app.core.redis_client as redis_mod

# One Redis channel for publishing comment events
COMMENTS_CHANNEL = "issueflow:comments"

_sub_task: Optional[asyncio.Task] = None


async def publish_comment_event(payload: dict) -> None:
    """
    Called by HTTP routes:
    - publish an event to Redis
    - all backend instances will receive it
    """
    if redis_mod.redis_client is None:
        # Redis not connected -> can't sync instances
        return

    # Redis Pub/Sub payload must be string/bytes -> use JSON string
    try:
        message = json.dumps(payload)
    except Exception:
        # If payload is not JSON-serializable, just skip publishing
        return

    await redis_mod.redis_client.publish(COMMENTS_CHANNEL, message)


async def _subscriber_loop(on_event: Callable[[dict], Awaitable[None]]) -> None:
    """
    Runs forever:
    - subscribes to Redis channel
    - receives messages
    - calls on_event(payload)
    """
    if redis_mod.redis_client is None:
        return

    pubsub = redis_mod.redis_client.pubsub()
    await pubsub.subscribe(COMMENTS_CHANNEL)

    try:
        while True:
            # Wait for a message (timeout keeps loop responsive)
            msg = await pubsub.get_message(
                ignore_subscribe_messages=True,
                timeout=1.0,
            )

            if msg is None:
                # No message received -> yield CPU a bit
                await asyncio.sleep(0.05)
                continue

            raw = msg.get("data")

            # If decode_responses=True, this will already be a string.
            # But keep bytes support just in case.
            if isinstance(raw, (bytes, bytearray)):
                raw = raw.decode("utf-8", errors="ignore")

            if not isinstance(raw, str) or not raw.strip():
                continue

            # ✅ JSON safety guard (IMPORTANT)
            try:
                payload = json.loads(raw)
            except Exception:
                # bad message should not crash the whole subscriber
                continue

            # Pass the message to our callback (broadcast to WS clients)
            try:
                await on_event(payload)
            except Exception:
                # Never crash subscriber because of one bad broadcast
                continue

    except asyncio.CancelledError:
        # Shutdown cancels the task -> exit gracefully
        pass

    finally:
        # Cleanup pubsub subscription
        try:
            await pubsub.unsubscribe(COMMENTS_CHANNEL)
        except Exception:
            pass

        try:
            await pubsub.close()
        except Exception:
            pass


async def start_comments_pubsub(on_event: Callable[[dict], Awaitable[None]]) -> None:
    """
    Start the background subscriber task once per backend process.
    """
    global _sub_task

    if _sub_task is not None and not _sub_task.done():
        return  # already running

    _sub_task = asyncio.create_task(_subscriber_loop(on_event))


async def stop_comments_pubsub() -> None:
    """
    Stop the background subscriber task.
    """
    global _sub_task

    if _sub_task is None:
        return

    _sub_task.cancel()
    try:
        await _sub_task
    except Exception:
        pass
    _sub_task = None
