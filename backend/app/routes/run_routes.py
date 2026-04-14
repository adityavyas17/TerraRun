from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Run, User
from app.schemas import RunCreateRequest, RunResponse
from app.auth import decode_access_token

router = APIRouter(prefix="/runs", tags=["runs"])


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


@router.post("", response_model=RunResponse)
def create_run(
    payload: RunCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    run = Run(
        user_id=current_user.id,
        distance_km=payload.distance_km,
        duration_seconds=payload.duration_seconds,
        avg_speed=payload.avg_speed,
    )
    db.add(run)
    db.commit()
    db.refresh(run)
    return run


@router.get("", response_model=list[RunResponse])
def get_runs(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    runs = (
        db.query(Run)
        .filter(Run.user_id == current_user.id)
        .order_by(Run.id.desc())
        .all()
    )
    return runs