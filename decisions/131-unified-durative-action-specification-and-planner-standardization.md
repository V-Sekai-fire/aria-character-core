# ADR-131: Unified Durative Action Specification and Planner Standardization

**Status:** Active  
**Date:** 2025-06-22  
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

**Hybrid Capabilities Model: Both Simple Traits and Rich Entities**

Capabilities support both simple atoms (for basic traits) and rich entities (for complex capabilities with properties):

```elixir
@type capability :: 
  atom() |                    # Simple trait: :agent, :consumable, :reusable
  %{                         # Rich capability entity
    required(:type) => String.t(),
    optional(:properties) => map(),
    optional(:constraints) => map()
  }
```

**Simple capabilities (atoms)** for basic categorical traits:
- **Categorical traits**: `:agent`, `:consumable`, `:tool`, `:appliance`
- **Basic behaviors**: `:reusable`, `:portable`, `:stackable`
- **Simple classifications**: `:kitchen_equipment`, `:ingredient`

**Rich capabilities (entities)** for complex behaviors with properties:
- **Constrained capabilities**: Temperature ranges, capacity limits, timing
- **Stateful capabilities**: Durability, charge level, maintenance status
- **Parameterized behaviors**: Precision levels, speed settings, quality grades

**Examples of hybrid capability composition:**
```elixir
# Kitchen appliance with mixed simple and rich capabilities
%{type: "oven", capabilities: [
  :appliance,                                    # Simple trait
  :kitchen_equipment,                            # Simple trait
  %{type: "heating", properties: %{             # Rich capability
    max_temp: 450,
    min_temp: 150,
    precision: "±5°F"
  }},
  %{type: "baking", properties: %{              # Rich capability
    timer: true,
    convection: true,
    rack_positions: 3
  }}
]}

# Agent with mixed capabilities
%{type: "chef", capabilities: [
  :agent,                                        # Simple trait
  :human,                                        # Simple trait
  %{type: "cooking", properties: %{             # Rich capability
    experience_level: "expert",
    specialties: ["french", "italian"],
    certifications: ["food_safety", "wine_pairing"]
  }},
  %{type: "knife_skills", properties: %{        # Rich capability
    precision: "professional",
    speed: "fast",
    techniques: ["julienne", "brunoise", "chiffonade"]
  }}
]}

# Simple consumable with basic traits
%{type: "flour", capabilities: [
  :consumable,                                   # Simple trait
  :ingredient,                                   # Simple trait
  :pantry_item,                                  # Simple trait
  :bakeable                                      # Simple trait
]}

# Complex tool with durability tracking
%{type: "knife", capabilities: [
  :tool,                                         # Simple trait
  :kitchen_equipment,                            # Simple trait
  :reusable,                                     # Simple trait
  %{type: "cutting", properties: %{             # Rich capability
    sharpness: 85,                              # 0-100 scale
    blade_material: "carbon_steel",
    maintenance_due: "2025-07-01"
  }},
  %{type: "slicing", properties: %{             # Rich capability
    thickness_range: {0.5, 10},                # mm
    precision: "high"
  }}
]}
```

**Query flexibility with hybrid capabilities:**
```elixir
# Simple capability queries (atoms)
entities_with_capability(:consumable)
entities_with_capability(:reusable)
entities_with_capability(:agent)

# Mixed simple and rich capability queries
entities_with_capabilities([:kitchen_equipment, %{type: "heating"}])
entities_with_capabilities([:agent, %{type: "cooking"}])

# Rich capability queries with property constraints
entities_with_capability(%{type: "heating", properties: %{max_temp: 400}})
entities_with_capability(%{type: "cutting", properties: %{sharpness: 80}})

# Complex queries combining multiple capability types
find_entities_matching([
  :tool,                                    # Must be a tool (simple)
  :kitchen_equipment,                       # Must be kitchen equipment (simple)
  %{type: "cutting", properties: %{         # Must have cutting capability (rich)
    sharpness: {:>=, 75},                   # With minimum sharpness
    maintenance_due: {:after, Date.utc_today()}  # Not due for maintenance
  }}
])

# Query by capability type regardless of properties
entities_with_capability_type("heating")    # All heating capabilities
entities_with_capability_type("cooking")    # All cooking capabilities
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
- ✅ `start` AND `end` only (fixed schedule)  
- ❌ Cannot mix `duration` with `start`/`end`
- ❌ Cannot have `start` without `end`
- ❌ Cannot have `end` without `start`

**Standardized formats:**
- **Goals**: ONLY `{subject, predicate, value}` format
- **State validation**: ONLY `StateV2.get_fact/3` direct fact checking (supports temporal queries)
- **Entity management**: ONLY through Domain actions API
- **Planning API**: Clear guidance on which API to use when

## Decision

Create a unified durative action specification system that eliminates confusion by providing ONE clear way to define actions with entities, capabilities, resources, and temporal constraints.

## Implementation Plan

### Phase 1: Core Duration Support (HIGH PRIORITY)
**File**: `lib/aria_engine/domain/actions.ex`

**Missing/Required**:
- [ ] Add support for ISO 8601 datetime strings (start/end times)
- [ ] Extend existing ISO 8601 duration string support
- [ ] Unified metadata validation for both formats

**Implementation Patterns Needed**:
```elixir
# Detect fixed time intervals
if Map.has_key?(metadata, :start) and Map.has_key?(metadata, :end) do
  # Create fixed interval from ISO 8601 datetime strings
  start_time = DateTime.from_iso8601!(metadata[:start])
  end_time = DateTime.from_iso8601!(metadata[:end])
  interval = Interval.new(start_time, end_time)
  
# Detect floating durations  
elsif Map.has_key?(metadata, :duration) do
  # Create floating interval from ISO 8601 duration string
  interval = Interval.from_iso8601_duration(metadata[:duration])
end
```

### Phase 2: Unified Entity/Capability/Resource Specification (HIGH PRIORITY)
**File**: `lib/aria_engine/domain/actions.ex`

**Missing/Required**:
- [ ] Add `requires_agent` metadata support
- [ ] Add `requires_entities` metadata support  
- [ ] Add `resources` metadata support
- [ ] Validation logic for requirements

**Implementation Patterns Needed**:
```elixir
# Agent capability requirements
requires_agent: %{
  capabilities: [:cooking, :menu_planning],
  properties: %{experience_level: "expert"}
}

# Entity requirements
requires_entities: [
  %{type: "oven", properties: %{temperature_max: 400}},
  %{type: "workspace", properties: %{size: "large"}}
]

# Resource requirements
resources: %{
  consumables: ["flour", "eggs", "milk"],
  tools: ["mixing_bowl", "whisk"],
  locations: ["kitchen"]
}
```

### Phase 3: Goal Format Standardization (HIGH PRIORITY)
**File**: Multiple files across codebase

**Missing/Required**:
- [ ] Audit all goal usage for `{predicate, subject, value}` format
- [ ] Convert to `{subject, predicate, value}` format
- [ ] Add deprecation warnings for old format
- [ ] Update documentation and examples

**Implementation Patterns Needed**:
```elixir
# CORRECT format (subject-first)
{subject, predicate, value}
{"player", "location", "room1"}
{"door", "state", "open"}

# DEPRECATED format (predicate-first) - TOMBSTONE
{predicate, subject, value}  # ❌ DO NOT USE
```

### Phase 4: State Validation Simplification (MEDIUM PRIORITY)
**File**: `lib/aria_engine/domain/actions.ex`

**Missing/Required**:
- [ ] Remove `validate_temporal_condition/2` function
- [ ] Remove `StateV2.evaluate_condition/2` usage
- [ ] Replace all with direct `StateV2.get_fact/3` calls
- [ ] Update condition validation logic

**Implementation Patterns Needed**:
```elixir
# ONLY use direct fact checking (supports temporal queries)
def validate_condition(state, {subject, predicate, required_value}) do
  StateV2.get_fact(state, subject, predicate) == required_value
end

# For temporal validation (past/future state checking)
def validate_temporal_condition(state, {subject, predicate, required_value}, time) do
  StateV2.get_fact(state, subject, predicate, time) == required_value
end

# Remove complex condition evaluators
```

### Phase 5: Planning API Standardization (MEDIUM PRIORITY)
**File**: Documentation and usage guidelines

**Missing/Required**:
- [ ] Create clear API usage guidelines
- [ ] Document when to use each planning API
- [ ] Provide migration path from legacy APIs
- [ ] Add deprecation warnings

**Implementation Patterns Needed**:
```elixir
# For new code: Use HybridCoordinatorV2 directly
coordinator = HybridCoordinatorV2.new_default(opts)
HybridCoordinatorV2.plan(coordinator, domain, state, goals, opts)

# For legacy compatibility: Use PlannerAdapter
PlannerAdapter.plan(domain, state, todos, opts)

# For direct HTN: Use plan_tasks
PlannerAdapter.plan_tasks(domain, state, tasks, opts)
```

### Phase 6: Action Definition Standardization (HIGH PRIORITY)
**File**: `lib/aria_engine/domain.ex` and `lib/aria_engine/domain/actions.ex`

**Missing/Required**:
- [ ] Implement Action Atom Priority Rule to prevent aliasing
- [ ] Fix automatic primitive method creation naming conflicts
- [ ] Standardize on `Domain.add_action/3` with metadata
- [ ] Deprecate complex DurativeAction struct usage
- [ ] Simplify module-based domain creation
- [ ] Update all domain examples

**Action Atom Priority Rule (CRITICAL)**:
```elixir
# PROBLEM: Current automatic primitive method creation causes aliasing
task_name = Atom.to_string(name)  # "move" - CONFLICTS with :move atom

# SOLUTION: Use task_ prefix to eliminate ALL aliasing
task_name = "task_#{Atom.to_string(name)}"  # "task_move"
primitive_method_fn = fn _state, args -> [{name, args}] end  # returns {:move, args}

# Zero aliasing achieved:
# - Action atoms: :move, :cook, :build (direct execution)
# - Task methods: "task_move", "task_cook", "task_build" (decomposition)
# - NO conflicts between atom and string identifiers
```

**Implementation Patterns Needed**:
```elixir
# Clear separation with zero aliasing
# Action atoms: :move, :cook, :build (direct execution, high priority)
# Task methods: "task_move", "task_cook", "task_build" (decomposition, lower priority)

# No resolution conflicts - completely different namespaces
def resolve_action_or_task(domain, identifier) do
  cond do
    is_atom(identifier) and has_action?(domain, identifier) ->
      {:action, get_action(domain, identifier)}
    
    is_binary(identifier) and has_task_methods?(domain, identifier) ->
      {:task_methods, get_task_methods(domain, identifier)}
    
    true ->
      {:error, "No action or task method found for #{inspect(identifier)}"}
  end
end

# Automatic primitive method creation with task_ prefix
def create_primitive_method(domain, action_name) do
  task_name = "task_#{Atom.to_string(action_name)}"
  primitive_method_fn = fn _state, args -> [{action_name, args}] end
  Domain.add_task_method(domain, task_name, primitive_method_fn)
end
```

## Implementation Strategy

### Approach Requirements
1. **Clean Evolution**: Prioritize evolving codebase with all tests and warnings resolved over internal backward compatibility
2. **Testing Strategy**: Comprehensive unit tests for each phase with zero warnings/errors
3. **Sequential Implementation**: One phase at a time with complete test suite passing and clean compilation
4. **Phase 1 Priority**: Core Duration Support must support both fixed schedule (ISO 8601 datetime strings) and floating duration schedule (ISO 8601 duration strings)

### Current State Analysis (June 22, 2025)

**✅ ALREADY IMPLEMENTED:**
- **Goal Format Standardization**: All 87 test instances use correct `{subject, predicate, value}` format
- **State Validation**: `StateV2.get_fact/3` is already the standard approach throughout codebase
- **Floating Duration Support**: ISO 8601 duration strings (`"PT8H"`) already supported via `Interval.from_iso8601_duration/1`

**❌ MISSING IMPLEMENTATION:**
- **Fixed Schedule Support**: ISO 8601 datetime strings for `start`/`end` times not supported
- **Unified Metadata Validation**: No validation for agent/entity/resource requirements
- **Action Atom Priority Rule**: Automatic primitive method creation causes aliasing conflicts
- **Deprecated Function Cleanup**: Some legacy validation functions still present

### Step 1: Phase 1 - Core Duration Support Extension
**Status**: ⏳ IN PROGRESS
**Priority**: HIGH

1. Add ISO 8601 datetime string support for fixed intervals (`start`/`end` metadata)
2. Maintain existing ISO 8601 duration string support (`duration` metadata)
3. Create unified temporal specification validation (duration XOR start+end)
4. Comprehensive unit tests for both fixed and floating duration patterns

### Step 2: Phase 2 - Unified Metadata Validation
**Status**: 📋 PLANNED
**Priority**: HIGH

1. Extend action metadata to support `requires_agent`, `requires_entities`, `resources`
2. Create comprehensive validation logic with type specifications
3. Add runtime validation with clear error messages
4. Integrate validation into `Domain.add_action/4`

### Step 3: Phase 3 - Goal Format Standardization
**Status**: ✅ COMPLETED
**Priority**: ~~HIGH~~ COMPLETE

~~1. Audit and convert goal formats to subject-first~~ ✅ Already using `{subject, predicate, value}` format
~~2. Add deprecation warnings for old format~~ ✅ No old format found in codebase
~~3. Update documentation and examples~~ ✅ All examples already use correct format

### Step 4: Phase 4 - State Validation Simplification  
**Status**: ✅ MOSTLY COMPLETE
**Priority**: ~~MEDIUM~~ LOW

~~1. Remove `validate_temporal_condition/2` function~~ ⚠️ Still present but not widely used
~~2. Replace all with direct `StateV2.get_fact/3` calls~~ ✅ Already standard practice
~~3. Update condition validation logic~~ ✅ `StateV2.evaluate_condition/2` handles complex cases

### Step 5: Phase 5 - Action Atom Priority Rule Implementation
**Status**: 📋 PLANNED  
**Priority**: HIGH

1. Implement `task_` prefix for automatic primitive method creation
2. Fix aliasing conflicts between action atoms and task method strings
3. Update method resolution logic for zero conflicts
4. Comprehensive tests for action/task namespace separation

### Step 6: Phase 6 - Enhanced Metadata Support
**Status**: 📋 PLANNED
**Priority**: MEDIUM

1. Add agent capability requirement checking
2. Add entity and resource requirement validation
3. Integrate with planning system for resource allocation
4. Update all domain examples with new metadata patterns

### Current Focus: Phase 1 - Core Duration Support Extension

**Rationale**: Complete the missing ISO 8601 datetime string support for fixed scheduling before building unified specification system. This enables both floating duration (effort-based) and fixed schedule (time-based) action definitions.

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

# Temporal validation (mutually exclusive)
defp validate_temporal_specification(metadata) do
  temporal_keys = [:duration, :start, :end]
  present_keys = Enum.filter(temporal_keys, &Map.has_key?(metadata, &1))
  
  cond do
    # No temporal specification (valid)
    Enum.empty?(present_keys) ->
      {:ok, :no_temporal_spec}
    
    # Duration only (floating effort)
    present_keys == [:duration] ->
      validate_iso8601_duration(metadata[:duration])
    
    # Start and end (fixed interval)
    Enum.sort(present_keys) == [:end, :start] ->
      with {:ok, start_dt} <- validate_iso8601_datetime(metadata[:start]),
           {:ok, end_dt} <- validate_iso8601_datetime(metadata[:end]) do
        if DateTime.compare(start_dt, end_dt) == :lt do
          {:ok, :fixed_interval}
        else
          {:error, "start time must be before end time"}
        end
      end
    
    # Invalid combinations
    true ->
      {:error, "invalid temporal specification - use either :duration OR (:start AND :end)"}
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

## Progress Tracking

**Phase 1**: ⏳ IN PROGRESS - Core Duration Support (missing ISO 8601 datetime strings)
**Phase 2**: 📋 PLANNED - Unified Metadata Validation (agent/entity/resource requirements)  
**Phase 3**: ✅ COMPLETED - Goal Format Standardization (already using correct format)
**Phase 4**: ✅ MOSTLY COMPLETE - State Validation Simplification (StateV2.get_fact/3 standard)
**Phase 5**: 📋 PLANNED - Action Atom Priority Rule Implementation (task_ prefix)
**Phase 6**: 📋 PLANNED - Enhanced Metadata Support (capability/resource integration)

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
