#!/bin/bash

# AI Object Counting App - Stop Script
# This script stops all running services

echo "🛑 Stopping AI Object Counting App..."

# Kill processes on specific ports
echo "🔍 Stopping services on ports..."

# Stop Flutter app (port 3000)
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "   Stopping Flutter app (port 3000)..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
fi

# Stop Backend API (port 5001)
if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null ; then
    echo "   Stopping Backend API (port 5001)..."
    lsof -ti:5001 | xargs kill -9 2>/dev/null || true
fi

# Stop Monitoring Server (port 8080)
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "   Stopping Monitoring Server (port 8080)..."
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
fi

# Kill any remaining Python processes related to our app
echo "🧹 Cleaning up Python processes..."
pkill -f "python3 app.py" 2>/dev/null || true
pkill -f "python3 monitoring_server.py" 2>/dev/null || true

# Kill any remaining Flutter processes
echo "🧹 Cleaning up Flutter processes..."
pkill -f "flutter run" 2>/dev/null || true

sleep 2

echo "✅ All services stopped successfully!"
echo ""
echo "🔍 Checking ports..."
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "   ⚠️  Port 3000 still in use"
else
    echo "   ✅ Port 3000 is free"
fi

if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null ; then
    echo "   ⚠️  Port 5001 still in use"
else
    echo "   ✅ Port 5001 is free"
fi

if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "   ⚠️  Port 8080 still in use"
else
    echo "   ✅ Port 8080 is free"
fi

echo ""
echo "🎉 Cleanup complete!"
