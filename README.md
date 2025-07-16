# Aria Character Core

**⚠️ ALPHA • v0.2.0 • Temporal Planning Feature Complete ⚠️**

AI planning research project with working temporal scheduling and hybrid HTN+STN planning systems in Elixir.

* R25W1398085: [Unified Durative Action Specification](decisions/R25W1398085-unified-durative-action-specification-and-planner-standardization.md)

## Current Status: Alpha Feature Complete

* ✅ **Temporal Planning**: Feature complete with 382 passing tests, needs broader validation
* ✅ **Scheduler Samples**: Working demonstrations with 3 core scheduling scenarios
* ✅ **STN Constraints**: Simple Temporal Network solving with MiniZinc
* 🧪 **Research Phase**: Algorithm validation and performance testing

## Quick Start

```bash
# Prerequisites: Elixir 1.18+, Erlang/OTP 26+, MiniZinc (required for alpha stage), cmake, and libgit2_1.8-devel
mix deps.get && mix compile
mix test  # All 382 tests passing

# Run scheduler demonstrations
mix schedule.samples  # Runs 3 core scheduling scenarios
```

## Core Capabilities

* **Hybrid HTN+STN Planning**: Combines goal decomposition with temporal constraints
* **Temporal Scheduling**: Resource and time management with ~~millisecond precision~~ (Replaced with configurable time units and LOD resolution v0.2.0)
* ~~**MCP Integration**~~ (Removed in v0.2.0): Schedule activities interface for external tool access

---

## Technical Overview

Aria Character Core is a research codebase for experimenting with AI planning, temporal scheduling, and NPC simulation. The project focuses on hybrid planning algorithms that combine Hierarchical Task Networks (HTN) with Simple Temporal Networks (STN) for intelligent agent behavior.

### Architecture Highlights

* **HybridCoordinatorV2**: Multi-strategy planning system with STN, ~~Optimizer~~ (Proposed in ADR-109, not implemented), and Default strategies
* **Timeline Module**: Complete temporal reasoning with Allen's Interval Algebra (IntervalRelations)
* **MiniZinc Integration**: Constraint programming for Simple Temporal Network solving
* **Strategy Pattern**: Extensible planning approaches for different problem types

### Research Focus

* **Temporal Constraint Solving**: Real-time scheduling with resource conflicts
* **Parallel Processing**: Multi-agent coordination using ~~Flow-based systems~~ (Removed v0.2.0)
* **Knowledge Representation**: RDF integration for decision-making; ~~SPARQL removed v0.2.0~~
* **Performance Scaling**: Algorithm validation from single to massive agent populations

## Development Status Matrix

| Component              | Status           | Tests       | Notes                                                    |
| ---------------------- | ---------------- | ----------- | -------------------------------------------------------- |
| **Temporal Planning**  | ✅ Alpha Complete | 382 passing | Feature complete, needs broader validation               |
| **STN Constraints**    | ✅ Alpha Complete | All passing | MiniZinc constraint solving implemented and tested       |
| **Scheduler Interface** | ✅ Alpha Complete | All passing | Core scheduling interface functional; ~~MCP integration removed v0.2.0~~ |
| **Timeline System**    | ✅ Alpha Complete | All passing | Interval algebra and agent classification complete       |
| **Storage System**     | ⏸️ Postponed     | 0/20+       | Chunk distribution deferred; not maintained             |
| **NPC Management**     | ⏸️ Paused        | Mixed       | Basic structure exists; development paused              |
| **Batch Processing**   | ⏸️ Paused        | N/A         | Helpers and allocation logic removed; future work       |
| **KHR System**         | 🧪 R&D           | N/A         | Experimental glTF interactivity; under research         |

## Scheduler Demonstrations

The project includes three core scheduling scenarios that demonstrate temporal planning capabilities:

1. **Sequential Scheduling**: Basic sequential activity planning with time constraints
2. **Resource Constraints**: Advanced scheduling with location conflicts, prop availability, and character limitations
3. **Entity Capabilities**: Character-specific scheduling based on individual abilities and restrictions

Each demonstration showcases different aspects of temporal planning and constraint solving capabilities.

## What This Is/Isn't

| ✅ This IS                                        | ❌ This is NOT       |
| ------------------------------------------------- | -------------------- |
| Research codebase for AI planning algorithms      | Playable game        |
| Working temporal scheduling system                 | Production software  |
| Academic investigation of HTN+STN integration     | Stable API/framework |
| Alpha-complete planning demonstrations             | Ready for end users  |

## Research Achievements

Based on ADR-117 (Temporal Planning Segment Closure), the project has successfully delivered:

* **Production-Ready Temporal Constraint Solving**: Complete MiniZinc STN implementation
* **Multi-Strategy Planning Architecture**: Extensible HybridCoordinatorV2 system
* **Comprehensive Test Coverage**: 382 tests with 100% pass rate
* **Real-Time Performance**: Millisecond precision with parallel processing capability
* **Clean Architecture**: Strategy pattern with modular, maintainable components

## Development Priorities

**Current Alpha Validation Focus:**

* Broader algorithm testing across diverse scenarios
* Performance benchmarking and optimization
* Integration testing with external systems
* Documentation and research publication preparation

**Future Development:**

* Novel writing system integration
* ~~Enhanced MCP server ecosystem~~ (Removed in v0.2.0)
* Creative workflow optimization tools
* Advanced temporal reasoning capabilities

## Contributing

This is active research code focused on:

* Algorithm implementation and validation
* Performance testing and optimization
* Test coverage expansion
* Research documentation and publication

See `mix.exs` for dependencies and development tools. Contributions should focus on experimental research, algorithm improvements, and comprehensive testing.

## License

MIT © 2025-present K. S. Ernest (iFire) Lee

**Research Disclaimer:** Alpha-stage research code. Temporal planning features are complete but require broader validation. Expect ongoing algorithm refinements and performance optimizations.
