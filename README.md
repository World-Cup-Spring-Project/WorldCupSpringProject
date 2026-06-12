# XXX - Sistema de Microsserviços para Operações da Copa do Mundo

![Java](https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white)
![Apache Kafka](https://img.shields.io/badge/Apache_Kafka-231F20?style=for-the-badge&logo=apache-kafka&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![Spring Cloud](https://img.shields.io/badge/Spring_Cloud-6DB33F?style=for-the-badge&logo=spring&logoColor=white)

O **XXX** é um ecossistema de software distribuído, de alta escalabilidade e orientado a eventos, projetado para gerenciar a criticidade operacional, volumetria massiva e alta volatilidade transacional de um evento de magnitude global: a Copa do Mundo da FIFA.

A arquitetura adota uma abordagem de **Persistência Poliglota** e **Event-Driven Architecture (EDA)** utilizando microsserviços especializados. Isso garante que picos massivos de tráfego (como a abertura de bilheterias ou atualizações de golos em tempo real) sejam absorvidos sem causar degradação ou indisponibilidade no ecossistema.

---

## 🛠️ Pilha Tecnológica Global (Stack)

* **Core Framework:** Java (Spring Boot)
* **Persistência Relacional:** Spring Data JPA (PostgreSQL)
* **Persistência Não-Relacional:** Spring Data MongoDB (MongoDB)
* **Cache & Travas Distribuídas:** Redis
* **Mensageria & Eventos:** Apache Kafka
* **Service Discovery:** Netflix Eureka Server (Spring Cloud)
* **Roteamento & Segurança Periférica:** API Gateway / Load Balancer
* **Comunicação Síncrona:** API REST via Spring `RestClient` (Spring 6.1+)

---

## 🗂️ Arquitetura e Divisão de Domínios

O ecossistema é segmentado em 7 microsserviços isolados por contexto e banco de dados:

### 1. `ms-core-data` (Núcleo de Dados Centralizado)
* **Responsabilidade:** Atua como fonte centralizada de dados mestres estáveis e imutáveis compartilhados por múltiplos contextos (dados estruturais de estádios, federações, seleções oficiais e delegações).
* **Tecnologias:** Java Spring Boot, Spring Data JPA, PostgreSQL, API REST.

### 2. `ms-tickets` (Vendas e Reserva de Ingressos)
* **Responsabilidade:** Componente de maior pressão transacional. Processa ordens de compra concorrentes e implementa mecanismos de travas no Redis para mitigar problemas de consistência e evitar a venda duplicada do mesmo assento (*double-booking*).
* **Tecnologias:** Java Spring Boot, Spring Data JPA, Redis (Distributed Locks), Apache Kafka, API Gateway.

### 3. `ms-matches` (Gestão de Partidas e Placar Oficial)
* **Responsabilidade:** Consome dados ao vivo de telemetria esportiva de uma API externa via `RestClient` do Spring. Mantém e propaga o estado ativo dos jogos (golos, cartões, substituições) de forma fluida e reativa.
* **Tecnologias:** Java Spring Boot, Spring Data MongoDB, MongoDB, Redis, Apache Kafka.

### 4. `ms-access-control` (Controle de Catracas e Acesso)
* **Responsabilidade:** Validação em milissegundos de QR Codes de ingressos nas catracas dos estádios. Implementa resiliência de rede para permitir operação local isolada (*fallback*) caso perca a conectividade com a base central.
* **Tecnologias:** Java Spring Boot, Spring Data JPA, Apache Kafka, Load Balancer.

### 5. `ms-engagement` (Gamification e Votação)
* **Responsabilidade:** Processamento massivo de votações populares concentradas nos minutos finais de cada partida (ex: escolha do "Craque do Jogo") utilizando estruturas em memória para evitar gargalos.
* **Tecnologias:** Java Spring Boot, Redis (Sorted Sets), Apache Kafka.

### 6. `ms-logistics` (Gestão de Delegações e Transporte)
* **Responsabilidade:** Orquestração de regras de negócio complexas para agendamento de recursos (hotéis, campos de treino e frotas de transporte), aplicando o padrão Saga para transações distribuídas.
* **Tecnologias:** Java Spring Boot, Spring Data JPA, Apache Kafka.

### 7. `ms-analytics` (Consolidador Financeiro e Ocupação)
* **Responsabilidade:** Componente estritamente reativo. Consome streams de dados contínuos do Kafka gerados pelas catracas e bilheterias para consolidar dashboards de faturamento e taxa de ocupação por setor em tempo real.
* **Tecnologias:** Java Spring Boot, Spring Data JPA, Apache Kafka.

---

## 💾 Modelagem de Dados & Persistência Poliglota

### Relacional (PostgreSQL)
Aplicado em cenários de conformidade ACID rígida e integridade referencial forte (cadastro base em `ms-core-data`, checkout financeiro em `ms-tickets` e controle de agendas em `ms-logistics`).

### Não-Relacional (MongoDB)
O `ms-matches` adota o MongoDB para persistir a linha do tempo das partidas de forma desnormalizada, absorvendo as mudanças de esquema dos payloads JSON recebidos da API externa de dados em tempo real.
