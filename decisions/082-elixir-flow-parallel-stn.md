# ADR-082: Elixir Flow Parallel STN Processing

**Status:** Active (June 16, 2025)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related activities in this document are purely fictional game planning scenarios for the Aria character temporal reasoning system. These are not related to any real military events, actual operations, or real-world situations. This is entertainment software development for a fictional character AI system.

## Context

STN constraint propagation in the PC-2 algorithm is embarrassingly parallel, with each (i,j,k) triple in the path consistency algorithm processable independently. Elixir Flow provides GPU-style parallel processing patterns that can significantly reduce wall-clock time for large constraint networks.

Reference: [Elixir Flow Documentation](https://hexdocs.pm/flow/Flow.html)

## Decision

Implement GPU-style parallel STN constraint solving using Elixir Flow, providing multiple parallelization strategies to optimize performance across different constraint network sizes and system configurations.

## Implementation Plan

### Phase 1: Parallel STN Module Foundation

- [ ] Create `AriaEngine.Timeline.ParallelSTN` module
- [ ] Implement `solve_parallel_pc2/2` with Flow-based parallelization
- [ ] Add configurable concurrency and batch size parameters
- [ ] Create parallel constraint propagation pipeline

### Phase 2: Parallelization Strategies

- [ ] **Constraint Propagation Parallelization** - Independent (i,j,k) triple processing
- [ ] **Segment-Based Solving** - Parallel processing of temporal window segments
- [ ] **Agent-Based Decomposition** - Independent agent constraint network solving
- [ ] **Pipeline-Based Processing** - Streaming constraint update processing

### Phase 3: Flow Pipeline Implementation

- [ ] Implement triple generation with `Flow.from_enumerable/2`
- [ ] Add parallel constraint propagation with `Flow.map/2`
- [ ] Create constraint matrix merging with `Flow.reduce/3`  
- [ ] Add inconsistency detection across parallel streams

### Phase 4: Performance Optimization

- [ ] Implement dynamic work balancing based on constraint density
- [ ] Add NUMA-aware processing for multi-socket systems
- [ ] Create adaptive batch sizing based on network complexity
- [ ] Add parallel processing fallback for small networks

### Phase 5: Integration with Constant Work Pattern

- [ ] Combine Flow parallelization with constant work sizing
- [ ] Implement parallel dummy constraint processing
- [ ] Add distributed constraint propagation across worker pools
- [ ] Create hybrid serial/parallel execution strategies

## Implementation Details

### GPU-Style Parallel Processing Architecture

```elixir
# Parallel PC-2 implementation using Flow
def solve_parallel_pc2_flow(constraint_network, max_concurrency) do
  max_size = constraint_network.max_network_size
  
  # Generate all (i,j,k) triples for parallel processing
  triples = for k <- 0..(max_size-1), 
                j <- 0..(max_size-1), 
                i <- 0..(max_size-1), 
                do: {i, j, k}
  
  # Process triples in parallel using Flow
  triples
  |> Flow.from_enumerable(max_demand: 100)
  |> Flow.partition(stages: max_concurrency)
  |> Flow.map(fn {i, j, k} -> 
       propagate_constraint_parallel(constraint_network, i, j, k) 
     end)
  |> Flow.partition(stages: 1)  # Merge results
  |> Flow.reduce(fn -> %{} end, fn update, acc -> 
       merge_constraint_updates(acc, update) 
     end)
  |> Enum.to_list()
end
```

### Parallelization Strategy Selection

- **Small networks (< 32 timepoints)**: Serial processing (parallel overhead not justified)
- **Medium networks (32-128 timepoints)**: Constraint propagation parallelization
- **Large networks (128+ timepoints)**: Segmentation + parallel processing
- **Multi-agent scenarios**: Agent-based decomposition + parallel solving

## Success Criteria

- Parallel processing reduces wall-clock time for large constraint networks
- Flow integration provides configurable concurrency control
- Multiple parallelization strategies optimize different scenario types
- Performance scales appropriately with available CPU cores

## Consequences

**Positive:**

- Significant performance improvement for large constraint networks
- Scalable performance based on available system resources
- GPU-style parallel processing patterns adapted for STN solving
- Flexible parallelization strategies for different use cases

**Risks:**

- Parallel processing overhead for small constraint networks
- Complexity in constraint matrix merging and synchronization
- Potential for increased memory usage during parallel processing
- Need for careful tuning of concurrency parameters

## Related ADRs

- **ADR-080**: STN Performance Benchmarking Framework
- **ADR-081**: AWS Constant Work Pattern for STN Solving
- **ADR-083**: STN Timeline Segmentation Strategy
