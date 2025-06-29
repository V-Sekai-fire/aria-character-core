# AriaCore: Unified Action Specification System

This directory contains the complete implementation of the unified action specification system as defined in ADR R25W1398085, providing a clean, module-based approach to domain creation with automatic registration and temporal processing.

## Overview

AriaCore implements a **sociable testing approach** that leverages existing AriaCore systems rather than reimplementing domain logic. The system enables developers to create domains using simple `@action` and `@task_method` attributes while automatically handling entity management, temporal processing, and state management.

## Architecture

### Phase 1: Action Attributes Processing (`action_attributes.ex`)

Processes `@action`, `@command`, `@task_method`, `@unigoal_method`, `@multigoal_method`, and `@multitodo_method` attributes from domain modules:

```elixir
@action duration: "PT2H",
        requires_entities: [%{type: "agent", capabilities: [:cooking]}],
        preconditions: [{"ingredient_available", "tomato", true}],
        effects: [{"meal_status", "soup", "ready"}]
def cook_soup(state, [soup_id]) do
  AriaState.RelationalState.set_fact(state, "meal_status", soup_id, "ready")
end
```

**Features:**

- Automatic metadata extraction from module attributes
- Entity registry creation from action requirements
- Temporal specifications generation from duration metadata
- Integration with existing AriaCore.Domain system

### Phase 2: Module-based Domain Creation (`unified_domain.ex`)

Creates fully functional domains from modules using the sociable testing approach:

```elixir
# Create domain from module
domain = AriaCore.UnifiedDomain.create_from_module(RestaurantDomain)

# Domain is fully compatible with existing systems
{:ok, plan} = AriaEngineCore.plan(domain, initial_state, goals)
```

**Features:**

- Leverages existing `AriaCore.Domain.new()` (no rewrite needed)
- Automatic entity registry setup from action requirements
- Temporal specifications integration
- Domain merging and validation capabilities

## Method Types (R25W1398085 Specification)

The AriaEngine planner uses six types of methods for different purposes:

### @action - Direct State Changes

```elixir
@action duration: "PT2H",
        requires_entities: [%{type: "agent", capabilities: [:cooking]}]
def cook_meal(state, [meal_id]) do
  state |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
  {:ok, state}
end
```

### @command - Execution-time Logic with Failure Handling

```elixir
@command true
def cook_meal_command(state, [meal_id]) do
  case attempt_cooking_with_failure_chance(state, meal_id) do
    {:ok, new_state} -> {:ok, new_state}
    {:error, reason} -> {:error, reason}
  end
end
```

### @task_method - Complex Workflow Decomposition

```elixir
@task_method true
def prepare_complete_meal(state, [meal_id]) do
  {:ok, [
    {"ingredient_available", "main_ingredient", true},
    {:prep_ingredients, [meal_id]},
    {:cook_main_course, [meal_id]},
    {:quality_check, [meal_id]},
    {"meal_status", meal_id, "ready"}
  ]}
end
```

### @unigoal_method - Single Predicate Goal Handling

```elixir
@unigoal_method predicate: "location"
def move_to_location(state, {subject, value}) do
  {:ok, [
    {"available", subject, true},
    {:move_action, [subject, value]},
    {"location", subject, value}
  ]}
end
```

### @multigoal_method - Multiple Goal Optimization

```elixir
@multigoal_method true
def optimize_cooking_batch(state, multigoal) do
  # Reorder or optimize goals for better efficiency
  {:ok, optimized_multigoal}
end
```

### @multitodo_method - Todo List Optimization

```elixir
@multitodo_method true
def optimize_cooking_sequence(state, todo_list) do
  # Reorder todo_list for better efficiency
  {:ok, reordered_list}
end
```

## Temporal Patterns Support (8 Valid Combinations)

The system supports all 8 temporal patterns from R25W1398085:

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

## Supporting Systems

### Entity Management (`entity/management.ex`)

Complete entity management system supporting the action attribute requirements:

```elixir
# Automatic entity registry from action metadata
registry = AriaCore.Entity.Management.new_registry()
|> AriaCore.Entity.Management.register_entity_type(%{
  type: "chef", 
  capabilities: [:cooking, :baking]
})

# Entity matching for action requirements
{:ok, matches} = AriaCore.Entity.Management.match_entities(registry, requirements)
```

### Temporal Processing (`temporal/interval.ex`)

Comprehensive temporal system supporting all duration formats and patterns:

```elixir
# ISO 8601 duration parsing
duration = AriaCore.Temporal.Interval.parse_iso8601("PT2H30M")  # {:fixed, 9000}

# Variable durations
variable = AriaCore.Temporal.Interval.variable(1800, 7200)  # {:variable, {1800, 7200}}

# Conditional durations based on state
conditional = AriaCore.Temporal.Interval.conditional(%{
  {"skill_level", "chef", :expert} => 1800,
  {"skill_level", "chef", :novice} => 3600
})
```

### State Management (`state/relational.ex`)

Relational state system using {predicate, subject, value} format:

```elixir
# Create and manage state
state = AriaState.RelationalState.new()
|> AriaState.RelationalState.set_fact("status", "chef_1", "available")
|> AriaState.RelationalState.set_fact("temperature", "oven_1", 350)

# Goal satisfaction checking
goals = [
  {"status", "chef_1", "available"},
  {"temperature", "oven_1", {:>=, 300}}
]
assert AriaState.RelationalState.satisfies_goals?(state, goals)
```

## Primary API Functions (R25W1398085)

```elixir
# Planning only - returns solution tree
@spec plan(AriaEngineCore.Domain.t(), AriaState.t(), [AriaEngineCore.todo_item()]) :: 
  {:ok, AriaEngineCore.Plan.solution_tree()} | {:error, atom()}

# Planning + execution - returns final state  
@spec run_lazy(AriaEngineCore.Domain.t(), AriaState.t(), [AriaEngineCore.todo_item()]) :: 
  {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}

# Take a pre-made plan and execute it
@spec run_lazy_tree(AriaEngineCore.Domain.t(), AriaState.t(), AriaEngineCore.Plan.solution_tree()) :: 
  {:ok, {AriaState.t(), AriaEngineCore.Plan.solution_tree()}} | {:error, atom()}
```

## Complete Example

The `examples/restaurant_domain.ex` demonstrates all system features:

```elixir
defmodule AriaCore.Examples.RestaurantDomain do
  use AriaCore.Domain

  # Simple action with basic requirements
  @action duration: "PT30M",
          requires_entities: [%{type: "agent", capabilities: [:cooking]}],
          preconditions: [{"ingredient_available", "tomato", true}],
          effects: [{"meal_status", "soup", "cooking"}]
  def cook_soup(state, [soup_id]) do
    state
    |> AriaState.RelationalState.set_fact("meal_status", soup_id, "cooking")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
    {:ok, state}
  end

  # Complex action with conditional duration
  @action duration: {:conditional, %{
            {"skill_level", "chef", :expert} => 1800,
            {"skill_level", "chef", :intermediate} => 2700,
            {"skill_level", "chef", :novice} => 3600
          }},
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :baking]},
            %{type: "equipment", capabilities: [:heating]}
          ]
  def bake_bread(state, [bread_id, chef_id, oven_id]) do
    # Implementation...
    {:ok, state}
  end

  # Task method for complex goal decomposition
  @task_method true
  def prepare_complete_meal_method(state, [meal_id]) do
    {:ok, [
      {"ingredient_available", "main_ingredient", true},
      {:prep_ingredients, [meal_id]},
      {:cook_main_course, [meal_id]},
      {:quality_check, [meal_id]},
      {"meal_status", meal_id, "ready"}
    ]}
  end

  # Unigoal method for location handling
  @unigoal_method predicate: "location"
  def move_to_location(state, {subject, value}) do
    {:ok, [
      {"available", subject, true},
      {:move_action, [subject, value]},
      {"location", subject, value}
    ]}
  end
end

# Usage
domain = AriaCore.UnifiedDomain.create_from_module(RestaurantDomain)
state = RestaurantDomain.create_test_state()
goals = RestaurantDomain.create_test_goals()

# Ready for planning and execution with existing AriaCore systems
```

## Entity Model (Everything is an Entity)

Everything is an entity with capabilities:

```elixir
# Entity types with capabilities
%{type: "agent", capabilities: [:cooking, :menu_planning]}
%{type: "oven", capabilities: [:heating, :baking]}
%{type: "kitchen", capabilities: [:workspace]}
%{type: "flour", capabilities: [:consumable]}
```

## Goal Format Standard

**ONLY use this format:**

```elixir
{predicate, subject, value}  # ✅ CORRECT
```

## State Validation

**ONLY use direct fact checking:**

```elixir
AriaState.RelationalState.get_fact(state, predicate, subject)  # ✅ CORRECT
```

## Testing

Comprehensive test suite in `test/aria_core/unified_action_specification_test.exs` validates:

- All implementation phases
- Integration between systems
- Sociable testing approach verification
- Error handling and edge cases
- Complete workflow from module to execution

## Key Benefits

### Sociable Testing Approach

- **Leverages existing systems**: No reimplementation of core AriaCore functionality
- **Maintains compatibility**: New domains work with existing planning and execution systems
- **Reduces complexity**: Builds on proven, tested infrastructure

### Developer Experience

- **Simple syntax**: Clean `@action` and `@task_method` attributes
- **Automatic processing**: Entity registry and temporal specs generated automatically
- **Full integration**: Seamless integration with existing AriaCore systems

### System Architecture

- **Modular design**: Each component has a single, well-defined responsibility
- **Extensible**: Easy to add new temporal patterns or entity types
- **Maintainable**: Clear separation of concerns and comprehensive documentation

## Usage Patterns

### Basic Domain Creation

```elixir
# 1. Define domain module with attributes
defmodule MyDomain do
  use AriaCore.Domain
  
  @action duration: "PT1H", requires_entities: [...]
  def my_action(state, args), do: # implementation
end

# 2. Create domain
domain = AriaCore.UnifiedDomain.create_from_module(MyDomain)

# 3. Use with existing AriaCore systems
{:ok, plan} = AriaEngineCore.plan(domain, state, goals)
```

### Multiple Domain Management

```elixir
# Create registry for multiple domains
modules = [CookingDomain, CleaningDomain, MaintenanceDomain]
registry = AriaCore.UnifiedDomain.create_domain_registry(modules)

# Merge domains as needed
unified = AriaCore.UnifiedDomain.merge_domains([domain1, domain2])
```

### Validation and Debugging

```elixir
# Validate domain module
:ok = AriaCore.UnifiedDomain.validate_domain_module(MyDomain)

# Get comprehensive domain information
info = AriaCore.UnifiedDomain.get_domain_info(MyDomain)
```

This implementation provides a complete, production-ready unified action specification system that maintains compatibility with existing AriaCore infrastructure while providing a clean, modern interface for domain development according to R25W1398085 specification.
