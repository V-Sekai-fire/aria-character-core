# V-Sekai Core Decisions

## Status: Proposed (Research Phase)

| Decision                          | Technical Rationale                                                       | Student/Marketing Explanation                                                                                             |
| --------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **PostgreSQL with TimescaleDB**   | Robust ACID compliance, time-series optimization, horizontal scalability  | Like a super-organized filing system that grows with your needs and handles time-based data efficiently                   |
| **Three-layer architecture**      | Separates real-time, API, and persistence concerns to prevent bottlenecks | Think of it as separating the kitchen, dining room, and storage - each handles its job without slowing others down        |
| **Erlang/Elixir for game server** | Lightweight processes enable massive multiplayer concurrency              | Like having thousands of tiny helpers working simultaneously, each handling one player's actions instantly                |
| **HTN+STN hybrid planning**       | Combines hierarchical decomposition with temporal constraint solving      | A smart planning system that breaks big goals into steps while respecting time limits, like a chess master thinking ahead |
| **Web-based text interface**      | Accessible testing and platform interaction entry point                   | A simple chat-like interface where anyone can test the system without complex setup                                       |
| **3D domain simulation**          | Realistic multi-agent interactions via operational archetypes             | Virtual characters that act like real people in a 3D world, making the simulation feel alive and authentic                |
| **Four Bartle taxonomy personas** | Efficient scaling across different player interaction patterns            | Four personality types (socializers, explorers, achievers, competitors) that represent how different people play games    |

## Architecture Overview

```mermaid
    graph TD
        subgraph "Real-Time"
            Godot[Godot Clients]
            GameServer[ENet Game Server]
        end
        subgraph "API"
            API[aria_neon_frontlines]
        end
        subgraph "Persistence"
            PostgreSQL[PostgreSQL + TimescaleDB]
        end
        Godot --> GameServer
        GameServer --> API
        API --> PostgreSQL
```

## Current Status

| Component            | Status          |
| -------------------- | --------------- |
| Phoenix Framework    | ✅ COMPLETED    |
| HTN+STN Planning     | ✅ COMPLETED    |
| PostgreSQL Migration | ✅ COMPLETED    |
| ENet Game Server     | 🧪 EXPERIMENTAL |

## Next Steps

**Phase 4**: Web-based text interface for user interaction
**Phase 5**: 3D domain simulation with operational archetypes

---

_See separate documents for detailed implementation and database architecture_
