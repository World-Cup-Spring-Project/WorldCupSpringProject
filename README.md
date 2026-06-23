# ArenaCup - Plataforma de Microservicos para Copa do Mundo

Projeto academico baseado em uma arquitetura de microservicos para organizar dados, jogos, ingressos, engajamento, logistica e metricas de uma competicao de futebol. A aplicacao usa Spring Boot, Docker Compose, Eureka, API Gateway, Kafka, Redis, PostgreSQL e MongoDB.

## Objetivo do projeto

O objetivo do ArenaCup e simular uma plataforma distribuida para uma Copa do Mundo, onde cada microservico tem uma responsabilidade propria:

- centralizar dados oficiais de selecoes, estadios, grupos e jogos;
- controlar partidas e status dos jogos;
- vender, consultar, transferir e cancelar ingressos;
- publicar eventos de compra e cancelamento em Kafka;
- consumir eventos para gerar metricas no `ms-analytics`;
- permitir votacoes e engajamento dos usuarios;
- controlar fluxos logisticos de delegacoes, hoteis, treinos e transporte;
- expor tudo por um unico ponto de entrada, o `api-gateway`.

## Servicos do projeto

| Servico | Responsabilidade | Banco / recurso principal | Rota pelo gateway |
| --- | --- | --- | --- |
| `api-gateway` | Entrada unica da aplicacao e roteamento para os micros | Eureka | `http://localhost:9999` |
| `eureka` | Service discovery dos microservicos | Registro Eureka | `http://localhost:8761` |
| `auth-service` | Cadastro, login e consulta do usuario autenticado | PostgreSQL | `/auth/**` |
| `ms-core-data` | Dados base da Copa: selecoes, estadios, grupos e jogos | PostgreSQL + API externa | `/api/core/**` |
| `ms-matches` | Sincronizacao e controle das partidas | MongoDB + Kafka | `/api/matches/**` |
| `ms-tickets` | Compra, consulta, transferencia e cancelamento de ingressos | PostgreSQL + Redis + Kafka | `/api/tickets/**` |
| `ms-analytics` | Metricas de vendas, cancelamentos, receita, ocupacao e publico | PostgreSQL + Kafka | `/api/analytics/**` |
| `ms-engagement` | Votacao e ranking de jogadores por partida | Redis + Kafka | `/api/engagement/**` |
| `ms-logistics` | Delegacoes, hoteis, locais de treino, transporte e saga logistica | PostgreSQL + Kafka | `/api/logistics/**` |

## Infraestrutura

O `docker-compose.yml` principal fica em:

```text
WorldCupSpringProject/docker-compose.yml
```

Ele sobe os servicos da aplicacao e tambem a infraestrutura:

- `postgres`: banco relacional principal, exposto em `localhost:5433`;
- `mongo`: banco usado pelo `ms-matches`, exposto em `localhost:27017`;
- `redis`: cache e controle rapido de estado, exposto em `localhost:6379`;
- `kafka`: mensageria entre micros, exposto em `localhost:29092`;
- `kafka-ui`: interface para ver topicos Kafka, em `http://localhost:8085`;
- `zipkin`: rastreamento distribuido, em `http://localhost:9411`;
- `eureka`: descoberta dos servicos, em `http://localhost:8761`.

## Como executar

Entre na pasta do compose principal:

```powershell
cd C:\Users\guilh\Documents\springtest\WorldCupSpringProject
```

Suba todos os containers:

```powershell
docker compose up -d --build
```

Veja se todos ficaram saudaveis:

```powershell
docker compose ps
```

Para acompanhar logs de um servico especifico:

```powershell
docker compose logs -f ms-analytics
```

Para derrubar o ambiente sem apagar os dados:

```powershell
docker compose down
```

Para derrubar e apagar os volumes de banco, limpando os dados:

```powershell
docker compose down -v
```

## Fluxo principal da aplicacao

### 1. Carga de dados da Copa

O `ms-core-data` e o microservico responsavel pelos dados base da competicao. Ele trabalha com selecoes, estadios, grupos e jogos.

Quando o ambiente sobe, ele tenta sincronizar os dados com a API externa configurada em `WORLDCUP_API_URL`. Se a API externa estiver indisponivel, o servico pode usar os dados ja existentes no banco ou dados locais de seed, dependendo das configuracoes de fallback.

Exemplos de consulta pelo gateway:

```http
GET http://localhost:9999/api/core/teams
GET http://localhost:9999/api/core/stadiums
GET http://localhost:9999/api/core/games
GET http://localhost:9999/api/core/groups
```

### 2. Sincronizacao de partidas

O `ms-matches` consulta o `ms-core-data` para montar e manter as partidas no seu proprio banco MongoDB. Ele tambem publica eventos Kafka quando o status de uma partida muda.

Exemplos:

```http
GET  http://localhost:9999/api/matches
POST http://localhost:9999/api/matches/sync
PATCH http://localhost:9999/api/matches/{id}/status
```

### 3. Compra de ingresso

O fluxo de compra passa pelo `api-gateway` e chega no `ms-tickets`.

Fluxo resumido:

1. O cliente chama `POST /api/tickets/buy`.
2. O `ms-tickets` valida o jogo e o estadio no `ms-core-data`.
3. O `ms-tickets` usa Redis para evitar conflito de assento.
4. O ingresso e salvo no PostgreSQL.
5. Um evento e publicado no Kafka no topico `ticket-issued-events`.
6. O `ms-analytics` consome esse evento e atualiza as metricas de vendas.

Exemplo:

```http
POST http://localhost:9999/api/tickets/buy
```

```json
{
  "matchId": "29",
  "stadiumId": "10",
  "seatCode": "SETOR-A-001",
  "customerDocument": "12345678900",
  "price": 250.00
}
```

### 4. Cancelamento de ingresso

O cancelamento tambem passa pelo `ms-tickets`.

Fluxo resumido:

1. O cliente chama `DELETE /api/tickets/{id}/cancel`.
2. O `ms-tickets` marca o ingresso como cancelado.
3. O assento pode ser liberado no Redis.
4. Um evento e publicado no Kafka no topico `ticket-cancelled-events`.
5. O `ms-analytics` consome o evento e atualiza as metricas de cancelamento.

Exemplo:

```http
DELETE http://localhost:9999/api/tickets/1/cancel
```

### 5. Analytics

O `ms-analytics` nao calcula as metricas inventando dados. Ele depende dos eventos reais de compra e cancelamento publicados pelo `ms-tickets`.

Principais consultas:

| Nome para usar no Postman | URL |
| --- | --- |
| Resumo geral das metricas | `GET http://localhost:9999/api/analytics/summary` |
| Receita por setor | `GET http://localhost:9999/api/analytics/revenue-by-sector` |
| Ocupacao por setor | `GET http://localhost:9999/api/analytics/occupancy-by-sector` |
| Jogos ou estadios mais lucrativos | `GET http://localhost:9999/api/analytics/top-profitable-games` |
| Taxa de cancelamento | `GET http://localhost:9999/api/analytics/cancellation-rate` |
| Selecao com maior publico | `GET http://localhost:9999/api/analytics/top-attendance-team` |

Observacao importante: atualmente o setor vem do codigo do assento informado na compra. Por exemplo, em `SETOR-A-001`, o agrupamento usa a parte do setor enviada no `seatCode`. Ja a taxa de ocupacao pode aparecer como `0` quando nao existe capacidade real de setor cadastrada para calcular percentual.

### 6. Engajamento

O `ms-engagement` trabalha com votacoes por partida, ranking e janela de votacao. Ele se integra ao `ms-matches` e usa Redis para armazenar dados rapidos de votacao.

Exemplos:

```http
POST http://localhost:9999/api/engagement/matches/{matchId}/votes
GET  http://localhost:9999/api/engagement/matches/{matchId}/ranking
GET  http://localhost:9999/api/engagement/matches/{matchId}/window
```

### 7. Logistica

O `ms-logistics` organiza recursos logisticos, como delegacoes, hoteis, locais de treino e transporte. Ele tambem possui um fluxo de saga para reservar um pacote completo de logistica.

Exemplos:

```http
GET  http://localhost:9999/api/logistics/delegations
GET  http://localhost:9999/api/logistics/hotels
GET  http://localhost:9999/api/logistics/training-venues
GET  http://localhost:9999/api/logistics/transport/assets
POST http://localhost:9999/api/logistics/logistics/full-package
```

## Principais topicos Kafka

| Topico | Quem publica | Quem consome | Finalidade |
| --- | --- | --- | --- |
| `ticket-issued-events` | `ms-tickets` | `ms-analytics` | Registrar venda de ingresso |
| `ticket-cancelled-events` | `ms-tickets` | `ms-analytics` | Registrar cancelamento de ingresso |
| `match-status-changed-events` | `ms-matches` | `ms-engagement` | Abrir/fechar janelas de votacao |
| `man-of-the-match-chosen-events` | `ms-engagement` | Outros micros interessados | Resultado de votacao |
| `logistics-*-events` | `ms-logistics` | Micros interessados | Eventos do fluxo logistico |

## URLs uteis

| Ferramenta | URL |
| --- | --- |
| API Gateway | `http://localhost:9999` |
| Eureka | `http://localhost:8761` |
| Kafka UI | `http://localhost:8085` |
| Zipkin | `http://localhost:9411` |
| ms-core-data direto | `http://localhost:8081` |
| PostgreSQL | `localhost:5433` |
| MongoDB | `localhost:27017` |
| Redis | `localhost:6379` |

## Tecnologias utilizadas

- Java 21;
- Spring Boot;
- Spring Cloud Gateway;
- Eureka Server e Eureka Client;
- Spring Data JPA;
- Spring Data MongoDB;
- Spring Data Redis;
- Apache Kafka;
- PostgreSQL;
- MongoDB;
- Redis;
- Docker e Docker Compose;
- Zipkin para rastreamento distribuido;
- Resilience4j para retry e circuit breaker;
- Actuator para health checks.

