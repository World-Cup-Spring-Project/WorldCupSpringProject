SET search_path TO core_data;

CREATE TABLE IF NOT EXISTS sync_metadata (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    last_sync_at TIMESTAMPTZ NOT NULL,
    last_sync_source VARCHAR(32) NOT NULL,
    teams_count INT NOT NULL,
    stadiums_count INT NOT NULL,
    groups_count INT NOT NULL,
    games_count INT NOT NULL
);
