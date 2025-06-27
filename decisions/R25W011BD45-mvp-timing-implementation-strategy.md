# R25W011BD45: MVP Timing Implementation Strategy

<!-- @adr_serial R25W011BD45 -->

## Status

Accepted

## Context

The temporal planner requires deterministic and accurate action timing for reliable gameplay and player intervention, implemented with simple calculations suitable for weekend development.

## Decision

Implement deterministic action timing using simple Euclidean distance calculation with constant movement speed, verified through automated testing.

## Rationale

- **Deterministic Behavior**: Same movement always takes exactly the same time
- **Simple Implementation**: Straightforward distance/speed calculation suitable for weekend timeline
- **Testable Accuracy**: Automated tests verify timing precision within acceptable tolerance
- **Reliable Interruption**: Predictable timing enables meaningful player intervention

## Implementation

### Distance Calculation

- **Simple Formula**: `time = distance / speed` where distance = `sqrt((x2-x1)² + (y2-y1)²)`
- **Variable Speed**: Per-agent movement speed (Alex: 4.0, Maya: 3.0, Jordan: 3.0 u/s)
- **Deterministic Duration**: Identical inputs always produce identical timing
- **3D Ready**: Formula supports Z-coordinate but uses Z=0 for weekend

### Progress Tracking

- **Linear Interpolation**: Position calculated as linear interpolation between start and end
- **Interruption Support**: Store current position when action interrupted, resume from there
- **Real-time Updates**: Position updates calculated at each game tick

### Timing Reliability

- **Sub-second Precision**: Duration calculations accurate to 0.1 second
- **Measurable Performance**: Automated tests verify real vs expected completion times
- **Graceful Interruption**: Actions can be stopped cleanly at any point with accurate position

## Technical Implementation

```elixir
def calculate_move_duration(from_pos, to_pos, speed \\ 3.0) do
  distance = :math.sqrt(
    :math.pow(to_pos.x - from_pos.x, 2) +
    :math.pow(to_pos.y - from_pos.y, 2)
  )
  distance / speed
end

def calculate_current_position(start_pos, end_pos, start_time, duration, current_time) do
  progress = (current_time - start_time) / duration
  progress = max(0.0, min(1.0, progress))  # Clamp to [0, 1]

  %{
    x: start_pos.x + progress * (end_pos.x - start_pos.x),
    y: start_pos.y + progress * (end_pos.y - start_pos.y),
    z: 0.0
  }
end
```

### Test Coverage Strategy

- **Unit Tests**: Duration calculation formulas with known inputs/outputs
- **Integration Tests**: Oban job timing accuracy in real execution
- **Property Tests**: Movement interpolation with random positions
- **Performance Tests**: Timing precision under load conditions

## Timing Requirements

- **Deterministic Calculation**: Identical inputs always produce identical timing
- **Sub-second Precision**: Duration calculations accurate to 0.1 second
- **Measurable Performance**: Real vs expected completion times within 10ms tolerance
- **Graceful Interruption**: Actions can be stopped cleanly with accurate position tracking

## Consequences

### Positive

- Simple, predictable timing model easy to implement and test
- Deterministic behavior enables reliable player intervention
- Mathematical foundation supports future complexity additions
- Clear performance benchmarks for validation

### Negative

- Simplified movement model may not reflect realistic physics
- Linear interpolation may not match natural movement patterns
- Constant speed assumption ignores acceleration/deceleration
- May require refinement for more complex terrain interactions

## Related Decisions

- Implements ADR-009 (Action Duration Calculations) with specific formulas
- Links to R25W0101F54 (Test-Driven Development) with testable timing
- Supports R25W009BCB5 (MVP Definition) with deterministic demonstrations
