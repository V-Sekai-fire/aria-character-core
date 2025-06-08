# Aria System Data Persistence Service

## Overview

The System Data Persistence Service provides robust, distributed persistence for structured system data, including operational entities, schemas, configurations, and transactional records using CockroachDB.

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