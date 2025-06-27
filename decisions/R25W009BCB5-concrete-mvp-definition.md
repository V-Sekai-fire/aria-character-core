# R25W009BCB5: Concrete MVP Definition

<!-- @adr_serial R25W009BCB5 -->

## Status

Accepted

## Context

The weekend project needs exact success criteria that leverage existing AriaEngine infrastructure while focusing on temporal extensions and modern 3D visualization.

## Decision

Define exactly what constitutes success for the weekend project, leveraging existing AriaEngine infrastructure and focusing on temporal extensions with Three.js 3D visualization.

## Rationale

- **Clear Success Criteria**: All components must work together for demonstrable temporal planning
- **Infrastructure Leverage**: Build on existing AriaEngine components rather than starting from scratch
- **Modern Visualization**: Three.js 3D interface provides professional demonstration capability
- **Temporal Focus**: Core value is temporal planning, not general game development

## Implementation

### MVP Success Criteria (All Must Work)

1. **Temporal State Extension**: Extend existing `AriaEngine.State` to include time and action scheduling
2. **Membrane Job Integration**: One `GameActionJob` schedules and executes a timed action
3. **Real-Time 3D Web Interface**: Phoenix LiveView with Three.js shows action progress with 3D positions
4. **Player Interruption**: Web button/hotkey cancels scheduled action, triggers re-planning
5. **Basic Stability**: Simple Lyapunov function validates action reduces distance to goal

### MVP Technical Stack

- **Base**: Existing `AriaEngine.State`, `AriaEngine.Domain`, `AriaEngine.Plan`
- **Extensions**: `TemporalState` (extends State), `GameActionJob` (Membrane worker)
- **New Modules**: `TimeStrike.LiveView`, `TimeStrike.GameEngine`
- **Frontend**: Three.js 3D scene with Phoenix LiveView integration
- **Infrastructure**: Existing `AriaQueue`, `AriaData.QueueRepo`, Membrane setup

### MVP TimeStrike Scenario (Ultra-Minimal)

- **3D Map**: 25×10×1 grid space, Alex starts at {2,3,0}, goal: reach {8,3,0}
- **Action**: `move_to` only - no combat, skills, or enemies
- **Duration**: Movement takes `distance / agent.move_speed` seconds
- **Display**: Three.js 3D scene updated in real-time showing Alex's 3D position

### Weekend Acceptance Test (10-minute demo)

1. Navigate to: `http://localhost:4000/timestrike`
2. See: Three.js 3D tactical map with Alex ('A') at position {2,3,0}
3. Click: Target position {8,3,0} - shows "Planning movement - ETA: 2.0s"
4. Watch: Alex 3D model moves in real-time across 3D grid with camera following
5. Click: "Cancel Action" button at {5,3,0} - Alex stops, shows "Replanning from {5,3,0}"
6. Continue: New plan generated, Alex continues to {8,3,0}
7. Success: "Mission Complete!" with cinematic camera celebration

### Post-MVP Extensions (If Time Permits)

- Add simple enemy at {6,3,0} that Alex must avoid
- Add conviction choice: "1: Stealth, 2: Combat, 3: Diplomacy"
- Add basic action cooldowns and stamina
- Camera angle controls for enhanced streaming visualization

## Technical Details

```elixir
# Minimal data structures
defmodule TemporalState do
  @enforce_keys [:state, :current_time, :scheduled_actions]
  defstruct [:state, :current_time, scheduled_actions: []]
end

# Timed action with 3D coordinates
@type timed_action :: %{
  id: String.t(),
  agent: String.t(),
  action: atom(),
  args: list(),
  start_time: DateTime.t(),
  duration: float(),
  position: {float(), float(), float()},
  status: :scheduled | :executing | :completed
}
```

## Consequences

### Positive

- Clear, measurable success criteria
- Leverages existing infrastructure for rapid development
- Professional 3D demonstration capability
- Foundation for future feature expansion

### Negative

- Limited scenario may not fully showcase temporal planning power
- Requires web development expertise in addition to backend logic
- 3D visualization adds complexity to minimum viable demonstration
- May not satisfy players expecting full game experience

## Related Decisions

- Links to R25W00787B6 (Weekend Implementation Scope) for realistic feature set
- Interface approach evolved from ADR-030 (Console TUI, superseded) to ADR-069 (Web Interface)
- Implements ADR-019 (3D Coordinates) through coordinate display
- Supports R25W012424D (Minimum Success Criteria) with concrete validation
- Enables R25W0135BA2 (Research Strategy) with practical demonstration
