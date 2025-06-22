# ADR-133: Planner Standardization Open Problems

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** MEDIUM  
**Extracted from:** ADR-131

## Context

During the unified durative action specification work, several additional standardization issues were identified that affect planner usability and consistency. These problems are documented here as a reference catalog for future improvement work.

## Open Problems Catalog

### 1. Method Registration Inconsistencies ✅ SOLUTION IDENTIFIED
**Priority:** MEDIUM  
**Status:** Solution designed, implementation pending

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

### 2. Multigoal vs Unigoal Confusion ✅ SOLUTION IDENTIFIED
**Priority:** MEDIUM  
**Status:** Solution designed, implementation pending

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

### 3. Domain Module Creation Patterns ✅ SOLUTION IDENTIFIED
**Priority:** LOW  
**Status:** Solution designed, implementation pending

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

### 4. Error Handling Standardization ✅ SOLUTION IDENTIFIED
**Priority:** MEDIUM  
**Status:** Solution designed, implementation pending

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

### 5. Todo/Goal Conversion Complexity ✅ SOLUTION IDENTIFIED
**Priority:** LOW  
**Status:** Solution designed, implementation pending

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
```

**Benefits**:
- **Maximum flexibility**: Methods can return any combination of actions, tasks, goals, and multigoals
- **Natural decomposition**: Each method type outputs what makes sense for its level
- **Action Atom Priority preserved**: Planner resolves `:move` vs `"task_move"` based on availability
- **Unified processing**: Planner handles all element types uniformly
- **Clear documentation**: Type specs make the complete interchangeability explicit
- **No conversion confusion**: All formats are valid in any context

**Impact**: Eliminates data format confusion by making all todo element types explicitly interchangeable with clear type specifications and processing logic

### 6. Migration Path Gaps
**Priority:** MEDIUM  
**Status:** Needs analysis

**Problem**: Incomplete migration guidance for existing code
- ADR mentions migration but lacks concrete steps for existing code
- No deprecation timeline or compatibility guarantees
- Missing automated migration tools or scripts

**Potential Solutions**:
- Create migration scripts for common patterns
- Establish deprecation timeline with clear milestones
- Provide automated code transformation tools
- Document step-by-step migration procedures

**Impact**: Difficult transition from legacy patterns to new unified approach

## Implementation Priority

**High Priority (Blocking Issues)**:
- None currently - all high-priority issues have solutions

**Medium Priority (Quality of Life)**:
1. Method Registration Inconsistencies
2. Multigoal vs Unigoal Confusion  
3. Error Handling Standardization
4. Migration Path Gaps

**Low Priority (Nice to Have)**:
1. Domain Module Creation Patterns
2. Todo/Goal Conversion Complexity

## Success Criteria

- [ ] All identified problems have documented solutions
- [ ] Implementation plans exist for medium/high priority issues
- [ ] Clear migration paths defined for breaking changes
- [ ] Consistent patterns established across the planner
- [ ] Developer confusion eliminated through standardization

## Related ADRs

- **ADR-131**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-132**: Fix Duration Handling Precision Loss (extracted issue)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Catalog complete, solutions designed for most issues
**Next Steps:** Prioritize implementation based on impact and effort
**Timeline:** Medium priority - quality of life improvements for developers
