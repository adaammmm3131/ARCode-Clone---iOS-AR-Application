-- Migration: White Label Configuration
-- Date: 2024-01-28

CREATE TABLE IF NOT EXISTS white_label_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    settings JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_white_label_configs_user_id ON white_label_configs(user_id);
CREATE INDEX idx_white_label_configs_active ON white_label_configs(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_white_label_configs_domain ON white_label_configs((settings->>'custom_domain')) WHERE settings->>'custom_domain' IS NOT NULL;

-- Email Templates Custom Table
CREATE TABLE IF NOT EXISTS email_templates_custom (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_type VARCHAR(50) NOT NULL, -- welcome, processing, weekly_stats, etc.
    subject VARCHAR(255) NOT NULL,
    html_content TEXT NOT NULL,
    text_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_email_templates_user_id ON email_templates_custom(user_id);
CREATE INDEX idx_email_templates_type ON email_templates_custom(template_type);







