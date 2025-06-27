# R25W1405B8B: Technical Implementation - Duration Handling and Validation

<!-- @adr_serial R25W1405B8B -->

**Status:** Active
**Date:** 2025-06-22  
**Priority:** MEDIUM
**Parent ADR:** R25W1398085 (Core Specification)

## Overview

**Current State**: Duration handling loses microsecond precision through unnecessary `round()` calls
**Target State**: Preserve Timex's microsecond precision throughout the entire duration conversion chain

## How the Planner Search Actually Works

### Demystifying the "Brute Force"

When people say planners do "brute force" search, it sounds scary - like the computer is randomly trying everything. But it's actually intelligent search with smart pruning. Here's what really happens when you ask for pasta:

**Step 1: Goal Analysis**

```elixir
# You want: {"chef", "has_meal", "pasta"}
# Planner asks: "What actions could make this true?"
# Searches action metadata for effects that set "has_meal" to "pasta"
# Finds: cook_meal action
```

**Step 2: Requirement Checking**

```elixir
# cook_meal requires: chef + ingredients + oven
# Planner asks: "Do we have these entities with the right capabilities?"
# Checks current state for available entities
# Missing: ingredients
```

**Step 3: Recursive Planning**

```elixir
# Planner asks: "What actions could get ingredients?"
# Finds: gather_ingredients action
# Checks requirements: chef + market access
# Available: chef is free, market is open
```

**Step 4: Plan Construction**

```elixir
# Builds plan: [gather_ingredients, cook_meal]
# Validates temporal constraints: gathering takes 30min, cooking takes 2h
# Checks resource conflicts: chef can't do both simultaneously
# Result: Sequential plan with proper timing
```

### Why Entity Requirements Matter for Search

The `requires_entities` metadata isn't just documentation - it's how the planner prunes the search space:

```elixir
@action duration: "PT2H",
        requires_entities: [
          %{type: "chef", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]}
        ]
def cook_meal(state, [meal_type]) do
  # Implementation
end
```

**Without entity requirements:** Planner would try cook_meal even when no chef is available, fail during execution, and waste time backtracking.

**With entity requirements:** Planner checks availability BEFORE adding action to plan, avoiding impossible paths entirely.

### Search Pruning in Action

```elixir
# Scenario: Chef is in meeting until 3pm, cooking takes 2 hours
# Goal: Have dinner ready by 5pm

# Naive search would try:
# 1. Start cooking at 1pm (FAIL - chef unavailable)
# 2. Start cooking at 2pm (FAIL - chef unavailable) 
# 3. Start cooking at 3pm (SUCCESS - chef free, finishes by 5pm)

# Smart search with entity validation:
# 1. Check chef availability for 2-hour window before 5pm
# 2. Find chef free from 3pm-5pm
# 3. Schedule cooking for 3pm (SUCCESS on first try)
```

This is why the planner feels "magical" - it's not trying random combinations, it's using the metadata to intelligently navigate the solution space.

## Timex Integration Requirements

All temporal validation and parsing MUST use Timex instead of Elixir's base DateTime functionality for enhanced ISO 8601 support, better timezone handling, and more robust duration parsing.

### Required Timex Functions

```elixir
# Replace DateTime.from_iso8601/1 with Timex parsing
# Before: DateTime.from_iso8601("2025-06-22T10:00:00Z")
# After: Timex.parse("2025-06-22T10:00:00Z", "{ISO:Extended}")

# Replace basic duration parsing with Timex.Duration
# Before: Regex-based ISO 8601 duration validation
# After: Timex.Duration.parse("PT2H")

# Replace DateTime.compare/2 with Timex comparison
# Before: DateTime.compare(start_dt, end_dt)
# After: Timex.compare(start_dt, end_dt)
```

## Precision Preservation Implementation

### Phase 1: Remove Precision Loss Points

**Target locations where `round()` destroys precision:**

- [x] **Line 95**: `Duration.to_seconds(duration) |> round()` → Remove `round()`
- [x] **Line 67**: `seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`  
- [x] **Line 75**: `min_seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`
- [x] **Line 83**: `seconds |> round() |> seconds_to_duration_struct()` → Remove `round()`
- [x] **Line 280**: `Duration.to_seconds(duration) |> round()` → Remove `round()`

### Phase 2: Updated Duration Struct Format

**Change from integer-only to float-supporting:**

```elixir
# Before (precision loss):
%{hours: 1, minutes: 30, seconds: 45}

# After (precision preserved):
%{hours: 1, minutes: 30, seconds: 45.123456}
```

### Phase 3: Helper Function Updates

```elixir
# seconds_to_duration_struct/1 - preserve fractional seconds
@spec seconds_to_duration_struct(number()) :: %{hours: non_neg_integer(), minutes: non_neg_integer(), seconds: number()}
def seconds_to_duration_struct(total_seconds) when is_number(total_seconds) do
  hours = trunc(total_seconds / 3600)
  remaining_seconds = total_seconds - (hours * 3600)
  minutes = trunc(remaining_seconds / 60)
  seconds = remaining_seconds - (minutes * 60)  # Keep as float

  %{
    hours: hours,
    minutes: minutes,
    seconds: seconds  # Float with fractional part preserved
  }
end

# duration_struct_to_seconds/1 - handle float seconds
@spec duration_struct_to_seconds(map()) :: number()
def duration_struct_to_seconds(duration) when is_map(duration) do
  hours = Map.get(duration, :hours, 0)
  minutes = Map.get(duration, :minutes, 0)
  seconds = Map.get(duration, :seconds, 0)

  hours * 3600 + minutes * 60 + seconds  # Result is float if seconds is float
end

# valid_duration?/1 - accept float seconds
@spec valid_duration?(map()) :: boolean()
def valid_duration?(duration) when is_map(duration) do
  hours = Map.get(duration, :hours, 0)
  minutes = Map.get(duration, :minutes, 0)
  seconds = Map.get(duration, :seconds, 0)

  is_integer(hours) and hours >= 0 and
    is_integer(minutes) and minutes >= 0 and minutes < 60 and
    is_number(seconds) and seconds >= 0 and seconds < 60  # Changed to number()
end
```

## Validation Framework Implementation

### ISO 8601 Temporal Validation

```elixir
# ISO 8601 datetime validation using Timex
@spec validate_iso8601_datetime(String.t(), String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
defp validate_iso8601_datetime(datetime_string, field_name) when is_binary(datetime_string) do
  case Timex.parse(datetime_string, "{ISO:Extended}") do
    {:ok, datetime} ->
      {:ok, datetime}
    {:error, reason} ->
      {:error, "invalid ISO 8601 datetime for #{field_name}: #{reason}"}
  end
end

# ISO 8601 duration validation using Timex
@spec validate_iso8601_duration(String.t()) :: {:ok, Timex.Duration.t()} | {:error, String.t()}
defp validate_iso8601_duration(duration_string) when is_binary(duration_string) do
  case Timex.Duration.parse(duration_string) do
    {:ok, duration} ->
      {:ok, duration}
    {:error, reason} ->
      {:error, "invalid ISO 8601 duration: #{reason}"}
  end
end

# Start/end time comparison using Timex
@spec validate_start_before_end(String.t(), String.t()) :: :ok | {:error, String.t()}
defp validate_start_before_end(start_string, end_string) do
  with {:ok, start_dt} <- Timex.parse(start_string, "{ISO:Extended}"),
       {:ok, end_dt} <- Timex.parse(end_string, "{ISO:Extended}") do
    if Timex.compare(start_dt, end_dt) == -1 do
      :ok
    else
      {:error, "start time must be before end time"}
    end
  end
end
```

### Temporal Specification Validation

```elixir
@spec validate_temporal_specification(map()) :: {:ok, map()} | {:error, list()}
def validate_temporal_specification(metadata) do
  case extract_temporal_fields(metadata) do
    %{duration: duration} when is_binary(duration) ->
      validate_iso8601_duration(duration)
      
    %{start: start_time, end: end_time} ->
      with {:ok, _} <- validate_iso8601_datetime(start_time, "start"),
           {:ok, _} <- validate_iso8601_datetime(end_time, "end"),
           :ok <- validate_start_before_end(start_time, end_time) do
        {:ok, %{start: start_time, end: end_time}}
      end
      
    %{start: start_time} ->
      validate_iso8601_datetime(start_time, "start")
      
    %{end: end_time} ->
      validate_iso8601_datetime(end_time, "end")
      
    %{} ->
      # No temporal specification - default to zero duration
      {:ok, %{duration: "PT0S"}}
      
    invalid ->
      {:error, [%{
        field: "temporal_specification",
        message: "Invalid temporal specification format",
        value: invalid,
        expected: "duration string OR start/end datetimes"
      }]}
  end
end
```

## Entity Requirements Validation (Planner-Level Only)

### Planner-Level Entity Validation Framework

**CRITICAL:** Entity validation occurs at planning time, NOT in action functions.

```elixir
# Planner validates requirements before action selection
defmodule AriaEngine.Planner.EntityValidator do
  @spec validate_action_requirements(AriaState.t(), map()) :: {:ok, [String.t()]} | {:error, list()}
  def validate_action_requirements(state, action_metadata) do
    case Map.get(action_metadata, :requires_entities, []) do
      entities when is_list(entities) ->
        validate_entity_availability(state, entities)
      invalid ->
        {:error, [%{
          field: "requires_entities",
          message: "Entity requirements must be a list",
          value: invalid,
          expected: "List of entity requirement maps"
        }]}
    end
  end

  @spec validate_entity_availability(AriaState.t(), [map()]) :: {:ok, [String.t()]} | {:error, String.t()}
  defp validate_entity_availability(state, entity_requirements) do
    Enum.reduce_while(entity_requirements, {:ok, []}, fn entity_req, {:ok, acc} ->
      case find_available_entity(state, entity_req) do
        {:ok, entity_id} -> {:cont, {:ok, [entity_id | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @spec find_available_entity(AriaState.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  defp find_available_entity(state, %{type: type, capabilities: capabilities}) do
    # Find entities with required type and capabilities that are available
    entities = find_entities_with_capabilities(state, capabilities)
    |> Enum.filter(fn entity_id ->
      AriaState.RelationalState.get_fact(state, entity_id, "type") == type and
      AriaState.RelationalState.get_fact(state, entity_id, "available") == true
    end)

    case entities do
      [entity_id | _] -> {:ok, entity_id}
      [] -> {:error, "No available entity with type #{type} and capabilities #{inspect(capabilities)}"}
    end
  end
end
```

**❌ TOMBSTONED: Entity validation in action functions**

Actions must NOT validate their own requirements. This is the planner's responsibility.

## CRITICAL ENFORCEMENT: Function Attribute Requirements

**Every function that integrates with the planner system MUST have the corresponding attribute:**

### Required Attribute Patterns

**Planner Actions:**

```elixir
@action duration: "PT2H", requires_entities: [...]
def action_name(state, args) do
  # Can reference @action metadata
end
```

**Execution Commands:**

```elixir
@command
def command_name(state, args) do
  # Execution-time logic only
end
```

**Task Methods:**

```elixir
@task_method
def task_name(state, args) do
  # Task decomposition logic
end
```

**Unigoal Methods:**

```elixir
@unigoal_method predicate: "location"
def method_name(state, [subject, value]) do
  # Goal decomposition logic
end
```

**Multigoal Methods:**

```elixir
@multigoal_method goal_pattern: :pattern_name
def method_name(state, multigoal) do
  # Multigoal handling logic
end
```

### Violation Examples (FORBIDDEN)

❌ **WRONG - No attribute but references planner metadata:**

```elixir
def cook_meal(state, [meal_type]) do  # No @action attribute
  case validate(@action[:requires_entities]) do  # ❌ References non-existent metadata
end
```

❌ **WRONG - No attribute but presented as planner function:**

```elixir
def travel_to_location(state, [subject, target]) do  # No @unigoal_method attribute
  # Presented as unigoal method but not registered with planner
end
```

✅ **CORRECT - Helper function (no planner integration):**

```elixir
defp calculate_cooking_time(meal_type) do  # Private helper
  # No planner metadata references, no attribute needed
end
```

**ENFORCEMENT:** Functions without attributes are helper functions only - no planner integration allowed.

## Temporal Conditions/Effects System

### Universal Todo List Support in Temporal Conditions

Temporal conditions now support **any todo list item type**, not just goals:

```elixir
# Enhanced temporal conditions with mixed todo types
%Domain.DurativeAction{
  name: :collaborative_cooking,
  duration: {:fixed, 3600},
  
  # Entity requirements with temporal conditions
  requires_entities: [
    %{type: "agent", capabilities: [:cooking, :teamwork]},
    %{type: "agent", capabilities: [:prep_work]},
    %{type: "oven", capabilities: [:heating, :baking]}
  ],
  
  conditions: %{
    at_start: [
      # Goals (state conditions) - SIMULTANEOUS achievement required
      {"available", "chef_1", true},
      {"available", "prep_cook", true}, 
      {"temperature", "oven", {:>=, 350}},
      
      # Tasks (complex operations)
      {:preheat_workspace, []},
      {:gather_team, ["cooking_crew"]},
      
      # Actions (direct state changes)
      {:lock_kitchen_door, []},
      {:start_timer, ["cooking_session"]},
      
      # Multigoals (simultaneous goal sets)
      [{"clean", "workspace", true}, {"organized", "ingredients", true}]
    ],
    
    over_all: [
      # Ongoing state conditions
      {"coordination", "team", "active"},
      {"temperature", "oven", {:between, 350, 450}},
      
      # Continuous tasks
      {:monitor_cooking_progress, ["meal_id"]},
      {:maintain_workspace_cleanliness, []}
    ],
    
    at_end: [
      # Final state requirements
      {"quality", "meal", {:>=, 8}},
      {"cleanup", "kitchen", "complete"},
      
      # Completion tasks
      {:final_quality_check, ["meal_id"]},
      {:document_cooking_session, ["session_log"]}
    ]
  },
  
  effects: %{
    at_start: [
      {"status", "chef_1", "cooking"},
      {"status", "prep_cook", "assisting"},
      {"status", "oven", "in_use"}
    ],
    over_time: [
      {"experience", "team", {:increase, 1}},
      {"kitchen_heat", "environment", {:increase, 2}}
    ],
    at_end: [
      {"status", "meal", "ready"},
      {"status", "chef_1", "available"},
      {"status", "prep_cook", "available"},
      {"status", "oven", "available"}
    ]
  }
}
```

### Temporal Condition Validation Framework

```elixir
defmodule AriaEngine.TemporalConditionValidator do
  @type todo_item :: goal() | task() | action() | multigoal()
  @type goal :: {String.t(), String.t(), any()}
  @type task :: {atom(), list()}
  @type action :: {atom(), list()}
  @type multigoal :: [goal()]
  
  @spec validate_temporal_conditions(map()) :: {:ok, term()} | {:error, String.t()}
  def validate_temporal_conditions(conditions) when is_map(conditions) do
    validators = [
      &validate_at_start_conditions/1,
      &validate_over_all_conditions/1,
      &validate_at_end_conditions/1
    ]
    
    run_validators(conditions, validators)
  end
  
  @spec validate_at_start_conditions(map()) :: {:ok, term()} | {:error, String.t()}
  defp validate_at_start_conditions(%{at_start: conditions}) when is_list(conditions) do
    validate_todo_list(conditions, "at_start")
  end
  defp validate_at_start_conditions(_), do: {:ok, :no_at_start_conditions}
  
  @spec validate_over_all_conditions(map()) :: {:ok, term()} | {:error, String.t()}
  defp validate_over_all_conditions(%{over_all: conditions}) when is_list(conditions) do
    validate_todo_list(conditions, "over_all")
  end
  defp validate_over_all_conditions(_), do: {:ok, :no_over_all_conditions}
  
  @spec validate_at_end_conditions(map()) :: {:ok, term()} | {:error, String.t()}
  defp validate_at_end_conditions(%{at_end: conditions}) when is_list(conditions) do
    validate_todo_list(conditions, "at_end")
  end
  defp validate_at_end_conditions(_), do: {:ok, :no_at_end_conditions}
  
  @spec validate_todo_list([todo_item()], String.t()) :: {:ok, [term()]} | {:error, String.t()}
  defp validate_todo_list(todo_items, condition_type) do
    Enum.reduce_while(todo_items, {:ok, []}, fn item, {:ok, acc} ->
      case validate_todo_item(item, condition_type) do
        {:ok, validated_item} -> {:cont, {:ok, [validated_item | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  @spec validate_todo_item(todo_item(), String.t()) :: {:ok, term()} | {:error, String.t()}
  defp validate_todo_item({predicate, subject, value}, _condition_type) 
       when is_binary(predicate) and is_binary(subject) do
    # Goal validation
    {:ok, {:goal, {predicate, subject, value}}}
  end
  
  defp validate_todo_item({task_name, args}, _condition_type) 
       when is_atom(task_name) and is_list(args) do
    # Task validation
    {:ok, {:task, {task_name, args}}}
  end
  
  defp validate_todo_item(multigoal, condition_type) when is_list(multigoal) do
    # Multigoal validation - all items must be goals
    case Enum.all?(multigoal, &is_goal?/1) do
      true -> {:ok, {:multigoal, multigoal}}
      false -> {:error, "Invalid multigoal in #{condition_type}: all items must be goals"}
    end
  end
  
  defp validate_todo_item(invalid, condition_type) do
    {:error, "Invalid todo item in #{condition_type}: #{inspect(invalid)}"}
  end
  
  @spec is_goal?(term()) :: boolean()
  defp is_goal?({predicate, subject, _value}) 
       when is_binary(predicate) and is_binary(subject), do: true
  defp is_goal?(_), do: false
end
```

### Todo Type Processing Integration

```elixir
defmodule AriaEngine.TemporalProcessor do
  @spec process_temporal_condition(term(), AriaState.t(), AriaEngine.Domain.t(), String.t()) :: {:ok, term()} | {:error, String.t()}
  def process_temporal_condition(todo_item, state, domain, condition_type) do
    case todo_item do
      {:goal, {predicate, subject, value}} ->
        # Direct state checking
        current_value = AriaState.RelationalState.get_fact(state, predicate, subject)
        validate_goal_condition(current_value, value, condition_type)
        
      {:task, {task_name, args}} ->
        # Task decomposition and execution
        case Domain.get_task_methods(domain, task_name) do
          [] -> {:error, "No methods available for task #{task_name}"}
          methods -> execute_task_for_condition(methods, state, args, condition_type)
        end
        
      {:action, {action_name, args}} ->
        # Direct action execution
        Domain.execute_action(domain, state, action_name, args)
        
      {:multigoal, goals} ->
        # Simultaneous goal satisfaction
        validate_multigoal_condition(goals, state, condition_type)
    end
  end
  
  @spec validate_goal_condition(term(), term(), String.t()) :: {:ok, term()} | {:error, String.t()}
  defp validate_goal_condition(current_value, expected_value, condition_type) do
    case condition_type do
      "at_start" -> check_immediate_satisfaction(current_value, expected_value)
      "over_all" -> check_continuous_satisfaction(current_value, expected_value)
      "at_end" -> check_final_satisfaction(current_value, expected_value)
    end
  end
  
  @spec validate_multigoal_condition([{String.t(), String.t(), term()}], AriaState.t(), String.t()) :: {:ok, :multigoal_satisfied} | {:error, String.t()}
  defp validate_multigoal_condition(goals, state, condition_type) do
    # All goals must be satisfied simultaneously
    results = Enum.map(goals, fn {predicate, subject, value} ->
      current_value = AriaState.RelationalState.get_fact(state, predicate, subject)
      validate_goal_condition(current_value, value, condition_type)
    end)
    
    case Enum.all?(results, fn result -> match?({:ok, _}, result) end) do
      true -> {:ok, :multigoal_satisfied}
      false -> {:error, "Multigoal not satisfied in #{condition_type}"}
    end
  end
end
```

## Type Specifications

### Updated Duration Types

```elixir
# Support float seconds while maintaining backward compatibility
@type duration_struct :: %{
  hours: non_neg_integer(),
  minutes: non_neg_integer(),
  seconds: number()  # Changed from integer() to number() (includes float)
}

@spec seconds_to_duration_struct(number()) :: duration_struct()
@spec duration_struct_to_seconds(duration_struct()) :: number()
@spec validate_iso8601_duration(String.t()) :: {:ok, Timex.Duration.t()} | {:error, String.t()}
@spec validate_iso8601_datetime(String.t(), String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
```

## Backward Compatibility Strategy

The changes are backward compatible because:

- Integer seconds still work (1 is a valid float)
- Existing callers get more precision, not less
- Duration struct format is internal to Utils module
- All existing APIs continue to work unchanged

## Success Criteria

- [x] **Microsecond precision preserved** through entire conversion chain
- [x] **Timex precision utilized** instead of discarded
- [x] **No breaking changes** to existing API
- [x] **Better temporal accuracy** for scheduling and timing systems
- [x] **All existing tests pass** with enhanced precision
- [x] **Comprehensive validation framework** for all metadata types

## Related ADRs

- **R25W1398085**: Core Specification (parent ADR)
- **R25W141BE8A**: Architecture & Standards (system integration)
- **R25W1421349**: Developer Guide (usage examples)

## Implementation Status

**Status:** Active - Duration precision preservation under ongoing refinement

**Usage:** Enhanced temporal accuracy for all AriaEngine operations

**Timeline:** Available immediately

**Integration:** Full integration with validation framework and temporal constraints
