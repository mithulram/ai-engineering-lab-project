#!/bin/bash

# AI Object Counting App - Startup Script
# This script starts all required services
# Place this script in your project root directory

echo "🚀 Starting AI Object Counting App..."

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "📁 Working directory: $SCRIPT_DIR"
echo "📝 Make sure you're in the project root directory containing:"
echo "   - app.py"
echo "   - monitoring_server.py" 
echo "   - requirements.txt"
echo "   - flutter_frontend/ directory"
echo ""

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $1 is already in use. Killing existing process..."
        lsof -ti:$1 | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Check and clear ports
echo "🔍 Checking ports..."
check_port 3000
check_port 5001
check_port 8080

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
cd flutter_frontend
flutter pub get
cd ..

# Start backend API
echo "🔧 Starting Backend API (Port 5001)..."
python3 app.py &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Start monitoring server
echo "📊 Starting Monitoring Server (Port 8080)..."
python3 monitoring_server.py &
MONITORING_PID=$!

# Wait a moment for monitoring to start
sleep 3

# Start Flutter app
echo "📱 Starting Flutter Web App (Port 3000)..."
cd flutter_frontend
flutter run -d chrome --web-port 3000 &
FLUTTER_PID=$!

# Wait for Flutter to start
sleep 5

echo ""
echo "✅ All services started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   Flutter App:     http://localhost:3000"
echo "   Backend API:     http://localhost:5001"
echo "   Monitoring:      http://localhost:8080/dashboard"
echo ""
echo "📊 Process IDs:"
echo "   Backend API:     $BACKEND_PID"
echo "   Monitoring:      $MONITORING_PID"
echo "   Flutter App:     $FLUTTER_PID"
echo ""
echo "🛑 To stop all services, run: ./stop_app.sh"
echo "   Or manually kill the processes above"
echo ""

# Keep script running
echo "Press Ctrl+C to stop all services..."
trap 'echo "🛑 Stopping services..."; kill $BACKEND_PID $MONITORING_PID $FLUTTER_PID 2>/dev/null; exit' INT

# Wait for user to stop
wait
