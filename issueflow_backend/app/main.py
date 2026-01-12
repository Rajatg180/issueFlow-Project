from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db.init_db import init_db

from app.api.routes.auth import router as auth_router
from app.api.routes.onboarding import router as onboarding_router
from app.api.routes.projects import router as projects_router
from app.api.routes.issues import router as issues_router
from app.api.routes.project_invites import router as project_invites_router
from app.api.routes.invites import router as invites_router
from app.api.routes.users import router as users_router
from app.api.routes.comments import router as comments_router
from app.api.routes.dashboard import router as dashboard_router
from app.api.routes.comments_ws import router as comments_ws_router

import app.core.redis_client as redis_mod
from app.core.redis_pubsub import start_comments_pubsub, stop_comments_pubsub
from app.websockets.comments_hub import rebroadcast_from_redis

app = FastAPI(title="IssueFlow API")

# CORS for Flutter Web dev server
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://127.0.0.1",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_origin_regex=r"^http://localhost:\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def on_startup():
    init_db()

    # 1) Connect to Redis
    await redis_mod.init_redis()

    # 2) Start Redis subscriber loop for this instance
    #    Every event Redis receives -> rebroadcast to local WS clients
    await start_comments_pubsub(rebroadcast_from_redis)

@app.on_event("shutdown")
async def on_shutdown():
    # stop subscriber first
    await stop_comments_pubsub()
    # then close redis connection
    await redis_mod.close_redis()

# Routers
app.include_router(auth_router)
app.include_router(onboarding_router)
app.include_router(projects_router)
app.include_router(issues_router)
app.include_router(project_invites_router)
app.include_router(invites_router)
app.include_router(users_router)
app.include_router(comments_router)
app.include_router(dashboard_router)
app.include_router(comments_ws_router)

@app.get("/health")
def health():
    return {"status": "ok"}

# Debug endpoint to check Redis connectivity
@app.get("/debug/redis")
async def debug_redis():
    if redis_mod.redis_client is None:
        return {"ok": False, "message": "Redis not connected"}
    pong = await redis_mod.redis_client.ping()
    return {"ok": True, "ping": pong}
