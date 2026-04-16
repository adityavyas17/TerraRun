FROM python:3.12-slim

WORKDIR /app

# Install system deps for psycopg2 and GEOS (needed by shapely)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq-dev gcc libgeos-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Enable PostGIS extension on startup, then launch uvicorn
CMD ["sh", "-c", "python /app/setup_postgis.py && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
