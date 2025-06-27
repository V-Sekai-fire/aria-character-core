# R25W1015A2E: Port GTPyhop Blocks GTN to AriaEngine

<!-- @adr_serial R25W1015A2E -->

**Status:** Active (Paused)  
**Date:** 2025-06-22  
**Priority:** HIGH  

## Context

We need to port the GTPyhop blocks_gtn example to our AriaEngine planner to validate our Goal-Task Network (GTN) capabilities and establish a reference implementation. The blocks_gtn example implements the Gupta-Nau optimal blocks-world planning algorithm and demonstrates sophisticated planning concepts including:

- **Goal-Task Networks**: Combines multigoals with hierarchical task decomposition
- **Optimal Algorithm**: Implements proven near-optimal blocks-world planning
- **Complex State Analysis**: Sophisticated helper functions for block status and movement priorities
- **Predicate-Based Goals**: Must be adapted to our StateV2 predicate format

## Decision

Port the complete GTPyhop blocks_gtn domain to AriaEngine using predicate-based state representation, maintaining the sophisticated logic of the Gupta-Nau algorithm while ensuring compatibility with our planning architecture.

## Implementation Plan

### Phase 1: State Representation Design

**Objective**: Design predicate mappings for blocks-world state variables

**GTPyhop → AriaEngine StateV2 Mapping**:

- `pos[b] = 'table'` → `{"pos", ["block_b", "table"]}`
- `pos[b] = 'hand'` → `{"pos", ["block_b", "hand"]}`
- `pos[b1] = b2` → `{"pos", ["block_b1", "block_b2"]}`
- `clear[b] = true` → `{"clear", ["block_b", "true"]}`
- `clear[b] = false` → `{"clear", ["block_b", "false"]}`
- `holding['hand'] = b` → `{"holding", ["hand", "block_b"]}`
- `holding['hand'] = False` → `{"holding", ["hand", "false"]}`

**Tasks**:

- [ ] Create `AriaEngine.BlocksWorld.Domain` module
- [ ] Implement state conversion utilities
- [ ] Design predicate query helper functions
- [ ] Create state initialization functions
- [ ] Test basic state representation

### Phase 2: Action Implementation

**Objective**: Port all four primitive actions with predicate-based state changes

**Actions to Port**:

- [ ] `pickup(s,x)` - Pick up block from table
- [ ] `unstack(s,b1,b2)` - Remove b1 from top of b2
- [ ] `putdown(s,b1)` - Place held block on table
- [ ] `stack(s,b1,b2)` - Place held block b1 on top of b2

**Implementation Requirements**:

- [ ] Proper precondition checking using predicate queries
- [ ] State updates using predicate modifications
- [ ] Error handling for invalid actions
- [ ] Integration with AriaEngine action system

### Phase 3: Helper Function Translation

**Objective**: Convert GTPyhop helper functions to work with predicate-based state

**Helper Functions**:

- [ ] `is_done(b1, state, mgoal)` - Check if block and blocks below are in final position
- [ ] `status(b1, state, mgoal)` - Determine block status (done, inaccessible, move-to-table, move-to-block, waiting)
- [ ] `all_blocks(state)` - Get all blocks in the state
- [ ] `all_clear_blocks(state)` - Get all clear blocks

**Implementation Strategy**:

- Use StateV2.get_fact/3 for predicate queries
- Use StateV2.get_subjects_with_fact/3 for finding blocks
- Maintain original algorithm logic while adapting to predicate format

### Phase 4: Method Implementation

**Objective**: Port multigoal and task methods to our method system

**Multigoal Method**:

- [ ] `m_moveblocks(s, mgoal)` - Implements Gupta-Nau algorithm
  - Find clear blocks that can move to final location
  - Find clear blocks that need to move out of the way
  - Return appropriate task sequence

**Task Methods**:

- [ ] `m_take(s, x)` - Generate pickup or unstack action
- [ ] `m_put(s, x, y)` - Generate putdown or stack action

**Integration Requirements**:

- [ ] Register with AriaEngine.Domain.add_multigoal_method/3
- [ ] Register with AriaEngine.Domain.add_task_method/3
- [ ] Ensure proper return format for our planner

### Phase 5: Goal Representation

**Objective**: Convert GTPyhop Multigoal format to predicate-based goals

**Goal Conversion Examples**:

**GTPyhop Multigoal**:

```python
goal.pos = {'c':'b', 'b':'a', 'a':'table'}
```

**AriaEngine Predicate Goals**:

```elixir
[
  {"pos", ["c", "b"]},
  {"pos", ["b", "a"]},
  {"pos", ["a", "table"]}
]
```

**Tasks**:

- [ ] Design goal conversion utilities
- [ ] Implement goal satisfaction checking
- [ ] Test complex multigoals (Sussman anomaly scenarios)

### Phase 6: Comprehensive Testing

**Objective**: Port all test cases and validate against expected solutions

**Test Scenarios from GTPyhop**:

- [ ] Basic action tests (pickup, unstack, putdown, stack)
- [ ] Simple goal achievement tests
- [ ] Sussman anomaly problem
- [ ] Complex multigoal scenarios
- [ ] Large-scale problems (IPC-2011 BW-rand-50)

**Expected Solutions Validation**:

- [ ] Verify plans match GTPyhop expected results
- [ ] Performance benchmarking against original
- [ ] Edge case handling validation

### Phase 7: Duration Extension Foundation

**Objective**: Prepare for future temporal planning integration

**Design Considerations**:

- [ ] Identify duration integration points
- [ ] Document temporal constraint opportunities
- [ ] Design durative action conversion strategy
- [ ] Plan for temporal goal representation

## Success Criteria

- [ ] All GTPyhop blocks_gtn test cases pass with correct solutions
- [ ] Predicate-based state representation works seamlessly
- [ ] Multigoal and task methods integrate properly with AriaEngine
- [ ] Performance comparable to original GTPyhop implementation
- [ ] Comprehensive test coverage (>95%)
- [ ] Clear documentation and examples for future domain development

## File Structure

```
lib/aria_engine/blocks_world/
├── domain.ex              # Main domain module
├── actions.ex             # Action implementations
├── methods.ex             # Method implementations
├── helpers.ex             # Helper functions
└── state_utils.ex         # State conversion utilities

test/aria_engine/blocks_world/
├── domain_test.exs         # Domain integration tests
├── actions_test.exs        # Action unit tests
├── methods_test.exs        # Method unit tests
├── scenarios_test.exs      # Complex scenario tests
└── gtpyhop_validation_test.exs  # GTPyhop compatibility tests
```

## Dependencies

- **AriaEngine.Domain**: Core domain functionality
- **AriaEngine.StateV2**: Predicate-based state representation
- **AriaEngine.Planning**: Planning engine integration

## Risks and Mitigation

**Risk**: Complex helper function translation
**Mitigation**: Implement incrementally with extensive testing

**Risk**: Performance degradation with predicate queries
**Mitigation**: Optimize predicate access patterns, add caching if needed

**Risk**: Goal representation complexity
**Mitigation**: Create clear conversion utilities and comprehensive examples

## Related ADRs

- **R25W089FC2D**: Unified Durative Action Specification (provides action framework)
- **R25W10069A4**: Align Unigoal Method Registration with GTPyhop Design (method integration)
- **R25W046434A**: Migrate Planner to StateV2 Subject-Predicate-Fact (state representation)

## Implementation Status

**Current Phase**: Phase 1 - State Representation Design
**Next Steps**: Create domain module and implement basic state conversion
**Timeline**: Target completion within 2-3 development sessions

## Notes

This implementation will serve as a comprehensive validation of our GTN capabilities and provide a solid foundation for future temporal planning extensions. The blocks world domain is well-understood and provides excellent benchmarking opportunities against established algorithms.
