#!/bin/bash

# AI Object Counting Backend - Local Development Startup Script
# This script starts the Flask backend using Gunicorn for local development,
# with lazy model loading and proper process management.

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Configuration
API_PORT=${API_PORT:-5001}
DEMO_DIR="demo"
BACKEND_LOG="$DEMO_DIR/backend.log"
ACCESS_LOG="$DEMO_DIR/access.log"
ERROR_LOG="$DEMO_DIR/error.log"
PID_FILE="$DEMO_DIR/gunicorn.pid"
VENV_DIR=".venv"

# Ensure demo directory exists
mkdir -p "$DEMO_DIR"

# --- Functions ---
log() {
    echo -e "🚀 \033[1;34m[run_local]\033[0m $1"
}

success() {
    echo -e "✅ \033[1;32m[run_local]\033[0m $1"
}

warn() {
    echo -e "⚠️  \033[1;33m[run_local]\033[0m $1"
}

error() {
    echo -e "❌ \033[1;31m[run_local]\033[0m $1"
    exit 1
}

cleanup() {
    log "Cleaning up processes..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            kill $PID || true
            log "Killed Gunicorn process $PID"
        fi
        rm -f "$PID_FILE"
    fi
    pkill -f "gunicorn.*backend.app:app" || true # Ensure all gunicorn processes are killed
    pkill -f "python3 app.py" || true # Kill any direct flask runs
    rm -f "$DEMO_DIR"/*.pid || true # Remove any stale PIDs
    sleep 1
    success "Cleanup complete"
}

# --- Main Script ---
log "Starting AI Object Counting Backend (Local Development Mode)"
echo "================================================================"

cleanup

log "Setting up Python virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    log "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    success "Virtual environment created"
fi

log "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
success "Virtual environment activated"

log "Installing/updating dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
success "Dependencies installed"

log "Starting backend with lazy model loading..."
echo "   - Port: $API_PORT"
echo "   - Low memory mode: ENABLED"
echo "   - Debug mode: DISABLED"
echo "   - Auto-reloader: DISABLED"
echo "   - Logs: $BACKEND_LOG"

# Set environment variables for Flask and low memory mode
export FLASK_ENV=production # Use production mode for Gunicorn
export FLASK_DEBUG=0        # Explicitly disable Flask debug
export LOCAL_LOW_MEMORY=1   # Enable lazy loading / low memory mode
export API_PORT             # Pass port to Flask app

log "Starting gunicorn server..."
# Start Gunicorn with 1 worker and 2 threads, logging to files
# --preload: load application code before forking workers (can help with model loading)
# --timeout: set worker timeout
# --pid: write pid to file
gunicorn --bind "0.0.0.0:$API_PORT" \
         --workers 1 \
         --threads 2 \
         --worker-class sync \
         --worker-connections 1000 \
         --max-requests 100 \
         --max-requests-jitter 10 \
         --preload \
         --log-level info \
         --access-logfile "$ACCESS_LOG" \
         --error-logfile "$ERROR_LOG" \
         --pid "$PID_FILE" \
         "backend.app:app" &

GUNICORN_PID=$!
echo "$GUNICORN_PID" > "$PID_FILE"

# Wait for Gunicorn to start and check health
sleep 5 # Give Gunicorn a moment to bind
if curl -s http://127.0.0.1:$API_PORT/api/health > /dev/null; then
    success "Backend started successfully!"
else
    error "Backend failed to start. Check logs in $DEMO_DIR."
fi

echo
success "📊 Service Information:"
echo "   - Backend URL: http://127.0.0.1:$API_PORT"
echo "   - Health Check: http://127.0.0.1:$API_PORT/api/health"
echo "   - Metrics: http://127.0.0.1:$API_PORT/metrics"
echo "   - PID: $GUNICORN_PID"
echo
success "📝 Logs:"
echo "   - Backend: tail -f $BACKEND_LOG"
echo "   - Access: tail -f $ACCESS_LOG"
echo "   - Errors: tail -f $ERROR_LOG"
echo
success "🛑 To stop the backend:"
echo "   pkill -f 'gunicorn.*backend.app:app'"
echo "   or kill $GUNICORN_PID"
echo
success "🎉 Backend is running successfully!"
success "   Models will be loaded on first API request (lazy loading)"

# Keep the script running in the foreground to show logs, or detach if preferred
# wait $GUNICORN_PID