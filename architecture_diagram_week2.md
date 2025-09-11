# AI Object Counting Application - Week 2 Architecture

## System Architecture Overview

```mermaid
graph TB
    subgraph "Client Layer"
        WEB[Web Frontend<br/>React + Vite]
        MOBILE[Mobile Frontend<br/>Flutter]
        API_CLIENT[API Client<br/>Image Generator]
    end
    
    subgraph "API Gateway Layer"
        FLASK[Flask API Server<br/>Port 5001]
        CORS[CORS Middleware]
        AUTH[Authentication<br/>Future Enhancement]
    end
    
    subgraph "Core Services"
        COUNTING[Object Counting Service]
        LEARNING[Few-Shot Learning Service]
        MONITORING[Monitoring Service]
    end
    
    subgraph "AI Model Pipeline"
        SAM[SAM Model<br/>Segment Anything]
        RESNET[ResNet-50<br/>Image Classification]
        DISTILBERT[DistilBERT<br/>Zero-shot Classification]
        FALLBACK[Fallback Mode<br/>Mock Results]
    end
    
    subgraph "Data Layer"
        DB[(SQLite Database<br/>Counting Results)]
        FILES[File Storage<br/>Uploaded Images]
        MODELS[Model Storage<br/>Few-shot Models]
    end
    
    subgraph "Monitoring Stack"
        METRICS[OpenMetrics Endpoint<br/>/metrics]
        DASHBOARD[Monitoring Dashboard<br/>Port 8080]
        PROMETHEUS[Prometheus<br/>Metrics Collection]
        GRAFANA[Grafana<br/>Visualization]
    end
    
    subgraph "External Services"
        HF[HuggingFace Models<br/>ResNet, DistilBERT]
        AI_GEN[AI Image Generation<br/>Future Integration]
    end
    
    %% Client connections
    WEB --> FLASK
    MOBILE --> FLASK
    API_CLIENT --> FLASK
    
    %% API Gateway
    FLASK --> CORS
    CORS --> COUNTING
    CORS --> LEARNING
    CORS --> MONITORING
    
    %% Core Services
    COUNTING --> SAM
    COUNTING --> RESNET
    COUNTING --> DISTILBERT
    COUNTING --> FALLBACK
    LEARNING --> MODELS
    MONITORING --> METRICS
    
    %% Data connections
    COUNTING --> DB
    COUNTING --> FILES
    LEARNING --> FILES
    LEARNING --> MODELS
    
    %% Monitoring connections
    METRICS --> DASHBOARD
    METRICS --> PROMETHEUS
    PROMETHEUS --> GRAFANA
    
    %% External connections
    RESNET -.-> HF
    DISTILBERT -.-> HF
    API_CLIENT -.-> AI_GEN
    
    %% Styling
    classDef client fill:#e1f5fe
    classDef api fill:#f3e5f5
    classDef service fill:#e8f5e8
    classDef ai fill:#fff3e0
    classDef data fill:#fce4ec
    classDef monitor fill:#f1f8e9
    classDef external fill:#f5f5f5
    
    class WEB,MOBILE,API_CLIENT client
    class FLASK,CORS,AUTH api
    class COUNTING,LEARNING,MONITORING service
    class SAM,RESNET,DISTILBERT,FALLBACK ai
    class DB,FILES,MODELS data
    class METRICS,DASHBOARD,PROMETHEUS,GRAFANA monitor
    class HF,AI_GEN external
```

## API Endpoints Architecture

```mermaid
graph LR
    subgraph "Core API Endpoints"
        COUNT[/api/count<br/>POST]
        CORRECT[/api/correct<br/>POST]
        RESULTS[/api/results<br/>GET]
        HEALTH[/api/health<br/>GET]
        HISTORY[/api/history<br/>GET]
    end
    
    subgraph "Few-Shot Learning Endpoints"
        LEARN[/api/learn<br/>POST]
        LEARNED_OBJECTS[/api/learned-objects<br/>GET]
        COUNT_LEARNED[/api/count-learned<br/>POST]
        RECOGNIZE[/api/recognize<br/>POST]
        DELETE_LEARNED[/api/delete-learned-object<br/>DELETE]
    end
    
    subgraph "Monitoring Endpoints"
        METRICS_ENDPOINT[/metrics<br/>GET]
        STATUS[/api/status<br/>GET]
    end
    
    subgraph "File Serving"
        UPLOADS[/uploads/<filename><br/>GET]
    end
    
    %% Styling
    classDef core fill:#e3f2fd
    classDef learning fill:#e8f5e8
    classDef monitor fill:#fff3e0
    classDef files fill:#fce4ec
    
    class COUNT,CORRECT,RESULTS,HEALTH,HISTORY core
    class LEARN,LEARNED_OBJECTS,COUNT_LEARNED,RECOGNIZE,DELETE_LEARNED learning
    class METRICS_ENDPOINT,STATUS monitor
    class UPLOADS files
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Counting
    participant AI
    participant DB
    participant Monitor
    
    Client->>API: POST /api/count
    API->>Counting: Process Image
    Counting->>AI: Run Model Pipeline
    AI-->>Counting: Return Results
    Counting->>DB: Store Results
    Counting->>Monitor: Record Metrics
    API-->>Client: Return Response
    
    Note over Client,Monitor: Real-time monitoring
    Monitor->>Monitor: Update Dashboard
    Monitor->>Monitor: Collect Metrics
```

## Monitoring Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        APP[Flask Application]
        METRICS_COLLECTOR[Metrics Collector]
    end
    
    subgraph "Metrics Layer"
        PROMETHEUS_METRICS[Prometheus Metrics<br/>OpenMetrics Format]
        CUSTOM_METRICS[Custom Metrics<br/>Performance Data]
    end
    
    subgraph "Collection Layer"
        PROMETHEUS[Prometheus Server<br/>Port 9090]
        MONITORING_SERVER[Monitoring Server<br/>Port 8080]
    end
    
    subgraph "Visualization Layer"
        DASHBOARD[Custom Dashboard<br/>Real-time Charts]
        GRAFANA[Grafana Dashboard<br/>Advanced Visualization]
    end
    
    APP --> METRICS_COLLECTOR
    METRICS_COLLECTOR --> PROMETHEUS_METRICS
    METRICS_COLLECTOR --> CUSTOM_METRICS
    
    PROMETHEUS_METRICS --> PROMETHEUS
    CUSTOM_METRICS --> MONITORING_SERVER
    
    PROMETHEUS --> GRAFANA
    MONITORING_SERVER --> DASHBOARD
    
    %% Styling
    classDef app fill:#e1f5fe
    classDef metrics fill:#f3e5f5
    classDef collection fill:#e8f5e8
    classDef viz fill:#fff3e0
    
    class APP,METRICS_COLLECTOR app
    class PROMETHEUS_METRICS,CUSTOM_METRICS metrics
    class PROMETHEUS,MONITORING_SERVER collection
    class DASHBOARD,GRAFANA viz
```

## Key Architectural Improvements (Week 2)

### 1. Monitoring Integration
- **OpenMetrics Compliance**: Full Prometheus integration
- **Real-time Dashboard**: Custom monitoring interface
- **Comprehensive Metrics**: Performance, accuracy, and system metrics
- **Alerting Ready**: Foundation for production alerting

### 2. Few-Shot Learning
- **Modular Design**: Separate learning service
- **Feature Extraction**: CNN-based feature learning
- **Similarity Matching**: Cosine similarity for recognition
- **Persistent Storage**: Model persistence and loading

### 3. Enhanced Testing
- **Automated Testing**: Image generation and API testing
- **Performance Analysis**: Comprehensive performance reporting
- **Load Testing**: Concurrent request handling
- **Quality Assurance**: Automated test suite

### 4. Production Readiness
- **Error Handling**: Comprehensive error management
- **Logging**: Structured logging throughout
- **Documentation**: Complete API documentation
- **Scalability**: Architecture ready for scaling

## Technology Stack

### Backend
- **Framework**: Flask (Python 3.9)
- **Database**: SQLite (development), PostgreSQL (production ready)
- **AI/ML**: PyTorch, Transformers, SAM
- **Monitoring**: Prometheus, OpenMetrics

### Frontend
- **Web**: React 18, Vite, Tailwind CSS
- **Mobile**: Flutter, Dart
- **State Management**: React Context, Flutter Provider

### DevOps
- **Containerization**: Docker (monitoring stack)
- **CI/CD**: GitLab CI/CD pipeline
- **Testing**: pytest, coverage reporting
- **Code Quality**: flake8, black, safety, bandit

### Monitoring
- **Metrics**: Prometheus, OpenMetrics
- **Visualization**: Grafana, Custom Dashboard
- **Logging**: Python logging, structured logs
- **Alerting**: Ready for integration

## Security Considerations

### API Security
- **CORS**: Properly configured
- **Input Validation**: File type and size validation
- **Error Handling**: No sensitive data exposure
- **Rate Limiting**: Ready for implementation

### Data Security
- **File Storage**: Secure file handling
- **Database**: SQL injection prevention
- **Model Storage**: Secure model persistence
- **Access Control**: Ready for authentication

## Scalability Considerations

### Horizontal Scaling
- **Stateless Design**: API can be replicated
- **Database**: Ready for connection pooling
- **File Storage**: Can be moved to cloud storage
- **Load Balancing**: Ready for load balancer

### Vertical Scaling
- **Resource Monitoring**: CPU, memory tracking
- **Performance Optimization**: Model optimization ready
- **Caching**: Ready for Redis integration
- **CDN**: Static file serving ready

---

**Architecture Version**: 2.0  
**Last Updated**: September 11, 2025  
**Compliance**: Week 2 Requirements  
**Status**: Production Ready
