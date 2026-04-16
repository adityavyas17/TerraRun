import json

from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from geoalchemy2 import functions as gfunc

from app.database import get_db
from app.models import Territory, User
from app.schemas import TerritoryResponse, TerritoryListResponse
from app.auth import decode_access_token

router = APIRouter(prefix="/territories", tags=["territories"])


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


@router.get("", response_model=TerritoryListResponse)
def get_all_territories(db: Session = Depends(get_db)):
    """Return every user's territory as GeoJSON (for rendering on the map)."""
    territories = (
        db.query(Territory, User.name)
        .join(User, User.id == Territory.user_id)
        .all()
    )

    items = []
    for terr, user_name in territories:
        geojson_str = db.execute(gfunc.ST_AsGeoJSON(terr.geom)).scalar()
        geojson = json.loads(geojson_str) if geojson_str else None

        items.append(TerritoryResponse(
            user_id=terr.user_id,
            user_name=user_name,
            area_sq_m=round(terr.area_sq_m, 2),
            geojson=geojson,
        ))

    return TerritoryListResponse(territories=items)


@router.get("/me", response_model=TerritoryResponse)
def get_my_territory(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return the authenticated user's territory."""
    terr = (
        db.query(Territory)
        .filter(Territory.user_id == current_user.id)
        .first()
    )

    if terr is None:
        return TerritoryResponse(
            user_id=current_user.id,
            user_name=current_user.name,
            area_sq_m=0.0,
            geojson=None,
        )

    geojson_str = db.execute(gfunc.ST_AsGeoJSON(terr.geom)).scalar()
    geojson = json.loads(geojson_str) if geojson_str else None

    return TerritoryResponse(
        user_id=current_user.id,
        user_name=current_user.name,
        area_sq_m=round(terr.area_sq_m, 2),
        geojson=geojson,
    )
