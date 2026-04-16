from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models import Run, User, Territory
from app.schemas import ProfileStatsResponse
from app.auth import decode_access_token

router = APIRouter(prefix="/stats", tags=["stats"])


def get_current_user(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing token")

    token = authorization.split(" ", 1)[1]
    payload = decode_access_token(token)

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user


@router.get("", response_model=ProfileStatsResponse)
def get_profile_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    totals = (
        db.query(
            func.count(Run.id),
            func.coalesce(func.sum(Run.distance_km), 0.0),
            func.coalesce(func.avg(Run.avg_speed), 0.0),
        )
        .filter(Run.user_id == current_user.id)
        .first()
    )

    total_runs = int(totals[0] or 0)
    total_distance_km = float(totals[1] or 0.0)
    avg_speed = float(totals[2] or 0.0)

    # --- NEW: fetch territory area ---
    territory = (
        db.query(Territory)
        .filter(Territory.user_id == current_user.id)
        .first()
    )
    territory_area_sq_m = round(territory.area_sq_m, 2) if territory else 0.0

    return ProfileStatsResponse(
        total_distance_km=total_distance_km,
        total_runs=total_runs,
        avg_speed=avg_speed,
        territory_area_sq_m=territory_area_sq_m,
    )