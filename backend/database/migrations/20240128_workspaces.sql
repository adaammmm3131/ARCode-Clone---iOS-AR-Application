-- Migration: Workspaces and Collaboration
-- Date: 2024-01-28

-- Workspaces Table
CREATE TABLE IF NOT EXISTS workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workspaces_owner_id ON workspaces(owner_id);

-- Workspace Members Table
CREATE TABLE IF NOT EXISTS workspace_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'viewer', -- owner, admin, editor, viewer
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_by UUID REFERENCES users(id),
    UNIQUE(workspace_id, user_id)
);

CREATE INDEX idx_workspace_members_workspace_id ON workspace_members(workspace_id);
CREATE INDEX idx_workspace_members_user_id ON workspace_members(user_id);
CREATE INDEX idx_workspace_members_role ON workspace_members(role);

-- Workspace Comments Table
CREATE TABLE IF NOT EXISTS workspace_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    ar_code_id UUID REFERENCES ar_codes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_workspace_comments_workspace_id ON workspace_comments(workspace_id);
CREATE INDEX idx_workspace_comments_ar_code_id ON workspace_comments(ar_code_id);
CREATE INDEX idx_workspace_comments_user_id ON workspace_comments(user_id);
CREATE INDEX idx_workspace_comments_resolved ON workspace_comments(is_resolved) WHERE is_resolved = FALSE;

-- AR Code Versions Table
CREATE TABLE IF NOT EXISTS ar_code_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ar_code_id UUID NOT NULL REFERENCES ar_codes(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    asset_url TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_by UUID NOT NULL REFERENCES users(id),
    changelog TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ar_code_id, version_number)
);

CREATE INDEX idx_ar_code_versions_ar_code_id ON ar_code_versions(ar_code_id);
CREATE INDEX idx_ar_code_versions_version_number ON ar_code_versions(version_number);

-- Add workspace_id to ar_codes table
ALTER TABLE ar_codes ADD COLUMN IF NOT EXISTS workspace_id UUID REFERENCES workspaces(id) ON DELETE SET NULL;
CREATE INDEX idx_ar_codes_workspace_id ON ar_codes(workspace_id);







