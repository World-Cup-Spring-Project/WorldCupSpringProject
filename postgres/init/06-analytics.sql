SET search_path TO analytics;

CREATE TABLE IF NOT EXISTS revenue_snapshots (
    id BIGSERIAL PRIMARY KEY,
    stadium_id VARCHAR(32) NOT NULL,
    sector VARCHAR(32) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    ticket_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (stadium_id, sector)
);

CREATE TABLE IF NOT EXISTS occupancy_snapshots (
    id BIGSERIAL PRIMARY KEY,
    stadium_id VARCHAR(32) NOT NULL,
    validated_count INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (stadium_id)
);

CREATE TABLE IF NOT EXISTS engagement_snapshots (
    id BIGSERIAL PRIMARY KEY,
    match_id VARCHAR(32) NOT NULL UNIQUE,
    player_id VARCHAR(64) NOT NULL,
    total_votes INT NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
