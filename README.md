# Aria Character Core

**⚠️ ALPHA • v0.2.0 • Research Code • Not Production Ready ⚠️**

AI planning research project exploring intelligent NPC behavior through hybrid HTN+STN planning systems.

## Status Overview

| Component | Status | Tests | Notes |
|-----------|--------|-------|-------|
| **MCP Integration** | 🔶 Partial | 6/7 failing | Scheduler interface working, response handling issues |
| **Core Planning** | 🔶 Partial | 1 timeout | HTN/STN algorithms partially implemented |
| **Storage System** | ❌ Broken | 0/20+ | Chunk distribution failing |
| **Temporal Solver** | 🔶 Partial | Mixed | STN constraints have performance issues |
| **NPC Management** | 🔶 Partial | Mixed | Basic structure exists |
| **KHR System** | ❌ Removed | N/A | Deleted per ADR-096 (obsolete) |

**Current Reality:** 333 tests total, 326 passing, 7 failing (primarily MCP integration), 1 skipped.

## Quick Start

```bash
# Prerequisites: Elixir 1.16+, Erlang/OTP 26+
mix deps.get && mix compile
mix test  # Runs only working tests
```

**Key Limitation:** Most planning and storage systems non-functional.

## What This Is/Isn't

| ✅ This IS | ❌ This is NOT |
|------------|----------------|
| Research codebase exploring AI planning | Playable game |
| Academic investigation of HTN+STN hybrid planning | Production software |
| Experimental NPC behavior systems | Stable API/framework |
| Development environment for planning algorithms | Ready for end users |

## Research Focus

**Core Investigation Areas:**

- **Hybrid Planning:** HTN goal decomposition + STN temporal constraints
- **Temporal Scheduling:** Critical Path Method with resource conflict detection
- **Parallel Processing:** Flow-based coordination for multi-NPC systems
- **Knowledge Representation:** RDF/SPARQL for NPC decision-making

## Technical Architecture

```
lib/aria_engine/           # AI Planning Core (partially working)
├── hybrid_planner/        # Strategy coordination framework
├── mcp/                   # ✅ Model Context Protocol integration (working)
├── plan/                  # Core planning algorithms  
├── timeline/              # Temporal constraint handling
└── domains/               # Planning domain definitions

lib/aria_storage/          # Content Distribution (broken)
lib/aria_auth/             # Authentication Framework (partial)
lib/aria_security/         # Security Integration (partial)
```

## Current Capabilities

**Actually Working:**

- MCP Integration: Temporal scheduler interface via Model Context Protocol
- Project Structure: Modular Elixir architecture
- Development Tooling: Quality/testing/build systems

**Major Gaps:**

- Storage system fundamentally broken

## MCP Integration

The project includes a working Model Context Protocol server that exposes temporal scheduling capabilities:

```bash
# Start MCP server (stdio mode for IDE integration)
mix mcp.stdio
```

**Available Tools:**

- `schedule_activities`: Critical Path Method scheduling with hybrid planning
- Handles empty activity lists (valid mathematical solution)
- Resource conflict detection and analysis
- Dependency validation and circular dependency detection

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
