from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models import Run, User

router = APIRouter()


@router.get("/leaderboard")
def get_leaderboard(db: Session = Depends(get_db)):
    results = (
        db.query(
            User.name,
            func.sum(Run.distance_km).label("total_distance"),
            func.count(Run.id).label("total_runs"),
            func.avg(Run.avg_speed).label("avg_speed"),
        )
        .join(Run, Run.user_id == User.id)
        .group_by(User.id, User.name)
        .order_by(func.sum(Run.distance_km).desc())
        .all()
    )

    leaderboard = []
    for r in results:
        leaderboard.append({
            "name": r.name,
            "total_distance": float(r.total_distance or 0),
            "total_runs": int(r.total_runs or 0),
            "avg_speed": float(r.avg_speed or 0),
        })

    return leaderboard