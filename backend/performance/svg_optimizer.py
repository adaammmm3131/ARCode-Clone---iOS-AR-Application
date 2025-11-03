#!/usr/bin/env python3
"""
SVG Optimization
Minify, remove unnecessary elements, optimize paths
"""

import re
from typing import Optional, str
import logging

logger = logging.getLogger(__name__)

def optimize_svg(svg_content: str) -> str:
    """
    Optimize SVG content
    
    Args:
        svg_content: Original SVG string
        
    Returns:
        Optimized SVG string
    """
    optimized = svg_content
    
    # Remove comments
    optimized = re.sub(r'<!--.*?-->', '', optimized, flags=re.DOTALL)
    
    # Remove unnecessary whitespace
    optimized = re.sub(r'\s+', ' ', optimized)
    optimized = re.sub(r'>\s+<', '><', optimized)
    
    # Remove default attributes
    optimized = re.sub(r'\s+fill="black"', '', optimized)
    optimized = re.sub(r'\s+stroke="none"', '', optimized)
    
    # Optimize paths (basic)
    # Remove unnecessary spaces in paths
    optimized = re.sub(r'([MmLlHhVvCcSsQqTtAaZz])\s+', r'\1 ', optimized)
    
    # Remove leading/trailing whitespace
    optimized = optimized.strip()
    
    return optimized

def minify_svg_path(path_data: str) -> str:
    """
    Minify SVG path data
    
    Args:
        path_data: SVG path data string
        
    Returns:
        Minified path data
    """
    # Remove unnecessary spaces
    minified = re.sub(r'\s+', ' ', path_data)
    minified = re.sub(r'([MmLlHhVvCcSsQqTtAaZz])\s+', r'\1', minified)
    minified = re.sub(r'\s+([MmLlHhVvCcSsQqTtAaZz])', r'\1', minified)
    
    return minified.strip()

def validate_svg(svg_content: str) -> bool:
    """
    Basic SVG validation
    
    Args:
        svg_content: SVG content to validate
        
    Returns:
        True if valid SVG
    """
    # Check for basic SVG structure
    if not svg_content.strip().startswith('<svg'):
        return False
    
    if '</svg>' not in svg_content:
        return False
    
    return True







