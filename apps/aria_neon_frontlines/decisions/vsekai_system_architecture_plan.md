# V-Sekai System Architecture Plan

## Status: Proposed (Research Phase)

## Core Architectural Decisions

### Decision 1: Use PostgreSQL with TimescaleDB for persistence

**Rationale**: Provides robust ACID compliance, time-series optimization, and horizontal scalability for the V-Sekai platform.

### Decision 2: Implement three-layer architecture (Real-time, API, Persistence)

**Rationale**: Separates concerns to ensure real-time gameplay doesn't bottleneck database operations.

### Decision 3: Use Erlang/Elixir for real-time game server

**Rationale**: Erlang's lightweight processes enable massive concurrency for multiplayer interactions.

### Decision 4: Implement HTN+STN hybrid planning system

**Rationale**: Combines hierarchical task decomposition with temporal constraint solving for intelligent agent behavior.

### Decision 5: Focus on web-based text interface for Phase 4

**Rationale**: Provides accessible entry point for testing and using platform capabilities.

### Decision 6: Implement 3D domain simulation for Phase 5

**Rationale**: Enables realistic multi-agent interactions based on operational archetypes and operational modes.

## Architecture Overview

```mermaid
    graph TD
        subgraph "Real-Time Application Layer"
            Godot[Godot Clients]
            GameServer[ENet Game Server<br/>dragonhunt02/enet-godot<br/>Erlang Implementation]
        end

        subgraph "API Layer"
            API[aria_neon_frontlines REST API<br/>Elixir Phoenix]
        end

        subgraph "Unified Persistence Layer"
            PostgreSQL[PostgreSQL with TimescaleDB<br/>Ecto.Adapters.SQL<br/>Hypertables for Time-Series]
        end

        Godot -->|ENet Protocol (DTLS)| GameServer
        GameServer -->|API Calls| API
        API -->|SQL Transactions| PostgreSQL
```

## Current Implementation Status

**✅ COMPLETED**: Phoenix web framework with WebSocket support
**✅ COMPLETED**: HTN+STN temporal planning system
**✅ COMPLETED**: PostgreSQL with TimescaleDB migration
**🧪 EXPERIMENTAL**: ENet game server integration

## Detailed Architecture Implementation

### Real-Time Layer Implementation

**Decision**: Use Erlang/Elixir with dragonhunt02/enet-godot for game server

- Erlang port of ENet protocol for Godot Engine compatibility
- Direct ENet protocol communication between server and clients
- Lightweight processes for massive concurrency
- Dedicated processes per world instance
- In-memory state synchronization for position, VR motion, animations
- High-speed messaging for seamless world transitions

**Testing Approach**: Use block mesh style capsules in Godot Engine 3D

- Simplified geometric representation for collision detection
- Efficient spatial reasoning without complex 3D models
- Optimized testing of multi-agent interactions
- Streamlined world transition testing
- Reduced computational overhead for development

### API Layer Implementation

**Decision**: Elixir Phoenix application with REST APIs and WebSocket channels

- aria_neon_frontlines application as core API layer
- User authentication and authorization
- World transition management
- Inventory persistence handling
- Distributed cluster configuration for scaling
- Non-blocking analytics event ingestion

### Persistence Layer Implementation

**Decision**: PostgreSQL with TimescaleDB for time-series optimization

- ACID-compliant relational database foundation
- TimescaleDB hypertables for efficient time-series storage
- Automatic partitioning by time intervals
- Schema-based isolation for multi-world data
- Optimized temporal queries and analytics
- Horizontal scaling through clustering capabilities

**Performance Optimization**: Leverages PostgreSQL and TimescaleDB capabilities

- Proper indexing strategies for query performance
- MVCC for concurrent transaction handling
- Automatic partitioning for consistent scaling
- Time-series transaction optimization
- Real-time layer as primary performance bottleneck

## Player Persona Analysis

### Decision 7: Support four Bartle taxonomy personas

**Rationale**: Ensures architecture scales efficiently across different player interaction patterns.

**Social Explorer**: High concurrent connections, in-memory synchronization
**World Hopper**: Multi-world state management, fast zone transfers
**Achiever**: High transaction frequency, economic operation isolation
**Competitor**: Low-latency PvP interactions, real-time ranking updates

### Detailed Persona Analysis

**Social Explorer Persona**: Handles high concurrency through horizontal Erlang clustering

- Primary load on real-time layer with in-memory state sync
- Zero database IOPS for movement through memory-only operations
- Scales to thousands of concurrent users without database bottlenecks

**World Hopper Persona**: Manages multi-world state through schema isolation

- PostgreSQL schema-based separation for world data
- Fast in-memory state hand-offs for seamless transitions
- Optimized transaction latency for persistence operations

**Achiever Persona**: Supports high-frequency economic transactions

- PostgreSQL ACID guarantees for inventory operations
- MVCC ensures consistent trading operations
- Schema separation prevents cross-world interference

**Competitor Persona**: Enables low-latency competitive interactions

- Real-time layer handles PvP mechanics
- PostgreSQL transactions for match outcome recording
- Schema isolation for world-specific leaderboards

The system's data flow is designed around this separation of concerns. A user login validates credentials against the PostgreSQL user tables, and initial world state is loaded from the per-world schemas with optimized queries. Real-time locomotion and VR motion are synchronized entirely in-memory, with asynchronous events sent to the analytics hypertables using TimescaleDB's efficient time-series ingestion. A seamless world transition is a fast, in-memory messaging operation, while a persistent state change like an inventory update is handled as an efficient, atomic transaction within the appropriate schema. PostgreSQL's schema-based architecture ensures complete isolation between different data domains while maintaining transactional consistency across the entire system.

## PostgreSQL/TimescaleDB Architecture Considerations

The adoption of PostgreSQL with TimescaleDB introduces several architectural patterns that enhance the V-Sekai platform's capabilities:

**Schema-Based Isolation:** Each logical data domain (users, analytics, worlds) operates within dedicated schemas, providing complete isolation while maintaining transactional consistency across the entire system.

**ACID Transactions with MVCC:** PostgreSQL's multi-version concurrency control ensures that complex operations like inventory transfers and leaderboard updates maintain serializable isolation without blocking concurrent operations.

**Time-Series Query Optimization:** The analytics hypertables leverage TimescaleDB's efficient time-series structure for high-volume event ingestion, with automatic partitioning supporting temporal range queries for analytics and monitoring.

**Real-Time Features:** PostgreSQL's LISTEN/NOTIFY mechanism enables real-time notifications for critical events, such as inventory changes or leaderboard updates, which can be pushed to clients through the Phoenix channels.

**Horizontal Scalability:** PostgreSQL's built-in clustering and TimescaleDB's distributed hypertables eliminate the need for manual sharding strategies, providing seamless scaling as the platform grows while maintaining optimized latency for time-series transactions.

## Technology & Migration Decisions

### Decision 8: Current technology stack selection

**Rationale**: Balances research requirements with production-ready components.

**Database**: PostgreSQL with TimescaleDB hypertables
**Web Framework**: Phoenix 1.8 with LiveView
**Real-time**: Phoenix Channels (WebSocket)
**Planning Engine**: Custom HTN+STN implementation
**Testing**: 382 passing tests for reliability

### Decision 9: Phased migration approach

**Rationale**: Ensures stability while incrementally adding capabilities.

**Phase 1 ✅ COMPLETED**: Database migration (SQLite → PostgreSQL + TimescaleDB)
**Phase 4 PLANNED**: Web text interface for user interaction
**Phase 5 PLANNED**: 3D domain simulation with operational archetypes

### Technology Stack Details

**Database Layer**: PostgreSQL with TimescaleDB provides ACID compliance and time-series optimization

- Hypertables for efficient temporal data storage
- Automatic partitioning by time intervals
- Schema-based multi-world isolation
- Optimized queries for analytics workloads

**Web Framework**: Phoenix 1.8 with LiveView enables modern real-time experiences

- WebSocket channels for seamless communication
- LiveView for interactive web interfaces
- Distributed cluster support for scaling
- Robust testing framework integration

**Planning Engine**: Custom HTN+STN implementation for intelligent agent behavior

- Hierarchical task decomposition
- Temporal constraint solving with MiniZinc
- Complex scheduling and resource management
- Comprehensive test coverage validation

### Migration Path Implementation

**Phase 1 - Database Migration**: Successfully completed

- Full SQLite to PostgreSQL migration
- TimescaleDB hypertable implementation
- Schema isolation for multi-world support
- Backward compatibility maintained

**Phase 4 - Web Text Interface**: Planned implementation

- User-friendly web-based interaction
- Text commands and query interface
- Accessible testing and usage entry point
- Foundation for user engagement features

**Phase 5 - 3D Domain Simulation**: Planned implementation

- Core 3D simulation capabilities
- Operational archetypes from domain adaptation
- Transfer protocols for multi-agent interactions
- Realistic simulation environment foundation

### Research Components Status

**✅ Temporal Planning**: Complete HTN+STN implementation

- Full hierarchical task decomposition
- Temporal constraint solving with MiniZinc
- Complex scheduling algorithms
- 382 comprehensive test cases

**✅ Web Framework**: Fully functional Phoenix application

- Robust WebSocket channel support
- Real-time communication capabilities
- Distributed cluster configuration
- Comprehensive testing integration

**✅ Database Migration**: Successfully completed

- SQLite to PostgreSQL transition
- TimescaleDB hypertable optimization
- Schema-based isolation implemented
- Performance optimization achieved

**🧪 ENet Integration**: Experimental phase

- dragonhunt02/enet-godot project integration
- Godot Engine compatibility testing
- Block mesh capsule testing approach
- Multi-agent interaction validation

**📋 Multi-tenant Architecture**: Designed for future implementation

- Schema-based isolation patterns
- Scalability architecture planned
- Performance optimization strategies
- Future enhancement roadmap

## Implementation Notes

This architecture document represents the target state for V-Sekai's massive multiplayer platform. The current Aria Character Core project serves as a research foundation, implementing core planning algorithms and web infrastructure that will form the basis of the full V-Sekai system.

Key research achievements from the current project:

- Complete temporal constraint solving with MiniZinc integration
- Hybrid HTN+STN planning with 382 test cases
- Real-time WebSocket communication via Phoenix Channels
- Comprehensive test coverage and algorithm validation
