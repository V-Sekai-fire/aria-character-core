# KHR_interactivity Node Library - Standardized Interface Implementation

**Goal:** Complete glTF KHR_interactivity specification as Aria Engine actions with standardized interface pattern and comprehensive testing.

## Architecture Overview

### Two-Layer Design

**Layer 1: KHR Primitives (Explicit Node Addressing)**
- Direct glTF node control with explicit node indexing
- Pattern: `action(state, [node_index, ...inputs])`
- Perfect glTF spec compliance for reference runtime
- Used by: Direct node graph execution, debugging, testing

**Layer 2: Task Abstraction (Flow Control)**
- Hide node ID management behind task interface
- Pattern: `task: calculate_sequence([{:add, [5, 3]}, {:multiply, [:result, 2]}])`
- HTN planning interface: compose KHR primitives automatically
- Used by: Interactive behavior planning, complex workflows

### Standardized Interface Pattern

**All KHR primitives follow this contract:**

```elixir
def khr_action_name(state, [node_index | inputs]) do
  state
  |> StateV2.set_fact(Integer.to_string(node_index), "value", computed_result)
end
```

**Benefits:**
- Exact glTF node addressing: `"node_index" -> "value" -> result`
- Consistent state management across all operations
- Perfect compatibility with glTF node graph execution
- Composable primitives for higher-level behaviors

## Implementation Progress

### ✅ Completed Categories

**Math Constants** (4 actions)
- `khr_math_e`, `khr_math_pi`, `khr_math_inf`, `khr_math_nan`
- Pattern: `math_e(state, [node_index])`

**Math Arithmetic** (17 actions)  
- Unary: `abs`, `sign`, `neg`, `floor`, `ceil`, `round`, `trunc`, `fract`, `saturate`
- Binary: `add`, `sub`, `mul`, `div`, `rem`, `min`, `max`, `mix`
- Ternary: `clamp`
- Pattern: `math_add(state, [node_index, a, b])`

### 🚧 Remaining Categories

**Math Advanced**
- Trigonometry: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`
- Vector operations: `length`, `normalize`, `dot`, `cross`, `distance`
- Matrix operations: `multiply`, `transpose`, `inverse`, `determinant`
- Quaternion operations: `multiply`, `normalize`, `slerp`, `fromAxisAngle`

**Control Flow & Events**
- `flow_branch`, `flow_switch`, `flow_sequence`, `flow_loop`
- `event_trigger`, `event_listener`, `event_handler`

**Temporal Operations**
- `flow_delay`, `animation_start`, `animation_stop`, `timer_create`

**State Management**
- `variable_set`, `variable_get`, `pointer_get`, `pointer_set`

**Type Conversion & Debug**
- `convert_to_string`, `convert_to_number`, `debug_log`, `debug_assert`

## Testing Strategy

### Current Test Architecture

**Unit Tests** (Direct Function Calls)
```elixir
# Bypass planner - test primitives directly
result_state = KHRInteractivityDomain.math_abs(state, [4, 5.5])
assert StateV2.get_fact(result_state, "4", "value") == 5.5
```

**Integration Tests** (Simulated Planner Context)
```elixir
# Simulate planner but manually execute
case Planner.plan(domain, state, goals) do
  {:ok, plan} -> 
    # Still calls KHR functions directly in test
    final_state = execute_plan_manually(plan, state)
```

### Future: True Integration Tests
```elixir
# Planner handles everything automatically
{:ok, final_state} = HTNPlanner.execute_plan(domain, state, goals)
assert StateV2.get_fact(final_state, "calculated_node", "value") == expected
```

## Testing Structure

```
test/aria_engine/node_library/khr_interactivity/
├── unit/
│   ├── math_nodes_test.exs        # ✅ Completed - Standardized interface
│   ├── flow_nodes_test.exs        # 🚧 TODO
│   ├── temporal_nodes_test.exs    # 🚧 TODO
│   └── ...
└── integration/
    ├── planner_math_nodes_test.exs    # ✅ Completed - Simulated integration
    ├── planner_flow_nodes_test.exs    # 🚧 TODO
    ├── planner_temporal_nodes_test.exs # 🚧 TODO
    └── ...
```

## Implementation Requirements

**Every Node Must Have:**

1. **Standardized Interface**: `[node_index, ...inputs]` pattern
2. **Unit Test**: Direct function call verification  
3. **Integration Test**: Simulated planner context (current) or true planner execution (future)
4. **StateV2 Compatibility**: Proper fact storage and retrieval
5. **Domain Registration**: Auto-registration with `register_all_actions/1`
6. **Metadata**: `domain`, `category`, `khr_node_type`, `description`

## Node Library Structure

```
apps/aria_engine/lib/aria_engine/node_library/
└── khr_interactivity_domain.ex     # ✅ Single domain file with all actions
```

**Current Status**: Math constants and arithmetic complete with standardized interface.
**Next Steps**: Implement math trigonometry with same pattern, then control flow nodes.

**Key Principle**: All KHR primitives provide exact glTF compatibility while being composable building blocks for higher-level interactive behaviors.
