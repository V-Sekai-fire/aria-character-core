[Google Gemini](https://gemini.google.com/app/53d715a6adf1e129)

# R25W1900000: Aria Neon Traverse App

## Status

Proposed

## Context

This project aims to create a standalone bot harness for stress testing a navmesh-based city block simulation. The simulation focuses on three core, simplified mechanics: seamless bot movement, zone transfers, and trading interactions. The goal is to isolate and rigorously test these specific features, rather than building a full-scale, complex city simulation. This approach allows for a focused and efficient stress test with 1000+ concurrent bots.

A navigation mesh (navmesh) is a data structure that represents the walkable surfaces of a 3D environment as a network of interconnected polygons. It enables efficient pathfinding and collision detection for AI agents in complex environments.

## Decision

Create standalone `aria_neon_traverse` bot harness app with AriaHybridPlanner integration for massive multiplayer stress testing.

## Requirements

- Standalone operation, no `aria_neon_*` dependencies.
- AriaHybridPlanner integration for efficient bot pathfinding.
- Support for 1000+ concurrent bots.
- Focus on three core mechanics: bot movement, seamless server travel, and an authoritative trading system.

## Architecture

- A core system for bot block-to-block movement, utilizing the planner for path optimization.
- Zone transfer mechanics with state persistence for seamless travel.
- An authoritative engine for inventory trading.
- A robust management system for concurrent bots.

## Success Criteria

- Bot block-to-block movement working.
- Zone transfers with persistence.
- Authoritative trading system.
- 1000+ concurrent bots supported.
- <100ms response time.

## Future Vision: V-Sekai: Neon Frontlines

This project is the first phase of a larger vision for a multiplayer cyberpunk game. The `aria_neon_traverse_app` bot harness will test core systems, and the following stubs will be built upon for the full "V-Sekai: Neon Frontlines" experience.

**Core Gameplay** V-Sekai: Neon Frontlines is a massively scalable, multiplayer game set in a cyberpunk metropolis. The core gameplay loop focuses on intelligent AI planning, resource management, and competitive, tactical combat. The foundation laid by the `aria_neon_traverse_app` will allow for seamless bot movement, zone transfers, and trading between players and AI, which are crucial for all player archetypes.

**Gameplay Focus**

- **Planning Engine:** An innovative AI planning system for complex, real-time decision-making and coordinated team actions.
- **Player Archetypes:** Players can adopt distinct roles, including `Tactician`, `Gatherer`, `Crafter`, and `Combatant`. These roles are supported by the `aria_neon_traverse_app`'s core mechanics of movement and trading.
- **Game Modes:** Structured multiplayer modes will be developed to support both competitive and cooperative play styles.

**Long-Term Technical Architecture** The full architecture will be built upon a robust foundation using a distributed Erlang/Elixir cluster for real-time operations and a distributed database for state and analytics. This will enable massive concurrency and consistent, persistent game state. Key components include an ENet-based game server, a Phoenix/Elixir API layer, and a multi-database persistence system with TimescaleDB for temporal data.

_Built with Elixir, Phoenix, PostgreSQL, and Godot Engine_
