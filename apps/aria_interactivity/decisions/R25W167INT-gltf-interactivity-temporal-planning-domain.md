# R25W167INT: glTF Interactivity Extension as Temporal Planning Domain

<!-- @adr_serial R25W167INT -->

**Status:** Active
**Date:** 2025-09-03
**Priority:** HIGH

## Contributors

- K. S. Ernest (iFire) Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Context

The glTF 2.0 Interactivity Extension (KHR_interactivity) defines a comprehensive node-based system for 3D asset behavior, but lacks integration with temporal planning systems. The aria_interactivity app bridges this gap by mapping glTF interactivity nodes to IPyHOP planning domain elements, enabling temporal goal-task planning for interactive 3D experiences.

### Current State

- **glTF Interactivity Extension**: Defines 50+ node types for 3D behavior (math, flow control, state, animation, events)
- **aria-hybrid-planner**: IPyHOP-based temporal planner with @action/@command/@method attributes
- **Missing Integration**: No mapping between glTF nodes and planning domain constructs

### Problem Statement

How can we map glTF interactivity nodes to IPyHOP planning domain elements to enable temporal planning for 3D interactive experiences?

## Decision

Create aria_interactivity app that maps glTF Interactivity Extension nodes to IPyHOP planning domain constructs using the following mapping:

### Node → Domain Element Mapping

| glTF Node Category | IPyHOP Element    | Domain Task-Goal Pattern                    |
| ------------------ | ----------------- | ------------------------------------------- |
| Math Operations    | @action/@command  | `math/add` → planning + execution           |
| Flow Control       | @task_method      | `flow/sequence` → task decomposition        |
| State Operations   | @unigoal_method   | `variable/set` → goal achievement           |
| Animation Control  | @unigoal_method   | `animation/play` → goal achievement         |
| Event Handling     | @unigoal_method   | `event/trigger` → goal achievement          |

### Domain Task-Goal Implementation Patterns

**@task_method Pattern (Inline Lambda Creation - RECOMMENDED):**

```elixir
# Primary pattern: Inline lambda creation for procedural temporal actions
@task_method true
@spec create_temporal_animation(AriaState.t(), [animation_index, duration, start_time, end_time, speed]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def create_temporal_animation(state, [animation_index, duration, start_time, end_time, speed]) do
  # Manual annotation: create metadata + lambda + spec
  metadata = [duration: duration, start: start_time, end: end_time]

  # Create lambda with captured parameters (direct parameter binding)
  lambda_action = fn(state) ->
    AriaHybridPlanner.Action.create_temporal(
      :animation_start,
      [animation_index, start_time, end_time, speed],
      metadata
    )
  end

  # Manual "annotation" by creating spec (bypasses compile-time attributes)
  spec = %{
    action_fn: lambda_action,
    duration: duration,
    start: start_time,
    end: end_time
  }

  {:ok, [{:temporal_action, spec}]}
end
```

_Inline lambda creation provides the cleanest approach for procedural temporal action generation_

### Manual Annotation Workaround for Lambda Actions

**Since lambda functions cannot use compile-time `@action` attributes, use this manual inline lambda creation process:**

#### **Pattern 2: Inline Lambda Creation (RECOMMENDED)**
```elixir
@task_method true
@spec create_annotated_lambda(AriaState.t(), [animation_index, duration, start_time, end_time, speed]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def create_annotated_lambda(state, [animation_index, duration, start_time, end_time, speed]) do
  # Manual annotation: create metadata + lambda + spec
  metadata = [duration: duration, start: start_time, end: end_time]

  # Create lambda with captured parameters
  lambda_action = fn(state) ->
    AriaHybridPlanner.Action.create_temporal(
      :animation_start,
      [animation_index, start_time, end_time, speed],
      metadata
    )
  end

  # Manual "annotation" by creating spec
  spec = %{
    action_fn: lambda_action,
    duration: duration,
    start: start_time,
    end: end_time
  }

  {:ok, [{:temporal_action, spec}]}
end
```

### **Key Manual Annotation Steps:**

1. **Create metadata keyword list** (replaces `@action` attributes)
2. **Create lambda with captured parameters** (direct parameter binding)
3. **Create action spec manually** (bypasses compile-time attribute processing)
4. **Return temporal action** (ready for planner execution)

### **Why This Pattern is Most Useful for Procedural Generation:**

- **Direct parameter capture**: Lambda captures `animation_index`, `duration`, `start_time`, `end_time`, `speed` directly
- **Self-contained**: Everything happens within the task method
- **Clean procedural flow**: Parameters → metadata → lambda → action spec
- **No external dependencies**: Doesn't require helper functions or domain modifications
- **Immediate execution**: Action is ready to use as soon as the task method returns

_This pattern is ideal for procedural temporal action generation where actions are created dynamically based on input parameters_

### Lambda Action Annotation Process

**For dynamically generated lambda actions, annotations are applied programmatically using converter functions:**

```elixir
# Programmatic annotation for lambda actions
@task_method true
@spec create_annotated_lambda_action(AriaState.t(), [animation_index, duration, start_time, end_time, speed]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def create_annotated_lambda_action(state, [animation_index, duration, start_time, end_time, speed]) do
  # Create metadata (this replaces @action attributes for lambdas)
  metadata = [
    duration: duration,
    start: start_time,
    end: end_time,
    requires_entities: [%{type: "animation_system", capabilities: [:playback]}]
  ]

  # Use converter to create action spec (this is the "annotation" process)
  action_spec = AriaCore.ActionAttributes.Converters.convert_action_metadata(
    metadata,
    :lambda_animation_action,
    __MODULE__
  )

  # Replace the action function with your lambda
  lambda_fn = fn(state, args) ->
    animation_start_impl(state, args)
  end

  action_spec = Map.put(action_spec, :action_fn, lambda_fn)

  {:ok, [
    {:temporal_action, action_spec,
     duration: duration,
     start: start_time,
     end: end_time,
     animation_index: animation_index,
     speed: speed}
  ]}
end

# Helper function for lambda annotation
defp create_annotated_lambda(metadata, lambda_fn) do
  # Convert metadata using converter (simulates @action attribute)
  action_spec = AriaCore.ActionAttributes.Converters.convert_action_metadata(
    metadata,
    :lambda_action,
    __MODULE__
  )

  # Attach lambda function
  Map.put(action_spec, :action_fn, lambda_fn)
end
```

_Programmatic annotation process for lambda-generated temporal actions_

**@action/@command Pattern (Math Operations with Manual Lambda Support):**

```elixir
# Static function with compile-time attributes
@action true
@spec math_add(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
def math_add(state, [a, b]) do
  # Direct state transformation - planning assumes success
  {:ok, state}
end

# Static command with compile-time attributes
@command true
@spec math_add_command(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
def math_add_command(state, [a, b]) do
  # Execution-time logic with failure handling
  {:ok, state}
end

# Manual lambda annotation for dynamic math operations
@task_method true
@spec create_dynamic_math_operation(AriaState.t(), [operation, a, b]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def create_dynamic_math_operation(state, [operation, a, b]) do
  # Manual annotation: create metadata for lambda
  metadata = [
    requires_entities: [%{type: "math_processor", capabilities: [:arithmetic]}]
  ]

  # Create lambda with dynamic operation
  math_lambda = fn(state) ->
    case operation do
      "add" -> math_add_impl(state, [a, b])
      "subtract" -> math_subtract_impl(state, [a, b])
      "multiply" -> math_multiply_impl(state, [a, b])
      "divide" -> math_divide_impl(state, [a, b])
    end
  end

  # Manual annotation using converter
  action_spec = AriaCore.ActionAttributes.Converters.convert_action_metadata(
    metadata,
    :dynamic_math_operation,
```

_Single predicate goal: `{predicate, subject, value}`_

**@unigoal_method Pattern (Animation Control):**

```elixir
@unigoal_method predicate: "animation_playing"
@spec play_animation(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def play_animation(state, {animation_id, true}) do
  # Handle single predicate goal: {predicate, subject, value}
  {:ok, []}
end
```

_Single predicate goal: `{predicate, subject, value}`_

**@unigoal_method Pattern (Event Handling):**

```elixir
@unigoal_method predicate: "event_triggered"
@spec trigger_event(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
def trigger_event(state, {event_id, true}) do
  # Handle single predicate goal: {predicate, subject, value}
  {:ok, []}
end
```

_Single predicate goal: `{predicate, subject, value}`_

### Implementation Architecture

```
glTF Specification → Node Parser → Domain Generator → IPyHOP Integration
     ↓                    ↓              ↓                ↓
Specification.adoc → Node Definitions → @action/@method → aria-hybrid-planner
```

## Implementation Plan

### Phase 1: Domain Definition (TDD Cycles 2-4)

**Manual Domain Creation:**

- Create `AriaInteractivity.Domain` module with glTF node mappings
- Use `@action`, `@command`, `@task_method`, `@unigoal_method` attributes
- Map core node categories: math, flow control, state operations

**Node Categories to Implement:**

- **Math Nodes**: add, subtract, multiply, divide, trigonometry, vector operations
- **Flow Control**: sequence, branch, while/for loops, multi-gate
- **State Management**: variable get/set, pointer operations
- **Animation Control**: start, stop, interpolate with temporal constraints
- **Event System**: receive, send with async handling

### Phase 2: Temporal Integration (TDD Cycles 5-6)

**Duration and Timing:**

- Map glTF animation durations to IPyHOP temporal constraints
- Implement R25W1398085's 8 temporal patterns
- Handle ISO 8601 duration parsing and validation

**Execution Semantics:**

- Convert glTF flow sockets to task dependencies
- Implement conditional execution via @task_method
- Support event-driven workflow decomposition

### Phase 3: Planning Integration (TDD Cycles 7-8)

**Goal-Task Translation:**

- Convert glTF behavior graphs to planning problems
- Map node connections to task networks
- Support hierarchical task decomposition

**Domain Validation:**

- Ensure compliance with glTF Interactivity Specification
- Validate against aria-hybrid-planner requirements
- Test end-to-end planning workflows

## Technical Architecture

### Domain Module Structure

```elixir
defmodule AriaInteractivity.Domain do
  use AriaCore.ActionAttributes

  # Math Operations - Action/Command pairs
  @action true
  @spec math_add(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def math_add(state, [a, b]) do
    # Direct state transformation - planning assumes success
    {:ok, state}
  end

  @command true
  @spec math_add_command(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def math_add_command(state, [a, b]) do
    # Execution-time logic with failure handling
    {:ok, state}
  end

  # Control Flow - Task Methods
  @task_method true
  @spec flow_sequence(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def flow_sequence(state, tasks) do
    # Complex workflow decomposition - returns todo_item list
    {:ok, []}
  end

  # State Operations - Unigoal Methods
  @unigoal_method predicate: "variable_set"
  @spec set_variable(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def set_variable(state, {subject, value}) do
    # Handle single predicate goal: {predicate, subject, value}
    {:ok, []}
  end

  # Animation Control - Unigoal Methods
  @unigoal_method predicate: "animation_playing"
  @spec play_animation(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def play_animation(state, {animation_id, true}) do
    # Handle single predicate goal: {predicate, subject, value}
    {:ok, []}
  end

  # Event Handling - Unigoal Methods
  @unigoal_method predicate: "event_triggered"
  @spec trigger_event(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def trigger_event(state, {event_id, true}) do
    # Handle single predicate goal: {predicate, subject, value}
    {:ok, []}
  end
end
```

### Integration Points

**With aria_gltf:**

- Access to Specification.adoc for node definitions
- glTF parsing infrastructure for asset integration
- 3D transformation utilities

**With aria-hybrid-planner:**

- IPyHOP execution engine for plan execution
- Temporal constraint solver for duration handling
- Entity registry for resource management

**With aria_joint:**

- Bone/joint manipulation for 3D interactivity
- Animation state management
- Skeletal transformation utilities

## Success Criteria

### Functional Requirements

- [ ] **Node Coverage**: Map all major glTF interactivity node categories
- [ ] **Temporal Accuracy**: Correct duration and timing constraint handling
- [ ] **Planning Integration**: Successful plan generation from glTF graphs
- [ ] **Execution Semantics**: Proper execution of generated plans

### Technical Requirements

- [ ] **IPyHOP Compliance**: Use correct @action/@command/@method attributes
- [ ] **glTF Specification**: Adhere to KHR_interactivity extension
- [ ] **Temporal Constraints**: Support R25W1398085 temporal patterns
- [ ] **Performance**: Efficient planning for complex node graphs

### Quality Assurance

- [ ] **TDD Coverage**: Red-green cycles for all domain elements
- [ ] **Integration Tests**: End-to-end planning workflows
- [ ] **Specification Compliance**: Validation against glTF spec
- [ ] **Documentation**: Complete ADR and code documentation

## Consequences

### Positive

- **Unified Architecture**: Single domain for glTF interactivity planning
- **Temporal Planning**: Enable complex temporal reasoning for 3D assets
- **Extensible Design**: Easy addition of new glTF node types
- **Performance**: Optimized for real-time interactive planning

### Negative

- **Complexity**: Mapping between two different paradigms (glTF nodes ↔ IPyHOP)
- **Maintenance**: Need to track glTF specification updates
- **Learning Curve**: Understanding both glTF interactivity and IPyHOP

### Risks

- **Specification Changes**: glTF interactivity extension may evolve
- **Performance Bottlenecks**: Complex node graphs may impact planning speed
- **Integration Complexity**: Coordinating multiple apps (aria_gltf, aria_joint, aria-hybrid-planner)

## Related ADRs

- **R25W1398085**: Unified Durative Action Specification (temporal patterns)
- **R25W1547587**: Align Hybrid Planner Execution with IPyHOP Pattern (execution model)
- **R25W051BA69**: Fix KHR Interactivity Planner Test Architecture (related work)
- **R25W052DE7D**: Fix KHR Interactivity Planner Goal Processing Pipeline (related work)

## Academic Foundation

### glTF Interactivity Extension

- Khronos Group KHR_interactivity specification
- Node-based behavior graphs for 3D assets
- Visual scripting paradigm for game engines

### IPyHOP Planning Framework

- Nau, D.; et al. "IPyHOP: An Integrated Planning and Execution Framework"
- HTN (Hierarchical Task Network) planning
- Action/command distinction for robust execution

### Temporal Planning

- Vidal, T. "Handling the Ramification Problem in Action Formalisms" (durative actions)
- R25W1398085 temporal constraint patterns
- ISO 8601 duration specifications

## Implementation Status

**Current Status:** Domain architecture defined, implementation beginning

**Next Steps:**

1. Complete TDD Cycle 2: Manual domain definition creation
2. Implement math operations as @action/@command pairs
3. Add flow control as @task_method implementations
4. Integrate temporal constraints and duration handling

**Timeline:** Target completion within 2-3 development cycles

---

_This ADR establishes the architectural foundation for mapping glTF interactivity nodes to IPyHOP planning domain elements, enabling temporal goal-task planning for interactive 3D experiences._
