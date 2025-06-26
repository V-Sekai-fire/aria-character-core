# ADR-181: Unified Durative Action Specification

**Status:** Active  
**Date:** 2025-06-22  
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

### Temporal Patterns (9 Valid Combinations)

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

### Required Function Attributes

```elixir
@action duration: "PT2H", requires_entities: [...]
@command true
@task_method true
@unigoal_method predicate: "location"
@multigoal_method goal_pattern: :pattern_name
@multitodo_method true
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

**Pattern 2: Floating Duration**

```elixir
@action duration: "PT2H"  # Takes 2 hours, planner chooses when
```

**Pattern 4: Calculated Start (Deadline)**

```elixir
@action end: "2025-06-22T14:00:00-07:00", duration: "PT2H"  # Must start by 12 PM
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
@type object :: term()

# Unigoal Methods
@unigoal_method predicate: "predicate"
@spec method_name(AriaState.t(), [subject(), object()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}

# Multigoal Methods
@multigoal_method goal_pattern: :pattern_name
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
    |> register_entity(["main_kitchen", "kitchen", [:workspace]])
    |> register_entity(["flour_bag", "flour", [:consumable]])
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

**Planning with Solution Tree:**

```elixir
domain = MyApp.Domains.CookingDomain.create_domain()

# Set up entities
initial_state = AriaState.new()
{:ok, state_with_entities} = setup_kitchen_scenario(initial_state, [])

# Plan with goals
{:ok, solution_tree, plan} = AriaEngine.plan_with_tree(domain, state_with_entities, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "kitchen"}
])

# Execute with replanning on failure
case AriaEngine.run_lazy_refineahead(domain, state_with_entities, solution_tree) do
  {:ok, final_state} -> Logger.info("Execution completed")
  {:error, reason} -> Logger.error("Execution failed: #{reason}")
end
```

**Commands vs Actions:**

```elixir
# Planning-time: Actions assume success
{:ok, plan} = AriaEngine.plan(domain, state, [{:cook_meal, ["pasta"]}])

# Execution-time: Commands handle failures
case AriaEngine.execute_command(domain, state, :cook_meal_command, ["pasta"]) do
  {:ok, new_state} -> Logger.info("Success")
  {:error, :oven_malfunction} -> Logger.warn("Replanning needed")
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

- **ADR-182**: Technical Implementation Guide
- **ADR-183**: Architecture & Standards  
- **ADR-184**: Common Use Cases and Patterns

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

**Status:** Active - Core specification under ongoing refinement  
**Usage:** Foundation for all AriaEngine domain development  
**Timeline:** Available immediately  
**Compatibility:** Full backward compatibility maintained

### Overview

**Current State**: Multiple confusing and inconsistent patterns across AriaEngine planner

**Target State**: Single unified specification for durative actions with entities, capabilities, and temporal constraints

This specification provides a complete framework for temporal planning with durative actions, entity-based resource management, and hierarchical task decomposition. It addresses the complexity of multi-agent coordination while maintaining simplicity for single-agent scenarios.
