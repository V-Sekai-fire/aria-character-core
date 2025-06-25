# ADR-181: Core Specification - Unified Durative Action Specification

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** HIGH

## Overview

**Current State**: Multiple confusing and inconsistent patterns across AriaEngine planner

**Target State**: Single unified specification for durative actions with entities, capabilities, and temporal constraints

## From Confusion to Clarity: Understanding the Planning Paradigm

### Common "Wait, What?" Moments

When developers first encounter the planner patterns, several things feel confusing. Here's the journey from confusion to understanding:

**Confusion 1: "Why don't I just call the function?"**

```elixir
# Normal programming expectation:
cook_meal("pasta")  # Just call it when I want it

# Planning reality:
@action duration: "PT2H", requires_entities: [...]
def cook_meal(state, [meal_type]) do
  # This gets called BY THE PLANNER, not by you
end
```

**The "Aha!" Moment:** You're not writing a program - you're describing a toolbox. The planner is the craftsperson who decides which tools to use and when.

**Confusion 2: "This feels backwards and inefficient"**

```elixir
# What it feels like you're doing:
"Hey computer, I have these tools available, and I want pasta. Figure it out."

# What you think you should be doing:
"Step 1: Get ingredients. Step 2: Cook pasta. Step 3: Serve."
```

**The "Aha!" Moment:** The "inefficient" approach handles complexity that would break your step-by-step code:

- What if no ingredients are available?
- What if the chef is in a meeting?
- What if the oven is broken?
- What if you need to coordinate 3 chefs simultaneously?

**Confusion 3: "Why all this entity and capability stuff?"**

```elixir
# Feels overly complex:
@action requires_entities: [
  %{type: "chef", capabilities: [:cooking]},
  %{type: "oven", capabilities: [:heating]}
]

# Seems like it should be:
def cook_meal() do
  # Just cook!
end
```

**The "Aha!" Moment:** The metadata enables the planner's "magic":

- **Resource conflict detection**: "Chef can't cook two things at once"
- **Capability matching**: "Only entities with :cooking can do this"
- **Failure recovery**: "Oven broke? Find alternative heating source"
- **Temporal scheduling**: "Chef free from 3-5pm, cooking takes 2 hours"

### The Mental Model Shift

**From Procedural to Declarative:**

```elixir
# Procedural mindset (what you're used to):
def make_dinner() do
  if ingredients_available?() do
    if chef_available?() do
      if oven_working?() do
        cook_meal()
      else
        use_stovetop()  # But wait, what if stovetop is broken too?
      end
    else
      wait_for_chef()  # But how long? What if they never come back?
    end
  else
    buy_ingredients()  # But what if store is closed?
  end
end

# Declarative mindset (planning approach):
@action requires_entities: [
  %{type: "chef", capabilities: [:cooking]},
  %{type: "heating_source", capabilities: [:heating]}  # Could be oven OR stovetop
]
def cook_meal(state, [meal_type]) do
  # Just describe the state change - planner handles all the "what ifs"
  state |> AriaState.RelationalState.set_fact("meal_status", meal_type, "ready")
end
```

### Why This Architecture Scales

**Single Agent (feels overkill):**

```elixir
# For one chef making one meal, planning seems like overkill
@action requires_entities: [%{type: "chef", capabilities: [:cooking]}]
def cook_meal(state, [meal_type]) do
  # "Why not just call cook_meal()?"
end
```

**Multiple Agents (planning shines):**

```elixir
# For restaurant with 5 chefs, 3 ovens, 20 orders - planning is essential
@action requires_entities: [
  %{type: "chef", capabilities: [:cooking]},
  %{type: "oven", capabilities: [:heating]}
]
def cook_meal(state, [meal_type]) do
  # Planner automatically:
  # - Assigns available chef
  # - Reserves available oven
  # - Schedules around other orders
  # - Handles equipment failures
  # - Optimizes for efficiency
end
```

### The Power Becomes Obvious

Once you see planning handle scenarios that would be nightmarish to code imperatively, the "weird" architecture makes perfect sense:

- **Dynamic replanning**: Order changes mid-cooking? Planner adapts automatically
- **Resource optimization**: Minimize chef idle time across all orders
- **Failure recovery**: Equipment breaks? Find alternatives and replan
- **Temporal constraints**: "Appetizer ready before main course" handled automatically
- **Multi-agent coordination**: 5 chefs working together without conflicts

The planning approach trades initial conceptual complexity for massive scalability and robustness.

## Planning vs Imperative Programming

### Why Planning Feels "Inverted"

If you're coming from normal programming, the planner architecture feels backwards because you're used to telling the computer exactly what to do, step by step. Planning systems flip this around - you describe what's *possible* and what you *want*, then let the planner figure out the steps.

**Normal Programming (Imperative):**

```elixir
# You control the execution flow directly
@spec make_dinner() :: :ok
def make_dinner() do
  go_to_kitchen()           # Step 1: Do this now
  get_ingredients()         # Step 2: Then do this  
  cook_meal()              # Step 3: Then do this
  serve_meal()             # Step 4: Finally this
end

# You call it when you want it to happen
make_dinner()
```

**Planning (Declarative):**

```elixir
# You describe what actions CAN happen and their requirements
@action duration: "PT2H", 
        requires_entities: [
          %{type: "chef", capabilities: [:cooking]},
          %{type: "ingredients", capabilities: [:consumable]}
        ]
@spec cook_meal(AriaState.t(), [String.t()]) :: AriaState.t()
def cook_meal(state, [meal_id]) do
  # Just describes the state change, not when/how to execute
  state |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
end

# You give the planner a goal and it figures out the steps
AriaEngine.plan(domain, state, [{"meal_status", "dinner", "ready"}])
# Planner thinks: "To have dinner ready, I need to cook_meal. To cook_meal, I need chef + ingredients..."
```

### The Mental Model Shift

**Instead of:** "Do step 1, then step 2, then step 3"
**Think:** "Here are the tools available, here's what I want, figure it out"

This feels weird because:

1. **You don't call functions directly** - you register them as "possible actions"
2. **The planner decides when to use them** - it searches through combinations
3. **You describe capabilities, not procedures** - "I can cook IF I have ingredients" vs "get ingredients, then cook"

### Why This "Inversion" Exists

The planning approach handles complexity that would be nightmare to code imperatively:

- **Dynamic prerequisites**: "Cook pasta, but if no pasta, make bread instead"
- **Resource conflicts**: "Chef can't cook and attend meeting simultaneously"
- **Temporal constraints**: "2-hour cooking must finish before 6pm dinner"
- **Multi-agent coordination**: "3 chefs preparing different courses for same meal"
- **Failure recovery**: "Oven broke, find alternative cooking method and replan"

Try coding those scenarios with normal if/else statements - you'll quickly see why planning exists!

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
  
  @type meal_id :: String.t()
  @type participants :: [String.t()]
  
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
  @spec cook_meal(AriaState.t(), [meal_id()]) :: AriaState.t()
  def cook_meal(state, [meal_id]) do
    # Pure state transformation, planner already validated requirements
    state
    |> AriaState.RelationalState.set_fact("meal_status", meal_id, "cooking")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
  end

  # Fixed scheduling example with @action attributes
  @action start: "2025-06-22T10:00:00Z",
          end: "2025-06-22T11:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "conference_room_1", capabilities: [:meeting_space]}
          ],
          description: "Scheduled team meeting in conference room"
  @spec meeting(AriaState.t(), [participants()]) :: AriaState.t()
  def meeting(state, [participants]) do
    # Implementation
    state
    |> AriaState.RelationalState.set_fact("meeting_status", "team_meeting", "in_progress")
    |> AriaState.RelationalState.set_fact("room_status", "conference_room_1", "occupied")
  end
end
```

## Temporal Specification Patterns

### Supported Patterns

**Pattern 1: Instant Actions - Anytime (zero duration)**

```elixir
%{duration: "PT0S"}  # Zero duration - can be done anytime
```

**Pattern 2: Instant Actions - Time Point (zero duration at specific time)**

```elixir
%{
  start: "2025-06-22T11:00:00Z",  # Instant action at exact time point
  end: "2025-06-22T11:00:00Z"     # Same time = zero duration, specific moment
}
```

**Pattern 3: Floating Duration (effort-based scheduling)**

```elixir
%{duration: "PT2H"}  # ISO 8601 duration string
```

**Pattern 4: Fixed Schedule (time-based scheduling)**

```elixir
%{
  start: "2025-06-22T10:00:00Z",  # ISO 8601 datetime string
  end: "2025-06-22T11:00:00Z"     # ISO 8601 datetime string
}
```

**Pattern 5: Open-ended Intervals**

```elixir
%{start: "2025-06-22T10:00:00Z"}  # Start time only
%{end: "2025-06-22T11:00:00Z"}    # End time only
```

### Validation Rules

- ✅ `duration: "PT0S"` (instant actions - can be done anytime)
- ✅ `start` AND `end` with same time (instant actions - must be done at specific time point)
- ✅ `duration` only (floating effort)
- ✅ `start` AND `end` with different times (fixed closed interval)
- ✅ `start` only (open-ended interval - starts at time, no end constraint)
- ✅ `end` only (open-ended interval - must finish by time, no start constraint)
- ❌ Cannot mix `duration` with `start`/`end`
- ✅ Missing temporal specification defaults to `duration: "PT0S"` (zero duration floating)

## Simple Durative Actions

Durative actions use **only** duration and entity requirements - no complex temporal conditions:

```elixir
@action duration: "PT2H",
        requires_entities: [
          %{type: "agent", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]},
          %{type: "kitchen", capabilities: [:workspace]}
        ]
@spec cook_meal(AriaState.t(), [String.t()]) :: AriaState.t()
def cook_meal(state, [meal_id]) do
  # Pure state transformation - planner already validated requirements
  state
  |> AriaState.RelationalState.set_fact("meal_status", meal_id, "cooking")
  |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
end
```

### Prerequisites and Verification via Method Decomposition

Use natural hierarchical decomposition for complex workflows:

```elixir
@task_method
@spec prepare_and_cook_meal(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
def prepare_and_cook_meal(state, [meal_id]) do
  {:ok, [
    # Prerequisites as goals
    {"available", "chef_1", true},
    {"temperature", "oven", {:>=, 350}},
    
    # Preparation as tasks
    {:setup_workspace, []},
    {:gather_ingredients, [meal_id]},
    
    # Main action (simple durative action)
    {:cook_meal, [meal_id]},
    
    # Verification as goals
    {"quality", "meal", {:>=, 8}},
    {"cleanup", "kitchen", "complete"}
  ]}
end

@action duration: "PT2H", requires_entities: [...]
@spec cook_meal(AriaState.t(), [String.t()]) :: AriaState.t()
def cook_meal(state, [meal_id]) do
  # Simple, clean action
  state |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
end
```

**Why this approach works better:**

- **Natural decomposition** - methods handle complexity, actions stay simple
- **Reusable components** - prerequisites and verification become separate todo items
- **Clear hierarchy** - follows established hierarchical planning principles
- **No embedded complexity** - actions focus purely on state transformation

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
AriaState.RelationalState.get_fact(state, predicate, subject)  # ✅ DIRECT FACT CHECKING (supports temporal queries)
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
9. **❌ TOMBSTONE: Mixed goal formats** - ONLY `{predicate, subject, value}` format allowed, all other formats rejected
10. **❌ TOMBSTONE: Complex state evaluation functions** - Use direct `AriaState.RelationalState.get_fact/3` queries instead of `State.evaluate_condition/2` or `validate_temporal_condition/2`
11. **❌ TOMBSTONE: Any validation in action functions** - ALL validation happens at planning time, actions are pure state transformations
12. **❌ TOMBSTONE: Command registration in domains** - Commands are execution-time functions, not domain registration artifacts
13. **❌ TOMBSTONE: Goal format inconsistency in ADR-131** - Fixed documentation error where tombstone claimed `{predicate, subject, value}` was correct format, but all examples used `{subject, predicate, value}`. Corrected specification to match actual usage patterns throughout codebase.
14. **❌ TOMBSTONE: Old unigoal API patterns** - ONLY predicate-based registration allowed
15. **❌ TOMBSTONE: `Domain.add_action` registration pattern** - Use `@action` attributes in module-based domains instead
16. **❌ TOMBSTONE: `Domain.declare_commands` registration pattern** - Use `@command` attributes in module-based domains instead
17. **❌ TOMBSTONE: Temporal conditions in durative actions** - `conditions: %{at_start: [...], over_all: [...], at_end: [...]}` violates hierarchical decomposition principles
18. **❌ TOMBSTONE: Mixed todo types in temporal conditions** - Goals, tasks, actions, multigoals embedded in action metadata creates unwieldy complexity
19. **❌ TOMBSTONE: Domain.DurativeAction with temporal conditions/effects** - Overly complex structure that inverts natural method decomposition
20. **❌ TOMBSTONE: Temporal condition processing logic** - Use regular method decomposition instead
21. **❌ TOMBSTONE: `at_start`, `over_all`, `at_end` condition types** - Natural prerequisites/verification handled by methods
22. **❌ TOMBSTONE: Temporal condition semantics with type specifications** - Overly complex typing for fundamentally flawed approach

**Old unigoal API patterns (TOMBSTONED):**

```elixir
# DON'T USE: Full tuple goal pattern (TOMBSTONED)
@unigoal_method goal_pattern: {"chef", "location", :any}
@spec travel_to_location(AriaState.t(), {String.t(), String.t(), String.t()}) :: {:ok, [AriaEngine.todo_item()]}
def travel_to_location(state, {"chef", "location", target}) do
  # ❌ WRONG - tuple destructuring signature
end

# USE INSTEAD: Advanced predicate-based registration
@unigoal_method predicate: "location"
@spec travel_to_location(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
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
@spec cook_meal(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, String.t()}
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
@spec cook_meal(AriaState.t(), [String.t()]) :: AriaState.t()
def cook_meal(state, [meal_type]) do
  # CORRECT: Pure state transformation, planner already validated requirements
  state
  |> AriaState.RelationalState.set_fact("meal_status", meal_type, "cooking")
  |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
end
```

**Why this separation matters:**

- **Planning Time**: Planner validates `requires_entities` against state before selecting actions
- **Execution Time**: Actions focus purely on state transformation
- **Performance**: No redundant validation during execution
- **Architecture**: Clean separation between planning logic and execution logic

## Complete Module-Based Domain Pattern

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  # Domain metadata
  @domain_name "cooking"
  @description "Cooking and meal preparation domain"
  
  @type meal_id :: String.t()
  @type ingredient_list :: [String.t()]
  
  # Instant actions (zero duration) - can be done anytime
  @action duration: "PT0S",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "kitchen", capabilities: [:workspace]}
          ]
  @spec announce_meal_ready(AriaState.t(), [meal_id()]) :: AriaState.t()
  def announce_meal_ready(state, [meal_id]) do
    # Instant action - no time required, can be done anytime
    state
    |> AriaState.RelationalState.set_fact("announcement", meal_id, "ready")
    |> AriaState.RelationalState.set_fact("notification_sent", meal_id, true)
  end
  
  @action duration: "PT0S",
          requires_entities: [
            %{type: "agent", capabilities: [:observation]}
          ]
  @spec check_ingredient_availability(AriaState.t(), [ingredient_list()]) :: AriaState.t()
  def check_ingredient_availability(state, [ingredient_list]) do
    # Instant check - immediate state query and update, can be done anytime
    available_count = Enum.count(ingredient_list, fn ingredient ->
      AriaState.RelationalState.get_fact(state, "available", ingredient) == true
    end)
    
    state
    |> AriaState.RelationalState.set_fact("ingredients_checked", "kitchen", true)
    |> AriaState.RelationalState.set_fact("available_ingredient_count", "kitchen", available_count)
  end
  
  # Instant actions at specific time points (zero duration at exact moment)
  @action start: "2025-06-22T12:00:00Z",
          end: "2025-06-22T12:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "bell", capabilities: [:sound]}
          ]
  @spec ring_lunch_bell(AriaState.t(), []) :: AriaState.t()
  def ring_lunch_bell(state, []) do
    # Instant action that must happen at exactly 12:00 PM
    state
    |> AriaState.RelationalState.set_fact("bell_status", "lunch_bell", "rung")
    |> AriaState.RelationalState.set_fact("lunch_announced", "kitchen", true)
  end
  
  @action start: "2025-06-22T18:00:00Z",
          end: "2025-06-22T18:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:management]},
            %{type: "restaurant", capabilities: [:service]}
          ]
  @spec close_kitchen(AriaState.t(), []) :: AriaState.t()
  def close_kitchen(state, []) do
    # Instant action that must happen at exactly 6:00 PM
    state
    |> AriaState.RelationalState.set_fact("kitchen_status", "main_kitchen", "closed")
    |> AriaState.RelationalState.set_fact("service_ended", "restaurant", true)
  end
  
  # Actions (planning-time) with capability system
  @action duration: "PT2H", 
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :menu_planning]},
            %{type: "oven", capabilities: [:heating, :baking]},
            %{type: "kitchen", capabilities: [:workspace]},
            %{type: "flour", capabilities: [:consumable]},
            %{type: "eggs", capabilities: [:consumable]},
            %{type: "mixing_bowl", capabilities: [:container, :reusable]}
          ],
          mutual_exclusion: ["kitchen_cleanup"],
          temporal_constraints: [
            {:before, "gather_ingredients"},
            {:during, "kitchen_available"}
          ]
  @spec cook_meal(AriaState.t(), [meal_id()]) :: AriaState.t()
  def cook_meal(state, [meal_id]) do
    # CORRECT: Pure state transformation, planner already validated requirements
    state
    |> AriaState.RelationalState.set_fact("meal_status", meal_id, "cooking")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
    |> AriaState.RelationalState.set_fact("oven_status", "oven_1", "in_use")
  end
  
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:shopping]},
            %{type: "market", capabilities: [:ingredient_source]}
          ]
  @spec gather_ingredients(AriaState.t(), [String.t()]) :: AriaState.t()
  def gather_ingredients(state, [task_name]) do
    # Planning-time logic for ingredient gathering
    state
    |> AriaState.RelationalState.set_fact("task", "status", "ingredients_gathered")
    |> AriaState.RelationalState.set_fact("task", "ingredients", task_name)
  end
  
  # Commands (execution-time) with failure handling
  @command
  @spec cook_meal_command(AriaState.t(), [meal_id()]) :: {:ok, AriaState.t()} | {:error, String.t()}
  def cook_meal_command(state, [meal_id]) do
    case attempt_cooking_with_failure_chance(state, meal_id) do
      {:ok, new_state} -> 
        Logger.info("cook_meal_command succeeded for #{meal_id}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("cook_meal_command failed: #{reason}")
        {:error, reason}
    end
  end
  
  @command
  @spec gather_ingredients_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, String.t()}
  def gather_ingredients_command(state, [task_name]) do
    case attempt_gathering_with_failure_chance(state, task_name) do
      {:ok, new_state} -> 
        Logger.info("gather_ingredients_command succeeded")
        {:ok, new_state}
      {:error, reason} -> 
        Logger.warn("gather_ingredients_command failed: #{reason}")
        {:error, reason}
    end
  end
  
  # Task methods
  @task_method
  @spec task_prepare_ingredients(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
  def task_prepare_ingredients(state, [task_name]) do
    {:ok, [
      {:gather_ingredients, [task_name]},
      {:wash_ingredients, [task_name]},
      {:verify_ingredients, [task_name]}  # Auto-verification
    ]}
  end
  
  @task_method
  @spec task_complete_meal(AriaState.t(), [meal_id()]) :: {:ok, [AriaEngine.todo_item()]}
  def task_complete_meal(state, [meal_id]) do
    {:ok, [
      {:task_prepare_ingredients, [meal_id]},
      {:cook_meal, [meal_id]},
      {:serve_meal, [meal_id]}
    ]}
  end
  
  # Unigoal methods with automatic verification (ADVANCED: Predicate-based registration)
  @unigoal_method predicate: "location"
  @spec travel_to_location(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
  def travel_to_location(state, [subject, target]) do
    current = AriaState.RelationalState.get_fact(state, subject, "location")
    if current == target do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:walk_to_location, [subject, target]},
        {:verify_location, [subject, target]}  # Auto-verification
      ]}
    end
  end
  
  @unigoal_method predicate: "has"
  @spec acquire_item(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
  def acquire_item(state, [subject, item]) do
    current_items = AriaState.RelationalState.get_fact(state, subject, "inventory") || []
    if item in current_items do
      {:ok, []}  # Already has item
    else
      {:ok, [
        {:find_item, [item]},
        {:pick_up_item, [item]}
      ]}
    end
  end
  
  # EXPLICIT multigoal methods (Pure GTPyhop Style)
  # Domain author MUST define if multigoals are used
  @multigoal_method goal_pattern: :cooking_workflow
  @spec handle_cooking_workflow(AriaState.t(), AriaEngine.multigoal()) :: {:ok, [AriaEngine.todo_item()]}
  def handle_cooking_workflow(state, multigoal) do
    # Domain author explicitly chooses strategy
    case custom_cooking_optimization(state, multigoal.goals) do
      {:ok, plan} -> {:ok, plan}
      {:error, _} ->
        # Domain author EXPLICITLY chooses fallback
        Logger.debug("Custom optimization failed, using split_multigoal")
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
  
  @multigoal_method goal_pattern: :general_goals
  @spec handle_general_multigoal(AriaState.t(), AriaEngine.multigoal()) :: {:ok, [AriaEngine.todo_item()]}
  def handle_general_multigoal(state, multigoal) do
    # Strategy 1: Default/basic decomposition (analog to sequential_todo_execution)
    AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
  end
  
  @multigoal_method goal_pattern: :optimization_goals
  @spec handle_optimization_multigoal(AriaState.t(), AriaEngine.multigoal()) :: {:ok, [AriaEngine.todo_item()]}
  def handle_optimization_multigoal(state, multigoal) do
    # Strategy 2: MinizinC-optimized multigoal
    case AriaMinizincGoal.optimize_multigoal(state, multigoal) do
      {:ok, plan} -> 
        Logger.debug("MinizinC multigoal optimization succeeded")
        {:ok, plan}
      {:error, _} ->
        # Domain author explicitly chooses split_multigoal as fallback
        Logger.debug("MinizinC failed, using split_multigoal")
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
  
  # Multitodo methods (symmetric to multigoal methods)
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Strategy 1: Default/basic sequential execution (analog to split_multigoal)
    AriaEngine.TodoExecution.sequential_todo_execution(state, todo_list)
  end
  
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Strategy 2: Resource-optimized reordering
    todo_list
    |> group_by_resource_requirements(state)
    |> flatten_optimized_groups()
  end
  
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Strategy 3: Makespan-optimized reordering
    todo_list
    |> calculate_execution_times(state)
    |> sort_by_critical_path()
  end
  
  # Domain creation follows module-based pattern
  @spec create_domain(map()) :: AriaEngine.Domain.t()
  def create_domain(opts \\ %{}) do
    domain = __MODULE__.create_base_domain()
    
    # Configure goal verification (IPyHOP feature)
    domain = AriaEngine.Domain.set_verify_goals(domain, Map.get(opts, :verify_goals, true))
    
    # Initialize blacklist system
    domain = %{domain | blacklist: MapSet.new()}
    
    # Configure solution tree tracking
    domain = AriaEngine.Domain.enable_solution_tree(domain, true)
    
    domain
  end
  
  # Helper functions for domain logic
  @spec custom_cooking_optimization(AriaState.t(), [AriaEngine.goal()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, String.t()}
  defp custom_cooking_optimization(state, goals) do
    # Domain-specific optimization logic
    cooking_goals = Enum.filter(goals, &is_cooking_goal?/1)
    location_goals = Enum.filter(goals, &is_location_goal?/1)
    
    case {cooking_goals, location_goals} do
      {[], []} -> {:ok, []}
      {cooking, []} -> optimize_cooking_sequence(state, cooking)
      {[], locations} -> optimize_travel_sequence(state, locations)
      {cooking, locations} -> optimize_combined_workflow(state, cooking, locations)
    end
  end
  
  @spec is_cooking_goal?(AriaEngine.goal()) :: boolean()
  defp is_cooking_goal?({_subject, predicate, _value}) when predicate in ["meal_status", "cooking_task"], do: true
  defp is_cooking_goal?(_), do: false
  
  @spec is_location_goal?(AriaEngine.goal()) :: boolean()
  defp is_location_goal?({_subject, "location", _value}), do: true
  defp is_location_goal?(_), do: false
end
```

## Usage Examples and Patterns

### Planning with Solution Tree

```elixir
domain = MyApp.Domains.CookingDomain.create_domain()

# Planning creates solution tree with proper node types
{:ok, solution_tree, plan} = AriaEngine.plan_with_tree(domain, initial_state, [
  {:cook_meal, ["pasta"]},
  {"location", "chef", "kitchen"}  # Goal
])

# Execution with replanning on failure
case AriaEngine.run_lazy_refineahead(domain, initial_state, solution_tree) do
  {:ok, final_state} -> 
    Logger.info("Execution completed successfully")
  {:error, reason} -> 
    Logger.error("Execution failed: #{reason}")
end
```

### Commands vs Actions

```elixir
# Planning-time: Actions assume success for planning purposes
{:ok, plan} = AriaEngine.plan(domain, state, [{:cook_meal, ["pasta"]}])

# Execution-time: Commands handle real-world failures
case AriaEngine.execute_command(domain, state, :cook_meal_command, ["pasta"]) do
  {:ok, new_state} -> Logger.info("Cooking succeeded")
  {:error, :oven_malfunction} -> 
    # Command failed - action gets blacklisted, replanning triggered
    Logger.warn("Oven malfunction, trying alternative cooking method")
end
```

### Multigoal Handling (Pure GTPyhop Style)

```elixir
# Domain WITHOUT multigoal methods - planning FAILS
simple_domain = MyApp.Domains.SimpleCookingDomain.create_domain()

multigoal = [
  {"location", "chef", "kitchen"},
  {"has", "chef", "ingredients"}
]

case AriaEngine.plan(simple_domain, state, [multigoal]) do
  {:error, "No multigoal methods defined"} -> 
    # Expected - domain must define multigoal methods explicitly
    Logger.error("Domain must define multigoal methods explicitly")
end

# Domain WITH explicit multigoal methods - planning succeeds
advanced_domain = MyApp.Domains.CookingDomain.create_domain()

case AriaEngine.plan(advanced_domain, state, [multigoal]) do
  {:ok, plan} -> 
    # Success - domain has explicit @multigoal_method
    execute_plan(plan)
end
```

### Natural Method Decomposition Examples

Instead of complex temporal conditions, use the existing hierarchical planning system:

```elixir
# Simple, clean approach using method decomposition
defmodule MyApp.Domains.CleanCookingDomain do
  use AriaEngine.Domain
  
  # Simple durative action - just duration and entities
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]},
            %{type: "kitchen", capabilities: [:workspace]}
          ]
  def cook_meal(state, [meal_id]) do
    # Pure state transformation
    state
    |> AriaState.RelationalState.set_fact("meal_status", meal_id, "ready")
    |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "available")
  end
  
  # Complex workflow handled by method decomposition
  @task_method
  def full_cooking_workflow(state, [meal_id]) do
    {:ok, [
      # Prerequisites (instead of at_start conditions)
      {"available", "chef_1", true},
      {"temperature", "oven", {:>=, 350}},
      {"clean", "workspace", true},
      
      # Preparation tasks
      {:setup_workspace, []},
      {:gather_ingredients, [meal_id]},
      {:preheat_oven, []},
      
      # Main cooking action
      {:cook_meal, [meal_id]},
      
      # Verification (instead of at_end conditions)
      {"quality", "meal", {:>=, 8}},
      {"cleanup", "kitchen", "complete"}
    ]}
  end
end
```

**Why this approach is better:**

- **Natural hierarchy** - follows established hierarchical planning principles
- **Reusable components** - tasks can be used in multiple workflows
- **Clear separation** - actions stay simple, methods handle complexity
- **No embedded logic** - complexity lives in the decomposition, not the action
- **Easier to understand** - follows normal programming intuition
- **Maintainable** - changes to workflow don't require action modifications

## CRITICAL ENFORCEMENT: Function Attribute Requirements

**Every function that integrates with the planner system MUST have the corresponding attribute:**

### Required Attribute Patterns

**Planner Actions:**

```elixir
@action duration: "PT2H", requires_entities: [...]
@spec action_name(AriaState.t(), [term()]) :: AriaState.t()
def action_name(state, args) do
  # Can reference @action metadata
end
```

**Execution Commands:**

```elixir
@command
@spec command_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, String.t()}
def command_name(state, args) do
  # Execution-time logic only
end
```

**Task Methods:**

```elixir
@task_method
@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]}
def task_name(state, args) do
  # Task decomposition logic
end
```

**Unigoal Methods:**

```elixir
@unigoal_method predicate: "location"
@spec method_name(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
def method_name(state, [subject, value]) do
  # Goal decomposition logic
end
```

**Multigoal Methods:**

```elixir
@multigoal_method goal_pattern: :pattern_name
@spec multigoal_method(AriaState.t(), AriaEngine.multigoal()) :: {:ok, [AriaEngine.todo_item()]}
def multigoal_method(state, multigoal) do
  # Multigoal handling logic
end
```

**Multitodo Methods:**

```elixir
@multitodo_method
@spec multitodo_method(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
def multitodo_method(state, todo_list) do
  # Todo list optimization logic - multiple methods with same name
  # MinZinC chooses optimal strategy based on optimization criteria
end
```

### Violation Examples (FORBIDDEN)

❌ **WRONG - No attribute but references planner metadata:**

```elixir
@spec cook_meal(AriaState.t(), [String.t()]) :: term()
def cook_meal(state, [meal_type]) do  # No @action attribute
  case validate(@action[:requires_entities]) do  # ❌ References non-existent metadata
end
```

❌ **WRONG - No attribute but presented as planner function:**

```elixir
@spec travel_to_location(AriaState.t(), [String.t()]) :: term()
def travel_to_location(state, [subject, target]) do  # No @unigoal_method attribute
  # Presented as unigoal method but not registered with planner
end
```

✅ **CORRECT - Helper function (no planner integration):**

```elixir
@spec calculate_cooking_time(String.t()) :: non_neg_integer()
defp calculate_cooking_time(meal_type) do  # Private helper
  # No planner metadata references, no attribute needed
end
```

**ENFORCEMENT:** Functions without attributes are helper functions only - no planner integration allowed.

## Success Criteria

- [x] Both floating durations and fixed intervals supported via ISO 8601 strings
- [x] Unified action specification with entities, capabilities, and resources
- [x] All goals use `{predicate, subject, value}` format consistently
- [x] All state validation uses direct `State.get_fact/3` calls (with temporal query support)
- [x] Single standardized way to define actions
- [x] Clear documentation on which planning API to use when

## Related ADRs

- **ADR-182**: Technical Implementation (Implementation Guide)
- **ADR-183**: Architecture & Standards (System Design)
- **ADR-184**: Common Use Cases and Patterns (Pattern outline framework)

## Implementation Status

**Status:** Active - Core specification under ongoing refinement

**Usage:** Foundation for all AriaEngine domain development

**Timeline:** Available immediately

**Compatibility:** Full backward compatibility maintained
