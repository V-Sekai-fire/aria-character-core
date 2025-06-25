# ADR-184: Unified Action Specification Examples

## Status

**Active** - Module-based domain pattern with IPyHOP compatibility under ongoing refinement

## Context

Provides the definitive, corrected module-based domain specification pattern that integrates:

- IPyHOP-compatible features (Solution Tree, Commands, Blacklist)
- Pure GTPyhop multigoal philosophy (no automatic fallbacks)
- AriaEngine conventions (proper naming, capability system)
- Corrected `run_lazy_refineahead` integration

This ADR supersedes all previous action specification patterns and establishes the canonical approach for AriaEngine domain development.

## From Confusion to Clarity

### Common "Wait, What?" Moments

When developers first encounter the planner patterns in ADRs 181-184, several things feel confusing. Here's the journey from confusion to understanding:

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
  state |> State.set_fact("meal_status", meal_type, "ready")
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

## Complete Module-Based Domain Pattern

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
def cook_meal(state, [meal_type]) do
  # CORRECT: Pure state transformation, planner already validated requirements
  state
  |> AriaState.ObjectState.set_fact("meal_status", meal_type, "cooking")
  |> AriaState.ObjectState.set_fact("chef_status", "chef_1", "busy")
  |> AriaState.ObjectState.set_fact("oven_status", "oven_1", "in_use")
end
  
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:shopping]},
            %{type: "market", capabilities: [:ingredient_source]}
          ]
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
        Logger.info("cook_meal_command succeeded for #{meal_type}")
        {:ok, new_state}
      {:error, reason} ->
        Logger.warn("cook_meal_command failed: #{reason}")
        {:error, reason}
    end
  end
  
  @command
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
  
  # Unigoal methods with automatic verification (ADVANCED: Predicate-based registration)
  @unigoal_method predicate: "location"
  def travel_to_location(state, [subject, target]) do
    current = StateV2.get_fact(state, subject, "location")
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
  def acquire_item(state, [subject, item]) do
    current_items = StateV2.get_fact(state, subject, "inventory") || []
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
  
  # Domain creation follows module-based pattern
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

**Constraints field in entity requirements (violates state-based validation principle):**

```elixir
# DON'T USE: Constraints in action metadata (TOMBSTONED)
@action requires_entities: [
  %{type: "ingredient", capabilities: [:consumable], 
    constraints: %{quantity: {:min, 2}}}  # ❌ WRONG - quantities are state fluents
]

# USE INSTEAD: State-based validation
@action requires_entities: [
  %{type: "ingredient", capabilities: [:consumable]}  # ✅ CORRECT - capabilities only
]
def cook_meal(state, [meal_type]) do
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} ->
      # Validate quantities using state queries (CORRECT approach)
      case validate_ingredient_quantities(state, meal_type) do
        {:ok, _} -> execute_cooking_with_constraints(state, meal_type, entities)
        {:error, reason} -> {:error, reason}
      end
    {:error, reason} -> {:error, reason}
  end
end

defp validate_ingredient_quantities(state, meal_type) do
  required_ingredients = get_recipe_requirements(meal_type)
  
  Enum.reduce_while(required_ingredients, {:ok, []}, fn {ingredient, min_qty}, {:ok, acc} ->
    available_qty = StateV2.get_fact(state, ingredient, "quantity") || 0
    
    if available_qty >= min_qty do
      {:cont, {:ok, [ingredient | acc]}}
    else
      {:halt, {:error, "Insufficient #{ingredient}: need #{min_qty}, have #{available_qty}"}}
    end
  end)
end
```

**Why constraints are tombstoned:**

- **Action metadata** should define what capabilities are needed (static requirements)
- **State validation** should check current quantities, availability, and dynamic properties
- **Separation of concerns** - keeps action metadata clean and state queries explicit
- **Temporal awareness** - quantities can change over time, constraints cannot

**Automatic multigoal fallbacks (violates GTPyhop philosophy):**

- No automatic `split_multigoal` when domain methods fail
- No automatic MinizinC optimization without explicit domain choice
- Domain authors must explicitly handle all multigoal scenarios

### Additional Unstated Known Knowns (Explicitly Tombstoned)

**Status:** Tombstoned - Architectural violations that must be prevented

1. **❌ TOMBSTONE: `@command` attributes in domain registration** - Commands are execution-time functions, not domain metadata
2. **❌ TOMBSTONE: Command node types in solution tree** - Only 6 node types allowed: `:task | :action | :goal | :multigoal | :verify_goal | :verify_multigoal`
3. **❌ TOMBSTONE: Mixed goal formats** - ONLY `{subject, predicate, value}` format allowed
4. **❌ TOMBSTONE: Complex state evaluation in actions** - Use direct `State.get_fact/3` queries only
5. **❌ TOMBSTONE: Entity properties in action metadata** - Properties like `max_temp`, `quantity` belong in state
6. **❌ TOMBSTONE: Validation within action functions** - ALL validation is planner responsibility, actions are pure transformations
7. **❌ TOMBSTONE: Old unigoal API patterns** - ONLY predicate-based registration allowed
8. **❌ TOMBSTONE: `quantity` field in action metadata** - Quantities are state fluents, not action metadata
9. **❌ TOMBSTONE: Separate `resources` map with `consumables`, `tools`, `locations`** - Everything is entities with capabilities
10. **❌ TOMBSTONE: `properties` field in entity requirements** - Use capabilities instead
11. **❌ TOMBSTONE: Separate `requires_agent` field** - Agents are entities with capabilities
12. **❌ TOMBSTONE: `location` field in action metadata** - Locations are entities in `requires_entities`
13. **❌ TOMBSTONE: `constraints` field in entity requirements** - Quantities, availability, and dynamic properties are state fluents, not action metadata
14. **❌ TOMBSTONE: Requirement validation in action functions** - Actions assume planner has already validated requirements

**Old unigoal API patterns (TOMBSTONED):**

```elixir
# DON'T USE: Full tuple goal pattern (TOMBSTONED)
@unigoal_method goal_pattern: {"chef", "location", :any}
def travel_to_location(state, {"chef", "location", target}) do
  # ❌ WRONG - tuple destructuring signature
end

# USE INSTEAD: Advanced predicate-based registration
@unigoal_method predicate: "location"
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

**Action-level requirement validation (TOMBSTONED):**

**❌ WRONG - Action validating its own requirements:**

```elixir
@action requires_entities: [%{type: "agent", capabilities: [:cooking]}]
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
def cook_meal(state, [meal_type]) do
  # CORRECT: Pure state transformation, planner already validated requirements
  state
  |> State.set_fact("meal_status", meal_type, "cooking")
  |> State.set_fact("chef_status", "chef_1", "busy")
end
```

**Why action-level validation is tombstoned:**

- **Planning Time**: Planner validates `requires_entities` against state before selecting actions
- **Execution Time**: Actions focus purely on state transformation
- **Performance**: No redundant validation during execution
- **Architecture**: Clean separation between planning logic and execution logic
- **Commands Handle Failures**: Real-world execution failures are handled by commands, not actions

## CRITICAL ENFORCEMENT: Function Attribute Requirements

**Every function that integrates with the planner system MUST have the corresponding attribute:**

### Required Attribute Patterns

**Planner Actions:**
```elixir
@action duration: "PT2H", requires_entities: [...]
def action_name(state, args) do
  # Can reference @action metadata
end
```

**Execution Commands:**
```elixir
@command
def command_name(state, args) do
  # Execution-time logic only
end
```

**Task Methods:**
```elixir
@task_method
def task_name(state, args) do
  # Task decomposition logic
end
```

**Unigoal Methods:**
```elixir
@unigoal_method predicate: "location"
def method_name(state, [subject, value]) do
  # Goal decomposition logic
end
```

**Multigoal Methods:**
```elixir
@multigoal_method goal_pattern: :pattern_name
def method_name(state, multigoal) do
  # Multigoal handling logic
end
```

### Violation Examples (FORBIDDEN)

❌ **WRONG - No attribute but references planner metadata:**
```elixir
def cook_meal(state, [meal_type]) do  # No @action attribute
  case validate(@action[:requires_entities]) do  # ❌ References non-existent metadata
end
```

❌ **WRONG - No attribute but presented as planner function:**
```elixir
def travel_to_location(state, [subject, target]) do  # No @unigoal_method attribute
  # Presented as unigoal method but not registered with planner
end
```

✅ **CORRECT - Helper function (no planner integration):**
```elixir
defp calculate_cooking_time(meal_type) do  # Private helper
  # No planner metadata references, no attribute needed
end
```

**ENFORCEMENT:** Functions without attributes are helper functions only - no planner integration allowed.

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
  %{type: "ingredient", capabilities: [:consumable]}
]
def cook_meal(state, [meal_type]) do
  # AriaEngine automatically validates:
  # - Agent with cooking AND menu_planning capabilities
  # - Oven with heating AND baking capabilities  
  # - Ingredients with consumable capability
  
  case AriaEngine.EntityValidator.validate_requirements(state, @action[:requires_entities]) do
    {:ok, entities} ->
      # Validate quantities using state queries (CORRECT approach)
      case validate_ingredient_quantities(state, meal_type) do
        {:ok, _} -> proceed_with_cooking(state, meal_type, entities)
        {:error, reason} -> {:error, reason}
      end
    {:error, :missing_capabilities} -> {:error, "Required capabilities not available"}
  end
end

# State-based quantity validation helper
defp validate_ingredient_quantities(state, meal_type) do
  required_ingredients = get_recipe_requirements(meal_type)
  
  Enum.reduce_while(required_ingredients, {:ok, []}, fn {ingredient, min_qty}, {:ok, acc} ->
    available_qty = StateV2.get_fact(state, ingredient, "quantity") || 0
    
    if available_qty >= min_qty do
      {:cont, {:ok, [ingredient | acc]}}
    else
      {:halt, {:error, "Insufficient #{ingredient}: need #{min_qty}, have #{available_qty}"}}
    end
  end)
end
```

### Temporal Conditions/Effects Examples

```elixir
# ALREADY IMPLEMENTED: Temporal conditions/effects using Domain.DurativeAction
defmodule MyApp.Domains.AdvancedCookingDomain do
  use AriaEngine.Domain
  
  # Complex durative action with temporal conditions and effects
  @action duration: "PT2H",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :teamwork]},
            %{type: "agent", capabilities: [:prep_work]},
            %{type: "oven", capabilities: [:heating, :baking]}
          ]
  def collaborative_cooking(state, [meal_type]) do
    # Create durative action with temporal conditions/effects
    durative_action = %Domain.DurativeAction{
      name: :collaborative_cooking,
      duration: {:fixed, 7200},  # 2 hours in seconds
      
      # Temporal conditions - when things must be true
      conditions: %{
        at_start: [
          {"available", "chef_1", true},
          {"available", "prep_cook", true}, 
          {"temperature", "oven", {:>=, 350}}
        ],
        over_all: [
          {"coordination", "team", "active"},
          {"temperature", "oven", {:between, 350, 450}},
          {"workspace", "kitchen", "clean"}
        ],
        at_end: [
          {"quality", "meal", {:>=, 8}},
          {"cleanup", "kitchen", "complete"}
        ]
      },
      
      # Temporal effects - when things change  
      effects: %{
        at_start: [
          {"status", "chef_1", "cooking"},
          {"status", "prep_cook", "assisting"},
          {"status", "oven", "in_use"},
          {"workspace", "kitchen", "busy"}
        ],
        over_time: [
          {"experience", "team", {:increase, 1}},
          {"kitchen_heat", "environment", {:increase, 2}},
          {"aroma", "kitchen", {:intensify, 0.1}}
        ],
        at_end: [
          {"status", "meal", "ready"},
          {"status", "chef_1", "available"},
          {"status", "prep_cook", "available"},
          {"status", "oven", "available"},
          {"workspace", "kitchen", "clean"}
        ]
      },
      
      action_fn: &collaborative_cooking_implementation/2
    }
    
    # Execute durative action with temporal validation
    case Domain.execute_durative_action(state, durative_action) do
      {:ok, final_state} -> {:ok, final_state}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Meeting example with fixed schedule and temporal constraints
  @action start: "2025-06-22T10:00:00Z", 
          end: "2025-06-22T11:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "conference_room", capabilities: [:meeting_space]}
          ]
  def scheduled_meeting(state, [participants]) do
    durative_action = %Domain.DurativeAction{
      name: :scheduled_meeting,
      duration: {:fixed_interval, "2025-06-22T10:00:00Z", "2025-06-22T11:00:00Z"},
      
      conditions: %{
        at_start: [
          {"available", "conference_room_1", true},
          {"participants_ready", "meeting", true}
        ],
        over_all: [
          {"room_reserved", "conference_room_1", true},
          {"focus_level", "participants", {:>=, 7}}
        ],
        at_end: [
          {"agenda_complete", "meeting", true},
          {"notes_recorded", "meeting", true}
        ]
      },
      
      effects: %{
        at_start: [
          {"status", "conference_room_1", "in_use"},
          {"status", "meeting", "in_progress"}
        ],
        over_time: [
          {"progress", "agenda", {:increase, 0.02}}  # 2% per minute
        ],
        at_end: [
          {"status", "conference_room_1", "available"},
          {"status", "meeting", "completed"},
          {"knowledge_shared", "team", true}
        ]
      },
      
      action_fn: &scheduled_meeting_implementation/2
    }
    
    Domain.execute_durative_action(state, durative_action)
  end
  
  # Open-ended interval example (start time only)
  @action start: "2025-06-22T14:00:00Z",
          requires_entities: [
            %{type: "agent", capabilities: [:research]},
            %{type: "library", capabilities: [:information_access]}
          ]
  def research_session(state, [topic]) do
    durative_action = %Domain.DurativeAction{
      name: :research_session,
      duration: {:open_ended_start, "2025-06-22T14:00:00Z"},
      
      conditions: %{
        at_start: [
          {"available", "researcher", true},
          {"access", "library", true}
        ],
        over_all: [
          {"focus", "researcher", {:>=, 6}},
          {"resources", "library", "accessible"}
        ]
        # No at_end conditions - open-ended
      },
      
      effects: %{
        at_start: [
          {"status", "researcher", "researching"},
          {"session", "research", "active"}
        ],
        over_time: [
          {"knowledge", topic, {:increase, 0.1}},
          {"fatigue", "researcher", {:increase, 0.05}}
        ]
        # Effects continue until manually stopped
      },
      
      action_fn: &research_session_implementation/2
    }
    
    Domain.execute_durative_action(state, durative_action)
  end
end
```

### Execution Context Examples with Performance Monitoring

```elixir
# ALREADY IMPLEMENTED: Execution context tracking with LazyExecutionStrategy
defmodule MyApp.ExecutionExamples do
  
  # Create execution context with performance monitoring
  def execute_with_monitoring(domain, initial_state, todo_list, opts \\ []) do
    # Create execution context with monitoring
    context = HybridPlanner.Strategies.Default.LazyExecutionStrategy.create_execution_context(
      initial_state, 
      Map.merge(opts, %{monitoring: true, profiling: true})
    )
    
    # Execute with step-by-step monitoring
    case execute_with_context(domain, context, todo_list) do
      {:ok, final_state, final_context} ->
        # Get execution statistics
        stats = HybridPlanner.Strategies.Default.LazyExecutionStrategy.get_execution_stats(final_context)
        
        Logger.info("Execution completed successfully")
        Logger.info("Total steps: #{stats.total_steps}")
        Logger.info("Total time: #{stats.total_time_ms}ms")
        Logger.info("Average step time: #{stats.average_step_time_ms}ms")
        Logger.info("Execution rate: #{stats.execution_rate} steps/second")
        
        {:ok, final_state, stats}
        
      {:error, reason, context} ->
        # Get partial execution statistics
        stats = HybridPlanner.Strategies.Default.LazyExecutionStrategy.get_execution_stats(context)
        
        Logger.error("Execution failed: #{reason}")
        Logger.info("Partial execution - #{stats.total_steps} steps completed")
        
        {:error, reason, stats}
    end
  end
  
  # Step-by-step execution with context updates
  defp execute_with_context(domain, context, todo_list) do
    Enum.reduce_while(todo_list, {:ok, context.current_state, context}, fn step, {:ok, state, ctx} ->
      # Execute individual step with monitoring
      case HybridPlanner.Strategies.Default.LazyExecutionStrategy.execute_step(
        step, state, %{state_strategy: AriaEngine.State}, %{domain: domain}
      ) do
        {:ok, new_state} ->
          # Update execution context with step results
          updated_context = HybridPlanner.Strategies.Default.LazyExecutionStrategy.update_execution_context(
            ctx, step, new_state
          )
          
          # Log step completion
          Logger.debug("Step completed: #{inspect(step)}")
          Logger.debug("Context: #{updated_context.step_count} steps, #{updated_context.last_step_time - updated_context.start_time}ms elapsed")
          
          {:cont, {:ok, new_state, updated_context}}
          
        {:error, reason} ->
          # Handle execution failure with context preservation
          Logger.warning("Step failed: #{inspect(step)} - #{reason}")
          
          case HybridPlanner.Strategies.Default.LazyExecutionStrategy.handle_execution_failure(
            {:action_failed, step, reason}, state, %{state_strategy: AriaEngine.State}, %{domain: domain}
          ) do
            {:ok, recovered_state} ->
              Logger.info("Execution failure recovered, continuing")
              {:cont, {:ok, recovered_state, ctx}}
              
            {:error, recovery_reason} ->
              Logger.error("Execution failure recovery failed: #{recovery_reason}")
              {:halt, {:error, recovery_reason, ctx}}
          end
      end
    end)
  end
  
  # Entity requirement validation during execution
  def execute_with_entity_validation(domain, state, action_name, args) do
    # Get action metadata including entity requirements
    action_metadata = Domain.get_action_metadata(domain, action_name)
    
    # Validate entity requirements before execution
    case validate_entity_requirements_with_monitoring(state, action_metadata.requires_entities) do
      {:ok, validated_entities, validation_time} ->
        Logger.debug("Entity validation completed in #{validation_time}ms")
        Logger.debug("Validated entities: #{inspect(validated_entities)}")
        
        # Execute action with validated entities
        start_time = System.system_time(:millisecond)
        
        case HybridPlanner.Strategies.Default.LazyExecutionStrategy.execute_step(
          {action_name, args}, state, %{state_strategy: AriaEngine.State}, %{domain: domain}
        ) do
          {:ok, new_state} ->
            execution_time = System.system_time(:millisecond) - start_time
            Logger.info("Action #{action_name} executed successfully in #{execution_time}ms")
            {:ok, new_state}
            
          {:error, reason} ->
            execution_time = System.system_time(:millisecond) - start_time
            Logger.error("Action #{action_name} failed after #{execution_time}ms: #{reason}")
            {:error, reason}
        end
        
      {:error, reason, validation_time} ->
        Logger.error("Entity validation failed in #{validation_time}ms: #{reason}")
        {:error, "Entity validation failed: #{reason}"}
    end
  end
  
  # Entity requirement validation with timing
  defp validate_entity_requirements_with_monitoring(state, entity_requirements) do
    start_time = System.system_time(:millisecond)
    
    result = Enum.reduce_while(entity_requirements, {:ok, []}, fn entity_req, {:ok, acc} ->
      case find_available_entity_with_monitoring(state, entity_req) do
        {:ok, entity_id, search_time} -> 
          Logger.debug("Found entity #{entity_id} in #{search_time}ms")
          {:cont, {:ok, [entity_id | acc]}}
        {:error, reason, search_time} -> 
          Logger.debug("Entity search failed in #{search_time}ms: #{reason}")
          {:halt, {:error, reason}}
      end
    end)
    
    validation_time = System.system_time(:millisecond) - start_time
    
    case result do
      {:ok, entities} -> {:ok, Enum.reverse(entities), validation_time}
      {:error, reason} -> {:error, reason, validation_time}
    end
  end
  
  defp find_available_entity_with_monitoring(state, %{type: type, capabilities: capabilities}) do
    start_time = System.system_time(:millisecond)
    
    # Find entities with required type and capabilities
    entities = find_entities_with_capabilities(state, capabilities)
    |> Enum.filter(fn entity_id ->
      StateV2.get_fact(state, entity_id, "type") == type and
      StateV2.get_fact(state, entity_id, "available") == true
    end)
    
    search_time = System.system_time(:millisecond) - start_time
    
    case entities do
      [entity_id | _] -> {:ok, entity_id, search_time}
      [] -> {:error, "No available entity with type #{type} and capabilities #{inspect(capabilities)}", search_time}
    end
  end
end
```

### Goal Verification Examples using Domain.Utils

```elixir
# ALREADY IMPLEMENTED: Goal verification using Domain.Utils
defmodule MyApp.GoalVerificationExamples do
  
  # Automatic goal verification after unigoal methods
  @unigoal_method goal_pattern: {"chef", "location", :any}
  def travel_to_location(state, {"chef", "location", target}) do
    current = State.get_fact(state, "location", "chef")
    
    if current == target do
      # Goal already achieved - verify immediately
      case Domain.Utils.verify_goal(state, {"chef", "location", target}) do
        {:ok, true} -> 
          Logger.debug("Goal already achieved and verified: chef at #{target}")
          {:ok, []}
        {:ok, false} -> 
          Logger.warning("Goal verification failed despite state check")
          {:error, "Goal verification inconsistency"}
        {:error, reason} -> 
          {:error, "Goal verification error: #{reason}"}
      end
    else
      # Need to achieve goal - add verification task
      {:ok, [
        {:walk_to_location, ["chef", target]},
        {:verify_goal, [{"chef", "location", target}]}  # Automatic verification
      ]}
    end
  end
  
  # Complex goal verification with constraints
  @unigoal_method goal_pattern: {"chef", "has_ingredients", :any}
  def acquire_ingredients(state, {"chef", "has_ingredients", ingredient_list}) do
    case Domain.Utils.verify_complex_goal(state, {"chef", "has_ingredients", ingredient_list}) do
      {:ok, true} ->
        Logger.debug("Chef already has all required ingredients")
        {:ok, []}
        
      {:ok, false} ->
        # Determine missing ingredients
        current_ingredients = State.get_fact(state, "inventory", "chef") || []
        missing_ingredients = ingredient_list -- current_ingredients
        
        Logger.debug("Missing ingredients: #{inspect(missing_ingredients)}")
        
        # Create acquisition plan with verification
        acquisition_tasks = Enum.map(missing_ingredients, fn ingredient ->
          {:acquire_ingredient, [ingredient]}
        end)
        
        verification_task = {:verify_goal, [{"chef", "has_ingredients", ingredient_list}]}
        
        {:ok, acquisition_tasks ++ [verification_task]}
        
      {:error, reason} ->
        {:error, "Goal verification failed: #{reason}"}
    end
  end
  
  # Multigoal verification example
  @multigoal_method goal_pattern: :cooking_preparation
  def handle_cooking_preparation(state, multigoal) do
    # Verify each goal in multigoal before planning
    verification_results = Enum.map(multigoal.goals, fn goal ->
      case Domain.Utils.verify_goal(state, goal) do
        {:ok, true} -> {:achieved, goal}
        {:ok, false} -> {:needs_work, goal}
        {:error, reason} -> {:error, goal, reason}
      end
    end)
    
    # Separate achieved goals from goals needing work
    {achieved_goals, remaining_goals} = Enum.split_with(verification_results, fn
      {:achieved, _} -> true
      _ -> false
    end)
    
    # Check for verification errors
    error_goals = Enum.filter(verification_results, fn
      {:error, _, _} -> true
      _ -> false
    end)
    
    case error_goals do
      [] ->
        Logger.info("#{length(achieved_goals)} goals already achieved")
        Logger.info("#{length(remaining_goals)} goals need work")
        
        # Plan only for remaining goals
        remaining_goal_list = Enum.map(remaining_goals, fn {:needs_work, goal} -> goal end)
        
        case AriaEngine.Multigoal.split_multigoal(state, remaining_goal_list) do
          {:ok, plan} ->
            # Add verification for the entire multigoal at the end
            verification_task = {:verify_multigoal, [multigoal]}
            {:ok, plan ++ [verification_task]}
            
          {:error, reason} ->
            {:error, "Multigoal planning failed: #{reason}"}
        end
        
      errors ->
        error_details = Enum.map(errors, fn {:error, goal, reason} ->
          "#{inspect(goal)}: #{reason}"
        end)
        {:error, "Goal verification errors: #{Enum.join(error_details, ", ")}"}
    end
  end
  
  # Goal verification with state queries
  def verify_goal_with_state_queries(state, goal) do
    case goal do
      {"chef", "location", target_location} ->
        # Simple fact verification
        current_location = State.get_fact(state, "location", "chef")
        
        case current_location do
          ^target_location -> 
            Logger.debug("Goal verified: chef is at #{target_location}")
            {:ok, true}
          other_location -> 
            Logger.debug("Goal not achieved: chef is at #{other_location}, not #{target_location}")
            {:ok, false}
          nil -> 
            Logger.warning("Goal verification failed: chef location unknown")
            {:error, "Chef location not found in state"}
        end
        
      {"chef", "has_ingredients", ingredient_list} when is_list(ingredient_list) ->
        # Complex verification with list checking
        current_inventory = State.get_fact(state, "inventory", "chef") || []
        
        missing_ingredients = ingredient_list -- current_inventory
        
        case missing_ingredients do
          [] -> 
            Logger.debug("Goal verified: chef has all ingredients #{inspect(ingredient_list)}")
            {:ok, true}
          missing -> 
            Logger.debug("Goal not achieved: missing ingredients #{inspect(missing)}")
            {:ok, false}
        end
        
      {"meal", "quality", min_quality} when is_number(min_quality) ->
        # Numerical constraint verification
        current_quality = State.get_fact(state, "quality", "meal")
        
        case current_quality do
          quality when is_number(quality) and quality >= min_quality ->
            Logger.debug("Goal verified: meal quality #{quality} >= #{min_quality}")
            {:ok, true}
          quality when is_number(quality) ->
            Logger.debug("Goal not achieved: meal quality #{quality} < #{min_quality}")
            {:ok, false}
          nil ->
            Logger.debug("Goal not achieved: meal quality not set")
            {:ok, false}
          invalid ->
            Logger.warning("Goal verification failed: invalid quality value #{inspect(invalid)}")
            {:error, "Invalid quality value"}
        end
        
      unknown_goal ->
        Logger.error("Unknown goal pattern: #{inspect(unknown_goal)}")
        {:error, "Unknown goal pattern"}
    end
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
# UNIFIED: Consistent attribute pattern for all domain elements
@action duration: "PT2H", requires_entities: [...]
def cook(state, [meal_type]) do
  # Implementation
end

@action duration: "PT1H", requires_entities: [...]
def bake(state, [item_type]) do
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

- **ADR-181**: Unified Durative Action Specification and Planner Standardization (parent ADR)
- **ADR-182**: Fix Duration Handling Precision Loss (technical integration)
- **ADR-183**: Planner Standardization Open Problems (completed features)
- **ADR-086**: Implement Durative Actions (foundational work)

## Implementation Status

**Status:** Active - Canonical pattern under ongoing refinement

**Usage:** Reference implementation for all new AriaEngine domains

**Timeline:** Available immediately for domain development

**Compatibility:** IPyHOP-compatible with pure GTPyhop multigoal philosophy
