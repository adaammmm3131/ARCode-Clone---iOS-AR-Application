#!/usr/bin/env python3
"""
Image Optimization
WebP, AVIF conversion, responsive images
"""

import os
from PIL import Image
import io
from typing import Tuple, Optional, Dict
import logging

logger = logging.getLogger(__name__)

def convert_to_webp(
    image_data: bytes,
    quality: int = 80,
    max_size: Optional[Tuple[int, int]] = None
) -> bytes:
    """
    Convert image to WebP format
    
    Args:
        image_data: Original image bytes
        quality: Compression quality (0-100)
        max_size: Max dimensions (width, height)
        
    Returns:
        WebP image bytes
    """
    try:
        img = Image.open(io.BytesIO(image_data))
        
        # Convert RGBA to RGB if necessary (WebP supports both)
        if img.mode == 'RGBA':
            # Keep alpha channel
            pass
        elif img.mode not in ('RGB', 'RGBA'):
            img = img.convert('RGB')
        
        # Resize if max_size specified
        if max_size:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        output = io.BytesIO()
        img.save(output, format='WEBP', quality=quality, method=6)
        
        return output.getvalue()
    
    except Exception as e:
        logger.error(f"Error converting to WebP: {e}")
        raise

def convert_to_avif(
    image_data: bytes,
    quality: int = 80,
    max_size: Optional[Tuple[int, int]] = None
) -> bytes:
    """
    Convert image to AVIF format
    
    Args:
        image_data: Original image bytes
        quality: Compression quality (0-100)
        max_size: Max dimensions (width, height)
        
    Returns:
        AVIF image bytes
    """
    try:
        img = Image.open(io.BytesIO(image_data))
        
        if img.mode == 'RGBA':
            pass  # AVIF supports alpha
        elif img.mode not in ('RGB', 'RGBA'):
            img = img.convert('RGB')
        
        if max_size:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        output = io.BytesIO()
        
        # Try AVIF (requires pillow-avif-plugin)
        try:
            img.save(output, format='AVIF', quality=quality)
        except Exception:
            # Fallback to WebP if AVIF not available
            logger.warning("AVIF not available, using WebP fallback")
            img.save(output, format='WEBP', quality=quality)
        
        return output.getvalue()
    
    except Exception as e:
        logger.error(f"Error converting to AVIF: {e}")
        raise

def generate_responsive_images(
    image_data: bytes,
    sizes: Dict[str, Tuple[int, int]] = None
) -> Dict[str, bytes]:
    """
    Generate multiple sizes for responsive images
    
    Args:
        image_data: Original image bytes
        sizes: Dict of name -> (width, height) tuples
        
    Returns:
        Dict of name -> optimized image bytes
    """
    if sizes is None:
        sizes = {
            'thumbnail': (150, 150),
            'small': (400, 400),
            'medium': (800, 800),
            'large': (1200, 1200)
        }
    
    results = {}
    original = Image.open(io.BytesIO(image_data))
    
    for name, size in sizes.items():
        try:
            img = original.copy()
            img.thumbnail(size, Image.Resampling.LANCZOS)
            
            output = io.BytesIO()
            img.save(output, format='JPEG', quality=85, optimize=True)
            results[name] = output.getvalue()
        
        except Exception as e:
            logger.error(f"Error generating {name} size: {e}")
    
    return results

def optimize_image(
    image_data: bytes,
    format: str = 'webp',
    quality: int = 80,
    max_size: Optional[Tuple[int, int]] = None
) -> bytes:
    """
    Optimize image (convert format, resize, compress)
    
    Args:
        image_data: Original image bytes
        format: Target format ('webp', 'avif', 'jpeg')
        quality: Compression quality (0-100)
        max_size: Max dimensions
        
    Returns:
        Optimized image bytes
    """
    if format.lower() == 'webp':
        return convert_to_webp(image_data, quality, max_size)
    elif format.lower() == 'avif':
        return convert_to_avif(image_data, quality, max_size)
    elif format.lower() in ('jpg', 'jpeg'):
        img = Image.open(io.BytesIO(image_data))
        if max_size:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        output = io.BytesIO()
        if img.mode == 'RGBA':
            img = img.convert('RGB')
        img.save(output, format='JPEG', quality=quality, optimize=True)
        return output.getvalue()
    else:
        raise ValueError(f"Unsupported format: {format}")







