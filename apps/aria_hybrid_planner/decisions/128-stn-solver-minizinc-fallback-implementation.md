# ADR-128: STN Solver MiniZinc Fallback Implementation

<!-- @adr_serial R25V005A13A -->

**Status:** Paused  
**Date:** 2025-06-22  
**Implementation Start:** 2025-06-22  
**Paused:** 2025-06-22  
**Priority:** HIGH  
**Phase:** Implementation (Paused)  

## Context

The current STN (Simple Temporal Network) solver in `AriaEngine.Timeline.Internal.STN.MiniZincSolver` relies exclusively on MiniZinc for temporal constraint solving. When MiniZinc is unavailable, the solver simply marks the STN as inconsistent and fails completely, making the entire temporal planning system non-functional.

### Current Problem

```elixir
# Current failure behavior in MiniZincSolver.solve_stn/1
{:error, _reason} ->
  # Fall back to marking as inconsistent
  %{stn | consistent: false}
```

**Critical Issues:**

- **Complete System Failure**: Timeline scheduling becomes impossible when MiniZinc unavailable
- **No Graceful Degradation**: System fails hard rather than falling back to alternative solving
- **Production Risk**: Deployment environments may not have MiniZinc properly configured
- **Development Friction**: Local development blocked when MiniZinc installation issues occur

### Comparison with Multigoal Optimization

ADR-126 successfully implemented MiniZinc fallback for multigoal optimization with excellent results:

- **Hierarchical solver strategy**: MiniZinc → naive splitting → manual decomposition
- **100% fallback success rate**: System never fails completely
- **Graceful degradation**: Reduced functionality but continued operation
- **Method blacklisting**: Automatic fallback when primary solver fails

The STN solver needs similar robustness for temporal reasoning operations.

## Implementation Progress

**Current Phase:** Phase 1 - Core Floyd-Warshall STN Solver  
**Started:** June 22, 2025  
**Focus:** Implementing core Floyd-Warshall algorithm for STN constraint solving

### Phase 1 Progress

- [ ] Algorithm research and mathematical validation
- [ ] Core FloydWarshallSolver module implementation  
- [ ] Distance matrix conversion functions
- [ ] Negative cycle detection logic
- [ ] Solution extraction and STN integration
- [ ] Comprehensive test suite for Floyd-Warshall solver

### Implementation Notes

*Implementation progress and discoveries will be documented here as work proceeds.*

## Decision

Implement hierarchical STN solver strategy with Floyd-Warshall algorithm as the primary fallback for MiniZinc constraint solving.

### Architecture

**Hierarchical STN Solver Strategy:**

1. **Primary**: MiniZinc constraint solver (existing)
2. **Fallback**: Floyd-Warshall based STN solver (new)
3. **Final Fallback**: Conservative consistency checking (new)

**Integration Strategy:**

- Follow ADR-126 pattern for fallback implementation
- Use method blacklisting for automatic fallback
- Maintain backward compatibility with existing Timeline API
- Add configuration options for fallback behavior

## Implementation Plan

### Phase 1: Core Floyd-Warshall STN Solver (HIGH PRIORITY)

**File**: `lib/aria_engine/timeline/internal/stn/floyd_warshall_solver.ex`

**Core Algorithm Implementation:**

- [ ] Convert STN constraints to distance matrix representation
- [ ] Implement Floyd-Warshall algorithm for shortest path computation
- [ ] Add negative cycle detection for inconsistency identification
- [ ] Extract solved constraints back to STN format
- [ ] Handle infinite constraints and boundary conditions

**Key Functions:**

```elixir
@spec solve_stn(STN.t()) :: STN.t()
def solve_stn(stn)

@spec convert_to_distance_matrix(STN.t()) :: {matrix(), point_map()}
defp convert_to_distance_matrix(stn)

@spec floyd_warshall(matrix()) :: {matrix(), boolean()}
defp floyd_warshall(distance_matrix)

@spec extract_solution(matrix(), point_map(), STN.t()) :: STN.t()
defp extract_solution(solved_matrix, point_map, original_stn)
```

### Phase 2: Fallback Integration System (HIGH PRIORITY)

**File**: `lib/aria_engine/timeline/internal/stn/fallback_solver.ex`

**Hierarchical Solver Orchestration:**

- [ ] Implement solver method selection and blacklisting
- [ ] Add timeout handling for each solver attempt
- [ ] Create unified interface for Timeline module integration
- [ ] Add telemetry and logging for fallback triggers

**Solver Strategy Implementation:**

```elixir
@spec solve_with_fallback(STN.t(), keyword()) :: STN.t()
def solve_with_fallback(stn, opts \\ [])

@spec try_minizinc_solver(STN.t(), keyword()) :: {:ok, STN.t()} | {:error, term()}
defp try_minizinc_solver(stn, opts)

@spec try_floyd_warshall_solver(STN.t(), keyword()) :: {:ok, STN.t()} | {:error, term()}
defp try_floyd_warshall_solver(stn, opts)

@spec try_conservative_solver(STN.t(), keyword()) :: {:ok, STN.t()}
defp try_conservative_solver(stn, opts)
```

### Phase 3: Enhanced Operations Integration (MEDIUM PRIORITY)

**File**: `lib/aria_engine/timeline/internal/stn/operations.ex`

**Update Existing solve/1 Function:**

- [ ] Replace direct MiniZinc calls with hierarchical fallback system
- [ ] Add configuration options for solver preferences
- [ ] Implement performance monitoring and metrics collection
- [ ] Add solver method blacklisting persistence

**Configuration Options:**

```elixir
stn_solver_opts = [
  primary_solver: :minizinc,
  fallback_enabled: true,
  minizinc_timeout: 5_000,
  floyd_warshall_timeout: 1_000,
  conservative_fallback: true,
  telemetry_enabled: true,
  method_blacklist_ttl: 300_000  # 5 minutes
]
```

### Phase 4: Conservative Consistency Checker (LOW PRIORITY)

**File**: `lib/aria_engine/timeline/internal/stn/conservative_solver.ex`

**Basic Consistency Validation:**

- [ ] Implement simple constraint validation without full solving
- [ ] Detect obviously inconsistent constraints (negative cycles)
- [ ] Provide conservative estimates for constraint tightening
- [ ] Ensure system continues with reduced functionality

## Technical Specifications

### Floyd-Warshall Algorithm Adaptation

**STN Constraint Representation:**

- Convert STN constraints `{min_distance, max_distance}` to distance matrix
- Handle infinite constraints as matrix boundary values
- Use negative cycle detection to identify temporal inconsistencies
- Extract tightened constraints from solved shortest path matrix

**Performance Characteristics:**

- **Time Complexity**: O(n³) where n = number of time points
- **Space Complexity**: O(n²) for distance matrix storage
- **Target Performance**: <100ms for typical STN sizes (<50 time points)
- **Scalability**: Parallelizable for larger constraint networks

**Algorithm Implementation:**

```elixir
# Distance matrix initialization
for i <- 1..n, j <- 1..n do
  if i == j, do: 0, else: infinity
end

# Floyd-Warshall core algorithm
for k <- 1..n, i <- 1..n, j <- 1..n do
  if dist[i][k] + dist[k][j] < dist[i][j] do
    dist[i][j] = dist[i][k] + dist[k][j]
  end
end

# Negative cycle detection
for i <- 1..n do
  if dist[i][i] < 0, do: {:error, :inconsistent}
end
```

### Integration Points

**Timeline Module Integration:**

- `Timeline.solve/1` - Primary entry point using hierarchical fallback
- `STN.solve/1` - Internal STN solving with method selection
- Configuration system for solver preferences and timeouts
- Telemetry events for monitoring solver performance

**Fallback Triggers:**

- **MiniZinc Unavailable**: Binary not installed or accessible
- **MiniZinc Timeout**: Constraint solving exceeds configured timeout
- **MiniZinc Execution Error**: Solver returns error status or crashes
- **Template Rendering Error**: EEx template processing fails

**Fallback Behavior:**

1. **Method Blacklisting**: Failed solver method blacklisted for current session
2. **Automatic Retry**: System automatically tries next available solver
3. **Graceful Degradation**: Reduced solving capability but continued operation
4. **Error Logging**: Solver failures logged for debugging and monitoring

## Success Criteria

### Functional Requirements

- [ ] **100% Fallback Success Rate**: STN solving never fails completely due to MiniZinc unavailability
- [ ] **Mathematical Correctness**: Floyd-Warshall solver produces correct temporal constraint solutions
- [ ] **Consistency Guarantee**: Fallback solvers correctly identify inconsistent temporal networks
- [ ] **Zero Breaking Changes**: Existing Timeline API remains unchanged
- [ ] **Configuration Flexibility**: Runtime control over solver selection and fallback behavior

### Performance Requirements

- [ ] **Floyd-Warshall Performance**: <100ms solving time for typical STN sizes (<50 time points)
- [ ] **Fallback Overhead**: <10ms additional latency for solver selection logic
- [ ] **Memory Efficiency**: Distance matrix operations within reasonable memory bounds
- [ ] **Scalability**: Graceful performance degradation for larger constraint networks

### Robustness Requirements

- [ ] **Comprehensive Testing**: All STN operations work correctly with both solvers
- [ ] **Edge Case Handling**: Proper handling of infinite constraints, self-loops, empty STNs
- [ ] **Error Recovery**: Graceful handling of solver failures and timeouts
- [ ] **Production Monitoring**: Telemetry and logging for solver performance and fallback rates

## Test Scenarios

### Scenario 1: MiniZinc Unavailable

```
Initial State:
- MiniZinc binary not installed or accessible
- STN with valid temporal constraints

Expected Behavior:
- Primary solver fails immediately
- Floyd-Warshall solver activated automatically
- STN solved correctly with fallback algorithm
- System continues normal operation
```

### Scenario 2: MiniZinc Timeout

```
Initial State:
- Complex STN with many constraints
- MiniZinc solver exceeds timeout threshold

Expected Behavior:
- MiniZinc solver terminated after timeout
- Floyd-Warshall solver attempts solution
- If successful, STN marked as consistent
- Performance metrics logged for analysis
```

### Scenario 3: Inconsistent Temporal Network

```
Initial State:
- STN with contradictory temporal constraints
- Negative cycle in constraint graph

Expected Behavior:
- Both solvers detect inconsistency
- STN marked as consistent: false
- Negative cycle information preserved
- System handles inconsistency gracefully
```

### Scenario 4: Large Constraint Network

```
Initial State:
- STN with >100 time points and constraints
- Performance stress test scenario

Expected Behavior:
- MiniZinc solver preferred for complex problems
- Floyd-Warshall fallback if MiniZinc fails
- Conservative solver as final fallback
- Performance monitoring captures metrics
```

## Consequences

### Benefits

- **System Reliability**: Temporal planning system remains functional when MiniZinc unavailable
- **Deployment Flexibility**: Reduced dependency on external solver installation
- **Development Experience**: Local development continues despite MiniZinc configuration issues
- **Performance Predictability**: Floyd-Warshall provides consistent O(n³) performance
- **Mathematical Soundness**: Proven algorithm ensures correct temporal constraint solving

### Risks

**Implementation Complexity:**

- Floyd-Warshall algorithm requires careful implementation for STN constraints
- Distance matrix conversion must handle infinite and boundary constraints correctly
- Integration with existing STN data structures needs thorough testing

**Performance Considerations:**

- O(n³) complexity may be slower than MiniZinc for very large constraint networks
- Memory usage increases quadratically with number of time points
- Fallback overhead adds latency to solver selection process

**Maintenance Overhead:**

- Multiple solver implementations require ongoing maintenance
- Test coverage must validate all solver combinations
- Configuration complexity increases with multiple fallback options

### Mitigation Strategies

**Algorithm Correctness:**

- Comprehensive test suite with known STN problems and solutions
- Mathematical validation against temporal reasoning literature
- Edge case testing for boundary conditions and infinite constraints

**Performance Optimization:**

- Parallel processing for large constraint networks using `Task.async_stream/3`
- Memory optimization for distance matrix operations
- Performance benchmarking and profiling for typical use cases

**Integration Testing:**

- End-to-end testing with Timeline module operations
- Stress testing with various STN sizes and complexity levels
- Production monitoring to track solver performance and fallback rates

## Related ADRs

- **ADR-126**: MiniZinc Multigoal Optimization with Fallback (fallback pattern reference)
- **ADR-078**: Timeline Module PC-2 STN Implementation (STN solver architecture)
- **ADR-040**: Temporal Constraint Solver Selection (solver requirements)
- **ADR-075**: Complete Temporal Planner Architecture (temporal planning context)

## Implementation Strategy

### Current Focus: Phase 1 - Core Floyd-Warshall Implementation

**Immediate Priority:**

1. **Algorithm Research**: Review Floyd-Warshall adaptations for temporal constraint networks
2. **Core Implementation**: Create `FloydWarshallSolver` module with distance matrix operations
3. **Mathematical Validation**: Test against known STN problems with verified solutions
4. **Performance Benchmarking**: Establish baseline performance characteristics

**Success Metrics for Phase 1:**

- Floyd-Warshall solver correctly solves all test STN problems
- Performance meets <100ms target for typical constraint network sizes
- Negative cycle detection accurately identifies inconsistent temporal networks
- Solution extraction produces mathematically correct constraint tightening

The proven success of ADR-126's fallback system provides a solid foundation for this implementation. The Floyd-Warshall approach offers excellent performance characteristics for Elixir while ensuring the temporal planning system remains robust and reliable even when MiniZinc is unavailable.
