# ADR-185: AriaEngine Quick Start Guide

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Onboarding

## Overview

**Purpose**: Get new developers productive with AriaEngine in under 30 minutes  
**Target Audience**: Developers new to AriaEngine who need immediate practical guidance  
**Scope**: Essential concepts and working examples only

## Your First AriaEngine Domain (5 minutes)

### Step 1: Create a Simple Domain Module

```elixir
defmodule MyApp.Domains.SimpleDomain do
  use AriaEngine.Domain
  
  # Define a basic action - cooking takes 30 minutes
  @action duration: "PT30M"
  def cook_meal(state, [meal_type]) do
    # Actions transform state - assume planner validated requirements
    state
    |> State.set_fact("meal_status", meal_type, "ready")
    |> State.set_fact("chef_status", "chef_1", "available")
  end
  
  # Define a goal method - how to achieve "meal_ready"
  @unigoal_method predicate: "meal_status"
  def prepare_meal(state, [meal_type, "ready"]) do
    # Check if meal is already ready
    current_status = State.get_fact(state, "meal_status", meal_type)
    
    if current_status == "ready" do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:cook_meal, [meal_type]}  # Use the action we defined
      ]}
    end
  end
  
  # Create the domain
  def create_domain do
    __MODULE__.create_base_domain()
  end
end
```

### Step 2: Use Your Domain

```elixir
# Create domain and initial state
domain = MyApp.Domains.SimpleDomain.create_domain()
initial_state = State.new()

# Set up initial conditions
state = State.set_fact(initial_state, "chef_status", "chef_1", "available")

# Define what you want to achieve
goal = {"pasta", "meal_status", "ready"}

# Plan and execute
case AriaEngine.plan(domain, state, [goal]) do
  {:ok, final_state} -> 
    IO.puts("Success! Meal is ready.")
    IO.inspect(State.get_fact(final_state, "meal_status", "pasta"))
    
  {:error, reason} -> 
    IO.puts("Planning failed: #{reason}")
end
```

**Expected Output:**
```
Success! Meal is ready.
"ready"
```

## Essential Concepts (10 minutes)

### Actions vs Goals vs Tasks

**Actions** - What your system can DO:
```elixir
@action duration: "PT30M"
def cook_meal(state, [meal_type]) do
  # Direct state transformation
end
```

**Goals** - What you want to ACHIEVE:
```elixir
goal = {"pasta", "meal_status", "ready"}  # Subject, predicate, value
```

**Tasks** - HOW to break down complex work:
```elixir
@task_method
def prepare_dinner(state, [meal_type]) do
  {:ok, [
    {:gather_ingredients, [meal_type]},
    {:cook_meal, [meal_type]},
    {:serve_meal, [meal_type]}
  ]}
end
```

### State Management

AriaEngine uses **subject-predicate-value** facts:

```elixir
# Set facts
state = State.set_fact(state, "location", "chef_1", "kitchen")
state = State.set_fact(state, "has_ingredients", "chef_1", true)

# Get facts  
location = State.get_fact(state, "location", "chef_1")  # "kitchen"
has_ingredients = State.get_fact(state, "has_ingredients", "chef_1")  # true
```

### Planning Flow

1. **Define what you want** (goals)
2. **AriaEngine finds how** (using your methods)
3. **Execute the plan** (using your actions)

```elixir
# 1. What you want
goals = [
  {"chef_1", "location", "kitchen"},
  {"pasta", "meal_status", "ready"}
]

# 2. AriaEngine plans how
{:ok, plan} = AriaEngine.plan(domain, state, goals)

# 3. Execute (happens automatically in plan/3)
```

## Common Patterns (10 minutes)

### Pattern 1: Resource Requirements

```elixir
# Action that needs specific entities
@action duration: "PT1H", 
        requires_entities: [
          %{type: "chef", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]}
        ]
def bake_bread(state, [bread_type]) do
  # AriaEngine validates entities before calling this
  state
  |> State.set_fact("bread_status", bread_type, "baking")
  |> State.set_fact("oven_status", "oven_1", "in_use")
end
```

### Pattern 2: Conditional Logic

```elixir
@unigoal_method predicate: "location"
def travel_to_location(state, [subject, target_location]) do
  current = State.get_fact(state, "location", subject)
  
  case current do
    ^target_location -> 
      {:ok, []}  # Already there
    nil -> 
      {:error, "Subject location unknown"}
    _other_location -> 
      {:ok, [
        {:walk_to_location, [subject, target_location]}
      ]}
  end
end
```

### Pattern 3: Multiple Goals

```elixir
# AriaEngine handles multiple goals automatically
goals = [
  {"chef_1", "location", "kitchen"},
  {"chef_1", "has_ingredients", true},
  {"dinner", "meal_status", "ready"}
]

{:ok, final_state} = AriaEngine.plan(domain, initial_state, goals)
```

## Troubleshooting (5 minutes)

### Problem: "No methods available for goal"

**Cause**: Missing `@unigoal_method` for your goal pattern

**Solution**: Add a method that matches your goal's predicate:
```elixir
# For goal {"chef", "location", "kitchen"}
@unigoal_method predicate: "location"  # Matches the predicate
def handle_location_goal(state, [subject, target]) do
  # Implementation
end
```

### Problem: "Action failed during execution"

**Cause**: Action function returned `{:error, reason}`

**Solution**: Check your action logic:
```elixir
@action
def cook_meal(state, [meal_type]) do
  # Make sure you return {:ok, new_state} or the state directly
  case validate_cooking_possible(state, meal_type) do
    true -> 
      State.set_fact(state, "meal_status", meal_type, "ready")
    false -> 
      {:error, "Cannot cook #{meal_type} - missing ingredients"}
  end
end
```

### Problem: Planning takes too long

**Cause**: Complex goal dependencies or missing methods

**Solution**: Add more specific methods to reduce search space:
```elixir
# Instead of one complex method, break it down
@task_method
def prepare_complex_meal(state, [meal_type]) do
  {:ok, [
    {:task_gather_ingredients, [meal_type]},  # Smaller tasks
    {:task_prep_cooking, [meal_type]},
    {:cook_meal, [meal_type]}
  ]}
end
```

## Next Steps

**Ready for more?** Check these ADRs in order:

1. **ADR-186**: Common Use Cases and Patterns - Real-world examples
2. **ADR-187**: Developer Navigation Guide - Find what you need
3. **ADR-188**: Practical How-To Documentation - Advanced techniques

**Need technical details?** See the comprehensive documentation:

- **ADR-181**: Core Specification (complete action/goal reference)
- **ADR-182**: Technical Implementation (duration handling, validation)
- **ADR-183**: Architecture & Standards (IPyHOP integration, system design)
- **ADR-184**: Developer Guide (complete examples and patterns)

## Success Criteria

After reading this ADR, you should be able to:

- [x] Create a basic AriaEngine domain with actions and goals
- [x] Understand the difference between actions, goals, and tasks
- [x] Use state management with subject-predicate-value facts
- [x] Plan and execute simple scenarios
- [x] Troubleshoot common planning issues
- [x] Know where to find more detailed information

**Time Investment**: 30 minutes to working AriaEngine knowledge  
**Complexity Level**: Beginner-friendly  
**Prerequisites**: Basic Elixir knowledge
