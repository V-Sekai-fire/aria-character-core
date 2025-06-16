# ADR-081: AWS Constant Work Pattern for STN Solving

**Status:** Active (June 16, 2025)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related activities in this document are purely fictional game planning scenarios for the Aria character temporal reasoning system. These are not related to any real military events, actual operations, or real-world situations. This is entertainment software development for a fictional character AI system.

## Context

STN solving performance varies significantly based on constraint network size, creating unpredictable response times that can impact real-time temporal reasoning. The AWS "constant work" pattern provides a proven approach for eliminating performance variance in distributed systems.

Reference: [AWS Builders Library - Reliability and Constant Work](https://aws.amazon.com/builders-library/reliability-and-constant-work/)

## Decision

Implement the AWS constant work pattern for STN constraint solving, ensuring predictable performance regardless of actual constraint network complexity by always processing maximum-sized networks with dummy constraints.

## Implementation Plan

### Phase 1: Constant Work STN Module

- [ ] Create `AriaEngine.Timeline.ConstantWorkSTN` module
- [ ] Implement pre-allocated constraint network structures
- [ ] Add dummy constraint padding for maximum network sizes
- [ ] Create scenario-based network size configurations

### Phase 2: Constant Work PC-2 Algorithm

- [ ] Implement `solve_constant_work/1` that always processes max_size³ operations
- [ ] Add `apply_pc2_constant_work/2` with fixed operation count
- [ ] Create constraint propagation that handles real and dummy constraints uniformly
- [ ] Add active/dummy constraint masking system

### Phase 3: Integration and Validation

- [ ] Implement `add_real_constraints/3` for constant work insertion
- [ ] Create fictional game scenario examples with constant work sizing
- [ ] Add performance characteristics comparison documentation
- [ ] Validate anti-fragile properties under system stress

### Phase 4: Scenario-Specific Optimizations

- [ ] Configure maximum sizes for different game scenarios:
  - Single agent: 32 timepoints (target: <0.3ms)
  - Dual agent: 64 timepoints (target: <2.6ms)
  - Squad: 128 timepoints (target: <21ms)
  - Full mission: 256 timepoints (target: TBD)

## Implementation Details

### Key Principles Applied to STN Solving

1. **Fixed-size processing** - Always process maximum expected constraint network size
2. **Constant computational work** - Maintain identical operation count per solving cycle
3. **Pre-allocated structures** - Eliminate dynamic memory allocation during solving
4. **Dummy constraint padding** - Use neutral constraints to fill unused network positions
5. **Performance variance elimination** - Remove dependency on actual constraint count

### Anti-Fragile Properties

- **System overload** → Dummy constraints act as no-ops → Less real computational work
- **Memory pressure** → Zero additional allocations needed during solving
- **High constraint density** → Still processes in predictable constant time
- **System stress** → Performance remains constant, doesn't degrade

## Success Criteria

- STN solving time becomes predictable regardless of constraint network size
- Performance variance eliminated across different fictional game scenarios
- Memory allocation becomes constant (no GC pressure during solving)
- System demonstrates anti-fragile behavior under stress conditions

## Consequences

**Positive:**

- Predictable real-time performance for temporal reasoning
- Elimination of performance spikes from dynamic constraint changes
- Anti-fragile behavior under system stress
- Simplified performance monitoring and capacity planning

**Risks:**

- Higher baseline computational cost for simple scenarios
- Increased memory usage for small constraint networks
- Complexity in mapping real constraints to pre-allocated structures

## Related ADRs

- **ADR-080**: STN Performance Benchmarking Framework
- **ADR-082**: Elixir Flow Parallel STN Processing  
- **ADR-083**: STN Timeline Segmentation Strategy
