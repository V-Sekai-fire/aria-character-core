# Phase 1 - Core Gameplay Module (Alpha Sector Cluster)

## Status

Proposed

## Context

"V-Sekai: Neon Frontlines" requires a foundational phase to de-risk core backend systems at scale. This initial release must validate essential gameplay loops and critical infrastructure—specifically seamless shard transfers—within a controlled, static environment before introducing procedural complexity.

## Decision

Launch **Phase 1: Alpha Sector Cluster**, a live, persistent game module set in a handcrafted multi-district world. The focus is to validate the core engine at scale via three gameplay pillars:

1.  **Traversal & Shard Transfers:** Players will navigate between handcrafted districts to validate the seamless hand-off of player state across server processes (shards).
2.  **Live Contract Board:** A server-driven system will offer simple, systemic objectives (courier runs, item acquisition) to drive player interaction and test world systems.
3.  **Core Player Economy:** An authoritative trading system will validate transactional integrity under heavy, concurrent load.

## Success Criteria

A stable, live environment supporting thousands of concurrent players with seamless shard transfers and responsive (<100ms) interactions.

## Consequences

- **De-risks Core Tech:** This architecture directly tests the shard transfer mechanic, a critical and complex piece of MMO infrastructure.
- **Provides a Scalable Foundation:** A proven engine provides a reliable base upon which future content, features, and procedural systems can be built.
- **Ensures Focused Scope:** Using static zones instead of procedural generation allows the team to concentrate on core engine stability and performance.
- **Accepted Trade-offs:** This focused approach accepts that a static world with systemic quests has finite content and limited long-term replayability. The priority for Phase 1 is validating mechanical depth over content breadth.

- **Technology Stack:** Elixir, Phoenix, PostgreSQL, Godot Engine\*
