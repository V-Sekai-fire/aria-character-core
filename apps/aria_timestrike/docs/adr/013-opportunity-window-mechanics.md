# ADR-013: Opportunity Window Mechanics

## Status

Accepted

## Context

The temporal planner needs to create meaningful moments where player skill and timing can improve outcomes, generating excitement and requiring precise tactical decision-making.

## Decision

Create time-pressured decision points that generate excitement and require skill.

## Rationale

- **Skill-Based Gameplay**: Frame-perfect timing windows where input determines success/failure
- **Excitement Generation**: Narrow timing windows create high-tension moments
- **Player Agency**: Meaningful opportunities for player intervention in planned sequences
- **Streaming Appeal**: Creates clip-worthy moments and commentary opportunities

## Implementation

### Opportunity Types

- **Opportunity Prompts**: "Press F NOW!" appears for 1.5 seconds with countdown timer
- **Frame-Perfect Timing**: Optimal interventions require 50-100ms precision windows
- **Risk/Reward Moments**: Narrow timing windows where input determines success/failure
- **Focus Burst**: Hold SHIFT during actions for 25% speed boost (limited energy)

### Feedback Systems

- **Cascading Consequences**: Timing choices immediately affect ongoing situation
- **Visual Feedback**: All interventions get instant visual/audio response within 16ms
- **Success Indication**: Clear feedback for successful vs missed opportunities
- **Consequence Display**: Immediate visualization of intervention results

### Timing Windows

- **Precise Timing**: 50-100ms windows for optimal responses
- **Visual Countdown**: Clear timing indicators for player preparation
- **Multiple Opportunities**: Various intervention types throughout gameplay
- **Skill Progression**: Opportunities become more challenging with experience

## Technical Details

```elixir
# Opportunity window structure
%{
  type: :precision_shot,
  window_start: start_time,
  window_duration: 150,  # milliseconds
  optimal_window: 75,    # milliseconds for perfect timing
  prompt: "Press F NOW!",
  consequence: :enemy_elimination_vs_alert
}
```

## Consequences

### Positive

- Creates engaging skill-based gameplay moments
- Generates excitement and tension for players and viewers
- Provides meaningful player agency within planned sequences
- Creates shareable highlight moments for streaming

### Negative

- May frustrate players with slower reaction times
- Requires precise timing implementation and testing
- Could create unfair advantages for players with better hardware
- Adds complexity to action sequence design

## Related Decisions

- Links to ADR-012 (Real-Time Input System) for responsive controls
- Supports ADR-014 (Twitch Streaming Optimization) with clip-worthy moments
- Builds on ADR-015 (Imperfect Information) for genuine opportunity creation
