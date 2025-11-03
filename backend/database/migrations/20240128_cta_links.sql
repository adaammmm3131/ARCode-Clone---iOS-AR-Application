-- Migration: CTA Links Table
-- Date: 2024-01-28

CREATE TABLE IF NOT EXISTS cta_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ar_code_id UUID NOT NULL REFERENCES ar_codes(id) ON DELETE CASCADE,
    button_text VARCHAR(255) NOT NULL,
    button_style VARCHAR(50) NOT NULL DEFAULT 'primary',
    destination_url TEXT NOT NULL,
    destination_type VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL DEFAULT 'bottom_center',
    is_enabled BOOLEAN DEFAULT TRUE,
    analytics_id UUID, -- Pour A/B testing
    variant VARCHAR(10), -- 'A', 'B', 'C', etc.
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_cta_links_ar_code_id ON cta_links(ar_code_id);
CREATE INDEX idx_cta_links_analytics_id ON cta_links(analytics_id);
CREATE INDEX idx_cta_links_enabled ON cta_links(is_enabled) WHERE is_enabled = TRUE;

-- A/B Tests Table
CREATE TABLE IF NOT EXISTS ab_tests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ar_code_id UUID NOT NULL REFERENCES ar_codes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    variants JSONB NOT NULL, -- Array of variant objects
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    winner_variant_id VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ab_tests_ar_code_id ON ab_tests(ar_code_id);
CREATE INDEX idx_ab_tests_active ON ab_tests(is_active) WHERE is_active = TRUE;

-- A/B Test Results Table
CREATE TABLE IF NOT EXISTS ab_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_id UUID NOT NULL REFERENCES ab_tests(id) ON DELETE CASCADE,
    variant_id VARCHAR(10) NOT NULL,
    clicks INT DEFAULT 0,
    conversions INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ab_test_results_test_id ON ab_test_results(test_id);
CREATE INDEX idx_ab_test_results_variant_id ON ab_test_results(variant_id);







