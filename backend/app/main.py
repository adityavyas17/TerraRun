from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from app.routes.auth_routes import router as auth_router
from app.routes.run_routes import router as run_router
from app.routes.stats_routes import router as stats_router
from app.routes.leaderboard_routes import router as leaderboard_router


Base.metadata.create_all(bind=engine)

app = FastAPI(title="TerraRun API")
app.include_router(auth_router)
app.include_router(run_router)
app.include_router(leaderboard_router)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(run_router)
app.include_router(stats_router)


@app.get("/")
def root():
    return {"message": "TerraRun backend is running"}