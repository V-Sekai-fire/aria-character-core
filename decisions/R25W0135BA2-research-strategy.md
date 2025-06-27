# R25W0135BA2: Research Question Resolution Strategy

<!-- @adr_serial R25W0135BA2 -->

## Status

Accepted

## Context

The temporal planner implementation involves several critical research questions about Oban precision, real-time input, and SQLite performance that cannot be answered theoretically.

## Decision

Address critical research questions through rapid prototyping during implementation rather than separate investigation phases.

## Rationale

- **Implementation-Driven Discovery**: Build working code immediately and measure actual performance
- **Rapid Validation**: Test critical assumptions as part of development process
- **Fail Fast Strategy**: Discover fundamental limitations early in development
- **Practical Knowledge**: Real performance data more valuable than theoretical analysis

## Implementation

### Research Questions to Address

- **R1 (Oban Precision)**: Can Oban schedule actions with sub-second precision?
- **R2 (Real-time Input)**: Can we handle keyboard input without blocking game execution?
- **R3 (SQLite Performance)**: Is SQLite fast enough for real-time state updates?

### Research-Through-Implementation Approach

- **Question R1**: Test during first GameActionJob implementation
- **Question R2**: Test during CLI development with async input handling
- **Question R3**: Monitor during development, optimize if needed

### Rapid Validation Tests

```elixir
# R1: Oban timing precision
test "oban scheduling accuracy" do
  scheduled_time = DateTime.utc_now() |> DateTime.add(1, :second)
  start_time = System.monotonic_time(:millisecond)

  {:ok, _job} = GameActionJob.new(%{test_timing: true})
    |> Oban.insert(scheduled_at: scheduled_time)

  # Verify execution within 100ms tolerance
  assert_receive {:job_executed, execution_time}, 2000
  actual_delay = execution_time - start_time
  assert actual_delay < 1100  # 1000ms + 100ms tolerance
end

# R2: Non-blocking input
test "async keyboard input" do
  {:ok, pid} = TimeStrike.CLI.start_link()

  # Simulate keypress
  send(pid, {:test_input, "space"})

  # Verify received without blocking
  assert_receive {:input_received, "space"}, 50
end

# R3: SQLite performance sampling
test "basic sqlite performance" do
  {time, _result} = :timer.tc(fn ->
    Enum.each(1..100, fn i ->
      TemporalState.update_agent_position("alex", {i, 3, 0})
    end)
  end)

  # Should handle 100 updates quickly (100µs per update max)
  assert time < 10_000  # 10ms total for 100 updates
end
```

### Implementation-First Philosophy

- **Build and Measure**: Create working implementations and measure actual performance
- **Adjust Based on Reality**: Modify design based on discovered capabilities
- **Simple First**: Use straightforward implementations, optimize later if needed
- **Early Detection**: Identify fundamental blockers as soon as possible

## Research Integration Strategy

### During Development

- **Continuous Measurement**: Instrument all performance-critical operations
- **Reality-Based Decisions**: Adjust scope based on actual measured performance
- **Document Discoveries**: Record what works and what doesn't for future projects
- **Pivot Quickly**: Change approach if fundamental assumptions prove wrong

### Performance Benchmarks

- **Oban Precision**: Actions should execute within 100ms of scheduled time
- **Input Latency**: Keyboard input processed within 50ms
- **SQLite Performance**: State updates under 100µs each
- **Overall Latency**: End-to-end response under 200ms

## Risk Mitigation Through Discovery

### If Research Questions Fail

- **R1 Failure**: Use simplified timing with second-precision
- **R2 Failure**: Remove real-time input, use turn-based approach
- **R3 Failure**: Use in-memory state only, no persistence

### Success Adaptation

- **Better Than Expected**: Expand scope to use enhanced capabilities
- **As Expected**: Continue with planned implementation
- **Worse Than Expected**: Reduce scope to match actual performance

## Consequences

### Positive

- Quick discovery of system capabilities and limitations
- Implementation-driven knowledge more reliable than theory
- Rapid identification of fundamental blockers
- Practical performance data for future projects

### Negative

- May discover limitations too late to adjust overall approach
- Research time integrated into development may slow initial progress
- Could lead to multiple implementation attempts if discoveries require changes
- Performance assumptions may not hold under full system load

## Related Decisions

- Links to R25W00881AA (LLM Development Uncertainty) for adaptive strategy
- Supports R25W012424D (Minimum Success Criteria) with fallback planning
- Implements R25W0101F54 (Test-Driven Development) for iterative discovery
- Builds on ADR-020 (Design Consistency Verification) for validated foundation
- Enables R25W0143F62 (Risk Mitigation) through early discovery
- Supports web interface development (ADR-068, ADR-069) for enhanced user interaction
