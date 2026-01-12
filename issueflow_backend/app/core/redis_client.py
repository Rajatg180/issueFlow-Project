import os
from redis.asyncio import Redis

# Global Redis client variable (shared in this process)
redis_client: Redis | None = None


def get_redis_url() -> str:
    """
    Reads REDIS_URL from environment.
    Example inside docker: redis://redis:6379
    Example on host:       redis://localhost:6379
    """
    return os.getenv("REDIS_URL", "redis://localhost:6379")


async def init_redis() -> None:
    """
    Create Redis client and verify connection by ping.
    We keep it safe: if Redis is down, we don't crash the app.
    """
    global redis_client

    url = get_redis_url()
    client = Redis.from_url(url, decode_responses=True)

    try:
        # Quick connectivity check
        await client.ping()
        redis_client = client
        print(f"✅ Redis connected: {url}")
    except Exception as e:
        # Don't crash the app; just warn.
        redis_client = None
        print(f"⚠️ Redis not available at {url}. Error: {e}")


async def close_redis() -> None:
    """
    Close the client gracefully on shutdown.
    """
    global redis_client
    if redis_client is not None:
        await redis_client.close()
        redis_client = None
        print("🛑 Redis connection closed")
