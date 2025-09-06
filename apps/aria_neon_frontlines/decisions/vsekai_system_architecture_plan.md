V-Sekai: Neon Frontlines

About This Game

V-Sekai: Neon Frontlines combines emergent AI planning systems with immersive 3D environments in a neon-drenched cyberpunk metropolis where every shadow hides opportunity and danger lurks in the glow.

Neon Frontlines features intelligent AI companions with goal-task temporal planning, massive scalability through Erlang/Elixir servers, an immersive cyberpunk world in a single city block, and four distinct play styles.

The Tactician: Lead your squad in coordinated, high-stakes operations. Master positioning and planning to execute flawless strategies, perfect for the natural raid leader.

The Gather: Become the engine of the district. Master supply chains, corner the market, and explore the block to fuel the economy through gathering and logistics.

The Crafter: Push the limits of efficiency. Optimize resource pipelines and craft superior gear, dedicating yourself to mastering the intricate systems of the metropolis.

The Combatant: Rise through the ranks in competitive combat. Outmaneuver rival squads in skill-based firefights where only the sharpest reflexes and tightest teamwork prevail.
Steam Tags

Multiplayer, Strategy, Cyberpunk, AI, Tactical, Planning, Logistics, Competitive, Cooperative, Sci-fi, Resource Management, Combat
System Requirements

Minimum:

    OS: Windows 10, Ubuntu 18.04

    Processor: Intel Core i5-6600K

    Memory: 8 GB RAM

    Graphics: NVIDIA GTX 1060 6GB

    Storage: 20 GB available space

Recommended:

    OS: Windows 11, Ubuntu 20.04

    Processor: Intel Core i7-8700K

    Memory: 16 GB RAM

    Graphics: NVIDIA RTX 3070

    Storage: 50 GB SSD space

Roadmap

Phase 4: Web-based text interface
Phase 5: Domain simulation
Phase 6: Enhanced 3D domain simulation
Technical Architecture

```mermaid
graph TD
subgraph "Real-Time Layer<br/>Erlang/Elixir<br/>Lightweight Processes"
A[Godot Clients<br/>ENet Protocol<br/>DTLS Encryption<br/>3D Block Capsules]
B[ENet Game Server<br/>Massive Concurrency<br/>Process per World Instance<br/>In-Memory State Sync<br/>Zero-IOPS Transfers]
end

    subgraph "API Layer<br/>Phoenix/Elixir<br/>Distributed Cluster"
        C[aria_neon_frontlines<br/>WebSocket Channels<br/>REST Endpoints<br/>User Authentication<br/>World Transitions<br/>Inventory Persistence<br/>Analytics Ingestion]
    end

    subgraph "Persistence Layer<br/>PostgreSQL + TimescaleDB<br/>ACID Transactions"
        D[User Tables<br/>Session Management<br/>CDN Metadata<br/>High-Read Consistency]
        E[World Schemas<br/>Bitemporal 6NF<br/>Time-Series Hypertables<br/>Automatic Partitioning<br/>Compression Policies]
        F[Analytics Hypertables<br/>Temporal Queries<br/>Event Ingestion<br/>LISTEN/NOTIFY<br/>Real-Time Notifications]
    end

    subgraph "Planning Engine<br/>HTN+STN Hybrid<br/>382 Test Cases"
        G[Hierarchical Task Networks<br/>Temporal Constraint Solving<br/>Multi-Agent Coordination<br/>Complex Scheduling<br/>Resource Management]
        H[The Tactician<br/>Squad Command<br/>Tactical Coordination<br/>Log Tactical Decisions]
        I[The Provider<br/>Supply Chain Optimization<br/>Route Mapping<br/>Resource Distribution]
        J[The Artisan<br/>Efficiency Optimization<br/>Resource Allocation<br/>Performance Metrics]
        K[The Mercenary<br/>Firefight Coordination<br/>Tactical Advantage<br/>Strategic Positioning]
    end

    subgraph "Database Architecture<br/>Three Logical Databases"
        L[Lobby & Login<br/>PostgreSQL Standard<br/>User Auth & Sessions]
        M[Game Server State<br/>AriaState Relational<br/>Predicate-Subject-Fact<br/>Real-Time Sync]
        N[Per-World Bitemporal<br/>TimescaleDB Hypertables<br/>Historical Versioning<br/>Complex Temporal Queries]
    end

    A -->|"ENet Protocol<br/>UDP-based<br/>Reliable Messaging"| B
    B -->|"Phoenix Channels<br/>WebSocket<br/>JSON Payloads"| C
    C -->|"Ecto Transactions<br/>Optimized Queries<br/>Connection Pooling"| D
    C -->|"Hypertable Inserts<br/>Time-Series Data<br/>Automatic Partitioning"| E
    C -->|"Analytics Events<br/>Temporal Bucketing<br/>Real-Time Aggregation"| F
    G -->|"Intelligent Behavior<br/>Constraint Resolution<br/>Multi-Step Planning"| B
    H -.->|"Social Coordination<br/>Team Communication<br/>Tactical Planning"| G
    I -.->|"Logistics Optimization<br/>Route Optimization<br/>Supply Management"| G
    J -.->|"Efficiency Metrics<br/>Resource Optimization<br/>Performance Tracking"| G
    K -.->|"Combat Tactics<br/>Strategic Positioning<br/>Risk Assessment"| G
    D -.->|"User Authentication<br/>Session Validation<br/>Access Control"| L
    E -.->|"World State Persistence<br/>Temporal Versioning<br/>Historical Queries"| M
    F -.->|"Event Analytics<br/>Performance Monitoring<br/>Usage Statistics"| N
```

Built with Elixir, Phoenix, PostgreSQL, and Godot Engine
