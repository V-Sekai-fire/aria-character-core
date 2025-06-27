# R25W141BE8A: Architecture & Standards - IPyHOP Integration and System Design

<!-- @adr_serial R25W141BE8A -->

**Status:** Active
**Date:** 2025-06-25
**Priority:** HIGH
**Parent ADR:** R25W1398085 (Core Specification)

## Overview

**Current State**: Multiple architectural inconsistencies affecting planner usability
**Target State**: IPyHOP-compatible planner architecture with pure GTPyhop multigoal philosophy

## Why This Architecture Exists

### Problems That Planning Solves

The planning architecture in AriaEngine exists to solve problems that would be nightmarish to code with normal imperative programming. Here's why we need this "weird" approach:

**Problem 1: Multi-Agent Coordination**

```elixir
# Imperative nightmare: 3 chefs preparing different courses
@spec coordinate_dinner_prep() :: term()
def coordinate_dinner_prep() do
  if chef1_available?() and chef2_available?() and chef3_available?() do
    if appetizer_ingredients_ready?() and main_ingredients_ready?() and dessert_ingredients_ready?() do
      # But wait - what if chef1 needs the oven that chef2 is using?
      # And chef3 needs prep space that chef1 is occupying?
      # And the appetizer must finish before main course starts?
      # This quickly becomes impossible to manage...
    end
  end
end

# Planning solution: Describe capabilities and constraints
@action duration: "PT45M", requires_entities: [
  %{type: "chef", capabilities: [:appetizer_prep]},
  %{type: "prep_station", capabilities: [:workspace]}
]
@spec prepare_appetizer(AriaState.t(), [String.t()]) :: AriaState.t()
def prepare_appetizer(state, [dish_type]) do
  # Just describe the state change - planner handles coordination
end
```

**Problem 2: Temporal Constraint Satisfaction**

```elixir
# Imperative nightmare: "Dinner ready by 7pm, but prep takes 3 hours, 
# chef has meeting 2-4pm, oven shared with bread baking 5-6pm"
# Try coding all those constraints with if/else statements!

# Planning solution: Declare constraints, let solver figure it out
@action duration: "PT3H", 
        requires_entities: [%{type: "chef", capabilities: [:cooking]}]
@spec prepare_dinner(AriaState.t(), [String.t()]) :: AriaState.t()
def prepare_dinner(state, [meal_type]) do
  # Planner automatically schedules around meetings and oven conflicts
end
```

**Problem 3: Dynamic Replanning**

```elixir
# Imperative nightmare: "Oven broke, find alternative cooking method,
# reschedule everything, notify affected parties, update timelines"

# Planning solution: Automatic failure recovery
# When oven action fails, planner:
# 1. Blacklists oven-based actions
# 2. Finds alternative cooking methods (stovetop, grill)
# 3. Replans entire schedule automatically
# 4. Continues execution with new plan
```

### Why Entity Requirements Enable This Magic

The `requires_entities` metadata isn't just documentation - it's the key to intelligent search:

```elixir
@action requires_entities: [
  %{type: "chef", capabilities: [:cooking]},
  %{type: "oven", capabilities: [:heating]}
]
```

This tells the planner:

- **Resource conflicts**: "Chef can't cook two things simultaneously"
- **Capability matching**: "Only entities with :cooking capability can do this"
- **Availability checking**: "Don't plan this if chef is in meeting"
- **Failure recovery**: "If oven breaks, find alternative heating source"

### The Power of Declarative Constraints

Instead of writing complex scheduling logic, you declare what you need:

```elixir
# Multi-agent cooking scenario
@action duration: "PT2H", requires_entities: [
  %{type: "head_chef", capabilities: [:cooking, :supervision]},
  %{type: "sous_chef", capabilities: [:prep_work]},
  %{type: "oven", capabilities: [:heating, :baking]},
  %{type: "prep_station", capabilities: [:workspace]}
]
@spec collaborative_cooking(AriaState.t(), [String.t()]) :: AriaState.t()
def collaborative_cooking(state, [meal_type]) do
  # Planner automatically:
  # - Finds available chef and sous chef
  # - Reserves oven for 2-hour window
  # - Allocates prep station workspace
  # - Ensures no resource conflicts
  # - Handles temporal dependencies
end
```

The planner handles all the complexity you'd otherwise need to code manually: resource allocation, conflict detection, temporal scheduling, and failure recovery.

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

### Temporal Condition Integration

Solution tree supports temporal conditions with mixed todo types:

```elixir
defmodule AriaEngine.TemporalSolutionTree do
  @spec process_temporal_conditions(AriaEngine.SolutionTree.t(), map(), String.t()) :: {:ok, AriaEngine.SolutionTree.t()} | {:error, String.t()}
  def process_temporal_conditions(tree, durative_action, condition_type) do
    conditions = get_conditions_for_type(durative_action, condition_type)
    
    # Process mixed todo types in temporal conditions
    Enum.reduce_while(conditions, {:ok, tree}, fn condition, {:ok, current_tree} ->
      case process_temporal_todo_item(condition, current_tree, condition_type) do
        {:ok, updated_tree} -> {:cont, {:ok, updated_tree}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  @spec process_temporal_todo_item(term(), AriaEngine.SolutionTree.t(), String.t()) :: {:ok, AriaEngine.SolutionTree.t()} | {:error, String.t()}
  defp process_temporal_todo_item(todo_item, tree, condition_type) do
    case todo_item do
      # Goals: Direct state validation
      {predicate, subject, value} when is_binary(predicate) ->
        validate_goal_in_tree(tree, {predicate, subject, value}, condition_type)
        
      # Tasks: Add task nodes to solution tree
      {task_name, args} when is_atom(task_name) ->
        add_temporal_task_node(tree, {task_name, args}, condition_type)
        
      # Actions: Add action nodes to solution tree
      {action_name, args} when is_atom(action_name) ->
        add_temporal_action_node(tree, {action_name, args}, condition_type)
        
      # Multigoals: Add multigoal nodes to solution tree
      multigoal when is_list(multigoal) ->
        add_temporal_multigoal_node(tree, multigoal, condition_type)
    end
  end
  
  @spec add_temporal_task_node(AriaEngine.SolutionTree.t(), {atom(), list()}, String.t()) :: {:ok, AriaEngine.SolutionTree.t()}
  defp add_temporal_task_node(tree, {task_name, args}, condition_type) do
    node_id = SolutionTree.next_node_id(tree)
    
    node_data = %{
      type: :task,
      info: {task_name, args},
      status: :open,
      temporal_context: condition_type,
      created_at: System.system_time(:millisecond)
    }
    
    updated_tree = SolutionTree.add_node(tree, node_id, node_data)
    {:ok, updated_tree}
  end
  
  @spec add_temporal_multigoal_node(AriaEngine.SolutionTree.t(), [term()], String.t()) :: {:ok, AriaEngine.SolutionTree.t()}
  defp add_temporal_multigoal_node(tree, multigoal, condition_type) do
    node_id = SolutionTree.next_node_id(tree)
    
    node_data = %{
      type: :multigoal,
      info: multigoal,
      status: :open,
      temporal_context: condition_type,
      simultaneous_requirement: true,  # All goals must be true simultaneously
      created_at: System.system_time(:millisecond)
    }
    
    updated_tree = SolutionTree.add_node(tree, node_id, node_data)
    {:ok, updated_tree}
  end
end
```

### Corrected `run_lazy_refineahead`

True interleaved planning and execution with action priority:

```elixir
defmodule AriaEngine.LazyRefineahead do
  @spec run_lazy_refineahead(AriaEngine.Domain.t(), AriaState.t(), [term()], keyword()) :: {:ok, AriaState.t()} | {:error, String.t()}
  def run_lazy_refineahead(domain, initial_state, todo_list, opts \\ []) do
    # Initialize solution tree
    solution_tree = SolutionTree.new(todo_list)
    
    # Main refinement loop with action priority
    refinement_loop(domain, initial_state, solution_tree, 0, opts)
  end
  
  @spec find_next_open_node_with_action_priority(AriaEngine.SolutionTree.t(), non_neg_integer()) :: {:ok, non_neg_integer()} | nil
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
@spec execute_action_node(AriaEngine.Domain.t(), AriaState.t(), AriaEngine.SolutionTree.t(), non_neg_integer(), keyword()) :: {:ok, AriaState.t(), AriaEngine.SolutionTree.t()} | {:backtrack, non_neg_integer(), AriaEngine.SolutionTree.t()}
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
  @spec find_backtrack_point_with_blacklist_guidance(AriaEngine.SolutionTree.t(), non_neg_integer()) :: {:ok, non_neg_integer()} | {:error, :no_viable_backtrack_points}
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
  @spec resolve_multigoal(AriaEngine.Domain.t(), AriaState.t(), [term()]) :: {:ok, [term()]} | {:error, String.t()}
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
  @spec split_multigoal(AriaState.t(), [term()]) :: {:ok, [term()]} | {:error, String.t()}
  def split_multigoal(state, goals) do
    goals
    |> Enum.map(fn goal -> create_unigoal_task(goal) end)
    |> validate_goal_dependencies(state)
  end
  
  # Goal conflict analysis
  @spec analyze_goal_conflicts(AriaState.t(), [term()]) :: [term()]
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
  @spec optimize_multigoal(AriaState.t(), [term()], keyword()) :: {:ok, term()} | {:error, String.t()}
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
@spec refine_goal_node(AriaEngine.Domain.t(), AriaState.t(), AriaEngine.SolutionTree.t(), non_neg_integer(), keyword()) :: {:ok, AriaState.t(), AriaEngine.SolutionTree.t()} | {:error, String.t()}
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
@action duration: "PT2H",
        requires_entities: [
          %{type: "chef", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]}
        ]
@spec cook_meal(AriaState.t(), [String.t()]) :: AriaState.t()
def cook_meal(state, [meal_type]) do
  # CORRECT: Pure state transformation, planner already validated requirements
  state
  |> AriaState.RelationalState.set_fact("meal_status", meal_type, "cooking")
  |> AriaState.RelationalState.set_fact("chef_status", "chef_1", "busy")
end
```

**Execution-Time Commands** (handle real-world failures):

```elixir
@command
@spec cook_meal_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, String.t()}
def cook_meal_command(state, [meal_type]) do
  # Execution-time logic - handles real failures
  case attempt_cooking_with_failure_chance(state, meal_type) do
    {:ok, new_state} -> 
      Logger.info("cook_meal_command succeeded for #{meal_type}")
      {:ok, new_state}
    {:error, reason} ->
      Logger.warn("cook_meal_command failed: #{reason}")
      {:error, reason}  # Triggers blacklisting and replanning
  end
end
```

### Command Registration

```elixir
# Commands use @command attributes (unified pattern)
@command
@spec cook_meal_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, String.t()}
def cook_meal_command(state, [meal_type]) do
  # Execution-time logic - handles real failures
  case attempt_cooking_with_failure_chance(state, meal_type) do
    {:ok, new_state} -> 
      Logger.info("cook_meal_command succeeded for #{meal_type}")
      {:ok, new_state}
    {:error, reason} ->
      Logger.warn("cook_meal_command failed: #{reason}")
      {:error, reason}  # Triggers blacklisting and replanning
  end
end

@command
@spec gather_ingredients_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, String.t()}
def gather_ingredients_command(state, [task_name]) do
  # Execution-time logic with failure handling
  case attempt_gathering_with_failure_chance(state, task_name) do
    {:ok, new_state} -> 
      Logger.info("gather_ingredients_command succeeded")
      {:ok, new_state}
    {:error, reason} -> 
      Logger.warn("gather_ingredients_command failed: #{reason}")
      {:error, reason}
  end
end

# Domain creation follows module-based pattern
@spec create_domain(map()) :: AriaEngine.Domain.t()
def create_domain(opts \\ %{}) do
  domain = __MODULE__.create_base_domain()
  
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
  @spec execute_plan(AriaEngine.SolutionTree.t(), AriaState.t(), map(), keyword()) :: {:ok, AriaState.t()} | {:error, String.t()}
  def execute_plan(solution_tree, initial_state, strategies, opts \\ []) do
    domain = Map.get(opts, :domain)
    
    case Plan.Core.plan(domain, initial_state, opts) do
      {:ok, final_state} -> {:ok, final_state}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Execute individual step with state validation
  @spec execute_step(term(), AriaState.t(), map(), keyword()) :: {:ok, AriaState.t()} | {:error, String.t()}
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
  @spec handle_execution_failure(term(), AriaState.t(), map(), keyword()) :: {:ok, AriaState.t()} | {:error, String.t()}
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

### Todo List Optimization Framework

Multiple todo execution strategies with MinZinC optimization selection:

```elixir
defmodule AriaEngine.TodoOptimization do
  @spec optimize_todo_execution(AriaEngine.Domain.t(), AriaState.t(), [AriaEngine.todo_item()], keyword()) :: {:ok, [AriaEngine.todo_item()]} | {:error, String.t()}
  def optimize_todo_execution(domain, state, todo_list, opts \\ []) do
    # Get all available multitodo methods for this todo list
    available_methods = Domain.get_multitodo_methods(domain, todo_list)
    
    case available_methods do
      [] ->
        # No optimization methods available - use default sequential execution
        {:ok, todo_list}
        
      methods ->
        # Let MinZinC choose optimal strategy based on optimization criteria
        case MinizinC.optimize_todo_strategy(state, todo_list, methods, opts) do
          {:ok, optimized_todo_list} -> {:ok, optimized_todo_list}
          {:error, reason} -> 
            Logger.warning("Todo optimization failed: #{reason}, using default")
            {:ok, todo_list}
        end
    end
  end
end

# Built-in utilities available for explicit use by domain authors
defmodule AriaEngine.TodoExecution do
  # Basic todo execution utility (analog to split_multigoal)
  @spec sequential_todo_execution(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def sequential_todo_execution(_state, todo_list) do
    # Default strategy - no reordering, just return as-is
    # Analog to split_multigoal for todo lists
    todo_list
  end
end

# Example multitodo methods in domain
defmodule ExampleDomain do
  use AriaEngine.Domain
  
  # Strategy 1: Sequential execution (default/basic - analog to split_multigoal)
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Default sequential order - no optimization (like split_multigoal)
    AriaEngine.TodoExecution.sequential_todo_execution(state, todo_list)
  end
  
  # Strategy 2: Resource-optimized reordering
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Group todos by required resources to minimize context switching
    todo_list
    |> group_by_resource_requirements(state)
    |> flatten_optimized_groups()
  end
  
  # Strategy 3: Makespan-optimized reordering
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Reorder to minimize total execution time
    todo_list
    |> calculate_execution_times(state)
    |> sort_by_critical_path()
  end
  
  # Strategy 4: Parallelism-optimized reordering
  @multitodo_method
  @spec execute_todo_list(AriaState.t(), [AriaEngine.todo_item()]) :: [AriaEngine.todo_item()]
  def execute_todo_list(state, todo_list) do
    # Reorder to maximize parallel execution opportunities
    todo_list
    |> analyze_dependencies(state)
    |> reorder_for_parallelism()
  end
  
  # Helper functions for optimization strategies
  @spec group_by_resource_requirements([AriaEngine.todo_item()], AriaState.t()) :: [[AriaEngine.todo_item()]]
  defp group_by_resource_requirements(todo_list, state) do
    # Implementation: Group todos by required entity types/capabilities
  end
  
  @spec calculate_execution_times([AriaEngine.todo_item()], AriaState.t()) :: [{AriaEngine.todo_item(), non_neg_integer()}]
  defp calculate_execution_times(todo_list, state) do
    # Implementation: Calculate estimated execution time for each todo
  end
  
  @spec analyze_dependencies([AriaEngine.todo_item()], AriaState.t()) :: %{AriaEngine.todo_item() => [AriaEngine.todo_item()]}
  defp analyze_dependencies(todo_list, state) do
    # Implementation: Analyze dependencies between todos
  end
end
```

**Todo Optimization Integration with MinZinC:**

```elixir
defmodule AriaEngine.MinizinC.TodoOptimizer do
  @spec optimize_todo_strategy(AriaState.t(), [AriaEngine.todo_item()], [function()], keyword()) :: {:ok, [AriaEngine.todo_item()]} | {:error, String.t()}
  def optimize_todo_strategy(state, todo_list, available_methods, opts \\ []) do
    # Generate optimization model for todo execution strategies
    case generate_todo_optimization_model(state, todo_list, available_methods) do
      {:ok, model} ->
        solve_todo_optimization(model, opts)
      {:error, reason} ->
        {:error, "Todo optimization model generation failed: #{reason}"}
    end
  end
  
  @spec generate_todo_optimization_model(AriaState.t(), [AriaEngine.todo_item()], [function()]) :: {:ok, String.t()} | {:error, String.t()}
  defp generate_todo_optimization_model(state, todo_list, methods) do
    # Generate MinZinC model that evaluates different todo execution strategies
    # Based on resource utilization, makespan, parallelism potential, etc.
    model = """
    % Todo List Optimization Model
    include "globals.mzn";
    
    % Strategy selection variables
    var 1..#{length(methods)}: selected_strategy;
    
    % Optimization objectives
    var int: makespan;
    var float: resource_efficiency;
    var int: parallelism_score;
    
    % Constraints based on current state and todo requirements
    #{generate_todo_constraints(state, todo_list)}
    
    % Objective: Minimize makespan while maximizing resource efficiency
    solve minimize makespan + (1.0 - resource_efficiency) * 100;
    """
    
    {:ok, model}
  end
end
```

**Benefits of Todo List Optimization:**

- **Resource efficiency** - Group todos by required resources to minimize context switching
- **Makespan minimization** - Reorder todos to minimize total execution time  
- **Parallelism maximization** - Identify todos that can be executed in parallel
- **Automatic strategy selection** - MinZinC chooses optimal strategy based on current state
- **Consistent with goal optimization** - Follows same pattern as existing goal optimization methods

## Validation Framework Architecture

### Comprehensive Domain Validation (Planning-Time Only)

**CRITICAL:** All validation occurs at planning time. Actions assume preconditions are met.

```elixir
defmodule AriaEngine.Domain.Validator do
  @type validation_result :: {:ok, validated_data} | {:error, validation_errors}
  @type validation_error :: %{
    field: String.t(),
    message: String.t(),
    value: any(),
    expected: String.t()
  }
  
  # Main validation entry point (planning-time)
  @spec validate_domain(AriaEngine.Domain.t()) :: {:ok, AriaEngine.Domain.t()} | {:error, [validation_error()]}
  def validate_domain(domain) do
    with {:ok, _} <- validate_actions(domain),
         {:ok, _} <- validate_methods(domain),
         {:ok, _} <- validate_consistency(domain) do
      {:ok, domain}
    else
      {:error, errors} -> {:error, errors}
    end
  end
  
  # Action metadata validation (planning-time)
  @spec validate_action_metadata(map()) :: validation_result()
  def validate_action_metadata(metadata) do
    validators = [
      &validate_temporal_specification/1,
      &validate_entity_requirements/1,
      &validate_description/1,
      &validate_additional_metadata/1
    ]
    
    run_validators(metadata, validators)
  end
  
  # Planner validates requirements before action selection
  @spec validate_action_preconditions(AriaState.t(), map()) :: {:ok, [String.t()]} | {:error, String.t()}
  def validate_action_preconditions(state, action_metadata) do
    case Map.get(action_metadata, :requires_entities, []) do
      entities when is_list(entities) ->
        AriaEngine.Planner.EntityValidator.validate_action_requirements(state, action_metadata)
      invalid ->
        {:error, "Invalid entity requirements format"}
    end
  end
end
```

**❌ TOMBSTONED: Validation within action functions**

Actions must focus purely on state transformation and assume the planner has validated all preconditions.

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
@spec method_name(AriaState.t(), AriaEngine.multigoal()) :: {:ok, [AriaEngine.todo_item()]}
def method_name(state, multigoal) do
  # Multigoal handling logic
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

### Cross-Domain Consistency Validation

```elixir
defmodule AriaEngine.Domain.Validator.Consistency do
  @spec validate_domain_consistency(AriaEngine.Domain.t()) :: {:ok, AriaEngine.Domain.t()} | {:error, [map()]}
  def validate_domain_consistency(domain) do
    validators = [
      &validate_action_method_consistency/1,
      &validate_entity_capability_consistency/1,
      &validate_goal_pattern_consistency/1
    ]
    
    run_validators(domain, validators)
  end
  
  @spec validate_action_method_consistency(AriaEngine.Domain.t()) :: {:ok, AriaEngine.Domain.t()} | {:error, [map()]}
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

### Additional Unstated Known Knowns (Explicitly Tombstoned)

**Status:** Tomb
