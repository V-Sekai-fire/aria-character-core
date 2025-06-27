# ADR 106: Canonical Time Unit for Scheduling and Temporal Reasoning

<!-- @adr_serial R25V0032371 -->

## Status

Completed (June 19, 2025)

## Context

The AriaEngine codebase handles scheduling, planning, and temporal reasoning across multiple modules (MCPTools, Scheduler, Timeline, STN, etc.). Durations, start_times, and end_times are parsed from user input, JSON, and APIs in various formats (ISO 8601, DateTime intervals, integers). The system also supports multi-level-of-detail (LOD) temporal planning, where each STN (Simple Temporal Network) may use a different time resolution.

Historically, there has been ambiguity and inconsistency in the units used for durations and time points (minutes, seconds, integers, floats), leading to subtle bugs and integration issues.

## Decision

**Canonical Unit:**

- All durations, start_times, and end_times in activities, scheduler, timeline, and plan representations will be normalized to **float seconds** as early as possible.
- All arithmetic, comparisons, and state updates outside of STNs will use float seconds.

**STN Unit Handling:**

- Each STN instance will store its own explicit unit or resolution (e.g., seconds, minutes, abstract steps, or a scaling factor).
- All time points and constraints inside an STN are stored as unitless integers (or floats if needed).
- Conversion between float seconds and STN units will be explicit and centralized at the STN boundary, using the STN's unit/resolution field.

**Multi-LOD Support:**

- When converting between LODs (e.g., coarse to fine), use the unit/resolution fields to scale constraints and time points appropriately.
- The Timeline/context layer manages the mapping between real-world time and each STN's unit.

**Testing and Documentation:**

- All test cases and assertions will use float seconds for expected values, with `assert_in_delta` for comparisons where appropriate.
- All relevant documentation and comments will specify that durations, start_times, and end_times are in float seconds (except inside STNs).

## Consequences

- Eliminates ambiguity and risk of unit mismatch throughout the scheduling and planning pipeline.
- Makes integration between modules and LODs explicit and robust.
- Simplifies debugging and onboarding for new contributors.
- Requires a one-time audit and update of all code paths and tests to ensure compliance.

## Migration Plan

- All core Timeline and STN modules now use float seconds as the canonical unit outside STNs.
- STN struct and Units modules enforce explicit, centralized conversion using the time_unit field.
- Documentation and comments updated to clarify boundaries and conventions.
- All relevant tests updated to use float seconds and assert_in_delta for comparisons.

### Affected Modules

- `lib/aria_engine/timeline/time_converter.ex`
- `lib/aria_engine/timeline/interval.ex`
- `lib/aria_engine/timeline/internal/stn.ex`
- `lib/aria_engine/timeline/internal/stn/core.ex`
- `lib/aria_engine/timeline/internal/stn/units.ex`
- `test/aria_engine/mcp_tools_test.exs`

### Completion Criteria

- [x] All durations, start_times, and end_times outside STNs are float seconds
- [x] STN unit/resolution fields are explicit and conversions are centralized
- [x] Documentation and comments updated
- [x] Tests updated for float seconds and assert_in_delta

**Migration completed June 19, 2025.**
