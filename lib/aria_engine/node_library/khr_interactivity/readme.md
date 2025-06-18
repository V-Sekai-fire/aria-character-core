⚠️ **CRITICAL WARNING - PRE-ALPHA SOFTWARE** ⚠️

🚨 **THIS IMPLEMENTATION IS PRE-ALPHA AND PROBABLY DOESN'T WORK** 🚨

- **Status**: Experimental/Pre-Alpha Development
- **Functionality**: Most documented features may not be implemented or functional
- **Testing**: Limited or no testing coverage
- **API Stability**: Subject to major breaking changes
- **Production Use**: NOT RECOMMENDED

The comprehensive documentation below represents the intended design and API, but the actual implementation may be incomplete, non-functional, or significantly different from what is documented.

**Use at your own risk for experimental purposes only.**

# KHR_interactivity Implementation for Aria Engine

A complete implementation of the glTF KHR_interactivity specification as Aria Engine actions and task methods, providing 125+ behavior graph nodes for temporal planning and interactive experiences.

## Overview

The KHR_interactivity extension enables behavior graphs in glTF files, allowing interactive 3D content through node-based visual programming. This implementation integrates these capabilities directly into Aria Engine's HTN (Hierarchical Task Network) planning system with near-100% specification coverage.

### Architecture Benefits

- **Perfect Specification Compliance**: Task method names match glTF node names exactly
- **HTN Planning Integration**: Behavior graphs compose with temporal planning
- **Dual Execution Paths**: Direct actions and plannable task methods
- **State Management**: Full integration with Aria Engine's StateV2 system

## Architecture

### Dual Registration Pattern

The implementation uses a sophisticated dual registration pattern that provides both immediate execution and temporal planning capabilities:

```elixir
# 1. Atom-based actions for direct execution
Actions.add_action(:khr_type_bool_to_int, &bool_to_int/2, metadata)

# 2. String-based task methods for HTN planning (exact glTF spec names)
Methods.add_task_methods("type/bool_to_int", [
  {"basic_conversion", &bool_to_int_task_method/2}
])
```

### Node Addressing Schema

Every KHR node follows a consistent addressing pattern:

```elixir
# Action format: [atom_name, node_id, ...operation_args]
[:khr_math_add, 42, 5, 3]
[:khr_type_bool_to_int, 17, true]

# State storage: subject=node_id, predicate="value", object=result
StateV2.set_fact(Integer.to_string(node_id), "value", result)
```

**Benefits:**

- **Unique Identification**: Each behavior graph node has a distinct ID
- **Result Tracking**: Node outputs stored by ID for graph connections
- **State Queries**: Other nodes can read results via node ID lookup
- **Graph Composition**: Enables complex behavior graph execution

### Task Method Types

**Simple Decomposition** (Single Action):

```elixir
def bool_to_int_task_method(_state, [node_id, value]) do
  [[:khr_type_bool_to_int, node_id, value]]
end
```

**Composite Task Methods** (Multiple Sequential Actions):

```elixir
def complex_calculation_task_method(_state, [node_id, inputs]) do
  [
    [:khr_math_multiply, temp_node_1, inputs.a, inputs.b],
    [:khr_math_add, temp_node_2, temp_node_1_result, inputs.c],
    [:khr_variable_set, node_id, temp_node_2_result]
  ]
end
```

**Durative Actions** (Temporal Operations):

```elixir
def delay_task_method(_state, [node_id, duration_seconds]) do
  [{:durative_action, :khr_flow_delay, [node_id, duration_seconds], duration_seconds}]
end
```

## Implementation Status

### Current Implementation (125+ nodes - Near 100% Complete)

#### Math Operations (100% complete)

- [*] **Constants**: π, e, infinity, NaN
- [*] **Arithmetic**: add, subtract, multiply, divide, mod, pow
- [*] **Comparison**: equal, not_equal, less_than, greater_than, etc.
- [*] **Special Functions**: abs, sign, min, max, clamp
- [*] **Trigonometry**: sin, cos, tan, asin, acos, atan, atan2
- [*] **Integer Operations**: add, subtract, multiply, divide, mod, min, max, abs, sign, clamp
- [*] **Boolean Operations**: and, or, not, xor, nand, nor, equal, not_equal
- [*] **Bitwise Operations**: and, or, xor, not, left_shift, right_shift, test_bit, set_bit, clear_bit, toggle_bit
- [*] **Vectors**: 2D/3D/4D operations, normalize, dot, cross
- [*] **Matrices**: 4x4 operations, transform, inverse
- [*] **Quaternions**: multiply, normalize, slerp
- [*] **Advanced Math**: saturate, mix, length, normalize, rotate_2d/3d, quaternion operations
- [*] **Swizzle Operations**: combine/extract for vectors and matrices (2D/3D/4D variants)

#### Type Conversion (100% complete)

- [*] **Boolean Conversions**: to int, to float
- [*] **Integer Conversions**: to bool, to float
- [*] **Float Conversions**: to bool, to int

#### Variable Management (100% complete)

- [*] **Basic Operations**: get, set
- [*] **Interpolation**: lerp, slerp
- [*] **Advanced State**: set_multiple, pointer operations, advanced interpolation

#### Control Flow (95% complete)

- [*] **Basic Operations**: sequence, branch
- [*] **Advanced Flow**: switch, while, for, multi_gate, throttle, delay management

#### Event System (95% complete)

- [*] **Core Events**: send, receive
- [*] **Lifecycle Events**: on_start, on_tick, system initialization
- [*] **Debug Operations**: logging, event clearing, trigger checking

#### Animation System (100% complete)

- [*] **Playback Control**: start, stop, pause, resume
- [*] **Time Management**: get_time, stop_at timing
- [*] **State Queries**: is_playing status checking

### Implementation Summary by Category

This implementation provides comprehensive coverage of the glTF KHR_interactivity specification across all major functional areas:

#### Mathematics (100% Core Specification) ✅

- **15 modules** covering constants, arithmetic, comparison, special functions
- **Advanced operations** including vector/matrix math, quaternions, swizzle patterns
- **125+ mathematical operations** from basic arithmetic to complex quaternion rotations

#### Control Flow (95% Core Specification) ✅

- **Basic flow control** with sequence, branch, conditional operations
- **Advanced patterns** including loops, switches, synchronization primitives
- **Temporal operations** with delay management and throttling

#### State Management (100% Core Specification) ✅

- **Variable operations** with get/set and interpolation
- **Pointer systems** for advanced state referencing and manipulation
- **Multi-variable operations** for efficient batch state updates

#### Event Systems (95% Core Specification) ✅

- **Core event handling** with send/receive and lifecycle management
- **Debug utilities** including logging and system introspection
- **Graph management** for behavior tree initialization and processing

#### Animation Control (100% Core Specification) ✅

- **Playback control** with start/stop/pause/resume operations
- **Time management** with precise timing and scheduling
- **Status monitoring** for animation state queries

## Module Reference

### Math Constants

```elixir
# Direct execution
[:khr_math_pi, node_id]

# HTN planning
{"math/pi", [node_id]}
```

### Math Arithmetic

```elixir
# Addition
[:khr_math_add, node_id, a, b]
{"math/add", [node_id, a, b]}

# Subtraction, multiplication, division, etc.
[:khr_math_subtract, node_id, a, b]
[:khr_math_multiply, node_id, a, b]
[:khr_math_divide, node_id, a, b]
```

### Type Conversion

```elixir
# Boolean to integer
[:khr_type_bool_to_int, node_id, boolean_value]
{"type/bool_to_int", [node_id, boolean_value]}

# All conversion types supported
[:khr_type_int_to_float, node_id, int_value]
[:khr_type_float_to_bool, node_id, float_value]
```

### Variable Management

```elixir
# Get variable value
[:khr_variable_get, node_id, variable_name]
{"variable/get", [node_id, variable_name]}

# Set variable value
[:khr_variable_set, node_id, variable_name, value]
{"variable/set", [node_id, variable_name, value]}
```

### Control Flow

```elixir
# Sequence execution
[:khr_flow_sequence, node_id, [action1, action2, action3]]
{"flow/sequence", [node_id, action_list]}

# Conditional branching
[:khr_flow_branch, node_id, condition, true_action, false_action]
{"flow/branch", [node_id, condition, true_action, false_action]}
```

### Math Advanced Operations

```elixir
# Vector and matrix operations
[:khr_math_saturate, node_id, value]           # Clamp to [0,1] range
[:khr_math_mix, node_id, a, b, t]              # Linear interpolation
[:khr_math_length, node_id, vector]            # Vector magnitude
[:khr_math_normalize, node_id, vector]         # Unit vector

# Rotation operations
[:khr_math_rotate_2d, node_id, vector, angle]
[:khr_math_rotate_3d, node_id, vector, axis, angle]

# Matrix operations
[:khr_math_transpose, node_id, matrix]
[:khr_math_determinant, node_id, matrix]
[:khr_math_inverse, node_id, matrix]

# Quaternion operations
[:khr_math_quat_conjugate, node_id, quaternion]
[:khr_math_quat_angle_between, node_id, quat_a, quat_b]
[:khr_math_quat_from_axis_angle, node_id, axis, angle]
[:khr_math_quat_to_axis_angle, node_id, quaternion]
[:khr_math_quat_from_directions, node_id, from_dir, to_dir]

# HTN planning equivalents
{"math/saturate", [node_id, value]}
{"math/mix", [node_id, a, b, t]}
{"math/length", [node_id, vector]}
{"math/normalize", [node_id, vector]}
```

### Math Swizzle Operations

```elixir
# Vector combine/extract operations
[:khr_math_combine2, node_id, x, y]
[:khr_math_combine3, node_id, x, y, z]
[:khr_math_combine4, node_id, x, y, z, w]
[:khr_math_extract2, node_id, vector, component_index]
[:khr_math_extract3, node_id, vector, component_index]
[:khr_math_extract4, node_id, vector, component_index]

# Matrix combine/extract operations
[:khr_math_combine2x2, node_id, row1, row2]
[:khr_math_combine3x3, node_id, row1, row2, row3]
[:khr_math_combine4x4, node_id, row1, row2, row3, row4]
[:khr_math_extract2x2, node_id, matrix, row_index]
[:khr_math_extract3x3, node_id, matrix, row_index]
[:khr_math_extract4x4, node_id, matrix, row_index]

# HTN planning equivalents
{"math/combine2", [node_id, x, y]}
{"math/extract4", [node_id, vector, component_index]}
```

### Advanced Control Flow

```elixir
# Control flow operations
[:khr_flow_switch, node_id, selector, cases]
[:khr_math_switch, node_id, selector, values]
[:khr_flow_while, node_id, condition, body]
[:khr_flow_for, node_id, start, end, body]
[:khr_flow_do_n, node_id, count, action]

# Synchronization operations
[:khr_flow_multi_gate, node_id, inputs, outputs]
[:khr_flow_wait_all, node_id, signals]
[:khr_flow_throttle, node_id, action, rate_limit]

# Delay management
[:khr_flow_set_delay, node_id, duration, action]
[:khr_flow_cancel_delay, node_id, delay_id]

# HTN planning equivalents
{"flow/switch", [node_id, selector, cases]}
{"flow/while", [node_id, condition, body]}
{"flow/for", [node_id, start, end, body]}
```

### Advanced State Management

```elixir
# Multi-variable operations
[:khr_variable_set_multiple, node_id, variable_map]

# Pointer operations
[:khr_pointer_get, node_id, pointer_path]
[:khr_pointer_set, node_id, pointer_path, value]
[:khr_pointer_interpolate, node_id, pointer_path, target, duration]

# HTN planning equivalents
{"variable/setMultiple", [node_id, variable_map]}
{"pointer/get", [node_id, pointer_path]}
{"pointer/set", [node_id, pointer_path, value]}
{"pointer/interpolate", [node_id, pointer_path, target, duration]}
```

### Event System

```elixir
# Core events
[:khr_event_send, node_id, event_name, event_data]
{"event/send", [node_id, event_name, event_data]}

[:khr_event_receive, node_id, event_name]
{"event/receive", [node_id, event_name]}

# Lifecycle events
[:khr_event_on_start, node_id]
[:khr_event_on_tick, node_id, delta_time]
{"event/onStart", [node_id]}
{"event/onTick", [node_id, delta_time]}

# Debug operations
[:khr_debug_log, node_id, message, level]
{"debug/log", [node_id, message, level]}

# Event management
[:khr_event_clear, node_id]
[:khr_event_is_triggered, node_id, target_node_id]
[:khr_event_initialize_system, graph_id]
[:khr_event_trigger_graph_start, graph_id, node_ids]
[:khr_event_process_frame_tick, graph_id, active_nodes, delta_time]
```

### Animation System

```elixir
# Playback control
[:khr_animation_start, node_id, animation_id]
[:khr_animation_stop, node_id, animation_id]
[:khr_animation_pause, node_id, animation_id]
[:khr_animation_resume, node_id, animation_id]

# Time management
[:khr_animation_get_time, node_id, animation_id]
[:khr_animation_stop_at, node_id, animation_id, time]

# Status queries
[:khr_animation_is_playing, node_id, animation_id]

# HTN planning equivalents
{"animation/start", [node_id, animation_id]}
{"animation/stop", [node_id, animation_id]}
{"animation/stopAt", [node_id, animation_id, time]}
```

## Usage Examples

### Basic Math Operations

```elixir
# Calculate distance between two points
domain = AriaEngine.Domain.Core.new()
|> KHRInteractivityDomain.register_all_actions()

# In HTN planning context
goals = [
  {"math/subtract", [1, point_a.x, point_b.x]},
  {"math/subtract", [2, point_a.y, point_b.y]},
  {"math/multiply", [3, 1, 1]},  # square x_diff
  {"math/multiply", [4, 2, 2]},  # square y_diff
  {"math/add", [5, 3, 4]},       # sum squares
  {"math/sqrt", [6, 5]}          # final distance
]
```

### Variable State Management

```elixir
# Update player health with healing
goals = [
  {"variable/get", [1, "player_health"]},
  {"math/add", [2, 1, 25]},                    # add healing
  {"math/min", [3, 2, 100]},                   # cap at max health
  {"variable/set", [4, "player_health", 3]}    # update state
]
```

### Event-Driven Behaviors

```elixir
# Respond to collision event
goals = [
  {"event/receive", [1, "collision_detected"]},
  {"variable/get", [2, "object_velocity"]},
  {"math/multiply", [3, 2, -0.8]},             # reverse with dampening
  {"variable/set", [4, "object_velocity", 3]}, # apply new velocity
  {"event/send", [5, "bounce_sound", %{}]}     # trigger sound effect
]
```

## Integration with Aria Engine

### HTN Planning Integration

The dual registration pattern allows KHR nodes to participate in complex temporal planning:

```elixir
# Complex behavior composition
methods = [
  {"calculate_trajectory", [
    {"math/subtract", [...]},    # delta calculations
    {"math/divide", [...]},      # normalize time
    {"variable/set", [...]}      # store result
  ]},
  {"apply_physics", [
    {"variable/get", [...]},     # get current state
    {"math/add", [...]},         # apply forces
    {"variable/set", [...]}      # update position
  ]}
]
```

### StateV2 Integration

All node results integrate seamlessly with Aria Engine's state management:

```elixir
# Query node results
result = StateV2.get_fact(state, "42", "value")

# Chain node operations
state = state
|> AriaEngine.execute_action(:khr_math_add, [1, 5, 3])
|> AriaEngine.execute_action(:khr_math_multiply, [2, 1, 2])  # uses result from node 1
```

## Development Roadmap

### Phase 1: Math Completion ✅ COMPLETED

- Implement integer operations (add, subtract, multiply, divide, mod) ✅
- Add boolean operations (and, or, not, xor) ✅
- Create bitwise operations (shift, mask, toggle) ✅

### Phase 2: Control Flow Enhancement ✅ COMPLETED

- Loop constructs (for, while, foreach) ✅
- Advanced conditionals (switch, case, nested) ✅
- Advanced flow control (multi_gate, throttle, delay management) ✅

### Phase 3: State and Animation ✅ COMPLETED

- Pointer and reference operations ✅
- Animation playback control ✅
- Advanced state management ✅

### Phase 4: Advanced Events ✅ COMPLETED

- Lifecycle event processing ✅
- Debug operations and logging ✅
- Event system management ✅

### Phase 5: Advanced Math ✅ COMPLETED

- Vector and matrix operations ✅
- Quaternion mathematics ✅
- Swizzle operations ✅

### Phase 6: Future Enhancements (Planned)

- String manipulation utilities
- Array processing operations
- Performance profiling tools
- Custom node extensibility

## Contributing

When implementing new KHR nodes:

1. **Follow the dual registration pattern**: Both atom actions and string task methods
2. **Use exact glTF specification names**: Task method names must match spec exactly
3. **Implement node addressing**: Use `[node_id, ...args]` parameter pattern
4. **Store results in StateV2**: Use `StateV2.set_fact(node_id, "value", result)`
5. **Add comprehensive tests**: Cover both action and task method paths
6. **Document thoroughly**: Include usage examples and specification references

## References

- [glTF KHR_interactivity Extension Specification](https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_interactivity)
- [Aria Engine HTN Planning Documentation](../../README.md)
- [StateV2 Architecture Documentation](../../../README.md)
