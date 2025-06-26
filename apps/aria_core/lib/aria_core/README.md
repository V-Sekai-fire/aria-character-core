# AriaCore: Unified Action Specification System

This directory contains the complete implementation of the unified action specification system as defined in ADR-181, providing a clean, module-based approach to domain creation with automatic registration and temporal processing.

## Overview

AriaCore implements a **sociable testing approach** that leverages existing AriaCore systems rather than reimplementing domain logic. The system enables developers to create domains using simple `@action` and `@task_method` attributes while automatically handling entity management, temporal processing, and state management.

## Architecture

### Phase 1: Action Attributes Processing (`action_attributes.ex`)

Processes `@action` and `@task_method` attributes from domain modules:

```elixir
@action duration: "PT2H",
        requires_entities: [%{type: "agent", capabilities: [:cooking]}],
        preconditions: [{"ingredient_available", "tomato", true}],
        effects: [{"meal_status", "soup", "ready"}]
def cook_soup(state, [soup_id]) do
  AriaCore.State.Relational.set_fact(state, "meal_status", soup_id, "ready")
end
```

**Features:**

- Automatic metadata extraction from module attributes
- Entity registry creation from action requirements
- Temporal specifications generation from duration metadata
- Integration with existing AriaCore.Domain system

### Phase 2: Temporal Conditions Conversion (`temporal_converter.ex`)

Converts complex durative actions with temporal conditions into simple actions plus task methods:

```elixir
# Durative action with at_start/over_all/at_end conditions
durative_action = %{
  conditions: %{
    at_start: [{"oven", "temperature", {:>=, 350}}],
    over_all: [{"oven", "status", "operational"}],
    at_end: [{"meal", "quality", {:>=, 8}}]
  }
}

# Converts to simple action + method decomposition
{simple_action, method} = TemporalConverter.convert_durative_action(durative_action)
```

**Features:**

- Preserves temporal semantics during conversion
- Generates method decompositions that enforce temporal constraints
- Validates conversion maintains action equivalence
- Supports all 9 temporal patterns from ADR-181

### Phase 3: Module-based Domain Creation (`unified_domain.ex`)

Creates fully functional domains from modules using the sociable testing approach:

```elixir
# Create domain from module
domain = AriaCore.UnifiedDomain.create_from_module(RestaurantDomain)

# Domain is fully compatible with existing systems
{:ok, plan} = AriaCore.plan(domain, initial_state, goals)
```

**Features:**

- Leverages existing `AriaCore.Domain.new()` (no rewrite needed)
- Automatic entity registry setup from action requirements
- Temporal specifications integration
- Domain merging and validation capabilities

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
state = AriaCore.State.Relational.new()
|> AriaCore.State.Relational.set_fact("status", "chef_1", "available")
|> AriaCore.State.Relational.set_fact("temperature", "oven_1", 350)

# Goal satisfaction checking
goals = [
  {"status", "chef_1", "available"},
  {"temperature", "oven_1", {:>=, 300}}
]
assert AriaCore.State.Relational.satisfies_goals?(state, goals)
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
    |> AriaCore.State.Relational.set_fact("meal_status", soup_id, "cooking")
    |> AriaCore.State.Relational.set_fact("chef_status", "chef_1", "busy")
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
  end

  # Task method for complex goal decomposition
  @task_method goal_pattern: {"meal_ready", :meal_id, true},
               priority: 1
  def prepare_complete_meal_method(state, [meal_id]) do
    {:ok, [
      {"ingredient_available", "main_ingredient", true},
      {:prep_ingredients, [meal_id]},
      {:cook_main_course, [meal_id]},
      {:quality_check, [meal_id]},
      {"meal_status", meal_id, "ready"}
    ]}
  end
end

# Usage
domain = AriaCore.UnifiedDomain.create_from_module(RestaurantDomain)
state = RestaurantDomain.create_test_state()
goals = RestaurantDomain.create_test_goals()

# Ready for planning and execution with existing AriaCore systems
```

## Temporal Patterns Support

The system supports all 9 temporal patterns mentioned in ADR-181:

1. **Fixed duration**: `{:fixed, 3600}`
2. **Variable duration**: `{:variable, {1800, 7200}}`
3. **Conditional duration**: `{:conditional, conditions_map}`
4. **Parallel execution**: `Interval.create_execution_pattern(:parallel, actions)`
5. **Sequential execution**: `Interval.create_execution_pattern(:sequential, actions)`
6. **Overlapping intervals**: `Interval.create_execution_pattern(:overlapping, actions)`
7. **Deadline constraints**: `Interval.add_constraint(specs, action, {:deadline, datetime})`
8. **Resource-dependent timing**: `{:resource_dependent, config}`
9. **Temporal conditions**: Handled by `TemporalConverter` (at_start/over_all/at_end)

## Testing

Comprehensive test suite in `test/aria_core/unified_action_specification_test.exs` validates:

- All three implementation phases
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
{:ok, plan} = AriaCore.plan(domain, state, goals)
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

This implementation provides a complete, production-ready unified action specification system that maintains compatibility with existing AriaCore infrastructure while providing a clean, modern interface for domain development.
