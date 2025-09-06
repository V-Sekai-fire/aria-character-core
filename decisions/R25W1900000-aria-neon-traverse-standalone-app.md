# R25W1900000: Aria Neon Traverse App

## Status

Proposed

## Context

Need bot harness for stress testing navmesh-based city block simulation with 1000+ concurrent bots. Navmesh serves as the core simulation mechanism for movement, zone transfers, and trading interactions. Current `aria_neon_frontlines` lacks these features.

A navigation mesh (navmesh) is a data structure that represents the walkable surfaces of a 3D environment as a network of interconnected polygons. It enables efficient pathfinding and collision detection for AI agents in complex environments like city blocks.

## Decision

Create standalone `aria_neon_traverse` bot harness app with AriaHybridPlanner integration for massive multiplayer stress testing.

## Requirements

- Standalone operation, no `aria_neon_*` dependencies
- AriaHybridPlanner integration for bot path optimization
- 1000+ concurrent bot support
- Authoritative trading system

## Architecture

- Bot block movement with planner optimization
- Zone transfer mechanics with state persistence
- Authoritative inventory trading engine
- Concurrent bot management

## Implementation

- Week 1: Core domain and movement
- Week 2: Zone transfers
- Week 3: Trading system
- Week 4: Performance optimization

## Success Criteria

- Bot block-to-block movement working
- Zone transfers with persistence
- Authoritative trading system
- 1000+ concurrent bots
- <100ms response time

## Timeline

4 weeks to production-ready app
