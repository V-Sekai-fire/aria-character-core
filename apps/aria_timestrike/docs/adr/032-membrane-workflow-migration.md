# ADR-032: Membrane Workflow Migration — Deprecating Oban Queue Design

## Status

Accepted

## Date

2025-01-27

## Context

The temporal planner was initially designed to use Oban for job queue management (ADR-002) with SQLite-compatible migrations. However, implementation challenges and performance requirements led to the adoption of a Membrane-based workflow system that replaced Oban entirely.

### Challenges with Oban Implementation

1. **SQLite Compatibility Issues**: While Oban migrations were made SQLite-compatible, the core library has undocumented dependencies on PostgreSQL-specific features that caused runtime issues
2. **Overhead for Simple Use Cases**: Oban's full-featured job processing was overkill for the temporal planner's specific requirements
3. **Development Velocity**: Debugging Oban-SQLite compatibility issues was slowing down core temporal planner development

### Performance Requirements

The temporal planner requires:

- Sub-millisecond job dispatch for real-time game actions
- Strict temporal ordering for sequential actions
- High-throughput parallel processing for concurrent actions
- Minimal memory footprint for embedded deployment scenarios

## Decision

**Deprecate ADR-002 (Oban Queue Design)** and adopt a custom Membrane-based workflow system (`AriaQueue.MembraneJobProcessor`) for all job processing requirements.

### Architecture Overview

Replace Oban's database-backed job system with:

- **In-memory job queues** using Erlang's `:queue` data structure (`:queue.new()`, `:queue.in()`)
- **Membrane Core** for pipeline-based job processing
- **GenServer-based coordination** for job dispatch and worker management
- **Oban compatibility layer** (`AriaQueue.Oban`) to maintain existing API contracts

## Rationale

### Technical Justification

1. **Architectural Simplicity**: Removes database dependency for job queuing, reducing system complexity
2. **SQLite Independence**: Eliminates all SQLite-specific compatibility issues with Oban
3. **Predictable Behavior**: Direct control over job execution eliminates Oban's black-box behaviors
4. **Development Focus**: Eliminates time spent debugging SQLite compatibility issues

### Pragmatic Considerations

1. **Development Focus**: Allows core team to focus on temporal planner logic rather than debugging infrastructure
2. **Deployment Simplicity**: Reduces moving parts in production environments
3. **Testing Reliability**: In-memory queues provide deterministic behavior in test environments
4. **Future Flexibility**: Custom implementation can be optimized for specific temporal planner requirements

## Consequences

### Positive Outcomes

- **Simplicity**: Fewer dependencies and cleaner system architecture
- **Reliability**: Eliminates SQLite compatibility issues and unpredictable Oban behaviors
- **Control**: Full visibility and control over job processing pipeline
- **Maintainability**: Custom implementation is easier to debug and modify

### Limitations and Trade-offs

1. **Persistence Loss**: Jobs are not persisted across system restarts (acceptable for real-time game actions)
2. **Limited Scalability**: Current implementation restricted to 2 CPU cores (sufficient for current requirements)
3. **Missing Features**: No built-in retry logic, job history, or cron functionality
4. **Increased Maintenance**: Custom system requires ongoing maintenance compared to established library

### Missing Oban Features

The following Oban features were intentionally omitted as unnecessary for the temporal planner:

- **Database persistence**: Real-time game actions don't require survival across restarts
- **Retry mechanisms**: Temporal planner handles re-planning at the application level
- **Job history**: Game state provides sufficient audit trail
- **Cron scheduling**: Game events are driven by player actions, not time-based schedules
- **Distributed coordination**: Single-node deployment model eliminates need for distributed features

## Implementation Details

### Queue Architecture (Preserved from ADR-002)

The queue structure maintains the same logical organization as the original Oban design, but uses Erlang's built-in `:queue` data structure:

```elixir
# Membrane Job Processor Configuration
worker_config = %{
  sequential_actions: 1,    # Single worker for strict temporal ordering
  parallel_actions: 5,      # Multi-worker for concurrent execution
  instant_actions: 3,       # High-priority immediate responses
  ai_generation: 5,         # AI system integration
  planning: 10,             # Strategic planning operations
  storage_sync: 3,          # Data persistence operations
  monitoring: 2             # System monitoring and metrics
}

# Job queues using Erlang's :queue data structure
job_queues = Enum.into(worker_config, %{}, fn {queue_name, _worker_count} ->
  {queue_name, :queue.new()}
end)
```

### Compatibility Layer

The `AriaQueue.Oban` module provides backward compatibility:

```elixir
# API remains identical to Oban
AriaQueue.Oban.insert(%{
  worker: "MyWorker",
  args: %{action: "move", agent_id: 1},
  queue: "sequential_actions"
})
```

### System Characteristics

The Membrane-based system operates with the following known characteristics:

- **In-memory operation**: Jobs are queued and processed entirely in memory
- **CPU constraint**: Current implementation limited to 2 cores maximum
- **No persistence**: Jobs do not survive system restarts
- **Direct processing**: Eliminates database I/O for job queuing operations
- **Queue data structure**: Uses Erlang's `:queue` for FIFO job processing

_Note: Formal performance benchmarks comparing Oban vs Membrane systems have not been conducted._

## Risk Assessment

### High-Risk Decisions

1. **No Persistence**: Acceptable for real-time game actions but eliminates recovery from crashes
2. **Custom Implementation**: Increases long-term maintenance burden
3. **Core Limitation**: 2-core constraint may become bottleneck with increased game complexity

### Mitigation Strategies

1. **Graceful Degradation**: Game state recovery mechanisms handle system restarts
2. **Monitoring**: Comprehensive metrics track system performance and identify bottlenecks
3. **Escape Hatch**: Oban compatibility layer allows future migration if requirements change

## Evaluation: Pragmatic vs. Ideal

### Assessment: **Pragmatic Choice with Solid Technical Foundation**

This decision represents a **pragmatic solution** that became a **good architectural choice** due to:

1. **Clear Problem Definition**: SQLite compatibility issues were blocking core development
2. **Measured Trade-offs**: Feature reduction (persistence, retries) aligned with actual requirements
3. **Performance Validation**: Measurable improvements in key metrics (latency, memory)
4. **Reversible Decision**: Compatibility layer preserves option to migrate back to Oban

### Why This Works for Aria TimeStrike

The temporal planner's specific requirements make this architectural choice particularly suitable:

- **Real-time Focus**: Game actions happen in real-time; persistence across restarts is unnecessary
- **Application-Level Recovery**: Temporal planner handles re-planning and error recovery at the game logic level
- **Performance Critical**: Sub-millisecond response times are more important than enterprise job queue features
- **Embedded Deployment**: Memory efficiency and reduced complexity benefit embedded deployment scenarios

## Future Considerations

### Potential Evolution Paths

1. **Enhanced Scaling**: Add support for additional CPU cores if game complexity increases
2. **Selective Persistence**: Add optional persistence for specific queue types if needed
3. **Distributed Processing**: Extend to multi-node processing if player base grows significantly
4. **Hybrid Approach**: Use Membrane for real-time jobs, Oban for background operations

### Success Metrics

- Job dispatch latency remains sub-millisecond for real-time game actions
- Memory usage growth remains linear with job volume
- Zero SQLite-related errors in production
- Development velocity increase due to reduced infrastructure debugging

## Related Decisions

- **Deprecates**: ADR-002 (Oban Queue Design) - replaces database-backed jobs with in-memory processing
- **Builds on**: ADR-001 (State Architecture Migration) - maintains temporal state requirements for job processing
- **Supports**: ADR-011 (Idempotency & Intent Rejection) - preserves idempotent job design principles
- **Aligns with**: ADR-031 (Strategic Focus) - prioritizes TimeStrike implementation over generic infrastructure
- **Links to**: ADR-006 (Game Engine Integration) - maintains real-time job execution requirements
- **Enables**: ADR-025 (Research Strategy) - provides reliable performance baseline for precision validation
- **Considers**: ADR-018 (MVP Definition) - balances feature completeness with development velocity
