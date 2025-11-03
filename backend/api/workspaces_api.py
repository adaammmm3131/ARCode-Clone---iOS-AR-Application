#!/usr/bin/env python3
"""
Workspaces API
Endpoints pour gestion des workspaces, membres, comments, version history
"""

from flask import Blueprint, request, jsonify
from auth_supabase import require_auth
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import json
import uuid
from datetime import datetime
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

workspaces_bp = Blueprint('workspaces', __name__)

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'arcode'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD', '')
    )

@workspaces_bp.route('/api/v1/workspaces', methods=['GET'])
@require_auth
def get_workspaces(user: Dict):
    """Get all workspaces for current user"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        user_id = user.get('sub')
        
        cursor.execute("""
            SELECT w.id, w.name, w.description, w.owner_id, w.settings, w.created_at, w.updated_at
            FROM workspaces w
            INNER JOIN workspace_members wm ON w.id = wm.workspace_id
            WHERE wm.user_id = %s
            ORDER BY w.created_at DESC
        """, (user_id,))
        
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        workspaces = []
        for row in rows:
            workspaces.append({
                'id': str(row[0]),
                'name': row[1],
                'description': row[2],
                'owner_id': str(row[3]),
                'settings': row[4] if row[4] else {},
                'created_at': row[5].isoformat() if row[5] else None,
                'updated_at': row[6].isoformat() if row[6] else None
            })
        
        return jsonify(workspaces), 200
    
    except Exception as e:
        logger.error(f"Error getting workspaces: {e}")
        return jsonify({'error': 'Failed to get workspaces'}), 500

@workspaces_bp.route('/api/v1/workspaces', methods=['POST'])
@require_auth
def create_workspace(user: Dict):
    """Create a new workspace"""
    try:
        data = request.get_json()
        name = data.get('name')
        description = data.get('description')
        user_id = user.get('sub')
        
        if not name:
            return jsonify({'error': 'Missing name'}), 400
        
        workspace_id = str(uuid.uuid4())
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create workspace
        cursor.execute("""
            INSERT INTO workspaces (
                id, name, description, owner_id, settings, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, '{}'::jsonb, NOW(), NOW())
            RETURNING id, created_at, updated_at
        """, (workspace_id, name, description, user_id))
        
        result = cursor.fetchone()
        
        # Add owner as member with owner role
        member_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO workspace_members (
                id, workspace_id, user_id, role, joined_at, invited_by
            ) VALUES (%s, %s, %s, 'owner', NOW(), %s)
        """, (member_id, workspace_id, user_id, user_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'name': name,
            'description': description,
            'owner_id': user_id,
            'settings': {},
            'created_at': result[1].isoformat(),
            'updated_at': result[2].isoformat()
        }), 201
    
    except Exception as e:
        logger.error(f"Error creating workspace: {e}")
        return jsonify({'error': 'Failed to create workspace'}), 500

@workspaces_bp.route('/api/v1/workspaces/<workspace_id>', methods=['GET'])
@require_auth
def get_workspace(user: Dict, workspace_id: str):
    """Get workspace details"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, name, description, owner_id, settings, created_at, updated_at
            FROM workspaces
            WHERE id = %s
        """, (workspace_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return jsonify({'error': 'Workspace not found'}), 404
        
        return jsonify({
            'id': str(row[0]),
            'name': row[1],
            'description': row[2],
            'owner_id': str(row[3]),
            'settings': row[4] if row[4] else {},
            'created_at': row[5].isoformat() if row[5] else None,
            'updated_at': row[6].isoformat() if row[6] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting workspace: {e}")
        return jsonify({'error': 'Failed to get workspace'}), 500

@workspaces_bp.route('/api/v1/workspaces/<workspace_id>/members', methods=['GET'])
@require_auth
def get_workspace_members(user: Dict, workspace_id: str):
    """Get workspace members"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, workspace_id, user_id, role, joined_at, invited_by
            FROM workspace_members
            WHERE workspace_id = %s
            ORDER BY joined_at
        """, (workspace_id,))
        
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        members = []
        for row in rows:
            members.append({
                'id': str(row[0]),
                'workspace_id': str(row[1]),
                'user_id': str(row[2]),
                'role': row[3],
                'joined_at': row[4].isoformat() if row[4] else None,
                'invited_by': str(row[5]) if row[5] else None
            })
        
        return jsonify(members), 200
    
    except Exception as e:
        logger.error(f"Error getting workspace members: {e}")
        return jsonify({'error': 'Failed to get workspace members'}), 500

@workspaces_bp.route('/api/v1/workspaces/<workspace_id>/members/invite', methods=['POST'])
@require_auth
def invite_member(user: Dict, workspace_id: str):
    """Invite a member to workspace"""
    try:
        data = request.get_json()
        email = data.get('email')
        role = data.get('role', 'viewer')
        
        if not email:
            return jsonify({'error': 'Missing email'}), 400
        
        # TODO: Send invitation email
        # For now, create member record (assuming user exists)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get user ID from email (simplified - in production, query users table)
        # For now, create placeholder
        member_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())  # Would be fetched from users table
        
        cursor.execute("""
            INSERT INTO workspace_members (
                id, workspace_id, user_id, role, joined_at, invited_by
            ) VALUES (%s, %s, %s, %s, NOW(), %s)
            RETURNING id, joined_at
        """, (member_id, workspace_id, user_id, role, user.get('sub')))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'workspace_id': workspace_id,
            'user_id': user_id,
            'role': role,
            'joined_at': result[1].isoformat(),
            'invited_by': user.get('sub')
        }), 201
    
    except Exception as e:
        logger.error(f"Error inviting member: {e}")
        return jsonify({'error': 'Failed to invite member'}), 500

@workspaces_bp.route('/api/v1/workspaces/comments', methods=['POST'])
@require_auth
def create_comment(user: Dict):
    """Create a comment"""
    try:
        data = request.get_json()
        workspace_id = data.get('workspace_id')
        ar_code_id = data.get('ar_code_id')
        content = data.get('content')
        
        if not all([workspace_id, content]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        comment_id = str(uuid.uuid4())
        user_id = user.get('sub')
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO workspace_comments (
                id, workspace_id, ar_code_id, user_id, content, created_at, updated_at, is_resolved
            ) VALUES (%s, %s, %s, %s, %s, NOW(), NOW(), FALSE)
            RETURNING id, created_at, updated_at
        """, (comment_id, workspace_id, ar_code_id, user_id, content))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'workspace_id': workspace_id,
            'ar_code_id': ar_code_id,
            'user_id': user_id,
            'content': content,
            'created_at': result[1].isoformat(),
            'updated_at': result[2].isoformat(),
            'is_resolved': False
        }), 201
    
    except Exception as e:
        logger.error(f"Error creating comment: {e}")
        return jsonify({'error': 'Failed to create comment'}), 500

@workspaces_bp.route('/api/v1/ar-codes/<ar_code_id>/versions', methods=['GET'])
@require_auth
def get_ar_code_versions(user: Dict, ar_code_id: str):
    """Get version history for AR Code"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, ar_code_id, version_number, asset_url, metadata,
                   created_by, created_at, changelog
            FROM ar_code_versions
            WHERE ar_code_id = %s
            ORDER BY version_number DESC
        """, (ar_code_id,))
        
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        versions = []
        for row in rows:
            versions.append({
                'id': str(row[0]),
                'ar_code_id': str(row[1]),
                'version_number': row[2],
                'asset_url': row[3],
                'metadata': row[4] if row[4] else {},
                'created_by': str(row[5]),
                'created_at': row[6].isoformat() if row[6] else None,
                'changelog': row[7]
            })
        
        return jsonify(versions), 200
    
    except Exception as e:
        logger.error(f"Error getting versions: {e}")
        return jsonify({'error': 'Failed to get versions'}), 500







