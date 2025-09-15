# 🚀 AI Object Counting App - Run Instructions

## 📁 Project Setup

1. **Clone or download** this project to your local machine
2. **Navigate** to the project root directory in your terminal
3. **Verify** you have the following files in your project root:
   - `app.py` (Backend API server)
   - `monitoring_server.py` (Monitoring dashboard)
   - `requirements.txt` (Python dependencies)
   - `flutter_frontend/` (Flutter web app directory)
   - `start_app.sh` and `stop_app.sh` (Optional automation scripts)

## 📋 Prerequisites

Make sure you have the following installed:
- Python 3.9+
- Flutter SDK
- Chrome browser (for Flutter web)

## 🛠️ Setup Commands

### 1. Install Python Dependencies
```bash
# Navigate to your project root directory
# Replace with your actual project path
cd /path/to/your/ai-engineering-lab-project

# Install Python dependencies
pip3 install -r requirements.txt
```

**💡 Tip:** To find your project path, use `pwd` command in your terminal when you're in the project directory.

### 2. Install Flutter Dependencies
```bash
# Navigate to Flutter frontend
cd flutter_frontend

# Install Flutter dependencies
flutter pub get

# Go back to project root
cd ..
```

## 🚀 Running the Application

### Option 1: Run All Services (Recommended)

Open **3 separate terminal windows** and run these commands:

#### Terminal 1 - Backend API Server
```bash
cd /path/to/your/ai-engineering-lab-project
python3 app.py
```
**Expected Output:**
```
INFO:model_pipeline:Using device: cpu
INFO:model_pipeline:SAM model initialized successfully
INFO:__main__:Database tables created
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5001
```

#### Terminal 2 - Monitoring Server
```bash
cd /path/to/your/ai-engineering-lab-project
python3 monitoring_server.py
```
**Expected Output:**
```
INFO:__main__:Monitoring server started on port 8080
INFO:__main__:Dashboard: http://localhost:8080/dashboard
INFO:__main__:API: http://localhost:8080/api/metrics
```

#### Terminal 3 - Flutter Web App
```bash
cd /path/to/your/ai-engineering-lab-project/flutter_frontend
flutter run -d chrome --web-port 3000
```
**Expected Output:**
```
Launching lib/main.dart on Chrome in debug mode...
Web development server is running at http://localhost:3000
```

### Option 2: Run Services in Background

If you prefer to run services in the background:

```bash
# Navigate to project root
cd /path/to/your/ai-engineering-lab-project

# Start backend API (background)
python3 app.py &

# Start monitoring server (background)
python3 monitoring_server.py &

# Start Flutter app (foreground)
cd flutter_frontend
flutter run -d chrome --web-port 3000
```

## 🌐 Access URLs

Once all services are running, you can access:

- **Flutter Web App**: http://localhost:3000
- **Backend API**: http://localhost:5001
- **Monitoring Dashboard**: http://localhost:8080/dashboard
- **API Health Check**: http://localhost:5001/api/health
- **Metrics Endpoint**: http://localhost:5001/metrics

## 🧪 Testing the Application

### 1. Basic Health Check
```bash
# Test backend health
curl http://localhost:5001/api/health

# Test monitoring server
curl http://localhost:8080/api/metrics
```

### 2. Test Object Counting API
```bash
# Test with a sample image (replace with actual image path)
curl -X POST -F "image=@/path/to/your/image.jpg" -F "item_type=car" http://localhost:5001/api/count
```

### 3. Test Few-Shot Learning
```bash
# Get learned objects
curl http://localhost:5001/api/learned-objects

# Learn a new object (replace with actual image paths)
curl -X POST -F "object_name=bicycle" -F "images=@/path/to/image1.jpg" -F "images=@/path/to/image2.jpg" http://localhost:5001/api/learn
```

## 🔧 Troubleshooting

### Port Already in Use
If you get "Address already in use" errors:

```bash
# Kill processes on specific ports
lsof -ti:3000 | xargs kill -9  # Flutter app
lsof -ti:5001 | xargs kill -9  # Backend API
lsof -ti:8080 | xargs kill -9  # Monitoring server

# Or kill all Python processes
pkill -f python3
```

### Flutter Issues
```bash
# Clean Flutter build
cd flutter_frontend
flutter clean
flutter pub get
flutter run -d chrome --web-port 3000
```

### Python Dependencies
```bash
# Reinstall dependencies
pip3 install --upgrade -r requirements.txt
```

## 📱 Flutter App Features to Test

1. **Upload & Count**: Upload images and count objects
2. **Monitoring**: View real-time metrics and system status
3. **Few-Shot Learning**: Learn new object types
4. **Image Generation**: Generate test images automatically
5. **Performance Analysis**: View performance reports
6. **Results & History**: View past counting results

## 🎯 Quick Start Commands

For a quick start, run these commands in order:

```bash
# 1. Make sure you're in the project root directory
# (The directory containing app.py, requirements.txt, etc.)

# 2. Install dependencies
pip3 install -r requirements.txt
cd flutter_frontend && flutter pub get && cd ..

# 3. Start backend services
python3 app.py &
python3 monitoring_server.py &

# 4. Start Flutter app
cd flutter_frontend
flutter run -d chrome --web-port 3000
```

**🚀 Even Easier:** If you have the automation scripts, just run:
```bash
./start_app.sh
```

## 📊 Expected Behavior

- **Backend**: Should show Flask debug server running on port 5001
- **Monitoring**: Should show server running on port 8080
- **Flutter**: Should open Chrome browser with the app at localhost:3000
- **All services**: Should show "Connected" status in the Flutter app

## 🆘 If Something Goes Wrong

1. Check all services are running on correct ports
2. Verify no firewall is blocking the ports
3. Check browser console for JavaScript errors (F12)
4. Ensure all dependencies are installed
5. Try restarting all services

## 📝 Notes

- The app uses real AI models for object counting and analysis
- All core functionality works with real AI processing
- The monitoring dashboard shows real metrics from the backend
- Few-shot learning creates actual model files in `few_shot_models/` directory

---

## 📊 Week 2: Advanced Monitoring & Grafana Dashboards

### 🎯 Grafana Dashboard Import

The application now includes comprehensive Grafana dashboards for monitoring and analysis:

#### **Available Dashboards:**

1. **Pipeline Overview** (`pipeline-overview`)
   - Request rate by status
   - Model inference time by model  
   - Model confidence distribution
   - Average response time

2. **Version Comparison** (`version-comparison`)
   - Accuracy, precision, recall by pipeline version
   - Blocked requests by pipeline version
   - Dropdown filter for pipeline versions

3. **Safety & Misuse** (`safety-misuse`)
   - Blocked requests by reason
   - Top rule triggers (pie chart)
   - Blocked examples over time

4. **Resource & Latency** (`resource-latency`)
   - CPU usage
   - Memory usage
   - Per-model latency histogram (P50, P95, P99)

#### **Import Steps:**

1. **Start Grafana** (if using Docker):
   ```bash
   docker-compose up -d grafana
   ```

2. **Access Grafana**: http://localhost:3000 (admin/admin123)

3. **Dashboards are auto-provisioned** from:
   - `monitoring/grafana/dashboards/`
   - `monitoring/grafana/provisioning/dashboards/dashboards.yml`

4. **Manual Import** (if needed):
   - Go to Grafana → Dashboards → Import
   - Upload JSON files from `monitoring/grafana/dashboards/`

### 🔧 Environment Variables for Port Configuration

To avoid port conflicts, use these environment variables:

```bash
# API Configuration
export API_PORT=5001
export MONITORING_PORT=8080

# Prometheus & Grafana
export PROMETHEUS_PORT=9090
export GRAFANA_PORT=3000
export NODE_EXPORTER_PORT=9100

# Start with custom ports
API_PORT=5002 MONITORING_PORT=8081 python3 app.py
```

### 📈 Metrics Verification

Verify all required metrics are exposed:

```bash
# Check metrics endpoint
curl http://localhost:5001/metrics | grep -E "(pipeline_version|ai_object_counting)"

# Run automated verification tests
python3 test_week2_metrics.py
```

### 🐳 Docker Setup (Complete Stack)

For a complete monitoring stack with Docker:

```bash
# Start complete stack
docker-compose up -d

# Access services:
# - AI App: http://localhost:5001
# - Grafana: http://localhost:3000 (admin/admin123)
# - Prometheus: http://localhost:9090
# - Node Exporter: http://localhost:9100

# View logs
docker-compose logs -f ai-app

# Stop stack
docker-compose down
```

### 🔍 Required Metrics with pipeline_version Labels

The `/metrics` endpoint now exposes:

- `ai_object_counting_inference_time_seconds` (Histogram) with `model`, `object_type`, `pipeline_version`
- `ai_object_counting_model_confidence` (Gauge) with `model`, `object_type`, `pipeline_version`
- `ai_object_counting_request_count_total` (Counter) with `endpoint`, `method`, `status_code`, `pipeline_version`
- `ai_object_counting_blocked_requests_total` (Counter) with `reason`, `pipeline_version`
- `ai_object_counting_accuracy`, `ai_object_counting_precision`, `ai_object_counting_recall` (Gauges) with `pipeline_version`
- Image metadata metrics with `pipeline_version` labels

### 🧪 Verification Commands

```bash
# Test all Week 2 requirements
python3 test_week2_metrics.py

# Check specific metrics
curl -s http://localhost:5001/metrics | grep "pipeline_version"

# Verify Grafana dashboards
ls -la monitoring/grafana/dashboards/*.json

# Test port configuration
MONITORING_PORT=8081 python3 monitoring_server_enhanced.py &
curl http://localhost:8081/api/metrics
```

---

**Happy Testing! 🎉**
