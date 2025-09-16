#!/usr/bin/env bash
# bootstrap_and_run.sh - Bootstrap script for AI Object Counting project
# This script sets up the environment and starts all services

set -euo pipefail

# Configuration
API_PORT="${API_PORT:-5001}"
METRICS_PORT="${METRICS_PORT:-5002}"
PROMETHEUS_PORT="${PROMETHEUS_PORT:-9090}"
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
FLUTTER_PORT="${FLUTTER_PORT:-3000}"
PYTHON="${PYTHON:-python3}"
DEMO_DIR="${DEMO_DIR:-./demo}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[bootstrap]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[bootstrap]${NC} $*"
}

error() {
    echo -e "${RED}[bootstrap]${NC} $*"
}

success() {
    echo -e "${GREEN}[bootstrap]${NC} $*"
}

# Function to kill processes on specific ports
cleanup_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        if command -v lsof >/dev/null 2>&1; then
            local pids=$(lsof -ti:$port 2>/dev/null || true)
            if [ -n "$pids" ]; then
                log "Killing processes on port $port: $pids"
                echo "$pids" | xargs -r kill -9
                sleep 1
            fi
        elif command -v ss >/dev/null 2>&1; then
            local pids=$(ss -tlnp | grep ":$port " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | sort -u || true)
            if [ -n "$pids" ]; then
                log "Killing processes on port $port: $pids"
                echo "$pids" | xargs -r kill -9
                sleep 1
            fi
        else
            warn "Neither lsof nor ss available, skipping port cleanup for $port"
        fi
    done
}

# Function to wait for URL to be available
wait_for_url() {
    local url=$1
    local timeout=${2:-30}
    local i=0
    
    log "Waiting for $url to be available..."
    until curl -s --max-time 2 "$url" >/dev/null 2>&1; do
        i=$((i+1))
        if [ $i -ge $timeout ]; then
            error "Timeout waiting for $url"
            return 1
        fi
        sleep 1
    done
    success "$url is available"
    return 0
}

# Main execution
main() {
    log "Starting AI Object Counting project bootstrap..."
    
    # Create demo directory
    mkdir -p "$DEMO_DIR"
    
    # Clean up ports before starting
    log "Cleaning up ports..."
    cleanup_ports "$API_PORT" "$METRICS_PORT" "$PROMETHEUS_PORT" "$GRAFANA_PORT" "$FLUTTER_PORT"
    
    # Setup Python virtual environment
    if [ -f "requirements.txt" ]; then
        log "Setting up Python virtual environment..."
        if [ ! -d ".venv" ]; then
            $PYTHON -m venv .venv
        fi
        
        # Activate venv
        if [ -f ".venv/bin/activate" ]; then
            source .venv/bin/activate
            log "Activated virtual environment"
        fi
        
        # Install requirements
        log "Installing Python requirements..."
        pip install -q -r requirements.txt
        success "Python requirements installed"
    else
        warn "No requirements.txt found, skipping Python setup"
    fi
    
    # Start backend
    log "Starting backend on port $API_PORT..."
    nohup $PYTHON app.py > "$DEMO_DIR/backend.log" 2>&1 &
    echo $! > "$DEMO_DIR/backend.pid"
    
    # Wait for backend to be healthy
    if wait_for_url "http://127.0.0.1:$API_PORT/api/health" 30; then
        success "Backend is healthy"
        curl -s "http://127.0.0.1:$API_PORT/api/health" | jq . 2>/dev/null > "$DEMO_DIR/health_response.json" || true
    else
        error "Backend failed to start properly"
        tail -n 20 "$DEMO_DIR/backend.log" || true
        exit 1
    fi
    
    # Start monitoring stack
    if [ -f "monitoring/docker-compose.yml" ]; then
        log "Starting monitoring stack..."
        (cd monitoring && docker compose up -d) || warn "Failed to start monitoring stack"
        
        # Wait for monitoring services
        wait_for_url "http://127.0.0.1:$PROMETHEUS_PORT" 20 || warn "Prometheus not ready"
        wait_for_url "http://127.0.0.1:$GRAFANA_PORT" 20 || warn "Grafana not ready"
    else
        warn "No monitoring/docker-compose.yml found, skipping monitoring"
    fi
    
    # Create sample images if missing
    log "Ensuring sample images exist..."
    python3 - <<'PY' || true
from pathlib import Path
from PIL import Image
p=Path('tests/data'); p.mkdir(parents=True, exist_ok=True)
for n,c in [('sample_car.jpg',(160,160,160)),('sample_tank.jpg',(80,80,80))]:
    f=p/n
    if not f.exists():
        img=Image.new('RGB',(64,64),c)
        img.save(str(f),'JPEG')
        print(f"Created {f}")
    else:
        print(f"Sample image {f} already exists")
PY
    
    # Run demo request
    log "Running demo request..."
    if [ -f "tests/data/sample_car.jpg" ]; then
        curl -s -X POST "http://127.0.0.1:$API_PORT/api/count" \
            -F "image=@tests/data/sample_car.jpg" \
            -F "item_type=car" -o "$DEMO_DIR/resp_benign.json"
        success "Demo request completed"
    else
        warn "No sample_car.jpg found, skipping demo request"
    fi
    
    # Optionally start Flutter frontend
    if command -v flutter >/dev/null 2>&1 && [ -d "flutter_frontend" ]; then
        log "Starting Flutter frontend on port $FLUTTER_PORT..."
        cd flutter_frontend
        flutter pub get >/dev/null 2>&1 || true
        nohup flutter run -d web-server --web-port "$FLUTTER_PORT" > "../$DEMO_DIR/flutter.log" 2>&1 &
        echo $! > "../$DEMO_DIR/flutter.pid"
        cd ..
        
        # Wait for Flutter
        wait_for_url "http://127.0.0.1:$FLUTTER_PORT" 30 || warn "Flutter not ready"
    else
        warn "Flutter CLI not found or flutter_frontend directory missing, skipping Flutter"
    fi
    
    # Print summary
    echo
    success "=== Bootstrap Complete ==="
    echo
    log "Service URLs:"
    echo "  Backend Health: http://127.0.0.1:$API_PORT/api/health"
    echo "  Prometheus:     http://127.0.0.1:$PROMETHEUS_PORT"
    echo "  Grafana:        http://127.0.0.1:$GRAFANA_PORT"
    if [ -f "$DEMO_DIR/flutter.pid" ]; then
        echo "  Flutter:        http://127.0.0.1:$FLUTTER_PORT"
    fi
    echo
    log "Log files:"
    echo "  Backend:        $DEMO_DIR/backend.log"
    if [ -f "$DEMO_DIR/flutter.pid" ]; then
        echo "  Flutter:        $DEMO_DIR/flutter.log"
    fi
    echo
    log "Demo artifacts:"
    echo "  Response:       $DEMO_DIR/resp_benign.json"
    echo "  Health:         $DEMO_DIR/health_response.json"
    echo
    
    # Show demo response if available
    if [ -f "$DEMO_DIR/resp_benign.json" ]; then
        log "Demo response:"
        jq . "$DEMO_DIR/resp_benign.json" 2>/dev/null || cat "$DEMO_DIR/resp_benign.json"
    fi
}

# Run main function
main "$@"
