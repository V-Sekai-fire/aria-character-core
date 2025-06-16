# ADR-031: Strategic Focus - TimeStrike Implementation Over Blender/Godot Tool Integration

## Status

Accepted

## Date

2025-06-14

## Context

With the symbolic planner now functional, a critical strategic decision emerged: should development focus on (A) expanding tool integration capabilities
by exposing the planner to Blender/Godot through MCP for workflow automation,
or (B) completing the TimeStrike game implementation as a concrete demonstration of temporal planning capabilities?

The choice represents two fundamentally different value propositions:

- **Option A (Tool Integration)**: Aria becomes a sophisticated automation tool for content creation workflows,
  leveraging MCP integration to provide AI-assisted task execution across creative software
- **Option B (TimeStrike Focus)**: Aria demonstrates its core temporal planning capabilities through a complete, shippable game that validates the entire architectural vision

## Decision

Prioritize TimeStrike game implementation over broader tool integration capabilities.

## Rationale

### Strategic Advantage: Proof of Concept Over Feature Breadth

TimeStrike provides concrete validation of the entire temporal planning architecture. A working game demonstrates:

- Real-time planning under time pressure
- Complex state management with temporal dependencies
- User interaction patterns that stress-test the system
- Performance characteristics under realistic load
- Complete integration of all architectural components (ADRs 001-030)

Tool integration, while valuable, fragments focus across multiple problem domains (content creation workflows, Blender API complexity, Godot integration quirks)
without proving the core temporal planning thesis.

### Market Positioning: Tangible Product Over Abstract Tool

A playable TimeStrike game creates immediate value:

- **Streamable content** for Twitch/YouTube audience building
- **Sellable product** once 2+ hours of gameplay content exists
- **Portfolio piece** demonstrating complete system capabilities
- **User feedback generation** from actual gameplay sessions

Tool integration creates capabilities without immediate market validation or revenue potential.

### Technical Risk Mitigation

TimeStrike leverages existing, validated architectural decisions:

- Uses web interface approach (ADR-068, ADR-069) superseding previous TUI approach (ADR-030)
- Builds on proven AriaEngine state management (ADR-001)
- Exercises real-time execution patterns (ADR-006)
- Validates Oban queue performance under load (ADR-002)

Blender/Godot integration introduces new technical risks:

- Complex external API dependencies
- Version compatibility maintenance burden
- Debugging across multiple software environments
- Unclear performance characteristics for fine-grained operations (polygon-by-polygon copying)

### Implementation Momentum

Current progress strongly favors TimeStrike completion:

- Core temporal planner implementation complete
- State management architecture proven (struct movement between points)
- Console TUI foundation established
- Test domain fully specified (ADR-005)

Tool integration requires starting from architectural foundations in an unproven domain.

### Weekend Timeline Optimization

Given the explicit weekend implementation scope (ADR-016), TimeStrike aligns with minimum viable success criteria (ADR-024):

- Builds on 80% completed foundations
- Leverages all existing architectural decisions
- Provides clear success metrics (working gameplay demonstration)
- Minimizes scope creep risk

Tool integration would require significant new architectural work outside the weekend timeline.

## Implementation

### Immediate Actions (Weekend Focus)

1. **Complete TimeStrike MVP**: Finish console TUI implementation with working temporal planning demonstration
2. **Validate Performance**: Stress-test all architectural components under realistic game conditions
3. **Document Lessons**: Capture implementation discoveries for future architectural refinement

### Future Consideration (Post-Weekend)

Tool integration capabilities remain valuable for future development:

- MCP server framework already specified (ADR-029)
- Blender/Godot integration can build on proven temporal planning core
- Avatar creation workflows become viable once core system is validated

## Consequences

### Positive

- **Focused Development**: All effort concentrated on proving core temporal planning thesis
- **Immediate Value**: Creates demonstrable, shareable, potentially sellable product
- **Risk Reduction**: Builds on validated architectural foundation rather than exploring new domains
- **Clear Success Metrics**: Working game provides unambiguous validation of system capabilities
- **Market Validation**: Real user interaction generates actionable feedback
- **Portfolio Asset**: Complete game implementation showcases full-stack capabilities

### Negative

- **Delayed Tool Integration**: Blender/Godot automation capabilities postponed to future development cycles
- **Narrower Immediate Scope**: Foregoes potential early adoption from content creation community
- **Single Application Domain**: Concentrates risk in gaming/entertainment market rather than diversifying across tool automation

### Strategic Implications

This decision establishes Aria as a **temporal planning engine with game development as the primary validation domain**, rather than a **general-purpose automation platform**. This focus enables:

- Clear value proposition communication
- Concentrated technical expertise development
- Simplified go-to-market strategy
- Stronger competitive differentiation in the AI-assisted game development space

## Related Decisions

- **Validates**: ADR-005 (TimeStrike Test Domain) - confirms game implementation as primary validation approach
- **Aligns with**: ADR-016 (Weekend Implementation Scope) - maintains realistic timeline constraints
- **Implements**: ADR-018 (MVP Definition) - delivers concrete demonstration of temporal planning capabilities
- **Builds on**: ADR-024 (Minimum Success Criteria) - leverages existing progress toward achievable weekend goal
- **Supersedes**: ADR-030 (Console TUI) with ADR-068/069 (Web Interface) - modernizes interface approach for better demonstration capability
- **Defers**: ADR-029 (MCP Integration) - postpones broader tool integration until core system validation complete
- **Leverages**: ADR-001-004 (Core Architecture) - maximizes return on established architectural investments
- **Exercises**: ADR-006-013 (Real-time Systems) - validates all temporal planning components under realistic load
- **Demonstrates**: ADR-020 (Design Consistency) - proves architectural coherence through complete implementation
- **Follows**: ADR-025-026 (Research Strategy & Risk Mitigation) - prioritizes proven capabilities over speculative extensions
