CREATE TABLE IF NOT EXISTS scans (
    id UUID PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    image_url TEXT NOT NULL,
    explanation TEXT,
    asset_3d_url TEXT,
    confidence FLOAT DEFAULT 0.0,
    subject_topic VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scans_user_id ON scans(user_id);
CREATE INDEX IF NOT EXISTS idx_scans_subject_topic ON scans(subject_topic);
