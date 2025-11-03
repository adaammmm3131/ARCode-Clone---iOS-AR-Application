# Phase 21.2 - CDN Optimization

Guide pour optimisation avancée CDN: compression, image optimization, lazy loading.

## Vue d'ensemble

Cloudflare Free plan inclut:
- ✅ Compression gzip/brotli automatique
- ✅ Image optimization (WebP/AVIF) via Polish
- ✅ Auto Minify
- ✅ Edge locations worldwide (330+)
- ✅ Bandwidth illimité

## Étape 1: Image Optimization

### 1.1. Polish (Image Optimization)

Dashboard → Speed → Optimization → Polish:

**Polish:** Lossless (ou Lossy pour meilleure compression)
- Lossless: Meilleure qualité, compression modérée
- Lossly: Compression agressive, qualité réduite

**Note:** Polish n'est pas disponible en Free plan. Alternative:
- Server-side conversion WebP/AVIF
- Utiliser Cloudflare Workers (si disponible)

### 1.2. Image Conversion WebP/AVIF

#### Server-Side Conversion

Créer endpoint pour conversion:

```python
# backend/cdn/image_optimizer.py
from PIL import Image
import io

def convert_to_webp(image_data: bytes, quality: int = 80) -> bytes:
    """Convert image to WebP"""
    img = Image.open(io.BytesIO(image_data))
    output = io.BytesIO()
    img.save(output, format='WEBP', quality=quality)
    return output.getvalue()

def convert_to_avif(image_data: bytes, quality: int = 80) -> bytes:
    """Convert image to AVIF (requires pillow-avif-plugin)"""
    img = Image.open(io.BytesIO(image_data))
    output = io.BytesIO()
    img.save(output, format='AVIF', quality=quality)
    return output.getvalue()
```

#### Content Negotiation

Nginx configuration pour servir WebP/AVIF si disponible:

```nginx
location /images/ {
    # Try WebP first, fallback to original
    location ~* \.(jpg|jpeg|png)$ {
        add_header Vary Accept;
        set $webp "";
        if ($http_accept ~* "image/webp") {
            set $webp ".webp";
        }
        try_files "${request_uri}${webp}" $uri =404;
    }
}
```

### 1.3. Responsive Images

Serve multiple sizes:

```python
def generate_responsive_images(image_path: str) -> dict:
    """Generate multiple sizes for responsive images"""
    sizes = {
        'thumbnail': (150, 150),
        'small': (400, 400),
        'medium': (800, 800),
        'large': (1200, 1200),
        'original': None
    }
    
    results = {}
    for name, size in sizes.items():
        if size:
            img = Image.open(image_path)
            img.thumbnail(size, Image.Resampling.LANCZOS)
            results[name] = img
        else:
            results[name] = Image.open(image_path)
    
    return results
```

## Étape 2: Video Optimization

### 2.1. Adaptive Bitrate Streaming

Utiliser HLS (HTTP Live Streaming) ou DASH:

```python
# Generate HLS playlist
def generate_hls_playlist(video_path: str, output_dir: str):
    """Generate HLS adaptive bitrate streams"""
    # Using ffmpeg
    qualities = [
        ('1080p', '1920:1080', '5000k'),
        ('720p', '1280:720', '2500k'),
        ('480p', '854:480', '1000k'),
        ('360p', '640:360', '500k')
    ]
    
    for name, resolution, bitrate in qualities:
        subprocess.run([
            'ffmpeg', '-i', video_path,
            '-c:v', 'libx264',
            '-s', resolution,
            '-b:v', bitrate,
            '-c:a', 'aac',
            '-b:a', '128k',
            '-hls_time', '10',
            '-hls_playlist_type', 'vod',
            f'{output_dir}/{name}.m3u8'
        ])
```

### 2.2. Video Compression

Compress videos avec H.265 (HEVC) ou H.264:

```bash
# H.265 compression (meilleure qualité/taille)
ffmpeg -i input.mp4 -c:v libx265 -crf 28 -c:a copy output.mp4

# H.264 (compatibilité maximale)
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -c:a copy output.mp4
```

## Étape 3: Lazy Loading

### 3.1. Images Lazy Loading

```html
<!-- Native lazy loading -->
<img src="image.jpg" loading="lazy" alt="Image">

<!-- Intersection Observer API -->
<script>
const images = document.querySelectorAll('img[data-src]');
const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            imageObserver.unobserve(img);
        }
    });
});
images.forEach(img => imageObserver.observe(img));
</script>
```

### 3.2. 3D Models Lazy Loading

iOS/Swift:

```swift
// Lazy load 3D models when visible
class LazyAssetLoader {
    func loadAssetWhenVisible(url: URL, view: UIView) {
        // Use ARView or SceneKit view visibility
        // Load asset only when AR view is visible
    }
}
```

## Étape 4: Preloading

### 4.1. Resource Hints

```html
<!-- DNS Prefetch -->
<link rel="dns-prefetch" href="https://assets.ar-code.com">

<!-- Preconnect -->
<link rel="preconnect" href="https://api.ar-code.com" crossorigin>

<!-- Preload critical resources -->
<link rel="preload" href="/critical.js" as="script">
<link rel="preload" href="/critical.css" as="style">

<!-- Prefetch -->
<link rel="prefetch" href="/next-page.html">
```

### 4.2. Preload Critical Assets

```javascript
// Preload critical 3D models
function preloadAssets(assetUrls) {
    assetUrls.forEach(url => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.as = 'fetch';
        link.href = url;
        link.crossOrigin = 'anonymous';
        document.head.appendChild(link);
    });
}
```

## Étape 5: Cache Headers Nginx

Mettre à jour Nginx pour headers optimaux:

```nginx
# Static assets - Long cache
location ~* \.(jpg|jpeg|png|gif|ico|svg|webp|avif|woff|woff2|ttf|eot|glb|usdz|ply|splat)$ {
    expires 1M;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
}

# API - No cache
location /api/ {
    add_header Cache-Control "no-store, no-cache, must-revalidate";
    add_header Pragma "no-cache";
    expires 0;
}

# HTML - Short cache
location ~* \.(html)$ {
    expires 1h;
    add_header Cache-Control "public, must-revalidate";
}
```

## Étape 6: Compression Brotli/Gzip

### 6.1. Nginx Compression

```nginx
# Enable gzip
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript 
           application/json application/javascript application/xml+rss 
           application/rss+xml font/truetype font/opentype 
           application/vnd.ms-fontobject image/svg+xml;

# Enable Brotli (requires nginx-module-brotli)
# brotli on;
# brotli_comp_level 6;
# brotli_types text/plain text/css text/xml text/javascript 
#              application/json application/javascript application/xml+rss;
```

**Note:** Cloudflare gère compression automatiquement, mais configurer sur origin aussi aide.

## Étape 7: Edge Locations

Cloudflare a 330+ edge locations worldwide. Aucune configuration nécessaire - automatique.

**Vérifier edge location:**
```bash
curl -I https://ar-code.com
# Header: cf-ray (indique edge location)
```

## Étape 8: Cache Invalidation

### 8.1. Automatic Invalidation

Via R2 ou assets uploads, invalider cache automatiquement:

```python
from cdn.cloudflare_cache import purge_cache

def upload_and_purge(file_data, key):
    """Upload file and purge Cloudflare cache"""
    url = upload_file(file_data, key, content_type)
    
    # Purge cache for this URL
    purge_cache([url])
    
    return url
```

### 8.2. Cache Tags (Cloudflare Enterprise)

Free plan n'a pas cache tags. Alternative:
- Utiliser versioning dans URLs (`/assets/v1/model.glb`)
- Purge manuel via dashboard

## Étape 9: Performance Monitoring

### 9.1. Cloudflare Analytics

Dashboard → Analytics → Web Analytics:
- Pageviews
- Unique visitors
- Bandwidth saved
- Cache hit ratio

### 9.2. Real User Monitoring

Dashboard → Analytics → Web Analytics:
- Core Web Vitals
- Time to First Byte (TTFB)
- Cache hit ratio

## Checklist

- [ ] Compression gzip/brotli activée
- [ ] Image optimization configurée (WebP/AVIF)
- [ ] Video optimization (H.265/H.264)
- [ ] Lazy loading implémenté
- [ ] Preloading critical assets
- [ ] Cache headers Nginx optimisés
- [ ] Cache invalidation strategy
- [ ] Performance monitoring activé

## Prochaines étapes

Voir Phase 22 - Security pour OAuth et API security.







