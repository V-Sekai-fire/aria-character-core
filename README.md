# Aria Character Core

**⚠️ ALPHA • v0.2.0 • Research Code • Not Production Ready ⚠️**

AI planning research project exploring intelligent NPC behavior through hybrid HTN+STN planning systems in Elixir.

## Project Overview

Aria Character Core is a research codebase for experimenting with AI planning, temporal scheduling, and NPC simulation. It is not a game or production system, but a platform for developing and testing hybrid HTN (Hierarchical Task Network) and STN (Simple Temporal Network) planning algorithms.

### Key Features
- **Hybrid Planning:** Combines HTN goal decomposition with STN temporal constraints.
- **Temporal Scheduling:** Schedules tasks with resource and time constraints.
- **Sample Simulations:** Includes scripts for running scalable community simulations.
- **Extensible:** Modular Elixir codebase for research and experimentation.

### Limitations
- **Not a Playable Game:** No user-facing gameplay or UI.
- **Incomplete Systems:** Storage, batch processing, and some integration features are non-functional or experimental.
- **Research Focus:** Many features are prototypes or under development; expect incomplete or unstable code.

## Current Status

| Component            | Status       | Tests       | Notes                                                                           |
| -------------------- | ------------ | ----------- | ------------------------------------------------------------------------------- |
| **Core Planning**    | ✅ Done      | All passing | HTN/STN algorithms implemented and tested                                       |
| **Storage System**   | ⏸️ Postponed | 0/20+       | Chunk distribution deferred; not maintained                                     |
| **Temporal Solver**  | ✅ Done      | All passing | STN constraints and scheduling implemented                                      |
| **NPC Management**   | ⏸️ Paused    | Mixed       | Basic structure exists; development paused                                      |
| **Batch Processing** | ⏸️ Paused    | N/A         | Helpers and allocation logic removed; future work paused                        |
| **KHR System**       | 🧪 R&D       | N/A         | Experimental; under research                                                    |

**Tests:** 333 total, 326 passing, 7 failing (mainly MCP integration), 1 skipped.

## Quick Start

```bash
# Prerequisites: Elixir 1.16+, Erlang/OTP 26+
mix deps.get && mix compile
mix test  # Runs only working tests

# Run scheduler samples
mix schedule.samples  # Default 6 residents
TOWN_SCALE=1 mix schedule.samples    # Small town (1 resident)
TOWN_SCALE=50 mix schedule.samples   # Medium town (50 residents)
TOWN_SCALE=1000 mix schedule.samples # Large city (1000 residents)
```

## What This Is/Isn't

| ✅ This IS                                        | ❌ This is NOT       |
| ------------------------------------------------- | -------------------- |
| Research codebase for AI planning                 | Playable game        |
| Academic investigation of HTN+STN planning        | Production software  |
| Experimental NPC behavior systems                 | Stable API/framework |
| Development environment for planning algorithms   | Ready for end users  |

## Research Focus

- **Hybrid Planning:** HTN + STN integration
- **Temporal Scheduling:** Resource and time management
- **Parallel Processing:** Multi-NPC coordination (Flow-based)
- **Knowledge Representation:** RDF/SPARQL for decision-making

## Scheduler Samples

Demonstrates temporal planning and scalable simulations:

1. **Simple Sequential Activities**
2. **Resource-Constrained Scheduling**
3. **Complex Dependencies**
4. **Entity and Capability Management**
5. **Simulation Mode**
6. **Smallville Community Simulation**

## Development Priorities

- Fix storage system (chunk-based distribution)
- Restore disabled tests
- Improve integration and performance

## Contributing

Focus on experimental research, algorithm implementation, and test recovery. See `mix.exs` for dependencies and development tools.

## License

MIT © 2025-present K. S. Ernest (iFire) Lee

**Disclaimer:** Active research code. Expect incomplete features and non-functional systems.
