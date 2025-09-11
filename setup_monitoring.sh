#!/bin/bash

# AI Object Counting - Manual Monitoring Setup Script
# This script sets up Prometheus and Grafana without Docker

echo "Setting up monitoring stack for AI Object Counting..."

# Check if we're on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS. Installing via Homebrew..."
    
    # Install Prometheus
    if ! command -v prometheus &> /dev/null; then
        echo "Installing Prometheus..."
        brew install prometheus
    else
        echo "Prometheus already installed"
    fi
    
    # Install Grafana
    if ! command -v grafana-server &> /dev/null; then
        echo "Installing Grafana..."
        brew install grafana
    else
        echo "Grafana already installed"
    fi
    
    # Start services
    echo "Starting Prometheus..."
    prometheus --config.file=monitoring/prometheus.yml --storage.tsdb.path=monitoring/data --web.listen-address=:9090 &
    PROMETHEUS_PID=$!
    echo "Prometheus started with PID: $PROMETHEUS_PID"
    
    echo "Starting Grafana..."
    grafana-server --config=monitoring/grafana.ini --homepath=/opt/homebrew/share/grafana &
    GRAFANA_PID=$!
    echo "Grafana started with PID: $GRAFANA_PID"
    
    echo "Monitoring stack started!"
    echo "Prometheus: http://localhost:9090"
    echo "Grafana: http://localhost:3000 (admin/admin123)"
    echo ""
    echo "To stop the services, run:"
    echo "kill $PROMETHEUS_PID $GRAFANA_PID"
    
else
    echo "This script is designed for macOS. Please install Prometheus and Grafana manually:"
    echo "1. Download Prometheus from https://prometheus.io/download/"
    echo "2. Download Grafana from https://grafana.com/grafana/download"
    echo "3. Configure them using the files in the monitoring/ directory"
fi
