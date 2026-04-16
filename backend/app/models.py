from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.sql import func
from geoalchemy2 import Geometry
from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)


class Run(Base):
    __tablename__ = "runs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    distance_km = Column(Float, nullable=False)
    duration_seconds = Column(Integer, nullable=False)
    avg_speed = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # --- NEW: optional GPS track stored as a PostGIS LINESTRING ---
    route_geom = Column(
        Geometry("LINESTRING", srid=4326, spatial_index=True),
        nullable=True,
    )


class Territory(Base):
    """Each user has at most one territory polygon, grown/shrunk by runs."""
    __tablename__ = "territories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    geom = Column(
        Geometry("GEOMETRY", srid=4326, spatial_index=True),
        nullable=False,
    )
    area_sq_m = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )