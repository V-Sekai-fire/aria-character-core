# Aria Character Core

**⚠️ ALPHA/EXPERIMENTAL STATUS ⚠️**

An experimental AI planning research project exploring intelligent NPC behavior through hybrid planning systems. This is active development code - not a released game or production software.

## Project Status

**Current Version:** 0.1.0 (Alpha)

**Development Status:**
- 🔬 **Research Phase:** Core AI planning algorithms under development
- 🧪 **Experimental Codebase:** Many systems incomplete or non-functional
- ⚠️ **Testing Issues:** 115+ tests currently disabled due to implementation gaps
- 📚 **Academic Focus:** Exploring hybrid HTN+STN planning for game AI

**This is NOT:**
- A playable game
- Production-ready software  
- A stable API or framework
- Ready for end-user installation

## Research Goals

This project investigates advanced AI planning techniques for game NPCs, specifically:

### Hybrid Planning Architecture
- **HTN (Hierarchical Task Network)** planning for high-level goal decomposition
- **STN (Simple Temporal Network)** constraints for temporal reasoning
- **Multi-strategy coordination** between different planning approaches
- **Real-time adaptation** of plans based on changing conditions

### Visual Scripting Research
- **glTF KHR_interactivity** standard implementation for node-based NPC behavior
- **Mathematical computation nodes** for AI decision-making
- **Event-driven programming** models for reactive NPC systems

### High-Performance Processing
- **Flow-based parallel processing** for multi-NPC coordination
- **GPU-inspired convergence patterns** adapted for CPU architectures
- **Scalable temporal constraint solving** across populations

## Technical Architecture

### Core Modules (Implementation Status)

```
lib/aria_engine/           # AI Planning Core
├── hybrid_planner/        # 🔶 Partial - Strategy coordination framework
├── plan/                  # 🔶 Partial - Core planning algorithms  
├── timeline/              # 🔶 Partial - Temporal constraint handling
├── node_library/          # ✅ Working - KHR math nodes (45 tests passing)
└── domains/               # 🔶 Partial - Planning domain definitions

lib/aria_town/             # Knowledge & NPC Management
├── knowledge_base.ex      # 🔶 Partial - RDF knowledge representation
├── npc_manager.ex         # 🔶 Partial - NPC lifecycle management
└── time_manager.ex        # 🔶 Partial - Temporal coordination

lib/aria_storage/          # Content Distribution Research
├── casync_decoder.ex      # 🔶 Partial - Content-addressable storage
├── chunks.ex              # ❌ Disabled - Chunking system has test failures
└── storage.ex             # 🔶 Partial - Storage abstraction

lib/aria_auth/             # Authentication Framework
├── macaroons.ex           # 🔶 Partial - Token-based auth research
└── sessions.ex            # 🔶 Partial - Session management

lib/aria_security/         # Security Integration
├── openbao.ex             # 🔶 Partial - Vault integration
└── secrets.ex             # 🔶 Partial - Secrets management
```

**Legend:**
- ✅ Working: Functional with passing tests
- 🔶 Partial: Basic structure exists, many features incomplete
- ❌ Disabled: Non-functional, tests disabled due to failures

## Current Capabilities

### What Actually Works
- **KHR Math Nodes:** Complete implementation with 45 passing tests
- **Basic Project Structure:** Modular Elixir architecture established
- **Development Tooling:** Code quality, testing, and build systems configured
- **Core Dependencies:** AI/ML libraries (Nx, LibGraph) integrated

### Major Limitations
- **Planning System:** Core HTN/STN algorithms incomplete
- **Temporal Reasoning:** STN constraint solver has timing issues
- **Storage System:** Chunk-based content distribution failing tests
- **Integration:** Most cross-system integration non-functional
- **Performance:** Many components have timeout and scaling issues

## Development Environment

### Prerequisites
```bash
# Elixir 1.16+ required
# Erlang/OTP 26+ required
```

### Setup
```bash
mix deps.get
mix compile
```

### Testing
```bash
# Run working tests only (368 tests, ~115 disabled)
mix test

# Many integration tests are currently disabled
# See test/DISABLED_TESTS.md for details
```

### Current Test Status
- **Total Tests:** 368 (115+ disabled due to failures)
- **Passing:** 368/368 currently enabled tests
- **Major Systems:** Many core planning tests disabled
- **Working Example:** KHR math nodes demonstrate target patterns

## Research Dependencies

This project explores integration of several research areas:

- **AI Planning:** HTN/STN hybrid approaches
- **Temporal Reasoning:** Constraint satisfaction for time-based planning  
- **Parallel Processing:** Flow-based coordination patterns
- **Knowledge Representation:** RDF/SPARQL for NPC knowledge
- **Visual Programming:** glTF-based node scripting
- **Content Distribution:** Casync-inspired asset streaming

## Contributing

This is experimental research code. Contributions should focus on:

- **Core Algorithm Implementation:** Help complete HTN/STN planning systems
- **Test Recovery:** Fix disabled tests to restore system functionality  
- **Performance Research:** Address timeout and scaling issues
- **Integration Work:** Connect partial systems into working pipelines
- **Documentation:** Document research findings and implementation decisions

### Development Priorities
1. **Restore Core Planning Tests:** Many temporal planning tests are disabled
2. **Complete HTN/STN Integration:** Hybrid planner needs algorithm implementation
3. **Fix Storage System:** Chunk-based system has fundamental issues
4. **Performance Optimization:** Address widespread timeout problems

## License

Copyright (c) 2025-present K. S. Ernest (iFire) Lee  
SPDX-License-Identifier: MIT

---

**Disclaimer:** This is active research and development code. Expect significant changes, incomplete features, and non-functional systems. Not suitable for production use or as a stable dependency.
