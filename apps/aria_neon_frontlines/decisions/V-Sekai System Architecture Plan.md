This document outlines a scalable architecture for the V-Sekai massive online multiplayer platform. The design consolidates all persistent data into a single, horizontally-scalable database technology to prioritize operational simplicity and data locality. A fundamental principle of the architecture is the separation of the real-time application layer from the persistence layer. This separation ensures that high-frequency, low-latency gameplay interactions do not create a bottleneck for the database service that stores permanent data.

The real-time layer is an Erlang-based game server that uses `dragonhunt02/enet-godot`. This project is an Erlang port of the ENet protocol library, created for compatibility with the ENet implementation used by Godot Engine clients. Since the server and clients both adhere to the ENet protocol, they can communicate directly. This implementation allows the server to leverage Erlang's lightweight processes to achieve massive concurrency. Each active world instance is managed by a dedicated process, which synchronizes ephemeral state data such as player position, VR motion, and avatar animations. This design also enables seamless world transitions by handling the state hand-off between world instances as a high-speed, in-memory messaging operation, which avoids the persistence layer entirely.

The API layer is the existing `uro/` Elixir Phoenix application. It provides REST API endpoints that the game server uses to interact with the persistence layer. Its responsibilities include handling user authentication, authorizing world transitions, retrieving world data, and managing inventory persistence. The Phoenix application can be configured in a distributed cluster to handle horizontal scaling. This layer also provides a dedicated, non-blocking ingestion endpoint to receive high-volume analytics events from the game server.

The persistence layer uses FoundationDB with the Ecto.Adapters.FoundationDB adapter to provide a distributed, ACID-compliant key-value store with multi-tenant isolation. FoundationDB manages all permanent data for the V-Sekai universe through logical tenant separation rather than traditional table-based organization. The primary tenant handles user accounts and social graphs. The analytics tenant uses FoundationDB's efficient key-value structure for high-volume event ingestion with custom indexing for temporal queries. The per-world tenant uses multi-tenant isolation to segregate world-specific data, enabling horizontal scaling through FoundationDB's built-in distribution capabilities. This approach provides immediate horizontal scalability without requiring schema migrations or sharding extensions.

The architecture leverages FoundationDB's distributed key-value store capabilities to provide high-throughput, low-latency persistence operations. FoundationDB's performance characteristics are optimized for the V-Sekai workload through tenant-based isolation and efficient key-value operations. The system distributes operations across FoundationDB's cluster with sub-millisecond latency for tenant-scoped transactions, enabling the real-time layer to remain the primary bottleneck rather than persistence operations. FoundationDB's built-in distribution and multi-version concurrency control (MVCC) ensure consistent performance as the platform scales horizontally.

The architecture's performance under load can be understood through four distinct player persona scenarios, reflecting the Bartle taxonomy. Each scenario stresses a different part of the system and demonstrates how the design remains efficient and responsive.

- **The Social Explorer (High Player Concurrency):** This persona, combining Bartle's Socializer and Explorer types, represents many users gathering in popular worlds or discovering new content. The primary load is on the Real-Time Application Layer. To support this, the Erlang game server cluster is scaled horizontally to handle the high number of concurrent connections. The core gameplay experience of fluid locomotion and expressive VR motion is managed entirely in memory. This ensures maximum responsiveness and generates zero database IOPS for movement, effectively decoupling player count from database load.
- **The World Hopper (High Instance Count):** A specific type of Explorer, this persona represents players who frequently traverse many different worlds or create numerous private instances. This activity tests the system's ability to manage state for a large number of active, concurrent worlds. FoundationDB's tenant-based isolation is critical here, as it provides logical separation of world data with built-in distribution across the cluster. Seamless zone transfers are essential for this persona, supported by fast, in-memory state hand-offs that leverage FoundationDB's sub-millisecond transaction latency for any required persistence operations.
- **The Achiever (High Transactional Intensity):** This persona, represented by a trader or collector, engages in frequent economic or goal-oriented activity. This activity leverages FoundationDB's ACID transaction guarantees for inventory transfers and economic operations. FoundationDB's multi-version concurrency control (MVCC) ensures that high-frequency trading operations remain consistent and isolated, with tenant-based separation preventing cross-world interference. The architecture supports trustworthy operations through FoundationDB's atomic transactions, which provide serializable isolation for complex economic interactions.
- **The Competitor (High-Stakes Interaction):** This persona, representing Bartle's Killer type, engages in competitive activities like player-vs-player combat. This scenario places high demands on the Real-Time Application Layer to ensure low-latency, fair, and responsive gameplay. It also leverages FoundationDB's transaction capabilities when match outcomes are recorded. A victory or defeat triggers an atomic transaction to update player rankings and distribute rewards, utilizing FoundationDB's tenant isolation for both world-specific leaderboards and global ranking systems with guaranteed consistency.

The system's data flow is designed around this separation of concerns. A user login validates credentials against the FoundationDB primary tenant, and initial world state is loaded from the per-world tenant with tenant-scoped queries. Real-time locomotion and VR motion are synchronized entirely in-memory, with asynchronous events sent to the analytics tenant using FoundationDB's efficient key-value ingestion. A seamless world transition is a fast, in-memory messaging operation, while a persistent state change like an inventory update is handled as an efficient, atomic transaction within the appropriate tenant. FoundationDB's multi-tenant architecture ensures complete isolation between different data domains while maintaining transactional consistency across the entire system.

    graph TD
        subgraph "Real-Time Application Layer"
            Godot[Godot Clients]
            GameServer[ENet Game Server<br/>dragonhunt02/enet-godot<br/>Erlang Implementation]
        end

        subgraph "API Layer"
            API[uro/ REST API<br/>Elixir Phoenix]
        end

        subgraph "Unified Persistence Layer"
            FoundationDB[FoundationDB Cluster<br/>Ecto.Adapters.FoundationDB<br/>Primary, Analytics & World Tenants]
        end

        Godot -->|ENet Protocol (DTLS)| GameServer
        GameServer -->|API Calls| API
        API -->|Tenant-Scoped Transactions| FoundationDB

## FoundationDB-Specific Architecture Considerations

The adoption of FoundationDB introduces several architectural patterns that enhance the V-Sekai platform's capabilities:

**Multi-Tenant Isolation:** Each logical data domain (users, analytics, worlds) operates within dedicated tenants, providing complete isolation while maintaining transactional consistency across the entire system.

**ACID Transactions with MVCC:** FoundationDB's multi-version concurrency control ensures that complex operations like inventory transfers and leaderboard updates maintain serializable isolation without blocking concurrent operations.

**Key-Value Query Optimization:** The analytics tenant leverages FoundationDB's efficient key-value structure for high-volume event ingestion, with custom indexes supporting temporal range queries for analytics and monitoring.

**Watch-Based Real-Time Features:** FoundationDB's watch mechanism enables real-time notifications for critical events, such as inventory changes or leaderboard updates, which can be pushed to clients through the Phoenix channels.

**Horizontal Scalability:** FoundationDB's built-in distribution eliminates the need for manual sharding strategies, providing seamless scaling as the platform grows while maintaining sub-millisecond latency for tenant-scoped operations.
