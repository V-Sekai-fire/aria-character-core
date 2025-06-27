# R25W00881AA: LLM-Assisted Development Time Uncertainty

<!-- @adr_serial R25W00881AA -->

## Status

Accepted

## Context

Development time estimation becomes extremely unreliable when using LLM assistance, requiring adaptive strategies to handle unpredictable acceleration in some areas and normal development speed in others.

## Decision

Acknowledge that LLM assistance makes time estimation extremely unreliable and build adaptive development strategy.

## Rationale

- **Velocity Uncertainty**: LLM assistance can accelerate development 5-50x in some areas, but may not help with others
- **Variable Effectiveness**: Fast with LLM for data structures and algorithms, unknown speed for complex integrations
- **Persistent Challenges**: Understanding existing codebase and architectural decisions remain slow
- **Unpredictable Blockers**: Debugging edge cases and performance optimization may not benefit from LLM assistance

## Implementation

### Development Areas by LLM Effectiveness

- **Fast with LLM**: Data structure design, boilerplate code, algorithm implementation
- **Unknown Speed**: Complex integrations, debugging edge cases, performance optimization
- **Still Slow**: Understanding existing codebase, architectural decisions, testing strategies

### Adaptive Planning Strategy

- **Time-boxed Iterations**: Use 2-hour time boxes with frequent progress re-assessment
- **Minimum Viable Demos**: Focus on end-to-end working demos at each stage
- **Scope Flexibility**: Ready to cut features if complexity exceeds LLM assistance
- **Parallel Development**: Work on multiple approaches simultaneously when uncertain

### Risk Mitigation Scenarios

- **High Acceleration**: Full implementation with polish and advanced features
- **Low Acceleration**: Bare minimum MVP with manual fallbacks
- **Blocker Identification**: Pre-identify areas where LLM might not help

### Success Metrics

- **Core Success**: Temporal planner schedules and executes one action via Oban
- **Enhanced Success**: Player can interrupt and redirect actions in real-time
- **Full Success**: Complete TimeStrike scenario with all player intervention mechanics

## Technical Approach

```elixir
# Development velocity tracking
%{
  task_type: :data_structure_design,
  estimated_time: :unknown,
  llm_effectiveness: :high,
  fallback_plan: :manual_implementation,
  success_criteria: "Working struct with tests"
}
```

## Consequences

### Positive

- Realistic acknowledgment of development uncertainty
- Adaptive strategy handles both high and low acceleration scenarios
- Focus on demonstrable progress over theoretical completeness
- Learning opportunity for future LLM-assisted projects

### Negative

- Difficult to provide accurate timeline commitments
- May lead to over-conservative or over-optimistic planning
- Requires constant scope adjustment and re-prioritization
- Potential for incomplete features if acceleration doesn't materialize

## Related Decisions

- Links to R25W00787B6 (Weekend Implementation Scope) for realistic timeline management
- Supports R25W009BCB5 (MVP Definition) with success criteria flexibility
- Enables R25W0135BA2 (Research Strategy) through implementation discovery
