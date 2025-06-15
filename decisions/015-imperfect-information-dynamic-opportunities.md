# ADR-015: Imperfect Information & Dynamic Opportunities

## Status

Accepted

## Context

The temporal planner must create genuine opportunities for player intervention despite optimal AI planning by introducing uncertainty and incomplete information that human players can better navigate.

## Decision

Deliberately introduce uncertainty and incomplete information to create genuine opportunities for player intervention despite optimal planning.

## Rationale

- **Human vs AI Advantage**: Create scenarios where human judgment excels over algorithmic planning
- **Genuine Opportunities**: Ensure player interventions have meaningful impact beyond random chance
- **Dynamic Gameplay**: Environmental changes create new tactical possibilities during execution
- **Uncertainty Management**: Fog of war and incomplete information force adaptive decision-making

## Implementation

### Fog of War Systems

- **Limited Visibility**: Planner makes decisions with incomplete battlefield information
- **Estimated Positions**: Enemy positions estimated, not precisely known until line-of-sight
- **Hidden Hazards**: Environmental dangers revealed only when approached
- **Unpredictable Variables**: Agent stamina/health not perfectly predictable under stress
- **Equipment Reliability**: Random failure chances for gear and equipment

### Dynamic Environment

- **Adaptive Opposition**: Enemies adapt their tactics based on player actions
- **Environmental Events**: Explosions, structural collapse create new paths/obstacles
- **Time-Sensitive Opportunities**: Doors closing, reinforcements arriving create urgency
- **Resource Scarcity**: Limited resources force suboptimal initial plans

### Human Capability Advantages

- **Pattern Recognition**: Player spots enemy behavioral patterns AI misses
- **Intuitive Risk Assessment**: Human judgment on "gut feeling" moments
- **Creative Problem Solving**: Unconventional approaches AI doesn't consider
- **Situational Adaptation**: Rapid response to unexpected situations

### Designed Suboptimality

- **Conservative Planning**: Plans optimize for 80% success rather than theoretical perfection
- **Risk/Reward Options**: Multiple viable approaches with different risk profiles
- **Safe vs Aggressive**: AI suggests safe path, player can choose risky shortcuts
- **Information Asymmetry**: Player has access to information the planner lacks

## Technical Details

```elixir
# Uncertainty factors
%{
  enemy_position_accuracy: 0.7,    # 70% position accuracy
  equipment_reliability: 0.9,      # 90% reliability
  environmental_stability: 0.8,    # 80% stability
  information_completeness: 0.6    # 60% complete information
}
```

## Consequences

### Positive

- Creates meaningful opportunities for player skill and judgment
- Ensures player interventions have genuine tactical value
- Maintains engagement through uncertainty and adaptation
- Balances AI optimization with human decision-making strengths

### Negative

- May frustrate players expecting perfect information
- Requires careful balance to avoid feeling random or unfair
- Increases complexity of AI planning systems
- Could lead to player analysis paralysis with too much uncertainty

## Related Decisions

- Links to ADR-013 (Opportunity Window Mechanics) for timing-based decisions
- Supports ADR-016 (Weekend Implementation Scope) with manageable complexity
- Enables ADR-025 (Research Strategy) through implementation discovery
