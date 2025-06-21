# Aria Character Core

**⚠️ ALPHA • v0.2.0 • Research Code • Not Production Ready ⚠️**

AI planning research project exploring intelligent NPC behavior through hybrid HTN+STN planning systems.

NOTE: We use elixir 18.

## Status Overview

| Component            | Status       | Tests       | Notes                                                                           |
| -------------------- | ------------ | ----------- | ------------------------------------------------------------------------------- |
| **MCP Integration**  | ✅ Done      | 7/7 passing | Stdio scheduler interface fully implemented and stable; duration now in seconds |
| **Core Planning**    | ✅ Done      | All passing | HTN/STN algorithms fully implemented and stable                                 |
| **Storage System**   | ⏸️ Postponed | 0/20+       | Chunk distribution work deferred; not currently maintained                      |
| **Temporal Solver**  | ✅ Done      | All passing | STN constraints and temporal scheduling fully implemented and stable            |
| **NPC Management**   | ⏸️ Paused    | Mixed       | Development paused; basic structure exists                                      |
| **Batch Processing** | ⏸️ Paused    | N/A         | Batch helpers and core allocation logic removed; future work paused             |
| **KHR System**       | 🧪 R&D       | N/A         | Experimental research and development ongoing                                   |

**Current Reality:** 333 tests total, 326 passing, 7 failing (primarily MCP integration), 1 skipped.

## Quick Start

```bash
# Prerequisites: Elixir 1.16+, Erlang/OTP 26+
mix deps.get && mix compile
mix test  # Runs only working tests
```

**Key Limitation:** Most planning and storage systems non-functional.

## What This Is/Isn't

| ✅ This IS                                        | ❌ This is NOT       |
| ------------------------------------------------- | -------------------- |
| Research codebase exploring AI planning           | Playable game        |
| Academic investigation of HTN+STN hybrid planning | Production software  |
| Experimental NPC behavior systems                 | Stable API/framework |
| Development environment for planning algorithms   | Ready for end users  |

## Research Focus

**Core Investigation Areas:**

- **Hybrid Planning:** HTN goal decomposition + STN temporal constraints
- **Temporal Scheduling:** Scheduling with resource conflict detection
- **Parallel Processing:** Flow-based coordination for multi-NPC systems
- **Knowledge Representation:** RDF/SPARQL for NPC decision-making

## MCP Integration

The project includes a working Model Context Protocol (MCP) server that exposes temporal scheduling and pipeline management capabilities.

### Available Tools

| Tool Name                     | Description                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| schedule_activities           | Schedule activities using Membrane pipeline architecture with multiple strategy options  |
| validate_scheduling_solutions | Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver |
| configure_pipeline_layout     | Configure and create a new Membrane pipeline with specified topology and elements        |
| setup_element_config          | Validate and setup configuration for pipeline elements                                   |
| start_planning_pipeline       | Start a new planning pipeline with predefined topology                                   |
| stop_planning_pipeline        | Stop an active planning pipeline                                                         |
| get_pipeline_status           | Get detailed status information for a specific pipeline                                  |
| get_pipeline_metrics          | Get overall metrics for the pipeline manager                                             |
| list_active_pipelines         | List all currently active pipelines                                                      |
| send_pipeline_request         | Send a request to a specific active pipeline                                             |

## Development Priorities

1. **Fix Storage System:** Resolve chunk-based distribution failures

## Contributing

Focus areas for experimental research contributions:

- **Algorithm Implementation:** Complete HTN/STN planning systems
- **Test Recovery:** Fix disabled tests to restore functionality
- **Performance Research:** Solve timeout and scaling issues
- **Integration:** Connect partial systems into working pipelines

## Dependencies

Exploring integration of: AI Planning (HTN/STN) • Temporal Reasoning • Parallel Processing (Flow) • Knowledge Representation (RDF/SPARQL) • Model Context Protocol (MCP) • Content Distribution (Casync-inspired)

---

**License:** MIT • **Copyright:** 2025-present K. S. Ernest (iFire) Lee  
**Disclaimer:** Active research code. Expect incomplete features and non-functional systems.
