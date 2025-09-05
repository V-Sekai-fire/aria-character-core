# V-Sekai Core Decisions

## Status: Proposed (Research Phase)

### Decision 1: PostgreSQL with TimescaleDB for persistence
**Rationale**: Robust ACID compliance, time-series optimization, horizontal scalability.

### Decision 2: Three-layer architecture (Real-time, API, Persistence)
**Rationale**: Separates concerns to prevent real-time bottlenecks.

### Decision 3: Erlang/Elixir for real-time game server
**Rationale**: Lightweight processes enable massive multiplayer concurrency.

### Decision 4: HTN+STN hybrid planning system
**Rationale**: Combines hierarchical decomposition with temporal constraint solving.

### Decision 5: Web-based text interface for Phase 4
**Rationale**: Accessible testing and platform interaction entry point.

### Decision 6: 3D domain simulation for Phase 5
**Rationale**: Realistic multi-agent interactions via operational archetypes.

### Decision 7: Four Bartle taxonomy personas
**Rationale**: Efficient scaling across different player interaction patterns.

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

| Component | Status |
|-----------|--------|
| Phoenix Framework | ✅ COMPLETED |
| HTN+STN Planning | ✅ COMPLETED |
| PostgreSQL Migration | ✅ COMPLETED |
| ENet Game Server | 🧪 EXPERIMENTAL |


## Next Steps

**Phase 4**: Web-based text interface for user interaction
**Phase 5**: 3D domain simulation with operational archetypes

---

*See separate documents for detailed implementation and database architecture*
