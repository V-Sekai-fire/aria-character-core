# Aria Character Core

**⚠️ ALPHA • v0.1.0 • Research Code • Not Production Ready ⚠️**

AI planning research project exploring intelligent NPC behavior through hybrid HTN+STN planning systems.

## Status Overview

| Component | Status | Tests | Notes |
|-----------|--------|-------|-------|
| **KHR Math Nodes** | ✅ Working | 45/45 | Complete implementation |
| **Core Planning** | ❌ Broken | 0/115+ | HTN/STN algorithms incomplete |
| **Storage System** | ❌ Broken | 0/20+ | Chunk distribution failing |
| **Temporal Solver** | 🔶 Partial | Mixed | STN constraints have timing issues |
| **NPC Management** | 🔶 Partial | Mixed | Basic structure exists |

**Current Reality:** 368 enabled tests passing, 115+ tests disabled due to core system failures.

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
- **Visual Scripting:** glTF KHR_interactivity nodes adapted for AI planning
- **Parallel Processing:** Flow-based coordination for multi-NPC systems
- **Knowledge Representation:** RDF/SPARQL for NPC decision-making

## Technical Architecture

```
lib/aria_engine/           # AI Planning Core (mostly incomplete)
├── hybrid_planner/        # Strategy coordination framework
├── plan/                  # Core planning algorithms  
├── timeline/              # Temporal constraint handling
├── node_library/          # ✅ KHR math nodes (working)
└── domains/               # Planning domain definitions

lib/aria_town/             # Knowledge & NPC Management (partial)
lib/aria_storage/          # Content Distribution (broken)
lib/aria_auth/             # Authentication Framework (partial)
lib/aria_security/         # Security Integration (partial)
```

## Current Capabilities

**Actually Working:**
- KHR Math Nodes: Complete glTF-inspired computation nodes
- Project Structure: Modular Elixir architecture
- Development Tooling: Quality/testing/build systems
- Dependencies: AI/ML libraries (Nx, LibGraph) integrated

**Major Gaps:**
- Planning algorithms incomplete (HTN/STN core missing)
- Temporal reasoning has performance issues
- Storage system fundamentally broken
- Cross-system integration non-functional

## Development Priorities

1. **Restore Planning Tests:** Fix 115+ disabled core planning tests
2. **Complete HTN/STN Integration:** Implement hybrid planning algorithms
3. **Fix Storage System:** Resolve chunk-based distribution failures
4. **Performance Issues:** Address widespread timeout problems

## Contributing

Focus areas for experimental research contributions:
- **Algorithm Implementation:** Complete HTN/STN planning systems
- **Test Recovery:** Fix disabled tests to restore functionality
- **Performance Research:** Solve timeout and scaling issues
- **Integration:** Connect partial systems into working pipelines

See `test/DISABLED_TESTS.md` for specific failing systems.

## Dependencies

Exploring integration of: AI Planning (HTN/STN) • Temporal Reasoning • Parallel Processing (Flow) • Knowledge Representation (RDF/SPARQL) • Visual Programming (glTF nodes) • Content Distribution (Casync-inspired)

---

**License:** MIT • **Copyright:** 2025-present K. S. Ernest (iFire) Lee  
**Disclaimer:** Active research code. Expect incomplete features and non-functional systems.
