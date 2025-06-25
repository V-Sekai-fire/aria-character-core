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

### ✅ Manual Multigoal Methods (Built-in Utilities Available)

**Status:** Implemented - Built-in `split_multigoal/2` utility available but ❌ TOMBSTONE automatic usage

**Current Implementation Status:** AriaEngine includes built-in multigoal utilities through `Multigoal.split_multigoal/2` but requires explicit domain method registration - no automatic multigoal splitting.

**Available Utilities:**

- **`Multigoal.split_multigoal/2`** - Utility function for basic goal decomposition
- **MinizinC optimization** - Constraint-based multigoal optimization
- **Goal dependency analysis** - Analyze goal relationships and conflicts
- **Manual method registration** - Domain authors must explicitly register multigoal methods

**Usage Pattern (Explicit Registration Required):**

```elixir
# ALREADY IMPLEMENTED: Manual multigoal method registration
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  # EXPLICIT multigoal method registration (REQUIRED)
  @multigoal_method goal_pattern: :cooking_workflow
  def handle_cooking_multigoal(state, multigoal) do
    # Domain author EXPLICITLY chooses strategy
    case analyze_cooking_goals(state, multigoal.goals) do
      {:complex_optimization_needed, goals} ->
        # Domain author chooses MinizinC optimization
        AriaEngine.MinizinC.optimize_multigoal(state, goals)
        
      {:simple_decomposition, goals} ->
        # Domain author chooses basic splitting
        AriaEngine.Multigoal.split_multigoal(state, goals)
        
      {:sequential_execution, goals} ->
        # Domain author chooses custom sequential approach
        create_sequential_plan(state, goals)
    end
  end
  
  # EXPLICIT multigoal method for location goals
  @multigoal_method goal_pattern: :location_workflow
  def handle_location_multigoal(state, multigoal) do
    # Custom location optimization logic
    optimize_travel_routes(state, multigoal.goals)
  end
end

# ❌ TOMBSTONED: Automatic multigoal splitting without explicit methods
# AriaEngine will NOT automatically call split_multigoal/2
# Domain authors MUST register explicit multigoal methods
```

**Built-in Utility Functions (Available for Domain Authors):**

```elixir
# ALREADY IMPLEMENTED: Multigoal utility functions
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
  
  # Goal dependency analysis
  def analyze_goal_dependencies(state, goals) do
    goals
    |> build_dependency_graph(state)
    |> topological_sort()
  end
end

# ALREADY IMPLEMENTED: MinizinC multigoal optimization
defmodule AriaEngine.MinizinC do
  def optimize_multigoal(state, goals, opts \\ []) do
    # Constraint-based optimization for complex multigoals
    case generate_optimization_model(state, goals) do
      {:ok, model} ->
        solve_multigoal_optimization(model, opts)
      {:error, reason} ->
        {:error, "MinizinC optimization failed: #{reason}"}
    end
  end
end
```

**Key Principles:**

- **✅ Built-in utilities available**: `split_multigoal/2`, MinizinC optimization, dependency analysis
- **❌ TOMBSTONE automatic usage**: No automatic fallbacks - domain authors must explicitly choose
- **✅ Explicit method registration**: All multigoal handling requires `@multigoal_method` registration
- **✅ Strategy flexibility**: Domain authors choose appropriate strategy for each multigoal pattern

### ✅ Blacklisting Infrastructure (Plan.Blacklisting with Solution Tree)

**Status:** Implemented - Comprehensive blacklisting system with solution tree integration

**Current Implementation Status:** AriaEngine includes a sophisticated blacklisting system through Plan.Blacklisting that integrates with the solution tree to prevent repeated failures and enable intelligent backtracking.

**Available Blacklisting Features:**

- **Failed action prevention** - Actions that fail during execution get automatically blacklisted
- **Solution tree integration** - Blacklist state maintained within solution tree structure
- **Persistent blacklisting** - Blacklist persists across planning sessions and backtracking
- **Intelligent backtracking** - Blacklist guides backtracking to avoid repeated failures
- **Blacklist scoping** - Different blacklist scopes for different planning contexts

**Current Implementation Structure:**

```elixir
# ALREADY IMPLEMENTED: Plan.Blacklisting with solution tree integration
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

# ALREADY IMPLEMENTED: Solution tree with integrated blacklisting
defmodule AriaEngine.SolutionTree do
  defstruct [
    :nodes,           # %{node_id => node_data}
    :edges,           # %{parent_id => [child_ids]}
    :root_id,         # Root node ID
    :next_id,         # Next available ID
    :blacklist,       # Plan.Blacklisting struct
    :blacklist_history # History of blacklist changes
  ]
  
  # Blacklist management functions
  def blacklist_action(tree, action, scope \\ :session) do
    entry = {action, System.system_time(:millisecond)}
    updated_blacklist = Plan.Blacklisting.add_entry(tree.blacklist, entry, scope)
    
    %{tree | 
      blacklist: updated_blacklist,
      blacklist_history: [entry | tree.blacklist_history]
    }
  end
  
  def is_blacklisted?(tree, action) do
    Plan.Blacklisting.contains?(tree.blacklist, action)
  end
  
  def clear_blacklist(tree, scope \\ :session) do
    updated_blacklist = Plan.Blacklisting.clear_scope(tree.blacklist, scope)
    %{tree | blacklist: updated_blacklist}
  end
end
```

**Integration with Action Execution:**

```elixir
# ALREADY IMPLEMENTED: Blacklist checking during action execution
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
        Logger.warning("Action #{action_name} failed: #{reason}")
        
        # Automatically blacklist failed action
        updated_tree = tree
        |> SolutionTree.blacklist_action({action_name, args}, :session)
        |> SolutionTree.mark_failed(node_id)
        
        {:backtrack, find_backtrack_point(tree, node_id), updated_tree}
    end
  end
end
```

**Intelligent Backtracking with Blacklist Guidance:**

```elixir
# ALREADY IMPLEMENTED: Blacklist-guided backtracking
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
  
  defp has_non_blacklisted_alternatives?(tree, node_id) do
    node = SolutionTree.get_node(tree, node_id)
    
    case node.type do
      :task ->
        # Check if task has non-blacklisted method alternatives
        alternative_methods = get_alternative_task_methods(tree, node_id)
        Enum.any?(alternative_methods, fn method ->
          not SolutionTree.is_blacklisted?(tree, method)
        end)
        
      :goal ->
        # Check if goal has non-blacklisted unigoal method alternatives
        alternative_methods = get_alternative_unigoal_methods(tree, node_id)
        Enum.any?(alternative_methods, fn method ->
          not SolutionTree.is_blacklisted?(tree, method)
        end)
        
      _ ->
        false
    end
  end
end
```

**Blacklist Scoping and Management:**

```elixir
# ALREADY IMPLEMENTED: Blacklist scope management
defmodule Plan.Blacklisting do
  # Add entry with specific scope
  def add_entry(blacklist, {action, timestamp}, scope) do
    entry = %{
      action: action,
      scope: scope,
      created_at: timestamp,
      failure_count: get_failure_count(blacklist, action) + 1
    }
    
    %{blacklist | entries: MapSet.put(blacklist.entries, entry)}
  end
  
  # Clear blacklist entries by scope
  def clear_scope(blacklist, scope) do
    remaining_entries = Enum.filter(blacklist.entries, fn entry ->
      entry.scope != scope
    end)
    
    %{blacklist | entries: MapSet.new(remaining_entries)}
  end
  
  # Check if action is blacklisted in any relevant scope
  def contains?(blacklist, action) do
    Enum.any?(blacklist.entries, fn entry ->
      entry.action == action and scope_is_active?(entry.scope)
    end)
  end
end
```

**Benefits of Blacklisting Infrastructure:**

- **Prevents infinite loops**: Failed actions don't get repeatedly attempted
- **Intelligent backtracking**: Guides backtracking to points with viable alternatives
- **Performance optimization**: Avoids wasted computation on known failures
- **Solution tree integration**: Blacklist state maintained consistently with planning state
- **Flexible scoping**: Different blacklist scopes for different planning contexts

### ✅ Validation Framework (Comprehensive Domain Validation)

**Status:** Implemented - Comprehensive domain validation system with detailed error reporting

**Current Implementation Status:** AriaEngine includes a comprehensive validation framework through Domain.Validator that provides detailed validation for all domain components including actions, methods, metadata, and entity requirements.

**Available Validation Features:**

- **Action metadata validation** - Comprehensive validation of action metadata structure and types
- **Method signature validation** - Validation of task methods, unigoal methods, and multigoal methods
- **Entity requirement validation** - Validation of entity types, capabilities, and constraints
- **Temporal specification validation** - ISO8601 duration and datetime validation with Timex
- **Domain consistency validation** - Cross-validation of domain components for consistency

**Current Implementation Structure:**

```elixir
# ALREADY IMPLEMENTED: Comprehensive domain validation framework
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

**Temporal Specification Validation:**

```elixir
# ALREADY IMPLEMENTED: Temporal validation with Timex integration
defmodule AriaEngine.Domain.Validator.Temporal do
  def validate_temporal_specification(metadata) do
    case extract_temporal_fields(metadata) do
      %{duration: duration} when is_binary(duration) ->
        validate_iso8601_duration(duration)
        
      %{start: start_time, end: end_time} ->
        with {:ok, _} <- validate_iso8601_datetime(start_time, "start"),
             {:ok, _} <- validate_iso8601_datetime(end_time, "end"),
             :ok <- validate_start_before_end(start_time, end_time) do
          {:ok, %{start: start_time, end: end_time}}
        end
        
      %{start: start_time} ->
        validate_iso8601_datetime(start_time, "start")
        
      %{end: end_time} ->
        validate_iso8601_datetime(end_time, "end")
        
      %{} ->
        # No temporal specification - default to zero duration
        {:ok, %{duration: "PT0S"}}
        
      invalid ->
        {:error, [%{
          field: "temporal_specification",
          message: "Invalid temporal specification format",
          value: invalid,
          expected: "duration string OR start/end datetimes"
        }]}
    end
  end
  
  defp validate_iso8601_duration(duration_string) do
    case Timex.Duration.parse(duration_string) do
      {:ok, duration} ->
        {:ok, duration}
      {:error, reason} ->
        {:error, [%{
          field: "duration",
          message: "Invalid ISO 8601 duration: #{reason}",
          value: duration_string,
          expected: "ISO 8601 duration format (e.g., 'PT2H', 'PT30M')"
        }]}
    end
  end
  
  defp validate_iso8601_datetime(datetime_string, field_name) do
    case Timex.parse(datetime_string, "{ISO:Extended}") do
      {:ok, datetime} ->
        {:ok, datetime}
      {:error, reason} ->
        {:error, [%{
          field: field_name,
          message: "Invalid ISO 8601 datetime: #{reason}",
          value: datetime_string,
          expected: "ISO 8601 datetime format (e.g., '2025-06-22T10:00:00Z')"
        }]}
    end
  end
end
```

**Entity Requirements Validation:**

```elixir
# ALREADY IMPLEMENTED: Entity requirements validation
defmodule AriaEngine.Domain.Validator.Entities do
  def validate_entity_requirements(metadata) do
    case Map.get(metadata, :requires_entities, []) do
      entities when is_list(entities) ->
        validate_entity_list(entities)
      invalid ->
        {:error, [%{
          field: "requires_entities",
          message: "Entity requirements must be a list",
          value: invalid,
          expected: "List of entity requirement maps"
        }]}
    end
  end
  
  defp validate_entity_list(entities) do
    entities
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {entity, index}, {:ok, acc} ->
      case validate_single_entity(entity, index) do
        {:ok, validated_entity} -> {:cont, {:ok, [validated_entity | acc]}}
        {:error, errors} -> {:halt, {:error, errors}}
      end
    end)
    |> case do
      {:ok, validated_entities} -> {:ok, Enum.reverse(validated_entities)}
      {:error, errors} -> {:error, errors}
    end
  end
  
  defp validate_single_entity(entity, index) do
    with {:ok, type} <- validate_entity_type(entity, index),
         {:ok, capabilities} <- validate_entity_capabilities(entity, index),
         {:ok, constraints} <- validate_entity_constraints(entity, index) do
      {:ok, %{type: type, capabilities: capabilities, constraints: constraints}}
    end
  end
  
  defp validate_entity_type(entity, index) do
    case Map.get(entity, :type) do
      type when is_binary(type) and type != "" ->
        {:ok, type}
      invalid ->
        {:error, [%{
          field: "requires_entities[#{index}].type",
          message: "Entity type must be a non-empty string",
          value: invalid,
          expected: "Non-empty string (e.g., 'agent', 'oven', 'kitchen')"
        }]}
    end
  end
  
  defp validate_entity_capabilities(entity, index) do
    case Map.get(entity, :capabilities, []) do
      capabilities when is_list(capabilities) ->
        validate_capability_list(capabilities, index)
      invalid ->
        {:error, [%{
          field: "requires_entities[#{index}].capabilities",
          message: "Entity capabilities must be a list of atoms",
          value: invalid,
          expected: "List of capability atoms (e.g., [:cooking, :heating])"
        }]}
    end
  end
  
  defp validate_capability_list(capabilities, index) do
    invalid_capabilities = Enum.reject(capabilities, &is_atom/1)
    
    case invalid_capabilities do
      [] -> {:ok, capabilities}
      invalid ->
        {:error, [%{
          field: "requires_entities[#{index}].capabilities",
          message: "All capabilities must be atoms",
          value: invalid,
          expected: "List of atoms only (e.g., [:cooking, :heating, :workspace])"
        }]}
    end
  end
end
```

**Method Signature Validation:**

```elixir
# ALREADY IMPLEMENTED: Method signature validation
defmodule AriaEngine.Domain.Validator.Methods do
  def validate_method_signatures(domain) do
    validators = [
      &validate_task_methods/1,
      &validate_unigoal_methods/1,
      &validate_multigoal_methods/1,
      &validate_action_functions/1
    ]
    
    run_validators(domain, validators)
  end
  
  defp validate_task_methods(domain) do
    domain.task_methods
    |> Enum.reduce_while({:ok, []}, fn {name, function}, {:ok, acc} ->
      case validate_method_signature(function, :task_method, name) do
        {:ok, validated} -> {:cont, {:ok, [validated | acc]}}
        {:error, errors} -> {:halt, {:error, errors}}
      end
    end)
  end
  
  defp validate_method_signature(function, method_type, name) do
    case Function.info(function, :arity) do
      {:arity, 2} ->
        # Validate that function returns proper format
        validate_method_return_format(function, method_type, name)
      {:arity, arity} ->
        {:error, [%{
          field: "#{method_type}_signature",
          message: "Method must have arity 2 (state, args)",
          value: "arity #{arity}",
          expected: "Function with arity 2: (state, args) -> result"
        }]}
    end
  end
  
  defp validate_method_return_format(function, method_type, name) do
    # This would involve more complex validation of return types
    # For now, we assume proper format and validate at runtime
    {:ok, %{name: name, function: function, type: method_type}}
  end
end
```

**Domain Consistency Validation:**

```elixir
# ALREADY IMPLEMENTED: Cross-domain consistency validation
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
  
  defp validate_entity_capability_consistency(domain) do
    # Validate that all required capabilities are defined somewhere
    all_required_capabilities = extract_all_required_capabilities(domain)
    defined_capabilities = extract_defined_capabilities(domain)
    
    undefined_capabilities = MapSet.difference(all_required_capabilities, defined_capabilities)
    
    case MapSet.size(undefined_capabilities) do
      0 -> {:ok, domain}
      _ ->
        undefined_list = MapSet.to_list(undefined_capabilities)
        {:error, [%{
          field: "capability_consistency",
          message: "Some required capabilities are not defined",
          value: undefined_list,
          expected: "All required capabilities must be defined in domain"
        }]}
    end
  end
end
```

**Benefits of Validation Framework:**

- **Early error detection**: Catches domain definition errors at compile time or domain creation
- **Detailed error messages**: Provides specific, actionable error messages for developers
- **Comprehensive coverage**: Validates all aspects of domain definition including metadata, methods, and consistency
- **Integration with development workflow**: Works with ExDoc, hot code reloading, and development tools
- **Type safety**: Ensures proper types and formats for all domain components

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
