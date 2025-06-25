# ADR-132: Technical Implementation - Duration Handling and Validation

**Status:** Completed
**Date:** 2025-06-22  
**Completion Date:** 2025-06-22
**Priority:** MEDIUM  
**Parent ADR:** ADR-131 (Core Specification)

## Overview

**Current State**: Duration handling loses microsecond precision through unnecessary `round()` calls
**Target State**: Preserve Timex's microsecond precision throughout the entire duration conversion chain

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
def duration_struct_to_seconds(duration) when is_map(duration) do
  hours = Map.get(duration, :hours, 0)
  minutes = Map.get(duration, :minutes, 0)
  seconds = Map.get(duration, :seconds, 0)

  hours * 3600 + minutes * 60 + seconds  # Result is float if seconds is float
end

# valid_duration?/1 - accept float seconds
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
defp validate_iso8601_datetime(datetime_string, field_name) when is_binary(datetime_string) do
  case Timex.parse(datetime_string, "{ISO:Extended}") do
    {:ok, datetime} ->
      {:ok, datetime}
    {:error, reason} ->
      {:error, "invalid ISO 8601 datetime for #{field_name}: #{reason}"}
  end
end

# ISO 8601 duration validation using Timex
defp validate_iso8601_duration(duration_string) when is_binary(duration_string) do
  case Timex.Duration.parse(duration_string) do
    {:ok, duration} ->
      {:ok, duration}
    {:error, reason} ->
      {:error, "invalid ISO 8601 duration: #{reason}"}
  end
end

# Start/end time comparison using Timex
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

## Entity Requirements Validation

### Entity Validation Framework

```elixir
def validate_entity_requirements(metadata) do
  case Map.get(metadata, :requires_entities, []) do
    entities when is_list(entities) ->
      validate_entity_list(entities)
    invalid ->
      {:error, [%{
        field: "requires_entities",
        message: "Entity requirements must be a list",
        value: invalid,
        expected: "List of entity requirement maps"
      }]}
  end
end

defp validate_single_entity(entity, index) do
  with {:ok, type} <- validate_entity_type(entity, index),
       {:ok, capabilities} <- validate_entity_capabilities(entity, index),
       {:ok, constraints} <- validate_entity_constraints(entity, index) do
    {:ok, %{type: type, capabilities: capabilities, constraints: constraints}}
  end
end

defp validate_entity_type(entity, index) do
  case Map.get(entity, :type) do
    type when is_binary(type) and type != "" ->
      {:ok, type}
    invalid ->
      {:error, [%{
        field: "requires_entities[#{index}].type",
        message: "Entity type must be a non-empty string",
        value: invalid,
        expected: "Non-empty string (e.g., 'agent', 'oven', 'kitchen')"
      }]}
  end
end

defp validate_entity_capabilities(entity, index) do
  case Map.get(entity, :capabilities, []) do
    capabilities when is_list(capabilities) ->
      validate_capability_list(capabilities, index)
    invalid ->
      {:error, [%{
        field: "requires_entities[#{index}].capabilities",
        message: "Entity capabilities must be a list of atoms",
        value: invalid,
        expected: "List of capability atoms (e.g., [:cooking, :heating])"
      }]}
  end
end
```

## Temporal Conditions/Effects System

### Domain.DurativeAction Integration

```elixir
# Temporal conditions/effects with entity requirements
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
      {"available", "chef_1", true},
      {"available", "prep_cook", true}, 
      {"temperature", "oven", {:>=, 350}}
    ],
    over_all: [
      {"coordination", "team", "active"},
      {"temperature", "oven", {:between, 350, 450}}
    ],
    at_end: [
      {"quality", "meal", {:>=, 8}},
      {"cleanup", "kitchen", "complete"}
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

- **ADR-131**: Core Specification (parent ADR)
- **ADR-133**: Architecture & Standards (system integration)
- **ADR-134**: Developer Guide (usage examples)

## Implementation Status

**Status:** Completed - Duration precision preservation implemented
**Usage:** Enhanced temporal accuracy for all AriaEngine operations
**Timeline:** Available immediately
**Integration:** Full integration with validation framework and temporal constraints
