#!/usr/bin/env bash
# demo/run_demo.sh - Robust demo runner with port cleanup and retry logic
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
STOP_MONITORING="${STOP_MONITORING:-0}"

mkdir -p "$DEMO_DIR"

log() { printf "\n[demo] %s\n" "$*"; }
error() { printf "\n[demo] ERROR: %s\n" "$*" >&2; }

# Port cleanup function
cleanup_ports() {
    local ports=("$API_PORT" "$METRICS_PORT" "$PROMETHEUS_PORT" "$GRAFANA_PORT" "$FLUTTER_PORT")
    log "Cleaning up ports: ${ports[*]}"
    
    for port in "${ports[@]}"; do
        if command -v lsof >/dev/null 2>&1; then
            local pids
            pids=$(lsof -ti:"$port" 2>/dev/null || true)
            if [ -n "$pids" ]; then
                log "Killing processes on port $port: $pids"
                echo "$pids" | xargs -r kill -9 2>/dev/null || true
            fi
        elif command -v ss >/dev/null 2>&1; then
            local pids
            pids=$(ss -tlnp | grep ":$port " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' || true)
            if [ -n "$pids" ]; then
                log "Killing processes on port $port: $pids"
                echo "$pids" | xargs -r kill -9 2>/dev/null || true
            fi
        elif command -v netstat >/dev/null 2>&1; then
            local pids
            pids=$(netstat -tlnp 2>/dev/null | grep ":$port " | sed -n 's/.* \([0-9]*\)\/.*/\1/p' || true)
            if [ -n "$pids" ]; then
                log "Killing processes on port $port: $pids"
                echo "$pids" | xargs -r kill -9 2>/dev/null || true
            fi
        else
            log "No port cleanup tool available (lsof/ss/netstat)"
        fi
    done
    sleep 2
}

# Wait for URL function
wait_for_url() {
    local url=$1
    local timeout=${2:-30}
    local i=0
    until curl -s --max-time 2 "$url" >/dev/null 2>&1; do
        i=$((i+1))
        if [ $i -ge $timeout ]; then
            error "timeout waiting for $url"
            return 1
        fi
        sleep 1
    done
    return 0
}

# Cleanup function
cleanup() {
    log "Cleaning up demo processes..."
    
    # Kill backend
    if [ -f "$DEMO_DIR/backend.pid" ]; then
        local pid
        pid=$(cat "$DEMO_DIR/backend.pid" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log "Stopping backend (pid $pid)"
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$DEMO_DIR/backend.pid"
    fi
    
    # Kill flutter
    if [ -f "$DEMO_DIR/flutter.pid" ]; then
        local pid
        pid=$(cat "$DEMO_DIR/flutter.pid" 2>/dev/null || true)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log "Stopping flutter (pid $pid)"
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$DEMO_DIR/flutter.pid"
    fi
    
    # Stop monitoring if requested
    if [ "${STOP_MONITORING}" = "1" ] && [ -f "monitoring/docker-compose.yml" ]; then
        log "Stopping monitoring stack..."
        (cd monitoring && docker compose down) 2>/dev/null || true
    fi
    
    log "Done cleanup."
}
trap cleanup EXIT

log "Starting robust demo (RUN_HEADLESS=${RUN_HEADLESS})"

# Clean up ports first
cleanup_ports

# Set environment variables
export API_PORT METRICS_PORT HF_HOME TRANSFORMERS_CACHE

# Activate venv if present
if [ -f "./.venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    source ./.venv/bin/activate
    log "Activated .venv"
fi

# Start backend
log "Starting backend on port $API_PORT..."
BACKEND_LOG="$DEMO_DIR/backend.log"
nohup $PYTHON app.py > "$BACKEND_LOG" 2>&1 &
backend_pid=$!
echo "$backend_pid" > "$DEMO_DIR/backend.pid"
log "Backend started (pid $backend_pid), logging -> $BACKEND_LOG"

# Wait for backend health
log "Waiting for backend health at http://127.0.0.1:${API_PORT}/api/health"
if ! wait_for_url "http://127.0.0.1:${API_PORT}/api/health" 30; then
    error "Backend did not become healthy within timeout. Check $BACKEND_LOG"
    tail -n 80 "$BACKEND_LOG" || true
    exit 1
fi
log "Backend healthy."

# Save health response
curl -s "http://127.0.0.1:${API_PORT}/api/health" | jq . 2>/dev/null > "$DEMO_DIR/health_response.json" || true

# Start monitoring stack if available
if [ -f "monitoring/docker-compose.yml" ]; then
    log "Starting monitoring stack..."
    if command -v docker >/dev/null 2>&1; then
        (cd monitoring && docker compose up -d) || log "Failed to start monitoring stack"
        wait_for_url "http://127.0.0.1:${PROMETHEUS_PORT}" 20 || log "Prometheus not ready"
        wait_for_url "http://127.0.0.1:${GRAFANA_PORT}" 20 || log "Grafana not ready"
    else
        log "Docker not available; skipping monitoring startup"
    fi
else
    log "No monitoring/docker-compose.yml found; skipping monitoring startup"
fi

# Start Flutter web server with retry logic
if command -v flutter >/dev/null 2>&1; then
    log "Starting Flutter web server on port $FLUTTER_PORT..."
    cd flutter_frontend
    
    flutter_attempts=0
    flutter_max_attempts=3
    flutter_started=false
    
    while [ $flutter_attempts -lt $flutter_max_attempts ] && [ "$flutter_started" = "false" ]; do
        flutter_attempts=$((flutter_attempts + 1))
        log "Flutter attempt $flutter_attempts/$flutter_max_attempts"
        
        # Clean up port before retry
        if [ $flutter_attempts -gt 1 ]; then
            cleanup_ports
        fi
        
        # Try to start Flutter
        if flutter run -d web-server --web-port "$FLUTTER_PORT" > "../demo/flutter.log" 2>&1 &
        then
            flutter_pid=$!
            echo "$flutter_pid" > "../demo/flutter.pid"
            log "Flutter started (pid $flutter_pid), logging -> $DEMO_DIR/flutter.log"
            
            # Wait for Flutter to be ready
            if wait_for_url "http://127.0.0.1:${FLUTTER_PORT}" 30; then
                log "Flutter web server ready"
                flutter_started=true
            else
                log "Flutter web server not ready, will retry..."
                kill "$flutter_pid" 2>/dev/null || true
                rm -f "../demo/flutter.pid"
            fi
        else
            log "Failed to start Flutter, will retry..."
        fi
        
        if [ "$flutter_started" = "false" ] && [ $flutter_attempts -lt $flutter_max_attempts ]; then
            log "Waiting 2s before retry..."
            sleep 2
        fi
    done
    
    cd "$ROOT"
    
    if [ "$flutter_started" = "false" ]; then
        log "Flutter web server failed to start after $flutter_max_attempts attempts"
        rm -f "$DEMO_DIR/flutter.pid"
    fi
else
    log "Flutter CLI not found; skipping Flutter start"
fi

# Create sample images if missing
log "Ensuring sample images..."
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
if curl -s -X POST "http://127.0.0.1:${API_PORT}/api/count" \
    -F "image=@tests/data/sample_car.jpg" \
    -F "item_type=car" -o "$DEMO_DIR/resp_benign.json"; then
    log "Saved $DEMO_DIR/resp_benign.json"
else
    error "Failed to run benign request"
    exit 1
fi

log "Running blocked request..."
if curl -s -X POST "http://127.0.0.1:${API_PORT}/api/count" \
    -F "image=@tests/data/sample_tank.jpg" \
    -F "item_type=tank" -o "$DEMO_DIR/resp_blocked.json"; then
    log "Saved $DEMO_DIR/resp_blocked.json"
else
    error "Failed to run blocked request"
    exit 1
fi

# Fetch metrics
log "Fetching metrics..."
if curl -s "http://127.0.0.1:${API_PORT}/metrics" -o "$DEMO_DIR/metrics_snippet.txt"; then
    log "Metrics written to $DEMO_DIR/metrics_snippet.txt"
else
    error "Could not fetch metrics from ${API_PORT}"
    exit 1
fi

# Validate results
log "Validating results..."

# Check benign response has required fields
if ! jq -e '.confidence and .processing_time' "$DEMO_DIR/resp_benign.json" >/dev/null 2>&1; then
    error "Benign response missing confidence or processing_time"
    exit 1
fi

# Check metrics has model confidence
if ! grep -q "ai_object_counting_model_confidence" "$DEMO_DIR/metrics_snippet.txt"; then
    error "Metrics missing ai_object_counting_model_confidence"
    exit 1
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