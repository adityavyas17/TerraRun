"""
Territory capture logic using PostGIS spatial operations.

Core mechanic:
  1. A user's run path (LINESTRING) is buffered into a polygon (~30 m radius).
  2. That polygon is subtracted from every OTHER user's territory (ST_Difference).
  3. The polygon is unioned with the runner's own territory (ST_Union).
  4. Empty or degenerate territories are cleaned up.
"""

from sqlalchemy.orm import Session
from sqlalchemy import func
from geoalchemy2.shape import from_shape, to_shape
from geoalchemy2 import functions as gfunc
from shapely.geometry import LineString, mapping
from shapely.ops import unary_union
from shapely import wkt

from app.models import Territory


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BUFFER_METERS = 30          # radius around the run path
SRID_WGS84 = 4326          # GPS coordinates
SRID_METRIC = 3857         # Web-Mercator for metre-based buffer


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _linestring_from_coords(coords: list[list[float]]) -> LineString | None:
    """Convert [[lat, lng], ...] to a Shapely LineString (lng, lat order).

    Returns None if fewer than 2 valid points.
    """
    points = [(lng, lat) for lat, lng in coords if lat is not None and lng is not None]
    if len(points) < 2:
        return None
    return LineString(points)


def _buffer_route_to_polygon(route: LineString, buffer_m: float = BUFFER_METERS):
    """Buffer a WGS-84 LineString by *buffer_m* metres via Web-Mercator projection.

    We do NOT use pyproj here — instead we let PostGIS handle the transform
    inside ``claim_territory`` via ST_Transform.  This helper only builds the
    raw SQL expression.
    """
    # We'll push raw WGS-84 linestring into PostGIS and transform there.
    return route


# ---------------------------------------------------------------------------
# Core territory operations (executed inside a DB session)
# ---------------------------------------------------------------------------

def claim_territory(user_id: int, route_coords: list[list[float]], db: Session) -> dict:
    """Run the full territory-claim pipeline and return summary info.

    Parameters
    ----------
    user_id : int
        The authenticated user.
    route_coords : list[list[float]]
        GPS coordinates as [[lat, lng], …].
    db : Session
        Active SQLAlchemy session (caller must commit/rollback).

    Returns
    -------
    dict with keys:
        claimed_area_sq_m  – area of the newly-claimed polygon (metres²)
        total_area_sq_m    – user's total territory after this run
        territory_geojson  – GeoJSON dict of user's full territory
    """
    line = _linestring_from_coords(route_coords)
    if line is None:
        return {"claimed_area_sq_m": 0, "total_area_sq_m": 0, "territory_geojson": None}

    # --- Step 1: Build the new polygon in PostGIS (buffer in metric CRS) ---
    line_wkt = line.wkt

    # ST_Buffer in metres using ST_Transform to/from Web-Mercator
    new_poly_expr = func.ST_Transform(
        func.ST_Buffer(
            func.ST_Transform(func.ST_GeomFromText(line_wkt, SRID_WGS84), SRID_METRIC),
            BUFFER_METERS,
        ),
        SRID_WGS84,
    )

    # Materialise into WKT so we can reuse the value
    new_poly_wkt = db.execute(func.ST_AsText(new_poly_expr)).scalar()
    if not new_poly_wkt:
        return {"claimed_area_sq_m": 0, "total_area_sq_m": 0, "territory_geojson": None}

    new_poly_geom = func.ST_GeomFromText(new_poly_wkt, SRID_WGS84)

    # --- Step 2: Subtract from every other user's territory ---------------
    rival_territories = (
        db.query(Territory)
        .filter(Territory.user_id != user_id)
        .all()
    )

    for rival in rival_territories:
        diff = db.execute(
            func.ST_AsText(
                func.ST_Difference(rival.geom, new_poly_geom)
            )
        ).scalar()

        if diff is None or diff == "GEOMETRYCOLLECTION EMPTY":
            db.delete(rival)
        else:
            rival.geom = func.ST_GeomFromText(diff, SRID_WGS84)
            # Recompute area (in sq metres via Web-Mercator)
            rival.area_sq_m = db.execute(
                func.ST_Area(func.ST_Transform(func.ST_GeomFromText(diff, SRID_WGS84), SRID_METRIC))
            ).scalar() or 0.0

    # --- Step 3: Union with user's own territory --------------------------
    own = (
        db.query(Territory)
        .filter(Territory.user_id == user_id)
        .first()
    )

    if own is None:
        # First territory for this user
        area = db.execute(
            func.ST_Area(func.ST_Transform(new_poly_geom, SRID_METRIC))
        ).scalar() or 0.0

        own = Territory(
            user_id=user_id,
            geom=func.ST_GeomFromText(new_poly_wkt, SRID_WGS84),
            area_sq_m=area,
        )
        db.add(own)
    else:
        merged_wkt = db.execute(
            func.ST_AsText(
                func.ST_Union(own.geom, new_poly_geom)
            )
        ).scalar()
        own.geom = func.ST_GeomFromText(merged_wkt, SRID_WGS84)
        own.area_sq_m = db.execute(
            func.ST_Area(func.ST_Transform(func.ST_GeomFromText(merged_wkt, SRID_WGS84), SRID_METRIC))
        ).scalar() or 0.0

    db.flush()  # so own.area_sq_m is populated

    # --- Step 4: Build response -------------------------------------------
    territory_geojson_str = db.execute(
        func.ST_AsGeoJSON(own.geom)
    ).scalar()

    import json
    territory_geojson = json.loads(territory_geojson_str) if territory_geojson_str else None

    claimed_area = db.execute(
        func.ST_Area(func.ST_Transform(new_poly_geom, SRID_METRIC))
    ).scalar() or 0.0

    return {
        "claimed_area_sq_m": round(claimed_area, 2),
        "total_area_sq_m": round(own.area_sq_m, 2),
        "territory_geojson": territory_geojson,
    }
