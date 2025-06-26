# ADR-181: Planner Specification - Unified Durative Action Specification

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

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

### Why Planning Feels "Backwards"

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

### Why is this backwards?

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

## Entity Registration and State Setup

Before the planner can match entities to action requirements, entities must be registered in the state with their types and capabilities.

### Basic Entity Registration Pattern

```elixir
@spec register_entity(AriaState.t(), String.t(), String.t(), [capability()]) :: AriaState.t()
def register_entity(state, entity_id, type, capabilities) do
  state
  |> AriaState.RelationalState.set_fact("type", entity_id, type)
  |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
  |> AriaState.RelationalState.set_fact("status", entity_id, "available")
end
```

### Complete Scenario Setup

```elixir
@spec setup_kitchen_scenario() :: AriaState.t()
def setup_kitchen_scenario() do
  AriaState.RelationalState.new()
  |> register_entity("chef_1", "agent", [:cooking, :menu_planning])
  |> register_entity("sous_chef_1", "agent", [:cooking, :prep_work])
  |> register_entity("oven_1", "oven", [:heating, :baking])
  |> register_entity("stovetop_1", "stovetop", [:heating, :sauteing])
  |> register_entity("main_kitchen", "kitchen", [:workspace])
  |> register_entity("prep_station", "kitchen", [:workspace, :prep_area])
  |> register_entity("flour_bag", "flour", [:consumable])
  |> register_entity("eggs_dozen", "eggs", [:consumable])
  |> register_entity("mixing_bowl_1", "mixing_bowl", [:container, :reusable])
end
```

### Entity Properties and Status

Additional entity properties are stored as separate facts:

```elixir
@spec setup_detailed_kitchen() :: AriaState.t()
def setup_detailed_kitchen() do
  setup_kitchen_scenario()
  # Entity locations
  |> AriaState.RelationalState.set_fact("location", "chef_1", "main_kitchen")
  |> AriaState.RelationalState.set_fact("location", "oven_1", "main_kitchen")
  
  # Equipment properties
  |> AriaState.RelationalState.set_fact("max_temp", "oven_1", 450)
  |> AriaState.RelationalState.set_fact("min_temp", "oven_1", 150)
  |> AriaState.RelationalState.set_fact("current_temp", "oven_1", 75)
  
  # Consumable quantities
  |> AriaState.RelationalState.set_fact("quantity", "flour_bag", 5.0)
  |> AriaState.RelationalState.set_fact("unit", "flour_bag", "pounds")
  |> AriaState.RelationalState.set_fact("quantity", "eggs_dozen", 12)
  |> AriaState.RelationalState.set_fact("unit", "eggs_dozen", "count")
end
```

### Complete End-to-End Example

```elixir
# 1. Set up entities in state
initial_state = setup_kitchen_scenario()

# 2. Create domain with action specifications
domain = MyApp.Domains.CookingDomain.create_domain()

# 3. Plan with goals - planner finds entities that match action requirements
{:ok, plan} = AriaEngine.plan(domain, initial_state, [
  {:cook_meal, ["pasta"]},
  {"location", "chef_1", "main_kitchen"}  # Goal format
])

# 4. Execute plan - entities are automatically assigned based on capabilities
{:ok, final_state} = AriaEngine.execute_plan(domain, initial_state, plan)
```

### How Capability Matching Works

When the planner encounters an action like `cook_meal`, it:

1. **Reads action requirements**: `requires_entities: [%{type: "agent", capabilities: [:cooking]}]`
2. **Queries state for matching entities**: Finds entities where `type == "agent"` AND `:cooking` in `capabilities`
3. **Checks availability**: Ensures entity `status == "available"` (not already assigned)
4. **Makes assignment**: Reserves the entity for this action's duration
5. **Updates state**: Marks entity as busy during action execution

```elixir
# Planner internally performs queries like:
available_cooks = AriaState.RelationalState.query(state, fn entity_id ->
  type = AriaState.RelationalState.get_fact(state, "type", entity_id)
  capabilities = AriaState.RelationalState.get_fact(state, "capabilities", entity_id)
  status = AriaState.RelationalState.get_fact(state, "status", entity_id)
  
  type == "agent" && 
  :cooking in capabilities && 
  status == "available"
end)
# Returns: ["chef_1", "sous_chef_1"] (entities that can cook and are available)
```

### Entity Registration Best Practices

**Required facts for all entities:**

- `"type"` - Entity category (agent, oven, kitchen, etc.)
- `"capabilities"` - List of capability atoms
- `"status"` - Availability state ("available", "busy", "broken", etc.)

**Optional but recommended facts:**

- `"location"` - Where the entity is located
- `"quantity"` - For consumable entities
- Equipment-specific properties (temperature ranges, capacity, etc.)

**Entity naming conventions:**

- Use descriptive IDs: `"chef_1"`, `"main_oven"`, `"prep_station_a"`
- Include numbers for multiple similar entities: `"mixing_bowl_1"`, `"mixing_bowl_2"`
- Avoid generic names that don't distinguish between entities

## Domain Definition of Actions Specification

### Module-Based Domain Pattern

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
  @action start: "2025-06-22T10:00:00-07:00",
          end: "2025-06-22T11:00:00-07:00",
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

  # Start time with duration example (calculated end time)
  @action start: "2025-06-22T14:00:00-07:00",
          duration: "PT1H30M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]}
          ],
          description: "Afternoon baking session starting at 2 PM, lasting 1.5 hours"
  @spec afternoon_baking(AriaState.t(), [String.t()]) :: AriaState.t()
  def afternoon_baking(state, [recipe]) do
    # Automatically scheduled from 14:00 to 15:30 (start + duration)
    state
    |> AriaState.RelationalState.set_fact("baking_status", recipe, "in_progress")
    |> AriaState.RelationalState.set_fact("oven_reserved", "main_oven", true)
  end

  # End time with duration example (calculated start time)
  @action end: "2025-06-22T18:00:00-07:00",
          duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]},
            %{type: "oven", capabilities: [:heating]},
            %{type: "kitchen", capabilities: [:workspace]}
          ],
          description: "Dinner preparation must finish by 6 PM, takes 2 hours"
  @spec prepare_dinner(AriaState.t(), [String.t()]) :: AriaState.t()
  def prepare_dinner(state, [menu]) do
    # Automatically scheduled from 16:00 to 18:00 (end - duration = start)
    state
    |> AriaState.RelationalState.set_fact("dinner_status", menu, "preparing")
    |> AriaState.RelationalState.set_fact("kitchen_reserved", "main_kitchen", true)
  end

  # Fully constrained example (validation)
  @action start: "2025-06-22T09:00:00-07:00",
          end: "2025-06-22T11:00:00-07:00",
          duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "conference_room", capabilities: [:meeting_space]}
          ],
          description: "Morning workshop with explicit time validation"
  @spec morning_workshop(AriaState.t(), [String.t()]) :: AriaState.t()
  def morning_workshop(state, [topic]) do
    # System validates: 09:00 + 2 hours = 11:00 (consistent)
    state
    |> AriaState.RelationalState.set_fact("workshop_status", topic, "in_session")
    |> AriaState.RelationalState.set_fact("room_status", "conference_room", "occupied")
  end
end
```

## Temporal Specification Patterns

### Supported Patterns

All temporal specifications follow the 9-pattern system defined in the Complete Temporal Specification Permutations table. Each pattern represents a valid combination of `start`, `end`, and `duration` fields:

**Pattern 1: No Temporal Specification**

- No duration, start, or end specified (❌ ❌ ❌ ❌)
- Defaults to instant action that can be scheduled anytime

**Pattern 2: Zero Duration Specified**

- Explicit zero duration (❌ ❌ ❌ ✅) with `duration: "PT0S"`
- Instant action that can be scheduled anytime

**Pattern 3: Floating Duration**

```elixir
%{duration: "PT2H"}  # Takes 2 hours, planner chooses when
```

**Pattern 4: Deadline Constraint**

```elixir
%{end: "2025-06-22T14:00:00-07:00"}  # Must finish by 2 PM
```

**Pattern 5: Duration with Deadline (Calculated Start)**

```elixir
%{end: "2025-06-22T14:00:00-07:00", duration: "PT2H"}  # start = end - duration
```

**Pattern 6: Scheduled Start**

```elixir
%{start: "2025-06-22T10:00:00-07:00"}  # Starts at 10 AM
```

**Pattern 7: Start with Duration (Calculated End)**

```elixir
%{start: "2025-06-22T10:00:00-07:00", duration: "PT2H"}  # end = start + duration
```

**Pattern 8: Fixed Interval**

```elixir
%{start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"}  # Explicit times
```

**Pattern 9: Fully Constrained (Validation)**

```elixir
%{start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00", duration: "PT2H"}  # Validates consistency
```

**Reference:** See "Complete Temporal Specification Permutations" section for detailed semantics, validation rules, and implementation logic for each pattern.

### Complete Temporal Specification Permutations

**All 9 possible combinations of `start`, `end`, and `duration` are legal:**

| Pattern | start | end | duration | Status | Semantics |
|---------|-------|-----|----------|--------|-----------|
| 1 | ❌ | ❌ | ❌ | ❌ | Valid default case (instant action, anytime) |
| 2 | ❌ | ❌ | ❌ | ✅ | Valid default case (instant action, anytime) |
| 3 | ❌ | ❌ | ✅ | ✅ | Floating duration (schedule anytime) |
| 4 | ❌ | ✅ | ❌ | ✅ | Deadline constraint (finish by end time) |
| 5 | ❌ | ✅ | ✅ | ✅ | **Calculated start** (`start = end - duration`) |
| 6 | ✅ | ❌ | ❌ | ✅ | Open start (begins at time, no end constraint) |
| 7 | ✅ | ❌ | ✅ | ✅ | **Calculated end** (`end = start + duration`) |
| 8 | ✅ | ✅ | ❌ | ✅ | Fixed interval (explicit start and end) |
| 9 | ✅ | ✅ | ✅ | ✅ | **Constraint validation** (`start + duration = end`) |

### Validation Rules

- ✅ **Pattern 1**: Missing temporal specification (alternative interpretation) - valid default case
- ✅ **Pattern 2**: Missing temporal specification (standard interpretation) - valid default case  
- ✅ **Pattern 3**: `duration` only (floating effort - schedule anytime)
- ✅ **Pattern 4**: `end` only (deadline constraint - must finish by time)
- ✅ **Pattern 5**: `end` AND `duration` (calculated start - `start = end - duration`)
- ✅ **Pattern 6**: `start` only (open start - begins at time, no end constraint)
- ✅ **Pattern 7**: `start` AND `duration` (calculated end - `end = start + duration`)
- ✅ **Pattern 8**: `start` AND `end` (fixed interval - explicit times)
  - ✅ Same time = instant action at specific moment
  - ✅ Different times = fixed closed interval
- ✅ **Pattern 9**: `start` AND `end` AND `duration` (constraint validation - must satisfy `start + duration = end`)

### Semantic Definitions

**Pattern 1: No Temporal Specification**

```elixir
%{}  # No duration, start, or end specified
```

*Semantics*: Instant action that can be scheduled at any time.
*Use case*: "Check inventory" - can be done anytime, takes no time.

**Pattern 2: Zero Duration Specified**

```elixir
%{duration: "PT0S"}  # Explicit zero duration
```

*Semantics*: Instant action that can be scheduled at any time.
*Use case*: "Quick status check" - explicitly zero duration, can be done anytime.
*Note*: Both Pattern 1 and 2 have identical semantics but different specifications.

**Pattern 3: Floating Duration**

```elixir
%{duration: "PT2H"}
```

*Semantics*: Action takes 2 hours, planner chooses when to schedule it.
*Use case*: "Cook meal" - takes 2 hours, schedule when convenient.

**Pattern 4: Deadline Constraint**

```elixir
%{end: "2025-06-22T14:00:00-07:00"}
```

*Semantics*: Action must complete by 2 PM, planner chooses start time.
*Use case*: "Prepare lunch" - must be ready by 2 PM, start whenever needed.

**Pattern 5: Duration with Deadline (Calculated Start)**

```elixir
%{end: "2025-06-22T14:00:00-07:00", duration: "PT2H"}
```

*Semantics*: Must finish by 2 PM, takes 2 hours, so must start by 12 PM.
*Use case*: "Baking for dinner" - must finish by dinner time, takes 2 hours.

**Pattern 6: Scheduled Start**

```elixir
%{start: "2025-06-22T10:00:00-07:00"}
```

*Semantics*: Action starts at 10 AM, planner chooses end time (or instant if no duration).
*Use case*: "Morning meeting" - starts at 10 AM, duration flexible.

**Pattern 7: Start with Duration (Calculated End)**

```elixir
%{start: "2025-06-22T10:00:00-07:00", duration: "PT2H"}
```

*Semantics*: Starts at 10 AM, takes 2 hours, automatically ends at 12 PM.
*Use case*: "Workshop session" - starts at 10 AM, runs for 2 hours.

**Pattern 8: Fixed Interval**

```elixir
%{start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00"}
```

*Semantics*: Explicitly scheduled from 10 AM to 12 PM.
*Use case*: "Conference call" - fixed time slot from 10 AM to 12 PM.

**Pattern 9: Fully Constrained (Validation)**

```elixir
%{start: "2025-06-22T10:00:00-07:00", end: "2025-06-22T12:00:00-07:00", duration: "PT2H"}
```

*Semantics*: All three specified, system validates `start + duration = end` (10 AM + 2 hours = 12 PM).
*Use case*: "Explicit schedule verification" - ensure all temporal constraints are consistent.

### Implementation Logic

**Pattern 4 Calculation (Backward Time)**

```elixir
# Given: end time and duration
# Calculate: start time
start_time = DateTime.add(end_time, -duration_seconds, :second)
```

**Pattern 6 Calculation (Forward Time)**

```elixir
# Given: start time and duration  
# Calculate: end time
end_time = DateTime.add(start_time, duration_seconds, :second)
```

**Pattern 8 Validation (Consistency Check)**

```elixir
# Given: start, end, and duration
# Validate: start + duration = end
calculated_end = DateTime.add(start_time, duration_seconds, :second)
if calculated_end != end_time do
  {:error, "Inconsistent temporal specification: start + duration ≠ end"}
end
```

### Error Handling

**Pattern 4 Errors:**

- Negative start time (duration longer than time until end)
- Invalid duration format

**Pattern 8 Errors:**

- Inconsistent constraint: `start + duration ≠ end`
- Example: start=10:00, end=13:00, duration=PT2H (10+2≠13)

**General Errors:**

- Invalid ISO 8601 datetime format
- Invalid ISO 8601 duration format
- Start time after end time (Pattern 7)

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
  @action start: "2025-06-22T12:00:00-07:00",
          end: "2025-06-22T12:00:00-07:00",
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
  
  @action start: "2025-06-22T18:00:00-07:00",
          end: "2025-06-22T18:00:00-07:00",
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
  @command true
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
  
  @command true
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
  @task_method true
  @spec task_prepare_ingredients(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
  def task_prepare_ingredients(state, [task_name]) do
    {:ok, [
      {:gather_ingredients, [task_name]},
      {:wash_ingredients, [task_name]},
      {:verify_ingredients, [task_name]}  # Auto-verification
    ]}
  end
  
  @task_method true
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
  @multitodo_method true
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Strategy 1: Default/basic sequential execution (analog to split_multigoal)
    AriaEngine.TodoExecution.sequential_todo_execution(state, todo_list)
  end
  
  @multitodo_method true
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
  state
end
```

**Execution Commands:**

```elixir
@command
@spec command_name(AriaState.t(), [term()]) :: {:ok, AriaState.t()} | {:error, String.t()}
def command_name(state, args) do
  # Execution-time logic only
  state
end
```

**Task Methods:**

```elixir
@task_method
@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]}
def task_name(state, args) do
  # Task decomposition logic
  [...]
end
```

**Unigoal Methods:**

```elixir
@unigoal_method predicate: "location"
@spec method_name(AriaState.t(), [String.t()]) :: {:ok, [AriaEngine.todo_item()]}
def method_name(state, [subject, value]) do
  # Goal decomposition logic
  [...]
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

## Tombstoned Concepts

The following concepts were explicitly rejected during design:

1. **❌ TOMBSTONE: `quantity` field in action metadata** - Quantities are state fluents, not action metadata
2. **❌ TOMBSTONE: Separate `resources` map with `consumables`, `tools`, `locations`** - Everything is entities with capabilities
3. **❌ TOMBSTONE: `properties` field in entity requirements** - Use capabilities instead
4. **❌ TOMBSTONE: Separate `requires_agent` field** - Agents are entities with capabilities
5. **❌ TOMBSTONE: `location` field in action metadata** - Locations are entities in `requires_entities`
6. **❌ TOMBSTONE: `constraints` field in entity requirements** - Quantities, availability, and dynamic properties are state fluents, not action metadata
7. **❌ TOMBSTONE: Requirement validation in action functions** - Actions assume planner has already validated requirements
8. **❌ TOMBSTONE: Entity properties in action metadata** - Properties like `max_temp`, `quantity`, `size` belong in state, not action metadata
9. **❌ TOMBSTONE: Mixed goal formats** - ONLY `{predicate, subject, value}` format allowed, all other formats rejected
10. **❌ TOMBSTONE: Complex state evaluation functions** - Use direct `AriaState.RelationalState.get_fact/3` queries instead of `State.evaluate_condition/2` or `validate_temporal_condition/2`
11. **❌ TOMBSTONE: Any validation in action functions** - ALL validation happens at planning time, actions are pure state transformations
12. **❌ TOMBSTONE: Command registration in domains** - Commands are execution-time functions, not domain registration artifacts
13. **❌ TOMBSTONE: Goal format inconsistency in ADR-131** - Fixed documentation error where tombstone claimed `{predicate, subject, value}` was correct format, but all examples used `{subject, predicate, value}`
14. **❌ TOMBSTONE: Old unigoal API patterns** - ONLY predicate-based registration allowed
15. **❌ TOMBSTONE: `Domain.add_action` registration pattern** - Use `@action` attributes in module-based domains instead
16. **❌ TOMBSTONE: `Domain.declare_commands` registration pattern** - Use `@command` attributes in module-based domains instead
17. **❌ TOMBSTONE: Temporal conditions in durative actions** - `conditions: %{at_start: [...], over_all: [...], at_end: [...]}` violates hierarchical decomposition principles
18. **❌ TOMBSTONE: Mixed todo types in temporal conditions** - Goals, tasks, actions, multigoals embedded in action metadata creates unwieldy complexity
19. **❌ TOMBSTONE: Domain.DurativeAction with temporal conditions/effects** - Overly complex structure that inverts natural method decomposition
20. **❌ TOMBSTONE: Temporal condition processing logic** - Use regular method decomposition instead
21. **❌ TOMBSTONE: `at_start`, `over_all`, `at_end` condition types** - Natural prerequisites/verification handled by methods
22. **❌ TOMBSTONE: Temporal condition semantics with type specifications** - Overly complex typing for fundamentally flawed approach
23. **❌ TOMBSTONE: Functions without attributes referencing planner metadata** - Functions must have corresponding attributes (@action, @command, etc.) to integrate with planner system
24. **❌ TOMBSTONE: Functions presented as planner functions without attributes** - All planner integration requires explicit attribute declaration
25. **❌ TOMBSTONE: `mutual_exclusion` field in action metadata** - Resource conflicts handled by planner entity allocation, not action metadata
26. **❌ TOMBSTONE: `temporal_constraints` field in action metadata** - Temporal relationships handled by method decomposition, not embedded action constraints
27. **❌ TOMBSTONE: UTC timezone format when local timezone isn't UTC** - Use local timezone strings (e.g., "-07:00") instead of "Z" suffix when working in non-UTC timezones
28. **❌ TOMBSTONE: `priority` field in @unigoal_method attributes** - Priority handling belongs in planner method selection logic, not in attribute metadata
29. **❌ TOMBSTONE: `goal_pattern` field in @task_method attributes** - Task methods are for workflow decomposition only, not goal pattern matching
30. **❌ TOMBSTONE: Bare module attributes without values (@task_method, @command, @multitodo_method)** - Use explicit true value (@task_method true) to follow standard Elixir conventions and avoid compiler warnings

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

## Related Work and Standards

### Academic Foundation

This specification builds upon established research in automated planning and scheduling, particularly temporal planning with durative actions. The core concepts align with and extend several foundational works in the field:

**Temporal Planning and Durative Actions:**

- Fox, M.; Long, D. (2003). "PDDL2.1: An Extension to PDDL for Expressing Temporal Planning Domains". *Journal of Artificial Intelligence Research*, 20:61-124. DOI: [`10.1613/jair.1129`](https://doi.org/10.1613/jair.1129)
- Fox, M.; Long, D. (2006). "Modelling Mixed Discrete-Continuous Domains for Planning". *Journal of Artificial Intelligence Research*, 27:235-297. DOI: [`10.1613/jair.2044`](https://doi.org/10.1613/jair.2044)

**Automated Planning Theory:**

- Ghallab, M.; Nau, D.; Traverso, P. (2004). *Automated Planning: Theory and Practice*. Morgan Kaufmann. ISBN: 1-55860-856-7. Available: [`http://www.laas.fr/planning/`](http://www.laas.fr/planning/)

**Planning Domain Definition Language Standards:**

- Kovacs, D.L. (2011). "BNF Definition of PDDL 3.1". Technical Report. Available: [`https://planning.wiki/ref/pddl`](https://planning.wiki/ref/pddl)

### Programming Language Ecosystems and Runtime Systems

**Actor Model and Fault-Tolerant Computing:**

- Hewitt, C.; Bishop, P.; Steiger, R. (1973). "A Universal Modular ACTOR Formalism for Artificial Intelligence". *Proceedings of the 3rd International Joint Conference on Artificial Intelligence*, 235-245. Available: [`https://www.ijcai.org/Proceedings/73/Papers/027B.pdf`](https://www.ijcai.org/Proceedings/73/Papers/027B.pdf)
- Armstrong, J. (2003). "Making reliable distributed systems in the presence of software errors". *Doctoral Dissertation*, Royal Institute of Technology, Stockholm. Available: [`https://erlang.org/doc/`](https://erlang.org/doc/)

**Functional Programming and Concurrency:**

- Agha, G. (1986). "Actors: A Model of Concurrent Computation in Distributed Systems". *MIT Press*. ISBN: 0-262-01092-5. DOI: [`10.7551/mitpress/1086.001.0001`](https://doi.org/10.7551/mitpress/1086.001.0001)
- Valim, J. (2013). "Elixir in Action". *Manning Publications*. ISBN: 978-1617295027

**OTP Design Principles:**

- Cesarini, F.; Thompson, S. (2009). "Erlang Programming". *O'Reilly Media*. ISBN: 978-0596518189
- Logan, M.; Merritt, E.; Carlsson, R. (2010). "Erlang and OTP in Action". *Manning Publications*. ISBN: 978-1933988788

### Constraint Programming and Optimization

**Constraint Satisfaction Problems:**

- Tsang, E. (1993). "Foundations of Constraint Satisfaction". *Academic Press*. ISBN: 0-12-701610-4. DOI: [`10.1016/B978-0-12-701610-8.50005-2`](https://doi.org/10.1016/B978-0-12-701610-8.50005-2)
- Rossi, F.; van Beek, P.; Walsh, T. (2006). "Handbook of Constraint Programming". *Elsevier*. ISBN: 978-0444527264. DOI: [`10.1016/S1574-6526(06)80007-4`](https://doi.org/10.1016/S1574-6526(06)80007-4)

**MiniZinc Constraint Programming Language:**

- Nethercote, N.; Stuckey, P.J.; Becket, R.; Brand, S.; Duck, G.J.; Tack, G. (2007). "MiniZinc: Towards a Standard CP Modelling Language". *Proceedings of the 13th International Conference on Principles and Practice of Constraint Programming*, 529-543. DOI: [`10.1007/978-3-540-74970-7_38`](https://doi.org/10.1007/978-3-540-74970-7_38)
- Stuckey, P.J.; Feydy, T.; Schutt, A.; Tack, G.; Wallace, M. (2014). "The MiniZinc Challenge 2008-2013". *AI Magazine*, 35(2):55-60. DOI: [`10.1609/aimag.v35i2.2539`](https://doi.org/10.1609/aimag.v35i2.2539)

**Google OR-Tools and CP-SAT:**

- Perron, L.; Furnon, V. (2019). "OR-Tools". Available: [`https://developers.google.com/optimization`](https://developers.google.com/optimization)
- Perron, L.; Didier, F. (2020). "CP-SAT, a constraint programming solver that scales". *Proceedings of the 26th International Conference on Principles and Practice of Constraint Programming*. DOI: [`10.1007/978-3-030-58475-7_25`](https://doi.org/10.1007/978-3-030-58475-7_25)

### Temporal Reasoning and Algorithms

**Simple Temporal Networks:**

- Dechter, R.; Meiri, I.; Pearl, J. (1991). "Temporal constraint networks". *Artificial Intelligence*, 49(1-3):61-95. DOI: [`10.1016/0004-3702(91)90006-6`](https://doi.org/10.1016/0004-3702(91)90006-6)

**Path Consistency Algorithms:**

- Mackworth, A.K. (1977). "Consistency in networks of relations". *Artificial Intelligence*, 8(1):99-118. DOI: [`10.1016/0004-3702(77)90007-8`](https://doi.org/10.1016/0004-3702(77)90007-8)
- Mohr, R.; Henderson, T.C. (1986). "Arc and path consistency revisited". *Artificial Intelligence*, 28(2):225-233. DOI: [`10.1016/0004-3702(86)90083-4`](https://doi.org/10.1016/0004-3702(86)90083-4)

**Floyd-Warshall Algorithm:**

- Floyd, R.W. (1962). "Algorithm 97: Shortest path". *Communications of the ACM*, 5(6):345. DOI: [`10.1145/367766.368168`](https://doi.org/10.1145/367766.368168)
- Warshall, S. (1962). "A theorem on boolean matrices". *Journal of the ACM*, 9(1):11-12. DOI: [`10.1145/321105.321107`](https://doi.org/10.1145/321105.321107)

**Allen's Interval Algebra:**

- Allen, J.F. (1983). "Maintaining knowledge about temporal intervals". *Communications of the ACM*, 26(11):832-843. DOI: [`10.1145/182.358434`](https://doi.org/10.1145/182.358434)
- Allen, J.F.; Hayes, P.J. (1985). "A common-sense theory of time". *Proceedings of the 9th International Joint Conference on Artificial Intelligence*, 528-531. Available: [`https://www.ijcai.org/Proceedings/85-1/Papers/070.pdf`](https://www.ijcai.org/Proceedings/85-1/Papers/070.pdf)

### Project Management and Scheduling

**PERT and Critical Path Method:**

- Malcolm, D.G.; Roseboom, J.H.; Clark, C.E.; Fazar, W. (1959). "Application of a technique for research and development program evaluation". *Operations Research*, 7(5):646-669. DOI: [`10.1287/opre.7.5.646`](https://doi.org/10.1287/opre.7.5.646)
- Kelley Jr, J.E.; Walker, M.R. (1959). "Critical-path planning and scheduling". *Proceedings of the Eastern Joint Computer Conference*, 160-173. DOI: [`10.1145/1460299.1460318`](https://doi.org/10.1145/1460299.1460318)

### Web Technologies and Real-Time Systems

**Real-Time Web Applications:**

- Fette, I.; Melnikov, A. (2011). "The WebSocket Protocol". *RFC 6455*. DOI: [`10.17487/RFC6455`](https://doi.org/10.17487/RFC6455)
- McCann, S.; Kamp, J. (2019). "Phoenix LiveView: Interactive, Real-Time Apps. No Need to Write JavaScript". *Pragmatic Bookshelf*. ISBN: 978-1680508215

**3D Graphics on the Web:**

- Parisi, T. (2012). "WebGL: Up and Running". *O'Reilly Media*. ISBN: 978-1449323578
- Dirksen, J. (2018). "Learn Three.js: Programming 3D animations and visualizations for the web with HTML5 and WebGL". *Packt Publishing*. ISBN: 978-1788833288

### Standards and Protocols

**Date and Time Standards:**

- International Organization for Standardization (2019). "ISO 8601-1:2019 Date and time — Representations for information interchange — Part 1: Basic rules". ISO Standard. Available: [`https://www.iso.org/standard/70907.html`](https://www.iso.org/standard/70907.html)

**3D Graphics Standards:**

- Khronos Group (2021). "glTF 2.0 Specification". Available: [`https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html`](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)
- Khronos Group (2023). "KHR_interactivity Extension Specification". Available: [`https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_interactivity`](https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_interactivity)

**Semantic Web Technologies:**

- Berners-Lee, T.; Hendler, J.; Lassila, O. (2001). "The Semantic Web". *Scientific American*, 284(5):34-43. DOI: [`10.1038/scientificamerican0501-34`](https://doi.org/10.1038/scientificamerican0501-34)
- Sporny, M.; Longley, D.; Kellogg, G.; Lanthaler, M.; Lindström, N. (2020). "JSON-LD 1.1: A JSON-based Serialization for Linked Data". *W3C Recommendation*. Available: [`https://www.w3.org/TR/json-ld11/`](https://www.w3.org/TR/json-ld11/)

**Model Context Protocol:**

- Anthropic (2024). "Model Context Protocol Specification". Available: [`https://spec.modelcontextprotocol.io/`](https://spec.modelcontextprotocol.io/)

### Stream Processing and Concurrency

**Stream Processing Architectures:**

- Akidau, T.; Bradshaw, R.; Chambers, C.; Chernyak, S.; Fernández-Moctezuma, R.J.; Lax, R.; McVeety, S.; Mills, D.; Perry, F.; Schmidt, E.; Whittle, S. (2015). "The Dataflow Model: A Practical Approach to Balancing Correctness, Latency, and Cost in Massive-Scale, Unbounded, Out-of-Order Data Processing". *Proceedings of the VLDB Endowment*, 8(12):1792-1803. DOI: [`10.14778/2824032.2824076`](https://doi.org/10.14778/2824032.2824076)

**GenStage and Flow Patterns:**

- Valim, J. (2016). "GenStage and Flow". *ElixirConf 2016*. Available: [`https://www.youtube.com/watch?v=XPlXNUXmcgE`](https://www.youtube.com/watch?v=XPlXNUXmcgE)
- Juric, S. (2019). "Elixir in Action, Second Edition". *Manning Publications*. ISBN: 978-1617295027

**Background Job Processing:**

- Sidekiq Contributors (2024). "Sidekiq: Simple, efficient background processing for Ruby". Available: [`https://sidekiq.org/`](https://sidekiq.org/)
- Oban Contributors (2024). "Oban: Robust job processing in Elixir, backed by modern PostgreSQL". Available: [`https://getoban.pro/`](https://getoban.pro/)

### Comparison with Established Standards

| Feature | PDDL 2.1 | PDDL+ | ADR-181 Specification |
|---------|----------|-------|----------------------|
| **Durative Actions** | ✅ Basic support | ✅ Enhanced | ✅ Unified entity-based |
| **Temporal Constraints** | ✅ at_start/at_end | ✅ Continuous | ✅ 9-pattern system |
| **Resource Management** | ❌ Limited | ❌ Numeric only | ✅ Entity capabilities |
| **Hierarchical Decomposition** | ❌ No | ❌ No | ✅ Method-based |
| **Multi-agent Support** | ❌ No | ❌ No | ✅ Entity allocation |
| **Goal Format** | Mixed | Mixed | ✅ Standardized {predicate, subject, value} |

### Research Context

This specification addresses several open problems in automated planning and scheduling:

**Temporal Planning:** Extends classical STRIPS planning with temporal reasoning capabilities, supporting both fixed intervals and floating durations as described in temporal constraint satisfaction literature.

**Resource Allocation:** Implements entity-based resource management through capability matching, addressing the resource allocation problem in multi-agent planning systems.

**Hierarchical Task Networks:** Integrates HTN-style method decomposition with durative action planning, bridging the gap between hierarchical planning and temporal scheduling.

**Constraint Satisfaction:** The 9-pattern temporal specification system provides a complete framework for temporal constraint satisfaction in planning domains.

### Implementation Standards

**International Planning Competition:** The specification draws from standards established through the International Planning Competition series. Competition resources: [`http://www.icaps-conference.org/`](http://www.icaps-conference.org/)

**Planning Domain Modeling:** Follows established conventions for domain-independent planning while extending expressiveness for modern applications requiring temporal reasoning and resource management.

### Keywords and Research Areas

This specification contributes to research in: automated planning and scheduling, temporal planning, durative actions, hierarchical task networks, resource allocation, constraint satisfaction, multi-agent planning, planning domain definition languages, temporal constraint networks, scheduling optimization, and intelligent agent coordination.

### Future Research Directions

The unified specification enables research into:

- **Temporal Optimization:** Advanced scheduling algorithms for durative action sequences
- **Resource Contention:** Sophisticated entity allocation strategies for multi-agent environments  
- **Hybrid Planning:** Integration of symbolic planning with continuous control systems
- **Distributed Planning:** Coordination protocols for multi-agent temporal planning
- **Learning-Enhanced Planning:** Machine learning integration for capability discovery and optimization

### Standards Compliance

This specification maintains compatibility with established planning frameworks while extending capabilities for modern applications. Implementation follows best practices from the automated planning community and provides clear migration paths from existing PDDL-based systems.

For researchers and practitioners working with temporal planning, durative actions, resource scheduling, or multi-agent coordination, this specification provides a comprehensive foundation that builds upon decades of research in automated planning and scheduling.
