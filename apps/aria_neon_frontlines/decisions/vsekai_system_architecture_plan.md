# V-Sekai System Architecture Plan

## Status: Proposed (Research Phase)

This document outlines a scalable architecture for the V-Sekai massive online multiplayer platform. The design consolidates all persistent data into a single, horizontally-scalable database technology to prioritize operational simplicity and data locality. A fundamental principle of the architecture is the separation of the real-time application layer from the persistence layer. This separation ensures that high-frequency, low-latency gameplay interactions do not create a bottleneck for the database service that stores permanent data.

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

This architecture plan is currently in research phase. The Aria Character Core project has implemented several key components that form the foundation of the V-Sekai system. The Phoenix web framework has been successfully implemented through the aria_neon_frontlines application, providing robust WebSocket support for real-time communication. The temporal planning system is complete, featuring a sophisticated HTN+STN hybrid approach that handles complex scheduling and constraint solving. PostgreSQL with TimescaleDB serves as the current persistence layer, utilizing hypertables for efficient time-series data storage and retrieval. Real-time communication is handled through Phoenix Channels, enabling seamless WebSocket connections. The ENet game server integration remains in experimental phase, representing an area for future development and testing.

The real-time layer is an Erlang-based game server that uses `dragonhunt02/enet-godot`. This project is an Erlang port of the ENet protocol library, created for compatibility with the ENet implementation used by Godot Engine clients. Since the server and clients both adhere to the ENet protocol, they can communicate directly. This implementation allows the server to leverage Erlang's lightweight processes to achieve massive concurrency. Each active world instance is managed by a dedicated process, which synchronizes ephemeral state data such as player position, VR motion, and avatar animations. This design also enables seamless world transitions by handling the state hand-off between world instances as a high-speed, in-memory messaging operation, which avoids the persistence layer entirely.

**Testing Implementation:** The real-time layer should be tested using `dragonhunt02/enet-godot` with block mesh style capsules in Godot Engine 3D. This approach provides a simplified geometric representation for collision detection and spatial reasoning, enabling efficient testing of multi-agent interactions, world transitions, and spatial synchronization without the computational overhead of complex 3D models.

The API layer is the `aria_neon_frontlines` Elixir Phoenix application. It provides REST API endpoints and WebSocket channels for real-time communication. Its responsibilities include handling user authentication, authorizing world transitions, retrieving world data, and managing inventory persistence. The Phoenix application can be configured in a distributed cluster to handle horizontal scaling. This layer also provides a dedicated, non-blocking ingestion endpoint to receive high-volume analytics events from the game server.

The persistence layer uses PostgreSQL with TimescaleDB to provide a robust, ACID-compliant relational database with time-series optimization. PostgreSQL manages all permanent data for the V-Sekai universe through traditional table-based organization with TimescaleDB hypertables for efficient time-series data storage. The facts table uses TimescaleDB hypertables for optimal time-series performance, with automatic partitioning by time intervals. The analytics system leverages PostgreSQL's efficient indexing and TimescaleDB's time-bucketing capabilities for high-volume event ingestion with optimized temporal queries. The per-world data uses schema-based isolation to segregate world-specific data, enabling horizontal scaling through PostgreSQL's built-in clustering and TimescaleDB's distributed hypertables.

The architecture leverages PostgreSQL and TimescaleDB's relational and time-series capabilities to provide high-throughput, low-latency persistence operations. PostgreSQL's performance characteristics are optimized for the V-Sekai workload through proper indexing, TimescaleDB hypertables, and efficient query optimization. The system distributes operations across PostgreSQL clusters with optimized latency for time-series transactions, enabling the real-time layer to remain the primary bottleneck rather than persistence operations. PostgreSQL's MVCC and TimescaleDB's automatic partitioning ensure consistent performance as the platform scales horizontally.

The architecture's performance under load can be understood through four distinct player persona scenarios, reflecting the Bartle taxonomy. Each scenario stresses a different part of the system and demonstrates how the design remains efficient and responsive.

The Social Explorer represents a combination of Bartle's Socializer and Explorer types, where many users gather in popular worlds or discover new content. This scenario places primary load on the Real-Time Application Layer. To support this usage pattern, the Erlang game server cluster scales horizontally to handle high numbers of concurrent connections. The core gameplay experience of fluid locomotion and expressive VR motion is managed entirely in memory, ensuring maximum responsiveness while generating zero database IOPS for movement. This effectively decouples player count from database load, allowing the system to scale to thousands of concurrent users without database bottlenecks.

The World Hopper represents a specific type of Explorer who frequently traverses many different worlds or creates numerous private instances. This activity tests the system's ability to manage state for a large number of active, concurrent worlds. PostgreSQL's schema-based isolation is critical here, as it provides logical separation of world data with built-in clustering across the database. Seamless zone transfers are essential for this persona, supported by fast, in-memory state hand-offs that leverage PostgreSQL's optimized transaction latency for any required persistence operations.

The Achiever represents a trader or collector who engages in frequent economic or goal-oriented activity. This persona leverages PostgreSQL's ACID transaction guarantees for inventory transfers and economic operations. PostgreSQL's multi-version concurrency control ensures that high-frequency trading operations remain consistent and isolated, with schema-based separation preventing cross-world interference. The architecture supports trustworthy operations through PostgreSQL's atomic transactions, which provide serializable isolation for complex economic interactions.

The Competitor represents Bartle's Killer type, engaging in competitive activities like player-vs-player combat. This scenario places high demands on the Real-Time Application Layer to ensure low-latency, fair, and responsive gameplay. It also leverages PostgreSQL's transaction capabilities when match outcomes are recorded. A victory or defeat triggers an atomic transaction to update player rankings and distribute rewards, utilizing PostgreSQL's schema isolation for both world-specific leaderboards and global ranking systems with guaranteed consistency.

The system's data flow is designed around this separation of concerns. A user login validates credentials against the PostgreSQL user tables, and initial world state is loaded from the per-world schemas with optimized queries. Real-time locomotion and VR motion are synchronized entirely in-memory, with asynchronous events sent to the analytics hypertables using TimescaleDB's efficient time-series ingestion. A seamless world transition is a fast, in-memory messaging operation, while a persistent state change like an inventory update is handled as an efficient, atomic transaction within the appropriate schema. PostgreSQL's schema-based architecture ensures complete isolation between different data domains while maintaining transactional consistency across the entire system.

## PostgreSQL/TimescaleDB Architecture Considerations

The adoption of PostgreSQL with TimescaleDB introduces several architectural patterns that enhance the V-Sekai platform's capabilities:

**Schema-Based Isolation:** Each logical data domain (users, analytics, worlds) operates within dedicated schemas, providing complete isolation while maintaining transactional consistency across the entire system.

**ACID Transactions with MVCC:** PostgreSQL's multi-version concurrency control ensures that complex operations like inventory transfers and leaderboard updates maintain serializable isolation without blocking concurrent operations.

**Time-Series Query Optimization:** The analytics hypertables leverage TimescaleDB's efficient time-series structure for high-volume event ingestion, with automatic partitioning supporting temporal range queries for analytics and monitoring.

**Real-Time Features:** PostgreSQL's LISTEN/NOTIFY mechanism enables real-time notifications for critical events, such as inventory changes or leaderboard updates, which can be pushed to clients through the Phoenix channels.

**Horizontal Scalability:** PostgreSQL's built-in clustering and TimescaleDB's distributed hypertables eliminate the need for manual sharding strategies, providing seamless scaling as the platform grows while maintaining optimized latency for time-series transactions.

## Technology Alternatives & Migration Path

### Current Technology Stack (Aria Character Core v0.2.0)

The current implementation of Aria Character Core v0.2.0 utilizes PostgreSQL with TimescaleDB hypertables as the database layer, providing efficient time-series data storage and retrieval. The web framework is built on Phoenix 1.8 with LiveView, offering a modern, real-time web experience. Real-time communication is handled through Phoenix Channels, enabling seamless WebSocket connections for interactive features. The planning engine features a custom HTN+STN implementation that handles complex temporal scheduling and constraint solving. The project maintains comprehensive test coverage with 382 passing tests, ensuring reliability and stability of the core functionality.

### Production Migration Path

The production migration follows a phased approach to ensure stability and maintainability. Phase 1, database migration, has been completed successfully. This phase involved migrating from SQLite to PostgreSQL with TimescaleDB, implementing hypertables for optimal time-series data handling, adding multi-tenant isolation patterns, and maintaining backward compatibility throughout the transition.

Phase 4 focuses on providing a comprehensive text interface on the web. This phase will develop a user-friendly web-based interface that allows users to interact with the V-Sekai system through text commands and queries, providing an accessible entry point for testing and using the platform's capabilities.

Phase 5 addresses simulating the 3D domain tasks as outlined in the domain adaptation specification. This phase will implement the core 3D simulation capabilities, focusing on the operational archetypes and transfer protocols defined in the neon frontlines domain adaptation document, enabling realistic multi-agent interactions within the simulated environment.

### Research Components Status

The temporal planning component is complete, featuring a full HTN+STN implementation that handles complex hierarchical task decomposition and temporal constraint solving. The web framework is fully functional, with the Phoenix application providing robust real-time capabilities through WebSocket channels. Database migration has been completed successfully, transitioning from SQLite to PostgreSQL with TimescaleDB for optimal time-series performance. ENet integration remains in experimental phase, utilizing the dragonhunt02/enet-godot project for game server communication. Multi-tenant architecture has been designed but not yet implemented, representing a future enhancement for data isolation and scalability.

## Implementation Notes

This architecture document represents the target state for V-Sekai's massive multiplayer platform. The current Aria Character Core project serves as a research foundation, implementing core planning algorithms and web infrastructure that will form the basis of the full V-Sekai system.

Key research achievements from the current project:

- Complete temporal constraint solving with MiniZinc integration
- Hybrid HTN+STN planning with 382 test cases
- Real-time WebSocket communication via Phoenix Channels
- Comprehensive test coverage and algorithm validation
