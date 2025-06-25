# ADR-133: Architecture & Standards - IPyHOP Integration and System Design

**Status:** Active
**Date:** 2025-06-25
**Priority:** HIGH
**Parent ADR:** ADR-131 (Core Specification)

## Overview

**Current State**: Multiple architectural inconsistencies affecting planner usability
**Target State**: IPyHOP-compatible planner architecture with pure GTPyhop multigoal philosophy

## IPyHOP Architecture Integration

### Solution Tree Structure

IPyHOP-compatible node types and operations with proper state tracking:

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

**Node Priority System:**

- `:action` nodes execute with highest priority (immediate execution)
- `:task` nodes decompose into subtasks/actions
- `:goal` nodes decompose into subgoals with automatic verification
- `:multigoal` nodes require explicit domain methods (no automatic fallbacks)

### Corrected `run_lazy_refineahead`

True interleaved planning and execution with action priority:

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

**Key Architectural Principles:**

- **True interleaved planning and execution** - no separate planning phase
- **Action nodes execute immediately** when selected
- **Proper backtracking on failure** with state restoration
- **Method alternative exploration** when primary methods fail

## Blacklist System Architecture

### Failed Action Prevention

Comprehensive blacklisting system with solution tree integration:

```elixir
defmodule Plan.Blacklisting do
  @type blacklist_entry :: {action_name :: atom(), args :: list()}
  @type blacklist_scope :: :global | :session | :subtree
  
  defstruct [
    :entries,        # MapSet of blacklisted actions
    :scope,          # Blacklist scope level
    :created_at,     # Timestamp for blacklist entry
    :failure_count   # Number of failures for this action
  ]
end

# Integration with solution tree
defp execute_action_node(domain, state, tree, node_id, opts) do
  node = SolutionTree.get_node(tree, node_id)
  {action_name, args} = node.info
  
  # Check blacklist before execution
  if SolutionTree.is_blacklisted?(tree, {action_name, args}) do
    Logger.debug("Action #{action_name} is blacklisted, triggering backtrack")
    {:backtrack, find_backtrack_point(tree, node_id), tree}
  else
    # Execute action with failure handling
    case Domain.execute_action(domain, state, action_name, args) do
      {:ok, new_state} ->
        updated_tree = SolutionTree.mark_completed(tree, node_id)
        {:ok, new_state, updated_tree}
        
      {:error, reason} ->
        # Automatically blacklist failed action
        updated_tree = tree
        |> SolutionTree.blacklist_action({action_name, args}, :session)
        |> SolutionTree.mark_failed(node_id)
        
        {:backtrack, find_backtrack_point(tree, node_id), updated_tree}
    end
  end
end
```

### Intelligent Backtracking

Blacklist-guided backtracking to avoid repeated failures:

```elixir
defmodule AriaEngine.Backtracker do
  def find_backtrack_point_with_blacklist_guidance(tree, failed_node_id) do
    # Find backtrack points that have non-blacklisted alternatives
    potential_points = find_potential_backtrack_points(tree, failed_node_id)
    
    # Filter points that have viable (non-blacklisted) alternatives
    viable_points = Enum.filter(potential_points, fn point_id ->
      has_non_blacklisted_alternatives?(tree, point_id)
    end)
    
    case viable_points do
      [best_point | _] -> {:ok, best_point}
      [] -> {:error, :no_viable_backtrack_points}
    end
  end
end
```

## Pure GTPyhop Multigoal Philosophy

### No Automatic Fallbacks

Domain authors must explicitly define multigoal methods - no automatic splitting:

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
```

### Built-in Utilities Available (Explicit Use Only)

```elixir
# Available utilities for domain authors (explicit registration required)
defmodule AriaEngine.Multigoal do
  # Basic goal decomposition utility
  def split_multigoal(state, goals) do
    goals
    |> Enum.map(fn goal -> create_unigoal_task(goal) end)
    |> validate_goal_dependencies(state)
  end
  
  # Goal conflict analysis
  def analyze_goal_conflicts(state, goals) do
    goals
    |> Enum.combinations(2)
    |> Enum.filter(fn [goal1, goal2] -> 
      conflicts?(state, goal1, goal2) 
    end)
  end
end

# MinizinC multigoal optimization
defmodule AriaEngine.MinizinC do
  def optimize_multigoal(state, goals, opts \\ []) do
    case generate_optimization_model(state, goals) do
      {:ok, model} ->
        solve_multigoal_optimization(model, opts)
      {:error, reason} ->
        {:error, "MinizinC optimization failed: #{reason}"}
    end
  end
end
```

## Goal Verification Architecture

### Automatic Verification Tasks

Goal verification tasks are automatically added after goal methods:

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

### Verification Node Types

- **`:verify_goal`** - Verify single goal achievement
- **`:verify_multigoal`** - Verify multigoal achievement
- **Integration with solution tree** - verification nodes tracked like other node types

## Commands System Architecture

### Planning vs Execution Separation

Clear separation between planning-time actions and execution-time commands:

**Planning-Time Actions** (assume success for planning):

```elixir
@action duration: "PT2H", requires_entities: [...]
def cook_meal(state, [meal_type]) do
  # Planning-time logic - assumes success for planning
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} -> {:ok, updated_state}
    {:error, reason} -> {:error, reason}
  end
end
```

**Execution-Time Commands** (handle real-world failures):

```elixir
@command
def cook_meal_command(state, [meal_type]) do
  # Execution-time logic - handles real failures
  case attempt_cooking_with_failure_chance(state, meal_type) do
    {:ok, new_state} -> 
      Logger.info("Command> cook_meal_command succeeded for #{meal_type}")
      {:ok, new_state}
    {:error, reason} -> 
      Logger.warn("Command> cook_meal_command failed: #{reason}")
      {:error, reason}  # Triggers blacklisting and replanning
  end
end
```

### Command Registration

```elixir
# Domain creation with command registration
def create_domain(opts \\ %{}) do
  domain = __MODULE__.create_base_domain()
  
  # Register commands for execution-time behavior
  domain = AriaEngine.Domain.declare_commands(domain, [
    &cook_meal_command/2,
    &gather_ingredients_command/2
  ])
  
  # Initialize blacklist system
  domain = %{domain | blacklist: MapSet.new()}
  
  domain
end
```

## Execution Strategy Framework

### LazyExecutionStrategy Integration

```elixir
defmodule HybridPlanner.Strategies.Default.LazyExecutionStrategy do
  @behaviour HybridPlanner.Strategies.ExecutionStrategy
  
  # Execute complete plan with lazy refinement
  def execute_plan(solution_tree, initial_state, strategies, opts \\ []) do
    domain = Map.get(opts, :domain)
    
    case Plan.Core.plan(domain, initial_state, opts) do
      {:ok, final_state} -> {:ok, final_state}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Execute individual step with state validation
  def execute_step(step, current_state, strategies, opts \\ []) do
    state_strategy = Map.get(strategies, :state_strategy)
    domain = Map.get(opts, :domain)
    
    case step do
      {action_name, args} when is_atom(action_name) ->
        state_strategy.apply_action(current_state, {action_name, args}, domain, opts)
      _ ->
        {:error, "Unknown step format: #{inspect(step)}"}
    end
  end
  
  # Handle execution failures with recovery
  def handle_execution_failure(failure, current_state, strategies, opts \\ []) do
    case failure do
      {:action_failed, action_name, reason} ->
        Logger.warning("Action #{action_name} failed - #{reason}")
        {:ok, current_state}  # Continue with current state
      {:temporal_violation, constraint, reason} ->
        Logger.warning("Temporal violation - #{reason}")
        {:ok, current_state}  # Continue with current state
      _ ->
        {:error, "Cannot recover from failure: #{inspect(failure)}"}
    end
  end
end
```

## Validation Framework Architecture

### Comprehensive Domain Validation

```elixir
defmodule AriaEngine.Domain.Validator do
  @type validation_result :: {:ok, validated_data} | {:error, validation_errors}
  @type validation_error :: %{
    field: String.t(),
    message: String.t(),
    value: any(),
    expected: String.t()
  }
  
  # Main validation entry point
  def validate_domain(domain) do
    with {:ok, _} <- validate_actions(domain),
         {:ok, _} <- validate_methods(domain),
         {:ok, _} <- validate_consistency(domain) do
      {:ok, domain}
    else
      {:error, errors} -> {:error, errors}
    end
  end
  
  # Action metadata validation
  def validate_action_metadata(metadata) do
    validators = [
      &validate_temporal_specification/1,
      &validate_entity_requirements/1,
      &validate_description/1,
      &validate_additional_metadata/1
    ]
    
    run_validators(metadata, validators)
  end
end
```

### Cross-Domain Consistency Validation

```elixir
defmodule AriaEngine.Domain.Validator.Consistency do
  def validate_domain_consistency(domain) do
    validators = [
      &validate_action_method_consistency/1,
      &validate_entity_capability_consistency/1,
      &validate_goal_pattern_consistency/1
    ]
    
    run_validators(domain, validators)
  end
  
  defp validate_action_method_consistency(domain) do
    # Ensure actions and methods don't conflict
    action_names = MapSet.new(Map.keys(domain.actions))
    method_names = MapSet.new(Map.keys(domain.task_methods))
    
    conflicts = MapSet.intersection(action_names, method_names)
    
    case MapSet.size(conflicts) do
      0 -> {:ok, domain}
      _ ->
        conflict_list = MapSet.to_list(conflicts)
        {:error, [%{
          field: "action_method_consistency",
          message: "Actions and methods have conflicting names",
          value: conflict_list,
          expected: "Unique names for actions and methods"
        }]}
    end
  end
end
```

## Tombstoned Features

### Rigid Relations (Redundant)

**Status:** Tombstoned - Redundant with AriaEngine's existing capability system

```elixir
# DON'T USE: Rigid relations (redundant)
@rigid_relations %{
  types: %{"person" => ["alice", "bob"]},
  predicates: %{"can_cook" => [["alice"], ["bob"]]}
}

# USE INSTEAD: Capability system
@action requires_entities: [
  %{type: "agent", capabilities: [:cooking], constraints: %{name: "alice"}}
]
```

**Why Capability System is Superior:**

- **Dynamic validation** - checks current state, not static declarations
- **Constraint support** - quantity, location, status constraints
- **Temporal awareness** - entities can gain/lose capabilities over time
- **Integration** - works seamlessly with existing AriaEngine infrastructure

### Automatic Multigoal Fallbacks

**Status:** Tombstoned - Violates pure GTPyhop design philosophy

**Removed automatic fallbacks** that violated pure GTPyhop design:

- No automatic `split_multigoal` when domain methods fail
- No automatic MinizinC optimization without explicit domain choice
- Domain authors must explicitly handle all multigoal scenarios

## Resolved Architectural Problems

### 1. Method Registration Inconsistencies ✅ RESOLVED

**Solution:** Module-based domain pattern with `@action`, `@command`, `@task_method`, `@unigoal_method`, `@multigoal_method` attributes

### 2. Multigoal vs Unigoal Confusion ✅ RESOLVED

**Solution:** Clear hierarchical decomposition with pure GTPyhop multigoal philosophy

**Clear Hierarchy:**

1. **Multigoal methods** → Domain-specific optimization for multiple goals (explicit only)
2. **Unigoal methods** → Decompose single goal into task todos
3. **Task methods** → Decompose tasks into subtasks/actions
4. **Actions** → Change state directly (highest execution priority)

### 3. Domain Module Creation Patterns ✅ RESOLVED

**Solution:** Module-first pattern following Elixir conventions

### 4. Error Handling Standardization ✅ RESOLVED

**Solution:** Standard Elixir tagged tuples with descriptive errors

### 5. Todo/Goal Conversion Complexity ✅ RESOLVED

**Solution:** Unified todo list format with full interchangeability

### 6. Migration Path Gaps ✅ RESOLVED

**Solution:** Clear migration guidance with concrete examples

## Success Criteria

- [x] IPyHOP-compatible solution tree structure implemented
- [x] Corrected `run_lazy_refineahead` with interleaved planning/execution
- [x] Pure GTPyhop multigoal philosophy (no automatic fallbacks)
- [x] Comprehensive blacklist system with intelligent backtracking
- [x] Goal verification tasks with automatic verification
- [x] Commands system for execution-time behavior
- [x] Validation framework for comprehensive domain validation
- [x] All architectural inconsistencies resolved

## Related ADRs

- **ADR-131**: Core Specification (parent ADR)
- **ADR-132**: Technical Implementation (implementation details)
- **ADR-134**: Developer Guide (usage examples)

## Implementation Status

**Status:** Active - IPyHOP standardization under ongoing refinement

**Architecture:** IPyHOP-compatible with pure GTPyhop multigoal philosophy

**Timeline:** Available immediately for domain development

**Compatibility:** Full backward compatibility with existing capability system
