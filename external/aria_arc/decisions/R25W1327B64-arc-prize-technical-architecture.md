# R25W1327B64: ARC Prize Technical Architecture

<!-- @adr_serial R25W1327B64 -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** HIGH  
**Prerequisites:** R25W1298CE1 (Hybrid Planner Restoration) must be completed first

## Context

This ADR defines the minimal viable technical architecture for the ARC Prize 2025 proof of concept sprint, with strict scope constraints based on git commit cadence analysis.

**Architecture Principles:**

- **Minimal viable implementation** for 2-week sprint
- **Evidence-based scope limits** (2 apps maximum)
- **Implementation gates** requiring working code before architectural expansion
- **No premature optimization** or speculative features

## System Architecture

### Phase 1 Sprint Architecture (Week 3)

**Scope:** Computational search foundation with strict 2-app limit

```
┌─────────────────┐    ┌──────────────────────┐
│   aria_arc      │    │  aria_hybrid_planner │
│                 │    │                      │
│ ┌─────────────┐ │    │ ┌──────────────────┐ │
│ │ ARC Tasks   │ │    │ │ Strategy Pattern │ │
│ │ - JSON Load │ │    │ │ - Domain         │ │
│ │ - Grid Rep  │ │    │ │ - State          │ │
│ │ - Validation│ │    │ │ - Planning       │ │
│ └─────────────┘ │    │ └──────────────────┘ │
│                 │    │                      │
│ ┌─────────────┐ │    │ ┌──────────────────┐ │
│ │Transform    │ │    │ │ R25W091EA37 Patterns │ │
│ │ - Primitives│ │    │ │ - add_method/4   │ │
│ │ - Generator │ │    │ │ - Module domains │ │
│ │ - Search    │ │    │ │ - Error handling │ │
│ └─────────────┘ │    │ └──────────────────┘ │
│                 │    │                      │
│ ┌─────────────┐ │    │                      │
│ │ Evaluation  │ │    │                      │
│ │ - Scoring   │ │    │                      │
│ │ - Metrics   │ │    │                      │
│ └─────────────┘ │    │                      │
└─────────────────┘    └──────────────────────┘
```

**Phase 1 Components:**

### aria_arc Application

**Scope:** Minimal ARC task processing

**Core Modules:**

- `AriaArc.TaskLoader` - JSON parsing and validation
- `AriaArc.Grid` - Grid representation and operations
- `AriaArc.Transform` - Transformation primitives and generation
- `AriaArc.Search` - Brute force search implementation
- `AriaArc.Evaluator` - Grid comparison and scoring

**Data Structures:**

```elixir
# ARC Task representation
%AriaArc.Task{
  id: String.t(),
  train: [%{input: grid(), output: grid()}],
  test: [%{input: grid()}]
}

# Grid representation (simple 2D array)
@type grid :: [[integer()]]

# Transformation program
%AriaArc.Transform{
  operations: [operation()],
  parameters: map()
}
```

### aria_hybrid_planner Integration

**Scope:** Use restored hybrid planner for Phase 2 only

**Requirements from R25W1298CE1:**

- Clean compilation with `mix compile --warnings-as-errors`
- Full test suite passing with `mix test`
- R25W091EA37 standardization implemented
- Module-based domain creation functional

### Phase 2 Integration Architecture (Week 4)

**Scope:** Hybrid reasoning coordination (only if Phase 1 succeeds)

```
┌─────────────────┐    ┌──────────────────────┐
│   aria_arc      │◄──►│  aria_hybrid_planner │
│                 │    │                      │
│ ┌─────────────┐ │    │ ┌──────────────────┐ │
│ │ ARC Domain  │ │    │ │ ARC Domain       │ │
│ │ - Actions   │ │    │ │ - Methods        │ │
│ │ - Goals     │ │    │ │ - Planning       │ │
│ └─────────────┘ │    │ └──────────────────┘ │
│                 │    │                      │
│ ┌─────────────┐ │    │ ┌──────────────────┐ │
│ │ Meta-Search │ │    │ │ Strategy Coord   │ │
│ │ - Planning  │ │    │ │ - Meta-reasoning │ │
│ │ - Guidance  │ │    │ │ - Search Control │ │
│ └─────────────┘ │    │ └──────────────────┘ │
└─────────────────┘    └──────────────────────┘
```

## Implementation Constraints

### Strict Scope Limits

**Based on Git Commit Analysis:**

1. **2 Apps Maximum:** No expansion beyond `aria_arc` + `aria_hybrid_planner`
2. **No Architectural Expansion:** Without proven necessity and working code
3. **Implementation Gates:** Working code required before any design changes
4. **No Premature Abstraction:** Build concrete solutions first

### Forbidden Expansions

**These are explicitly prohibited during the sprint:**

- Additional apps or modules beyond the 2-app limit
- Complex abstraction layers without proven need
- Speculative features for "future extensibility"
- Architectural refactoring without implementation necessity
- Integration with other apps beyond hybrid planner

### Implementation Gates

**Phase 1 Gates:**

- **Gate 1:** ARC task loading functional before transformation work
- **Gate 2:** Transformation generation working before search implementation
- **Gate 3:** Search evaluation achieving >1% accuracy before Phase 2

**Phase 2 Gates:**

- **Gate 4:** ARC domain working with hybrid planner before meta-reasoning
- **Gate 5:** Planning coordination functional before final evaluation

## Data Flow Architecture

### Phase 1: Computational Search

```
ARC JSON → TaskLoader → Grid → Transform Generator → Search → Evaluator → Results
```

### Phase 2: Hybrid Reasoning (Conditional)

```
ARC Task → ARC Domain → Hybrid Planner → Meta-Search → Guided Transform → Results
```

## Technology Stack

### Core Technologies

- **Elixir/OTP:** Primary language and runtime
- **JSON:** ARC task format
- **ExUnit:** Testing framework

### Dependencies

- **aria_hybrid_planner:** Planning and reasoning (after R25W1298CE1 restoration)
- **Jason:** JSON parsing
- **Standard library only:** No additional external dependencies

### Prohibited Dependencies

- **No ML libraries:** Keep computational approach pure
- **No complex frameworks:** Maintain simplicity
- **No speculative dependencies:** Only add when proven necessary

## Performance Targets

### Phase 1 Targets

- **Task Loading:** <100ms per task
- **Transform Generation:** 1000+ programs per task
- **Search Evaluation:** Complete evaluation in <10 minutes per task
- **Accuracy Target:** >1% on training tasks

### Phase 2 Targets (Conditional)

- **Planning Integration:** <1 second planning overhead per task
- **Meta-Reasoning:** Improved search efficiency
- **Accuracy Target:** 5%+ for go/no-go decision

## Testing Strategy

### Phase 1 Testing

- **Unit tests:** Each module with >80% coverage
- **Integration tests:** End-to-end task processing
- **Performance tests:** Search evaluation timing
- **Accuracy tests:** Training task evaluation

### Phase 2 Testing (Conditional)

- **Domain tests:** ARC domain functionality
- **Integration tests:** Hybrid planner coordination
- **System tests:** Complete hybrid reasoning pipeline

## Deployment Architecture

### Development Environment

- **Local development:** Standard Elixir/Mix setup
- **Testing:** Automated test suite
- **Evaluation:** Training task accuracy measurement

### Production Considerations

- **Not applicable:** This is a proof of concept sprint
- **Future consideration:** Only if 5%+ accuracy achieved

## Risk Mitigation

### Architecture Risks

1. **Scope creep:** Strict 2-app limit enforcement
2. **Over-engineering:** Implementation gates prevent premature abstraction
3. **Integration complexity:** Phase 2 is conditional on Phase 1 success

### Technical Risks

1. **Hybrid planner dependency:** R25W1298CE1 must be completed first
2. **Performance bottlenecks:** Simple computational approach may be slow
3. **Accuracy limitations:** Brute force search may not achieve targets

## Success Criteria

### Phase 1 Architecture Success

- [ ] 2-app architecture functional
- [ ] All implementation gates passed
- [ ] >1% accuracy on training tasks
- [ ] Clean compilation and test coverage

### Phase 2 Architecture Success (Conditional)

- [ ] Hybrid reasoning integration working
- [ ] Planning coordination functional
- [ ] 5%+ accuracy for continuation decision

## Related ADRs

- **R25W1298CE1**: Hybrid Planner Complete Restoration and Standardization (prerequisite)
- **R25W130E6A7**: ARC Prize 2025 - Two-Week Proof of Concept Sprint (masthead)
- **R25W131C16E**: ARC Prize Implementation Plan
- **R25W133C875**: ARC Prize Risk Analysis

This architecture is designed for rapid implementation with strict scope constraints to prevent the analysis paralysis observed in previous git commit patterns.
