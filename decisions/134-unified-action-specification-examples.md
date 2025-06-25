# ADR 134: Unified Action Specification Examples

## Status
**Completed** (June 25, 2025) - Final module-based domain pattern with IPyHOP compatibility

## Context

Provides the definitive, corrected module-based domain specification pattern that integrates:
- IPyHOP-compatible features (Solution Tree, Commands, Blacklist)
- Pure GTPyhop multigoal philosophy (no automatic fallbacks)
- AriaEngine conventions (proper naming, capability system)
- Corrected `run_lazy_refineahead` integration

This ADR supersedes all previous action specification patterns and establishes the canonical approach for AriaEngine domain development.

## Final Complete Module-Based Domain Pattern

```elixir
defmodule MyApp.Domains.CookingDomain do
  use AriaEngine.Domain
  
  # Domain metadata
  @domain_name "cooking"
  @description "Cooking and meal preparation domain"
  
  # Actions (planning-time) with capability system
  @action duration: "PT2H", 
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :menu_planning]},
            %{type: "oven", capabilities: [:heating, :baking]},
            %{type: "ingredient", capabilities: [:consumable], 
              constraints: %{quantity: {:min, 2}}}
          ],
          mutual_exclusion: ["kitchen_cleanup"],
          temporal_constraints: [
            {:before, "gather_ingredients"},
            {:during, "kitchen_available"}
          ]
  def cook_meal(state, [meal_type]) do
    case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
      {:ok, entities} ->
        execute_cooking_with_constraints(state, meal_type, entities)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @action duration: "PT30M"
  def gather_ingredients(state, [task_name]) do
    # Planning-time logic for ingredient gathering
    case find_available_ingredients(state, task_name) do
      {:ok, ingredients} ->
        state
        |> StateV2.set_fact("task", "status", "ingredients_gathered")
        |> StateV2.set_fact("task", "ingredients", ingredients)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Commands (execution-time) with failure handling
  @command
  def cook_meal_command(state, [meal_type]) do
    case attempt_cooking_with_failure_chance(state, meal_type) do
      {:ok, new_state} -> 
        Logger.info("Command> cook_meal_command succeeded for #{meal_type}")
        {:ok, new_state}
      {:error, reason} -> 
        Logger.warn("Command> cook_meal_command failed: #{reason}")
        {:error, reason}
    end
  end
  
  @command
  def gather_ingredients_command(state, [task_name]) do
    case attempt_gathering_with_failure_chance(state, task_name) do
      {:ok, new_state} -> 
        Logger.info("Command> gather_ingredients_command succeeded")
        {:ok, new_state}
      {:error, reason} -> 
        Logger.warn("Command> gather_ingredients_command failed: #{reason}")
        {:error, reason}
    end
  end
  
  # Task methods
  @task_method
  def task_prepare_ingredients(state, [task_name]) do
    {:ok, [
      {:gather_ingredients, [task_name]},
      {:wash_ingredients, [task_name]},
      {:verify_ingredients, [task_name]}  # Auto-verification
    ]}
  end
  
  @task_method
  def task_complete_meal(state, [meal_type]) do
    {:ok, [
      {:task_prepare_ingredients, [meal_type]},
      {:cook_meal, [meal_type]},
      {:serve_meal, [meal_type]}
    ]}
  end
  
  # Unigoal methods with automatic verification
  @unigoal_method goal_pattern: {"chef", "location", :any}
  def travel_to_location(state, {"chef", "location", target}) do
    current = StateV2.get_fact(state, "chef", "location")
    if current == target do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:walk_to_location, ["chef", target]},
        {:verify_location, ["chef", target]}  # Auto-verification
      ]}
    end
  end
  
  @unigoal_method goal_pattern: {"chef", "has", :any}
  def acquire_item(state, {"chef", "has", item}) do
    current_items = StateV2.get_fact(state, "chef", "inventory") || []
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
  def handle_general_multigoal(state, multigoal) do
    # Explicit fallback chain implemented by domain author
    case AriaMinizincGoal.optimize_multigoal(state, multigoal) do
      {:ok, plan} -> 
        Logger.debug("MinizinC multigoal optimization succeeded")
        {:ok, plan}
      {:error, _} ->
        # Domain author explicitly chooses split_multigoal
        Logger.debug("MinizinC failed, using split_multigoal")
        AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)
    end
  end
  
  # Domain creation with all IPyHOP features
  def create_domain(opts \\ %{}) do
    domain = __MODULE__.create_base_domain()
    
    # Configure goal verification (IPyHOP feature)
    domain = AriaEngine.Domain.set_verify_goals(domain, Map.get(opts, :verify_goals, true))
    
    # Register commands for execution-time behavior
    domain = AriaEngine.Domain.declare_commands(domain, [
      &cook_meal_command/2,
      &gather_ingredients_command/2
    ])
    
    # Initialize blacklist system
    domain = %{domain | blacklist: MapSet.new()}
    
    # Configure solution tree tracking
    domain = AriaEngine.Domain.enable_solution_tree(domain, true)
    
    domain
  end
  
  # Helper functions for domain logic
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
  
  defp is_cooking_goal?({_subject, predicate, _value}) when predicate in ["meal_status", "cooking_task"], do: true
  defp is_cooking_goal?(_), do: false
  
  defp is_location_goal?({_subject, "location", _value}), do: true
  defp is_location_goal?(_), do: false
end
```

## Key Features

### ✅ Complete IPyHOP Compatibility

**Solution Tree with proper node types:**
- `:task` - Decompose into subtasks/actions
- `:action` - Execute immediately (highest priority)
- `:goal` - Decompose into subgoals
- `:multigoal` - Decompose into individual goals
- `:verify_goal` - Verify goal achievement
- `:verify_multigoal` - Verify multigoal achievement

**Corrected `run_lazy_refineahead` with interleaved planning/execution:**
- True interleaved planning and execution (no separate planning phase)
- Action nodes execute immediately when selected
- Proper backtracking on failure with state restoration

**Action priority over task decomposition in node selection:**
```elixir
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
```

**Replan/Backtracking system with method alternatives:**
- IPyHOP-style failure recovery
- State restoration at backtrack points
- Alternative method exploration

**Blacklist system for failed actions:**
- Failed actions get blacklisted automatically
- Integration with solution tree
- Prevents repeated failures

**Goal verification tasks:**
- Automatic verification after goal methods
- `:verify_goal` and `:verify_multigoal` node types

### ✅ Pure GTPyhop Multigoal Philosophy

**NO automatic fallbacks for multigoals:**
- Domain authors must explicitly define `@multigoal_method` if multigoals are used
- Planning fails if multigoals are encountered without domain methods
- `split_multigoal` and MinizinC available as explicit tools for domain authors

**Example of explicit multigoal handling:**
```elixir
# This will FAIL if no @multigoal_method defined:
multigoal = [
  {"chef", "location", "kitchen"},
  {"chef", "has", "ingredients"}
]

# Only succeeds if domain has explicit @multigoal_method
case AriaEngine.plan(domain, state, [multigoal]) do
  {:ok, plan} -> execute_plan(plan)
  {:error, "No multigoal methods defined"} -> 
    # Domain author must add @multigoal_method
    Logger.error("Domain must define multigoal methods explicitly")
end
```

### ✅ AriaEngine Integration

**Uses existing capability system (no rigid relations needed):**
```elixir
# CORRECT: Use capability system
@action requires_entities: [
  %{type: "agent", capabilities: [:cooking]}
]

# WRONG: Don't use rigid relations (redundant)
@rigid_relations %{
  types: %{"person" => ["alice", "bob"]}
}
```

**Proper Elixir naming conventions:**
- `cook_meal_command/2` instead of `c_cook_meal/2`
- `_command` suffix for execution-time behavior
- Standard Elixir function naming throughout

**Temporal constraints and mutual exclusion:**
- Integration with existing temporal constraint system
- Mutual exclusion enforcement
- Duration validation

**StateV2 compatibility throughout:**
- All state operations use StateV2
- Subject-predicate-value fact structure
- Temporal state queries supported

### 🪦 Tombstoned Features

**Rigid Relations (redundant with capability system):**
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

**Automatic multigoal fallbacks (violates GTPyhop philosophy):**
- No automatic `split_multigoal` when domain methods fail
- No automatic MinizinC optimization without explicit domain choice
- Domain authors must explicitly handle all multigoal scenarios

## Usage Examples

### Planning with Solution Tree
```elixir
domain = MyApp.Domains.CookingDomain.create_domain()

# Planning creates solution tree with proper node types
{:ok, solution_tree, plan} = AriaEngine.plan_with_tree(domain, initial_state, [
  {:cook_meal, ["pasta"]},
  {"chef", "location", "kitchen"}  # Goal
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
  {"chef", "location", "kitchen"},
  {"chef", "has", "ingredients"}
]

case AriaEngine.plan(simple_domain, state, [multigoal]) do
  {:error, "No multigoal methods defined"} -> 
    # Expected - domain must define multigoal methods explicitly
    Logger.error("Domain lacks multigoal support")
end

# Domain WITH explicit multigoal methods - planning succeeds
advanced_domain = MyApp.Domains.CookingDomain.create_domain()

case AriaEngine.plan(advanced_domain, state, [multigoal]) do
  {:ok, plan} -> 
    # Success - domain has explicit @multigoal_method
    execute_plan(plan)
end
```

### Capability-Based Entity Validation
```elixir
# Entities are validated automatically based on capabilities
@action requires_entities: [
  %{type: "agent", capabilities: [:cooking, :menu_planning]},
  %{type: "oven", capabilities: [:heating, :baking]},
  %{type: "ingredient", capabilities: [:consumable], 
    constraints: %{quantity: {:min, 2}}}
]
def cook_meal(state, [meal_type]) do
  # AriaEngine automatically validates:
  # - Agent with cooking AND menu_planning capabilities
  # - Oven with heating AND baking capabilities  
  # - At least 2 consumable ingredients
  
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} -> proceed_with_cooking(state, meal_type, entities)
    {:error, :missing_capabilities} -> {:error, "Required capabilities not available"}
    {:error, :insufficient_quantity} -> {:error, "Not enough ingredients"}
  end
end
```

## Implementation Architecture

### Core System Integration

**Solution Tree Structure:**
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

**Corrected `run_lazy_refineahead` Implementation:**
```elixir
defmodule AriaEngine.LazyRefineahead do
  def run_lazy_refineahead(domain, initial_state, todo_list, opts \\ []) do
    # Initialize solution tree
    solution_tree = SolutionTree.new(todo_list)
    
    # Main refinement loop with action priority
    refinement_loop(domain, initial_state, solution_tree, 0, opts)
  end
  
  defp refinement_loop(domain, state, tree, parent_node_id, opts) do
    case find_next_open_node_with_action_priority(tree, parent_node_id) do
      nil ->
        {:ok, state}  # Planning complete
        
      {:ok, node_id} ->
        case refine_node_with_priority(domain, state, tree, node_id, opts) do
          {:ok, new_state, updated_tree} ->
            refinement_loop(domain, new_state, updated_tree, parent_node_id, opts)
            
          {:backtrack, backtrack_node_id, updated_tree} ->
            refinement_loop(domain, state, updated_tree, backtrack_node_id, opts)
            
          {:error, reason} ->
            {:error, reason}
        end
    end
  end
end
```

**Multigoal Resolution (Pure GTPyhop Style):**
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

## Migration from Previous Patterns

### From Legacy TimelineGraph Pattern
```elixir
# BEFORE: Complex timeline graph setup
timeline_graph = TimelineGraph.new()
{:ok, timeline_graph, _} = TimelineGraph.create_entity(timeline_graph, "chef", "Head Chef", %{})
{:ok, timeline_graph} = TimelineGraph.add_capabilities(timeline_graph, "chef", [:cooking])

# AFTER: Simple entity requirements in action metadata
@action requires_entities: [
  %{type: "chef", capabilities: [:cooking]}
]
def cook_meal(state, [meal_type]) do
  # Implementation
end
```

### From Multiple Action Definition Patterns
```elixir
# BEFORE: Inconsistent patterns
Domain.add_action(:cook, &cook/2)  # No metadata
Domain.add_action(:bake, %DurativeAction{...})  # Complex struct

# AFTER: Unified module-based pattern
@action duration: "PT2H", requires_entities: [...]
def cook_meal(state, [meal_type]) do
  # Implementation
end
```

### From Automatic Multigoal Fallbacks
```elixir
# BEFORE: Automatic fallbacks (violates GTPyhop)
def resolve_multigoal(domain, state, multigoal) do
  case try_domain_methods(domain, state, multigoal) do
    {:error, _} -> AriaEngine.Multigoal.split_multigoal(state, multigoal.goals)  # WRONG
  end
end

# AFTER: Pure GTPyhop style (explicit only)
def resolve_multigoal(domain, state, multigoal) do
  case Domain.get_multigoal_methods(domain, multigoal) do
    [] -> {:error, "No multigoal methods defined"}  # CORRECT
    methods -> try_domain_methods_only(methods, state, multigoal)
  end
end
```

## Related ADRs

- **ADR-131**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-132**: Fix Duration Handling Precision Loss (technical integration)
- **ADR-133**: Planner Standardization Open Problems (completed features)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Completed - Final canonical pattern established
**Usage:** Reference implementation for all new AriaEngine domains
**Timeline:** Available immediately for domain development
**Compatibility:** IPyHOP-compatible with pure GTPyhop multigoal philosophy
