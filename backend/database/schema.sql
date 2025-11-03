-- ARCode Database Schema
-- PostgreSQL 14+

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (synced with Supabase Auth)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supabase_id UUID UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100),
    full_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    -- GDPR Consent fields
    consent_analytics BOOLEAN DEFAULT FALSE,
    consent_marketing BOOLEAN DEFAULT FALSE,
    consent_cookies BOOLEAN DEFAULT FALSE,
    consent_updated_at TIMESTAMP WITH TIME ZONE,
    -- Email Notification Preferences
    email_notifications_processing BOOLEAN DEFAULT TRUE,
    email_notifications_scans BOOLEAN DEFAULT FALSE,
    email_notifications_weekly_stats BOOLEAN DEFAULT TRUE,
    email_notifications_marketing BOOLEAN DEFAULT FALSE
);

-- AR Codes table
CREATE TABLE ar_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- object_capture, face_filter, ai_code, etc.
    qr_code_url TEXT NOT NULL,
    asset_url TEXT,
    thumbnail_url TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Assets table
CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ar_code_id UUID REFERENCES ar_codes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- model_3d, video, image, splat
    format VARCHAR(20), -- glb, usdz, mp4, jpg, ply
    url TEXT NOT NULL,
    size_bytes BIGINT,
    width INTEGER,
    height INTEGER,
    duration_seconds INTEGER, -- pour vidéos
    lod_level VARCHAR(20), -- high, medium, low
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics events table
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ar_code_id UUID REFERENCES ar_codes(id) ON DELETE SET NULL,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- qr_scan, placement, interaction, screenshot, conversion
    event_data JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    user_agent TEXT,
    device_type VARCHAR(50), -- ios, android, web
    browser VARCHAR(100),
    location_country VARCHAR(2),
    location_city VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Processing jobs table
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES assets(id) ON DELETE SET NULL,
    job_type VARCHAR(50) NOT NULL, -- photogrammetry, gaussian_splatting, ai_generation
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    progress INTEGER DEFAULT 0, -- 0-100
    input_url TEXT,
    output_url TEXT,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Webhooks table
CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ar_code_id UUID REFERENCES ar_codes(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    events TEXT[] NOT NULL, -- ['ar_code.created', 'scanned', etc.]
    secret TEXT NOT NULL, -- pour signature validation
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Webhook deliveries table
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL, -- pending, success, failed
    status_code INTEGER,
    response_body TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_ar_codes_user_id ON ar_codes(user_id);
CREATE INDEX idx_ar_codes_type ON ar_codes(type);
CREATE INDEX idx_ar_codes_created_at ON ar_codes(created_at DESC);
CREATE INDEX idx_ar_codes_public ON ar_codes(is_public) WHERE is_public = TRUE;

CREATE INDEX idx_assets_ar_code_id ON assets(ar_code_id);
CREATE INDEX idx_assets_user_id ON assets(user_id);
CREATE INDEX idx_assets_type ON assets(type);

CREATE INDEX idx_analytics_ar_code_id ON analytics_events(ar_code_id);
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at DESC);
CREATE INDEX idx_analytics_location ON analytics_events(location_country, location_city);

-- Analytics daily stats aggregation table
CREATE TABLE IF NOT EXISTS analytics_daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    ar_code_id UUID REFERENCES ar_codes(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    count INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    unique_sessions INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(date, ar_code_id, event_type)
);

CREATE INDEX idx_daily_stats_date ON analytics_daily_stats(date DESC);
CREATE INDEX idx_daily_stats_ar_code_id ON analytics_daily_stats(ar_code_id);
CREATE INDEX idx_daily_stats_event_type ON analytics_daily_stats(event_type);

CREATE INDEX idx_processing_jobs_user_id ON processing_jobs(user_id);
CREATE INDEX idx_processing_jobs_status ON processing_jobs(status);
CREATE INDEX idx_processing_jobs_job_type ON processing_jobs(job_type);

CREATE INDEX idx_webhooks_user_id ON webhooks(user_id);
CREATE INDEX idx_webhooks_ar_code_id ON webhooks(ar_code_id);
CREATE INDEX idx_webhooks_active ON webhooks(is_active) WHERE is_active = TRUE;

CREATE INDEX idx_webhook_deliveries_webhook_id ON webhook_deliveries(webhook_id);
CREATE INDEX idx_webhook_deliveries_status ON webhook_deliveries(status);
CREATE INDEX idx_webhook_deliveries_created_at ON webhook_deliveries(created_at DESC);

-- JSONB indexes
CREATE INDEX idx_ar_codes_metadata ON ar_codes USING GIN(metadata);
CREATE INDEX idx_analytics_event_data ON analytics_events USING GIN(event_data);

-- Updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ar_codes_updated_at BEFORE UPDATE ON ar_codes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_processing_jobs_updated_at BEFORE UPDATE ON processing_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

