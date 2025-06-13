# Aria Queue Service

## Overview

The Queue Service manages asynchronous service requests and background jobs, ensuring reliable and scalable task execution using Oban with CockroachDB as the persistent backend.

## System Role

**Boot Order:** Core Services Layer (Boot Second)
**Dependencies:** `aria_data` (Oban persistence), `aria_security` (DB credentials)
**External Systems:** Oban

## Purpose

To serve as the 'Director of Flow,' patiently and orderly managing tasks to prevent overwhelm and ensure every request is addressed, fostering resilience and fairness in processing.

## Key Responsibilities

- Hold and manage queues for service requests and data components awaiting processing
- Ensure resilient and scalable background job processing
- Provide job scheduling, retry logic, and failure handling
- Support multiple queue types for different service priorities
- Integrate with the System Data Persistence Service for job persistence and state management

## Core Technologies

- **Oban**: Elixir background job processing library
- **CockroachDB**: Persistent backend for job storage (via System Data Persistence Service)
- **Telemetry**: Job monitoring and metrics

## Service Type

Stateful (leveraging persistent backend via System Data Persistence Service)

## Key Interactions

- **Security Service**: Obtains credentials for secure operation
- **Authentication Service**: Validates service identity and authorization for all queue operations
- **System Data Persistence Service**: For job persistence and state management
- **Coordinate Service**: For request retries and managing job submission
- **All Aria Services**: Manage asynchronous tasks and background processing

## Queue Types

- **ai_generation**: Character generation and AI inference jobs
- **planning**: Engine service planning and decision-making tasks
- **storage_sync**: CDN synchronization and asset management
- **monitoring**: System health checks and metric collection