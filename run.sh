#!/usr/bin/env bash
# DummyKong — run all three components
# Usage: ./run.sh [--clean]

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$ROOT")"
KONG_INSTALL="$(dirname "$(command -v kong)")"
ENV_DIR="$KONG_INSTALL/RULEZ/$PROJECT_NAME"

# ── 1. kong setup ───────────────────────────────────────────────────────────
if [[ "$1" == "--clean" ]]; then
    echo "[kong] Cleaning environments..."
    kong use "$ROOT/kong.rules" --clean
fi

if [[ ! -f "$ROOT/kong.rules" ]]; then
    echo "[kong] Generating kong.rules..."
    (cd "$ROOT" && kong rules)
fi

echo "[kong] Setting up environments in $ENV_DIR ..."
kong use "$ROOT/kong.rules"

# ── 2. Activate Python venv ─────────────────────────────────────────────────
if [[ -f "$ENV_DIR/.venv/bin/activate" ]]; then
    source "$ENV_DIR/.venv/bin/activate"
fi

# ── 3. Build Rust fractal binary ────────────────────────────────────────────
echo "[fractal] Building Rust binary..."
if [[ -f "$ENV_DIR/.rust-toolchain/activate.sh" ]]; then
    source "$ENV_DIR/.rust-toolchain/activate.sh"
fi
(cd "$ROOT" && cargo build --release)

# ── 4. Start Flask backend (background) ─────────────────────────────────────
echo "[backend] Starting Flask on http://localhost:5000 ..."
python "$ROOT/src/backend/app.py" &
BACKEND_PID=$!

# ── 5. Start Vite frontend (background) ─────────────────────────────────────
echo "[frontend] Starting Vite on http://localhost:5173 ..."
(cd "$ROOT" && node "$ENV_DIR/node_modules/vite/bin/vite.js") &
FRONTEND_PID=$!

# ── 6. Show fractal demo ─────────────────────────────────────────────────────
echo "[fractal] Running ASCII demo..."
"$ROOT/target/release/fractal"

echo ""
echo "Backend  → http://localhost:5000"
echo "Frontend → http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop all services."

cleanup() {
    echo "Stopping services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    wait $BACKEND_PID $FRONTEND_PID 2>/dev/null
}
trap cleanup INT TERM
wait
