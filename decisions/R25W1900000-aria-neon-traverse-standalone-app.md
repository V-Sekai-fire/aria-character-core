# ADR-002: Phase 1 - Core Gameplay Module (Alpha Sector)

## Status

Proposed

## Context

To ensure a stable and scalable foundation for "V-Sekai: Neon Frontlines," the project requires a focused initial phase that de-risks the most critical backend systems. The previous proposal's scope, including a dynamic procedural world, introduced too much complexity for a foundational release. This revised plan returns to the core principle: build a stable, playable game module on a massive scale, but within a controlled, static environment.

## Decision

We will build and launch **Phase 1: Alpha Sector**. This release will be a fully playable, persistent online world set within a single, large, handcrafted city district. The gameplay will be focused on validating three core pillars at scale, without the complexity of procedural generation:

1.  **Massive-Scale Traversal:** Players will navigate the large, detailed Alpha Sector. The primary goal is to test and validate the seamless streaming and state management required to support thousands of concurrent players in a single, contiguous zone.
2.  **Live Contract Board:** To provide clear goals and drive player interaction, the game will feature a live, server-driven contract board. This system will offer a constant stream of simple, systemic objectives (e.g., courier runs, item acquisition, location surveys) that encourage players to engage with the world and its economy.
3.  **Core Player-Driven Economy:** A robust, authoritative trading system will allow players to exchange goods. This provides the foundational economic loop and tests the system's transactional integrity under heavy load.

The success of this phase is a stable, live game environment within the Alpha Sector that proves the engine can support thousands of concurrent players with responsive (<100ms) interactions.

## Consequences

### Positive:

- **Drastically Reduced Scope:** Focusing on a single, static zone eliminates the immense complexity and unpredictability of procedural generation, allowing the team to focus on core engine stability.
- **Clear, Measurable Goals:** The performance of the traversal, contract, and trading systems within a known environment can be benchmarked precisely.
- **Delivers a Polished Experience:** By limiting the scope, the team can deliver a more stable, polished, and performant experience for the initial launch.
- **Establishes a Scalable Foundation:** The engine, once proven in the Alpha Sector, provides a reliable foundation upon which future content, features, and procedural systems can be built.

### Negative:

- **Limited Replayability:** A static world with systemic quests will have less long-term replayability than a dynamic one. The engagement will rely on the core loop and player-to-player interactions.
- **Content is Finite:** Players will eventually explore the entirety of the Alpha Sector. This plan accepts that the initial phase is about depth of mechanics, not breadth of content.

- **Technology Stack:** Elixir, Phoenix, PostgreSQL, Godot Engine\*
