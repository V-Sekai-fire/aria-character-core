# R25W131C16E: ARC Prize Implementation Plan

<!-- @adr_serial R25W131C16E -->

**Status:** Proposed  
**Date:** 2025-06-24  
**Priority:** HIGH  
**Prerequisites:** R25W1298CE1 (Hybrid Planner Restoration) must be completed first

## Context

This ADR provides the detailed implementation plan for the ARC Prize 2025 two-week proof of concept sprint, incorporating lessons learned from git commit cadence analysis showing the planning-to-implementation gap.

**Evidence-Based Reality Check:**
Previous work shows 40+ planning commits with minimal implementation, indicating need for strict scope limits and implementation gates to prevent analysis paralysis.

## Implementation Timeline

**Prerequisites (Weeks 1-2: June 24 - July 8):**

- R25W1298CE1: Hybrid Planner Complete Restoration and Standardization

**ARC Sprint (Weeks 3-4: July 8 - July 22):**

- Phase 1: Computational search foundation
- Phase 2: Hybrid reasoning integration

## Phase 1: Computational Search Foundation (Week 3: July 8-15)

### Day 1-2: ARC Data Integration

**Scope:** Minimal viable ARC task loading

- [ ] Create `apps/aria_arc` application
- [ ] Load ARC training tasks from JSON format
- [ ] Implement basic grid representation
- [ ] Create task validation and parsing
- [ ] **Implementation Gate:** Must have working task loader before proceeding

### Day 3-4: Transformation Program Generator

**Scope:** Basic transformation search

- [ ] Implement grid transformation primitives (rotate, flip, translate)
- [ ] Create transformation program generator
- [ ] Add basic pattern matching operations
- [ ] Test transformation application to grids
- [ ] **Implementation Gate:** Must generate and apply transformations before proceeding

### Day 5-7: Search and Evaluation

**Scope:** Brute force search with evaluation

- [ ] Implement transformation program search (1000+ programs per task)
- [ ] Add grid comparison and scoring
- [ ] Create evaluation metrics for transformation quality
- [ ] Test on 10 training tasks, target 1-5% accuracy
- [ ] **Phase 1 Success Gate:** Must achieve >1% accuracy on training tasks

**Phase 1 Constraints:**

- **Maximum 2 apps:** `aria_arc` + `aria_hybrid_planner` only
- **No architectural expansion** without proven necessity
- **Implementation gates** requiring working code before design changes

## Phase 2: Hybrid Reasoning Integration (Week 4: July 15-22)

### Day 8-10: Domain Integration

**Scope:** ARC domain for hybrid planner

- [ ] Create ARC reasoning domain using R25W091EA37 standardized patterns
- [ ] Implement ARC-specific actions and methods
- [ ] Add transformation planning capabilities
- [ ] Test domain integration with hybrid planner
- [ ] **Implementation Gate:** Must have working ARC domain before proceeding

### Day 11-12: Planning Coordination

**Scope:** Hybrid reasoning for ARC tasks

- [ ] Integrate computational search with planning system
- [ ] Add meta-reasoning for transformation selection
- [ ] Implement planning-guided search strategies
- [ ] Test hybrid approach on training tasks
- [ ] **Implementation Gate:** Must show planning coordination working

### Day 13-14: Evaluation and Analysis

**Scope:** Final evaluation and decision

- [ ] Run comprehensive evaluation on training set
- [ ] Measure accuracy improvement from hybrid approach
- [ ] Document approach strengths and limitations
- [ ] Make go/no-go decision for full competition
- [ ] **Final Success Gate:** Achieve 5%+ accuracy for continuation

## Evidence-Based Scope Constraints

**Strict Limits (Based on Git Commit Analysis):**

- **2 apps maximum:** No expansion beyond `aria_arc` + `aria_hybrid_planner`
- **Implementation gates:** Working code required before any architectural changes
- **No feature creep:** Stick to minimal viable implementation
- **Daily commits:** Prevent analysis paralysis through regular implementation progress

**Timeline Multipliers Applied:**

- **3-5x multiplier** applied to initial estimates based on observed planning-implementation gap
- **Mandatory implementation gates** to prevent endless architectural discussions
- **Scope enforcement** to avoid the pattern of 40+ planning commits with minimal code

## Success Criteria

### Phase 1 Success (Week 3)

- [ ] ARC task loading functional
- [ ] Transformation program generation working
- [ ] Search evaluation achieving >1% accuracy on training tasks
- [ ] Clean compilation and basic test coverage

### Phase 2 Success (Week 4)

- [ ] ARC domain integrated with hybrid planner
- [ ] Planning coordination functional
- [ ] Hybrid approach showing measurable improvement
- [ ] Final accuracy measurement for go/no-go decision

### Overall Success Criteria

- **Technical:** 5%+ accuracy = proceed to full competition
- **Learning:** <3% accuracy = valuable learning experience, stop there
- **Process:** Avoid analysis paralysis through implementation gates

## Risk Mitigation

**High-Risk Areas:**

1. **Analysis paralysis:** Previous pattern of extensive planning with minimal implementation
2. **Scope creep:** Tendency to expand architecture without proven necessity
3. **Integration complexity:** Hybrid planner integration may be more complex than expected

**Mitigation Strategies:**

- **Implementation gates:** No architectural work without working code
- **Scope enforcement:** Strict 2-app limit with no exceptions
- **Daily commits:** Regular implementation progress tracking
- **Evidence-based timeline:** 3-5x multipliers based on historical patterns

## Dependencies

**Critical Path:**

1. **R25W1298CE1 completion:** Hybrid planner must be 100% functional
2. **Phase 1 gates:** Each implementation gate must pass before proceeding
3. **Phase 2 integration:** Depends on successful Phase 1 completion

## Related ADRs

- **R25W1298CE1**: Hybrid Planner Complete Restoration and Standardization (prerequisite)
- **R25W130E6A7**: ARC Prize 2025 - Two-Week Proof of Concept Sprint (masthead)
- **R25W1327B64**: ARC Prize Technical Architecture
- **R25W133C875**: ARC Prize Risk Analysis

## Monitoring and Tracking

**Daily Tracking:**

- Implementation progress (lines of code, working features)
- Test coverage and compilation status
- Accuracy measurements on training tasks
- Scope adherence (app count, feature creep indicators)

**Weekly Gates:**

- Phase 1: >1% accuracy on training tasks
- Phase 2: Hybrid approach functional with measurable improvement
- Final: Go/no-go decision based on accuracy threshold

This implementation plan incorporates lessons learned from git commit analysis to ensure focused execution and prevent the analysis paralysis that has affected previous planning efforts.
