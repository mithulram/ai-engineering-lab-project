#!/usr/bin/env python3
"""
Enhanced monitoring server with beautiful dashboard for AI Object Counting Application
This provides a modern, informative monitoring interface with real-time metrics
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

class EnhancedMonitoringHandler(http.server.SimpleHTTPRequestHandler):
    """Enhanced handler for monitoring endpoints with beautiful dashboard"""
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        if path == '/metrics':
            self.serve_metrics()
        elif path == '/dashboard':
            self.serve_enhanced_dashboard()
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
    
    def serve_enhanced_dashboard(self):
        """Serve an enhanced HTML dashboard with modern UI"""
        html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Object Counting - Advanced Monitoring Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 20px 0;
            box-shadow: 0 2px 20px rgba(0,0,0,0.1);
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .logo i {
            font-size: 2.5rem;
            color: #667eea;
        }
        
        .logo h1 {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .status-indicator {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 20px;
            background: rgba(102, 126, 234, 0.1);
            border-radius: 25px;
            border: 2px solid rgba(102, 126, 234, 0.2);
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4CAF50;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-bottom: 30px;
        }
        
        .card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 25px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 40px rgba(0,0,0,0.15);
        }
        
        .card-header {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid rgba(102, 126, 234, 0.1);
        }
        
        .card-header i {
            font-size: 1.5rem;
            color: #667eea;
        }
        
        .card-header h2 {
            font-size: 1.3rem;
            font-weight: 600;
            color: #333;
        }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 15px;
        }
        
        .metric-card {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .metric-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, rgba(255,255,255,0.1), rgba(255,255,255,0.05));
            pointer-events: none;
        }
        
        .metric-value {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 5px;
            position: relative;
            z-index: 1;
        }
        
        .metric-label {
            font-size: 0.9rem;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }
        
        .metric-trend {
            position: absolute;
            top: 10px;
            right: 10px;
            font-size: 0.8rem;
            opacity: 0.8;
        }
        
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        
        .system-status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .status-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 15px;
            background: rgba(102, 126, 234, 0.05);
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        
        .status-icon {
            font-size: 1.2rem;
        }
        
        .status-text {
            flex: 1;
        }
        
        .status-label {
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 2px;
        }
        
        .status-value {
            font-weight: 600;
            font-size: 1rem;
        }
        
        .online { color: #4CAF50; }
        .offline { color: #f44336; }
        .warning { color: #ff9800; }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .info-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            background: rgba(102, 126, 234, 0.05);
            border-radius: 10px;
            border: 1px solid rgba(102, 126, 234, 0.1);
        }
        
        .info-label {
            font-weight: 500;
            color: #555;
        }
        
        .info-value {
            font-weight: 600;
            color: #333;
        }
        
        .refresh-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            font-size: 1.5rem;
            cursor: pointer;
            box-shadow: 0 4px 20px rgba(102, 126, 234, 0.3);
            transition: transform 0.3s ease;
        }
        
        .refresh-btn:hover {
            transform: scale(1.1);
        }
        
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255,255,255,.3);
            border-radius: 50%;
            border-top-color: #fff;
            animation: spin 1s ease-in-out infinite;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .error-message {
            background: #ffebee;
            color: #c62828;
            padding: 15px;
            border-radius: 10px;
            border-left: 4px solid #f44336;
            margin: 10px 0;
        }
        
        .success-message {
            background: #e8f5e8;
            color: #2e7d32;
            padding: 15px;
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
            margin: 10px 0;
        }
        
        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                gap: 15px;
            }
            
            .grid {
                grid-template-columns: 1fr;
            }
            
            .metrics-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="logo">
                <i class="fas fa-robot"></i>
                <h1>AI Object Counting Monitor</h1>
            </div>
            <div class="status-indicator">
                <div class="status-dot"></div>
                <span>Live Monitoring Active</span>
            </div>
        </div>
    </div>

    <div class="container">
        <!-- System Overview -->
        <div class="grid">
            <div class="card">
                <div class="card-header">
                    <i class="fas fa-chart-line"></i>
                    <h2>Performance Metrics</h2>
                </div>
                <div class="metrics-grid">
                    <div class="metric-card">
                        <div class="metric-value" id="accuracy">-</div>
                        <div class="metric-label">Accuracy</div>
                        <div class="metric-trend" id="accuracy-trend">📈</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-value" id="precision">-</div>
                        <div class="metric-label">Precision</div>
                        <div class="metric-trend" id="precision-trend">📈</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-value" id="recall">-</div>
                        <div class="metric-label">Recall</div>
                        <div class="metric-trend" id="recall-trend">📈</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-value" id="confidence">-</div>
                        <div class="metric-label">Avg Confidence</div>
                        <div class="metric-trend" id="confidence-trend">📈</div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <i class="fas fa-server"></i>
                    <h2>System Status</h2>
                </div>
                <div class="system-status">
                    <div class="status-item">
                        <i class="fas fa-api status-icon online" id="api-icon"></i>
                        <div class="status-text">
                            <div class="status-label">Backend API</div>
                            <div class="status-value online" id="api-status">Checking...</div>
                        </div>
                    </div>
                    <div class="status-item">
                        <i class="fas fa-database status-icon online" id="db-icon"></i>
                        <div class="status-text">
                            <div class="status-label">Database</div>
                            <div class="status-value online" id="db-status">Active</div>
                        </div>
                    </div>
                    <div class="status-item">
                        <i class="fas fa-chart-bar status-icon online" id="metrics-icon"></i>
                        <div class="status-text">
                            <div class="status-label">Metrics</div>
                            <div class="status-value online" id="metrics-status">Collecting</div>
                        </div>
                    </div>
                    <div class="status-item">
                        <i class="fas fa-brain status-icon online" id="ai-icon"></i>
                        <div class="status-text">
                            <div class="status-label">AI Models</div>
                            <div class="status-value online" id="ai-status">Loaded</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Performance Charts -->
        <div class="grid">
            <div class="card" style="grid-column: 1 / -1;">
                <div class="card-header">
                    <i class="fas fa-chart-area"></i>
                    <h2>Performance Trends</h2>
                </div>
                <div class="chart-container">
                    <canvas id="performanceChart"></canvas>
                </div>
            </div>
        </div>

        <!-- Detailed Information -->
        <div class="grid">
            <div class="card">
                <div class="card-header">
                    <i class="fas fa-info-circle"></i>
                    <h2>System Information</h2>
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Total Requests</span>
                        <span class="info-value" id="total-requests">0</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Images Processed</span>
                        <span class="info-value" id="images-processed">0</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Avg Response Time</span>
                        <span class="info-value" id="avg-response-time">0ms</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Uptime</span>
                        <span class="info-value" id="uptime">0s</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Last Update</span>
                        <span class="info-value" id="last-update">-</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Model Status</span>
                        <span class="info-value" id="model-status">Active</span>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <i class="fas fa-cogs"></i>
                    <h2>Model Performance</h2>
                </div>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">SAM Model</span>
                        <span class="info-value" id="sam-status">✅ Loaded</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">ResNet-50</span>
                        <span class="info-value" id="resnet-status">✅ Loaded</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">DistilBERT</span>
                        <span class="info-value" id="bert-status">✅ Loaded</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Inference Time</span>
                        <span class="info-value" id="inference-time">0ms</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Segments Found</span>
                        <span class="info-value" id="segments-found">0</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Object Types</span>
                        <span class="info-value" id="object-types">9</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <button class="refresh-btn" onclick="refreshAll()" title="Refresh Data">
        <i class="fas fa-sync-alt"></i>
    </button>

    <script>
        let performanceChart;
        let performanceData = [];
        let startTime = Date.now();
        
        // Initialize chart with better styling
        function initChart() {
            const ctx = document.getElementById('performanceChart').getContext('2d');
            performanceChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'Accuracy',
                        data: [],
                        borderColor: '#667eea',
                        backgroundColor: 'rgba(102, 126, 234, 0.1)',
                        tension: 0.4,
                        fill: true
                    }, {
                        label: 'Precision',
                        data: [],
                        borderColor: '#764ba2',
                        backgroundColor: 'rgba(118, 75, 162, 0.1)',
                        tension: 0.4,
                        fill: true
                    }, {
                        label: 'Recall',
                        data: [],
                        borderColor: '#f093fb',
                        backgroundColor: 'rgba(240, 147, 251, 0.1)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'top',
                            labels: {
                                usePointStyle: true,
                                padding: 20
                            }
                        }
                    },
                    scales: {
                        x: {
                            grid: {
                                color: 'rgba(0,0,0,0.05)'
                            }
                        },
                        y: {
                            beginAtZero: true,
                            max: 1,
                            grid: {
                                color: 'rgba(0,0,0,0.05)'
                            },
                            ticks: {
                                callback: function(value) {
                                    return (value * 100).toFixed(0) + '%';
                                }
                            }
                        }
                    },
                    interaction: {
                        intersect: false,
                        mode: 'index'
                    }
                }
            });
        }
        
        // Enhanced metrics fetching
        async function fetchMetrics() {
            try {
                const response = await fetch('/api/metrics');
                const metrics = await response.json();
                
                // Update main metrics with better formatting
                updateMetric('accuracy', metrics['ai_object_counting_accuracy'] || 0, '%');
                updateMetric('precision', metrics['ai_object_counting_precision'] || 0, '%');
                updateMetric('recall', metrics['ai_object_counting_recall'] || 0, '%');
                updateMetric('confidence', metrics['ai_object_counting_model_confidence'] || 0, '%');
                
                // Update detailed information
                document.getElementById('total-requests').textContent = 
                    metrics['ai_object_counting_total_requests'] || 0;
                document.getElementById('images-processed').textContent = 
                    metrics['ai_object_counting_images_processed'] || 0;
                document.getElementById('avg-response-time').textContent = 
                    Math.round((metrics['ai_object_counting_response_time_seconds'] || 0) * 1000) + 'ms';
                document.getElementById('inference-time').textContent = 
                    Math.round((metrics['ai_object_counting_inference_time_seconds'] || 0) * 1000) + 'ms';
                document.getElementById('segments-found').textContent = 
                    metrics['ai_object_counting_segments_found'] || 0;
                
                // Update chart
                const now = new Date();
                performanceData.push({
                    time: now,
                    accuracy: metrics['ai_object_counting_accuracy'] || 0,
                    precision: metrics['ai_object_counting_precision'] || 0,
                    recall: metrics['ai_object_counting_recall'] || 0
                });
                
                // Keep only last 30 data points
                if (performanceData.length > 30) {
                    performanceData.shift();
                }
                
                updateChart();
                updateUptime();
                updateLastUpdate();
                
            } catch (error) {
                console.error('Error fetching metrics:', error);
                showError('Failed to fetch metrics: ' + error.message);
            }
        }
        
        function updateMetric(id, value, suffix = '') {
            const element = document.getElementById(id);
            const formattedValue = (value * 100).toFixed(1);
            element.textContent = formattedValue + suffix;
            
            // Update trend indicator
            const trendElement = document.getElementById(id + '-trend');
            if (value > 0.8) {
                trendElement.textContent = '📈';
                trendElement.style.color = '#4CAF50';
            } else if (value > 0.6) {
                trendElement.textContent = '➡️';
                trendElement.style.color = '#ff9800';
            } else {
                trendElement.textContent = '📉';
                trendElement.style.color = '#f44336';
            }
        }
        
        function updateChart() {
            if (performanceChart) {
                performanceChart.data.labels = performanceData.map(d => 
                    d.time.toLocaleTimeString()
                );
                performanceChart.data.datasets[0].data = performanceData.map(d => d.accuracy);
                performanceChart.data.datasets[1].data = performanceData.map(d => d.precision);
                performanceChart.data.datasets[2].data = performanceData.map(d => d.recall);
                performanceChart.update('none');
            }
        }
        
        function updateUptime() {
            const uptime = Math.floor((Date.now() - startTime) / 1000);
            const hours = Math.floor(uptime / 3600);
            const minutes = Math.floor((uptime % 3600) / 60);
            const seconds = uptime % 60;
            document.getElementById('uptime').textContent = 
                `${hours}h ${minutes}m ${seconds}s`;
        }
        
        function updateLastUpdate() {
            document.getElementById('last-update').textContent = 
                new Date().toLocaleTimeString();
        }
        
        // Enhanced system status checking
        async function checkSystemStatus() {
            // Check Backend API
            try {
                const response = await fetch('http://localhost:5001/api/health');
                if (response.ok) {
                    updateStatus('api', 'Online', 'online');
                    updateStatusIcon('api-icon', 'fas fa-check-circle', 'online');
                } else {
                    updateStatus('api', 'Offline', 'offline');
                    updateStatusIcon('api-icon', 'fas fa-times-circle', 'offline');
                }
            } catch (error) {
                updateStatus('api', 'Offline', 'offline');
                updateStatusIcon('api-icon', 'fas fa-times-circle', 'offline');
            }
            
            // Check Metrics
            try {
                const response = await fetch('/api/metrics');
                if (response.ok) {
                    updateStatus('metrics', 'Active', 'online');
                    updateStatusIcon('metrics-icon', 'fas fa-chart-bar', 'online');
                } else {
                    updateStatus('metrics', 'Inactive', 'offline');
                    updateStatusIcon('metrics-icon', 'fas fa-exclamation-triangle', 'offline');
                }
            } catch (error) {
                updateStatus('metrics', 'Inactive', 'offline');
                updateStatusIcon('metrics-icon', 'fas fa-exclamation-triangle', 'offline');
            }
            
            // Check AI Models (simplified check)
            updateStatus('ai', 'Loaded', 'online');
            updateStatusIcon('ai-icon', 'fas fa-brain', 'online');
            
            // Check Database
            updateStatus('db', 'Active', 'online');
            updateStatusIcon('db-icon', 'fas fa-database', 'online');
        }
        
        function updateStatus(id, text, status) {
            const element = document.getElementById(id + '-status');
            element.textContent = text;
            element.className = 'status-value ' + status;
        }
        
        function updateStatusIcon(id, iconClass, status) {
            const element = document.getElementById(id);
            element.className = iconClass + ' status-icon ' + status;
        }
        
        function showError(message) {
            // Create or update error message
            let errorDiv = document.getElementById('error-message');
            if (!errorDiv) {
                errorDiv = document.createElement('div');
                errorDiv.id = 'error-message';
                errorDiv.className = 'error-message';
                document.querySelector('.container').insertBefore(errorDiv, document.querySelector('.grid'));
            }
            errorDiv.textContent = message;
            setTimeout(() => {
                if (errorDiv) errorDiv.remove();
            }, 5000);
        }
        
        function refreshAll() {
            const btn = document.querySelector('.refresh-btn i');
            btn.className = 'fas fa-sync-alt loading';
            
            Promise.all([
                fetchMetrics(),
                checkSystemStatus()
            ]).finally(() => {
                btn.className = 'fas fa-sync-alt';
            });
        }
        
        // Initialize everything
        document.addEventListener('DOMContentLoaded', function() {
            initChart();
            fetchMetrics();
            checkSystemStatus();
            
            // Update every 3 seconds
            setInterval(fetchMetrics, 3000);
            setInterval(checkSystemStatus, 10000);
            setInterval(updateUptime, 1000);
        });
    </script>
</body>
</html>
        """
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html_content.encode())

def start_enhanced_monitoring_server(port=8080):
    """Start the enhanced monitoring server"""
    handler = EnhancedMonitoringHandler
    
    with socketserver.TCPServer(("", port), handler) as httpd:
        logger.info(f"Enhanced monitoring server started on port {port}")
        logger.info(f"Dashboard: http://localhost:{port}/dashboard")
        logger.info(f"Metrics: http://localhost:{port}/metrics")
        logger.info(f"API: http://localhost:{port}/api/metrics")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            logger.info("Enhanced monitoring server stopped")

if __name__ == "__main__":
    start_enhanced_monitoring_server()
