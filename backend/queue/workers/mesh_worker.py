#!/usr/bin/env python3
"""
Mesh Optimization Worker
Worker pour mesh cleanup avec Blender headless
"""

import os
import sys
from pathlib import Path
from typing import Dict, Any
import logging
import subprocess
from job_tracker import update_job_status
from job_models import JobStatus
from rq import get_current_job

logger = logging.getLogger(__name__)

def process_mesh_optimization_job(
    job_id: str,
    mesh_path: str,
    user_id: str,
    lod_levels: list = ['high', 'medium', 'low']
) -> Dict[str, Any]:
    """
    Process mesh optimization avec Blender
    
    Args:
        job_id: Job ID
        mesh_path: Path to input mesh (GLB/USDZ)
        user_id: User ID
        lod_levels: LOD levels to generate
        
    Returns:
        Result dict with optimized mesh URLs
    """
    current_job = get_current_job()
    
    try:
        update_job_status(job_id, JobStatus.PROCESSING, progress=0)
        
        workspace = Path(f"/tmp/mesh/processing/{job_id}")
        workspace.mkdir(parents=True, exist_ok=True)
        
        output_urls = {}
        
        # Process each LOD level
        for i, lod_level in enumerate(lod_levels):
            progress_start = (i / len(lod_levels)) * 90
            progress_end = ((i + 1) / len(lod_levels)) * 90
            
            update_job_status(
                job_id,
                JobStatus.PROCESSING,
                progress=int(progress_start)
            )
            
            # Blender script path
            script_path = workspace / f"optimize_{lod_level}.py"
            
            # Generate Blender Python script
            generate_blender_script(script_path, mesh_path, lod_level)
            
            # Run Blender headless
            output_path = workspace / f"model_{lod_level}.glb"
            
            blender_cmd = [
                'blender',
                '--background',
                '--python', str(script_path),
                '--', str(mesh_path), str(output_path), lod_level
            ]
            
            subprocess.run(blender_cmd, check=True, capture_output=True)
            
            # Upload to R2
            from api.r2_client import upload_file
            
            with open(output_path, 'rb') as f:
                mesh_data = f.read()
                key = f"models/{user_id}/{job_id}/model_{lod_level}.glb"
                url = upload_file(mesh_data, key, 'model/gltf-binary')
                output_urls[f'{lod_level}_url'] = url
            
            update_job_status(
                job_id,
                JobStatus.PROCESSING,
                progress=int(progress_end)
            )
        
        # Upload final optimized mesh
        update_job_status(job_id, JobStatus.PROCESSING, progress=95)
        
        update_job_status(
            job_id,
            JobStatus.COMPLETED,
            progress=100,
            output_url=output_urls.get('high_url')
        )
        
        return {
            'success': True,
            'output_urls': output_urls,
            'job_id': job_id
        }
    
    except Exception as e:
        logger.error(f"Error processing mesh optimization job {job_id}: {e}")
        update_job_status(
            job_id,
            JobStatus.FAILED,
            progress=0,
            error_message=str(e)
        )
        raise

def generate_blender_script(script_path: Path, input_path: str, lod_level: str):
    """Generate Blender Python script for mesh optimization"""
    
    # Decimation ratios par LOD
    decimation_ratios = {
        'high': 0.5,
        'medium': 0.2,
        'low': 0.1
    }
    
    ratio = decimation_ratios.get(lod_level, 0.5)
    
    script_content = f"""
import bpy
import sys

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import mesh
input_path = sys.argv[4]
bpy.ops.import_scene.gltf(filepath=input_path)

# Decimate mesh
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
        mod.decimate_type = 'COLLAPSE'
        mod.ratio = {ratio}
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="Decimate")

# Export
output_path = sys.argv[5]
bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format='GLB',
    use_selection=False
)
"""
    
    script_path.write_text(script_content)









