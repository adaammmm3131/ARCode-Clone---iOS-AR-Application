#!/usr/bin/env python3
"""
Lazy Loading Helpers
Generate lazy loading HTML/JS
"""

from typing import List, Dict, Any

def generate_lazy_image_html(
    src: str,
    alt: str,
    placeholder: str = None,
    sizes: str = None
) -> str:
    """
    Generate HTML for lazy-loaded image
    
    Args:
        src: Image source URL
        alt: Alt text
        placeholder: Placeholder image URL
        sizes: Responsive image sizes
        
    Returns:
        HTML string
    """
    if placeholder:
        style = f"background-image: url('{placeholder}'); background-size: cover;"
    else:
        style = "background: #f0f0f0;"
    
    sizes_attr = f'sizes="{sizes}"' if sizes else ''
    
    return f"""
    <img 
        src="{placeholder or 'data:image/svg+xml,%3Csvg xmlns=\\'http://www.w3.org/2000/svg\\' viewBox=\\'0 0 400 300\\'%3E%3C/svg%3E'}"
        data-src="{src}"
        alt="{alt}"
        loading="lazy"
        {sizes_attr}
        style="{style}"
        onload="this.classList.add('loaded')"
    >
    """

def generate_lazy_script() -> str:
    """Generate JavaScript for lazy loading with Intersection Observer"""
    return """
    <script>
    // Lazy load images
    (function() {
        const images = document.querySelectorAll('img[data-src]');
        
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        img.src = img.dataset.src;
                        img.classList.add('loaded');
                        imageObserver.unobserve(img);
                    }
                });
            }, {
                rootMargin: '50px'
            });
            
            images.forEach(img => imageObserver.observe(img));
        } else {
            // Fallback for older browsers
            images.forEach(img => {
                img.src = img.dataset.src;
                img.classList.add('loaded');
            });
        }
    })();
    
    // Lazy load scripts
    function lazyLoadScript(src) {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = src;
            script.defer = true;
            script.onload = resolve;
            script.onerror = reject;
            document.body.appendChild(script);
        });
    }
    </script>
    """

def generate_preload_tags(resources: List[Dict[str, str]]) -> str:
    """
    Generate preload/prefetch link tags
    
    Args:
        resources: List of dicts with 'href', 'as', 'type' (optional), 'rel' (default: preload)
        
    Returns:
        HTML string with link tags
    """
    tags = []
    for resource in resources:
        rel = resource.get('rel', 'preload')
        href = resource['href']
        as_type = resource.get('as', '')
        resource_type = resource.get('type', '')
        
        tag = f'<link rel="{rel}" href="{href}"'
        if as_type:
            tag += f' as="{as_type}"'
        if resource_type:
            tag += f' type="{resource_type}"'
        if rel == 'preconnect':
            tag += ' crossorigin'
        tag += '>'
        
        tags.append(tag)
    
    return '\n'.join(tags)







