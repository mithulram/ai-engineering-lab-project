#!/usr/bin/env python3
"""
Simple monitoring server that serves Prometheus metrics and a basic Grafana-like dashboard
This is a lightweight alternative to the full Prometheus/Grafana stack
"""

import http.server
import socketserver
import json
import time
import threading
import requests
from urllib.parse import urlparse, parse_qs
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MonitoringHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler for monitoring endpoints"""
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/metrics':
            self.serve_metrics()
        elif path == '/dashboard':
            self.serve_dashboard()
        elif path == '/api/metrics':
            self.serve_metrics_api()
        else:
            super().do_GET()
    
    def serve_metrics(self):
        """Serve Prometheus metrics from the Flask app"""
        try:
            response = requests.get('http://localhost:5001/metrics', timeout=5)
            if response.status_code == 200:
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; version=0.0.4; charset=utf-8')
                self.end_headers()
                self.wfile.write(response.content)
            else:
                self.send_error(500, "Failed to fetch metrics from Flask app")
        except Exception as e:
            logger.error(f"Error fetching metrics: {str(e)}")
            self.send_error(500, f"Error fetching metrics: {str(e)}")
    
    def serve_metrics_api(self):
        """Serve metrics as JSON for dashboard"""
        try:
            response = requests.get('http://localhost:5001/metrics', timeout=5)
            if response.status_code == 200:
                # Parse Prometheus metrics and convert to JSON
                metrics_data = self.parse_prometheus_metrics(response.text)
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps(metrics_data).encode())
            else:
                self.send_error(500, "Failed to fetch metrics from Flask app")
        except Exception as e:
            logger.error(f"Error fetching metrics: {str(e)}")
            self.send_error(500, f"Error fetching metrics: {str(e)}")
    
    def parse_prometheus_metrics(self, metrics_text):
        """Parse Prometheus metrics text into structured data"""
        metrics = {}
        current_metric = None
        
        for line in metrics_text.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            if line.startswith('ai_object_counting_'):
                # Extract metric name and value
                parts = line.split(' ')
                if len(parts) >= 2:
                    metric_name = parts[0]
                    try:
                        value = float(parts[1])
                        metrics[metric_name] = value
                    except ValueError:
                        continue
        
        return metrics
    
    def serve_dashboard(self):
        """Serve a simple HTML dashboard"""
        html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>AI Object Counting - Monitoring Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .card { background: white; padding: 20px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #e3f2fd; border-radius: 4px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #1976d2; }
        .metric-label { font-size: 14px; color: #666; }
        .chart-container { position: relative; height: 300px; margin: 20px 0; }
        h1 { color: #333; }
        h2 { color: #555; margin-top: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 AI Object Counting - Performance Dashboard</h1>
        
        <div class="card">
            <h2>📊 Real-time Metrics</h2>
            <div id="metrics-container">
                <div class="metric">
                    <div class="metric-value" id="accuracy">-</div>
                    <div class="metric-label">Accuracy</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="precision">-</div>
                    <div class="metric-label">Precision</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="recall">-</div>
                    <div class="metric-label">Recall</div>
                </div>
                <div class="metric">
                    <div class="metric-value" id="requests">-</div>
                    <div class="metric-label">Total Requests</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>📈 Performance Trends</h2>
            <div class="chart-container">
                <canvas id="performanceChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>🔧 System Status</h2>
            <div id="status-container">
                <p>Backend API: <span id="api-status">Checking...</span></p>
                <p>Metrics Endpoint: <span id="metrics-status">Checking...</span></p>
                <p>Last Update: <span id="last-update">-</span></p>
            </div>
        </div>
    </div>

    <script>
        let performanceChart;
        let performanceData = [];
        
        // Initialize chart
        function initChart() {
            const ctx = document.getElementById('performanceChart').getContext('2d');
            performanceChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Accuracy',
                        data: [],
                        borderColor: 'rgb(75, 192, 192)',
                        tension: 0.1
                    }, {
                        label: 'Precision',
                        data: [],
                        borderColor: 'rgb(255, 99, 132)',
                        tension: 0.1
                    }, {
                        label: 'Recall',
                        data: [],
                        borderColor: 'rgb(54, 162, 235)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 1
                        }
                    }
                }
            });
        }
        
        // Update metrics
        function updateMetrics() {
            fetch('/api/metrics')
                .then(response => response.json())
                .then(data => {
                    // Update metric values
                    document.getElementById('accuracy').textContent = 
                        (data.ai_object_counting_accuracy || 0).toFixed(3);
                    document.getElementById('precision').textContent = 
                        (data.ai_object_counting_precision || 0).toFixed(3);
                    document.getElementById('recall').textContent = 
                        (data.ai_object_counting_recall || 0).toFixed(3);
                    document.getElementById('requests').textContent = 
                        data.ai_object_counting_requests_total || 0;
                    
                    // Update chart
                    const now = new Date().toLocaleTimeString();
                    performanceChart.data.labels.push(now);
                    performanceChart.data.datasets[0].data.push(data.ai_object_counting_accuracy || 0);
                    performanceChart.data.datasets[1].data.push(data.ai_object_counting_precision || 0);
                    performanceChart.data.datasets[2].data.push(data.ai_object_counting_recall || 0);
                    
                    // Keep only last 20 data points
                    if (performanceChart.data.labels.length > 20) {
                        performanceChart.data.labels.shift();
                        performanceChart.data.datasets.forEach(dataset => dataset.data.shift());
                    }
                    
                    performanceChart.update();
                    
                    // Update status
                    document.getElementById('api-status').textContent = '✅ Online';
                    document.getElementById('metrics-status').textContent = '✅ Online';
                    document.getElementById('last-update').textContent = now;
                })
                .catch(error => {
                    console.error('Error fetching metrics:', error);
                    document.getElementById('api-status').textContent = '❌ Offline';
                    document.getElementById('metrics-status').textContent = '❌ Error';
                });
        }
        
        // Initialize and start updates
        initChart();
        updateMetrics();
        setInterval(updateMetrics, 5000); // Update every 5 seconds
    </script>
</body>
</html>
        """
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html_content.encode())

def start_monitoring_server(port=8080):
    """Start the monitoring server"""
    handler = MonitoringHandler
    
    with socketserver.TCPServer(("", port), handler) as httpd:
        logger.info(f"Monitoring server started on port {port}")
        logger.info(f"Dashboard: http://localhost:{port}/dashboard")
        logger.info(f"Metrics: http://localhost:{port}/metrics")
        logger.info(f"API: http://localhost:{port}/api/metrics")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            logger.info("Monitoring server stopped")

if __name__ == "__main__":
    start_monitoring_server()
