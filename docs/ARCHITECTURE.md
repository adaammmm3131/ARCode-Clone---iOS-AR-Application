# Architecture - ARCode Clone

Documentation complète de l'architecture du système ARCode Clone.

## 📚 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture iOS](#architecture-ios)
3. [Architecture Backend](#architecture-backend)
4. [Flux de Données](#flux-de-données)
5. [Sécurité](#sécurité)
6. [Performance](#performance)
7. [Diagrammes](#diagrammes)

## 🏗️ Vue d'Ensemble

ARCode Clone est une application iOS de réalité augmentée avec un backend Python/Flask.

### Composants Principaux

```
┌─────────────────┐
│   iOS App       │
│   (SwiftUI)     │
└────────┬────────┘
         │ HTTPS/REST
         │
┌────────▼────────┐
│   API Gateway   │
│   (Nginx)       │
└────────┬────────┘
         │
┌────────▼────────┐
│   Flask API     │
│   (Python)      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼────┐
│PostgreSQL│ │ Redis  │
└─────────┘ └───────┘
```

## 📱 Architecture iOS

### Pattern MVVM

```
View (SwiftUI)
    ↓ observes
ViewModel
    ↓ uses
Service (Protocol)
    ↓ implements
Concrete Service
    ↓ calls
NetworkService / ARKit / etc.
```

### Dependency Injection (Swinject)

Toutes les dépendances sont résolues via `DependencyContainer`:

```swift
// Enregistrement
container.register(NetworkServiceProtocol.self) { _ in
    NetworkService()
}.inObjectScope(.container)

// Résolution
let networkService = container.resolve(NetworkServiceProtocol.self)
```

### Structure des Modules

```
Sources/
├── ARCodeCloneApp.swift      # Entry point
├── Views/                    # SwiftUI Views
│   ├── DashboardHomeView
│   ├── ARExperienceView
│   └── ...
├── ViewModels/              # MVVM ViewModels
│   ├── DashboardViewModel
│   ├── ARExperienceViewModel
│   └── ...
├── Models/                  # Data Models
│   ├── ARCode
│   ├── User
│   └── ...
├── Services/                # Business Logic
│   ├── NetworkService
│   ├── ARRenderingPipeline
│   ├── AnalyticsService
│   └── ...
└── Utils/                   # Utilities
    ├── DependencyContainer
    └── ARConfigurationFactory
```

### AR Rendering Pipeline

```
ARSCNView
    ↓
ARRenderingPipeline
    ├── ARSession Setup
    ├── Plane Detection
    ├── Lighting Estimation
    ├── Model Loading
    └── Rendering Optimization
        ├── Frustum Culling
        ├── LOD Switching
        └── Occlusion Handling
```

## 🔧 Architecture Backend

### Stack Technique

- **API Gateway**: Nginx (reverse proxy, SSL, rate limiting)
- **Application**: Flask (Python)
- **Database**: PostgreSQL
- **Cache**: Redis
- **Storage**: Cloudflare R2 (S3-compatible)
- **Processing**: COLMAP, Nerfstudio, Blender
- **Queue**: Redis Queue (RQ)

### Structure Backend

```
backend/
├── api/                    # Flask API endpoints
│   ├── app.py             # Main application
│   ├── cta_links_api.py
│   ├── workspaces_api.py
│   └── ...
├── ai/                     # AI services
│   ├── ollama_api.py
│   └── stable_diffusion_api.py
├── photogrammetry/         # 3D processing
│   ├── colmap_pipeline.py
│   └── mesh_optimizer.py
├── gaussian/               # Gaussian Splatting
│   └── gaussian_trainer.py
├── queue/                  # Background jobs
│   ├── job_service.py
│   └── workers/
├── database/               # Database schema
│   ├── schema.sql
│   └── migrations/
└── monitoring/             # Monitoring
    ├── grafana/
    └── prometheus/
```

### Flux de Traitement

```
User Upload Video
    ↓
Flask API receives
    ↓
Enqueue Job (RQ)
    ↓
Worker picks up
    ↓
COLMAP Pipeline
    ├── Frame Extraction
    ├── Feature Extraction
    ├── Sparse Reconstruction
    ├── Dense Reconstruction
    └── Mesh Generation
    ↓
Blender Optimization
    ├── Mesh Cleanup
    ├── Retopology
    └── LOD Generation
    ↓
Format Conversion
    ├── GLB
    └── USDZ
    ↓
Upload to R2
    ↓
Update AR Code
    ↓
Notify User
```

## 🔄 Flux de Données

### Création AR Code

```
iOS App
    ↓ POST /api/v1/ar-codes/create
API Gateway (Nginx)
    ↓
Flask API
    ↓
PostgreSQL (insert)
    ↓
Redis (cache)
    ↓
Response JSON
    ↓
iOS App (update UI)
```

### Scan QR Code

```
User scans QR
    ↓
Parse URL (ar-code.com/a/abc123)
    ↓
GET /api/v1/ar-codes/{id}
    ↓
Load Asset from R2
    ↓
Render in AR
    ↓
Track Analytics
    ↓ POST /api/v1/analytics/track
```

### Upload & Processing

```
User uploads video
    ↓
POST /api/v1/3d/upload
    ↓
Upload to R2 (presigned URL)
    ↓
POST /api/v1/3d/photogrammetry
    ↓
Enqueue job (RQ)
    ↓
Worker processes
    ↓
Update job status (Redis)
    ↓
Webhook notification
    ↓
iOS app updates UI
```

## 🔒 Sécurité

### Authentification Flow

```
User Login
    ↓
Supabase Auth
    ↓
JWT Token
    ↓
Store in Keychain (iOS)
    ↓
Include in API requests
    ↓
API validates token
    ↓
Access granted
```

### Rate Limiting

```
Request
    ↓
Nginx (first layer)
    ├── IP-based limiting
    └── Pass to Flask
        ↓
Flask-Limiter (second layer)
    ├── User-based limiting
    └── Redis counter
```

### Data Security

- **HTTPS Only** (TLS 1.3)
- **JWT Tokens** (expiration, refresh)
- **Keychain Storage** (iOS)
- **Input Validation** (all endpoints)
- **SQL Injection Prevention** (parameterized queries)
- **XSS Prevention** (content sanitization)

## ⚡ Performance

### iOS Optimization

- **AR Rendering**: 60fps target
- **Memory**: <150MB per scene
- **LOD**: Automatic switching
- **Texture Streaming**: Progressive loading
- **Cache**: Local asset caching

### Backend Optimization

- **Database**: Indexed queries
- **Redis Cache**: Frequent queries
- **CDN**: Cloudflare R2 (edge locations)
- **Compression**: Draco (3D), WebP (images)
- **Async Processing**: Background jobs

### CDN Strategy

```
User Request
    ↓
Cloudflare CDN
    ├── Cache hit? → Return cached
    └── Cache miss? → Origin (R2)
        ↓
        Cache for 1 month
        ↓
        Return to user
```

## 📊 Diagrammes

### Architecture Complète

```
┌─────────────────────────────────────────────────────────┐
│                    iOS Application                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │  Views   │  │ViewModels│  │ Services │             │
│  │ (SwiftUI)│  │  (MVVM)  │  │(Protocol)│             │
│  └──────────┘  └──────────┘  └──────────┘             │
│       │              │              │                   │
│       └──────────────┴──────────────┘                   │
│                    │                                     │
│              DependencyContainer                        │
└────────────────────┼─────────────────────────────────────┘
                     │ HTTPS/REST
                     │
┌────────────────────▼─────────────────────────────────────┐
│              Nginx API Gateway                           │
│  ┌──────────────────────────────────────┐              │
│  │  SSL Termination, Rate Limiting      │              │
│  └──────────────────────────────────────┘              │
└────────────────────┼─────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│              Flask Application                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │   API    │  │  Queue   │  │  Workers  │            │
│  │ Endpoints│  │  (RQ)    │  │(Processing)│            │
│  └──────────┘  └──────────┘  └──────────┘            │
└────────────────────┼─────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼──────┐ ┌───▼──────┐
│ PostgreSQL   │ │ Redis   │ │ Cloudflare│
│  (Database)  │ │ (Cache) │ │ R2 (Storage)│
└──────────────┘ └─────────┘ └──────────┘
```

### Flux AR Experience

```
User scans QR code
    ↓
Parse URL metadata
    ↓
GET AR Code (API)
    ↓
Load Asset (CDN)
    ├── 3D Model → SceneKit
    ├── Video → AVPlayer
    ├── Image → UIImage
    └── Splat → Gaussian Renderer
    ↓
ARKit Session
    ├── Plane Detection
    ├── Lighting Estimation
    └── Tracking
    ↓
Render Pipeline
    ├── Frustum Culling
    ├── LOD Selection
    └── Occlusion Handling
    ↓
60fps Rendering
    ↓
User Interactions
    ├── Gestures
    ├── CTA Clicks
    └── Screenshots
    ↓
Analytics Tracking
```

### Processing Pipeline

```
Video Upload
    ↓
Frame Extraction (30fps)
    ↓
COLMAP Pipeline
    ├── Feature Extraction (SIFT/ORB)
    ├── Feature Matching
    ├── Sparse Reconstruction (SfM)
    ├── Bundle Adjustment
    ├── Dense Reconstruction (MVS)
    └── Point Cloud
    ↓
Mesh Generation
    ├── Poisson Surface Reconstruction
    ├── Texture Mapping
    └── UV Unwrapping
    ↓
Blender Optimization
    ├── Mesh Cleanup
    ├── Retopology
    ├── LOD Generation (High/Medium/Low)
    └── Compression (Draco)
    ↓
Format Conversion
    ├── GLB (glTF 2.0)
    └── USDZ (Apple)
    ↓
Upload to R2
    ↓
Notify User
```

## 🔍 Monitoring & Observability

### Metrics Collection

- **Prometheus**: System metrics, API metrics
- **Grafana**: Dashboards, visualization
- **Sentry**: Error tracking, performance
- **Umami**: User analytics

### Logging

- **Application Logs**: Structured JSON
- **Access Logs**: Nginx
- **Error Logs**: Sentry
- **Performance Logs**: Custom metrics

## 📦 Deployment

### iOS App

- **TestFlight**: Beta testing
- **App Store**: Production release
- **CI/CD**: GitHub Actions
- **Code Signing**: Automated

### Backend

- **Oracle Cloud**: VM hosting
- **Docker**: Containerization (optional)
- **Systemd**: Service management
- **Nginx**: Reverse proxy
- **SSL**: Cloudflare SSL

## 🔗 Liens Utiles

- [Guide Développeur](DEVELOPER_GUIDE.md)
- [Documentation API](API_DOCUMENTATION.md)
- [Architecture iOS détaillée](../README.md#architecture)



