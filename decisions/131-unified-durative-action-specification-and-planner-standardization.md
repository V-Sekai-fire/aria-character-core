# ADR-131: Unified Durative Action Specification and Planner Standardization

**Status:** Completed  
**Date:** 2025-06-22  
**Completion Date:** 2025-06-22  
**Priority:** HIGH

## Context

The AriaEngine planner has evolved multiple confusing and inconsistent patterns that make it difficult to use effectively. Users struggle with unclear APIs, multiple ways to accomplish the same tasks, and inconsistent data formats across the system.

### Current Confusing Patterns

**1. Multiple Duration Formats:**
- ISO 8601 duration strings: `"PT8H"` (floating effort)
- **MISSING**: ISO 8601 datetime strings: `"2025-06-22T10:00:00Z"` (fixed scheduling)
- Complex Interval structs with various constructors

**2. Multiple Entity/Capability/Resource Patterns:**
```elixir
# TimelineGraph pattern
TimelineGraph.create_entity(graph, "guard", "Tower Guard", %{})
TimelineGraph.add_capabilities(graph, "guard", [:patrol])

# AgentEntity pattern  
AgentEntity.create_agent("chef", "Head Chef", %{}, capabilities: [:cooking])

# Timeline + Interval pattern
agent = AgentEntity.create_agent("aria", "Aria", %{})
interval = Interval.new(start, end, agent: agent)
```

**3. Inconsistent Goal Formats:**
- **DEPRECATED**: `{predicate, subject, value}` ❌ TOMBSTONE THIS
- **CORRECT**: `{subject, predicate, value}` ✅ ONLY USE THIS

**4. Multiple State Validation Approaches:**
- `validate_temporal_condition/2` ❌ REMOVE
- `StateV2.evaluate_condition/2` ❌ REMOVE  
- **ONLY USE**: `StateV2.get_fact/3` ✅ DIRECT FACT CHECKING (supports temporal queries)

**5. Multiple Planning APIs:**
- `Plan.plan/4` (legacy)
- `PlannerAdapter.plan/4` (migration wrapper)
- `HybridCoordinatorV2.plan/4` (new system)
- `PlannerAdapter.plan_tasks/4` (direct HTN)

**6. Inconsistent Action Definition:**
```elixir
# Pattern 1: Simple function
Domain.add_action(:move, &move/2)

# Pattern 2: Function with metadata
Domain.add_action(:cook, &cook/2, %{duration: "PT2H"})

# Pattern 3: DurativeAction struct
Domain.add_action(:build, %DurativeAction{...})

# Pattern 4: Module-based
Domain.from_module(SomeModule)
```

### Target State

**FINAL: Unified entity+capabilities model with tombstoned concepts**

## ❌ TOMBSTONED CONCEPTS (DO NOT IMPLEMENT)

The following concepts were considered but explicitly rejected during design:

1. **❌ TOMBSTONE: `quantity` field in action metadata** - Quantities are state fluents, not action metadata
2. **❌ TOMBSTONE: Separate `resources` map with `consumables`, `tools`, `locations`** - Everything is entities with capabilities
3. **❌ TOMBSTONE: `properties` field in entity requirements** - Use capabilities instead
4. **❌ TOMBSTONE: Separate `requires_agent` field** - Agents are entities with capabilities
5. **❌ TOMBSTONE: `location` field in action metadata** - Locations are entities in `requires_entities`

## ✅ FINAL CLEAN MODEL

```elixir
# FINAL: Unified entity-based metadata structure
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
  
  # Static documentation (like database column comment)
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

**Key insight: Everything is an entity with capabilities that define behavior:**
- **Agents**: `%{type: "chef", capabilities: [:cooking, :menu_planning]}`
- **Tools**: `%{type: "oven", capabilities: [:heating, :baking]}`
- **Locations**: `%{type: "kitchen", capabilities: [:workspace]}`
- **Consumables**: `%{type: "flour", capabilities: [:consumable]}`

## Capabilities as Traits (Composition over Inheritance)

**Capabilities serve as traits** in this model, providing flexible composition without inheritance hierarchies. This avoids is-a relationships and parent-child type complexity.

**Capabilities as Simple Traits Only (Properties Belong in State)**

Capabilities are simple atoms that represent what an entity can do or what category it belongs to. All dynamic properties, constraints, and state information belong in StateV2, not in action metadata.

```elixir
@type capability :: atom()  # Simple trait only: :agent, :heating, :cutting, :consumable
```

**Capability categories:**
- **Categorical traits**: `:agent`, `:consumable`, `:tool`, `:appliance`
- **Behavioral capabilities**: `:heating`, `:cutting`, `:cooking`, `:baking`
- **Functional traits**: `:reusable`, `:portable`, `:stackable`, `:container`
- **Domain-specific**: `:kitchen_equipment`, `:ingredient`, `:meeting_space`

**Examples of capability composition (properties in state):**
```elixir
# Kitchen appliance with simple capability traits
%{type: "oven", capabilities: [
  :appliance,                                    # Categorical trait
  :kitchen_equipment,                            # Domain classification
  :heating,                                      # Behavioral capability
  :baking                                        # Behavioral capability
]}

# Properties stored in state, not action metadata
# StateV2.set_fact(state, "oven_1", "max_temp", 450)
# StateV2.set_fact(state, "oven_1", "min_temp", 150)
# StateV2.set_fact(state, "oven_1", "precision", "±5°F")

# Agent with simple capability traits
%{type: "chef", capabilities: [
  :agent,                                        # Categorical trait
  :human,                                        # Type classification
  :cooking,                                      # Behavioral capability
  :knife_skills                                  # Behavioral capability
]}

# Agent properties stored in state
# StateV2.set_fact(state, "chef_1", "experience_level", "expert")
# StateV2.set_fact(state, "chef_1", "specialties", ["french", "italian"])
# StateV2.set_fact(state, "chef_1", "certifications", ["food_safety"])

# Simple consumable with basic traits
%{type: "flour", capabilities: [
  :consumable,                                   # Categorical trait
  :ingredient,                                   # Domain classification
  :pantry_item,                                  # Storage classification
  :bakeable                                      # Usage capability
]}

# Consumable quantities in state
# StateV2.set_fact(state, "flour", "quantity", 5)
# StateV2.set_fact(state, "flour", "unit", "cups")

# Tool with simple capability traits
%{type: "knife", capabilities: [
  :tool,                                         # Categorical trait
  :kitchen_equipment,                            # Domain classification
  :cutting,                                      # Behavioral capability
  :slicing,                                      # Behavioral capability
  :reusable                                      # Functional trait
]}

# Tool state tracked separately
# StateV2.set_fact(state, "knife_1", "sharpness", 85)
# StateV2.set_fact(state, "knife_1", "blade_material", "carbon_steel")
# StateV2.set_fact(state, "knife_1", "maintenance_due", "2025-07-01")
```

**Query flexibility with simple capabilities:**
```elixir
# Simple capability queries (atoms only)
entities_with_capability(:consumable)
entities_with_capability(:reusable)
entities_with_capability(:agent)
entities_with_capability(:heating)
entities_with_capability(:cutting)

# Multiple capability queries
entities_with_capabilities([:kitchen_equipment, :heating])
entities_with_capabilities([:agent, :cooking])
entities_with_capabilities([:tool, :cutting, :reusable])

# Property constraints handled through state queries
entities_with_capability(:heating)
|> Enum.filter(fn entity_id ->
  StateV2.get_fact(state, entity_id, "max_temp") >= 400
end)

# Complex entity matching with state-based property filtering
find_entities_matching([
  :tool,                                    # Must be a tool
  :kitchen_equipment,                       # Must be kitchen equipment
  :cutting                                  # Must have cutting capability
])
|> Enum.filter(fn entity_id ->
  sharpness = StateV2.get_fact(state, entity_id, "sharpness")
  maintenance_due = StateV2.get_fact(state, entity_id, "maintenance_due")
  
  sharpness >= 75 and 
  Date.compare(maintenance_due, Date.utc_today()) == :gt
end)

# Find all entities with specific capabilities
entities_with_capability(:heating)         # All heating-capable entities
entities_with_capability(:cooking)         # All cooking-capable entities
entities_with_capability(:consumable)      # All consumable entities
```

**Benefits of capabilities-as-traits:**
- **No inheritance complexity**: Avoids is-a relationships and parent-child hierarchies
- **Flexible composition**: Mix and match any combination of traits and behaviors
- **Flat namespace**: Easy to understand and query without nested type systems
- **Extensible**: Add new traits without breaking existing entities
- **Query-friendly**: Find entities by any trait combination
- **Domain-agnostic**: Works for any entity type without predefined hierarchies

**Quantities are state, not metadata:**
```elixir
# Action implementation handles quantities through state
def cook_meal(state, [meal_type]) do
  flour_available = StateV2.get_fact(state, "flour", "quantity")
  eggs_available = StateV2.get_fact(state, "eggs", "quantity")
  
  if flour_available >= 2 and eggs_available >= 6 do
    state
    |> StateV2.set_fact("flour", "quantity", flour_available - 2)
    |> StateV2.set_fact("eggs", "quantity", eggs_available - 6)
    |> StateV2.set_fact("meal", "status", "cooked")
  else
    {:error, :insufficient_ingredients}
  end
end
```

## Phase 1: Core Duration Support - BOTH Fixed and Floating Schedules

**CURRENT STATE:**
- ✅ **Floating Duration Support**: `duration: "PT2H"` (ISO 8601 duration strings) - ALREADY WORKS
- ❌ **Fixed Schedule Support**: `start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"` (ISO 8601 datetime strings) - MISSING

**REQUIRED IMPLEMENTATION:**
Must support BOTH scheduling patterns with unified validation:

```elixir
# Pattern 1: Floating Duration (effort-based scheduling) - EXISTING ✅
Domain.add_action(:cook_meal, &cook_meal/2, %{
  duration: "PT2H",  # ISO 8601 duration string - ALREADY SUPPORTED
  requires_entities: [
    %{type: "agent", capabilities: [:cooking, :menu_planning]},
    %{type: "oven"}
  ],
  resources: %{ingredients: ["flour", "eggs"], tools: ["mixing_bowl"]}
})

# Pattern 2: Fixed Schedule (time-based scheduling) - NEW ❌
Domain.add_action(:meeting, &meeting/2, %{
  start: "2025-06-22T10:00:00Z",  # ISO 8601 datetime string - NEEDS IMPLEMENTATION
  end: "2025-06-22T11:00:00Z",    # ISO 8601 datetime string - NEEDS IMPLEMENTATION
  requires_entities: [
    %{type: "agent", capabilities: [:communication]}
  ],
  location: "conference_room_1"
})
```

**VALIDATION RULES:**
- ✅ `duration` only (floating effort)
- ✅ `start` AND `end` (fixed closed interval)
- ✅ `start` only (open-ended interval - starts at time, no end constraint)
- ✅ `end` only (open-ended interval - must finish by time, no start constraint)
- ❌ Cannot mix `duration` with `start`/`end`
- ❌ Must have at least one temporal specification (`duration` OR `start` OR `end`)

**TIMEX INTEGRATION REQUIREMENT:**
All temporal validation and parsing MUST use Timex instead of Elixir's base DateTime functionality for enhanced ISO 8601 support, better timezone handling, and more robust duration parsing.

### Timex Implementation Details

**Required Timex Functions:**
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

**Validation Function Updates:**
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

**Benefits of Timex Integration:**
- **Enhanced ISO 8601 support**: More robust parsing with better error messages
- **Timezone handling**: Proper timezone conversion and management
- **Duration arithmetic**: Better duration parsing and manipulation
- **Scheduling integration**: Better compatibility with scheduling systems
- **Error reporting**: More descriptive error messages for invalid formats

**Standardized formats:**
- **Goals**: ONLY `{subject, predicate, value}` format
- **State validation**: ONLY `StateV2.get_fact/3` direct fact checking (supports temporal queries)
- **Entity management**: ONLY through Domain actions API
- **Planning API**: Clear guidance on which API to use when
- **Temporal parsing**: ONLY Timex for all datetime and duration operations

## Decision

Create a unified durative action specification system that eliminates confusion by providing ONE clear way to define actions with entities, capabilities, resources, and temporal constraints.

## Test-Driven Implementation Strategy

Following Martin Fowler's TDD methodology, we implement the unified durative action specification through **Red-Green-Refactor** cycles, writing tests first to drive the design.

### TDD Process Overview

1. **Write comprehensive test list first** - Identify all test cases before any implementation
2. **Sequence tests by design impact** - Pick tests that drive us to key design decisions
3. **Red-Green-Refactor iterations** - For each test: write failing test → make it pass → refactor
4. **Interface-first thinking** - Tests force us to design the API before implementation

### Complete Test Case Inventory

**Infrastructure Tests (Foundation)**
- [ ] Action atom registration without aliasing conflicts
- [ ] Task method registration with `task_` prefix
- [ ] Action vs task method resolution priority
- [ ] Automatic primitive method creation
- [ ] Domain creation and action registration

**Metadata Validation Framework Tests**
- [ ] Basic metadata structure validation
- [ ] Type specification enforcement
- [ ] Error message clarity and specificity
- [ ] Validation integration with `Domain.add_action/3`
- [ ] Invalid metadata rejection

**Temporal Specification Tests**
- [ ] ISO 8601 duration string validation (`"PT2H"`)
- [ ] ISO 8601 datetime string validation (`"2025-06-22T10:00:00Z"`)
- [ ] Fixed closed interval validation (start + end)
- [ ] Open-ended interval validation (start only, end only)
- [ ] Temporal specification mutual exclusion (duration XOR start/end)
- [ ] Missing temporal specification rejection
- [ ] Invalid temporal format rejection

**Entity Requirement Tests**
- [ ] Simple capability validation (atoms only)
- [ ] Entity type requirement validation
- [ ] Multiple entity requirement validation
- [ ] Invalid entity requirement rejection
- [ ] Entity requirement integration with state queries

**State Integration Tests**
- [ ] Property queries through StateV2.get_fact/3
- [ ] Temporal state queries (past/future checking)
- [ ] Capability-based entity filtering
- [ ] State-based property constraints
- [ ] Dynamic property management

**End-to-End Integration Tests**
- [ ] Complete action definition with all metadata types
- [ ] Planning integration with unified specification
- [ ] Goal achievement with entity requirements
- [ ] Resource allocation during planning
- [ ] Temporal constraint satisfaction

### Test-First Implementation Sequence

**Iteration 1: Infrastructure Foundation (Action Atom Priority Rule)**
```elixir
# RED: Write failing test
test "action atoms resolve with higher priority than task methods" do
  domain = Domain.new()
  |> Domain.add_action(:move, &move_action/2)
  |> Domain.add_task_method("task_move", &move_task/2)
  
  # Action atom should resolve first
  assert {:action, _} = Domain.resolve(:move, domain)
  assert {:task_method, _} = Domain.resolve("task_move", domain)
end

# GREEN: Implement minimal resolution logic
# REFACTOR: Clean up implementation
```

**Iteration 2: Metadata Validation Framework**
```elixir
# RED: Write failing test
test "validates action metadata structure and types" do
  metadata = %{
    duration: "PT2H",
    requires_entities: [%{type: "oven", capabilities: [:heating]}]
  }
  
  assert {:ok, _} = validate_action_metadata(metadata)
  assert {:error, _} = validate_action_metadata(%{invalid: "data"})
end

# GREEN: Implement validation framework
# REFACTOR: Extract validation functions
```

**Iteration 3: Temporal Specification Support**
```elixir
# RED: Write failing test
test "supports all temporal specification patterns" do
  # Duration only
  assert {:ok, _} = validate_temporal(%{duration: "PT2H"})
  
  # Fixed interval
  assert {:ok, _} = validate_temporal(%{
    start: "2025-06-22T10:00:00Z",
    end: "2025-06-22T11:00:00Z"
  })
  
  # Open-ended intervals
  assert {:ok, _} = validate_temporal(%{start: "2025-06-22T10:00:00Z"})
  assert {:ok, _} = validate_temporal(%{end: "2025-06-22T11:00:00Z"})
  
  # Invalid combinations
  assert {:error, _} = validate_temporal(%{duration: "PT2H", start: "2025-06-22T10:00:00Z"})
end

# GREEN: Implement temporal validation
# REFACTOR: Extract ISO 8601 parsing
```

**Iteration 4: Entity Requirements**
```elixir
# RED: Write failing test
test "validates entity requirements with capabilities" do
  entities = [
    %{type: "agent", capabilities: [:cooking]},
    %{type: "oven", capabilities: [:heating, :baking]}
  ]
  
  assert {:ok, _} = validate_entity_requirements(entities)
  assert {:error, _} = validate_entity_requirements([%{invalid: "entity"}])
end

# GREEN: Implement entity validation
# REFACTOR: Extract capability validation
```

**Iteration 5: State Integration**
```elixir
# RED: Write failing test
test "integrates with StateV2 for property queries" do
  state = StateV2.new()
  |> StateV2.set_fact("oven_1", "max_temp", 450)
  
  entities = find_entities_with_capability(state, :heating)
  |> filter_by_property(state, "max_temp", {:>=, 400})
  
  assert "oven_1" in entities
end

# GREEN: Implement state integration
# REFACTOR: Extract query helpers
```

**Iteration 6: End-to-End Integration**
```elixir
# RED: Write failing test
test "complete unified action specification works end-to-end" do
  domain = Domain.new()
  |> Domain.add_action(:cook_meal, &cook_meal/2, %{
    duration: "PT2H",
    requires_entities: [
      %{type: "agent", capabilities: [:cooking]},
      %{type: "oven", capabilities: [:heating]}
    ]
  })
  
  # Should integrate with planning system
  {:ok, plan} = plan_with_unified_specification(domain, state, goals)
  assert plan.actions |> Enum.any?(&(&1.name == :cook_meal))
end

# GREEN: Implement end-to-end integration
# REFACTOR: Clean up integration points
```

### Red-Green-Refactor Guidelines

**Red Phase (Write Failing Test)**
- Focus on interface design - how should the API work?
- Write the test you wish you could call
- Make it fail for the right reason (missing implementation, not syntax error)

**Green Phase (Make Test Pass)**
- Write minimal code to make the test pass
- Don't worry about perfect design yet
- Get to green as quickly as possible

**Refactor Phase (Clean Up)**
- Improve both test and implementation code
- Extract common patterns
- Ensure code is well-structured and maintainable
- All tests must still pass after refactoring

### Current Focus: Iteration 1 - Infrastructure Foundation

**Next Test to Implement**: Action atom priority rule test to establish foundational infrastructure before building validation framework.

**Rationale**: Following TDD principles, we start with the test that drives the most fundamental design decision - how actions and task methods are resolved. This infrastructure must work correctly before we can build the metadata validation and temporal specification features on top of it.

## Success Criteria

- [ ] Both floating durations and fixed intervals supported via ISO 8601 strings
- [ ] Unified action specification with entities, capabilities, and resources
- [ ] All goals use `{subject, predicate, value}` format consistently
- [ ] All state validation uses direct `StateV2.get_fact/3` calls (with temporal query support)
- [ ] Clear documentation on which planning API to use when
- [ ] Single standardized way to define actions
- [ ] All existing functionality preserved during migration
- [ ] Comprehensive test coverage for new unified API

## Consequences

**Benefits:**
- Eliminates confusion by providing ONE way to do each task
- Unified API for durative actions with full resource specification
- Consistent data formats across the entire system
- Clear migration path from legacy patterns
- Simplified state validation and goal handling
- Better integration between Domain actions and Timeline execution

**Risks:**
- Large scope requires careful migration to avoid breaking changes
- Multiple files need coordinated updates
- Existing code using deprecated patterns needs migration
- Comprehensive testing required to ensure compatibility

**Migration Strategy:**
- Maintain backward compatibility during transition
- Add deprecation warnings for old patterns
- Provide clear migration examples
- Update documentation with new standardized patterns

## Open Problems

The following additional issues were identified during analysis but are not yet addressed in the current implementation plan:

### 1. Method Registration Inconsistencies (MEDIUM PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: Multiple function arities with unclear usage patterns
- `add_task_method/3` vs `add_task_method/4` - when to use which arity?
- `add_unigoal_method/3` vs `add_unigoal_method/4` - same inconsistency
- Manual vs automatic primitive method registration confusion

**Solution**: Single Unified Method with Options Map
```elixir
# Replace all variants with single unified method
Domain.add_method(domain, name, function, opts \\ %{})

# Usage examples:
Domain.add_method(domain, "move", &move/2)  # Simple case (defaults to :task)
Domain.add_method(domain, "move", &move/2, %{type: :task})  # Explicit task method
Domain.add_method(domain, "move", &move/2, %{type: :unigoal, priority: 1})  # Unigoal with priority
Domain.add_method(domain, "move", &move/2, %{type: :multigoal, constraints: [...]})  # Multigoal

# Deprecation with helpful migration messages
def add_task_method(domain, name, function, opts \\ %{}) do
  IO.warn("add_task_method/3-4 is deprecated, use add_method/4 with type: :task")
  add_method(domain, name, function, Map.put(opts, :type, :task))
end
```

**Benefits**:
- Single function to learn (no arity confusion)
- Self-documenting options make intent clear
- Extensible without breaking changes
- Consistent pattern everywhere

**Impact**: Eliminates developer confusion about which method registration approach to use

### 2. Multigoal vs Unigoal Confusion (MEDIUM PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: Unclear distinction and integration patterns
- When to use multigoal methods vs unigoal methods
- How multigoal optimization integrates with unified action specification
- Unclear relationship between `AriaEngine.Multigoal` and domain methods

**Solution**: Clear Hierarchical Decomposition Pattern
```elixir
# Unigoal methods: Decompose single goal into todo list
# Input: {"subject", "predicate", "object"} 
# Output: [{task_name, args}, {task_name, args}, ...]
Domain.add_method(domain, "achieve_location", &achieve_location/2, %{
  type: :unigoal,
  goal_pattern: {"player", "location", :any}
})

def achieve_location(state, {"player", "location", target_room}) do
  [
    {"task_move", [target_room]},
    {"task_verify_location", [target_room]}
  ]
end

# Multigoal methods: Decompose goal list into unigoal methods (not todos)
# Input: [{"subject", "predicate", "object"}, {"subject", "predicate", "object"}]
# Output: [unigoal_method_name, unigoal_method_name, ...]
Domain.add_method(domain, "optimize_multiple_locations", &optimize_locations/2, %{
  type: :multigoal,
  goal_patterns: [{"player", "location", :any}, {"npc", "location", :any}]
})

def optimize_locations(state, goals) do
  [
    "achieve_location",  # Unigoal method for player
    "achieve_location"   # Unigoal method for NPC
  ]
end
```

**Clear Hierarchy**:
1. **Multigoal methods** → constraint-based strategic optimizers for `%AriaEngine.Multigoal{}` (special case)
2. **Unigoal methods** → decompose single goal into task todos (can backtrack)
3. **Task methods** → decompose tasks into more todos (can backtrack)
4. **Actions** → change state directly (can backtrack)

**Benefits**:
- Clear separation of concerns at each level
- Multigoal methods use constraint satisfaction (MiniZinc) to optimize goal achievement
- Unigoal methods focus on single goal decomposition strategies
- Task methods handle task decomposition into subtasks
- Actions are the only components that directly modify state
- All levels support backtracking by returning `false`

**Impact**: Eliminates confusion about decomposition levels and enables proper goal optimization

### 3. Domain Module Creation Patterns (LOW PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: Multiple domain creation approaches without clear guidance
- `Domain.new()` vs `Domain.from_module()` - different creation patterns
- Module-based domain definition vs programmatic building
- Inconsistent patterns for domain initialization

**Solution**: Module-First Pattern with Elixir Conventions
```elixir
# RECOMMENDED: Module-based domain definition (follows Elixir conventions)
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  # Domain metadata
  @domain_name "cooking"
  @description "Cooking and meal preparation domain"
  
  # Actions defined as module functions with metadata
  @action duration: "PT2H", requires_agent: %{capabilities: [:cooking]}
  def cook_meal(state, [meal_type, ingredients]) do
    # Action implementation
    StateV2.set_fact(state, "meal", "status", "cooking")
  end
  
  @action start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"
  def scheduled_meeting(state, [participants]) do
    # Fixed time action implementation
    StateV2.set_fact(state, "meeting", "status", "in_progress")
  end
  
  # Methods defined as module functions
  @unigoal_method goal_pattern: {"chef", "task", :any}
  def achieve_cooking_task(state, {"chef", "task", task_name}) do
    [
      {"task_prepare_ingredients", [task_name]},
      {"task_cook", [task_name]},
      {"task_serve", [task_name]}
    ]
  end
  
  @task_method
  def task_prepare_ingredients(state, [task_name]) do
    [
      {:gather_ingredients, [task_name]},
      {:wash_ingredients, [task_name]}
    ]
  end
end

# Usage: Automatic domain creation from module
domain = MyApp.Domains.CookingDomain.create_domain()

# Alternative: Explicit creation with options
domain = MyApp.Domains.CookingDomain.create_domain(%{
  validation: :strict,
  optimization: :enabled
})
```

**Benefits of Module-First Pattern**:
- **Follows Elixir conventions**: Uses modules, attributes, and pattern matching
- **Compile-time validation**: Metadata and function signatures checked at compile time
- **Clear organization**: All domain logic in one module
- **Documentation integration**: Works with ExDoc and `@doc` attributes
- **Hot code reloading**: Supports development workflow
- **Testable**: Easy to test individual actions and methods

**Fallback for Dynamic Domains**:
```elixir
# For runtime-generated domains (rare cases)
domain = Domain.new("dynamic_domain")
|> Domain.add_action(:runtime_action, &runtime_action/2, %{duration: "PT1H"})
|> Domain.add_method("runtime_method", &runtime_method/2, %{type: :task})
```

**Migration Strategy**:
- **New domains**: Always use module-based approach
- **Existing domains**: Migrate to modules during refactoring
- **Dynamic domains**: Keep programmatic approach for runtime generation only

**Impact**: Provides clear, Elixir-idiomatic domain creation that leverages compile-time checks and follows established patterns

### 4. Error Handling Standardization (MEDIUM PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: Inconsistent error return formats across the planner
- Some functions return `false`, others `{:error, reason}`, others raise exceptions
- No consistent error handling pattern across the planner
- Missing error recovery strategies

**Solution**: Standard Elixir Tagged Tuples with Descriptive Backtracking
```elixir
# Backtracker logic: Simple binary success/failure
case method_result do
  {:ok, todos} -> continue_with(todos)    # ✅ Success - continue
  _anything_else -> backtrack()           # ❌ Failure - try next method
end

# Method implementation: Descriptive errors for debugging
def task_method(state, args) do
  cond do
    not valid_preconditions?(state, args) ->
      {:error, :preconditions_failed}
    
    not enough_resources?(state, args) ->
      {:error, :insufficient_resources}
    
    true ->
      {:ok, [{:action, args}]}
  end
end

# Action implementation: Clear success/failure
def move_action(state, [target]) do
  cond do
    not reachable?(state, target) ->
      {:error, :unreachable_location}
    
    blocked_path?(state, target) ->
      {:error, :path_blocked}
    
    true ->
      new_state = StateV2.set_fact(state, "player", "location", target)
      {:ok, new_state}
  end
end
```

**Benefits**:
- **Standard Elixir patterns**: Follows `{:ok, result}` / `{:error, reason}` ecosystem conventions
- **Simple backtracker logic**: Just check for `{:ok, result}` - anything else triggers backtracking
- **Rich error information**: Descriptive error atoms help with debugging
- **Composable**: Works with standard `with` statements and error handling
- **Clear semantics**: Success and failure reasons are explicit

**Migration Strategy**:
```elixir
# Replace all `false` returns with `{:error, reason}`
# Replace all bare results with `{:ok, result}`

# Before
def old_method(state, args) do
  if condition do
    result
  else
    false
  end
end

# After  
def new_method(state, args) do
  if condition do
    {:ok, result}
  else
    {:error, :condition_failed}
  end
end
```

**Impact**: Eliminates weird `false` returns while providing both clean backtracking logic AND descriptive error information for debugging

### 5. Metadata Validation Issues (HIGH PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: No validation for the new unified metadata format
- No clear validation rules for unified metadata format
- Missing type specifications for metadata structure
- No runtime validation of action requirements (agents, entities, resources)

**Solution**: Comprehensive Metadata Validation with Type Specifications
```elixir
# Type specifications for metadata structure
@type action_metadata :: %{
  # Temporal specifications (mutually exclusive)
  optional(:duration) => String.t(),  # ISO 8601 duration: "PT2H"
  optional(:start) => String.t(),     # ISO 8601 datetime: "2025-06-22T10:00:00Z"
  optional(:end) => String.t(),       # ISO 8601 datetime: "2025-06-22T11:00:00Z"
  
  # Unified entity requirements (everything is an entity with capabilities)
  optional(:requires_entities) => [%{
    required(:type) => String.t(),
    optional(:capabilities) => [atom()]  # What this entity can do
  }],
  
  # Additional metadata
  optional(:description) => String.t()
}

# Validation function with clear error messages
def validate_action_metadata(metadata) when is_map(metadata) do
  with {:ok, _} <- validate_temporal_specification(metadata),
       {:ok, _} <- validate_agent_requirements(metadata),
       {:ok, _} <- validate_entity_requirements(metadata),
       {:ok, _} <- validate_resource_requirements(metadata) do
    {:ok, metadata}
  else
    {:error, reason} -> {:error, "Invalid action metadata: #{reason}"}
  end
end

# Temporal validation (supports open-ended intervals)
defp validate_temporal_specification(metadata) do
  temporal_keys = [:duration, :start, :end]
  present_keys = Enum.filter(temporal_keys, &Map.has_key?(metadata, &1))
  
  cond do
    # No temporal specification (invalid - must have at least one)
    Enum.empty?(present_keys) ->
      {:error, "must have at least one temporal specification: :duration OR :start OR :end"}
    
    # Duration only (floating effort)
    present_keys == [:duration] ->
      validate_iso8601_duration(metadata[:duration])
    
    # Start only (open-ended interval - starts at time, no end constraint)
    present_keys == [:start] ->
      validate_iso8601_datetime(metadata[:start])
    
    # End only (open-ended interval - must finish by time, no start constraint)
    present_keys == [:end] ->
      validate_iso8601_datetime(metadata[:end])
    
    # Start and end (fixed closed interval)
    Enum.sort(present_keys) == [:end, :start] ->
      with {:ok, start_dt} <- validate_iso8601_datetime(metadata[:start]),
           {:ok, end_dt} <- validate_iso8601_datetime(metadata[:end]) do
        if DateTime.compare(start_dt, end_dt) == :lt do
          {:ok, :fixed_closed_interval}
        else
          {:error, "start time must be before end time"}
        end
      end
    
    # Invalid combinations (duration cannot mix with start/end)
    true ->
      {:error, "invalid temporal specification - cannot mix :duration with :start/:end"}
  end
end

# Agent requirements validation
defp validate_agent_requirements(%{requires_agent: agent_req}) when is_map(agent_req) do
  with {:ok, _} <- validate_capabilities(agent_req[:capabilities]),
       {:ok, _} <- validate_properties(agent_req[:properties]) do
    {:ok, :valid_agent_requirements}
  end
end
defp validate_agent_requirements(_), do: {:ok, :no_agent_requirements}

# Entity requirements validation
defp validate_entity_requirements(%{requires_entities: entities}) when is_list(entities) do
  Enum.reduce_while(entities, {:ok, []}, fn entity, {:ok, acc} ->
    case validate_single_entity_requirement(entity) do
      {:ok, validated} -> {:cont, {:ok, [validated | acc]}}
      {:error, reason} -> {:halt, {:error, "entity requirement error: #{reason}"}}
    end
  end)
end
defp validate_entity_requirements(_), do: {:ok, :no_entity_requirements}

defp validate_single_entity_requirement(%{type: type} = entity) when is_binary(type) do
  if Map.has_key?(entity, :properties) and not is_map(entity[:properties]) do
    {:error, "entity properties must be a map"}
  else
    {:ok, entity}
  end
end
defp validate_single_entity_requirement(_) do
  {:error, "entity requirement must have :type field as string"}
end

# Resource requirements validation
defp validate_resource_requirements(%{resources: resources}) when is_map(resources) do
  valid_resource_types = [:consumables, :tools, :locations]
  
  Enum.reduce_while(resources, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
    cond do
      key not in valid_resource_types ->
        {:halt, {:error, "invalid resource type: #{key}"}}
      
      not is_list(value) or not Enum.all?(value, &is_binary/1) ->
        {:halt, {:error, "resource #{key} must be list of strings"}}
      
      true ->
        {:cont, {:ok, Map.put(acc, key, value)}}
    end
  end)
end
defp validate_resource_requirements(_), do: {:ok, :no_resource_requirements}

# ISO 8601 validation helpers
defp validate_iso8601_duration(duration) when is_binary(duration) do
  case Regex.match?(~r/^P(?:\d+Y)?(?:\d+M)?(?:\d+D)?(?:T(?:\d+H)?(?:\d+M)?(?:\d+S)?)?$/, duration) do
    true -> {:ok, duration}
    false -> {:error, "invalid ISO 8601 duration format: #{duration}"}
  end
end
defp validate_iso8601_duration(_), do: {:error, "duration must be string"}

defp validate_iso8601_datetime(datetime) when is_binary(datetime) do
  case DateTime.from_iso8601(datetime) do
    {:ok, dt, _offset} -> {:ok, dt}
    {:error, reason} -> {:error, "invalid ISO 8601 datetime: #{reason}"}
  end
end
defp validate_iso8601_datetime(_), do: {:error, "datetime must be string"}

# Integration with Domain.add_action/3
def add_action(domain, name, function, metadata \\ %{}) do
  case validate_action_metadata(metadata) do
    {:ok, validated_metadata} ->
      # Proceed with action registration
      do_add_action(domain, name, function, validated_metadata)
    
    {:error, reason} ->
      raise ArgumentError, "Cannot add action #{name}: #{reason}"
  end
end
```

**Benefits**:
- **Compile-time safety**: Type specifications catch errors early
- **Runtime validation**: Clear error messages for invalid metadata
- **Comprehensive coverage**: Validates all metadata fields with specific rules
- **Clear error messages**: Developers know exactly what's wrong
- **Fail-fast approach**: Invalid actions are rejected immediately

**Validation Rules**:
- **Temporal**: Either `:duration` OR (`:start` AND `:end`), not mixed
- **Agent capabilities**: Must be list of atoms if present
- **Entity requirements**: Must have `:type` string, optional `:properties` map
- **Resources**: Must be map with string lists for consumables/tools/locations
- **ISO 8601 formats**: Strict validation for duration and datetime strings

**Impact**: Eliminates runtime metadata errors and provides clear feedback for invalid action definitions

### 6. Migration Path Gaps (MEDIUM PRIORITY)
**Problem**: Incomplete migration guidance for existing code
- ADR mentions migration but lacks concrete steps for existing code
- No deprecation timeline or compatibility guarantees
- Missing automated migration tools or scripts

**Impact**: Difficult transition from legacy patterns to new unified approach

### 7. Todo/Goal Conversion Complexity (LOW PRIORITY) ✅ SOLUTION IDENTIFIED
**Problem**: Multiple data formats with unclear conversion rules
- Tasks: `{task_name, args}` vs Goals: `{subject, predicate, value}` vs Multigoals: `%Multigoal{}`
- Automatic conversion in PlannerAdapter creates confusion
- No clear guidelines on when to use which format

**Solution**: Unified Todo List Format with Full Interchangeability
```elixir
# Complete type specification for todo list elements (all interchangeable)
@type todo_element :: 
  {action_atom :: atom(), args :: list()} |              # Direct actions: {:move, ["room1"]}
  {task_name :: String.t(), args :: list()} |            # Task methods: {"task_move", ["room1"]}
  {subject :: String.t(), predicate :: String.t(), value :: any()} | # Goals: {"player", "location", "room1"}
  %AriaEngine.Multigoal{}                                # Multigoals: %AriaEngine.Multigoal{...}

# Todo lists can contain any mix of these elements in any order
@type todo_list :: [todo_element()]

# Example valid todo list with all element types mixed
todo_list = [
  {:move, ["room1"]},                      # Direct action atom
  {"task_verify", []},                     # Task method
  {"player", "location", "room1"},         # Goal
  %AriaEngine.Multigoal{goals: [...], ...}, # Multigoal
  {:cook, ["pasta"]},                      # Another direct action
  {"door", "state", "open"}                # Another goal
]

# Method examples returning different element types
def unigoal_method(state, goal) do
  {:ok, [
    {"task_move", ["room1"]},              # Task decomposition
    {"player", "location", "room1"}        # Goal verification
  ]}
end

def task_method(state, args) do
  {:ok, [
    {:move, ["room1"]},                    # Direct action
    {:verify_location, ["room1"]}          # Another direct action
  ]}
end

def multigoal_method(state, goals) do
  {:ok, [
    %AriaEngine.Multigoal{goals: goals, constraints: [...]} # Multigoal optimization
  ]}
end
```

**Benefits**:
- **Maximum flexibility**: Methods can return any combination of actions, tasks, goals, and multigoals
- **Natural decomposition**: Each method type outputs what makes sense for its level
- **Action Atom Priority preserved**: Planner resolves `:move` vs `"task_move"` based on availability
- **Unified processing**: Planner handles all element types uniformly
- **Clear documentation**: Type specs make the complete interchangeability explicit
- **No conversion confusion**: All formats are valid in any context

**Processing Logic**:
```elixir
# Planner processes each element based on its type
def process_todo_element(domain, state, element) do
  case element do
    {action_atom, args} when is_atom(action_atom) ->
      # Direct action execution
      execute_action(domain, state, action_atom, args)
    
    {task_name, args} when is_binary(task_name) ->
      # Task method decomposition
      decompose_task(domain, state, task_name, args)
    
    {subject, predicate, value} when is_binary(subject) and is_binary(predicate) ->
      # Goal achievement
      achieve_goal(domain, state, {subject, predicate, value})
    
    %AriaEngine.Multigoal{} = multigoal ->
      # Multigoal optimization
      optimize_multigoal(domain, state, multigoal)
  end
end
```

**Impact**: Eliminates data format confusion by making all todo element types explicitly interchangeable with clear type specifications and processing logic

### 8. Action Atom Aliasing (SOLVED ✅)
**Problem**: Automatic primitive method creation conflicted with action atoms
**Solution**: Implemented `task_` prefix approach for zero aliasing
- Action atoms: `:move`, `:cook`, `:build` (direct execution)
- Task methods: `"task_move"`, `"task_cook"`, `"task_build"` (decomposition)

## Related ADRs

- **ADR-086**: Implement Durative Actions (foundational work)
- **ADR-091**: Hybrid Planner Dependency Encapsulation (planning system)
- **ADR-129**: Aria Engine Plans glTF KHR Interactivity Implementation (related planning work)

## Extracted ADRs

- **ADR-132**: Fix Duration Handling Precision Loss (extracted from Phase 5)
- **ADR-133**: Planner Standardization Open Problems (extracted open problems catalog)
- **ADR-134**: Unified Action Specification Examples (extracted examples and patterns)

## Progress Tracking

**Phase 1**: ✅ COMPLETED - Core Duration Support (ISO 8601 datetime strings implemented)
**Phase 2**: ✅ COMPLETED - Unified Metadata Validation (agent/entity/resource requirements)  
**Phase 3**: ✅ COMPLETED - Goal Format Standardization (already using correct format)
**Phase 4**: ✅ COMPLETED - State Validation Simplification (StateV2.get_fact/3 standard)
**Phase 5**: ⚠️ **EXTRACTED** → **ADR-132**: Fix Duration Handling Precision Loss
**Phase 6**: 📋 PLANNED - Action Atom Priority Rule Implementation (task_ prefix)
**Phase 7**: 📋 PLANNED - Enhanced Metadata Support (capability/resource integration)
**Phase 8**: ⚠️ **IDENTIFIED** - Interval Module ISO 8601 Refactor (discovered during completion)

### Phase 8: Interval Module ISO 8601 Refactor

**Problem Identified**: The `AriaEngine.Timeline.Interval` module currently accepts `DateTime` structs but should only accept ISO 8601 strings to align with the unified durative action specification.

**Current Issues**:
- `new/2` and `new/3` accept `DateTime` structs instead of ISO 8601 strings
- `from_duration/3` accepts duration + time unit combinations
- Mixed temporal specification support when it should be ISO 8601 string-only

**Required Changes**:
```elixir
# Replace DateTime constructors with ISO 8601 string constructors
Interval.new_fixed_schedule("2025-06-22T10:00:00Z", "2025-06-22T11:00:00Z", opts \\ [])
Interval.new_floating_duration("PT1H", opts \\ [])

# Unified constructor with auto-detection
Interval.new(%{start: "2025-06-22T10:00:00Z", end: "2025-06-22T11:00:00Z"})
Interval.new(%{duration: "PT1H"})
```

**Implementation Plan**:
1. Add new ISO 8601 string-based constructors
2. Update internal structure to preserve original ISO 8601 strings in metadata
3. Maintain internal DateTime conversion for calculations
4. Update duration methods to be pattern-aware
5. Add migration utilities for existing DateTime-based intervals
6. Deprecate old constructors with clear migration path
7. Update test suite with comprehensive coverage

**Impact**: Ensures Timeline.Interval aligns with unified durative action specification requiring ISO 8601 strings for all temporal data.

## Implementation Status

### ✅ COMPLETED: Fixed Schedule Support (Phase 1)
- [x] ISO 8601 datetime validation for start/end times
- [x] Timezone requirement enforcement  
- [x] Start-before-end validation logic
- [x] Integration with existing metadata validation
- [x] Timex-based datetime parsing and validation
- [x] Error handling with descriptive messages for invalid formats

### ✅ COMPLETED: Metadata Validation Framework (Phase 2)
- [x] Unified entity requirements validation
- [x] Temporal specification conflict detection
- [x] Comprehensive error messaging system
- [x] Structured validation pipeline
- [x] Clear separation between temporal and entity validation

### ✅ COMPLETED: Test Coverage
- [x] All 8 unified durative action tests passing
- [x] Fixed schedule support validation
- [x] Metadata validation framework tests
- [x] End-to-end integration tests
- [x] Error handling validation tests

## Examples

### Before (Confusing Multiple Patterns)

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

### After (Unified Clear Patterns)

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

# Quantities handled in action implementation through state
def cook_meal(state, [meal_type]) do
  flour_available = StateV2.get_fact(state, "flour", "quantity")
  eggs_available = StateV2.get_fact(state, "eggs", "quantity")
  
  if flour_available >= 2 and eggs_available >= 6 do
    state
    |> StateV2.set_fact("flour", "quantity", flour_available - 2)
    |> StateV2.set_fact("eggs", "quantity", eggs_available - 6)
    |> StateV2.set_fact("meal", "status", "cooked")
  else
    {:error, :insufficient_ingredients}
  end
end
```

This unified approach eliminates confusion by providing exactly ONE way to accomplish each task, with clear examples and migration guidance.
