# ADR-181: Core Specification - Unified Durative Action Specification

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** HIGH

## Overview

**Current State**: Multiple confusing and inconsistent patterns across AriaEngine planner

**Target State**: Single unified specification for durative actions with entities, capabilities, and temporal constraints

## Core Entity Model

Everything is an entity with capabilities that define behavior:

- **Agents**: `%{type: "chef", capabilities: [:cooking, :menu_planning]}`
- **Tools**: `%{type: "oven", capabilities: [:heating, :baking]}`
- **Locations**: `%{type: "kitchen", capabilities: [:workspace]}`
- **Consumables**: `%{type: "flour", capabilities: [:consumable]}`

### Capabilities as Traits

Capabilities serve as simple traits providing flexible composition without inheritance hierarchies:

```elixir
@type capability :: atom()  # Simple trait only: :agent, :heating, :cutting, :consumable
```

**Capability categories:**

- **Categorical traits**: `:agent`, `:consumable`, `:tool`, `:appliance`
- **Behavioral capabilities**: `:heating`, `:cutting`, `:cooking`, `:baking`
- **Functional traits**: `:reusable`, `:portable`, `:stackable`, `:container`
- **Domain-specific**: `:kitchen_equipment`, `:ingredient`, `:meeting_space`

**Properties stored in state, not action metadata:**

```elixir
# Capabilities define what an entity can do
%{type: "oven", capabilities: [:appliance, :kitchen_equipment, :heating, :baking]}

# Properties stored in state
# State.set_fact(state, "max_temp", "oven_1", 450)
# State.set_fact(state, "min_temp", "oven_1", 150)
```

## Unified Action Specification

### Module-Based Domain Pattern (Authoritative)

```elixir
# CORRECT: Module-based domain pattern with @action attributes
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  # Unified entity-based metadata structure with @action attributes
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :menu_planning]},
            %{type: "oven", capabilities: [:heating, :baking]},
            %{type: "kitchen", capabilities: [:workspace]},
            %{type: "flour", capabilities: [:consumable]},
            %{type: "eggs", capabilities: [:consumable]},
            %{type: "mixing_bowl", capabilities: [:container, :reusable]}
          ],
          description: "Prepare a meal using specified ingredients and cooking equipment"
  def cook_meal(state, [meal_type]) do
    # Pure state transformation, planner already validated requirements
    state
    |> State.set_fact("meal_status", meal_type, "cooking")
    |> State.set_fact("chef_status", "chef_1", "busy")
  end

  # Fixed scheduling example with @action attributes
  @action start: "2025-06-22T10:00:00Z",
          end: "2025-06-22T11:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "conference_room_1", capabilities: [:meeting_space]}
          ],
          description: "Scheduled team meeting in conference room"
  def meeting(state, [participants]) do
    # Implementation
    state
    |> State.set_fact("meeting_status", "team_meeting", "in_progress")
    |> State.set_fact("room_status", "conference_room_1", "occupied")
  end
end
```

## Temporal Specification Patterns

### Supported Patterns

**Pattern 1: Floating Duration (effort-based scheduling)**

```elixir
%{duration: "PT2H"}  # ISO 8601 duration string
```

**Pattern 2: Fixed Schedule (time-based scheduling)**

```elixir
%{
  start: "2025-06-22T10:00:00Z",  # ISO 8601 datetime string
  end: "2025-06-22T11:00:00Z"     # ISO 8601 datetime string
}
```

**Pattern 3: Open-ended Intervals**

```elixir
%{start: "2025-06-22T10:00:00Z"}  # Start time only
%{end: "2025-06-22T11:00:00Z"}    # End time only
```

### Validation Rules

- ✅ `duration` only (floating effort)
- ✅ `start` AND `end` (fixed closed interval)
- ✅ `start` only (open-ended interval - starts at time, no end constraint)
- ✅ `end` only (open-ended interval - must finish by time, no start constraint)
- ❌ Cannot mix `duration` with `start`/`end`
- ✅ Missing temporal specification defaults to `duration: "PT0S"` (zero duration floating)

## Goal Format Standardization

**ONLY use this format:**

```elixir
{subject, predicate, value}  # ✅ CORRECT
```

**DEPRECATED formats:**

```elixir
{predicate, subject, value}  # ❌ TOMBSTONE THIS
```

## State Validation Approach

**ONLY use direct fact checking:**

```elixir
AriaState.ObjectState.get_fact(state, subject, predicate)  # ✅ DIRECT FACT CHECKING (supports temporal queries)
```

**DEPRECATED approaches:**

```elixir
validate_temporal_condition/2  # ❌ REMOVE
State.evaluate_condition/2     # ❌ REMOVE
```

## Tombstoned Concepts

The following concepts were explicitly rejected during design:

1. **❌ TOMBSTONE: `quantity` field in action metadata** - Quantities are state fluents, not action metadata
2. **❌ TOMBSTONE: Separate `resources` map with `consumables`, `tools`, `locations`** - Everything is entities with capabilities
3. **❌ TOMBSTONE: `properties` field in entity requirements** - Use capabilities instead
4. **❌ TOMBSTONE: Separate `requires_agent` field** - Agents are entities with capabilities
5. **❌ TOMBSTONE: `location` field in action metadata** - Locations are entities in `requires_entities`
6. **❌ TOMBSTONE: `constraints` field in entity requirements** - Quantities, availability, and dynamic properties are state fluents, not action metadata
7. **❌ TOMBSTONE: Requirement validation in action functions** - Actions assume planner has already validated requirements

### Additional Unstated Known Knowns (Explicitly Tombstoned)

8. **❌ TOMBSTONE: Entity properties in action metadata** - Properties like `max_temp`, `quantity`, `size` belong in state, not action metadata
9. **❌ TOMBSTONE: Mixed goal formats** - ONLY `{subject, predicate, value}` format allowed, all other formats rejected
10. **❌ TOMBSTONE: Complex state evaluation functions** - Use direct `State.get_fact/3` queries instead of `State.evaluate_condition/2` or `validate_temporal_condition/2`
11. **❌ TOMBSTONE: Any validation in action functions** - ALL validation happens at planning time, actions are pure state transformations
12. **❌ TOMBSTONE: Command registration in domains** - Commands are execution-time functions, not domain registration artifacts
13. **❌ TOMBSTONE: Goal format inconsistency in ADR-131** - Fixed documentation error where tombstone claimed `{predicate, subject, value}` was correct format, but all examples used `{subject, predicate, value}`. Corrected specification to match actual usage patterns throughout codebase.
14. **❌ TOMBSTONE: Old unigoal API patterns** - ONLY predicate-based registration allowed
15. **❌ TOMBSTONE: `Domain.add_action` registration pattern** - Use `@action` attributes in module-based domains instead
16. **❌ TOMBSTONE: `Domain.declare_commands` registration pattern** - Use `@command` attributes in module-based domains instead

**Old unigoal API patterns (TOMBSTONED):**

```elixir
# DON'T USE: Full tuple goal pattern (TOMBSTONED)
@unigoal_method goal_pattern: {"chef", "location", :any}
def travel_to_location(state, {"chef", "location", target}) do
  # ❌ WRONG - tuple destructuring signature
end

# USE INSTEAD: Advanced predicate-based registration
@unigoal_method predicate: "location"
def travel_to_location(state, [subject, target]) do
  # ✅ CORRECT - predicate-based with [subject, value] signature
end
```

**Why old unigoal patterns are tombstoned:**

- **Predicate-based registration** is more flexible and reusable
- **[subject, value] signature** works for any entity with that predicate
- **Less repetitive** - one method handles all subjects for a predicate
- **Better API design** - register by predicate, not full goal pattern
- **Cleaner domain code** - fewer method definitions needed

### Action-Level Requirement Validation (TOMBSTONED)

**CRITICAL ARCHITECTURAL PRINCIPLE:** Actions must NOT validate their own requirements. This violates separation of concerns between planning and execution.

**❌ WRONG - Action validating requirements:**

```elixir
@action requires_entities: [%{type: "agent", capabilities: [:cooking]}]
def cook_meal(state, [meal_type]) do
  # TOMBSTONED: Actions should not validate requirements
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} -> proceed_with_cooking(state, meal_type, entities)
    {:error, reason} -> {:error, reason}
  end
end
```

**✅ CORRECT - Action assumes requirements met:**

```elixir
@action requires_entities: [%{type: "agent", capabilities: [:cooking]}]
def cook_meal(state, [meal_type]) do
  # CORRECT: Pure state transformation, planner already validated requirements
  state
  |> AriaState.ObjectState.set_fact("meal_status", meal_type, "cooking")
  |> AriaState.ObjectState.set_fact("chef_status", "chef_1", "busy")
end
```

**Why this separation matters:**

- **Planning Time**: Planner validates `requires_entities` against state before selecting actions
- **Execution Time**: Actions focus purely on state transformation
- **Performance**: No redundant validation during execution
- **Architecture**: Clean separation between planning logic and execution logic

## Success Criteria

- [x] Both floating durations and fixed intervals supported via ISO 8601 strings
- [x] Unified action specification with entities, capabilities, and resources
- [x] All goals use `{subject, predicate, value}` format consistently
- [x] All state validation uses direct `State.get_fact/3` calls (with temporal query support)
- [x] Single standardized way to define actions
- [x] Clear documentation on which planning API to use when

## Related ADRs

- **ADR-182**: Technical Implementation (Implementation Guide)
- **ADR-183**: Architecture & Standards (System Design)
- **ADR-184**: Developer Guide (Usage & Examples)

## Implementation Status

**Status:** Active - Core specification under ongoing refinement

**Usage:** Foundation for all AriaEngine domain development

**Timeline:** Available immediately

**Compatibility:** Full backward compatibility maintained
