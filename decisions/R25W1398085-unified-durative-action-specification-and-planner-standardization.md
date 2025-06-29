# R25W1398085: Unified Durative Action Specification

<!-- @adr_serial R25W1398085 -->

**Status:** Completed  
**Date:** 2025-06-28  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Understanding Planning](#understanding-planning)
3. [Core Specification](#core-specification)
4. [Implementation Guide](#implementation-guide)
5. [Reference & Standards](#reference--standards)

---

## Quick Reference

### Entity Model Summary

Everything is an entity with capabilities:

```elixir
# Entity types with capabilities
%{type: "agent", capabilities: [:cooking, :menu_planning]}
%{type: "oven", capabilities: [:heating, :baking]}
%{type: "kitchen", capabilities: [:workspace]}
%{type: "flour", capabilities: [:consumable]}
```

### Temporal Patterns (8 Valid Combinations)

| Pattern | start | end | duration | Semantics |
|---------|-------|-----|----------|-----------|
| 1 | ❌ | ❌ | ❌ | Instant action, anytime |
| 2 | ❌ | ❌ | ✅ | Floating duration |
| 3 | ❌ | ✅ | ❌ | Deadline constraint |
| 4 | ❌ | ✅ | ✅ | **Calculated start** (`start = end - duration`) |
| 5 | ✅ | ❌ | ❌ | Open start |
| 6 | ✅ | ❌ | ✅ | **Calculated end** (`end = start + duration`) |
| 7 | ✅ | ✅ | ❌ | Fixed interval |
| 8 | ✅ | ✅ | ✅ | **Constraint validation** (`start + duration = end`) |

### Method Types Overview

The AriaEngine planner uses six types of methods for different purposes:

- **@action** - Direct state changes (cooking, moving, etc.)
- **@command** - Execution-time logic with failure handling
- **@task_method** - Break complex goals into smaller steps
- **@unigoal_method** - Handle single predicate goals like "location" or "status"
- **@multigoal_method** - Optimize solving multiple goals together
- **@multitodo_method** - Optimize processing lists of work items

### Method Selection Guide (Quick Reference for Experienced Developers)

*This table shows Elixir function signatures for each method type. If you're new to the system, skip to [Understanding Planning](#understanding-planning) first.*

| Method Type | Purpose | Function Signature |
|-------------|---------|-------------------|
| @action | Direct state transformations | `@spec action_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} \| {:error, atom()}` |
| @command | Execution-time logic | `@spec command_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} \| {:error, atom()}` |
| @task_method | Break down complex workflows | `@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]} \| {:error, atom()}` |
| @unigoal_method | Handle single predicate goals | `@spec method_name(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} \| {:error, atom()}` |
| @multigoal_method | Optimize multiple goal solving | `@spec multigoal_method(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} \| {:error, atom()}` |
| @multitodo_method | Optimize todo list processing | `@spec multitodo_method(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} \| {:error, atom()}` |

#### Component Breakdown

**Key Elements in the Function Signatures:**

- **`@spec`** - Elixir type specification that defines input and output types
- **`AriaState.t()`** - The current world state containing all facts and entities
- **`[term()]`** - List of parameters passed to the function (varies by method)
- **`{:ok, result} | {:error, atom()}`** - Standard Elixir success/failure return pattern
- **`AriaEngine.todo_item()`** - Work items that can be planned and executed by the system
- **`subject()`, `value()`** - Type aliases for goal components (typically strings or atoms)

### Primary API Functions

```elixir
# Planning only - returns solution tree
@spec plan(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, AriaEngineCore.Plan.solution_tree()} | {:error, atom()}

# Planning + execution - returns final state  
@spec run_lazy(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}

# Take a pre-made plan and execute it.
@spec run_lazy_tree(AriaEngine.Domain.t(), AriaState.t(), AriaEngineCore.Plan.solution_tree()) :: {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}
```

**Key Types:**

- `solution_tree()` - Complete planning result with actions, constraints, and metadata
- `final_state()` - World state after successful execution

**API Design Rationale:**

- `plan/3` only returns solution tree since planning doesn't modify state
- `run_lazy/3` and `run_lazy_tree/3` return both final state and solution tree since execution modifies state

### Required Function Attributes

```elixir
@action true
@command true
@task_method true
@unigoal_method predicate: "is_predicate"
@multigoal_method true
@multitodo_method true
```

**Documentation:** Use standard Elixir `@doc` attributes for all method documentation. This follows established Elixir patterns and integrates with ExDoc and IDE tooling.

### Action Method Examples

```elixir
# Direct state transformations
@doc "Transforms meal state from preparation to ready using cooking workflow"
@action duration: "PT2H", requires_entities: [%{type: "agent", capabilities: [:cooking]}]
@spec cook_meal(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}

@doc "Validates ingredient availability for meal preparation"
@action true
@spec check_ingredients(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}

@doc "Scheduled preparation workflow with fixed timing constraints"
@action start: "2025-06-22T10:00:00-07:00", duration: "PT1H"
@spec scheduled_prep(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
```

### Command Method Examples

```elixir
# Execution-time logic with failure handling
@command true
@spec cook_meal_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}

@command true
@spec validate_equipment(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}

@command true
@spec emergency_shutdown(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
```

### Task Method Examples

```elixir
# Complex workflow decomposition
@task_method true
@spec prepare_complete_meal(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@task_method true
@spec setup_kitchen_workspace(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@task_method true
@spec cleanup_after_cooking(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
```

### Unigoal Method Examples

```elixir
# Primary goal handling patterns
@unigoal_method predicate: "location"
@spec move_to_location(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@unigoal_method predicate: "has_item"  
@spec acquire_item(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@unigoal_method predicate: "temperature"
@spec set_temperature(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@unigoal_method predicate: "status"
@spec change_status(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
```

### Multigoal Method Examples

```elixir
# Multiple goal optimization
@multigoal_method true
@spec optimize_cooking_batch(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}

@multigoal_method true
@spec allocate_kitchen_resources(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}

@multigoal_method true
@spec coordinate_meal_prep(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}
```

### Multitodo Method Examples

```elixir
# Todo list optimization
@multitodo_method true
@spec optimize_cooking_sequence(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@multitodo_method true
@spec parallelize_prep_tasks(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@multitodo_method true
@spec reorder_by_dependencies(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
```

### Goal Format Standard

**ONLY use this format:**

```elixir
{predicate, subject, value}  # ✅ CORRECT
```

### State Validation

**ONLY use direct fact checking:**

```elixir
AriaState.RelationalState.get_fact(state, predicate, subject)  # ✅ CORRECT
```

---

## Understanding Planning

### Why Planning Feels "Backwards"

**Normal Programming (Imperative):**

```elixir
# You control execution directly
def make_dinner() do
  go_to_kitchen()     # Step 1
  get_ingredients()   # Step 2  
  cook_meal()        # Step 3
  {:ok, :dinner_made}
end

make_dinner()  # Call when you want it
```

**Planning (Declarative):**

```elixir
# You describe what's possible
@action duration: "PT2H", requires_entities: [
  %{type: "chef", capabilities: [:cooking]}
]
def cook_meal(state, [meal_id]) do
  # Called BY THE PLANNER, not by you
  state |> set_fact("meal_status", meal_id, "ready")
end

# You give goals, planner figures out steps
AriaEngine.plan(domain, state, [{"meal_status", "dinner", "ready"}])
```

### The Mental Model Shift

**Instead of:** "Do step 1, then step 2, then step 3"  
**Think:** "Here are the tools available, here's what I want, figure it out"

### When Planning Scales

**Single Agent (feels overkill):**

- One chef making one meal

**Multiple Agents (planning shines):**

- Restaurant with 5 chefs, 3 ovens, 20 orders
- Automatic resource allocation
- Failure recovery
- Temporal optimization

---

## Core Specification

### Entity Registration Pattern

Before planning, entities must be registered with types and capabilities:

```elixir
@action true
@spec register_entity(AriaState.t(), [String.t(), String.t(), [capability()]]) :: {:ok, AriaState.t()} | {:error, atom()}
def register_entity(state, [entity_id, type, capabilities]) do
  state
  |> AriaState.RelationalState.set_fact("type", entity_id, type)
  |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
  |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  {:ok, state}
end
```

### Domain Definition Syntax

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  @type meal_id :: String.t()
  
  # Simple durative action
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]}
          ]
  @spec cook_meal(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal(state, [meal_id]) do
    state |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
    {:ok, state}
  end
end
```

### Temporal Specification Patterns

**Pattern 1: Instant action, anytime**

```elixir
@action true # Instant action, planner chooses when
```

**Pattern 2: Floating Duration**

```elixir
@action duration: "PT2H" # Takes 2 hours, planner chooses when
```

**Pattern 4: Calculated Start (Deadline)**

```elixir
@action end: "2025-06-22T14:00:00-07:00", duration: "PT2H" # Must start by 12 PM
```

**Pattern 6: Calculated End**

```elixir
@action start: "2025-06-22T10:00:00-07:00", duration: "PT2H"  # Ends at 12 PM
```

**Pattern 7: Fixed Interval**

```elixir
@action start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"
```

**Pattern 8: Validation**

```elixir
@action start: "2025-06-22T10:00:00-07:00", 
        end: "2025-06-22T12:00:00-07:00", 
        duration: "PT2H"  # System validates consistency
```

### Function Attribute Requirements

**Every planner function MUST have the corresponding attribute:**

```elixir
# Actions
@action true
@spec action_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}

# Commands  
@command true
@spec command_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, atom()}

# Task Methods
@task_method true
@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

@type subject :: term()
@type value :: term()

# Unigoal Methods
@unigoal_method predicate: "is_predicate"
@spec method_name(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

# Multigoal Methods
@multigoal_method true
@spec multigoal_method(AriaState.t(), AriaEngine.multigoal()) :: {:ok, AriaEngine.multigoal()} | {:error, atom()}

# Multitodo Methods
@multitodo_method true
@spec multitodo_method(AriaState.t(), [AriaEngine.todo_item()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
```

### Capabilities as Traits

Capabilities are simple traits for flexible composition:

```elixir
@type capability :: atom()

# Categories
:agent, :consumable, :tool, :appliance           # Categorical traits
:heating, :cutting, :cooking, :baking            # Behavioral capabilities  
:reusable, :portable, :stackable, :container     # Functional traits
:kitchen_equipment, :ingredient, :meeting_space  # Domain-specific
```

### Todo Items vs Domain-Level Optimization Methods

**Important Distinction:** Not all method types are todo_item types.

**Todo Item Types (work items that can be planned and executed):**

```elixir
@type todo_item :: 
  task() |                    # {task_name, args} - Composite workflows
  goal() |                    # {predicate, subject, value} - State goals  
  AriaEngine.Multigoal.t()    # Multiple coordinated goals
```

**Domain-Level Optimization Methods (NOT todo_items):**

- **@multigoal_method** - Optimizes how multiple goals are solved together
- **@multitodo_method** - Optimizes how todo lists are processed and ordered

These optimization methods operate at the domain/planner level to improve efficiency and coordination, but they are not individual work items that get planned and executed. They are meta-methods that enhance the planning process itself.

**Example:**

```elixir
# This IS a todo_item - can be planned and executed
{:cook_meal, ["pasta"]}

# This is NOT a todo_item - it's a domain optimization method
@multitodo_method true
def optimize_cooking_sequence(state, todo_list) do
  # Reorders todo_list for better efficiency
  {:ok, reordered_list}
end
```

---

## Implementation Guide

### Complete Working Example

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  @type meal_id :: String.t()
  @type ingredient_list :: [String.t()]
  
  # Entity setup
  @action true
  @spec setup_kitchen_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_kitchen_scenario(state, []) do
    state
    |> register_entity(["chef_1", "agent", [:cooking, :menu_planning]])
    |> register_entity(["oven_1", "oven", [:heating, :baking]])
    |> register_entity(["main_kitchen_1", "kitchen", [:workspace]])
    |> register_entity(["flour_bag_1", "flour", [:consumable]])
    {:ok, state}
  end
  
  # Instant actions (zero duration)
  @action duration: "PT0S",
          requires_entities: [%{type: "agent", capabilities: [:observation]}]
  @spec check_ingredients(AriaState.t(), [ingredient_list()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def check_ingredients(state, [ingredient_list]) do
    available_count = Enum.count(ingredient_list, fn ingredient ->
      AriaState.RelationalState.get_fact(state, "available", ingredient) == true
    end)
    
    state
    |> AriaState.RelationalState.set_fact("ingredients_checked", "kitchen", true)
    |> AriaState.RelationalState.set_fact("available_count", "kitchen", available_count)
    {:ok, state}
  end
  
  # Durative actions
  @action duration: "PT2H", 
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]},
            %{type: "kitchen", capabilities: [:workspace]}
          ]
  @spec cook_meal(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal(state, [meal_id]) do
    state
    |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "available")
    {:ok, state}
  end
  
  # Task methods for complex workflows
  @task_method true
  @spec prepare_complete_meal(AriaState.t(), [meal_id()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def prepare_complete_meal(state, [meal_id]) do
    {:ok, [
      # Prerequisites as goals
      {"available", "chef_1", true},
      {"temperature", "oven_1", {:>=, 350}},
      
      # Preparation tasks
      {:setup_workspace, []},
      {:gather_ingredients, [meal_id]},
      
      # Main cooking action
      {:cook_meal, [meal_id]},
      
      # Verification goals
      {"quality", meal_id, {:>=, 8}}
    ]}
  end
  
  # Commands for execution-time logic
  @command true
  @spec cook_meal_command(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal_command(state, [meal_id]) do
    case attempt_cooking_with_failure_chance(state, meal_id) do
      {:ok, new_state} -> 
        Logger.info("Cooking succeeded for #{meal_id}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("Cooking failed: #{reason}")
        {:error, reason}
    end
  end
  
  # Domain creation
  @spec create_domain(map()) :: AriaEngine.Domain.t()
  def create_domain(opts \\ %{}) do
    domain = __MODULE__.create_base_domain()
    domain = AriaEngine.Domain.set_verify_goals(domain, Map.get(opts, :verify_goals, true))
    domain = %{domain | blacklist: MapSet.new()}
    AriaEngine.Domain.enable_solution_tree(domain, true)
  end
  
  # Helper functions
  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.RelationalState.set_fact("type", entity_id, type)
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
    |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  end
  
  defp attempt_cooking_with_failure_chance(state, meal_id) do
    if :rand.uniform() > 0.1 do  # 90% success rate
      new_state = state
      |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
      {:ok, new_state}
    else
      {:error, "cooking_failed"}
    end
  end
end
```

### Usage Patterns

**"I want to see the plan before executing"**

When you need to review, validate, or modify the plan before execution. Use this for complex scenarios, debugging, or when you need approval workflows.

```elixir
# Create the plan first, inspect it, then decide whether to execute
case AriaEngineCore.plan(domain, state_with_entities, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "kitchen"}
]) do
  {:ok, solution_tree} ->
    # Inspect the plan - check timing, resource allocation, etc.
    IO.inspect(solution_tree, label: "Generated Plan")
    
    # Execute when ready
    AriaEngineCore.run_lazy_tree(domain, state_with_entities, solution_tree)
  {:error, reason} ->
    Logger.error("Planning failed: #{reason}")
end
```

**"I want it done automatically"**

When you just want to achieve your goals and don't care about planning details. Use this for simple goals, trusted domains, or production workflows.

```elixir
# Plan and execute in one step - fire and forget
case AriaEngineCore.run_lazy(domain, state_with_entities, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "kitchen"}
]) do
  {:ok, {final_state, solution_tree}} -> 
    Logger.info("Goals achieved successfully!")
    final_state
  {:error, reason} -> 
    Logger.error("Planning or execution failed: #{reason}")
end
```

**"I have a plan, just execute it"**

When you already have a validated plan to execute. Use this for batch processing, pre-approved workflows, or plan reuse scenarios.

```elixir
# Execute a solution tree that was created and validated earlier
case AriaEngineCore.run_lazy_tree(domain, state_with_entities, solution_tree) do
  {:ok, {final_state, updated_tree}} -> 
    Logger.info("Plan executed successfully!")
    final_state
  {:error, reason} -> 
    Logger.error("Plan execution failed: #{reason}")
end
```

**Commands vs Actions:**

```elixir
# Planning-time: Actions assume success for planning purposes
{:ok, solution_tree} = AriaEngineCore.plan(domain, state, [{:cook_meal, ["pasta"]}])

# Execution-time: Commands handle real-world failures
@command true
def cook_meal_command(state, [meal_id]) do
  case attempt_cooking_with_failure_chance(state, meal_id) do
    {:ok, new_state} -> {:ok, new_state}
    {:error, :oven_malfunction} -> {:error, :oven_malfunction}  # Triggers replanning
  end
end
```

### Best Practices

**1. Keep Actions Simple**

- Pure state transformations only
- No validation logic (planner handles this)
- No failure handling (use commands for that)

**2. Use Method Decomposition for Complexity**

- Prerequisites as goals
- Complex workflows as task methods
- Verification as separate goals

**3. Entity Registration**

- Register all entities before planning
- Include required facts: type, capabilities, status
- Use descriptive entity IDs

**4. Temporal Specifications**

- Use appropriate pattern for your use case
- Prefer floating durations when possible
- Use fixed intervals only when necessary

---

## Reference & Standards

### Success Criteria

**Planning Paradigm Alignment:**

- [x] Clear distinction between programming vs planning documented
- [x] All examples show planner-controlled execution
- [x] Action functions designed as pure state transformations
- [x] Domain registration supports planner discovery

**Technical Implementation:**

- [x] Floating durations and fixed intervals supported via ISO 8601
- [x] Unified action specification with entities and capabilities
- [x] All goals use `{predicate, subject, value}` format
- [x] State validation uses direct `State.get_fact/3` calls
- [x] Standardized `@action` attribute definitions

### Tombstoned Concepts

The following concepts were explicitly rejected:

1. **❌ `quantity` field in action metadata** - Quantities are state fluents
2. **❌ Separate `resources` map** - Everything is entities with capabilities
3. **❌ `properties` field in entity requirements** - Use capabilities instead
4. **❌ Separate `requires_agent` field** - Agents are entities with capabilities
5. **❌ `location` field in action metadata** - Locations are entities
6. **❌ Requirement validation in action functions** - Planner validates requirements
7. **❌ Mixed goal formats** - ONLY `{predicate, subject, value}` allowed
8. **❌ Complex state evaluation functions** - Use direct fact checking
9. **❌ Temporal conditions in durative actions** - Use method decomposition
10. **❌ Functions without attributes** - All planner functions need attributes

### Related ADRs

- **R25W1405B8B**: Technical Implementation Guide
- **R25W141BE8A**: Architecture & Standards  
- **R25W1421349**: Common Use Cases and Patterns

### Academic Foundation

This specification builds upon established research in automated planning:

**Temporal Planning:**

- Fox, M.; Long, D. (2003). "PDDL2.1: An Extension to PDDL for Expressing Temporal Planning Domains". *Journal of Artificial Intelligence Research*, 20:61-124.

**Automated Planning Theory:**

- Ghallab, M.; Nau, D.; Traverso, P. (2004). *Automated Planning: Theory and Practice*. Morgan Kaufmann.

**Constraint Programming:**

- Nethercote, N.; Stuckey, P.J.; et al. (2007). "MiniZinc: Towards a Standard CP Modelling Language". *CP 2007*.

**Temporal Reasoning:**

- Dechter, R.; Meiri, I.; Pearl, J. (1991). "Temporal constraint networks". *Artificial Intelligence*, 49(1-3):61-95.

**Standards:**

- ISO 8601-1:2019 Date and time representations
- Khronos Group glTF 2.0 and KHR_interactivity specifications

### Implementation Status

**Status:** Completed - Core specification fully implemented and integrated.  
**Usage:** Foundation for all AriaEngine domain development. All new domain definitions should use `AriaEngine.Domain`.  
**Timeline:** Available immediately.  
**Compatibility:** Full backward compatibility maintained.

### Overview

**Current State**: Multiple confusing and inconsistent patterns across AriaEngine planner

**Target State**: Single unified specification for durative actions with entities, capabilities, and temporal constraints

This specification provides a complete framework for temporal planning with durative actions, entity-based resource management, and hierarchical task decomposition. It addresses the complexity of multi-agent coordination while maintaining simplicity for single-agent scenarios.
