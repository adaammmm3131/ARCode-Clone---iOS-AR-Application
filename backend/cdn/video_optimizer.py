#!/usr/bin/env python3
"""
Video Optimization
H.265/H.264 compression, adaptive bitrate streaming
"""

import os
import subprocess
from pathlib import Path
from typing import List, Tuple, Optional, Dict
import logging

logger = logging.getLogger(__name__)

def compress_video(
    input_path: str,
    output_path: str,
    codec: str = 'libx264',  # libx264 or libx265
    crf: int = 23,  # 18-28 for H.264, 28-32 for H.265
    preset: str = 'medium'  # ultrafast, fast, medium, slow, veryslow
) -> bool:
    """
    Compress video with H.264 or H.265
    
    Args:
        input_path: Input video path
        output_path: Output video path
        codec: Video codec (libx264 or libx265)
        crf: Constant Rate Factor (lower = better quality)
        preset: Encoding preset
        
    Returns:
        True if successful
    """
    try:
        cmd = [
            'ffmpeg', '-i', input_path,
            '-c:v', codec,
            '-crf', str(crf),
            '-preset', preset,
            '-c:a', 'aac',
            '-b:a', '128k',
            '-movflags', '+faststart',  # For web playback
            '-y',  # Overwrite output
            output_path
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=3600  # 1 hour max
        )
        
        if result.returncode == 0:
            logger.info(f"Video compressed: {output_path}")
            return True
        else:
            logger.error(f"FFmpeg error: {result.stderr}")
            return False
    
    except subprocess.TimeoutExpired:
        logger.error("Video compression timeout")
        return False
    except Exception as e:
        logger.error(f"Error compressing video: {e}")
        return False

def generate_hls_streams(
    input_path: str,
    output_dir: str,
    qualities: List[Tuple[str, str, str]] = None
) -> List[str]:
    """
    Generate HLS adaptive bitrate streams
    
    Args:
        input_path: Input video path
        output_dir: Output directory for HLS files
        qualities: List of (name, resolution, bitrate) tuples
        
    Returns:
        List of generated .m3u8 playlist paths
    """
    if qualities is None:
        qualities = [
            ('1080p', '1920:1080', '5000k'),
            ('720p', '1280:720', '2500k'),
            ('480p', '854:480', '1000k'),
            ('360p', '640:360', '500k')
        ]
    
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    playlist_paths = []
    
    for name, resolution, bitrate in qualities:
        try:
            output_m3u8 = f"{output_dir}/{name}.m3u8"
            output_ts_dir = f"{output_dir}/{name}_segments"
            Path(output_ts_dir).mkdir(exist_ok=True)
            
            cmd = [
                'ffmpeg', '-i', input_path,
                '-c:v', 'libx264',
                '-s', resolution,
                '-b:v', bitrate,
                '-maxrate', bitrate,
                '-bufsize', f'{int(bitrate[:-1]) * 2}k',
                '-c:a', 'aac',
                '-b:a', '128k',
                '-hls_time', '10',
                '-hls_playlist_type', 'vod',
                '-hls_segment_filename', f'{output_ts_dir}/segment_%03d.ts',
                output_m3u8
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=3600
            )
            
            if result.returncode == 0:
                playlist_paths.append(output_m3u8)
                logger.info(f"HLS stream generated: {name}")
            else:
                logger.error(f"HLS generation error for {name}: {result.stderr}")
        
        except Exception as e:
            logger.error(f"Error generating HLS {name}: {e}")
    
    # Generate master playlist
    if playlist_paths:
        master_playlist = generate_master_playlist(playlist_paths, output_dir)
        playlist_paths.insert(0, master_playlist)
    
    return playlist_paths

def generate_master_playlist(
    playlist_paths: List[str],
    output_dir: str
) -> str:
    """Generate HLS master playlist (.m3u8)"""
    master_path = f"{output_dir}/master.m3u8"
    
    with open(master_path, 'w') as f:
        f.write("#EXTM3U\n")
        f.write("#EXT-X-VERSION:3\n\n")
        
        bandwidth_map = {
            '1080p': 5000000,
            '720p': 2500000,
            '480p': 1000000,
            '360p': 500000
        }
        
        for playlist in playlist_paths:
            name = Path(playlist).stem
            bandwidth = bandwidth_map.get(name, 1000000)
            
            f.write(f"#EXT-X-STREAM-INF:BANDWIDTH={bandwidth},RESOLUTION={get_resolution(name)}\n")
            f.write(f"{Path(playlist).name}\n\n")
    
    return master_path

def get_resolution(name: str) -> str:
    """Get resolution string from quality name"""
    resolutions = {
        '1080p': '1920x1080',
        '720p': '1280x720',
        '480p': '854x480',
        '360p': '640x360'
    }
    return resolutions.get(name, '1280x720')







