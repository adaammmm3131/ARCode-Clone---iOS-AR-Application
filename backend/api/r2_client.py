#!/usr/bin/env python3
"""
Cloudflare R2 Storage Client
S3-compatible API pour upload/download assets
"""

import boto3
import os
from botocore.config import Config
from botocore.exceptions import ClientError
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# Configuration S3-compatible pour R2
r2_config = Config(
    signature_version='s3v4',
    region_name='auto'
)

# Client R2
r2_client = boto3.client(
    's3',
    endpoint_url=os.getenv('R2_ENDPOINT_URL'),
    aws_access_key_id=os.getenv('R2_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('R2_SECRET_ACCESS_KEY'),
    config=r2_config
)

BUCKET_NAME = os.getenv('R2_BUCKET_NAME', 'ar-code-assets')
PUBLIC_URL = os.getenv('R2_PUBLIC_URL')

def upload_file(
    file_data: bytes,
    key: str,
    content_type: str,
    metadata: Optional[Dict[str, str]] = None
) -> str:
    """
    Upload file to R2
    
    Args:
        file_data: File bytes
        key: S3 key (path)
        content_type: MIME type
        metadata: Optional metadata dict
        
    Returns:
        Public URL of uploaded file
    """
    try:
        extra_args = {
            'ContentType': content_type,
            'ACL': 'public-read'
        }
        
        if metadata:
            extra_args['Metadata'] = metadata
        
        r2_client.put_object(
            Bucket=BUCKET_NAME,
            Key=key,
            Body=file_data,
            **extra_args
        )
        
        # Retourner URL publique
        return f"{PUBLIC_URL}/{key}"
    
    except ClientError as e:
        logger.error(f"R2 upload error: {e}")
        raise

def download_file(key: str) -> Optional[bytes]:
    """
    Download file from R2
    
    Args:
        key: S3 key (path)
        
    Returns:
        File bytes or None if not found
    """
    try:
        response = r2_client.get_object(
            Bucket=BUCKET_NAME,
            Key=key
        )
        return response['Body'].read()
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchKey':
            return None
        logger.error(f"R2 download error: {e}")
        raise

def delete_file(key: str) -> bool:
    """
    Delete file from R2
    
    Args:
        key: S3 key (path)
        
    Returns:
        True if successful
    """
    try:
        r2_client.delete_object(
            Bucket=BUCKET_NAME,
            Key=key
        )
        return True
    
    except ClientError as e:
        logger.error(f"R2 delete error: {e}")
        return False

def generate_presigned_url(
    key: str,
    expiration: int = 3600,
    method: str = 'put_object'
) -> str:
    """
    Generate presigned URL for upload/download
    
    Args:
        key: S3 key (path)
        expiration: URL expiration in seconds
        method: 'put_object' or 'get_object'
        
    Returns:
        Presigned URL
    """
    try:
        url = r2_client.generate_presigned_url(
            method,
            Params={
                'Bucket': BUCKET_NAME,
                'Key': key
            },
            ExpiresIn=expiration
        )
        return url
    
    except ClientError as e:
        logger.error(f"R2 presigned URL error: {e}")
        raise

def file_exists(key: str) -> bool:
    """
    Check if file exists in R2
    
    Args:
        key: S3 key (path)
        
    Returns:
        True if file exists
    """
    try:
        r2_client.head_object(
            Bucket=BUCKET_NAME,
            Key=key
        )
        return True
    
    except ClientError:
        return False

def list_files(prefix: str = '', max_keys: int = 1000) -> list:
    """
    List files in R2 bucket
    
    Args:
        prefix: Prefix to filter
        max_keys: Maximum number of keys
        
    Returns:
        List of file keys
    """
    try:
        response = r2_client.list_objects_v2(
            Bucket=BUCKET_NAME,
            Prefix=prefix,
            MaxKeys=max_keys
        )
        
        if 'Contents' in response:
            return [obj['Key'] for obj in response['Contents']]
        return []
    
    except ClientError as e:
        logger.error(f"R2 list error: {e}")
        return []









