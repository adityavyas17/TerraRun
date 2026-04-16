from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models import Run, User, Territory

router = APIRouter()


@router.get("/leaderboard")
def get_leaderboard(db: Session = Depends(get_db)):
    results = (
        db.query(
            User.id,
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

    # Pre-fetch territory areas for all users with territories
    territory_map = {}
    territories = db.query(Territory.user_id, Territory.area_sq_m).all()
    for t in territories:
        territory_map[t.user_id] = round(t.area_sq_m, 2)

    leaderboard = []
    for r in results:
        leaderboard.append({
            "name": r.name,
            "total_distance": float(r.total_distance or 0),
            "total_runs": int(r.total_runs or 0),
            "avg_speed": float(r.avg_speed or 0),
            # --- NEW: territory area ---
            "territory_area": territory_map.get(r.id, 0.0),
        })

    return leaderboard