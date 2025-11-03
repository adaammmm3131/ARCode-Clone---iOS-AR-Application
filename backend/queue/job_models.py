#!/usr/bin/env python3
"""
Job Models et Types
Modèles pour jobs de traitement
"""

from enum import Enum
from dataclasses import dataclass
from typing import Optional, Dict, Any
from datetime import datetime

class JobType(str, Enum):
    PHOTOGRAMMETRY = "photogrammetry"
    GAUSSIAN_SPLATTING = "gaussian_splatting"
    AI_VISION = "ai_vision"
    AI_GENERATION = "ai_generation"
    MESH_OPTIMIZATION = "mesh_optimization"
    FORMAT_CONVERSION = "format_conversion"

class JobStatus(str, Enum):
    PENDING = "pending"
    QUEUED = "queued"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RETRYING = "retrying"

class JobPriority(str, Enum):
    HIGH = "high"
    DEFAULT = "default"
    LOW = "low"

@dataclass
class ProcessingJob:
    """Modèle pour job de traitement"""
    job_id: str
    job_type: JobType
    user_id: str
    asset_id: Optional[str] = None
    input_url: Optional[str] = None
    output_url: Optional[str] = None
    status: JobStatus = JobStatus.PENDING
    progress: int = 0
    priority: JobPriority = JobPriority.DEFAULT
    retry_count: int = 0
    max_retries: int = 3
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = None
    created_at: datetime = None
    updated_at: datetime = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}
        if self.created_at is None:
            self.created_at = datetime.utcnow()
        if self.updated_at is None:
            self.updated_at = datetime.utcnow()

@dataclass
class JobProgress:
    """Modèle pour progression d'un job"""
    job_id: str
    stage: str
    progress: int  # 0-100
    message: str
    timestamp: datetime









