# AriaEngineCore TODO

**@aria_serial:** R25W158CORE

**ADR Reference:** R25W1398085 - Unified Durative Action Specification and Planner Standardization

## ⚠️ CRITICAL: Umbrella Workflow Enforcement

**MANDATORY RULE: All Mix commands MUST be executed from umbrella root directory.**

### Verification Commands

Before running ANY Mix commands, verify your location:

```bash
pwd  # Should show /home/ernest.lee/Developer/aria-character-core (umbrella root)
ls   # Should show apps/ directory and root mix.exs
```

### FORBIDDEN Patterns ❌

```bash
# NEVER do these operations:
cd apps/aria_engine_core && mix compile
cd apps/any_app && mix deps.get
```

### REQUIRED Patterns ✅

```bash
# ALWAYS work from umbrella root:
mix compile                           # Compiles all apps in dependency order
mix test apps/aria_engine_core       # Tests aria_engine_core from root
mix deps.get                         # Manages dependencies for entire umbrella
```

### Emergency Recovery

If umbrella gets broken by incorrect workflow:

1. **Return to umbrella root:** `cd /home/ernest.lee/Developer/aria-character-core`
2. **Clean everything:** `mix clean && mix deps.clean --all`
3. **Remove broken artifacts:** `rm -rf _build deps`
4. **Regenerate:** `mix deps.get && mix compile`

## Overview

AriaEngineCore provides the foundational temporal planning and execution capabilities for the Aria system. This app focuses on core planning algorithms, state space exploration, and solution tree management without domain-specific implementations.

## Current Status

**AriaEngineCore Dependencies (Tier 4):**

AriaEngineCore depends on the following umbrella apps:
- **aria_state** - State management and entity storage
- **aria_timeline** - Temporal coordination and timeline management  
- **aria_minizinc_stn** - STN constraint solving
- **aria_minizinc_goal** - Goal constraint solving
- **aria_minizinc_executor** - MiniZinc execution

**Testing Status:** ✅ 39/39 tests passing (0 failures)

**Integration Status:**
- ✅ **External API Complete:** Clean external module following umbrella standards
- ⚠️ **Domain Module Missing:** AriaEngineCore.Domain implementation needed
- ⚠️ **Planner Integration:** AriaHybridPlanner.Core dependency issues

## Completed ✅

### Core API Implementation ✅

- [x] AriaEngineCore external API module with proper delegation
- [x] Three main API functions: `plan/3`, `run_lazy/3`, `run_lazy_tree/3`
- [x] Type aliases for external API compatibility
- [x] State management API delegation to AriaEngineCore.State
- [x] Domain management API delegation to AriaEngineCore.Domain
- [x] Solution tree API structure
- [x] Version information and application metadata

### Internal Module Structure ✅

- [x] AriaEngineCore.Planner module integration
- [x] AriaEngineCore.State module delegation
- [x] AriaEngineCore.Plan module for solution trees
- [x] Proper module documentation and examples

## Critical Issues Requiring Resolution

### Issue 1: AriaEngineCore.Domain Module Missing (HIGH)

**Problem:** Multiple undefined function warnings for Domain module functions

**Impact:** External API delegation broken, affects umbrella integration

**Missing Functions:**
- `get_task_methods/2`, `get_unigoal_methods/2`, `get_multigoal_methods/1`
- `get_multitodo_methods/1`, `get_action_metadata/2`, `get_entity_registry/1`
- `get_durative_action/2`, `execute_action/4`

**Required:** Implement `AriaEngineCore.Domain` module or update external API delegation

### Issue 2: AriaHybridPlanner Dependency (MEDIUM)

**Problem:** Missing `AriaHybridPlanner.Core` module causing adapter warnings

**Impact:** Planner adapter functionality incomplete

**Required:** Either implement missing module or update adapter to handle missing dependency gracefully

### Issue 3: Code Quality & Warnings Cleanup (MEDIUM)

**Problem:** Compilation warnings for unused variables and functions

**Examples:**
- Unused variables: `matrix`, `m11`, `m3`, `m7` in math operations
- Missing delegation targets in external API

**Required:** Clean up warnings to improve development experience

## Implementation Plan

### Phase 1: Domain Module Implementation (HIGH PRIORITY)

**Status:** ⏳ PENDING

**Tasks:**
- [ ] **Implement AriaEngineCore.Domain module**
  - [ ] Add missing domain method functions (`get_task_methods/2`, etc.)
  - [ ] Implement entity registry management
  - [ ] Add action metadata and execution functions
  - [ ] Ensure proper integration with AriaState

- [ ] **External API Integration**
  - [ ] Fix delegation warnings in external API
  - [ ] Ensure all delegated functions have implementations
  - [ ] Add comprehensive type specifications

### Phase 2: Planner Infrastructure Enhancement (MEDIUM PRIORITY)

**Status:** ⏳ PENDING

**Tasks:**
- [ ] **Core Planning Algorithms**
  - [ ] Enhance state space exploration
  - [ ] Improve solution tree management
  - [ ] Optimize planning performance

- [ ] **Planner Integration**
  - [ ] Fix AriaHybridPlanner.Core dependency issues
  - [ ] Implement missing planner adapter functions
  - [ ] Add integration tests for planner components

### Phase 3: Code Quality and Testing (ONGOING)

**Status:** ⏳ PENDING

**Tasks:**
- [ ] **Warning Cleanup**
  - [ ] Fix unused variable warnings
  - [ ] Remove dead code and unused functions
  - [ ] Clean up import statements

- [ ] **Test Enhancement**
  - [ ] Add integration tests with dependent apps
  - [ ] Improve test coverage for core planning functionality
  - [ ] Add performance benchmarks

## Integration Points

**Apps that depend on AriaEngineCore:**
- **aria_hybrid_planner** - High-level planning coordination
- **aria_animation_demo** - Animation planning demonstrations
- **aria_khr_interactivity** - KHR behavior planning

**Apps that AriaEngineCore depends on:**
- **aria_state** - State management
- **aria_timeline** - Temporal coordination
- **aria_minizinc_*** - Constraint solving

## Success Criteria

- [ ] Complete AriaEngineCore.Domain module implementation
- [ ] All external API delegations working correctly
- [ ] Clean compilation with no warnings
- [ ] Comprehensive test suite with >95% coverage
- [ ] Integration tests with dependent apps passing
- [ ] Clear separation between core infrastructure and domain-specific functionality

## Testing Commands

```bash
# Run aria_engine_core tests from umbrella root
mix test apps/aria_engine_core

# Run with coverage
mix test apps/aria_engine_core --cover

# Run specific test files
mix test apps/aria_engine_core/test/specific_test.exs
```

## Implementation Notes

**Architecture Focus:**
- Core temporal planning and execution capabilities
- State space exploration and solution management
- Integration points for domain-specific apps
- Clean umbrella app communication patterns

**Performance Considerations:**
- Core planning algorithm complexity optimization
- Memory management for large state spaces
- Efficient integration with timeline and constraint solving

**Development Guidelines:**
- Follow umbrella app external API patterns
- Maintain clean separation of concerns
- Comprehensive documentation and type specifications
- Test-driven development approach
