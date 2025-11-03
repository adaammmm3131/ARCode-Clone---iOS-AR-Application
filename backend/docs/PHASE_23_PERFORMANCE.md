# Phase 23 - Performance - Guide Complet

## Vue d'ensemble

Phase 23 optimise les performances avec compression, lazy loading et cache strategy.

## Phase 23.1 - Performance Compression

### Draco Compression (3D Models)

**Fichier:** `backend/performance/draco_compression.py`

Compression GLB avec Draco:
- Compression level: 0-10 (default: 6)
- Quantization bits:
  - Positions: 14 bits
  - Normals: 10 bits
  - Texture coordinates: 12 bits

**Installation:**
```bash
npm install -g gltf-pipeline
# ou utiliser Blender avec export_draco_mesh_compression_enable
```

**Résultats:**
- Compression ratio: 50-80% typical
- Quality preserved

### Image Optimization

**Déjà implémenté:** `backend/cdn/image_optimizer.py`

- WebP conversion (quality 80)
- AVIF conversion (fallback WebP)
- Responsive images (multiple sizes)

### Video Optimization

**Déjà implémenté:** `backend/cdn/video_optimizer.py`

- H.265 compression (CRF 28)
- H.264 fallback (CRF 23)
- HLS adaptive bitrate streaming

### SVG Optimization

**Fichier:** `backend/performance/svg_optimizer.py`

Optimisations:
- Remove comments
- Remove whitespace
- Optimize paths
- Minify path data

## Phase 23.2 - Performance Loading

### Lazy Loading 3D Models

**Fichier:** `Sources/Services/AssetLoadingService.swift`

- Load models only when visible
- Progressive loading textures
- Background loading

### Progressive Texture Loading

**Fichier:** `Sources/Services/ProgressiveTextureLoader.swift`

- Load low-res first
- Upgrade to high-res asynchronously
- Mipmap support

### Auto LOD Switching

**Fichier:** `Sources/Services/AutoLODManager.swift`

Automatic LOD switching basé sur distance:
- High: < 2m
- Medium: 2-5m
- Low: > 5m

Updates every 0.5s.

### Skeleton Loaders

**Fichier:** `Sources/Services/SkeletonLoader.swift`

Loading states:
- `SkeletonView` - Basic skeleton
- `ARCodeCardSkeleton` - Card skeleton
- `ARCodeListSkeleton` - List skeleton
- Shimmer animation effect

## Phase 23.3 - Performance Cache

### Redis Query Caching

**Fichier:** `backend/performance/query_cache.py`

Features:
- Automatic query result caching
- TTL-based expiration
- Cache key generation from query + params
- Decorator for function caching

**Usage:**
```python
from performance.query_cache import get_cached_query, cache_query

# Get cached result
result = get_cached_query(query, params)
if not result:
    result = execute_query(query, params)
    cache_query(query, result, params, ttl=600)
```

### Cache Invalidation

**Fichier:** `backend/performance/cache_invalidation.py`

Smart invalidation:
- User cache invalidation
- AR Code cache invalidation
- Asset cache invalidation
- Query cache invalidation
- CDN cache invalidation

### Browser Caching

**Déjà configuré:** `backend/config/nginx.conf`

Headers:
- Static assets: `Cache-Control: public, immutable` (1 month)
- HTML: `Cache-Control: public, must-revalidate` (1 hour)
- API: `Cache-Control: no-store, no-cache` (bypass)

### CDN Edge Caching

**Déjà configuré:** Cloudflare

- 330+ edge locations
- Automatic compression
- Cache rules (1 month for assets)

## Configuration

### Environment Variables

```bash
# Query Cache
QUERY_CACHE_TTL=300  # 5 minutes

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Tools Required

```bash
# Draco compression
npm install -g gltf-pipeline

# Or use Blender (already installed)
# Blender supports Draco export natively
```

## Performance Targets

- **3D Model Load:** < 2s (via CDN + compression)
- **Image Load:** < 1s (WebP/AVIF)
- **Video Load:** Progressive (HLS)
- **LOD Switch:** < 0.5s
- **Cache Hit Ratio:** > 80%
- **TTFB:** < 200ms

## Checklist Phase 23

- [x] Draco compression
- [x] WebP/AVIF conversion
- [x] H.265/H.264 compression
- [x] SVG optimization
- [x] Progressive texture loading
- [x] Auto LOD switching
- [x] Skeleton loaders
- [x] Redis query caching
- [x] Cache invalidation strategy
- [x] Browser caching headers

## Prochaines étapes

Voir Phase 24 - Email Brevo pour notifications email.







