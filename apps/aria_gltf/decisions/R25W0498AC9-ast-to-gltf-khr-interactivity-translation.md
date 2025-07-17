# R25W0498AC9: AST-to-glTF KHR_interactivity Node Translation System

<!-- @adr_serial R25W0498AC9 -->

**Status:** Obsolete - KHR System Deleted  
**Date:** 2025-06-18  
**Deletion Date:** 2025-06-18  
**Priority:** ~~High~~ N/A

## Obsolescence Reason

This ADR is now obsolete as the entire KHR_interactivity system has been deleted from the project. The KHR node library, domain implementation, tests, and all related infrastructure have been removed. This ADR is preserved for historical reference only.

## Context

Develop a system that automatically translates Elixir function ASTs into executable sequences of glTF KHR_interactivity nodes. This enables developers to write natural Elixir code that gets compiled into standardized behavior graph nodes, supporting all 125+ available KHR_interactivity operations including math, control flow, variables, events, animation, and type conversion.

### Current State

- Complete KHR_interactivity node library implemented (125+ nodes)
- Proven node execution pattern: `[node_index, ...args] → StateV2.set_fact(node_index, "value", result)`
- Existing infrastructure for math, control flow, variables, events, animation operations
- StateV2 integration working with node-based fact storage

### Problem Statement

Currently, creating behavior graphs requires manual KHR node composition. Developers must write low-level action sequences instead of natural Elixir code. We need automatic translation from idiomatic Elixir functions to KHR node graphs.

## Decision

Implement a comprehensive AST-to-KHR translation system that:

1. **Parses Elixir function ASTs** into operation sequences
2. **Maps all AST patterns** to corresponding KHR_interactivity nodes
3. **Manages node IDs** with sequential assignment and dependency tracking
4. **Handles data flow** between nodes via StateV2 fact-based communication
5. **Supports all node categories** including math, control flow, variables, events, animation, type conversion
6. **Generates executable functions** that coordinate KHR node execution

## Implementation Plan

### Phase 1: Core Infrastructure

- [ ] Create `ASTTranslator.NodeManager` for sequential node ID assignment
- [ ] Implement `ASTTranslator.DataFlow` for operand resolution and dependency tracking
- [ ] Build `ASTTranslator.OperationRegistry` mapping all 125+ KHR operations
- [ ] Create `ASTTranslator.PatternMatcher` for comprehensive AST pattern recognition
- [ ] Implement basic translation pipeline with validation

### Phase 2: Multi-Category Operation Support

- [ ] Implement `ASTTranslator.MultiCategoryExtractor` for all operation types:
  - [ ] Math operations (arithmetic, comparison, trigonometry, vectors, matrices)
  - [ ] Control flow (sequence, branch, switch, loops)
  - [ ] Variable management (get, set, exists, delete, pointers)
  - [ ] Event system (send, receive, lifecycle, debug)
  - [ ] Animation control (start, stop, pause, resume, status)
  - [ ] Type conversion (bool ↔ int ↔ float)
- [ ] Handle complex nested expressions with proper dependency ordering
- [ ] Support variable assignments and references across node boundaries

### Phase 3: Code Generation

- [ ] Implement `ASTTranslator.CodeGenerator` for executable function creation
- [ ] Generate functions that coordinate KHR node execution sequences
- [ ] Handle parameter binding and node result retrieval
- [ ] Implement proper error handling and validation

### Phase 4: Advanced Pattern Support

- [ ] Support complex control flow patterns:
  - [ ] Nested if-then-else statements
  - [ ] Case/switch statements with multiple clauses
  - [ ] Sequential block execution
  - [ ] Conditional variable assignments
- [ ] Handle event-driven patterns and animation coordination
- [ ] Support mixed-category operations in single functions

### Phase 5: Integration and Validation

- [ ] Create comprehensive test suite covering all node categories
- [ ] Implement validation for KHR specification compliance
- [ ] Add debugging support with AST → nodes → execution tracing
- [ ] Performance optimization for generated execution sequences
- [ ] Documentation and usage examples

### Phase 6: Advanced Features

- [ ] Support for custom node extensions
- [ ] Optimization passes for redundant operations
- [ ] Type inference and validation
- [ ] Integration with existing aria_engine planning systems

## Technical Architecture

### Node ID Management Strategy

```elixir
# Sequential assignment with dependency tracking
# Node 1: base + modifier → facts["1"]["value"]
# Node 2: temp * 2 → facts["2"]["value"] (reads from Node 1)
# Node 3: abs(result) → facts["3"]["value"] (reads from Node 2)
```

### Complete Operation Mapping

- **Math Operations (45+ nodes)**: All arithmetic, comparison, trigonometry, vector/matrix operations
- **Control Flow (15+ nodes)**: Sequence, branch, switch, loops with temporal constraints
- **Variable Management (8+ nodes)**: Get/set operations, pointer indirection, existence checks
- **Event System (12+ nodes)**: Send/receive, lifecycle events, debug operations
- **Animation Control (8+ nodes)**: Playback control, time management, status queries
- **Type Conversion (6+ nodes)**: All bool ↔ int ↔ float conversions

### Data Flow Coordination

- Function parameters: Direct value passing
- Node references: Read from `StateV2.get_fact(state, node_id, "value")`
- Variable assignments: Map variable names to node IDs
- Nested expressions: Automatic dependency resolution

## Success Criteria

### Functional Requirements

- [ ] Successfully translate simple mathematical expressions
- [ ] Handle complex multi-operation functions with proper data flow
- [ ] Support all 125+ KHR_interactivity node operations
- [ ] Generate executable functions that integrate with existing aria_engine systems
- [ ] Maintain glTF specification compliance

### Performance Requirements

- [ ] Translation time < 100ms for typical functions
- [ ] Generated execution overhead < 10% vs hand-written KHR sequences
- [ ] Memory usage proportional to function complexity

### Quality Requirements

- [ ] Comprehensive error messages for unsupported AST patterns
- [ ] Complete test coverage for all supported operation categories
- [ ] Clear debugging support for AST → nodes → execution flow
- [ ] Full documentation with examples for each node category

## Consequences

### Benefits

- **Developer Productivity**: Write natural Elixir code instead of manual KHR composition
- **Specification Compliance**: Automatic mapping ensures glTF standard conformance
- **Full Feature Access**: All 125+ KHR_interactivity nodes available through AST translation
- **Type Safety**: Compile-time validation of supported operations
- **Integration**: Seamless compatibility with existing aria_engine infrastructure

### Risks and Mitigation

- **Complexity**: Comprehensive AST pattern matching → Start with MVP, expand incrementally
- **Performance**: Generated code overhead → Optimize execution paths, benchmark against manual composition
- **Maintenance**: Elixir language evolution → Design extensible pattern matching system
- **Debugging**: Multi-layer complexity → Build comprehensive tracing and error reporting

### Alternative Approaches Considered

- **Direct KHR Macros**: More explicit but less natural for developers
- **Domain-Specific Language**: Additional learning curve and tooling complexity
- **Manual Composition**: Current approach, but low developer productivity

## Related ADRs

- **R25W031D2CC**: Aria Flow Core API Implementation (existing flow infrastructure)
- **ADR-066**: Consolidate Flow and Queue into Engine (execution context)
- **R25W044B3F2**: Entity Agent Timeline Graph Architecture (temporal planning integration)

## Monitoring and Review

### Implementation Milestones

- **Week 1**: Core infrastructure (Phase 1)
- **Week 2**: Multi-category support (Phase 2)
- **Week 3**: Code generation (Phase 3)
- **Week 4**: Advanced patterns (Phase 4)
- **Week 5**: Integration and validation (Phase 5)

### Success Metrics

- Number of supported AST patterns
- Translation success rate for test functions
- Performance benchmarks vs manual KHR composition
- Developer adoption and feedback

This ADR will be updated with progress reports and any architectural changes discovered during implementation.
