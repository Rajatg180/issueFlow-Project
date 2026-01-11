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
app = FastAPI(title="IssueFlow API")

app = FastAPI(title="IssueFlow API")

# CORS for Flutter Web dev server (random localhost port)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://127.0.0.1",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost:63329/"
    ],
    allow_origin_regex=r"^http://localhost:\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    init_db()

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
