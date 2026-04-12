import sys
import os
import json
import hashlib

# Allow running as: python app.py
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import redis as redis_lib

app = Flask(__name__)
CORS(app)

# ── Database / cache connections (lazy) ──────────────────────────────────────

PG_URL = os.environ.get("DATABASE_URL", "postgresql://localhost:5432/dummykong")
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

_pg = None
_redis = None


def get_pg():
    global _pg
    if _pg is None or _pg.closed:
        _pg = psycopg2.connect(PG_URL)
        _pg.autocommit = True
        with _pg.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS fractals (
                    id SERIAL PRIMARY KEY,
                    params_hash TEXT UNIQUE NOT NULL,
                    iterations INT NOT NULL,
                    width INT NOT NULL,
                    height INT NOT NULL,
                    created_at TIMESTAMP DEFAULT now()
                )
            """)
    return _pg


def get_redis():
    global _redis
    if _redis is None:
        _redis = redis_lib.from_url(REDIS_URL, decode_responses=False)
    return _redis


def params_hash(iterations: int, width: int, height: int) -> str:
    return hashlib.sha256(f"{iterations}:{width}:{height}".encode()).hexdigest()[:16]


def mandelbrot(cx: float, cy: float, max_iter: int) -> int:
    x, y = 0.0, 0.0
    for i in range(max_iter):
        if x * x + y * y > 4.0:
            return i
        x, y = x * x - y * y + cx, 2 * x * y + cy
    return max_iter


@app.route("/api/fractal", methods=["POST"])
def fractal():
    data = request.get_json(force=True)
    iterations = int(data.get("iterations", 100))
    width = int(data.get("width", 800))
    height = int(data.get("height", 600))
    h = params_hash(iterations, width, height)

    # 1. Check Redis cache
    try:
        cached = get_redis().get(f"fractal:{h}")
        if cached:
            pixels = json.loads(cached)
            return jsonify({"pixels": pixels, "width": width, "height": height, "cached": True})
    except Exception:
        pass  # Redis down — fall through

    # 2. Compute
    pixels = []
    for py in range(height):
        for px in range(width):
            cx = (px / width) * 3.5 - 2.5
            cy = (py / height) * 2.0 - 1.0
            pixels.append(mandelbrot(cx, cy, iterations))

    # 3. Cache in Redis (60s TTL)
    try:
        get_redis().setex(f"fractal:{h}", 60, json.dumps(pixels))
    except Exception:
        pass

    # 4. Record in Postgres
    try:
        with get_pg().cursor() as cur:
            cur.execute(
                "INSERT INTO fractals (params_hash, iterations, width, height) "
                "VALUES (%s, %s, %s, %s) ON CONFLICT (params_hash) DO NOTHING",
                (h, iterations, width, height),
            )
    except Exception:
        pass

    return jsonify({"pixels": pixels, "width": width, "height": height, "cached": False})


@app.route("/api/history")
def history():
    """Return recent fractal generations from Postgres."""
    try:
        with get_pg().cursor() as cur:
            cur.execute(
                "SELECT params_hash, iterations, width, height, created_at "
                "FROM fractals ORDER BY created_at DESC LIMIT 20"
            )
            rows = cur.fetchall()
        return jsonify([
            {"hash": r[0], "iterations": r[1], "width": r[2], "height": r[3],
             "created_at": r[4].isoformat()}
            for r in rows
        ])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/health")
def health():
    pg_ok = False
    redis_ok = False
    try:
        with get_pg().cursor() as cur:
            cur.execute("SELECT 1")
        pg_ok = True
    except Exception:
        pass
    try:
        redis_ok = get_redis().ping()
    except Exception:
        pass
    return jsonify({"status": "ok", "postgres": pg_ok, "redis": redis_ok})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
