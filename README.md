# ArenaCup OS — WorldCupSpringProject

Repositório central da stack ArenaCup: **Eureka**, **API Gateway**, **docker-compose**, init do Postgres e scripts de build.

## Escopo (6 repositórios)

| Pasta | Papel |
|-------|--------|
| `WorldCupSpringProject/` | Eureka, Gateway, compose, postgres/init |
| `../ms-core-data/` | Dados mestres (worldcup26.ir) |
| `../ms-tickets/` | Ingressos + Kafka producer |
| `../ms-matches/` | Partidas (MongoDB) |
| `../ms-engagement/` | Votação Craque do Jogo |
| `../ms-analytics/` | Analytics (`ticket-issued-events`) |

## Arquitetura

```mermaid
flowchart LR
  Client[Cliente / demo.http] --> GW[api-gateway :9999]
  GW -->|lb://| Eureka[Eureka :8761]
  Eureka --> Core[ms-core-data]
  Eureka --> Tickets[ms-tickets]
  Eureka --> Matches[ms-matches]
  Eureka --> Engagement[ms-engagement]
  Eureka --> Analytics[ms-analytics]
  Tickets -->|ticket-issued-events| Kafka[(Kafka)]
  Matches -->|match-status-changed| Kafka
  Kafka --> Engagement
  Kafka --> Analytics
  Tickets -->|REST| Core
  Analytics -->|REST| Core
  Analytics -->|REST| Matches
```

## Subir a stack

```powershell
cd code/WorldCupSpringProject
docker compose up --build
```

Primeira execução: ~2–3 min até todos os healthchecks ficarem verdes.

Para banco limpo (recria schemas init):

```powershell
docker compose down -v
docker compose up --build
```

## URLs

| Serviço | URL |
|---------|-----|
| API Gateway | http://localhost:9999 |
| Eureka | http://localhost:8761 |
| **Zipkin** (tracing) | http://localhost:9411 |
| Kafka UI | http://localhost:8085 |
| PostgreSQL | localhost:5433 (`arenacup` / `arenacup` / `arenacup`) |

## Rotas do Gateway

| Prefixo | Destino Eureka |
|---------|----------------|
| `/api/core/**` | `lb://ms-core-data` |
| `/api/matches/**` | `lb://ms-matches` |
| `/api/tickets/**` | `lb://ms-tickets` |
| `/api/engagement/**` | `lb://ms-engagement` |
| `/api/analytics/**` | `lb://ms-analytics` |

StripPrefix=2 — ex.: `GET /api/core/teams/MEX` → `ms-core-data/teams/MEX`.

## Build local (opcional)

```powershell
.\build-all.ps1
```

Requer JDK 21. Os Dockerfiles fazem build multi-stage sem Maven local.

## Demo E2E

`../arenacup-demo.http` — ingresso → analytics → partida → votação.

## Seed do PostgreSQL (a cada subida dos containers)

Os scripts em `postgres/init/` rodam **apenas na primeira criação do volume**. Para repopular em todo `docker compose up`, o compose habilita:

| Serviço | Variável | Efeito |
|---------|----------|--------|
| `ms-core-data` | `POSTGRES_SEED_ON_STARTUP=true` | Aplica `seed_core_data.sql` (times, estádios, jogos) antes do sync da API |
| `ms-analytics` | `ANALYTICS_SEED_ON_STARTUP=true` | Limpa e recria métricas demo no schema `analytics` |

Falhas no seed ou na API externa **não derrubam** os microsserviços: o startup registra `WARN` e o serviço sobe com dados locais (quando existirem).

Após subir: `GET http://localhost:9999/api/analytics/summary` já retorna dados.

## Observabilidade (Zipkin)

Tracing distribuído via **Micrometer + Brave** — sem microsserviço novo; container `zipkin` no compose.

1. Execute o fluxo do `arenacup-demo.http`
2. Abra http://localhost:9411 e busque por service name (`api-gateway`, `ms-tickets`, etc.)
3. Logs dos containers incluem `traceId`/`spanId` para correlacionar com o Zipkin

Variáveis (já no compose):

| Variável | Valor Docker |
|----------|--------------|
| `ZIPKIN_ENDPOINT` | `http://zipkin:9411/api/v2/spans` |
| `TRACING_SAMPLING_PROBABILITY` | `1.0` (100% em dev) |

## Estrutura

```
WorldCupSpringProject/
├── docker-compose.yml
├── build-all.ps1
├── eureka/
├── gateway/
└── postgres/init/
    ├── 01-schemas.sql
    ├── 02-core-data-tables.sql
    ├── 03-tickets.sql
    ├── 06-analytics.sql
    └── 07-core-data-sync-metadata.sql
```

## Seed core-data (manual)

Snapshots em `../ms-core-data/postgres/seed/` — não rodam no `docker up`. Ver README do ms-core-data.
