# ADR-002: Oban Queue Design

## Status

Accepted

## Date

2025-06-13

## Context

The temporal planner requires different queuing strategies based on time ordering constraints.
Some operations must execute sequentially to maintain temporal correctness, while others can execute in parallel for performance.

## Decision

Use separate Oban queues based on time ordering constraints - sequential operations use single-worker queues, parallel operations use multi-worker queues.

## Rationale

- Time-dependent operations require strict ordering to prevent race conditions
- Order-independent operations can execute concurrently for better performance
- Immediate responses need high-priority handling for player feedback
- Clear separation of concerns based on ordering requirements

## Consequences

### Positive

- Temporal correctness through sequential queue
- Performance optimization through parallel execution
- Responsive player feedback via instant queue
- Predictable ordering guarantees

### Negative

- Additional complexity with multiple queue management
- Configuration overhead for queue setup

## Implementation Details

### Queue Architecture

- **`sequential_actions` Queue**: Single worker (concurrency: 1)

  - Use Case: Actions that must execute in exact temporal order
  - Examples: Agent movement chains, skill combos with timing dependencies
  - Worker Count: 1 (prevents race conditions)

- **`parallel_actions` Queue**: Multi-worker (concurrency: 5)

  - Use Case: Order-independent operations
  - Examples: Independent agent movements, environmental effects
  - Worker Count: 5 (concurrent execution)

- **`instant_actions` Queue**: High-priority (concurrency: 3)
  - Use Case: Immediate responses
  - Examples: SPACEBAR interrupts, goal changes
  - Worker Count: 3 (responsive but controlled)

### Configuration

```elixir
config :aria_queue, Oban,
  repo: AriaData.QueueRepo,
  notifier: Oban.Notifiers.PG,
  queues: [
    sequential_actions: 1,
    parallel_actions: 5,
    instant_actions: 3
  ]
```

## Related Decisions

- **Builds on**: ADR-001 (State Architecture Migration) - requires temporal state for time-ordered actions
- **Links to**: ADR-006 (Game Engine Integration) - queues execute actions at precise game ticks
- **Supports**: ADR-011 (Idempotency & Intent Rejection) - queue design enables graceful action cancellation
- **Enables**: ADR-025 (Research Strategy) - provides testable job scheduling for precision validation
