# ADR 133: Planner Standardization Open Problems

## Status
**Completed** (June 25, 2025) - All IPyHOP standardization problems resolved

## Context

During the unified durative action specification work, several additional standardization issues were identified that affect planner usability and consistency. This ADR documents the resolution of these problems and establishes the final IPyHOP-compatible planner architecture.

## Completed IPyHOP Features

### ✅ Solution Tree Structure
**Status:** Implemented - IPyHOP-compatible node types and operations

**Implementation:**
- IPyHOP-compatible node types: `:task`, `:action`, `:goal`, `:multigoal`, `:verify_goal`, `:verify_multigoal`
- Proper node status tracking: `:open`, `:closed`, `:failed`
- **Action priority in node selection** - actions execute before task decomposition
- State preservation at each node for backtracking
- Integration with blacklist system

```elixir
defmodule AriaEngine.SolutionTree do
  defstruct [
    :nodes,           # %{node_id => node_data}
    :edges,           # %{parent_id => [child_ids]}
    :root_id,         # Root node ID
    :next_id,         # Next available ID
    :blacklist        # MapSet of blacklisted actions
  ]
  
  @type node_type :: :task | :action | :goal | :multigoal | :verify_goal | :verify_multigoal
  @type node_status :: :open | :closed | :failed
end
```

### ✅ Corrected `run_lazy_refineahead`
**Status:** Implemented - True interleaved planning and execution

**Key Corrections:**
- **True interleaved planning and execution** - no separate planning phase
- **Action nodes execute immediately** when selected (highest priority)
- **Proper backtracking on failure** with state restoration
- **Method alternative exploration** when primary methods fail

```elixir
defmodule AriaEngine.LazyRefineahead do
  def run_lazy_refineahead(domain, initial_state, todo_list, opts \\ []) do
    # Initialize solution tree
    solution_tree = SolutionTree.new(todo_list)
    
    # Main refinement loop with action priority
    refinement_loop(domain, initial_state, solution_tree, 0, opts)
  end
  
  defp find_next_open_node_with_action_priority(tree, parent_node_id) do
    open_nodes = get_open_successor_nodes(tree, parent_node_id)
    
    case open_nodes do
      [] -> backtrack_to_parent(tree, parent_node_id)
      nodes ->
        # PRIORITY: Actions first, then tasks/goals
        prioritized_node = Enum.find(nodes, fn node_id ->
          SolutionTree.get_node(tree, node_id).type == :action
        end) || List.first(nodes)
        
        {:ok, prioritized_node}
    end
  end
end
```

### ✅ Replan/Backtracking System
**Status:** Implemented - IPyHOP-style failure recovery

**Implementation:**
- IPyHOP-style failure recovery with method alternatives
- State restoration at backtrack points
- Pruning of failed subtrees
- Alternative method exploration

```elixir
defmodule AriaEngine.Replanner do
  def replan(domain, current_state, solution_tree, failed_node_id, opts \\ []) do
    # Find backtrack point with alternative methods
    case find_backtrack_point_with_alternatives(solution_tree, failed_node_id) do
      {:ok, backtrack_node_id} ->
        # Restore state and prune failed subtree
        restored_state = restore_state_at_node(solution_tree, backtrack_node_id, current_state)
        pruned_tree = prune_failed_subtree(solution_tree, backtrack_node_id)
        
        # Continue planning with alternative methods
        continue_planning_with_alternatives(domain, restored_state, pruned_tree, backtrack_node_id, opts)
        
      {:error, :no_alternatives} ->
        {:error, "No alternative methods available for replanning"}
    end
  end
end
```

### ✅ Blacklist System
**Status:** Implemented - Failed action prevention

**Implementation:**
- **Failed action prevention** - actions that fail get blacklisted
- **Integration with solution tree** - blacklist checked during node selection
- **Automatic blacklisting on execution failure**
- **Persistent across planning sessions**

```elixir
defmodule AriaEngine.SolutionTree do
  def blacklist_action(tree, action) do
    %{tree | blacklist: MapSet.put(tree.blacklist, action)}
  end
  
  def is_blacklisted?(tree, action) do
    MapSet.member?(tree.blacklist, action)
  end
end

# Usage in action execution
defp execute_action_node(domain, state, tree, node_id, opts) do
  node = SolutionTree.get_node(tree, node_id)
  {action_name, args} = node.info
  
  # Check blacklist first
  if SolutionTree.is_blacklisted?(tree, node.info) do
    Logger.debug("Action #{action_name} is blacklisted, backtracking")
    {:backtrack, find_backtrack_point(tree, node_id), tree}
  else
    # Execute action
    case Domain.execute_action(domain, state, action_name, args) do
      {:ok, new_state} ->
        updated_tree = SolutionTree.mark_completed(tree, node_id)
        {:ok, new_state, updated_tree}
        
      {:error, reason} ->
        # Blacklist failed action and backtrack
        updated_tree = tree
        |> SolutionTree.blacklist_action(node.info)
        |> SolutionTree.mark_failed(node_id)
        
        {:backtrack, find_backtrack_point(tree, node_id), updated_tree}
    end
  end
end
```

### ✅ Goal Verification Tasks
**Status:** Implemented - Automatic verification after goal methods

**Implementation:**
- **Automatic verification after goal methods** - ensures goals are actually achieved
- **`:verify_goal` and `:verify_multigoal` node types**
- **Integration with solution tree structure**

```elixir
# Automatic verification task creation
defp refine_goal_node(domain, state, tree, node_id, opts) do
  node = SolutionTree.get_node(tree, node_id)
  goal = node.info
  
  # Try goal methods
  case Domain.get_unigoal_methods(domain, goal) do
    [] ->
      {:error, "No methods available for goal: #{inspect(goal)}"}
      
    methods ->
      case try_goal_methods(methods, state, goal) do
        {:ok, subtasks} ->
          # Add verification task automatically
          verification_task = {:verify_goal, [goal]}
          updated_subtasks = subtasks ++ [verification_task]
          
          # Create child nodes including verification
          updated_tree = SolutionTree.add_child_nodes(tree, node_id, updated_subtasks)
          {:ok, state, updated_tree}
          
        {:error, reason} ->
          {:error, reason}
      end
  end
end
```

### ✅ Pure GTPyhop Multigoal Resolution
**Status:** Implemented - No automatic fallbacks

**Key Implementation:**
- **NO automatic fallbacks** for multigoals
- **Domain authors must explicitly define** `@multigoal_method` if multigoals are used
- **Planning fails** if multigoals are encountered without domain methods
- **`split_multigoal` and MinizinC** available as explicit tools for domain authors

```elixir
defmodule AriaEngine.MultigoalResolver do
  def resolve_multigoal(domain, state, multigoal) do
    # ONLY try domain-defined multigoal methods
    case Domain.get_multigoal_methods(domain, multigoal) do
      [] ->
        # Pure GTPyhop: FAIL if no domain methods exist
        {:error, "No multigoal methods defined for multigoal pattern: #{inspect(multigoal)}"}
        
      methods ->
        # Try domain methods only - no automatic fallbacks
        try_domain_methods_only(methods, state, multigoal)
    end
  end
end

# Example domain with explicit multigoal methods
defmodule MyApp.Domains.CookingDomain do
  # EXPLICIT multigoal methods (Pure GTPyhop Style)
  @multigoal_method goal_pattern: :cooking_workflow
  def handle_cooking_workflow(state, multigoal) do
    # Domain author explicitly chooses strategy
    case custom_cooking_optimization(state, multigoal.goals) do
      {:ok, plan} -> {:ok, plan}
      {:error, _} ->
        # Domain author EXPLICITLY chooses fallback
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
end
```

## 🪦 Tombstoned Features

### Rigid Relations (Redundant)
**Status:** Tombstoned - Redundant with AriaEngine's existing capability system

The rigid relations pattern from GTPyhop is **redundant** with AriaEngine's existing capability system:

**Rigid Relations (Don't Use):**
```elixir
@rigid_relations %{
  types: %{"person" => ["alice", "bob"]},
  predicates: %{"can_cook" => [["alice"], ["bob"]]}
}
def is_a(variable, type), do: variable in @rigid_relations.types[type]
def can_cook(person), do: [person] in @rigid_relations.predicates["can_cook"]
```

**Capability System (Use This Instead):**
```elixir
@action requires_entities: [
  %{type: "agent", capabilities: [:cooking], constraints: %{name: "alice"}}
]
def cook_meal(state, [meal_type]) do
  # AriaEngine automatically validates capabilities
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} -> proceed_with_cooking(state, meal_type, entities)
    {:error, reason} -> {:error, reason}
  end
end
```

**Why Capability System is Superior:**
- **Dynamic validation** - checks current state, not static declarations
- **Constraint support** - quantity, location, status constraints
- **Temporal awareness** - entities can gain/lose capabilities over time
- **Integration** - works seamlessly with existing AriaEngine infrastructure
- **Flexibility** - supports complex entity relationships and dependencies

### Automatic Multigoal Fallbacks (Violates GTPyhop Philosophy)
**Status:** Tombstoned - Violates pure GTPyhop design philosophy

**Removed automatic fallbacks** that violated pure GTPyhop design:
- No automatic `split_multigoal` when domain methods fail
- No automatic MinizinC optimization without explicit domain choice
- Domain authors must explicitly handle all multigoal scenarios

**Before (Incorrect - Automatic Fallbacks):**
```elixir
def resolve_multigoal(domain, state, multigoal) do
  case try_domain_methods(domain, state, multigoal) do
    {:error, _} -> 
      # WRONG: Always falls back to automatic methods
      AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
  end
end
```

**After (Correct - Pure GTPyhop Style):**
```elixir
def resolve_multigoal(domain, state, multigoal) do
  case Domain.get_multigoal_methods(domain, multigoal) do
    [] -> 
      # CORRECT: Fail if no domain methods exist
      {:error, "No multigoal methods defined"}
    methods -> 
      # CORRECT: Use domain methods exclusively
      try_domain_methods_only(methods, state, multigoal)
  end
end
```

## Resolved Open Problems Catalog

### 1. Method Registration Inconsistencies ✅ RESOLVED

**Solution:** Module-based domain pattern with `@action`, `@command`, `@task_method`, `@unigoal_method`, `@multigoal_method` attributes

**Implementation:**
```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  @action duration: "PT2H", requires_entities: [...]
  def cook_meal(state, [meal_type]) do
    # Planning-time action
  end
  
  @command
  def cook_meal_command(state, [meal_type]) do
    # Execution-time command with failure handling
  end
  
  @task_method
  def task_prepare_ingredients(state, [task_name]) do
    {:ok, [{:gather_ingredients, [task_name]}]}
  end
  
  @unigoal_method goal_pattern: {"chef", "location", :any}
  def travel_to_location(state, goal) do
    {:ok, [{:walk_to_location, [target]}]}
  end
end
```

### 2. Multigoal vs Unigoal Confusion ✅ RESOLVED

**Solution:** Clear hierarchical decomposition with pure GTPyhop multigoal philosophy

**Clear Hierarchy:**
1. **Multigoal methods** → Domain-specific optimization for multiple goals (explicit only)
2. **Unigoal methods** → Decompose single goal into task todos
3. **Task methods** → Decompose tasks into subtasks/actions
4. **Actions** → Change state directly (highest execution priority)

### 3. Domain Module Creation Patterns ✅ RESOLVED

**Solution:** Module-first pattern following Elixir conventions

**Benefits:**
- Follows Elixir conventions with modules and attributes
- Compile-time validation of metadata and function signatures
- Clear organization with all domain logic in one module
- Integration with ExDoc and hot code reloading

### 4. Error Handling Standardization ✅ RESOLVED

**Solution:** Standard Elixir tagged tuples with descriptive errors

**Pattern:**
```elixir
# Success
{:ok, result}

# Failure (triggers backtracking)
{:error, :descriptive_reason}

# Backtracker logic
case method_result do
  {:ok, todos} -> continue_with(todos)
  _anything_else -> backtrack()
end
```

### 5. Todo/Goal Conversion Complexity ✅ RESOLVED

**Solution:** Unified todo list format with full interchangeability

**Complete Type Specification:**
```elixir
@type todo_element :: 
  {action_atom :: atom(), args :: list()} |              # Direct actions
  {task_name :: String.t(), args :: list()} |            # Task methods
  {subject :: String.t(), predicate :: String.t(), value :: any()} | # Goals
  %AriaEngine.Multigoal{}                                # Multigoals

@type todo_list :: [todo_element()]
```

### 6. Migration Path Gaps ✅ RESOLVED

**Solution:** Clear migration guidance in ADR-134 with concrete examples

**Migration Strategy:**
- Module-based domains for all new development
- Clear before/after examples for each pattern
- Deprecation of legacy patterns with helpful error messages

## Commands System Integration

### Planning-Time Actions vs Execution-Time Commands

**Planning-Time Actions** (assume success for planning purposes):
```elixir
@action duration: "PT2H", requires_entities: [...]
def cook_meal(state, [meal_type]) do
  # Planning-time logic - assumes success
  {:ok, updated_state}
end
```

**Execution-Time Commands** (handle real-world failures):
```elixir
@command
def cook_meal_command(state, [meal_type]) do
  # Execution-time logic - handles real failures
  case attempt_cooking_with_failure_chance(state, meal_type) do
    {:ok, new_state} -> {:ok, new_state}
    {:error, reason} -> {:error, reason}  # Triggers blacklisting and replanning
  end
end
```

### Integration with Blacklist System
When commands fail during execution:
1. **Action gets blacklisted** - prevents repeated attempts
2. **Backtracking triggered** - finds alternative methods
3. **Replanning occurs** - explores different approaches
4. **State restored** - returns to last known good state

## Success Criteria

- [x] All identified problems have documented solutions
- [x] Implementation plans exist for all issues
- [x] Clear migration paths defined for breaking changes
- [x] Consistent patterns established across the planner
- [x] Developer confusion eliminated through standardization
- [x] IPyHOP compatibility achieved with proper node types and priorities
- [x] Pure GTPyhop multigoal philosophy implemented
- [x] Solution tree structure with blacklist system
- [x] Corrected `run_lazy_refineahead` with interleaved planning/execution
- [x] Goal verification tasks for automatic verification
- [x] Commands system for execution-time behavior

## Related ADRs

- **ADR-131**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-132**: Fix Duration Handling Precision Loss (technical integration)
- **ADR-134**: Unified Action Specification Examples (final canonical pattern)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Completed - All IPyHOP standardization problems resolved
**Architecture:** IPyHOP-compatible with pure GTPyhop multigoal philosophy
**Timeline:** Available immediately for domain development
**Compatibility:** Full backward compatibility with existing capability system
