This document outlines a scalable architecture for the V-Sekai massive online multiplayer platform. The design consolidates all persistent data into a single, horizontally-scalable database technology to prioritize operational simplicity and data locality. A fundamental principle of the architecture is the separation of the real-time application layer from the persistence layer. This separation ensures that high-frequency, low-latency gameplay interactions do not create a bottleneck for the database service that stores permanent data.

The real-time layer is an Erlang-based game server that uses `dragonhunt02/enet-godot`. This project is an Erlang port of the ENet protocol library, created for compatibility with the ENet implementation used by Godot Engine clients. Since the server and clients both adhere to the ENet protocol, they can communicate directly. This implementation allows the server to leverage Erlang's lightweight processes to achieve massive concurrency. Each active world instance is managed by a dedicated process, which synchronizes ephemeral state data such as player position, VR motion, and avatar animations. This design also enables seamless world transitions by handling the state hand-off between world instances as a high-speed, in-memory messaging operation, which avoids the persistence layer entirely.

The API layer is the existing `uro/` Elixir Phoenix application. It provides REST API endpoints that the game server uses to interact with the persistence layer. Its responsibilities include handling user authentication, authorizing world transitions, retrieving world data, and managing inventory persistence. The Phoenix application can be configured in a distributed cluster to handle horizontal scaling. This layer also provides a dedicated, non-blocking ingestion endpoint to receive high-volume analytics events from the game server.

The persistence layer will begin as a single, powerful PostgreSQL server to simplify initial deployment and operations. This server will manage all permanent data for the V-Sekai universe, organized into three distinct logical roles. The primary data role uses standard tables for user accounts and social graphs. The analytics role uses the TimescaleDB extension and hypertables for event ingestion. The per-world data role uses standard tables designed to be "shard-ready" by including a `world_id` distribution key. This approach allows for a straightforward future migration to a horizontally-scaled, distributed cluster using an extension like Citus Data when the platform's scale demands it.

The architecture is designed to operate efficiently within a 2,500 IOPS budget. This load is projected to be distributed with 500 IOPS for primary data operations, 1,000 IOPS for analytics ingestion, and 1,000 IOPS for per-world transactional writes. This budget is feasible because the in-memory real-time layer absorbs the vast majority of user interactions, which minimizes the load on the database.

The architecture's performance under load can be understood through four distinct player persona scenarios, reflecting the Bartle taxonomy. Each scenario stresses a different part of the system and demonstrates how the design remains efficient and responsive.

- **The Social Explorer (High Player Concurrency):** This persona, combining Bartle's Socializer and Explorer types, represents many users gathering in popular worlds or discovering new content. The primary load is on the Real-Time Application Layer. To support this, the Erlang game server cluster is scaled horizontally to handle the high number of concurrent connections. The core gameplay experience of fluid locomotion and expressive VR motion is managed entirely in memory. This ensures maximum responsiveness and generates zero database IOPS for movement, effectively decoupling player count from database load.
- **The World Hopper (High Instance Count):** A specific type of Explorer, this persona represents players who frequently traverse many different worlds or create numerous private instances. This activity tests the system's ability to manage state for a large number of active, concurrent worlds. The sharding strategy in the persistence layer is critical here, as it distributes the data across the PostgreSQL cluster. Seamless zone transfers are essential for this persona, supported by fast, in-memory state hand-offs that are not constrained by database performance.
- **The Achiever (High Transactional Intensity):** This persona, represented by a trader or collector, engages in frequent economic or goal-oriented activity. This activity directly stresses the IOPS budget of the persistence layer, specifically the 1,000 IOPS allocated for per-world data. The architecture supports the need for trustworthy operations like inventory transfers by using atomic database transactions, which guarantee data consistency. Because these events are much less frequent than movement, the transactional load stays within the budgeted IOPS.
- **The Competitor (High-Stakes Interaction):** This persona, representing Bartle's Killer type, engages in competitive activities like player-vs-player combat. This scenario places high demands on the Real-Time Application Layer to ensure low-latency, fair, and responsive gameplay. It also stresses the persistence layer when match outcomes are recorded. A victory or defeat triggers an atomic transaction to update player rankings and distribute rewards, consuming IOPS from both the per-world and primary data budgets for world-specific and global leaderboards, respectively.

The system's data flow is designed around this separation of concerns. A user login validates credentials against the PostgreSQL cluster, and initial world state is loaded from the sharded tables. Real-time locomotion and VR motion are synchronized entirely in-memory, with asynchronous events sent to the analytics database only for logging. A seamless world transition is a fast, in-memory messaging operation, while a persistent state change like an inventory update is handled as an efficient, atomic transaction in the database.

    graph TD
        subgraph "Real-Time Application Layer"
            Godot[Godot Clients]
            GameServer[ENet Game Server<br/>dragonhunt02/enet-godot<br/>Erlang Implementation]
        end

        subgraph "API Layer"
            API[uro/ REST API<br/>Elixir Phoenix]
        end

        subgraph "Unified Persistence Layer"
            Postgres[Single PostgreSQL Server<br/>(Shard-Ready for Distribution)<br>Primary, Analytics & World Data]
        end

        Godot -->|ENet Protocol (DTLS)| GameServer
        GameServer -->|API Calls| API
        API -->|SQL Queries/Inserts| Postgres
