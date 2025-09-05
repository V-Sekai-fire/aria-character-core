# V-Sekai: Neon Frontlines

**About This Game**

V-Sekai: Neon Frontlines combines cutting-edge AI planning systems with immersive 3D environments in a neon-drenched cyberpunk metropolis where every shadow hides opportunity and danger lurks in the glow.

Neon Frontlines features intelligent AI companions with HTN+STN hybrid planning, massive scalability through Erlang/Elixir servers, an immersive cyberpunk world in a single city block, and four distinct play styles: Socializers who command squads and coordinate tactical operations, Explorers who master supply chains and optimize resource distribution, Achievers who maximize efficiency through intelligent resource allocation, and Competitors who outmaneuver rivals in high-stakes firefight coordination.

## System Requirements

**Minimum:**

- OS: Windows 10, Ubuntu 18.04
- Processor: Intel Core i5-6600K
- Memory: 8 GB RAM
- Graphics: NVIDIA GTX 1060 6GB
- Storage: 20 GB available space

**Recommended:**

- OS: Windows 11, Ubuntu 20.04
- Processor: Intel Core i7-8700K
- Memory: 16 GB RAM
- Graphics: NVIDIA RTX 3070
- Storage: 50 GB SSD space

## Steam Tags

Multiplayer, Strategy, Cyberpunk, AI, Tactical, Planning, Logistics, Competitive, Cooperative, Sci-fi, Resource Management, Combat

## Roadmap

**Phase 4**: Web-based text interface

**Phase 5**: Enhanced 3D domain simulation

## Technical Architecture

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
        H[Local Socializer Archetype<br/>Squad Command<br/>Tactical Coordination<br/>Log Tactical Decisions]
        I[Block Explorer Archetype<br/>Supply Chain Optimization<br/>Route Mapping<br/>Resource Distribution]
        J[Local Achiever Archetype<br/>Efficiency Optimization<br/>Resource Allocation<br/>Performance Metrics]
        K[Block Competitor Archetype<br/>Firefight Coordination<br/>Tactical Advantage<br/>Strategic Positioning]
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

---

_Built with Elixir, Phoenix, PostgreSQL, and Godot Engine_
