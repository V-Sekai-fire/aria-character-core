# AriaScheduler Migration Tombstone

**Migration Date:** June 23, 2025  
**Target Location:** `apps/aria_scheduler/`  
**Migration Type:** Module Extraction (Phase 4c of ADR-151)

## What was moved

**Scheduler modules:**
- `lib/aria_engine/scheduler.ex` → `apps/aria_scheduler/lib/scheduler.ex`
- `lib/aria_engine/scheduler/` → `apps/aria_scheduler/lib/scheduler/`
  - `core.ex` - Central scheduling coordination
  - `domain_converter.ex` - Domain transformation utilities
  - `entity_manager.ex` - Entity relationship management
  - `plan_converter.ex` - Plan format conversion
  - `resource_manager.ex` - Resource allocation handling
  - `state_manager.ex` - Scheduling state management
  - `domain_converter/` subdirectory with specialized converters

**Test files:**
- `test/aria_engine/scheduler_test.exs` → `apps/aria_scheduler/test/scheduler_test.exs`
- `test/aria_engine/scheduler/` → `apps/aria_scheduler/test/scheduler/`

## New app structure

```
apps/aria_scheduler/
├── lib/
│   ├── aria_scheduler.ex (main module)
│   ├── scheduler.ex (moved from lib/aria_engine/)
│   └── scheduler/ (moved from lib/aria_engine/scheduler/)
├── test/
│   ├── test_helper.exs
│   ├── scheduler_test.exs (moved)
│   └── scheduler/ (moved)
├── mix.exs
├── README.md
└── .formatter.exs
```

## Dependencies

AriaScheduler depends on:
- `aria_engine_core` - Core state management and domain utilities
- `aria_hybrid_planner` - Planning coordination and strategy management  
- `aria_temporal_planner` - Temporal reasoning and constraint solving
- External: `jason`, `libgraph`, `telemetry`, `timex`

## Integration

Main project updated to include `{:aria_scheduler, path: "apps/aria_scheduler"}` dependency.

## Compilation status

✅ **Successful compilation** with expected warnings for missing external modules (Plan, iso8601).

## Purpose

AriaScheduler provides activity scheduling, resource management, and domain conversion capabilities as an independent umbrella app with clear boundaries and modular testing.
