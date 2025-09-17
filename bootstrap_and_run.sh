#!/usr/bin/env bash
# bootstrap_and_run.sh - Enhanced bootstrap script for AI Object Counting project
# Optimized for 8GB M1 MacBook with port collision avoidance

set -euo pipefail

# Configuration with environment variable overrides
API_PORT="${API_PORT:-5001}"
PROM_PORT="${PROM_PORT:-9090}"
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
FLUTTER_PORT="${FLUTTER_PORT:-3001}"
NODE_EXPORTER_PORT="${NODE_EXPORTER_PORT:-9100}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DEMO_DIR="${DEMO_DIR:-./demo}"
ERRORS=()

log() {
    echo -e "${BLUE}[bootstrap]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[bootstrap]${NC} $*"
    ERRORS+=("$*")
}

error() {
    echo -e "${RED}[bootstrap]${NC} $*"
    ERRORS+=("$*")
}

success() {
    echo -e "${GREEN}[bootstrap]${NC} $*"
}

# Helper function to find a free port
find_free_port() {
    local start_port=$1
    local port=$start_port
    while lsof -ti:$port >/dev/null 2>&1; do
        port=$((port + 1))
        if [ $port -gt $((start_port + 100)) ]; then
            error "Could not find free port starting from $start_port"
            return 1
        fi
    done
    echo $port
}

# Helper function to wait for URL to be available
wait_for_url() {
    local url=$1
    local timeout_sec=${2:-60}
    local i=0
    
    log "Waiting for $url to be available (timeout: ${timeout_sec}s)..."
    until curl -s --max-time 2 "$url" >/dev/null 2>&1; do
        i=$((i+1))
        if [ $i -ge $timeout_sec ]; then
            error "Timeout waiting for $url"
            return 1
        fi
        sleep 1
    done
    success "$url is available"
    return 0
}

# Helper function to kill process on port politely
kill_on_port() {
    local port=$1
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        log "Found process(es) on port $port: $pids"
        echo "$pids" | xargs -r kill -TERM
        sleep 2
        
        # Check if still running
        local still_running=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$still_running" ]; then
            warn "Process still running on port $port, force killing: $still_running"
            echo "$still_running" | xargs -r kill -KILL
            sleep 1
        fi
        success "Cleared port $port"
    else
        log "Port $port is free"
    fi
}

# Detect system RAM and set LOCAL_LOW_MEMORY if needed
detect_memory() {
    local total_ram_gb=0
    
    if command -v sysctl >/dev/null 2>&1; then
        # macOS
        local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
        total_ram_gb=$((ram_bytes / 1024 / 1024 / 1024))
    elif [ -f /proc/meminfo ]; then
        # Linux
        local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_ram_gb=$((ram_kb / 1024 / 1024))
    fi
    
    if [ $total_ram_gb -le 16 ] && [ $total_ram_gb -gt 0 ]; then
        export LOCAL_LOW_MEMORY=1
        log "Detected ${total_ram_gb}GB RAM, enabling low-memory mode"
    else
        log "Detected ${total_ram_gb}GB RAM, using normal mode"
    fi
}

# Safe port cleanup
cleanup_ports() {
    log "Performing safe port cleanup..."
    
    # Remove stale PID files
    rm -f "$DEMO_DIR"/*.pid
    
    # Clean up ports
    for port in "$API_PORT" "$PROM_PORT" "$GRAFANA_PORT" "$FLUTTER_PORT" "$NODE_EXPORTER_PORT"; do
        kill_on_port "$port"
    done
}

# Setup Python environment
setup_python_env() {
    log "Setting up Python environment..."
    
    # Create venv if missing
    if [ ! -d ".venv" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv .venv
    fi
    
    # Activate venv
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        log "Activated virtual environment"
    fi
    
    # Install requirements
    if [ -f "requirements.txt" ]; then
        log "Installing Python requirements..."
        
        # Update SQLAlchemy constraint if present
        if grep -q "SQLAlchemy" requirements.txt; then
            sed -i.bak 's/SQLAlchemy.*/SQLAlchemy>=1.4.46,<2.0/' requirements.txt
            log "Updated SQLAlchemy constraint to <2.0,>=1.4.46"
        fi
        
        pip install -q -r requirements.txt
        success "Python requirements installed"
    else
        warn "No requirements.txt found, skipping Python setup"
    fi
}

# Start backend in low-memory safe mode
start_backend() {
    log "Starting backend in low-memory safe mode..."
    
    # Check for gunicorn
    if command -v gunicorn >/dev/null 2>&1 && [ "${LOCAL_LOW_MEMORY:-0}" = "1" ]; then
        log "Using gunicorn for low-memory mode"
        nohup gunicorn --bind 0.0.0.0:$API_PORT --workers 1 --threads 4 app:app > "$DEMO_DIR/backend.log" 2>&1 &
    else
        log "Using python3 app.py (gunicorn not available or normal mode)"
        nohup python3 app.py --port $API_PORT > "$DEMO_DIR/backend.log" 2>&1 &
    fi
    
    local backend_pid=$!
    echo "$backend_pid" > "$DEMO_DIR/backend.pid"
    log "Backend started (pid $backend_pid)"
    
    # Wait for backend to be healthy
    if wait_for_url "http://127.0.0.1:$API_PORT/api/health" 60; then
        success "Backend is healthy"
        return 0
    else
        error "Backend failed to start properly"
        log "Backend log tail:"
        tail -n 20 "$DEMO_DIR/backend.log" || true
        return 1
    fi
}

# Start monitoring stack with Docker
start_monitoring() {
    if ! command -v docker >/dev/null 2>&1 || ! command -v "docker compose" >/dev/null 2>&1; then
        warn "Docker not found — skipping Prometheus/Grafana startup. You can start them later with \`cd monitoring && docker compose up -d\`"
        return 0
    fi
    
    log "Starting monitoring stack with Docker..."
    
    # Ensure monitoring directory exists
    if [ ! -d "monitoring" ]; then
        warn "Monitoring directory not found, skipping Docker startup"
        return 0
    fi
    
    # Start Docker services
    if (cd monitoring && docker compose up -d); then
        success "Docker services started"
        
        # Wait for Prometheus target to be UP
        log "Waiting for Prometheus target to be UP..."
        local max_attempts=30
        local attempt=0
        
        while [ $attempt -lt $max_attempts ]; do
            if curl -s "http://localhost:$PROM_PORT/api/v1/targets" | jq -e '.data.activeTargets[] | select(.scrapePool == "ai-object-counting" and .health == "up")' >/dev/null 2>&1; then
                success "Prometheus target ai-object-counting is UP"
                break
            fi
            attempt=$((attempt + 1))
            sleep 2
        done
        
        if [ $attempt -eq $max_attempts ]; then
            warn "Prometheus target ai-object-counting did not come UP within timeout"
        fi
    else
        warn "Failed to start Docker services"
    fi
}

# Start Flutter web server
start_flutter() {
    if [ -z "${FLUTTER_HOME:-}" ] || ! command -v flutter >/dev/null 2>&1; then
        warn "Flutter CLI not available, skipping Flutter startup"
        return 0
    fi
    
    if [ ! -d "flutter_frontend" ]; then
        warn "Flutter frontend directory not found, skipping Flutter startup"
        return 0
    fi
    
    log "Starting Flutter web server..."
    
    # Find free port for Flutter
    local flutter_port=$(find_free_port $FLUTTER_PORT)
    if [ $? -ne 0 ]; then
        warn "Could not find free port for Flutter"
        return 1
    fi
    
    cd flutter_frontend
    flutter pub get >/dev/null 2>&1 || true
    
    # Try to start Flutter
    if nohup flutter run -d chrome --web-port "$flutter_port" > "../$DEMO_DIR/flutter.log" 2>&1 &; then
        local flutter_pid=$!
        echo "$flutter_pid" > "../$DEMO_DIR/flutter.pid"
        cd ..
        log "Flutter started on port $flutter_port (pid $flutter_pid)"
        
        # Update FLUTTER_PORT for reporting
        FLUTTER_PORT=$flutter_port
    else
        cd ..
        warn "Failed to start Flutter"
    fi
}

# Generate demo requests
generate_demo_requests() {
    log "Generating demo requests..."
    
    # Create sample images if missing
    mkdir -p tests/data
    if [ ! -f "tests/data/sample_car.jpg" ]; then
        python3 -c "from PIL import Image; img=Image.new('RGB',(64,64),(160,160,160)); img.save('tests/data/sample_car.jpg','JPEG')" || true
    fi
    if [ ! -f "tests/data/sample_tank.jpg" ]; then
        python3 -c "from PIL import Image; img=Image.new('RGB',(64,64),(80,80,80)); img.save('tests/data/sample_tank.jpg','JPEG')" || true
    fi
    
    # Benign request
    if curl -s -X POST "http://127.0.0.1:$API_PORT/api/count" \
        -F "image=@tests/data/sample_car.jpg" \
        -F "item_type=car" -o "$DEMO_DIR/resp_benign.json"; then
        success "Benign request completed"
    else
        warn "Benign request failed"
    fi
    
    # Blocked request
    if curl -s -X POST "http://127.0.0.1:$API_PORT/api/count" \
        -F "image=@tests/data/sample_tank.jpg" \
        -F "item_type=tank" -o "$DEMO_DIR/resp_blocked.json"; then
        success "Blocked request completed"
    else
        warn "Blocked request failed"
    fi
}

# Query Prometheus for metrics
query_prometheus() {
    if ! curl -s "http://localhost:$PROM_PORT/api/v1/targets" >/dev/null 2>&1; then
        warn "Prometheus not available, skipping metrics query"
        return 0
    fi
    
    log "Querying Prometheus for metrics..."
    
    # Query requests total
    curl -s "http://localhost:$PROM_PORT/api/v1/query?query=ai_object_counting_requests_total" | jq '.data.result' > "$DEMO_DIR/prometheus_requests.json" 2>/dev/null || true
    
    # Query model confidence
    curl -s "http://localhost:$PROM_PORT/api/v1/query?query=ai_object_counting_model_confidence" | jq '.data.result' > "$DEMO_DIR/prometheus_confidence.json" 2>/dev/null || true
    
    # Create metrics snippet
    curl -s "http://127.0.0.1:$API_PORT/metrics" | grep -E "ai_object_counting_(requests_total|model_confidence)" | head -10 > "$DEMO_DIR/metrics_snippet.txt" 2>/dev/null || true
    
    success "Prometheus metrics queried"
}

# Query Grafana
query_grafana() {
    if ! curl -s "http://localhost:$GRAFANA_PORT/api/health" >/dev/null 2>&1; then
        warn "Grafana not available, skipping Grafana query"
        return 0
    fi
    
    log "Querying Grafana..."
    
    # Try with default admin/admin credentials
    if curl -s -u admin:admin "http://localhost:$GRAFANA_PORT/api/datasources/proxy/1/api/v1/query?query=ai_object_counting_requests_total" | jq '.data.result' > "$DEMO_DIR/grafana_probe.json" 2>/dev/null; then
        success "Grafana query successful"
    else
        warn "Grafana query failed (check credentials or datasource configuration)"
    fi
}

# Generate bootstrap report
generate_report() {
    log "Generating bootstrap report..."
    
    local backend_health=false
    local prometheus_up=false
    local grafana_up=false
    local benign_response_exists=false
    local blocked_response_exists=false
    local metrics_sample=""
    
    # Check backend health
    if curl -s "http://127.0.0.1:$API_PORT/api/health" | jq -e '.status == "healthy"' >/dev/null 2>&1; then
        backend_health=true
    fi
    
    # Check Prometheus
    if curl -s "http://localhost:$PROM_PORT/api/v1/targets" >/dev/null 2>&1; then
        prometheus_up=true
    fi
    
    # Check Grafana
    if curl -s "http://localhost:$GRAFANA_PORT/api/health" >/dev/null 2>&1; then
        grafana_up=true
    fi
    
    # Check response files
    if [ -f "$DEMO_DIR/resp_benign.json" ] && jq empty "$DEMO_DIR/resp_benign.json" 2>/dev/null; then
        benign_response_exists=true
    fi
    
    if [ -f "$DEMO_DIR/resp_blocked.json" ] && jq empty "$DEMO_DIR/resp_blocked.json" 2>/dev/null; then
        blocked_response_exists=true
    fi
    
    # Get metrics sample
    if [ -f "$DEMO_DIR/metrics_snippet.txt" ]; then
        metrics_sample=$(head -n 3 "$DEMO_DIR/metrics_snippet.txt" | tr '\n' ' ')
    fi
    
    # Create report
    cat > "$DEMO_DIR/bootstrap_report.json" << EOF
{
  "backend_health": $backend_health,
  "backend_port": $API_PORT,
  "prometheus_up": $prometheus_up,
  "grafana_up": $grafana_up,
  "metrics_sample": "$metrics_sample",
  "benign_response_exists": $benign_response_exists,
  "blocked_response_exists": $blocked_response_exists,
  "errors": $(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .),
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    success "Bootstrap report generated: $DEMO_DIR/bootstrap_report.json"
}

# Main execution
main() {
    log "Starting AI Object Counting project bootstrap..."
    log "Configuration: API_PORT=$API_PORT, PROM_PORT=$PROM_PORT, GRAFANA_PORT=$GRAFANA_PORT, FLUTTER_PORT=$FLUTTER_PORT"
    
    # Create demo directory
    mkdir -p "$DEMO_DIR"
    
    # Detect memory and set environment
    detect_memory
    
    # Clean up ports
    cleanup_ports
    
    # Setup Python environment
    setup_python_env
    
    # Start backend
    if ! start_backend; then
        error "Failed to start backend"
        exit 1
    fi
    
    # Start monitoring
    start_monitoring
    
    # Start Flutter
    start_flutter
    
    # Generate demo requests
    generate_demo_requests
    
    # Query metrics
    query_prometheus
    query_grafana
    
    # Generate report
    generate_report
    
    # Print summary
    echo
    success "=== Bootstrap Complete ==="
    echo
    log "Service URLs:"
    echo "  Backend API:    http://127.0.0.1:$API_PORT"
    echo "  Backend Health: http://127.0.0.1:$API_PORT/api/health"
    if [ -f "$DEMO_DIR/prometheus_requests.json" ] && [ -s "$DEMO_DIR/prometheus_requests.json" ]; then
        echo "  Prometheus:     http://localhost:$PROM_PORT"
    else
        echo "  Prometheus:     Not available (Docker not running?)"
    fi
    if [ -f "$DEMO_DIR/grafana_probe.json" ] && [ -s "$DEMO_DIR/grafana_probe.json" ]; then
        echo "  Grafana:        http://localhost:$GRAFANA_PORT (admin/admin)"
    else
        echo "  Grafana:        Not available (Docker not running?)"
    fi
    if [ -f "$DEMO_DIR/flutter.pid" ]; then
        echo "  Flutter:        http://localhost:$FLUTTER_PORT"
    else
        echo "  Flutter:        Not started (Flutter CLI not available?)"
    fi
    echo
    log "Log files:"
    echo "  Backend:        $DEMO_DIR/backend.log"
    if [ -f "$DEMO_DIR/flutter.pid" ]; then
        echo "  Flutter:        $DEMO_DIR/flutter.log"
    fi
    echo
    log "Demo artifacts:"
    echo "  Benign:         $DEMO_DIR/resp_benign.json"
    echo "  Blocked:        $DEMO_DIR/resp_blocked.json"
    echo "  Metrics:        $DEMO_DIR/metrics_snippet.txt"
    echo "  Report:         $DEMO_DIR/bootstrap_report.json"
    echo
    
    if [ ${#ERRORS[@]} -gt 0 ]; then
        warn "Warnings encountered:"
        printf '%s\n' "${ERRORS[@]}" | sed 's/^/  - /'
        echo
    fi
    
    success "BOOTSTRAP_OK"
    exit 0
}

# Run main function
main "$@"