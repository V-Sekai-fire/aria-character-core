# AriaMembranePipeline Migration Tombstone

**Migration Date:** June 23, 2025  
**Target Location:** `apps/aria_membrane_pipeline/`  
**Migration Type:** Module Extraction (Phase 4d of ADR-151)

## What was moved

**Membrane pipeline modules:**

- `lib/aria_engine/membrane/` → `apps/aria_membrane_pipeline/lib/membrane/`
  - `format_transformer_filter.ex` - Data format transformation
  - `mcp_schedule_filter.ex` - MCP scheduling integration
  - `mcp_sink.ex` - Model Context Protocol data sink
  - `mcp_source.ex` - Model Context Protocol data source
  - `minizinc_solver_filter.ex` - MinZinc constraint solver integration
  - `minizinc_template_filter.ex` - MinZinc template processing
  - `pipeline_manager.ex` - Pipeline orchestration and management
  - `plan_filter.ex` - Planning data filtering
  - `planner_filter.ex` - Planner integration filter
  - `planner_mcp_filter.ex` - Planner MCP bridge
  - `schedule_planner_filter.ex` - Schedule planning coordination
  - `testing_filter.ex` - Testing infrastructure
  - `validation_pipeline_filter.ex` - Data validation pipeline
  - `format/` subdirectory with format definitions
  - `validation_pipeline/` subdirectory with validation components

**Test files:**

- `test/aria_engine/membrane/` → `apps/aria_membrane_pipeline/test/membrane/`

## New app structure

```
apps/aria_membrane_pipeline/
├── lib/
│   ├── aria_membrane_pipeline.ex (main module)
│   └── membrane/ (moved from lib/aria_engine/membrane/)
├── test/
│   ├── test_helper.exs
│   └── membrane/ (moved)
├── mix.exs
├── README.md
└── .formatter.exs
```

## Dependencies

AriaMembranePipeline depends on:

- `aria_engine_core` - Core state management and utilities
- `aria_hybrid_planner` - Planning strategy coordination
- `aria_temporal_planner` - Temporal reasoning capabilities
- `aria_scheduler` - Activity scheduling and resource management
- `membrane_core` - Membrane Framework foundation
- `membrane_file_plugin` - File I/O capabilities
- External: `jason`, `telemetry`, `porcelain`

## Integration

Main project updated to include `{:aria_membrane_pipeline, path: "apps/aria_membrane_pipeline"}` dependency.

## Compilation status

✅ **Successful compilation** with expected warnings for missing PipelineManager module functions.

## Purpose

AriaMembranePipeline provides streaming data processing, format transformation, validation pipelines, and solver integration using the Membrane Framework as an independent umbrella app with clear boundaries and modular testing.
