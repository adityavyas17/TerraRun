# TerraRun — Complete Setup & Run Guide

## Prerequisites

Install these once on your machine:

| Tool | Purpose | Download |
|------|---------|----------|
| **Docker Desktop** | Runs PostgreSQL + PostGIS + backend | https://www.docker.com/products/docker-desktop |
| **Flutter SDK** | Builds and runs the mobile app | https://docs.flutter.dev/get-started/install |
| **Android Studio / Xcode** | Device emulator | https://developer.android.com/studio |

> **Windows users**: Make sure Docker Desktop is running before any `docker` commands.

---

## Step 1 — Clone / Open the project

```
TerraRun/
├── backend/          ← FastAPI + PostGIS backend
├── lib/              ← Flutter frontend source
├── docker-compose.yml
└── pubspec.yaml
```

All commands below are run from inside the `TerraRun/` directory.

---

## Step 2 — Start the Backend (Docker)

```bash
# Build images and start containers (first time takes 2-3 minutes)
docker compose up --build

# Subsequent starts (no rebuild needed)
docker compose up
```

You will see output like:
```
terrarun_db       | database system is ready to accept connections
terrarun_backend  | [1/3] Enabling PostGIS extension …
terrarun_backend  | [2/3] Creating / updating tables …
terrarun_backend  | [3/3] Verifying PostGIS version …
terrarun_backend  | INFO:     Uvicorn running on http://0.0.0.0:8000
```

✅ **Backend is ready when you see the Uvicorn line.**

Verify it works:
```bash
curl http://localhost:8000/
# → {"message":"TerraRun backend is running"}
```

Or open [http://localhost:8000/docs](http://localhost:8000/docs) in your browser for the interactive API docs.

---

## Step 3 — Configure the Flutter App

Open `lib/config.dart` and set your machine's **local IP address** (not localhost) for Android/iOS devices:

```dart
class Config {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';         // ← Web browser
    }
    return 'http://192.168.X.X:8000';        // ← Replace with YOUR local IP
  }
}
```

### How to find your local IP

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your Wi-Fi or Ethernet adapter
# Example: 192.168.1.42
```

**macOS / Linux:**
```bash
ifconfig | grep "inet "
```

> **Note**: If running on a **web browser** or **Android emulator**, you can keep `localhost:8000` — no IP change needed.

---

## Step 4 — Install Flutter Dependencies

```bash
flutter pub get
```

---

## Step 5 — Run the Flutter App

### Option A — Android Emulator (easiest on Windows)

1. Open Android Studio → **Device Manager** → Start an emulator
2. Run:
```bash
flutter run
```

### Option B — Physical Android Device

1. Enable **Developer Options** + **USB Debugging** on your phone
2. Connect via USB
3. Ensure the phone and your PC are on the **same Wi-Fi network**
4. Update `config.dart` with your PC's local IP (Step 3)
5. Run:
```bash
flutter run
```

### Option C — Chrome (Web)

```bash
flutter run -d chrome
```
No IP change needed — just use `localhost:8000` in `config.dart`.

### Option D — Windows Desktop

```bash
flutter run -d windows
```

---

## Full Startup Sequence (Quick Reference)

```
1. Start Docker Desktop
       ↓
2. cd TerraRun && docker compose up
       ↓
3. Wait for "Uvicorn running on http://0.0.0.0:8000"
       ↓
4. Update lib/config.dart with your local IP (for physical device)
       ↓
5. flutter pub get
       ↓
6. flutter run
```

---

## Stopping Everything

```bash
# Stop containers (keeps DB data)
docker compose down

# Stop containers AND delete all DB data (clean slate)
docker compose down -v
```

---

## Useful Commands

| Command | What it does |
|---------|-------------|
| `docker compose up --build` | Rebuild images and start |
| `docker compose up -d` | Start in background (detached) |
| `docker compose logs -f backend` | Stream backend logs |
| `docker compose logs -f db` | Stream database logs |
| `docker compose ps` | Check container status |
| `docker compose down` | Stop containers, keep data |
| `docker compose down -v` | Stop containers, **delete** data |
| `flutter pub get` | Install/update Flutter packages |
| `flutter run` | Run the app on connected device |
| `flutter run -d chrome` | Run in browser |
| `flutter devices` | List available devices |

---

## API Endpoints Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| `POST` | `/auth/signup` | ❌ | Register new user |
| `POST` | `/auth/login` | ❌ | Login, get JWT token |
| `POST` | `/runs` | ✅ | Save a run (+ optional GPS path) |
| `GET` | `/runs` | ✅ | Get my run history |
| `GET` | `/stats` | ✅ | Get my stats + territory area |
| `GET` | `/leaderboard` | ❌ | Global leaderboard |
| `GET` | `/territories` | ❌ | All user territories as GeoJSON |
| `GET` | `/territories/me` | ✅ | My territory as GeoJSON |

Interactive docs: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## Database Access (optional)

Connect directly to the PostgreSQL container:

```bash
docker exec -it terrarun_db psql -U terrarun -d terrarun
```

Useful SQL queries:
```sql
-- Check all users
SELECT id, name, email FROM users;

-- Check all runs
SELECT id, user_id, distance_km, duration_seconds, avg_speed, created_at FROM runs;

-- Check territory ownership and sizes
SELECT t.user_id, u.name, t.area_sq_m FROM territories t JOIN users u ON u.id = t.user_id;

-- Check PostGIS is working
SELECT PostGIS_Version();
```

---

## Troubleshooting

**Docker container fails to start:**
- Make sure Docker Desktop is running
- Check logs: `docker compose logs backend`

**Flutter can't connect to backend (on physical device):**
- Make sure phone and PC are on **same Wi-Fi**
- Double-check IP in `lib/config.dart`
- Make sure your firewall allows port 8000

**"PostGIS extension not found" error:**
- The `postgis/postgis:16-3.4` image includes PostGIS — this shouldn't happen
- Try: `docker compose down -v && docker compose up --build`

**Flutter build errors:**
- Run `flutter clean && flutter pub get`, then retry
