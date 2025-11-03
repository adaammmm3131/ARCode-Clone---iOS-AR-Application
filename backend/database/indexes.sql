-- Additional Indexes for Performance Optimization

-- Composite indexes for common queries
CREATE INDEX idx_ar_codes_user_type ON ar_codes(user_id, type);
CREATE INDEX idx_ar_codes_public_created ON ar_codes(is_public, created_at DESC) WHERE is_public = TRUE;

-- Partial indexes for active records
CREATE INDEX idx_ar_codes_active ON ar_codes(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_processing_jobs_active ON processing_jobs(status, created_at DESC) WHERE status IN ('pending', 'processing');

-- Full text search indexes (if needed)
-- CREATE INDEX idx_ar_codes_title_search ON ar_codes USING gin(to_tsvector('english', title));
-- CREATE INDEX idx_ar_codes_description_search ON ar_codes USING gin(to_tsvector('english', description));

-- Time-based indexes for analytics
CREATE INDEX idx_analytics_created_type ON analytics_events(created_at DESC, event_type);
CREATE INDEX idx_analytics_date_range ON analytics_events USING btree(date_trunc('day', created_at));

-- Foreign key indexes (already created in schema.sql, but ensuring coverage)
CREATE INDEX idx_assets_ar_code_user ON assets(ar_code_id, user_id);
CREATE INDEX idx_processing_jobs_user_status ON processing_jobs(user_id, status);

-- JSONB path indexes
CREATE INDEX idx_ar_codes_metadata_type ON ar_codes((metadata->>'category')) WHERE metadata ? 'category';

-- Analyze tables after index creation
ANALYZE users;
ANALYZE ar_codes;
ANALYZE assets;
ANALYZE analytics_events;
ANALYZE processing_jobs;









