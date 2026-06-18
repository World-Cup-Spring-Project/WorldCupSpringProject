SET search_path TO tickets;

CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(36) PRIMARY KEY,
    stadium_id VARCHAR(32) NOT NULL,
    buyer_email VARCHAR(120) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tickets (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL REFERENCES orders(id),
    stadium_id VARCHAR(32) NOT NULL,
    sector VARCHAR(32) NOT NULL,
    seat VARCHAR(16) NOT NULL,
    qr_code VARCHAR(64) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (stadium_id, sector, seat)
);
