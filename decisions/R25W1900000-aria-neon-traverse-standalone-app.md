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
