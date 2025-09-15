# Docker Setup for AI Object Counting Application

This document provides instructions for running the AI Object Counting application using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of available RAM
- 10GB of free disk space (for AI models)

## Quick Start

1. **Clone and navigate to the project directory:**
   ```bash
   cd ai-engineering-lab-project
   ```

2. **Copy environment variables (optional):**
   ```bash
   cp docker-compose.env .env
   # Edit .env file to customize ports if needed
   ```

3. **Start the complete stack:**
   ```bash
   docker-compose up -d
   ```

4. **Access the services:**
   - **AI Application API**: http://localhost:5001
   - **Grafana Dashboard**: http://localhost:3000 (admin/admin123)
   - **Prometheus**: http://localhost:9090
   - **Node Exporter**: http://localhost:9100

## Environment Variables

The following environment variables can be customized:

| Variable | Default | Description |
|----------|---------|-------------|
| `API_PORT` | 5001 | Port for the main AI application |
| `MONITORING_PORT` | 8080 | Port for the monitoring server |
| `PROMETHEUS_PORT` | 9090 | Port for Prometheus |
| `GRAFANA_PORT` | 3000 | Port for Grafana |
| `GRAFANA_ADMIN_USER` | admin | Grafana admin username |
| `GRAFANA_ADMIN_PASSWORD` | admin123 | Grafana admin password |
| `NODE_EXPORTER_PORT` | 9100 | Port for Node Exporter |

## Services

### AI Application (`ai-app`)
- **Image**: Built from local Dockerfile
- **Port**: 5001 (configurable)
- **Health Check**: `/api/health` endpoint
- **Volumes**: 
  - `./.huggingface_cache:/app/.huggingface_cache` (AI models cache)
  - `./uploads:/app/uploads` (uploaded images)

### Prometheus (`prometheus`)
- **Image**: `prom/prometheus:latest`
- **Port**: 9090 (configurable)
- **Configuration**: `./monitoring/prometheus.yml`
- **Data**: Persistent volume `prometheus_data`

### Grafana (`grafana`)
- **Image**: `grafana/grafana:latest`
- **Port**: 3000 (configurable)
- **Credentials**: admin/admin123 (configurable)
- **Dashboards**: Auto-provisioned from `./monitoring/grafana/dashboards/`
- **Data**: Persistent volume `grafana_data`

### Node Exporter (`node-exporter`)
- **Image**: `prom/node-exporter:latest`
- **Port**: 9100 (configurable)
- **Purpose**: System metrics collection

## Grafana Dashboards

The following dashboards are automatically provisioned:

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

## Commands

### Start services
```bash
docker-compose up -d
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ai-app
```

### Stop services
```bash
docker-compose down
```

### Stop and remove volumes
```bash
docker-compose down -v
```

### Rebuild and restart
```bash
docker-compose up -d --build
```

### Scale services (if needed)
```bash
docker-compose up -d --scale ai-app=2
```

## Troubleshooting

### Port Conflicts
If you encounter port conflicts, modify the `.env` file or set environment variables:
```bash
export API_PORT=5002
export GRAFANA_PORT=3001
docker-compose up -d
```

### AI Models Not Loading
The first startup may take several minutes to download AI models. Check logs:
```bash
docker-compose logs -f ai-app
```

### Grafana Dashboard Not Loading
1. Ensure Prometheus is running and accessible
2. Check Grafana logs: `docker-compose logs -f grafana`
3. Verify dashboard files exist in `./monitoring/grafana/dashboards/`

### Memory Issues
If the application runs out of memory:
1. Increase Docker memory limit to at least 4GB
2. Monitor memory usage in Grafana dashboard
3. Consider running only essential services

## Development

For development, you can run individual services:

```bash
# Start only monitoring stack
docker-compose up -d prometheus grafana node-exporter

# Run AI app locally
python3 app.py
```

## Production Considerations

For production deployment:

1. **Security**:
   - Change default Grafana credentials
   - Use secrets management for sensitive data
   - Enable HTTPS/TLS

2. **Performance**:
   - Use production WSGI server (gunicorn)
   - Configure resource limits
   - Set up proper logging

3. **Monitoring**:
   - Configure alerting rules in Prometheus
   - Set up external monitoring
   - Regular backup of Grafana dashboards

4. **Scaling**:
   - Use load balancer for multiple app instances
   - Configure Prometheus federation
   - Set up Grafana clustering
