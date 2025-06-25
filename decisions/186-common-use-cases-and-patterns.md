# ADR-186: Common Use Cases and Patterns

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Guidance

## Overview

**Purpose**: Real-world examples and proven patterns for common AriaEngine scenarios  
**Target Audience**: Developers who completed the Quick Start Guide (ADR-185)  
**Scope**: Practical examples with complete working code

## Use Case 1: Restaurant Kitchen Management

### Scenario
Manage a restaurant kitchen with multiple chefs, equipment, and orders.

### Complete Working Example

```elixir
defmodule MyApp.Domains.RestaurantDomain do
  use AriaEngine.Domain
  
  # === ACTIONS ===
  
  @action duration: "PT45M",
          requires_entities: [
            %{type: "chef", capabilities: [:cooking, :pasta_making]},
            %{type: "stove", capabilities: [:heating]},
            %{type: "ingredients", capabilities: [:consumable]}
          ]
  def cook_pasta(state, [order_id, pasta_type]) do
    state
    |> State.set_fact("order_status", order_id, "cooking")
    |> State.set_fact("chef_status", "chef_1", "busy")
    |> State.set_fact("stove_status", "stove_1", "in_use")
    |> State.set_fact("dish_type", order_id, pasta_type)
  end
  
  @action duration: "PT30M",
          requires_entities: [
            %{type: "chef", capabilities: [:cooking, :grilling]},
            %{type: "grill", capabilities: [:grilling]}
          ]
  def grill_chicken(state, [order_id]) do
    state
    |> State.set_fact("order_status", order_id, "cooking")
    |> State.set_fact("chef_status", "chef_2", "busy")
    |> State.set_fact("grill_status", "grill_1", "in_use")
    |> State.set_fact("dish_type", order_id, "grilled_chicken")
  end
  
  @action duration: "PT10M"
  def plate_dish(state, [order_id]) do
    state
    |> State.set_fact("order_status", order_id, "ready")
    |> State.set_fact("plating_status", order_id, "complete")
  end
  
  # === GOAL METHODS ===
  
  @unigoal_method predicate: "order_status"
  def fulfill_order(state, [order_id, "ready"]) do
    current_status = State.get_fact(state, "order_status", order_id)
    dish_type = State.get_fact(state, "dish_type", order_id)
    
    case current_status do
      "ready" -> 
        {:ok, []}  # Already complete
      "cooking" -> 
        {:ok, [
          {:plate_dish, [order_id]}
        ]}
      _ -> 
        # Need to cook first
        case dish_type do
          "pasta" -> 
            {:ok, [
              {:cook_pasta, [order_id, "spaghetti"]},
              {:plate_dish, [order_id]}
            ]}
          "chicken" -> 
            {:ok, [
              {:grill_chicken, [order_id]},
              {:plate_dish, [order_id]}
            ]}
          nil -> 
            {:error, "Unknown dish type for order #{order_id}"}
        end
    end
  end
  
  # === TASK METHODS ===
  
  @task_method
  def process_dinner_rush(state, [order_list]) do
    # Break down multiple orders into individual goals
    order_goals = Enum.map(order_list, fn order_id ->
      {order_id, "order_status", "ready"}
    end)
    
    {:ok, order_goals}
  end
  
  def create_domain do
    __MODULE__.create_base_domain()
  end
end
```

### Usage Example

```elixir
# Set up restaurant state
domain = MyApp.Domains.RestaurantDomain.create_domain()
state = State.new()
|> State.set_fact("chef_status", "chef_1", "available")
|> State.set_fact("chef_status", "chef_2", "available")
|> State.set_fact("stove_status", "stove_1", "available")
|> State.set_fact("grill_status", "grill_1", "available")
|> State.set_fact("dish_type", "order_001", "pasta")
|> State.set_fact("dish_type", "order_002", "chicken")

# Process multiple orders
goals = [
  {"order_001", "order_status", "ready"},
  {"order_002", "order_status", "ready"}
]

case AriaEngine.plan(domain, state, goals) do
  {:ok, final_state} ->
    IO.puts("All orders completed!")
    IO.inspect(State.get_fact(final_state, "order_status", "order_001"))
    IO.inspect(State.get_fact(final_state, "order_status", "order_002"))
    
  {:error, reason} ->
    IO.puts("Kitchen planning failed: #{reason}")
end
```

## Use Case 2: Meeting Scheduling System

### Scenario
Schedule meetings with room booking, participant availability, and equipment setup.

### Complete Working Example

```elixir
defmodule MyApp.Domains.MeetingDomain do
  use AriaEngine.Domain
  
  # === ACTIONS ===
  
  @action start: "2025-06-25T10:00:00Z",
          end: "2025-06-25T11:00:00Z",
          requires_entities: [
            %{type: "conference_room", capabilities: [:meeting_space]},
            %{type: "projector", capabilities: [:presentation]}
          ]
  def conduct_meeting(state, [meeting_id, participants]) do
    state
    |> State.set_fact("meeting_status", meeting_id, "in_progress")
    |> State.set_fact("room_status", "conf_room_1", "occupied")
    |> State.set_fact("participants", meeting_id, participants)
  end
  
  @action duration: "PT15M"
  def setup_equipment(state, [room_id, equipment_list]) do
    state
    |> State.set_fact("equipment_status", room_id, "ready")
    |> State.set_fact("setup_complete", room_id, true)
  end
  
  @action duration: "PT5M"
  def send_invitations(state, [meeting_id, participant_list]) do
    state
    |> State.set_fact("invitations_sent", meeting_id, true)
    |> State.set_fact("participant_list", meeting_id, participant_list)
  end
  
  # === GOAL METHODS ===
  
  @unigoal_method predicate: "meeting_status"
  def schedule_meeting(state, [meeting_id, "scheduled"]) do
    current_status = State.get_fact(state, "meeting_status", meeting_id)
    
    case current_status do
      "scheduled" -> 
        {:ok, []}
      _ -> 
        participants = State.get_fact(state, "required_participants", meeting_id) || []
        {:ok, [
          {:send_invitations, [meeting_id, participants]},
          {:setup_equipment, ["conf_room_1", ["projector", "whiteboard"]]},
          {:conduct_meeting, [meeting_id, participants]}
        ]}
    end
  end
  
  @unigoal_method predicate: "room_available"
  def ensure_room_availability(state, [room_id, time_slot]) do
    current_status = State.get_fact(state, "room_status", room_id)
    
    case current_status do
      "available" -> 
        {:ok, []}
      "occupied" -> 
        {:error, "Room #{room_id} is occupied during #{time_slot}"}
      _ -> 
        # Assume available if not set
        {:ok, []}
    end
  end
  
  # === TASK METHODS ===
  
  @task_method
  def organize_daily_standup(state, [team_members]) do
    meeting_id = "standup_#{Date.utc_today()}"
    
    {:ok, [
      {:task_check_availability, [team_members]},
      {meeting_id, "meeting_status", "scheduled"}
    ]}
  end
  
  def create_domain do
    __MODULE__.create_base_domain()
  end
end
```

### Usage Example

```elixir
# Set up meeting system state
domain = MyApp.Domains.MeetingDomain.create_domain()
state = State.new()
|> State.set_fact("room_status", "conf_room_1", "available")
|> State.set_fact("equipment_status", "conf_room_1", "needs_setup")
|> State.set_fact("required_participants", "meeting_001", ["alice", "bob", "charlie"])

# Schedule a meeting
goal = {"meeting_001", "meeting_status", "scheduled"}

case AriaEngine.plan(domain, state, [goal]) do
  {:ok, final_state} ->
    IO.puts("Meeting scheduled successfully!")
    IO.inspect(State.get_fact(final_state, "meeting_status", "meeting_001"))
    
  {:error, reason} ->
    IO.puts("Meeting scheduling failed: #{reason}")
end
```

## Use Case 3: Resource Management System

### Scenario
Manage shared resources like vehicles, equipment, and personnel across projects.

### Complete Working Example

```elixir
defmodule MyApp.Domains.ResourceDomain do
  use AriaEngine.Domain
  
  # === ACTIONS ===
  
  @action duration: "PT2H",
          requires_entities: [
            %{type: "vehicle", capabilities: [:transportation]},
            %{type: "driver", capabilities: [:driving]}
          ]
  def transport_equipment(state, [equipment_id, from_location, to_location]) do
    state
    |> State.set_fact("equipment_location", equipment_id, to_location)
    |> State.set_fact("transport_status", equipment_id, "delivered")
    |> State.set_fact("vehicle_status", "truck_1", "available")
    |> State.set_fact("driver_status", "driver_1", "available")
  end
  
  @action duration: "PT30M"
  def allocate_resource(state, [resource_id, project_id]) do
    state
    |> State.set_fact("resource_allocation", resource_id, project_id)
    |> State.set_fact("allocation_status", resource_id, "allocated")
  end
  
  @action duration: "PT15M"
  def release_resource(state, [resource_id]) do
    state
    |> State.set_fact("resource_allocation", resource_id, nil)
    |> State.set_fact("allocation_status", resource_id, "available")
  end
  
  # === GOAL METHODS ===
  
  @unigoal_method predicate: "equipment_location"
  def move_equipment(state, [equipment_id, target_location]) do
    current_location = State.get_fact(state, "equipment_location", equipment_id)
    
    case current_location do
      ^target_location -> 
        {:ok, []}  # Already there
      source_location when is_binary(source_location) -> 
        {:ok, [
          {:transport_equipment, [equipment_id, source_location, target_location]}
        ]}
      nil -> 
        {:error, "Equipment location unknown"}
    end
  end
  
  @unigoal_method predicate: "resource_allocation"
  def assign_resource(state, [resource_id, project_id]) do
    current_allocation = State.get_fact(state, "resource_allocation", resource_id)
    
    case current_allocation do
      ^project_id -> 
        {:ok, []}  # Already assigned
      nil -> 
        {:ok, [
          {:allocate_resource, [resource_id, project_id]}
        ]}
      other_project -> 
        {:ok, [
          {:release_resource, [resource_id]},
          {:allocate_resource, [resource_id, project_id]}
        ]}
    end
  end
  
  # === MULTIGOAL METHODS ===
  
  @multigoal_method goal_pattern: :resource_optimization
  def optimize_resource_allocation(state, multigoal) do
    # Custom optimization for resource allocation
    goals = multigoal.goals
    
    # Group goals by resource type
    equipment_goals = Enum.filter(goals, fn {_subject, predicate, _value} ->
      predicate == "equipment_location"
    end)
    
    allocation_goals = Enum.filter(goals, fn {_subject, predicate, _value} ->
      predicate == "resource_allocation"
    end)
    
    # Optimize order: allocations first, then movements
    optimized_order = allocation_goals ++ equipment_goals
    
    {:ok, optimized_order}
  end
  
  def create_domain do
    __MODULE__.create_base_domain()
  end
end
```

### Usage Example

```elixir
# Set up resource management state
domain = MyApp.Domains.ResourceDomain.create_domain()
state = State.new()
|> State.set_fact("equipment_location", "crane_1", "warehouse")
|> State.set_fact("equipment_location", "excavator_1", "site_a")
|> State.set_fact("vehicle_status", "truck_1", "available")
|> State.set_fact("driver_status", "driver_1", "available")
|> State.set_fact("resource_allocation", "crane_1", nil)

# Coordinate multiple resource moves
goals = [
  {"crane_1", "equipment_location", "site_b"},
  {"crane_1", "resource_allocation", "project_x"},
  {"excavator_1", "equipment_location", "site_b"}
]

case AriaEngine.plan(domain, state, goals) do
  {:ok, final_state} ->
    IO.puts("Resource coordination complete!")
    IO.inspect(State.get_fact(final_state, "equipment_location", "crane_1"))
    IO.inspect(State.get_fact(final_state, "resource_allocation", "crane_1"))
    
  {:error, reason} ->
    IO.puts("Resource planning failed: #{reason}")
end
```

## Common Patterns Reference

### Pattern 1: State Validation in Goal Methods

```elixir
@unigoal_method predicate: "task_status"
def complete_task(state, [task_id, "complete"]) do
  # Always check current state first
  current_status = State.get_fact(state, "task_status", task_id)
  prerequisites = State.get_fact(state, "prerequisites_met", task_id)
  
  case {current_status, prerequisites} do
    {"complete", _} -> 
      {:ok, []}  # Already done
    {_, false} -> 
      {:error, "Prerequisites not met for task #{task_id}"}
    {_, true} -> 
      {:ok, [
        {:execute_task, [task_id]},
        {:mark_complete, [task_id]}
      ]}
    _ -> 
      # Check prerequisites first
      {:ok, [
        {:verify_prerequisites, [task_id]},
        {:execute_task, [task_id]},
        {:mark_complete, [task_id]}
      ]}
  end
end
```

### Pattern 2: Resource Conflict Resolution

```elixir
@action requires_entities: [
          %{type: "shared_resource", capabilities: [:processing]}
        ]
def use_shared_resource(state, [resource_id, task_id]) do
  # Check if resource is available
  current_user = State.get_fact(state, "resource_user", resource_id)
  
  case current_user do
    nil -> 
      # Available - claim it
      state
      |> State.set_fact("resource_user", resource_id, task_id)
      |> State.set_fact("resource_status", resource_id, "in_use")
    ^task_id -> 
      # Already claimed by this task
      state
    _other_task -> 
      # Conflict - let planner handle
      {:error, "Resource #{resource_id} is busy with another task"}
  end
end
```

### Pattern 3: Temporal Coordination

```elixir
@action start: "2025-06-25T09:00:00Z",
        end: "2025-06-25T17:00:00Z",
        requires_entities: [
          %{type: "team", capabilities: [:collaboration]}
        ]
def coordinate_team_work(state, [project_id, team_members]) do
  # Actions with fixed schedules for coordination
  state
  |> State.set_fact("project_status", project_id, "active")
  |> State.set_fact("team_coordination", project_id, "synchronized")
  |> State.set_fact("work_schedule", project_id, "business_hours")
end

@unigoal_method predicate: "project_status"
def manage_project(state, [project_id, "active"]) do
  team_size = State.get_fact(state, "team_size", project_id) || 1
  
  if team_size > 1 do
    # Multi-person project needs coordination
    {:ok, [
      {:coordinate_team_work, [project_id, team_size]},
      {:monitor_progress, [project_id]}
    ]}
  else
    # Single person project
    {:ok, [
      {:start_individual_work, [project_id]}
    ]}
  end
end
```

### Pattern 4: Error Recovery

```elixir
@action
def attempt_risky_operation(state, [operation_id]) do
  # Simulate operation that might fail
  success_chance = State.get_fact(state, "success_probability", operation_id) || 0.5
  
  if :rand.uniform() < success_chance do
    state
    |> State.set_fact("operation_status", operation_id, "success")
  else
    {:error, "Operation #{operation_id} failed - retry needed"}
  end
end

@unigoal_method predicate: "operation_status"
def ensure_operation_success(state, [operation_id, "success"]) do
  current_status = State.get_fact(state, "operation_status", operation_id)
  retry_count = State.get_fact(state, "retry_count", operation_id) || 0
  
  case {current_status, retry_count} do
    {"success", _} -> 
      {:ok, []}
    {_, count} when count >= 3 -> 
      {:error, "Operation #{operation_id} failed after 3 retries"}
    _ -> 
      {:ok, [
        {:increment_retry_count, [operation_id]},
        {:attempt_risky_operation, [operation_id]}
      ]}
  end
end
```

## Best Practices

### 1. Always Check Current State

```elixir
# GOOD: Check before acting
@unigoal_method predicate: "location"
def move_to_location(state, [subject, target]) do
  current = State.get_fact(state, "location", subject)
  
  case current do
    ^target -> {:ok, []}  # Already there
    _ -> {:ok, [{:walk_to, [subject, target]}]}
  end
end

# AVOID: Assuming state
@unigoal_method predicate: "location"
def move_to_location(state, [subject, target]) do
  {:ok, [{:walk_to, [subject, target]}]}  # Might be unnecessary
end
```

### 2. Use Descriptive Error Messages

```elixir
# GOOD: Helpful error messages
case validate_prerequisites(state, task_id) do
  {:error, missing} -> 
    {:error, "Task #{task_id} missing prerequisites: #{Enum.join(missing, ", ")}"}
  :ok -> 
    proceed_with_task(state, task_id)
end

# AVOID: Generic errors
case validate_prerequisites(state, task_id) do
  {:error, _} -> {:error, "Prerequisites failed"}
  :ok -> proceed_with_task(state, task_id)
end
```

### 3. Break Down Complex Operations

```elixir
# GOOD: Decomposed into manageable steps
@task_method
def complete_project(state, [project_id]) do
  {:ok, [
    {:task_planning_phase, [project_id]},
    {:task_execution_phase, [project_id]},
    {:task_review_phase, [project_id]}
  ]}
end

# AVOID: Monolithic operations
@action duration: "PT40H"  # 40 hours!
def complete_entire_project(state, [project_id]) do
  # Too much in one action
end
```

## Next Steps

**Continue learning:**

1. **ADR-187**: Developer Navigation Guide - Find what you need in the codebase
2. **ADR-188**: Practical How-To Documentation - Advanced techniques and debugging

**For deeper technical understanding:**

- **ADR-181**: Core Specification - Complete technical reference
- **ADR-182**: Technical Implementation - Duration handling and validation
- **ADR-183**: Architecture & Standards - System design and integration
- **ADR-184**: Developer Guide - Comprehensive examples and patterns

## Success Criteria

After reading this ADR, you should be able to:

- [x] Implement restaurant kitchen management with multiple resources
- [x] Create meeting scheduling systems with temporal constraints
- [x] Build resource management with conflict resolution
- [x] Apply common patterns for state validation and error handling
- [x] Structure complex domains with proper decomposition
- [x] Handle temporal coordination and resource conflicts

**Complexity Level**: Intermediate  
**Prerequisites**: ADR-185 (Quick Start Guide)  
**Time Investment**: 45-60 minutes for complete understanding
