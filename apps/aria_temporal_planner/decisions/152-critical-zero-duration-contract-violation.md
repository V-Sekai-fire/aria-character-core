# ADR-152: Complete Temporal Relations System Implementation

<!-- @adr_serial R25W0015136 -->

**Status:** Superseded → Decomposed (June 23, 2025)  
**Date:** June 23, 2025  
**Priority:** CRITICAL

## Tombstone: ADR Decomposition

This omnibus ADR has been decomposed into focused, actionable ADRs for better tracking and implementation:

**Critical Timeline Testing Issues:**

- **ADR-154**: Timeline Module Namespace Aliasing Fixes
- **ADR-155**: Hybrid Planner Test Suite Restoration  
- **ADR-156**: Cross-App Scheduler Dependency Resolution
- **ADR-157**: STN Consistency Test Recovery

**System Integration:**

- **ADR-158**: Comprehensive Timeline Test Suite Validation

**Future Temporal Relations Features:**

- **ADR-159**: Language-Neutral Temporal Relations Implementation
- **ADR-160**: Extended Temporal Relations System

**Rationale:** The original ADR mixed critical testing fixes with future feature development, making it difficult to track progress and prioritize work. The decomposed ADRs provide clear, focused objectives for timeline testing recovery.

**Implementation Priority:** Start with ADR-154 (namespace fixes) for immediate testing improvements, followed by ADR-157 (STN consistency) for core functionality validation.

## Context

A comprehensive temporal relations system is needed to handle all types of temporal relationships in the planning system. The current implementation has critical gaps including zero-duration contract violations and missing support for advanced temporal relations.

**Current Issues:**

- **Contract Violation:** Zero durations reach STN solver causing 28 test failures
- **Limited Relations:** Only basic Allen relations implemented
- **Missing Bridge Layer:** No proper temporal classification and constraint generation
- **Incomplete Taxonomy:** Advanced temporal relations not supported

**Required Temporal Relations:**

- Allen's 13 core interval relations
- Extended relations (flexible, conditional, fuzzy, periodic)
- Event-based relations (triggers, prevents, enables)
- Resource and priority relations
- Multi-timeline coordination
- Probabilistic temporal modeling

## Decision

Implement a complete temporal relations system with language-neutral naming, comprehensive Bridge layer classification, and support for all identified temporal relationship types.

## Implementation Plan

### Phase 1: Core Temporal Relations Foundation (Week 1)

**File:** `apps/aria_temporal_planner/lib/timeline/temporal_relations.ex`

- [ ] Implement Allen's 13 relations with language-neutral codes
- [ ] Add relation detection and classification functions
- [ ] Support internationalization for relation descriptions
- [ ] Replace `IntervalRelations` module with `TemporalRelations`

**Language-Neutral Relation Codes:**

- Point Relations: `EQ` (=), `ADJ_F` (→), `ADJ_B` (←)
- Containment: `WITHIN` (⊂), `CONTAINS` (⊃), `START_ALIGN` (⊢), `START_EXTEND` (⊢→), `END_ALIGN` (⊣), `END_EXTEND` (←⊣)
- Overlap: `OVERLAP_F` (⟩⟨), `OVERLAP_B` (⟨⟩)
- Separation: `PRECEDES` (<), `FOLLOWS` (>)

**File:** `apps/aria_temporal_planner/lib/timeline/bridge.ex`

- [x] Implement temporal relation classification system
- [x] Add STN constraint generation for each relation type
- [x] Fix zero-duration contract violations with proper filtering
- [x] Add defensive validation at all STN entry points

**File:** `apps/aria_temporal_planner/lib/timeline/internal/stn/core.ex`

- [x] Fix add_time_point to use {-1, 1} instead of {0, 0} for self-references
- [x] Fix add_interval duration constraints to use ranges instead of fixed-points
- [x] Update constraint intersection logic to handle micro-ranges properly
- [x] Convert all fixed-point constraints {n, n} to micro-ranges {n-1, n+1}

**File:** `apps/aria_temporal_planner/lib/timeline/internal/stn.ex`

- [x] Fix initialize_constant_work_structure dummy constraints to use {-1, 1}
- [x] Eliminate all remaining {0, 0} constraint violations in STN initialization

**Test Files Fixed:**

- [x] `test/timeline/internal/stn/operations_test.exs` - Fixed all {0, 0} constraints
- [x] `test/temporal_planner/stn_method_test.exs` - Fixed world_start constraint
- [x] All identified {0, 0} constraint violations eliminated from codebase

### Phase 2: Extended Temporal Relations (Week 2)

**File:** `apps/aria_temporal_planner/lib/timeline/extended_relations.ex`

- [ ] **FLEXIBLE** relations: STN constraint ranges `[min, max]`
- [ ] **CONDITIONAL** relations: Multiple STN branches with condition-based selection
- [ ] **FUZZY** relations: Cryptographic uncertainty modeling with `:crypto.strong_rand_bytes/1`
- [ ] **RESOURCE_BOUND/MUTEX** relations: Resource availability constraints

**Fuzzy Relations Implementation:**

```elixir
defmodule Timeline.FuzzyRelations do
  def fuzzy_to_stn_constraints(fuzzy_spec, confidence_level \\ 0.95) do
    case fuzzy_spec.uncertainty.type do
      :gaussian -> gaussian_bounds(fuzzy_spec, confidence_level)
      :uniform -> uniform_bounds(fuzzy_spec, confidence_level)
      :exponential -> exponential_bounds(fuzzy_spec, confidence_level)
    end
  end
end
```

### Phase 3: Oban-Based Temporal Relations (Week 2-3)

**Dependencies:**

```elixir
# apps/aria_temporal_planner/mix.exs
{:oban, "~> 2.17"},
{:ecto_sqlite3, "~> 0.12"}
```

**File:** `apps/aria_temporal_planner/lib/timeline/periodic_relations.ex`

- [ ] **PERIODIC** relations: Oban + SQLite scheduling for recurring patterns
- [ ] Support cron expressions, interval patterns, and custom schedules
- [ ] Integration with Timeline system for temporal instance generation

**File:** `apps/aria_temporal_planner/lib/timeline/event_relations.ex`

- [ ] **TRIGGERS/PREVENTS/ENABLES**: Oban event system for causal relationships
- [ ] **PREEMPTS/YIELDS**: Oban priority queue management
- [ ] **CASCADES**: Temporal interval modeling for event propagation

**File:** `apps/aria_temporal_planner/lib/timeline/multi_timeline_relations.ex`

- [ ] **MULTI_TIMELINE** coordination via shared Oban database
- [ ] **SYNCHRONIZED**: Identical events across multiple timelines
- [ ] **COORDINATED**: Cross-timeline event dependencies
- [ ] **REPLICATED**: Event replication across active timelines

### Phase 4: Probabilistic Relations (Week 3-4)

**Dependencies:**

```elixir
# apps/aria_temporal_planner/mix.exs
{:statistics, "~> 0.6.3"}
```

**Available Probability Distributions (via `statistics` library):**

- **Discrete**: Binomial, Poisson, Hypergeometric
- **Continuous**: Normal/Gaussian, Exponential, Beta, Chi-square, F, T
- **Custom Implementation**: Uniform (simple), Weibull, Gamma (if needed)

**File:** `apps/aria_temporal_planner/lib/timeline/probabilistic_relations.ex`

- [ ] **LIKELY_BEFORE**: P(X occurs before Y) = p using comparative distribution sampling
- [ ] **STOCHASTIC**: Random timing using `Statistics.Distributions` modules
- [ ] **DEPENDENT_PROBABILITY**: Conditional probability with Bayesian inference

**Implementation Strategy:**

```elixir
defmodule Timeline.ProbabilisticRelations do
  alias Statistics.Distributions.{Normal, Exponential, Poisson, Beta}
  
  def stochastic_timing(distribution_spec) do
    case distribution_spec.type do
      :normal -> Normal.rand(distribution_spec.mean, distribution_spec.std_dev)
      :exponential -> Exponential.rand(distribution_spec.lambda)
      :poisson -> Poisson.rand(distribution_spec.lambda)
      :beta -> Beta.rand(distribution_spec.alpha, distribution_spec.beta)
    end
  end
  
  def likely_before_probability(interval_a, interval_b, confidence) do
    # Monte Carlo simulation using distribution sampling
    samples = 10_000
    before_count = Enum.count(1..samples, fn _ ->
      a_time = sample_interval_timing(interval_a)
      b_time = sample_interval_timing(interval_b)
      a_time < b_time
    end)
    before_count / samples >= confidence
  end
end
```

### Phase 5: Integration and Testing (Week 4)

**File:** `apps/aria_temporal_planner/test/timeline/temporal_relations_test.exs`

- [ ] Comprehensive test suite for all relation types
- [ ] Contract validation tests preventing STN violations
- [ ] Performance benchmarks for Bridge layer processing
- [ ] Integration tests for Timeline → Bridge → STN flow

**File:** `apps/aria_temporal_planner/test/timeline/stn_consistency_test.exs`

- [ ] Fix all 28 failing STN consistency tests
- [ ] Validate proper Bridge filtering prevents contract violations
- [ ] Add regression tests for all temporal relation types

## Success Criteria

### Critical Success (Phase 1)

- [ ] All Allen relations implemented with language-neutral codes
- [ ] Zero-duration contract violations eliminated
- [ ] Bridge layer properly classifies and generates STN constraints
- [ ] All 28 STN consistency tests pass

### Functional Success (Phases 2-3)

- [ ] Extended relations (FLEXIBLE, CONDITIONAL, FUZZY) fully functional
- [ ] Oban-based relations (PERIODIC, TRIGGERS, MULTI_TIMELINE) operational
- [ ] Resource and priority relations working with STN constraints
- [ ] Multi-timeline coordination via Oban database

### Quality Success (Phases 4-5)

- [ ] Probabilistic relations implemented (library-dependent)
- [ ] Comprehensive test coverage for all relation types
- [ ] Performance optimization and error handling
- [ ] Complete documentation and internationalization

## Consequences

### Risks

- **High:** Complex implementation with multiple dependencies
- **Medium:** Performance impact from comprehensive Bridge layer processing
- **Low:** Potential breaking changes to existing temporal APIs

### Benefits

- **Critical:** Complete temporal reasoning capability
- **High:** Elimination of STN solver failures and architectural integrity
- **Medium:** Advanced scheduling and coordination features
- **Low:** Foundation for future temporal AI and planning enhancements

## Related ADRs

- **ADR-153**: STN Fixed-Point Constraint Prohibition (extracted from this ADR)
- **ADR-151**: Strict Encapsulation Modular Testing Architecture (interleaved implementation)
- **ADR-045**: Allen's Interval Algebra Temporal Relationships
- **ADR-046**: Interval Notation Usability

## Monitoring

- **Relation Coverage:** Percentage of temporal relations implemented
- **Test Stability:** STN consistency and temporal relation test pass rates
- **Performance:** Bridge layer processing overhead and optimization
- **Usage Patterns:** Which temporal relations are most frequently used

## Open Questions

### Probability Library Research

**Status:** RESOLVED - Use `statistics` library  
**Question:** Which Elixir probability library best supports our temporal modeling needs?  

**Research Results:**

1. **`statistics` v0.6.3** (RECOMMENDED)
   - **Downloads:** 1.1M total, 202K recent (very popular)
   - **Distributions:** Normal, Exponential, Poisson, Beta, Binomial, Chi-square, F, T, Hypergeometric
   - **Maintenance:** Active (last update Dec 2023)
   - **Dependencies:** Zero dependencies
   - **License:** Apache 2.0

2. **`numerix` v0.6.0** (Alternative)
   - **Downloads:** 157K total, lower recent activity
   - **Focus:** Linear algebra and machine learning (broader scope)
   - **Dependencies:** Requires `flow` library
   - **Maintenance:** Less active (last update Apr 2020)

**Decision:** Use `statistics` library for probabilistic temporal relations

- Covers all required distributions for temporal modeling
- High adoption and active maintenance
- Zero dependencies (clean integration)
- Focused specifically on statistics (not over-engineered)

**Implementation Update:**

```elixir
# apps/aria_temporal_planner/mix.exs
{:statistics, "~> 0.6.3"}
```

## Current Testing Status

### Test Failure Analysis (June 23, 2025)

**aria_temporal_planner:** 11 failures out of 181 tests (MAJOR IMPROVEMENT: 28→11)

- **Root Cause:** STN consistency checking logic issues after fixed-point constraint elimination
- **Pattern:** STNs with valid micro-range constraints marked as inconsistent
- **Impact:** Fixed-point contract violations resolved, but consistency detection needs repair
- **Progress:** All {0, 0} constraints eliminated, micro-ranges {-1, 1} implemented

**STN Fixed-Point Contract Issue:** ~~Extracted to ADR-153~~ **→ Moved to ADR-153**

**Detailed Analysis of STN Failures:**
The 28 STN consistency failures indicate a fundamental contract violation in the temporal constraint system. The failures occur because:

1. **Zero-Duration Contract Violation:** Zero-duration intervals are reaching the STN solver, which expects positive durations for temporal constraints. The STN solver cannot process constraints where start_time == end_time.

2. **Missing Bridge Layer Validation:** The Bridge layer (`apps/aria_temporal_planner/lib/timeline/bridge.ex`) is not properly filtering invalid temporal specifications before they reach the STN constraint generation.

3. **Cascading Consistency Failures:** Once one invalid constraint enters the STN system, it causes the entire constraint network to become inconsistent (`consistent: false`), affecting all subsequent temporal reasoning.

4. **Timeline Structure Corruption:** The Timeline data structures show `stn.consistent: false` because the underlying STN solver rejects the constraint set, making all temporal operations unreliable.

**Technical Root Cause:** The issue stems from the architectural gap between high-level temporal specifications (which may include zero durations for instantaneous events) and the STN solver's mathematical requirements (which need positive duration constraints for temporal reasoning).

**aria_scheduler:** 8 failures out of 13 tests  

- **Root Cause:** Missing AriaEngine.PlannerAdapter dependency
- **Error:** "plan_tasks requires full AriaEngine.PlannerAdapter from aria_hybrid_planner"
- **Impact:** Scheduler cannot execute enhanced planning

**Detailed Analysis of Scheduler Failures:**
The scheduler failures are architectural dependency issues:

1. **Cross-App Dependency Missing:** The scheduler expects `AriaEngine.PlannerAdapter` from `aria_hybrid_planner` but the module is not properly exposed or implemented.

2. **Interface Contract Mismatch:** The scheduler's `plan_tasks/2` function requires a "full" PlannerAdapter implementation, suggesting the current implementation is incomplete or stub-only.

3. **Integration Layer Broken:** The connection between the scheduler (which handles task execution timing) and the hybrid planner (which generates task sequences) is severed.

4. **Cascading Planning Failures:** Without the PlannerAdapter, the scheduler cannot convert high-level planning goals into executable task schedules, breaking the entire planning pipeline.

**Technical Root Cause:** This represents an incomplete extraction during the modularization process where the scheduler was separated from the hybrid planner but the interface contracts were not properly maintained.

**aria_hybrid_planner:** No tests available

- **Status:** "There are no tests to run"
- **Issue:** Missing test suite entirely

**Detailed Analysis of Missing Tests:**
The complete absence of tests in aria_hybrid_planner indicates:

1. **Incomplete Modularization:** During the extraction process (likely from ADR-150), the test suite was not properly migrated to the new app structure.

2. **Hidden Functionality Gaps:** Without tests, it's impossible to verify that the PlannerAdapter and other hybrid planner components are actually functional.

3. **Integration Risk:** The missing tests mean that changes to the hybrid planner cannot be validated, creating risk for the scheduler and other dependent systems.

4. **Quality Assurance Gap:** The hybrid planner is a critical component for multi-goal optimization and temporal planning, but has no automated verification.

**Technical Root Cause:** Test migration was incomplete during the app extraction process, leaving the hybrid planner without quality assurance coverage.

**aria_engine_core:** Compilation warnings only

- **Status:** Compiles but has unused variable warnings
- **Impact:** Low priority cleanup needed

**Detailed Analysis of Engine Core Warnings:**
The compilation warnings in aria_engine_core are maintenance issues:

1. **Code Cleanup Needed:** Unused variables suggest incomplete refactoring or dead code that should be removed.

2. **Potential Hidden Issues:** While warnings don't break functionality, they can mask more serious problems and indicate incomplete implementation.

3. **Development Hygiene:** Warnings in core components reduce confidence in code quality and can accumulate over time.

**Technical Root Cause:** Incomplete cleanup during recent refactoring activities, likely related to the modularization efforts in ADR-150 and ADR-151.

### Testing Strategy for ADR-152

**Phase 1 Testing Priority:**

1. **Fix STN consistency failures** in aria_temporal_planner (28 tests)
2. **Implement Bridge layer** zero-duration filtering
3. **Validate contract enforcement** prevents STN violations

**Phase 2-5 Testing:**

- Add comprehensive test coverage for new temporal relations
- Integration testing across apps once dependencies are resolved
- Performance benchmarking for Bridge layer processing

## Notes

This represents a fundamental expansion of the temporal reasoning system from basic Allen relations to a comprehensive temporal modeling framework. The implementation prioritizes STN-compatible relations while providing clear extension points for advanced temporal reasoning capabilities.

**Implementation Priority:** Phase 1 (core relations and contract violation fixes) takes immediate precedence, followed by systematic implementation of extended capabilities.

**Critical Path:** The 28 STN consistency test failures in aria_temporal_planner must be resolved first, as they block all temporal reasoning functionality across the entire system.

## Rejected Alternatives (Tombstones)

### Constraint Solvers

- ~~**fixpoint** (6.7K downloads)~~ - Inferior to MiniZinc (2024 competition results prove MiniZinc superiority for constraint programming)
- ~~**furlong** (Cassowary/Kiwi solver)~~ - Incremental constraint solving not needed for STN problems; MiniZinc handles temporal constraints more efficiently
- ~~**exhort** (Google OR-Tools wrapper)~~ - Overkill for temporal constraints; MiniZinc more specialized and faster for our use case
- ~~**Pure Elixir CSP libraries**~~ - Performance inferior to MiniZinc's optimized constraint solving engine

### Numerical Computing Alternatives

- ~~**Nx ecosystem** (nx + exla + polaris + scholar)~~ - Over-engineered for basic probability distributions; `statistics` library more focused and lightweight
- ~~**scholar** (ML on Nx)~~ - Machine learning capabilities not needed for basic probability distributions and temporal modeling
- ~~**polaris** (Nx optimizers)~~ - Optimization framework unnecessary when `statistics` provides direct distribution sampling

### Probability Libraries

- ~~**numerix**~~ - Less active maintenance (last update 2020), additional dependencies vs. `statistics` library
- ~~**Custom probability implementations**~~ - Reinventing the wheel when `statistics` provides proven, well-tested distributions

### Rationale for Current Stack

**MiniZinc** remains the optimal constraint solver:

- Proven fastest in 2024 MiniZinc Challenge competition
- Specialized for constraint satisfaction problems
- Superior performance for STN temporal constraint solving

**`statistics` library** optimal for probabilistic relations:

- 1.1M downloads, actively maintained (Dec 2023)
- Zero dependencies, clean integration
- Focused specifically on statistical distributions
- Covers all required distributions: Normal, Exponential, Poisson, Beta, Binomial, etc.

**Oban** optimal for event-based relations:

- Battle-tested in production Elixir applications
- Built-in scheduling, priority queues, and persistence
- Superior to custom event systems for PERIODIC, TRIGGERS, MULTI_TIMELINE relations

This tombstones section prevents future reconsideration of inferior alternatives and documents the research that confirmed our current technical choices are optimal.
