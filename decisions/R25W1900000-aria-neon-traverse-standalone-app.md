# R25W1900000: Aria Neon Traverse App

## Status

Proposed

## Context

Need inter-block movement, zone transfers, and authoritative trading for 1000+ concurrent players. Current `aria_neon_frontlines` lacks these features.

## Decision

Create standalone `aria_neon_traverse` app with AriaHybridPlanner integration for massive multiplayer stress testing.

## Requirements

- Standalone operation, no `aria_neon_*` dependencies
- AriaHybridPlanner integration for path optimization
- 1000+ concurrent player support
- Authoritative trading system

## Architecture

- Block movement with planner optimization
- Zone transfer mechanics with state persistence
- Authoritative inventory trading engine
- Concurrent player management

## Implementation

Week 1: Core domain and movement
Week 2: Zone transfers
Week 3: Trading system
Week 4: Performance optimization

## Success Criteria

- Block-to-block movement working
- Zone transfers with persistence
- Authoritative trading system
- 1000+ concurrent players
- <100ms response time

## Timeline

4 weeks to production-ready app
