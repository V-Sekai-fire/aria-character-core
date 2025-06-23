# AriaHybridPlanner Migration Tombstone

**Extracted:** 2025-06-23  
**New Location:** `apps/aria_hybrid_planner/`  
**ADR Reference:** ADR-151 Strict Encapsulation and Modular Testing Architecture

## What was moved

This module was extracted to maintain strict encapsulation boundaries and enable independent testing of hybrid planning functionality.

**Moved directories:**
- `lib/aria_engine/hybrid_planner/` → `apps/aria_hybrid_planner/lib/hybrid_planner/`
- `lib/aria_engine/plan/` → `apps/aria_hybrid_planner/lib/plan/`
- `lib/aria_engine/planning/` → `apps/aria_hybrid_planner/lib/planning/`

**Moved files:**
- `lib/aria_engine/planning.ex` → `apps/aria_hybrid_planner/lib/planning.ex`
- `lib/aria_engine/planner_adapter.ex` → `apps/aria_hybrid_planner/lib/planner_adapter.ex`

**Moved tests:**
- `test/aria_engine/hybrid_planner/` → `apps/aria_hybrid_planner/test/hybrid_planner/`
- `test/aria_engine/membrane/planner_filter_test.exs` → `apps/aria_hybrid_planner/test/planner_filter_test.exs`

## New app structure

The AriaHybridPlanner app provides:

- **HybridCoordinatorV2**: Central coordination system
- **Strategy System**: Pluggable planning strategies
- **Plan Management**: Core planning algorithms and utilities
- **Integration Layer**: Interfaces with temporal and state systems

## Dependencies

- **aria_engine_core**: Core state management and domain utilities
- **aria_temporal_planner**: Temporal reasoning and STN solving
- **libgraph**: Graph data structures for plan representation
- **jason**: JSON encoding/decoding
- **telemetry**: Event tracking and monitoring

All functionality now available in the dedicated umbrella app with independent testing capabilities.
