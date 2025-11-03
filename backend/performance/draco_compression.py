#!/usr/bin/env python3
"""
Draco Compression for 3D Models
GLB mesh compression using Draco
"""

import os
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

def compress_glb_with_draco(
    input_path: str,
    output_path: str,
    compression_level: int = 6,
    quantization_bits: Dict[str, int] = None
) -> Dict[str, Any]:
    """
    Compress GLB file with Draco compression
    
    Args:
        input_path: Input GLB file path
        output_path: Output GLB file path
        compression_level: Compression level (0-10, higher = better compression)
        quantization_bits: Quantization bits for positions, normals, texcoords
        
    Returns:
        Dict with compression results
    """
    if quantization_bits is None:
        quantization_bits = {
            'position': 14,
            'normal': 10,
            'texcoord': 12
        }
    
    try:
        # Use gltf-pipeline or gltf-transform for Draco compression
        # gltf-pipeline command:
        cmd = [
            'gltf-pipeline',
            '-i', input_path,
            '-o', output_path,
            '--draco.compressionLevel', str(compression_level),
            '--draco.quantizePositionBits', str(quantization_bits['position']),
            '--draco.quantizeNormalBits', str(quantization_bits['normal']),
            '--draco.quantizeTexcoordBits', str(quantization_bits['texcoord'])
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600  # 10 minutes max
        )
        
        if result.returncode == 0:
            original_size = Path(input_path).stat().st_size
            compressed_size = Path(output_path).stat().st_size
            compression_ratio = (1 - compressed_size / original_size) * 100
            
            logger.info(f"Draco compression: {compression_ratio:.1f}% reduction")
            
            return {
                'success': True,
                'original_size': original_size,
                'compressed_size': compressed_size,
                'compression_ratio': compression_ratio,
                'output_path': output_path
            }
        else:
            logger.error(f"Draco compression failed: {result.stderr}")
            return {
                'success': False,
                'error': result.stderr
            }
    
    except FileNotFoundError:
        logger.warning("gltf-pipeline not found, trying Blender method")
        return compress_with_blender(input_path, output_path, compression_level)
    except Exception as e:
        logger.error(f"Error compressing with Draco: {e}")
        return {
            'success': False,
            'error': str(e)
        }

def compress_with_blender(
    input_path: str,
    output_path: str,
    compression_level: int = 6
) -> Dict[str, Any]:
    """
    Compress GLB using Blender (alternative method)
    
    Args:
        input_path: Input GLB file
        output_path: Output GLB file
        compression_level: Compression level
        
    Returns:
        Compression results
    """
    try:
        # Blender script for Draco compression
        script = f"""
import bpy
import sys

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import GLB
bpy.ops.import_scene.gltf(filepath='{input_path}')

# Export with Draco compression
bpy.ops.export_scene.gltf(
    filepath='{output_path}',
    export_format='GLB',
    export_draco_mesh_compression_enable=True,
    export_draco_mesh_compression_level={compression_level},
    export_draco_position_quantization=14,
    export_draco_normal_quantization=10,
    export_draco_texcoord_quantization=12
)
"""
        
        script_path = Path('/tmp/draco_compress.py')
        script_path.write_text(script)
        
        cmd = [
            'blender',
            '--background',
            '--python', str(script_path)
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=600
        )
        
        if result.returncode == 0 and Path(output_path).exists():
            original_size = Path(input_path).stat().st_size
            compressed_size = Path(output_path).stat().st_size
            compression_ratio = (1 - compressed_size / original_size) * 100
            
            return {
                'success': True,
                'original_size': original_size,
                'compressed_size': compressed_size,
                'compression_ratio': compression_ratio
            }
        
        return {
            'success': False,
            'error': 'Blender compression failed'
        }
    
    except Exception as e:
        logger.error(f"Error with Blender compression: {e}")
        return {
            'success': False,
            'error': str(e)
        }







