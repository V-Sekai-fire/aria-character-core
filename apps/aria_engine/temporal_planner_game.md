# Design Document: "Conviction in Crisis"

A Real-Time Tactical Unit Test for a Temporal Goal-Task-Network Planner

## 1. Introduction

**"Conviction in Crisis"** is a self-contained, real-time tactical scenario designed to serve as a robust unit test for a temporal, re-entrant, goal-task-network (GTN) planner. It models a critical choice-driven encounter inspired by the game "Triangle Strategy."

The primary purpose is to validate the planner's ability to:

- **Decompose** high-level, abstract goals into a concrete sequence of tasks.
- **Manage temporal constraints**, such as cast times, cooldowns, and timed objectives.
- **Re-plan dynamically** by gracefully discarding an existing task network and generating a new one when the overarching goal changes abruptly.
- **Generate logical and effective plans** for multiple, non-player agents working towards a shared objective.

## 2. Core Architecture & Data Flow

The system consists of three main components: the **Game Engine**, the **Game State**, and the **Planner**.

1. **Game State**: A data structure holding the complete "ground truth" of the scenario at any given moment.
2. **Game Engine**: The main loop that updates the Game State based on executing tasks. It advances time, resolves actions (like attacks and movement), and sends updates to the Planner.
3. **Planner**: Receives the current Game State and a high-level goal. It generates a task network for all controllable agents and sends this plan to the Game Engine.

```
+------------------+      (1) Sends Current State & Goal      +-----------------+
|                  | ---------------------------------------> |                 |
|   Game Engine    |                                          |     Planner     |
| (Updates World)  |      (2) Returns Generated Task Plan     |  (Generates Plan) |
|                  | <--------------------------------------- |                 |
+-------^----------+                                          +--------+--------+
        |                                                              |
(3) Executes Tasks, |                                                  | (4) Monitors Plan
    Resolves Actions|                                                  |     Execution
        |                                                              |
        +----------------------------+-----------------------------------+
                                     |
                             +-------v-------+
                             |               |
                             |  Game State   |
                             | (Ground Truth)|
                             |               |
                             +---------------+
```

The scenario unfolds on a 25x10 grid. While the map is 2D, the system uses 3D coordinates for future extensibility (e.g., flying units, multi-level terrain).

- **Grid Size**: {width: 25, height: 10, depth: 1}
- **Map Properties**: Each cell can be walkable, provide cover, be a chasm, or be part of the escape_zone.
- **Key Locations**:
  - **Bridge Pillars**: (10, 3, 0) and (10, 7, 0), each with 150 HP.
  - **Hostage**: (20, 5, 0).
  - **Escape Zone**: Any tile where x >= 24.
- **Scenario Timers**:
  - **Hostage Execution**: The hostage is lost at 30.0 seconds.
  - **Enemy Reinforcements**: Arrive at 45.0 seconds.

### **3.2. Factions & Agents**

There are two teams: :player and :enemy. Each agent is defined by a consistent set of properties.

| ID         | Team    | HP  | Atk | Def | Move | Position   | Skills          |
| :--------- | :------ | :-- | :-- | :-- | :--- | :--------- | :-------------- |
| **Alex**   | :player | 120 | 25  | 15  | 4    | (4, 4, 0)  | Delaying Strike |
| **Maya**   | :player | 80  | 35  | 5   | 3    | (3, 5, 0)  | Scorch          |
| **Jordan** | :player | 95  | 10  | 10  | 3    | (4, 6, 0)  | Now!            |
| Soldier 1  | :enemy  | 70  | 20  | 10  | 3    | (15, 4, 0) | -               |
| Soldier 2  | :enemy  | 70  | 20  | 10  | 3    | (15, 5, 0) | -               |
| Soldier 3  | :enemy  | 70  | 20  | 10  | 3    | (15, 6, 0) | -               |
| Archer 1   | :enemy  | 50  | 18  | 5   | 3    | (18, 3, 0) | -               |
| Archer 2   | :enemy  | 50  | 18  | 5   | 3    | (18, 7, 0) | -               |

### **3.3. Planner's Action Library**

These are the primitive tasks the Planner can use to build a plan.

| Task / Skill    | Caster | Duration / Cast Time | Cooldown | Description & Effects                                                                    |
| :-------------- | :----- | :------------------- | :------- | :--------------------------------------------------------------------------------------- |
| move_to         | Any    | distance / move      | -        | Moves agent to a target position                                                         |
| attack          | Any    | 1.5s                 | -        | Standard attack. Deals (attacker.atk - target.def) damage                                |
| interact        | Any    | 2.0s                 | -        | Interact with a world object (e.g., a pillar)                                            |
| defend          | Any    | 1.0s (to activate)   | -        | Gain 50% damage reduction for 5s                                                         |
| wait            | Any    | duration             | -        | Agent does nothing for a set time                                                        |
| Delaying Strike | Alex   | 0.0s (instant)       | 10.0s    | Deals 1.5x damage and applies a slow effect for 5.0s                                     |
| Scorch          | Maya   | 2.0s                 | 8.0s     | Deals AoE damage in a 3x3 square at a target location                                    |
| Now!            | Jordan | 0.5s                 | 20.0s    | **Key Re-entrant Test**: Resets an ally's action, allowing them to act again immediately |

## **4. The Core Test: The "Conviction Choice"**

The test begins with the vague goal: **survive_the_encounter**. Immediately, the game engine forces the Planner to commit to one of four specific, mutually exclusive goals. This is the crucial re-planning event.

### **Choice 1: Morality (rescue_hostage)**

_"Our allies are our strength. We leave no one behind!"_

- **Goal:** Move a player agent to the hostage's tile before the execution timer runs out.
- **Success Condition:** alex.position == hostage.position AND world_time <= 30.0.
- **Likely Plan:** A direct rush. Maya uses Scorch to clear a path, Alex uses Delaying Strike to disable a key defender, and Jordan uses Now! on Alex to maximize forward movement.

### **Choice 2: Utility (destroy_bridge)**

_"This bridge is their only path. A hard choice now saves countless lives later."_

- **Goal:** Destroy the two bridge pillars to prevent enemy reinforcements.
- **Success Condition:** pillar_1.hp + pillar_2.hp <= 0.
- **Likely Plan:** A split operation. Alex and Jordan form a defensive line to intercept enemies while Maya moves into position to interact with and cast Scorch on the pillars. Jordan may use Now! on Maya to accelerate the destruction.

### **Choice 3: Liberty (escape_scenario)**

_"To fight tomorrow, we must survive today. We will retreat and choose our next battlefield."_

- **Goal:** Move all surviving player agents into the designated escape zone.
- **Success Condition:** All surviving agents on :player team have position.x >= 24.
- **Likely Plan:** A fighting retreat. Maya uses Scorch to create chokepoints, Alex uses Delaying Strike on the fastest pursuers, and Jordan uses defend to protect the most threatened ally while the team moves toward the map edge.

### **Choice 4: Valor (eliminate_all_enemies)**

_"We will make our stand here! Show them the iron will of our house!"_

- **Goal:** Reduce the HP of all agents on the :enemy team to 0.
- **Success Condition:** The list of agents on the :enemy team is empty.
- **Likely Plan:** A coordinated assault. The planner should identify the highest threats (e.g., archers) and focus fire. Maya uses Scorch for maximum AoE damage, Alex targets key enemies, and Jordan uses Now! on whichever ally can secure a kill or deal the most effective damage.

## **5. Data Structures & Types**

Before diving into the API, we need to define the core data structures that represent temporal planning concepts.

### **5.1. Temporal Actions**

A `timed_action` represents a concrete action that will be executed at a specific time:

```elixir
@type timed_action :: %{
  id: String.t(),                    # Unique identifier for this action
  agent_id: String.t(),              # Which agent performs this action
  action: atom(),                    # The action type (:move_to, :attack, :scorch, etc.)
  args: list(),                      # Arguments for the action
  start_time: float(),               # When this action begins (in seconds)
  duration: float(),                 # How long this action takes
  end_time: float(),                 # When this action completes (start_time + duration)
  prerequisites: [String.t()],       # IDs of actions that must complete first
  effects: [temporal_effect()],      # What changes this action makes to the world
  status: :scheduled | :executing | :completed | :cancelled
}
```

**Example timed_action:**

```elixir
%{
  id: "alex_move_001",
  agent_id: "alex",
  action: :move_to,
  args: [{8, 4, 0}],
  start_time: 5.0,
  duration: 1.0,
  end_time: 6.0,
  prerequisites: [],
  effects: [
    %{type: :set, object: "alex", property: "position", value: {8, 4, 0},
      start_time: 6.0, duration: :permanent, condition: nil}
  ],
  status: :scheduled
}
```

### **5.2. Goals & Tasks**

A `goal` represents a high-level objective that the planner must achieve:

```elixir
@type goal :: %{
  id: String.t(),                    # Unique identifier
  type: :rescue_hostage | :destroy_bridge | :escape_scenario | :eliminate_all_enemies,
  priority: 1..100,                  # Higher numbers = higher priority
  deadline: float() | :none,         # Must be completed by this time (or no deadline)
  success_condition: goal_condition(),  # What defines success
  failure_condition: goal_condition(),  # What defines failure
  agents: [String.t()],              # Which agents are involved
  constraints: [temporal_constraint()], # Additional constraints
  metadata: map()                    # Additional goal-specific data
}

@type goal_condition :: %{
  type: :and | :or | :not | :predicate,
  conditions: [goal_condition()] | nil,  # For composite conditions
  predicate: atom() | nil,               # For atomic conditions
  args: list()                           # Arguments to the predicate
}
```

**Example goal (rescue_hostage):**

```elixir
%{
  id: "rescue_hostage_001",
  type: :rescue_hostage,
  priority: 90,
  deadline: 30.0,
  success_condition: %{
    type: :and,
    conditions: [
      %{type: :predicate, predicate: :agent_at_position, args: ["alex", {20, 5, 0}]},
      %{type: :predicate, predicate: :world_time_less_than, args: [30.0]}
    ]
  },
  failure_condition: %{
    type: :or,
    conditions: [
      %{type: :predicate, predicate: :world_time_greater_than, args: [30.0]},
      %{type: :predicate, predicate: :agent_dead, args: ["alex"]}
    ]
  },
  agents: ["alex", "maya", "jordan"],
  constraints: [],
  metadata: %{hostage_position: {20, 5, 0}}
}
```

A `task` represents a decomposable unit of work:

```elixir
@type task :: %{
  id: String.t(),                    # Unique identifier
  name: String.t(),                  # Human-readable name
  type: :primitive | :compound,      # Primitive = direct action, Compound = needs decomposition
  action: atom() | nil,              # For primitive tasks
  args: list(),                      # Arguments
  agent_id: String.t(),              # Which agent performs this
  preconditions: [condition()],      # What must be true before this task
  effects: [temporal_effect()],      # What this task changes
  duration: float() | :variable,     # How long this task takes
  subtasks: [task()] | nil,          # For compound tasks
  constraints: [temporal_constraint()], # Temporal relationships
  metadata: map()
}
```

### **5.3. Temporal Constraints**

Constraints define relationships between actions and temporal requirements:

```elixir
@type temporal_constraint :: %{
  id: String.t(),
  type: :before | :after | :during | :meets | :overlaps | :starts | :finishes | :equals | :deadline | :cooldown,
  source: String.t(),                # ID of source action/task
  target: String.t() | nil,          # ID of target action/task (nil for absolute constraints)
  offset: float() | nil,             # Time offset (e.g., "5 seconds after")
  duration: float() | nil,           # For duration-based constraints
  condition: condition() | nil,      # Additional logical condition
  violation_penalty: float()         # Cost of violating this constraint
}
```

**Example temporal constraints:**

```elixir
# "Alex must move before Maya casts Scorch"
%{
  id: "alex_move_before_maya_scorch",
  type: :before,
  source: "alex_move_001",
  target: "maya_scorch_001",
  offset: nil,
  duration: nil,
  condition: nil,
  violation_penalty: 10.0
}

# "Jordan's Now! skill has a 20-second cooldown"
%{
  id: "jordan_now_cooldown",
  type: :cooldown,
  source: "jordan_now_001",
  target: nil,
  offset: nil,
  duration: 20.0,
  condition: nil,
  violation_penalty: 100.0
}
```

### **5.4. Temporal Effects & Conditions**

Effects describe how actions change the world state:

```elixir
@type temporal_effect :: %{
  type: :set | :add | :remove | :modify,
  object: String.t(),                # What object is affected
  property: String.t(),              # What property changes
  value: any(),                      # New value
  start_time: float(),               # When this effect begins
  duration: float() | :permanent,    # How long this effect lasts
  condition: condition() | nil       # Conditional effect
}

@type condition :: %{
  type: :equals | :not_equals | :greater | :less | :greater_equal | :less_equal | :exists | :not_exists,
  object: String.t(),
  property: String.t(),
  value: any()
}
```

### **5.5. Planning Methods**

Methods define how to decompose compound tasks into subtasks:

```elixir
@type planning_method :: %{
  id: String.t(),
  name: String.t(),
  task_name: String.t(),             # Which task type this method applies to
  preconditions: [condition()],      # When this method is applicable
  subtasks: [task()],                # What subtasks to create
  constraints: [temporal_constraint()], # Temporal relationships between subtasks
  priority: integer(),               # Method selection priority
  cost_estimate: float()             # Estimated cost of this decomposition
}
```

**Example planning method (rescue_hostage decomposition):**

```elixir
%{
  id: "rescue_hostage_method_001",
  name: "Direct Rush to Hostage",
  task_name: "rescue_hostage",
  preconditions: [
    %{type: :greater, object: "alex", property: "hp", value: 50},
    %{type: :less, object: "world", property: "time", value: 25.0}
  ],
  subtasks: [
    %{id: "clear_path", name: "Clear Path", type: :compound, agent_id: "maya"},
    %{id: "rush_hostage", name: "Rush to Hostage", type: :compound, agent_id: "alex"},
    %{id: "provide_support", name: "Provide Support", type: :compound, agent_id: "jordan"}
  ],
  constraints: [
    %{type: :before, source: "clear_path", target: "rush_hostage", offset: 1.0}
  ],
  priority: 80,
  cost_estimate: 15.5
}
```

### **5.6. Multi-Goal Structures**

For handling multiple competing or complementary goals:

```elixir
@type goal_network :: %{
  goals: [goal()],
  relationships: [goal_relationship()],
  resolution_strategy: :priority | :utility | :deadline | :custom,
  global_constraints: [temporal_constraint()]
}

@type goal_relationship :: %{
  type: :conflicts | :supports | :requires | :enables,
  source_goal: String.t(),
  target_goal: String.t(),
  strength: float()                  # How strong this relationship is
}
```

## **6. Technical API Specification**

This section outlines the Elixir-based implementation, focusing on the temporal extensions required to handle time-sensitive actions and goals. The architecture relies on Oban for scheduling, ensuring that actions are executed at the correct time.

### **6.1. Core Temporal State API (AriaEngine)**

#### **AriaEngine.TemporalState**

Handles time-aware facts. It can query the state of an object (e.g., alex.hp) at any point in time.

```elixir
defmodule AriaEngine.TemporalState do
  # Creates a new temporal state, optionally setting the current time.
  @spec new(float()) :: t()
  # Sets a fact that is true starting at a specific timestamp.
  @spec set_temporal_object(t(), String.t(), String.t(), any(), float()) :: t()
  # Gets the value of a fact at a specific time.
  @spec get_temporal_object(t(), String.t(), String.t(), float()) :: any() | nil
  # Adds a temporal constraint to the state.
  @spec add_temporal_constraint(t(), temporal_constraint()) :: t()
end
```

#### **AriaEngine.TemporalDomain**

Defines actions and methods with temporal properties like duration and time-based preconditions.

```elixir
defmodule AriaEngine.TemporalDomain do
  # Adds a temporal action with its execution logic function.
  @spec add_temporal_action(t(), atom(), temporal_action_fn()) :: t()
  # Adds a method for decomposing a high-level task.
  @spec add_temporal_task_method(t(), String.t(), temporal_method_fn()) :: t()
  # Executes a temporal action, returning the new state and action duration.
  @spec execute_temporal_action(t(), atom(), AriaEngine.TemporalState.t(), list(), float()) :: {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
end
```

### **6.2. Temporal Planning API (AriaEngine)**

#### **AriaEngine.TemporalPlanner**

The main planning engine. It contains the logic for plan(...) and replan(...), which handles plan invalidation and generation.

```elixir
defmodule AriaEngine.TemporalPlanner do
  # Generates a plan for a given goal from a starting state and time.
  @spec plan(AriaEngine.TemporalDomain.t(), AriaEngine.TemporalState.t(), goal(), float()) :: {:ok, AriaEngine.TemporalPlan.t()} | {:error, String.t()}
  # Cancels an old plan and generates a new one for a new goal.
  @spec replan(AriaEngine.TemporalDomain.t(), AriaEngine.TemporalState.t(), goal(), AriaEngine.TemporalPlan.t(), float()) :: {:ok, AriaEngine.TemporalPlan.t()} | {:error, String.t()}
  # Returns the next set of actions that should be executed at the current time.
  @spec get_next_actions(AriaEngine.TemporalPlan.t(), float()) :: [timed_action()]
end
```

#### **AriaEngine.TemporalPlan**

A data structure representing the plan itself, containing a list of timed actions and the temporal constraints between them.

```elixir
defmodule AriaEngine.TemporalPlan do
  # Adds a timed action to the plan.
  @spec add_action(t(), timed_action()) :: t()
  # Adds a constraint between actions (e.g., precedence).
  @spec add_constraint(t(), temporal_constraint()) :: t()
  # Checks for temporal conflicts in the plan.
  @spec check_conflicts(t()) :: {:ok, []} | {:error, [conflict()]}
  # Cancels all actions scheduled after a given timestamp.
  @spec cancel_after(t(), float()) :: t()
end
```

### **6.3. Action Execution API (Oban)**

#### **AriaEngine.Jobs.GameActionJob**

An Oban worker that executes a single game action. It takes the action details (e.g., `{agent: "alex", action: :move_to, target: {8, 4, 0}}`) and performs the necessary state update.

```elixir
defmodule AriaEngine.Jobs.GameActionJob do
  use Oban.Worker, queue: :game_actions, max_attempts: 1

  # Schedules a game action job to run at its specified start_time.
  @spec schedule_action(timed_action(), DateTime.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  # Cancels a scheduled Oban job by its unique action ID.
  @spec cancel_action(String.t()) :: :ok | {:error, any()}
  # The `perform` callback that executes when the job runs.
  @spec perform(Oban.Job.t()) :: :ok | {:error, any()}
end
```

### **6.4. Scenario-Specific API (ConvictionCrisis)**

#### **ConvictionCrisis.GameState**

Manages the specific state for this scenario, including initialization, win/loss condition checks, and applying action effects.

```elixir
defmodule ConvictionCrisis.GameState do
  # Initializes the game state with the starting layout.
  @spec initialize() :: t()
  # Updates the state of a specific agent.
  @spec update_agent(t(), String.t(), map()) :: t()
  # Applies the effects of a completed action to the state.
  @spec apply_action_effects(t(), timed_action(), float()) :: t()
  # Checks if the current state meets the win/loss condition for the active goal.
  @spec check_win_condition(t(), goal()) :: :win | :lose | :ongoing
end
```

#### **ConvictionCrisis.Actions**

Implements the specific temporal logic for each action in the scenario's domain (move, attack, skills, etc.).

```elixir
defmodule ConvictionCrisis.Actions do
  # Contains the implementation for all temporal actions, e.g.:
  @spec temporal_move(state, args, start_time) :: {:ok, new_state, duration} | :error
  @spec temporal_attack(state, args, start_time) :: {:ok, new_state, duration} | :error
  @spec temporal_skill(state, args, start_time) :: {:ok, new_state, duration} | :error
end
```

## **7. Test Interface & Demonstration (CLI)**

To run the test and visualize the planner's decisions, a simple, interactive command-line interface will be used.

### **7.1. UI Mockup & Flow**

The CLI provides a real-time view of the game state, the planner's current goal, and the list of scheduled actions.

```
=== Conviction in Crisis - Temporal Planner Test ===
Time: 00:05.2s | Goal: rescue_hostage | Plan Status: Executing

Current State:
- Alex: (6,4,0) HP:120/120 [Moving to (8,4,0), ETA: 00:06.1s]
- Maya: (3,5,0) HP:80/80 [Casting Scorch at (15,5,0), ETA: 00:07.0s]
- Jordan: (4,6,0) HP:95/95 [Ready]

Enemies:
- Soldier1: (15,4,0) HP:70/70
- Soldier2: (15,5,0) HP:70/70 [Will take 45 damage from Scorch]
- Archer1: (18,3,0) HP:50/50

Scheduled Actions:
00:06.1s - Alex reaches (8,4,0)
00:06.1s - Jordan uses "Now!" on Alex
00:07.0s - Maya's Scorch hits (15,5,0)
00:07.1s - Alex moves to (10,4,0)

[Press SPACE to pause | Q to quit | C to change conviction]
```

### **7.2. Core CLI Functionality**

The CLI task (mix aria_engine.play_conviction_crisis) will demonstrate:

1. **Temporal Planning**: Showing how the planner schedules actions over time.
2. **Re-entrant Behavior**: Allowing the user to trigger the "Conviction Choice" mid-game and observing the planner generate a new plan.
3. **Real-time Execution**: Using Oban to execute actions at their precise scheduled times, reflected in the UI.
4. **Performance Metrics**: Displaying key metrics like planning time and plan execution accuracy.

## **8. AriaEngine Modifications for Temporal Planning**

Here's how to modify the existing AriaEngine to support temporal, re-entrant Goal-Task-Network planning for "Conviction in Crisis":

### **8.1. Extend AriaEngine.State for Temporal Facts**

**File: `apps/aria_engine/lib/aria_engine/temporal_state.ex`**

```elixir
defmodule AriaEngine.TemporalState do
  @moduledoc """
  Extends AriaEngine.State with temporal awareness.
  Maintains both current facts and time-indexed fact history.
  """

  alias AriaEngine.State

  @type temporal_fact :: %{
    predicate: String.t(),
    subject: String.t(),
    object: any(),
    start_time: float(),
    end_time: float() | :permanent
  }

  defstruct base_state: %State{},
            temporal_facts: [],
            current_time: 0.0

  def new(current_time \\ 0.0) do
    %__MODULE__{
      base_state: State.new(),
      current_time: current_time
    }
  end

  def set_temporal_object(state, predicate, subject, object, start_time, duration \\ :permanent) do
    end_time = if duration == :permanent, do: :permanent, else: start_time + duration

    temporal_fact = %{
      predicate: predicate,
      subject: subject,
      object: object,
      start_time: start_time,
      end_time: end_time
    }

    # Update base state if this fact is currently active
    updated_base = if start_time <= state.current_time do
      State.set_object(state.base_state, predicate, subject, object)
    else
      state.base_state
    end

    %{state |
      base_state: updated_base,
      temporal_facts: [temporal_fact | state.temporal_facts]
    }
  end

  def get_temporal_object(state, predicate, subject, at_time) do
    # Find the most recent fact that was active at the given time
    state.temporal_facts
    |> Enum.filter(fn fact ->
      fact.predicate == predicate and fact.subject == subject and
      fact.start_time <= at_time and
      (fact.end_time == :permanent or at_time < fact.end_time)
    end)
    |> Enum.max_by(&(&1.start_time), fn -> nil end)
    |> case do
      nil -> nil
      fact -> fact.object
    end
  end

  def advance_time(state, new_time) when new_time >= state.current_time do
    # Update base state to reflect all facts that should be active at new_time
    active_facts = get_active_facts_at_time(state, new_time)

    new_base_state = Enum.reduce(active_facts, State.new(), fn fact, acc_state ->
      State.set_object(acc_state, fact.predicate, fact.subject, fact.object)
    end)

    %{state | base_state: new_base_state, current_time: new_time}
  end

  def get_active_facts_at_time(state, time) do
    state.temporal_facts
    |> Enum.filter(fn fact ->
      fact.start_time <= time and
      (fact.end_time == :permanent or time < fact.end_time)
    end)
    |> Enum.group_by(fn fact -> {fact.predicate, fact.subject} end)
    |> Enum.map(fn {_key, facts} -> Enum.max_by(facts, &(&1.start_time)) end)
  end
end
```

### **8.2. Extend AriaEngine.Domain for Temporal Actions**

**File: `apps/aria_engine/lib/aria_engine/temporal_domain.ex`**

```elixir
defmodule AriaEngine.TemporalDomain do
  @moduledoc """
  Extends AriaEngine.Domain with temporal action metadata.
  """

  alias AriaEngine.{Domain, TemporalState}

  defstruct base_domain: %Domain{},
            temporal_actions: %{},
            temporal_methods: %{}

  def new(name \\ "temporal_domain") do
    %__MODULE__{base_domain: Domain.new(name)}
  end

  def add_temporal_action(domain, action_name, action_fn, duration_fn, preconditions \\ []) do
    # Add to base domain
    updated_base = Domain.add_action(domain.base_domain, action_name, action_fn)

    # Add temporal metadata
    temporal_action = %{
      duration_fn: duration_fn,  # fn(state, args) -> duration
      preconditions: preconditions,
      effects: []
    }

    temporal_actions = Map.put(domain.temporal_actions, action_name, temporal_action)

    %{domain | base_domain: updated_base, temporal_actions: temporal_actions}
  end

  def get_action_duration(domain, action_name, state, args) do
    case Map.get(domain.temporal_actions, action_name) do
      %{duration_fn: duration_fn} -> duration_fn.(state, args)
      _ -> 1.0  # Default duration
    end
  end

  def execute_temporal_action(domain, action_name, state, args, start_time) do
    with action_fn when not is_nil(action_fn) <- Domain.get_action(domain.base_domain, action_name),
         duration <- get_action_duration(domain, action_name, state, args),
         new_base_state <- action_fn.(state.base_state, args) do

      if new_base_state == false do
        {:error, "Action #{action_name} failed"}
      else
        # Apply effects at start_time
        new_temporal_state = apply_action_effects(state, new_base_state, start_time)
        {:ok, new_temporal_state, duration}
      end
    else
      _ -> {:error, "Action #{action_name} not found"}
    end
  end

  defp apply_action_effects(temporal_state, new_base_state, start_time) do
    # Convert base state changes to temporal facts
    old_triples = AriaEngine.State.to_triples(temporal_state.base_state)
    new_triples = AriaEngine.State.to_triples(new_base_state)

    Enum.reduce(new_triples, temporal_state, fn {pred, subj, obj}, acc_state ->
      TemporalState.set_temporal_object(acc_state, pred, subj, obj, start_time)
    end)
  end
end
```

### **8.3. Create Temporal Planner with Re-entrancy**

**File: `apps/aria_engine/lib/aria_engine/temporal_planner.ex`**

```elixir
defmodule AriaEngine.TemporalPlanner do
  @moduledoc """
  Temporal planner that extends AriaEngine.Plan with time-awareness and re-entrancy.
  """

  alias AriaEngine.{Plan, TemporalState, TemporalDomain, TemporalPlan}

  def plan(temporal_domain, temporal_state, goals, current_time, opts \\ []) do
    # Convert temporal goals to HTN goals for existing planner
    htn_goals = convert_temporal_goals_to_htn(goals, current_time)

    # Use existing HTN planner
    case Plan.plan(temporal_domain.base_domain, temporal_state.base_state, htn_goals, opts) do
      {:ok, solution_tree} ->
        # Convert HTN solution to temporal plan
        temporal_plan = convert_solution_to_temporal_plan(solution_tree, temporal_domain, temporal_state, current_time)
        {:ok, temporal_plan}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def replan(temporal_domain, temporal_state, new_goals, old_plan, current_time, opts \\ []) do
    # Cancel future actions in old plan
    updated_plan = TemporalPlan.cancel_after(old_plan, current_time)

    # Plan for new goals from current state and time
    case plan(temporal_domain, temporal_state, new_goals, current_time, opts) do
      {:ok, new_plan} ->
        # Merge plans: keep completed actions, add new actions
        merged_plan = merge_temporal_plans(updated_plan, new_plan, current_time)
        {:ok, merged_plan}

      error ->
        error
    end
  end

  def get_next_actions(plan, current_time) do
    plan.actions
    |> Enum.filter(fn action ->
      action.start_time >= current_time and action.start_time < current_time + 0.1
    end)
    |> Enum.sort_by(&(&1.start_time))
  end

  # Private helper functions

  defp convert_temporal_goals_to_htn(goals, current_time) do
    Enum.map(goals, fn goal ->
      case goal do
        %{type: :rescue_hostage} ->
          {"rescue_hostage", [goal.agents, goal.deadline - current_time]}

        %{type: :destroy_bridge} ->
          {"destroy_bridge", [goal.agents]}

        %{type: :escape_scenario} ->
          {"escape_scenario", [goal.agents]}

        %{type: :eliminate_all_enemies} ->
          {"eliminate_enemies", [goal.agents]}

        # Simple goal format
        {predicate, subject, object} ->
          {predicate, subject, object}
      end
    end)
  end

  defp convert_solution_to_temporal_plan(solution_tree, temporal_domain, temporal_state, start_time) do
    # Extract primitive actions from solution tree
    primitive_actions = Plan.get_primitive_actions_dfs(solution_tree)

    # Add timing to actions
    {timed_actions, _} = Enum.reduce(primitive_actions, {[], start_time}, fn {action_name, args}, {actions, time} ->
      duration = TemporalDomain.get_action_duration(temporal_domain, action_name, temporal_state, args)

      timed_action = %{
        id: "action_#{length(actions)}",
        action: action_name,
        args: args,
        start_time: time,
        duration: duration,
        end_time: time + duration,
        status: :scheduled
      }

      {[timed_action | actions], time + duration}
    end)

    %TemporalPlan{
      actions: Enum.reverse(timed_actions),
      start_time: start_time
    }
  end

  defp merge_temporal_plans(old_plan, new_plan, current_time) do
    # Keep completed and in-progress actions from old plan
    kept_actions = Enum.filter(old_plan.actions, fn action ->
      action.start_time < current_time
    end)

    # Add new actions, adjusting their timing
    %{new_plan | actions: kept_actions ++ new_plan.actions}
  end
end
```

### **8.4. Create Conviction Crisis Game Module**

**File: `apps/aria_engine/lib/aria_engine/conviction_crisis.ex`**

```elixir
defmodule AriaEngine.ConvictionCrisis do
  @moduledoc """
  Implementation of the Conviction in Crisis scenario.
  """

  alias AriaEngine.{TemporalDomain, TemporalState, TemporalPlanner}

  def initialize_domain do
    TemporalDomain.new("conviction_crisis")
    |> TemporalDomain.add_temporal_action(:move_to, &move_action/2, &move_duration/2)
    |> TemporalDomain.add_temporal_action(:attack, &attack_action/2, fn _, _ -> 1.5 end)
    |> TemporalDomain.add_temporal_action(:scorch, &scorch_action/2, fn _, _ -> 2.0 end)
    |> TemporalDomain.add_temporal_action(:delaying_strike, &delaying_strike_action/2, fn _, _ -> 0.0 end)
    |> TemporalDomain.add_temporal_action(:now_skill, &now_skill_action/2, fn _, _ -> 0.5 end)
  end

  def initialize_state do
    TemporalState.new(0.0)
    |> TemporalState.set_temporal_object("position", "alex", {4, 4, 0}, 0.0)
    |> TemporalState.set_temporal_object("hp", "alex", 120, 0.0)
    |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0.0)
    |> TemporalState.set_temporal_object("hp", "maya", 80, 0.0)
    |> TemporalState.set_temporal_object("position", "jordan", {4, 6, 0}, 0.0)
    |> TemporalState.set_temporal_object("hp", "jordan", 95, 0.0)
    |> TemporalState.set_temporal_object("position", "hostage", {20, 5, 0}, 0.0)
    |> TemporalState.set_temporal_object("deadline", "hostage_execution", 30.0, 0.0)
  end

  def create_rescue_hostage_goal do
    %{
      id: "rescue_hostage_001",
      type: :rescue_hostage,
      priority: 90,
      deadline: 30.0,
      agents: ["alex", "maya", "jordan"]
    }
  end

  def create_destroy_bridge_goal do
    %{
      id: "destroy_bridge_001",
      type: :destroy_bridge,
      priority: 80,
      deadline: 45.0,
      agents: ["alex", "maya", "jordan"]
    }
  end

  # Action implementations
  defp move_action(state, [agent, {x, y, z}]) do
    AriaEngine.State.set_object(state, "position", agent, {x, y, z})
  end

  defp move_duration(state, [agent, target_pos]) do
    current_pos = AriaEngine.State.get_object(state, "position", agent)
    calculate_move_time(current_pos, target_pos)
  end

  defp calculate_move_time({x1, y1, z1}, {x2, y2, z2}) do
    distance = :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2) + :math.pow(z2 - z1, 2))
    distance / 3.0  # Assume speed of 3 units per second
  end

  # ... other action implementations
end
```

### **8.5. Integration Points**

1. **Oban Jobs**: Modify existing `TemporalPlan.execute/3` to use Oban for scheduling
2. **Re-entrancy**: Use existing `Plan.run_lazy_refineahead/3` as model for temporal re-planning
3. **CLI Interface**: Create Mix task that demonstrates goal switching and re-planning

This approach **extends** rather than replaces the existing AriaEngine, maintaining compatibility while adding temporal capabilities.
