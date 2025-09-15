#!/usr/bin/env bash
# demo/run_demo.sh - One-click demo runner (M1-friendly)
# Usage:
#   ./demo/run_demo.sh           -> interactive demo (keeps running)
#   RUN_HEADLESS=1 ./demo/run_demo.sh -> run demo requests and exit (non-blocking)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ---------- Config (override via env) ----------
API_PORT="${API_PORT:-5001}"
METRICS_PORT="${METRICS_PORT:-5002}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
FLUTTER_PORT="${FLUTTER_PORT:-3000}"
HF_HOME="${HF_HOME:-$ROOT/.huggingface_cache}"
TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-$ROOT/.huggingface_cache}"
DEMO_DIR="${DEMO_DIR:-$ROOT/demo}"
PYTHON="${PYTHON:-python3}"
RUN_HEADLESS="${RUN_HEADLESS:-0}"

mkdir -p "$DEMO_DIR"
log() { printf "\n[demo] %s\n" "$*"; }
wait_for_url() {
  local url=$1; local timeout=${2:-30}
  local i=0
  until curl -s --max-time 2 "$url" >/dev/null 2>&1; do
    i=$((i+1))
    if [ $i -ge $timeout ]; then
      echo "timeout waiting for $url" >&2
      return 1
    fi
    sleep 1
  done
  return 0
}

cleanup() {
  log "Cleaning up demo processes..."
  if [ -f "$DEMO_DIR/backend.pid" ]; then
    pid=$(cat "$DEMO_DIR/backend.pid" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      log "Stopping backend (pid $pid)"
      kill "$pid" || true
    fi
    rm -f "$DEMO_DIR/backend.pid"
  fi
  if [ -f "$DEMO_DIR/flutter.pid" ]; then
    pid=$(cat "$DEMO_DIR/flutter.pid" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      log "Stopping flutter (pid $pid)"
      kill "$pid" || true
    fi
    rm -f "$DEMO_DIR/flutter.pid"
  fi
  log "Done cleanup."
}
trap cleanup EXIT

log "Starting demo (RUN_HEADLESS=${RUN_HEADLESS})"
export API_PORT METRICS_PORT HF_HOME TRANSFORMERS_CACHE

# Activate venv if present
if [ -f "./.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source ./.venv/bin/activate
  log "Activated .venv"
fi

BACKEND_LOG="$DEMO_DIR/backend.log"
nohup $PYTHON app.py > "$BACKEND_LOG" 2>&1 &
backend_pid=$!
echo "$backend_pid" > "$DEMO_DIR/backend.pid"
log "Backend started (pid $backend_pid), logging -> $BACKEND_LOG"

log "Waiting for backend health at http://127.0.0.1:${API_PORT}/api/health"
if ! wait_for_url "http://127.0.0.1:${API_PORT}/api/health" 30; then
  log "Backend did not become healthy within timeout. Check $BACKEND_LOG"
  tail -n 80 "$BACKEND_LOG" || true
  exit 1
fi
log "Backend healthy."
curl -s "http://127.0.0.1:${API_PORT}/api/health" | jq . 2>/dev/null > "$DEMO_DIR/health_response.json" || true

# Try to start monitoring stack if monitoring/docker-compose.yml exists
if [ -f "monitoring/docker-compose.yml" ]; then
  log "Starting monitoring stack..."
  (cd monitoring && docker compose up -d) || true
  wait_for_url "http://127.0.0.1:${PROMETHEUS_PORT}" 20 || log "Prometheus not ready"
  wait_for_url "http://127.0.0.1:${GRAFANA_PORT}" 20 || log "Grafana not ready"
else
  log "No monitoring/docker-compose.yml found; skipping monitoring startup"
fi

# Optionally start Flutter web (only if 'flutter' is on PATH)
if command -v flutter >/dev/null 2>&1; then
  log "Starting Flutter web server..."
  cd flutter_frontend
  flutter pub get >/dev/null 2>&1 || true
  nohup flutter run -d web-server --web-port "${FLUTTER_PORT}" > "$DEMO_DIR/flutter.log" 2>&1 &
  flutter_pid=$!
  echo "$flutter_pid" > "$DEMO_DIR/flutter.pid"
  cd "$ROOT"
  log "Waiting for Flutter web server..."
  wait_for_url "http://127.0.0.1:${FLUTTER_PORT}" 30 || log "Flutter web not ready"
else
  log "Flutter CLI not found; skipping Flutter start"
fi

# Ensure sample images
python3 - <<'PY' || true
from pathlib import Path
from PIL import Image
p=Path('tests/data'); p.mkdir(parents=True, exist_ok=True)
for n,c in [('sample_car.jpg',(160,160,160)),('sample_tank.jpg',(80,80,80))]:
    f=p/n
    if not f.exists():
        img=Image.new('RGB',(64,64),c)
        img.save(str(f),'JPEG')
print("samples ready")
PY

# Run demo requests
log "Running benign request..."
curl -s -X POST "http://127.0.0.1:${API_PORT}/api/count" \
  -F "image=@tests/data/sample_car.jpg" \
  -F "item_type=car" -o "$DEMO_DIR/resp_benign.json" || true
log "Saved $DEMO_DIR/resp_benign.json"

log "Running blocked request..."
curl -s -X POST "http://127.0.0.1:${API_PORT}/api/count" \
  -F "image=@tests/data/sample_tank.jpg" \
  -F "item_type=tank" -o "$DEMO_DIR/resp_blocked.json" || true
log "Saved $DEMO_DIR/resp_blocked.json"

# Fetch metrics
if curl -s "http://127.0.0.1:${METRICS_PORT}/metrics" -o "$DEMO_DIR/metrics_snippet.txt"; then
  log "Metrics written to $DEMO_DIR/metrics_snippet.txt"
else
  log "Could not fetch metrics from ${METRICS_PORT}"
fi

log "=== Demo outputs ==="
ls -l "$DEMO_DIR"/resp_*.json "$DEMO_DIR"/metrics_snippet.txt "$DEMO_DIR"/backend.log || true
log "Benign:"
jq . "$DEMO_DIR/resp_benign.json" 2>/dev/null || cat "$DEMO_DIR/resp_benign.json" || true
log "Blocked:"
jq . "$DEMO_DIR/resp_blocked.json" 2>/dev/null || cat "$DEMO_DIR/resp_blocked.json" || true

# Open in browser on macOS
if [ "$(uname -s)" = "Darwin" ]; then
  [ -f "$DEMO_DIR/flutter.pid" ] && open "http://127.0.0.1:${FLUTTER_PORT}/" || true
  [ -f "monitoring/docker-compose.yml" ] && open "http://127.0.0.1:${GRAFANA_PORT}/" || true
fi

if [ "${RUN_HEADLESS}" = "1" ] || [ "${RUN_HEADLESS}" = "true" ]; then
  log "Headless run complete. Exiting."
  exit 0
fi

log "Interactive demo started. Press Ctrl+C to exit (cleanup will run)."
# Keep running so user can interact
while sleep 600; do :; done