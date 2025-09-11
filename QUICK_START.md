# ⚡ Quick Start Commands

## 🚀 One-Command Setup (Recommended)

```bash
# Clone, checkout, and start everything
git clone https://github.com/mithulram/ai-engineering-lab-project.git && \
cd ai-engineering-lab-project && \
git checkout week2 && \
pip3 install -r requirements.txt && \
python3 fix_huggingface_cache.py && \
cd flutter_frontend && \
flutter pub get && \
cd .. && \
chmod +x start_app.sh && \
./start_app.sh
```

## 🔧 Manual Setup Commands

### 1. Repository Setup
```bash
git clone https://github.com/mithulram/ai-engineering-lab-project.git
cd ai-engineering-lab-project
git checkout week2
```

### 2. Dependencies
```bash
pip3 install -r requirements.txt
python3 fix_huggingface_cache.py
cd flutter_frontend && flutter pub get && cd ..
```

### 3. Start Services
```bash
# Option A: Automated (Recommended)
chmod +x start_app.sh
./start_app.sh

# Option B: Manual (3 terminals)
# Terminal 1:
export HF_HOME=$(pwd)/.huggingface_cache && export TRANSFORMERS_CACHE=$(pwd)/.huggingface_cache && python3 app.py

# Terminal 2:
python3 monitoring_server_enhanced.py

# Terminal 3:
cd flutter_frontend && flutter run -d web-server --web-port 3000
```

## 🌐 Access URLs
- **App**: http://localhost:3000
- **API**: http://localhost:5001
- **Monitor**: http://localhost:8080/dashboard

## 🛑 Stop Everything
```bash
./stop_app.sh
```

## 🔍 Quick Health Check
```bash
curl http://localhost:5001/api/health
curl http://localhost:8080/api/metrics
```
