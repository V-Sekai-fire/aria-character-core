# ADR-131: Core Specification - Unified Durative Action Specification

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

### Final Clean Model

```elixir
# Unified entity-based metadata structure
Domain.add_action(:cook_meal, &cook_meal/2, %{
  # Temporal specification (floating duration)
  duration: "PT2H",
  
  # Unified entity requirements (everything is an entity with capabilities)
  requires_entities: [
    %{type: "agent", capabilities: [:cooking, :menu_planning]},
    %{type: "oven", capabilities: [:heating, :baking]},
    %{type: "kitchen", capabilities: [:workspace]},
    %{type: "flour", capabilities: [:consumable]},
    %{type: "eggs", capabilities: [:consumable]},
    %{type: "mixing_bowl", capabilities: [:container, :reusable]}
  ],
  
  # Static documentation
  description: "Prepare a meal using specified ingredients and cooking equipment"
})

# Fixed scheduling example
Domain.add_action(:meeting, &meeting/2, %{
  # Temporal specification (fixed interval)
  start: "2025-06-22T10:00:00Z",
  end: "2025-06-22T11:00:00Z",
  
  # Unified entity requirements
  requires_entities: [
    %{type: "agent", capabilities: [:communication]},
    %{type: "conference_room_1", capabilities: [:meeting_space]}
  ],
  
  description: "Scheduled team meeting in conference room"
})
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
{predicate, subject, value}  # ✅ CORRECT
```

**DEPRECATED formats:**
```elixir
{subject, predicate, value}  # ❌ TOMBSTONE THIS
```

## State Validation Approach

**ONLY use direct fact checking:**
```elixir
State.get_fact(state, predicate, subject)  # ✅ DIRECT FACT CHECKING (supports temporal queries)
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

## Success Criteria

- [x] Both floating durations and fixed intervals supported via ISO 8601 strings
- [x] Unified action specification with entities, capabilities, and resources
- [x] All goals use `{predicate, subject, value}` format consistently
- [x] All state validation uses direct `State.get_fact/3` calls (with temporal query support)
- [x] Single standardized way to define actions
- [x] Clear documentation on which planning API to use when

## Related ADRs

- **ADR-132**: Technical Implementation (Implementation Guide)
- **ADR-133**: Architecture & Standards (System Design)
- **ADR-134**: Developer Guide (Usage & Examples)

## Implementation Status

**Status:** Active - Core specification under ongoing refinement
**Usage:** Foundation for all AriaEngine domain development
**Timeline:** Available immediately
**Compatibility:** Full backward compatibility maintained
