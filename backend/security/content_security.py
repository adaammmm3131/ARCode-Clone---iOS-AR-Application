#!/usr/bin/env python3
"""
Content Security
Virus scanning (ClamAV), file validation, size limits, content moderation
"""

import os
import subprocess
import magic
import hashlib
from typing import Optional, Tuple, Dict, Any
from pathlib import Path
import logging
from PIL import Image
import mimetypes

logger = logging.getLogger(__name__)

# Configuration
MAX_FILE_SIZE = int(os.getenv('MAX_FILE_SIZE', str(250 * 1024 * 1024)))  # 250MB
ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif']
ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/quicktime', 'video/x-msvideo']
ALLOWED_3D_TYPES = ['model/gltf-binary', 'model/gltf+json', 'application/octet-stream']  # GLB, USDZ
CLAMAV_ENABLED = os.getenv('CLAMAV_ENABLED', 'true').lower() == 'true'
CLAMAV_SOCKET = os.getenv('CLAMAV_SOCKET', '/var/run/clamav/clamd.ctl')

def scan_file_with_clamav(file_path: str) -> Tuple[bool, Optional[str]]:
    """
    Scan file with ClamAV
    
    Args:
        file_path: Path to file to scan
        
    Returns:
        (is_safe, virus_name)
    """
    if not CLAMAV_ENABLED:
        logger.info("ClamAV disabled, skipping scan")
        return True, None
    
    try:
        result = subprocess.run(
            ['clamdscan', '--no-summary', '--fdpass', file_path],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode == 0:
            return True, None  # Clean
        else:
            # Extract virus name from output
            virus_name = result.stdout.strip() if result.stdout else 'Unknown'
            logger.warning(f"Virus detected: {virus_name}")
            return False, virus_name
    
    except subprocess.TimeoutExpired:
        logger.error("ClamAV scan timeout")
        return False, 'Scan timeout'
    except FileNotFoundError:
        logger.warning("ClamAV not installed, skipping scan")
        return True, None
    except Exception as e:
        logger.error(f"ClamAV scan error: {e}")
        return False, str(e)

def validate_file_type(file_path: str, expected_type: str = None) -> Tuple[bool, Optional[str]]:
    """
    Validate file type
    
    Args:
        file_path: Path to file
        expected_type: Expected type category ('image', 'video', '3d', None for any)
        
    Returns:
        (is_valid, mime_type)
    """
    try:
        # Detect MIME type
        mime = magic.Magic(mime=True)
        mime_type = mime.from_file(file_path)
        
        if expected_type == 'image':
            if mime_type not in ALLOWED_IMAGE_TYPES:
                return False, mime_type
        elif expected_type == 'video':
            if mime_type not in ALLOWED_VIDEO_TYPES:
                return False, mime_type
        elif expected_type == '3d':
            # Check extension for 3D files (GLB, USDZ)
            ext = Path(file_path).suffix.lower()
            if ext in ['.glb', '.usdz', '.ply']:
                return True, mime_type
            return False, mime_type
        
        return True, mime_type
    
    except Exception as e:
        logger.error(f"File type validation error: {e}")
        return False, None

def validate_file_size(file_path: str) -> Tuple[bool, int]:
    """
    Validate file size
    
    Args:
        file_path: Path to file
        
    Returns:
        (is_valid, file_size_bytes)
    """
    try:
        size = os.path.getsize(file_path)
        return size <= MAX_FILE_SIZE, size
    
    except Exception as e:
        logger.error(f"File size validation error: {e}")
        return False, 0

def validate_image_dimensions(file_path: str, max_width: int = 4096, max_height: int = 4096) -> bool:
    """
    Validate image dimensions
    
    Args:
        file_path: Path to image file
        max_width: Maximum width in pixels
        max_height: Maximum height in pixels
        
    Returns:
        True if dimensions are valid
    """
    try:
        with Image.open(file_path) as img:
            width, height = img.size
            return width <= max_width and height <= max_height
    
    except Exception as e:
        logger.error(f"Image dimension validation error: {e}")
        return False

def calculate_file_hash(file_path: str) -> str:
    """
    Calculate SHA256 hash of file
    
    Args:
        file_path: Path to file
        
    Returns:
        SHA256 hash string
    """
    sha256 = hashlib.sha256()
    
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            sha256.update(chunk)
    
    return sha256.hexdigest()

def validate_upload(
    file_path: str,
    file_type: str = None,
    scan_virus: bool = True
) -> Dict[str, Any]:
    """
    Complete upload validation
    
    Args:
        file_path: Path to uploaded file
        file_type: Expected type category
        scan_virus: Whether to scan for viruses
        
    Returns:
        Validation result dict
    """
    result = {
        'valid': False,
        'errors': [],
        'mime_type': None,
        'file_size': 0,
        'file_hash': None
    }
    
    # Check file exists
    if not os.path.exists(file_path):
        result['errors'].append('File not found')
        return result
    
    # Validate file size
    size_valid, file_size = validate_file_size(file_path)
    result['file_size'] = file_size
    
    if not size_valid:
        result['errors'].append(f'File size exceeds limit ({MAX_FILE_SIZE / 1024 / 1024}MB)')
    
    # Validate file type
    type_valid, mime_type = validate_file_type(file_path, file_type)
    result['mime_type'] = mime_type
    
    if not type_valid:
        result['errors'].append(f'File type not allowed: {mime_type}')
    
    # Validate image dimensions (if image)
    if file_type == 'image' and mime_type in ALLOWED_IMAGE_TYPES:
        if not validate_image_dimensions(file_path):
            result['errors'].append('Image dimensions exceed limits (4096x4096)')
    
    # Virus scan
    if scan_virus:
        is_safe, virus_name = scan_file_with_clamav(file_path)
        if not is_safe:
            result['errors'].append(f'Virus detected: {virus_name}')
    
    # Calculate hash
    try:
        result['file_hash'] = calculate_file_hash(file_path)
    except Exception as e:
        logger.error(f"Hash calculation error: {e}")
    
    # Final validation
    result['valid'] = len(result['errors']) == 0
    
    return result







