# ADR-134: Unified Action Specification Examples

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** LOW  
**Extracted from:** ADR-131

## Context

This ADR provides comprehensive examples and implementation patterns for the unified durative action specification. These examples demonstrate the before/after patterns, migration guidance, and best practices for using the new unified system.

## Before/After Examples

### Action Definition Patterns

#### Before (Confusing Multiple Patterns)

```elixir
# Multiple entity creation patterns
timeline_graph = TimelineGraph.new()
{:ok, timeline_graph, _} = TimelineGraph.create_entity(timeline_graph, "chef", "Head Chef", %{})
{:ok, timeline_graph} = TimelineGraph.add_capabilities(timeline_graph, "chef", [:cooking])

# Inconsistent goal formats
{predicate, subject, value}  # Wrong format
{"location", "player", "room1"}  # Predicate-first (deprecated)

# Complex state validation
validate_temporal_condition(condition, state)
StateV2.evaluate_condition(state, condition)

# Multiple action definition patterns
Domain.add_action(:cook, &cook/2)  # No metadata
Domain.add_action(:bake, %DurativeAction{...})  # Complex struct
```

#### After (Unified Clear Patterns)

```elixir
# Unified action specification with clean entity+capabilities model
Domain.add_action(:cook_meal, &cook_meal/2, %{
  duration: "PT2H",  # Floating effort
  requires_entities: [
    %{type: "agent", capabilities: [:cooking, :menu_planning]},
    %{type: "oven", capabilities: [:heating, :baking]},
    %{type: "flour", capabilities: [:consumable]},
    %{type: "eggs", capabilities: [:consumable]},
    %{type: "mixing_bowl", capabilities: [:container, :reusable]}
  ],
  description: "Prepare a meal using specified ingredients and cooking equipment"
})

Domain.add_action(:meeting, &meeting/2, %{
  start: "2025-06-22T10:00:00Z",  # Fixed scheduling
  end: "2025-06-22T11:00:00Z",
  requires_entities: [
    %{type: "agent", capabilities: [:communication]},
    %{type: "conference_room_1", capabilities: [:meeting_space]}
  ],
  description: "Scheduled team meeting in conference room"
})

# Standardized goal format (subject-first)
{subject, predicate, value}
{"player", "location", "room1"}  # Subject-first (correct)

# Simple state validation (supports temporal queries)
StateV2.get_fact(state, subject, predicate) == required_value

# Temporal state validation (past/future checking)
StateV2.get_fact(state, subject, predicate, time) == required_value
```

## Comprehensive Action Examples

### Floating Duration Actions (Effort-Based)

```elixir
# Simple cooking action
Domain.add_action(:cook_pasta, &cook_pasta/2, %{
  duration: "PT15M",
  requires_entities: [
    %{type: "agent", capabilities: [:cooking]},
    %{type: "stove", capabilities: [:heating]},
    %{type: "pasta", capabilities: [:consumable]},
    %{type: "water", capabilities: [:consumable]}
  ],
  description: "Cook pasta in boiling water"
})

# Complex manufacturing action
Domain.add_action(:build_furniture, &build_furniture/2, %{
  duration: "PT4H",
  requires_entities: [
    %{type: "agent", capabilities: [:carpentry, :tool_usage]},
    %{type: "wood", capabilities: [:consumable, :material]},
    %{type: "screws", capabilities: [:consumable, :fastener]},
    %{type: "drill", capabilities: [:tool, :drilling]},
    %{type: "saw", capabilities: [:tool, :cutting]},
    %{type: "workshop", capabilities: [:workspace, :ventilated]}
  ],
  description: "Build furniture from wood materials using carpentry tools"
})

# Research/knowledge work action
Domain.add_action(:write_report, &write_report/2, %{
  duration: "PT2H30M",
  requires_entities: [
    %{type: "agent", capabilities: [:writing, :research]},
    %{type: "computer", capabilities: [:tool, :word_processing]},
    %{type: "data", capabilities: [:information, :accessible]},
    %{type: "office", capabilities: [:workspace, :quiet]}
  ],
  description: "Write comprehensive report based on research data"
})
```

### Fixed Schedule Actions (Time-Based)

```elixir
# Scheduled meeting
Domain.add_action(:team_standup, &team_standup/2, %{
  start: "2025-06-22T09:00:00Z",
  end: "2025-06-22T09:30:00Z",
  requires_entities: [
    %{type: "agent", capabilities: [:communication, :team_member]},
    %{type: "conference_room", capabilities: [:meeting_space]},
    %{type: "projector", capabilities: [:display, :presentation]}
  ],
  description: "Daily team standup meeting"
})

# Scheduled maintenance
Domain.add_action(:server_maintenance, &server_maintenance/2, %{
  start: "2025-06-22T02:00:00Z",
  end: "2025-06-22T04:00:00Z",
  requires_entities: [
    %{type: "agent", capabilities: [:system_admin, :server_access]},
    %{type: "server", capabilities: [:maintenance_mode]},
    %{type: "backup_system", capabilities: [:data_protection]}
  ],
  description: "Scheduled server maintenance window"
})

# Event/appointment
Domain.add_action(:doctor_appointment, &doctor_appointment/2, %{
  start: "2025-06-22T14:00:00Z",
  end: "2025-06-22T14:45:00Z",
  requires_entities: [
    %{type: "patient", capabilities: [:appointment_holder]},
    %{type: "doctor", capabilities: [:medical_professional]},
    %{type: "examination_room", capabilities: [:medical_facility]}
  ],
  description: "Medical examination appointment"
})
```

### Open-Ended Interval Actions

```elixir
# Start-only constraint (deadline-free)
Domain.add_action(:begin_project, &begin_project/2, %{
  start: "2025-06-22T08:00:00Z",  # Must start at this time
  requires_entities: [
    %{type: "agent", capabilities: [:project_management]},
    %{type: "team", capabilities: [:available, :assigned]},
    %{type: "resources", capabilities: [:allocated]}
  ],
  description: "Begin project work at specified start time"
})

# End-only constraint (flexible start)
Domain.add_action(:submit_proposal, &submit_proposal/2, %{
  end: "2025-06-22T17:00:00Z",  # Must finish by this deadline
  requires_entities: [
    %{type: "agent", capabilities: [:writing, :proposal_creation]},
    %{type: "proposal_data", capabilities: [:complete, :reviewed]},
    %{type: "submission_system", capabilities: [:accessible]}
  ],
  description: "Submit proposal before deadline"
})
```

## Capability Composition Examples

### Categorical Traits

```elixir
# Basic entity categories
%{type: "chef", capabilities: [:agent, :human]}
%{type: "oven", capabilities: [:appliance, :kitchen_equipment]}
%{type: "flour", capabilities: [:consumable, :ingredient]}
%{type: "knife", capabilities: [:tool, :kitchen_equipment]}
```

### Behavioral Capabilities

```elixir
# What entities can do
%{type: "chef", capabilities: [:cooking, :knife_skills, :menu_planning]}
%{type: "oven", capabilities: [:heating, :baking, :temperature_control]}
%{type: "mixer", capabilities: [:mixing, :blending, :speed_control]}
```

### Functional Traits

```elixir
# How entities behave
%{type: "mixing_bowl", capabilities: [:container, :reusable, :dishwasher_safe]}
%{type: "flour", capabilities: [:consumable, :stackable, :pantry_storage]}
%{type: "knife", capabilities: [:reusable, :sharpenable, :portable]}
```

### Domain-Specific Capabilities

```elixir
# Kitchen domain
%{type: "sous_chef", capabilities: [:agent, :cooking, :food_prep, :kitchen_management]}
%{type: "walk_in_cooler", capabilities: [:storage, :refrigeration, :large_capacity]}

# Office domain  
%{type: "manager", capabilities: [:agent, :leadership, :decision_making, :team_coordination]}
%{type: "conference_room", capabilities: [:meeting_space, :presentation_capable, :video_conferencing]}

# Manufacturing domain
%{type: "machinist", capabilities: [:agent, :precision_work, :machine_operation, :quality_control]}
%{type: "cnc_machine", capabilities: [:manufacturing, :precision_cutting, :computer_controlled]}
```

## Action Implementation Patterns

### Resource Consumption Through State

```elixir
def cook_meal(state, [meal_type]) do
  # Check resource availability through state
  flour_available = StateV2.get_fact(state, "flour", "quantity")
  eggs_available = StateV2.get_fact(state, "eggs", "quantity")
  
  # Validate sufficient resources
  if flour_available >= 2 and eggs_available >= 6 do
    # Consume resources and update state
    state
    |> StateV2.set_fact("flour", "quantity", flour_available - 2)
    |> StateV2.set_fact("eggs", "quantity", eggs_available - 6)
    |> StateV2.set_fact("meal", "status", "cooked")
    |> StateV2.set_fact("meal", "type", meal_type)
  else
    {:error, :insufficient_ingredients}
  end
end
```

### Capability-Based Entity Validation

```elixir
def build_furniture(state, [furniture_type]) do
  # Find entities with required capabilities
  available_agents = find_entities_with_capabilities(state, [:carpentry, :tool_usage])
  available_tools = find_entities_with_capabilities(state, [:tool, :cutting])
  available_workspace = find_entities_with_capabilities(state, [:workspace, :ventilated])
  
  # Validate entity availability
  cond do
    Enum.empty?(available_agents) ->
      {:error, :no_qualified_carpenter}
    
    Enum.empty?(available_tools) ->
      {:error, :missing_cutting_tools}
    
    Enum.empty?(available_workspace) ->
      {:error, :no_suitable_workspace}
    
    true ->
      # Proceed with furniture building
      agent = List.first(available_agents)
      workspace = List.first(available_workspace)
      
      state
      |> StateV2.set_fact(agent, "current_task", "building_furniture")
      |> StateV2.set_fact(workspace, "occupied_by", agent)
      |> StateV2.set_fact(furniture_type, "status", "under_construction")
  end
end
```

### Temporal State Validation

```elixir
def scheduled_meeting(state, [meeting_id]) do
  meeting_time = StateV2.get_fact(state, meeting_id, "scheduled_time")
  current_time = DateTime.utc_now()
  
  # Validate timing constraints
  cond do
    DateTime.compare(current_time, meeting_time) == :lt ->
      {:error, :meeting_not_yet_started}
    
    DateTime.compare(current_time, meeting_time) == :gt ->
      {:error, :meeting_already_passed}
    
    true ->
      # Meeting is happening now
      participants = StateV2.get_fact(state, meeting_id, "participants")
      
      state
      |> StateV2.set_fact(meeting_id, "status", "in_progress")
      |> StateV2.set_fact(meeting_id, "start_time", current_time)
      |> update_participant_status(participants, "in_meeting")
  end
end
```

## Migration Guidance

### From Legacy TimelineGraph Pattern

```elixir
# Before: Complex timeline graph setup
timeline_graph = TimelineGraph.new()
{:ok, timeline_graph, _} = TimelineGraph.create_entity(timeline_graph, "chef", "Head Chef", %{})
{:ok, timeline_graph} = TimelineGraph.add_capabilities(timeline_graph, "chef", [:cooking])

# After: Simple entity requirements in action metadata
Domain.add_action(:cook, &cook/2, %{
  duration: "PT1H",
  requires_entities: [
    %{type: "chef", capabilities: [:cooking]}
  ]
})
```

### From Complex DurativeAction Structs

```elixir
# Before: Complex struct definition
action = %DurativeAction{
  name: :cook,
  duration: %Duration{hours: 2, minutes: 0, seconds: 0},
  preconditions: [...],
  effects: [...],
  resources: %{agents: [...], tools: [...]}
}

# After: Simple metadata map
Domain.add_action(:cook, &cook/2, %{
  duration: "PT2H",
  requires_entities: [
    %{type: "agent", capabilities: [:cooking]},
    %{type: "stove", capabilities: [:heating]}
  ]
})
```

### From Multiple Goal Formats

```elixir
# Before: Inconsistent goal formats
{predicate, subject, value}  # Wrong order
{"location", "player", "room1"}  # Predicate-first

# After: Standardized subject-first format
{subject, predicate, value}
{"player", "location", "room1"}  # Subject-first (correct)
```

## Best Practices

### Entity Design Principles

1. **Everything is an entity**: Agents, tools, locations, consumables all use the same pattern
2. **Capabilities as simple traits**: Use atoms for what entities can do or what they are
3. **Properties in state**: Dynamic values belong in StateV2, not action metadata
4. **Composition over inheritance**: Mix capabilities freely without hierarchies

### Temporal Specification Guidelines

1. **Use floating durations** for effort-based work (`duration: "PT2H"`)
2. **Use fixed intervals** for scheduled events (`start: "...", end: "..."`)
3. **Use open intervals** for flexible constraints (start-only or end-only)
4. **Always include timezone** in datetime strings (`"2025-06-22T10:00:00Z"`)

### Action Implementation Best Practices

1. **Check preconditions first**: Validate entity availability and state requirements
2. **Handle errors gracefully**: Return `{:error, reason}` for clear failure modes
3. **Update state atomically**: Make all state changes together or not at all
4. **Use descriptive error atoms**: `:insufficient_ingredients` vs `:error`

### Capability Design Guidelines

1. **Keep capabilities atomic**: Each capability represents one trait or ability
2. **Use domain-specific terms**: `:cooking` vs `:food_preparation` based on domain
3. **Avoid complex hierarchies**: Flat capability lists are easier to query
4. **Make capabilities queryable**: Design for `find_entities_with_capability/2`

## Related ADRs

- **ADR-131**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-132**: Fix Duration Handling Precision Loss (technical issue)
- **ADR-133**: Planner Standardization Open Problems (related issues)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Documentation complete, examples ready for reference
**Usage:** Reference guide for implementing unified action specifications
**Timeline:** Available immediately for new action definitions
