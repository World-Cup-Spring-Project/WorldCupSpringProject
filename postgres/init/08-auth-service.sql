SET search_path TO auth_service;

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO usuarios (id, nome, email, senha_hash, ativo, criado_em)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Fan Demo',
    'fan@arenacup.com',
    '123456',
    TRUE,
    NOW()
)
ON CONFLICT (email) DO NOTHING;
