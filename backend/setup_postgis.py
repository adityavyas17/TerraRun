"""
One-time setup script to enable PostGIS and create / migrate tables.

Usage:
    python setup_postgis.py

Prerequisites:
    - PostgreSQL with PostGIS extension installed.
    - The 'terrarun' database already exists.
"""

from sqlalchemy import text
from app.database import engine, Base

# Import all models so Base.metadata knows about them
import app.models  # noqa: F401


def main():
    print("[1/3] Enabling PostGIS extension …")
    with engine.connect() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis;"))
        conn.commit()
    print("      ✓ PostGIS enabled")

    print("[2/3] Creating / updating tables …")
    Base.metadata.create_all(bind=engine)
    print("      ✓ Tables synced")

    print("[3/3] Verifying PostGIS version …")
    with engine.connect() as conn:
        version = conn.execute(text("SELECT PostGIS_Full_Version();")).scalar()
    print(f"      ✓ {version}")

    print("\nDone!  Your database is ready for territory capture.")


if __name__ == "__main__":
    main()
