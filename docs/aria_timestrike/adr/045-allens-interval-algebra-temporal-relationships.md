# ADR-045: Allen's Interval Algebra for Temporal Relationships

## Status

Accepted

## Context

The AriaTimestrike temporal planner requires a formal system for reasoning about time intervals and their relationships. As we implement the temporal planning capabilities outlined in ADR-042, we need a robust mathematical foundation for expressing and reasoning about temporal constraints between actions, events, and states.

Allen's Interval Algebra provides a complete and well-established framework for temporal reasoning that has been widely used in AI planning systems, scheduling applications, and temporal databases.

## Decision

We will implement Allen's Interval Algebra as the foundational temporal reasoning system for AriaTimestrike's temporal planner. This will provide:

1. **Complete Temporal Relationship Set**: All 13 possible relationships between time intervals
2. **Formal Mathematical Foundation**: Well-defined semantics for temporal reasoning
3. **Compositional Reasoning**: Ability to derive new relationships from existing ones
4. **Constraint Propagation**: Support for temporal constraint satisfaction

## Allen's Interval Algebra Relationships

### Basic Relationships (7 + 6 inverses = 13 total)

| Relationship     | Symbol | Description                           | Example   |
| ---------------- | ------ | ------------------------------------- | --------- |
| **A before B**   | `<`    | A finishes completely before B begins | `[A] [B]` |
| **A meets B**    | `m`    | A finishes exactly when B begins      | `[A][B]`  |
| **A overlaps B** | `o`    | A starts before B, they overlap       | `[A[B]A]` |
| **A starts B**   | `s`    | A and B start together, A ends first  | `[AB]B`   |
| **A during B**   | `d`    | A occurs entirely within B            | `B[A]B`   |
| **A finishes B** | `f`    | A and B end together, B starts first  | `B[AB]`   |
| **A equals B**   | `=`    | A and B have identical time spans     | `[AB]`    |

### Inverse Relationships

- **B after A** (`>`) - inverse of before
- **B met-by A** (`mi`) - inverse of meets
- **B overlapped-by A** (`oi`) - inverse of overlaps
- **B started-by A** (`si`) - inverse of starts
- **B contains A** (`di`) - inverse of during
- **B finished-by A** (`fi`) - inverse of finishes
- **B equals A** (`=`) - equals is its own inverse

## Implementation Plan

### Phase 1: Core Interval Data Types

```elixir
defmodule AriaTimestrike.Temporal.Interval do
  @type t :: %__MODULE__{
    start: DateTime.t() | :unbounded,
    end: DateTime.t() | :unbounded,
    label: String.t()
  }

  @type relation :: :before | :meets | :overlaps | :starts | :during |
                   :finishes | :equals | :after | :met_by | :overlapped_by |
                   :started_by | :contains | :finished_by
end
```

### Phase 2: Relationship Detection

```elixir
defmodule AriaTimestrike.Temporal.Relations do
  @spec relate(Interval.t(), Interval.t()) :: Interval.relation()
  def relate(interval_a, interval_b)

  @spec satisfies?(Interval.t(), Interval.t(), Interval.relation()) :: boolean()
  def satisfies?(interval_a, interval_b, relation)
end
```

### Phase 3: Compositional Reasoning

```elixir
defmodule AriaTimestrike.Temporal.Composition do
  @spec compose(Interval.relation(), Interval.relation()) :: [Interval.relation()]
  def compose(relation_ab, relation_bc)

  @spec infer_relations(map()) :: {:ok, map()} | {:error, :inconsistent}
  def infer_relations(constraint_network)
end
```

### Phase 4: Temporal Constraint Satisfaction

```elixir
defmodule AriaTimestrike.Temporal.CSP do
  @spec propagate_constraints(map()) :: {:ok, map()} | {:error, :inconsistent}
  def propagate_constraints(constraint_network)

  @spec check_consistency(map()) :: boolean()
  def check_consistency(constraint_network)
end
```

## Integration with Temporal Planner

### Action Temporal Constraints

Actions in the temporal planner will use Allen's relationships to express:

- **Precedence**: `action_a before action_b`
- **Synchronization**: `action_a meets action_b`
- **Overlapping Execution**: `action_a overlaps action_b`
- **Containment**: `complex_action contains sub_action`

### State Temporal Reasoning

Game states will be associated with time intervals, allowing:

- **State Persistence**: How long conditions remain true
- **State Transitions**: Temporal relationships between state changes
- **Causal Reasoning**: Inferring state relationships from action timing

### Multi-Agent Coordination

Allen's algebra will support:

- **Simultaneous Actions**: Multiple agents acting `equals` in time
- **Sequential Coordination**: Agent actions in `before/after` chains
- **Overlapping Coordination**: Actions that `overlap` for cooperation

## Benefits

1. **Mathematical Rigor**: Formal semantics eliminate ambiguity in temporal reasoning
2. **Completeness**: All possible interval relationships are expressible
3. **Compositionality**: Complex temporal networks can be reasoned about systematically
4. **Proven Foundation**: Extensively used and validated in temporal AI systems
5. **Constraint Propagation**: Automatic inference of implicit temporal relationships

## Consequences

### Positive

- Enables sophisticated temporal planning and reasoning
- Provides foundation for multi-agent temporal coordination
- Supports complex temporal constraints in game scenarios
- Allows formal verification of temporal plan properties

### Negative

- Increases complexity of the temporal reasoning system
- Requires careful implementation to maintain performance
- May need optimization for real-time game scenarios
- Learning curve for developers unfamiliar with interval algebra

## References

- Allen, J.F. (1983). "Maintaining knowledge about temporal intervals"
- Vilain, M., & Kautz, H. (1986). "Constraint propagation algorithms for temporal reasoning"
- Dechter, R., Meiri, I., & Pearl, J. (1991). "Temporal constraint networks"

## Related ADRs

- ADR-042: Staged TDD Implementation for Temporal Planner
- ADR-041: Temporal Solver Tech Stack Requirements
- ADR-034: TimeStrike Temporal Planner Enhancement

---

**Date**: 2025-06-15  
**Authors**: K. S. Ernest (iFire) Lee  
**Status**: Accepted  
**Impacts**: AriaTimestrike temporal planner, multi-agent coordination, temporal constraint satisfaction

## Shorthand Notation for Constraints

While the interval relationships are powerful, writing them as formal logical expressions can be cumbersome. A more convenient shorthand notation is often used to define the temporal constraints for actions or events. This notation makes the existence of an interval implicit.

This is interpreted to mean that if an interval exists for the primary action (e.g., Turn), then other intervals must also exist that satisfy the specified temporal relationships.

### Examples

#### Turn Action Constraints
```
Turn(?target)            met-by   Pointing(?direction)
                         meets    Pointing(?target)
```

This constraint means:
- If a `Turn(?target)` action interval exists
- Then there must be a `Pointing(?direction)` interval that ends exactly when `Turn` begins
- And there must be a `Pointing(?target)` interval that begins exactly when `Turn` ends

#### Calibrate Action Constraints
```
Calibrate(?instrument)   met-by       Status(?instrument, On)
                         contained-by CalibrationTarget(?target)
                         contained-by Pointing(?target)
                         meets        Status(?instrument, Calibrated)
```

This constraint means:
- If a `Calibrate(?instrument)` action interval exists
- Then `Status(?instrument, On)` must end exactly when `Calibrate` begins
- And `CalibrationTarget(?target)` must contain the entire `Calibrate` interval
- And `Pointing(?target)` must also contain the entire `Calibrate` interval
- And `Status(?instrument, Calibrated)` must begin exactly when `Calibrate` ends

### Shorthand Notation Benefits

1. **Conciseness**: More readable than full logical expressions
2. **Implicit Intervals**: No need to explicitly declare interval variables
3. **Natural Expression**: Mirrors how temporal constraints are naturally described
4. **Implementation Ready**: Can be directly parsed into constraint networks

### Implementation in AriaTimestrike

```elixir
defmodule AriaTimestrike.Temporal.Constraints do
  @type constraint :: {atom(), atom(), any()}
  @type relation_constraint :: {relation(), constraint()}
  
  @spec parse_shorthand(String.t()) :: [relation_constraint()]
  def parse_shorthand(constraint_text)
  
  @spec compile_constraints([relation_constraint()]) :: constraint_network()
  def compile_constraints(shorthand_constraints)
end
```
