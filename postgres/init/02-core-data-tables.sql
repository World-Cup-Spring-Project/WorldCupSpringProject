SET search_path TO core_data;

-- Colunas em camelCase, iguais aos JSON expostos pelo ms-core-data (REST).
-- Dados: sync da API worldcup26.ir ou seed manual em ms-core-data/postgres/seed/

CREATE TABLE IF NOT EXISTS teams (
    id VARCHAR(16) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    federation VARCHAR(80) NOT NULL,
    "groupLetter" VARCHAR(4),
    "flagUrl" VARCHAR(255),
    "worldcupId" VARCHAR(16) NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS teams_worldcup_id_idx ON teams ("worldcupId");

CREATE TABLE IF NOT EXISTS stadiums (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    city VARCHAR(120) NOT NULL,
    capacity INT NOT NULL DEFAULT 0,
    country VARCHAR(80)
);

CREATE TABLE IF NOT EXISTS groups (
    id VARCHAR(8) PRIMARY KEY,
    teams TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS games (
    id VARCHAR(16) PRIMARY KEY,
    "homeTeamId" VARCHAR(16),
    "awayTeamId" VARCHAR(16),
    "homeScore" INT NOT NULL DEFAULT 0,
    "awayScore" INT NOT NULL DEFAULT 0,
    "groupName" VARCHAR(16) NOT NULL,
    matchday VARCHAR(8),
    "stadiumId" VARCHAR(32),
    finished BOOLEAN NOT NULL DEFAULT FALSE,
    "timeElapsed" VARCHAR(32),
    type VARCHAR(16),
    "localDate" VARCHAR(32),
    "homeTeamLabel" VARCHAR(120),
    "awayTeamLabel" VARCHAR(120),
    "homeTeamName" VARCHAR(120),
    "awayTeamName" VARCHAR(120)
);
