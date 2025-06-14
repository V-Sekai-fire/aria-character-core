# ADR-012: Real-Time Input System

## Status
Accepted

## Context
The temporal planner must support continuous player input without pausing gameplay, enabling streaming-compatible real-time tactical control and intervention.

## Decision
Implement real-time player input that never pauses the game engine for Twitch streaming compatibility.

## Rationale
- **Continuous Gameplay**: Game engine maintains 1000 FPS tick rate continuously without pauses
- **Streaming Compatibility**: Never-pause design essential for entertaining stream content
- **Immediate Response**: Sub-millisecond response time for all tactical inputs
- **Seamless Integration**: Input blends smoothly with ongoing actions

## Implementation
### Input Processing
- **No Game Pauses**: Game engine maintains continuous tick rate
- **Interrupt & Queue**: SPACEBAR cancels current action, immediately starts new one
- **Hotkey System**: 1-9 keys for instant tactical responses during action execution
- **Directional Override**: WASD keys instantly redirect movement without stopping

### Response Characteristics
- **Sub-millisecond Response**: All inputs processed within single tick (< 1ms)
- **Seamless Transitions**: New actions blend smoothly with interrupted ones
- **Immediate Feedback**: Visual and state updates occur within same frame

### Input Types
- **Interruption**: SPACEBAR for immediate action cancellation
- **Tactical Commands**: Numbered hotkeys for pre-defined actions
- **Movement Override**: Directional keys for movement redirection
- **Context Actions**: Situational inputs based on current game state

## Technical Details
```elixir
# Input processing pipeline
def handle_input(input, game_state) do
  case input do
    :spacebar -> cancel_current_action_and_replan(game_state)
    {:hotkey, n} -> execute_tactical_option(n, game_state)
    {:movement, direction} -> override_movement(direction, game_state)
    _ -> game_state
  end
end
```

## Consequences
### Positive
- Optimal streaming entertainment value
- Responsive tactical gameplay experience
- Smooth integration with temporal planning system
- Professional-quality input handling

### Negative
- Complex input state management
- Potential for input conflicts during rapid commands
- Increased CPU usage from continuous input monitoring
- More complex testing scenarios for input combinations

## Related Decisions
- Builds on ADR-006 (Real-time Execution) for continuous gameplay
- Links to ADR-007 (Conviction Choice Mechanics) for timed decisions
- Supports ADR-013 (Opportunity Window Mechanics) with frame-perfect timing
