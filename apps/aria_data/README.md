# Aria System Data Persistence Service

## Overview

The System Data Persistence Service provides robust, distributed persistence for structured system data, including operational entities, schemas, configurations, and transactional records using CockroachDB.

## System Role

**Boot Order:** Foundation Layer (Boot First)
**Dependencies:** `aria_security` (for DB credentials)
**External Systems:** CockroachDB 22.1 (or PostgreSQL)

## Purpose

To act as the 'Living Library,' lovingly organizing and caring for the system's structured knowledge and operational data, ensuring fast access and strong consistency for critical system functions.

## Key Responsibilities

- Store and retrieve structured data objects, schemas, Standard Operating Procedures (SOPs), and system configurations
- Provide ACID transactions and strong consistency for critical operational data
- Manage database schemas, migrations, and data modeling through Ecto
- Handle real-time queries and analytics for system operations
- Support vector embeddings and similarity search through CockroachDB's vector extension
- Provide JSON storage for semi-structured configuration and metadata

## Core Technologies

- **PostgreSQL**: Primary development database (Ecto.Adapters.Postgres)
- **CockroachDB**: Production-ready distributed SQL database (PostgreSQL-compatible)
- **Ecto**: Database ORM and query builder for Elixir
- **CockroachDB Vector Extension**: For embedding vectors and similarity search
- **Postgrex**: PostgreSQL driver for Elixir

## Technology Choices

- **CockroachDB 22.1**: This service will utilize CockroachDB version 22.1. This specific version is chosen for its stability, feature set, distributed SQL capabilities, data resilience, and horizontal scalability, which are critical for system data persistence.
  - Download: <https://buildomat.eng.oxide.computer/public/file/oxidecomputer/cockroach/linux-amd64/865aff1595e494c2ce95030c7a2f20c4370b5ff8/cockroach.tgz>

## Service Type

Stateful

## Key Interactions

- **Security Service**: Obtains credentials for secure database access
- **Authentication Service**: Validates service identity and authorization for all data operations
- **Workflow Service**: Stores SOP definitions and execution state
- **Queue Service**: Provides persistent backend for Oban job storage
- **Monitor Service**: Stores metrics and system state data for analysis
- **Debugger Service & Tune Service**: Persists configurations and learned parameters
- **All Aria Services**: Central data persistence layer for the entire system