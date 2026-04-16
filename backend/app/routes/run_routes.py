import json

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from geoalchemy2 import functions as gfunc
from geoalchemy2.shape import from_shape
from shapely.geometry import LineString

from app.database import get_db
from app.models import Run, User
from app.schemas import RunCreateRequest, RunResponse
from app.auth import decode_access_token
from app.territory import claim_territory

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
    # Build the Run record (same as before)
    run = Run(
        user_id=current_user.id,
        distance_km=payload.distance_km,
        duration_seconds=payload.duration_seconds,
        avg_speed=payload.avg_speed,
    )

    # --- NEW: If GPS coordinates were provided, store the route and claim territory ---
    territory_result = None

    if payload.route_coordinates and len(payload.route_coordinates) >= 2:
        # Convert [[lat, lng], …] → Shapely LineString (lng, lat order)
        points = [
            (lng, lat)
            for lat, lng in payload.route_coordinates
            if lat is not None and lng is not None
        ]
        if len(points) >= 2:
            line = LineString(points)
            run.route_geom = from_shape(line, srid=4326)

            # Commit run first so it has an ID, then claim territory
            db.add(run)
            db.flush()

            territory_result = claim_territory(
                user_id=current_user.id,
                route_coords=payload.route_coordinates,
                db=db,
            )

            db.commit()
            db.refresh(run)

            # Build response with GeoJSON
            route_geojson = json.loads(
                db.execute(gfunc.ST_AsGeoJSON(run.route_geom)).scalar() or "null"
            )

            return RunResponse(
                id=run.id,
                user_id=run.user_id,
                distance_km=run.distance_km,
                duration_seconds=run.duration_seconds,
                avg_speed=run.avg_speed,
                created_at=run.created_at,
                route_geojson=route_geojson,
                territory_geojson=territory_result.get("territory_geojson") if territory_result else None,
            )

    # --- Original path: no coordinates, scalar-only save ---
    db.add(run)
    db.commit()
    db.refresh(run)
    return RunResponse(
        id=run.id,
        user_id=run.user_id,
        distance_km=run.distance_km,
        duration_seconds=run.duration_seconds,
        avg_speed=run.avg_speed,
        created_at=run.created_at,
    )


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

    results = []
    for run in runs:
        route_geojson = None
        if run.route_geom is not None:
            raw = db.execute(gfunc.ST_AsGeoJSON(run.route_geom)).scalar()
            if raw:
                route_geojson = json.loads(raw)

        results.append(RunResponse(
            id=run.id,
            user_id=run.user_id,
            distance_km=run.distance_km,
            duration_seconds=run.duration_seconds,
            avg_speed=run.avg_speed,
            created_at=run.created_at,
            route_geojson=route_geojson,
        ))

    return results