# Design Document: "Conviction in Crisis"

A Real-Time Tactical Unit Test for a Temporal Goal-Task-Network Planner

## 1. Introduction

**"Conviction in Crisis"** is a self-contained, real-time tactical scenario designed to serve as a robust unit test for a temporal, re-entrant, goal-task-network (GTN) planner. It models a critical cCurrent State:

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
00:07.1s - Alex moves to (10,4,0)counter inspired by the game "Triangle Strategy."

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

## 3. Game State Representation (The Domain)

This section defines the precise data structures and constants for the "Bridge of Betrayal" scenario.

### 3.1. World & Map

- **`grid_map_size`**: `{width: 25, height: 10, depth: 1}` representing coordinates `(x: 0-24, y: 0-9, z: 0)`.
- **`map_layout`**: A 3D array where each cell has properties:
  - `walkable`: (boolean)
  - `cover_value`: (integer, e.g., 25% damage reduction)
  - `is_chasm`: (boolean)
  - `is_escape_zone`: (boolean, true if `x >= 24`)

**Note**: While this scenario uses a 2D tactical map (z=0 for all entities), the system uses 3D coordinates to ensure future extensibility for multi-level scenarios, aerial units, and vertical movement mechanics.

- **Key Locations**:
  - **Bridge Area**: `x` from 3 to 21 inclusive.
  - **Pillars**:
    - `pillar_1`: `{position: (10, 3, 0), hp: 150}`
    - `pillar_2`: `{position: (10, 7, 0), hp: 150}`
  - **Hostage**: `(20, 5, 0)`
- **World Timers & Flags** (values in seconds):
  - `world_time`: (float) Starts at 0.0, advanced by the Game Engine.
  - `hostage_execution_timer`: `30.0`
  - `enemy_reinforcement_timer`: `45.0`

### 3.2. Agent State (Characters & Enemies)

A list of agent structs, each with the following properties:

| Property         | Type                       | Description                                                    |
| ---------------- | -------------------------- | -------------------------------------------------------------- |
| `id`             | Atom/Symbol                | Unique identifier (e.g., `:alex`, `:enemy_1`)                  |
| `team`           | Atom/Symbol                | `:player` or `:enemy`                                          |
| `position`       | `{x: int, y: int, z: int}` | Current grid coordinates.                                      |
| `hp`             | Integer                    | Current health points.                                         |
| `max_hp`         | Integer                    | Maximum health points.                                         |
| `attack_power`   | Integer                    | Base damage dealt by the `attack` task.                        |
| `defense`        | Integer                    | Flat damage reduction from incoming attacks.                   |
| `move_speed`     | Integer                    | Squares per second the agent can move.                         |
| `skills`         | List of Skill Structs      | The agent's available special abilities.                       |
| `active_effects` | List of Effect Structs     | Active buffs/debuffs (e.g., `{effect: :slow, duration: 5.0}`). |
| `current_task`   | Task Struct or `nil`       | The task the agent is currently executing.                     |

### 3.3. Initial Scenario Constants

| Character | ID         | HP  | Atk | Def | Move Speed | Position     | Skills            |
| --------- | ---------- | --- | --- | --- | ---------- | ------------ | ----------------- |
| Alex      | `:alex`    | 120 | 25  | 15  | 4          | `(4, 4, 0)`  | `Delaying Strike` |
| Maya      | `:maya`    | 80  | 35  | 5   | 3          | `(3, 5, 0)`  | `Scorch`          |
| Jordan    | `:jordan`  | 95  | 10  | 10  | 3          | `(4, 6, 0)`  | `Now!`            |
| Soldier 1 | `:enemy_1` | 70  | 20  | 10  | 3          | `(15, 4, 0)` | N/A               |
| Soldier 2 | `:enemy_2` | 70  | 20  | 10  | 3          | `(15, 5, 0)` | N/A               |
| Soldier 3 | `:enemy_3` | 70  | 20  | 10  | 3          | `(15, 6, 0)` | N/A               |
| Archer 1  | `:enemy_4` | 50  | 18  | 5   | 3          | `(18, 3, 0)` | N/A               |
| Archer 2  | `:enemy_5` | 50  | 18  | 5   | 3          | `(18, 7, 0)` | N/A               |

## 4. Agent Tasks (Planner's Action Library)

These are the primitive actions the planner can assign to agents.

| Task Name       | Parameters                        | Duration (s)            | Description & Effects                                                                                             |
| --------------- | --------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **`move_to`**   | `agent_id`, `position`            | `distance / move_speed` | Moves agent. Precondition: Path is walkable. Effect: Updates agent `position`.                                    |
| **`attack`**    | `attacker_id`, `target_id`        | `1.5`                   | Perform a melee/ranged attack. Precondition: Target in range. Effect: `target.hp -= (attacker.atk - target.def)`. |
| **`use_skill`** | `caster_id`, `skill_id`, `target` | Varies (see below)      | Uses a special ability.                                                                                           |
| **`interact`**  | `agent_id`, `object_id`           | `2.0`                   | Interact with a world object (e.g., a pillar). Effect: `object.hp -= agent.atk`.                                  |
| **`defend`**    | `agent_id`                        | `1.0` (to activate)     | Agent gains 50% damage reduction for 5s. Effect: Adds `:defending` to `active_effects`.                           |
| **`wait`**      | `agent_id`, `duration`            | `duration`              | Agent does nothing.                                                                                               |

### 4.1. Skill Definitions

| Skill Name        | Caster | Cast Time | Cooldown | Description                                                                                |
| ----------------- | ------ | --------- | -------- | ------------------------------------------------------------------------------------------ |
| `Delaying Strike` | Alex   | `0.0s`    | `10.0s`  | Deals 1.5x damage and applies `{effect: :slow, duration: 5.0s}`.                           |
| `Scorch`          | Maya   | `2.0s`    | `8.0s`   | Deals AoE damage in a 3x3 square at the target location.                                   |
| `Now!`            | Jordan | `0.5s`    | `20.0s`  | Resets an ally's action, allowing them to act again immediately. **(Key Re-entrant Test)** |

## 5. The "Conviction Choice" Problem

The test begins. The planner is given the initial high-level goal: **`survive_the_encounter`**. The engine immediately presents the "Conviction Choice," forcing the planner to re-evaluate and adopt one of the four more specific goals.

### **Choice 1: Morality - `rescue_hostage`**

- **Narrative**: "Our allies are our strength. We leave no one behind!"
- **Planner's Goal**: Prioritize all actions that result in Alex reaching the `hostage` tile.
- **Likely Task Network**:
  1. Jordan uses `Now!` on Alex.
  2. Alex `move_to` a forward position.
  3. Maya uses `Scorch` on the main cluster of enemies blocking the path.
  4. Alex uses `Delaying Strike` on a key enemy to create an opening.
  5. Alex continues to `move_to` the hostage location.
- **Success Condition**: `alex.position == hostage.position` AND `world_time <= hostage_execution_timer`.

### **Choice 2: Utility - `destroy_bridge`**

- **Narrative**: "This bridge is their only path. A hard choice now saves countless lives later."
- **Planner's Goal**: Prioritize dealing damage to `pillar_1` and `pillar_2`.
- **Likely Task Network**:
  1. Maya begins to `move_to` a position in range of a pillar.
  2. Alex and Jordan `move_to` defensive positions to intercept advancing enemies.
  3. Maya casts `Scorch` targeting a pillar (and hopefully nearby enemies).
  4. Jordan uses `Now!` on Maya to speed up pillar destruction.
  5. Agents `interact` or `attack` pillars until their combined HP is 0.
- **Success Condition**: `pillar_1.hp + pillar_2.hp <= 0`.

### **Choice 3: Liberty - `escape_scenario`**

- **Narrative**: "To fight tomorrow, we must survive today. We will retreat and choose our next battlefield."
- **Planner's Goal**: Prioritize moving all player agents to the `escape_zone`.
- **Likely Task Network**:
  1. Maya uses `Scorch` on enemies to create a chokepoint or apply `slow`.
  2. Jordan casts `defend` on the most threatened ally.
  3. Alex uses `Delaying Strike` on the fastest enemy to prevent pursuit.
  4. All agents use `move_to` actions to progress towards `x >= 24`.
- **Success Condition**: All surviving agents in the `:player` team have `position.x >= 24`.

### **Choice 4: Valor - `eliminate_all_enemies`**

- **Narrative**: "We will make our stand here! Show them the iron will of our house!"
- **Planner's Goal**: Prioritize reducing the HP of all agents on the `:enemy` team to 0.
- **Likely Task Network**:
  1. The planner identifies the highest threat (Archers).
  2. Alex `move_to` and `attack` the nearest enemy.
  3. Maya casts `Scorch` to maximize damage on clustered enemies.
  4. Jordan uses `Now!` on the agent who can deal the most effective damage next.
  5. Focus-fire continues until all enemies are defeated.
- **Success Condition**: The list of agents on the `:enemy` team is empty.

## 6. Temporal Goal-Task-Network (GTN) Planner Design

This section outlines how to modify the existing re-entrant GTN planner in `aria_engine` to become a temporal planner capable of handling time-sensitive goals and actions.

### 6.1. Core Temporal Extensions

#### 6.1.1. Temporal State Representation

The existing `AriaEngine.State` needs temporal extensions:

```elixir
# Temporal facts in state
temporal_state = AriaEngine.State.new()
|> AriaEngine.State.set_temporal_object("location", "alex", {4, 4, 0}, 0.0)
|> AriaEngine.State.set_temporal_object("hp", "alex", 120, 0.0)
|> AriaEngine.State.set_temporal_object("cooldown", "alex_delaying_strike", 0.0, 0.0)
|> AriaEngine.State.set_temporal_object("world_time", "game", 0.0, 0.0)
```

#### 6.1.2. Temporal Domain Actions

Actions in `AriaEngine.Domain` must include temporal constraints:

```elixir
# Example temporal action
def temporal_move_action(state, [agent_id, target_pos], start_time) do
  agent_pos = State.get_temporal_object(state, "location", agent_id, start_time)
  move_speed = State.get_temporal_object(state, "move_speed", agent_id, start_time)

  distance = calculate_distance(agent_pos, target_pos)
  duration = distance / move_speed
  end_time = start_time + duration

  # Check temporal preconditions
  if path_clear_during(state, agent_pos, target_pos, start_time, end_time) do
    state
    |> State.set_temporal_object("location", agent_id, target_pos, end_time)
    |> State.add_temporal_constraint({:occupies_path, agent_id, agent_pos, target_pos, start_time, end_time})
  else
    false
  end
end
```

### 6.2. Temporal Plan Generation Architecture

```
+------------------+     (1) Current State + Goal     +-------------------+
|                  | ----------------------------->   |                   |
|   Game Loop      |                                 |  Temporal GTN     |
| (Oban Scheduler) |     (2) Temporal Plan           |    Planner        |
|                  | <-----------------------------   |                   |
+--------+---------+                                 +----------+--------+
         |                                                      |
         | (3) Schedule Timed Actions                          | (4) Re-plan on
         |     via Oban Jobs                                   |    Goal Change
         v                                                      |
+------------------+                                           |
|                  |                                           |
|  Oban Job Queue  |                                           |
| - MoveJob        |                                           |
| - AttackJob      | <-----------------------------------------+
| - SkillJob       |     (5) Action Execution Updates State
| - InteractJob    |
+------------------+
```

### 6.3. Implementation Components

#### 6.3.1. Temporal Planning Algorithm

The planner uses a modified GTPyhop approach with temporal reasoning:

1. **Temporal Goal Decomposition**: Break high-level goals into time-bounded tasks
2. **Temporal Method Selection**: Choose methods based on temporal constraints
3. **Temporal Conflict Resolution**: Resolve resource and scheduling conflicts
4. **Re-entrant Planning**: Dynamically re-plan when goals change mid-execution

#### 6.3.2. Oban Integration for Action Scheduling

Each planned action becomes an Oban job scheduled at the precise execution time:

```elixir
# Schedule a temporal action
%{
  agent_id: "alex",
  action: :move_to,
  target: {10, 5, 0},
  start_time: 5.2,
  duration: 2.0
}
|> AriaEngine.Jobs.GameActionJob.new(scheduled_at: game_start_time + 5.2)
|> Oban.insert()
```

### 6.4. Re-entrant Planning Mechanics

#### 6.4.1. Plan Invalidation

When a new goal is selected (Conviction Choice), the planner must:

1. Cancel pending Oban jobs for the old plan
2. Preserve currently executing actions if they're still beneficial
3. Generate a new temporal plan for the new goal
4. Schedule new Oban jobs for the new plan

#### 6.4.2. Temporal Constraint Propagation

The planner maintains temporal constraints between actions:

- **Precedence**: Action A must complete before Action B starts
- **Resource Conflicts**: Two actions can't use the same agent simultaneously
- **World State Dependencies**: Action effects must be available when needed

## 7. CLI Implementation Using Aria Components

### 7.1. Mix Task Structure

Create a Mix task that provides an interactive text-based game interface:

```bash
mix aria_engine.play_conviction_crisis
```

### 7.2. Game Components Integration

#### 7.2.1. AriaQueue (Oban) - Action Scheduling

- Schedule timed actions as Oban jobs
- Handle action execution at precise timestamps
- Manage job cancellation for re-planning

#### 7.2.2. AriaEngine - Planning Logic

- Temporal state management
- Goal-task network planning
- Re-entrant plan generation

#### 7.2.3. AriaStorage - Game State Persistence

- Save/load game sessions
- Store planning history
- Cache computed plans

#### 7.2.4. AriaMonitor - Performance Tracking

- Track planner performance metrics
- Monitor action execution timing
- Collect planning statistics

### 7.3. Text-Based Game Flow

1. **Initialization**: Setup game state, start Oban, load scenario
2. **Planning Phase**: Generate initial plan for `survive_the_encounter`
3. **Conviction Choice**: Present 4 choices, trigger re-planning
4. **Execution Loop**: Execute scheduled actions, update display
5. **Monitoring**: Show real-time game state and planner decisions
6. **Win/Lose Conditions**: Evaluate success based on chosen goal

### 7.4. User Interface Design

```
=== Conviction in Crisis - Temporal Planner Test ===
Time: 00:05.2s | Goal: rescue_hostage | Plan Status: Executing

Current State:
- Alex: (6,4) HP:120/120 [Moving to (8,4), ETA: 00:06.1s]
- Maya: (3,5) HP:80/80 [Casting Scorch at (15,5), ETA: 00:07.0s]
- Jordan: (4,6) HP:95/95 [Ready]

Enemies:
- Soldier1: (15,4) HP:70/70
- Soldier2: (15,5) HP:70/70 [Will take 45 damage from Scorch]
- Archer1: (18,3) HP:50/50

Scheduled Actions:
00:06.1s - Alex reaches (8,4)
00:06.1s - Jordan uses "Now!" on Alex
00:07.0s - Maya's Scorch hits (15,5)
00:07.1s - Alex moves to (10,4)

[Press SPACE to pause | Q to quit | R to replan]
```

### 7.5. CLI Implementation Requirements

The CLI task should demonstrate:

1. **Temporal Planning**: Show how the planner schedules actions over time
2. **Re-entrant Behavior**: Allow mid-game goal changes and observe re-planning
3. **Real-time Execution**: Use Oban to execute actions at precise times
4. **Conflict Resolution**: Handle temporal constraints and resource conflicts
5. **Performance Metrics**: Display planning time, plan quality, execution accuracy

This implementation will serve as both a unit test for the temporal planner and a demonstration of how Aria components work together in a real-time, decision-making system.

## 8. Temporal Planner API Design

This section defines the complete API for the temporal Goal-Task-Network planner, covering all components needed for the "Conviction in Crisis" scenario.

### 8.1. Core Temporal State API

#### 8.1.1. AriaEngine.TemporalState

```elixir
defmodule AriaEngine.TemporalState do
  @moduledoc """
  Temporal extension of AriaEngine.State for time-aware planning.
  """

  # Create temporal state
  @spec new(float()) :: t()
  def new(current_time \\ 0.0)

  # Set temporal facts
  @spec set_temporal_object(t(), String.t(), String.t(), any(), float()) :: t()
  def set_temporal_object(state, predicate, subject, object, timestamp)

  # Get temporal facts at specific time
  @spec get_temporal_object(t(), String.t(), String.t(), float()) :: any() | nil
  def get_temporal_object(state, predicate, subject, timestamp)

  # Get temporal facts in time range
  @spec get_temporal_range(t(), String.t(), String.t(), float(), float()) :: [any()]
  def get_temporal_range(state, predicate, subject, start_time, end_time)

  # Add temporal constraints
  @spec add_temporal_constraint(t(), temporal_constraint()) :: t()
  def add_temporal_constraint(state, constraint)

  # Check if state is valid at time
  @spec valid_at_time?(t(), float()) :: boolean()
  def valid_at_time?(state, timestamp)
end

# Usage Example
temporal_state = AriaEngine.TemporalState.new(0.0)
|> AriaEngine.TemporalState.set_temporal_object("location", "alex", {4, 4, 0}, 0.0)
|> AriaEngine.TemporalState.set_temporal_object("hp", "alex", 120, 0.0)
|> AriaEngine.TemporalState.set_temporal_object("cooldown", "alex_delaying_strike", 0.0, 0.0)

alex_position_at_5s = AriaEngine.TemporalState.get_temporal_object(temporal_state, "location", "alex", 5.0)
```

#### 8.1.2. AriaEngine.TemporalDomain

```elixir
defmodule AriaEngine.TemporalDomain do
  @moduledoc """
  Temporal extension of AriaEngine.Domain for time-aware actions and methods.
  """

  # Create temporal domain
  @spec new(String.t()) :: t()
  def new(name)

  # Add temporal action
  @spec add_temporal_action(t(), atom(), temporal_action_fn()) :: t()
  def add_temporal_action(domain, action_name, action_fn)

  # Add temporal task method
  @spec add_temporal_task_method(t(), String.t(), temporal_method_fn()) :: t()
  def add_temporal_task_method(domain, task_name, method_fn)

  # Execute temporal action
  @spec execute_temporal_action(t(), atom(), AriaEngine.TemporalState.t(), list(), float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def execute_temporal_action(domain, action, state, args, start_time)

  # Get action duration
  @spec get_action_duration(t(), atom(), AriaEngine.TemporalState.t(), list()) :: float()
  def get_action_duration(domain, action, state, args)
end

# Usage Example
domain = AriaEngine.TemporalDomain.new("conviction_crisis")
|> AriaEngine.TemporalDomain.add_temporal_action(:move_to, &ConvictionCrisis.Actions.temporal_move/4)
|> AriaEngine.TemporalDomain.add_temporal_action(:attack, &ConvictionCrisis.Actions.temporal_attack/4)
|> AriaEngine.TemporalDomain.add_temporal_action(:use_skill, &ConvictionCrisis.Actions.temporal_skill/4)
```

### 8.2. Temporal Planning API

#### 8.2.1. AriaEngine.TemporalPlanner

```elixir
defmodule AriaEngine.TemporalPlanner do
  @moduledoc """
  Main temporal planning engine for Goal-Task-Network planning.
  """

  # Plan for a goal
  @spec plan(AriaEngine.TemporalDomain.t(), AriaEngine.TemporalState.t(), goal(), float()) ::
    {:ok, AriaEngine.TemporalPlan.t()} | {:error, String.t()}
  def plan(domain, state, goal, current_time)

  # Re-entrant planning (cancel and replan)
  @spec replan(AriaEngine.TemporalDomain.t(), AriaEngine.TemporalState.t(), goal(), AriaEngine.TemporalPlan.t(), float()) ::
    {:ok, AriaEngine.TemporalPlan.t()} | {:error, String.t()}
  def replan(domain, state, new_goal, current_plan, current_time)

  # Validate temporal plan
  @spec validate_plan(AriaEngine.TemporalPlan.t(), AriaEngine.TemporalState.t()) ::
    {:ok, []} | {:error, [String.t()]}
  def validate_plan(plan, state)

  # Get next actions to execute
  @spec get_next_actions(AriaEngine.TemporalPlan.t(), float()) :: [timed_action()]
  def get_next_actions(plan, current_time)
end

# Usage Example
{:ok, plan} = AriaEngine.TemporalPlanner.plan(
  domain,
  temporal_state,
  {:rescue_hostage, "alex", {20, 5}},
  0.0
)

# Re-plan when goal changes
{:ok, new_plan} = AriaEngine.TemporalPlanner.replan(
  domain,
  temporal_state,
  {:destroy_bridge, ["pillar_1", "pillar_2"]},
  plan,
  5.2
)
```

#### 8.2.2. AriaEngine.TemporalPlan Management

```elixir
defmodule AriaEngine.TemporalPlan do
  @moduledoc """
  Represents and manages temporal execution plans.
  """

  # Create new temporal plan
  @spec new() :: t()
  def new()

  # Add timed action
  @spec add_action(t(), timed_action()) :: t()
  def add_action(plan, action)

  # Add temporal constraint
  @spec add_constraint(t(), temporal_constraint()) :: t()
  def add_constraint(plan, constraint)

  # Get actions in time range
  @spec get_actions_in_range(t(), float(), float()) :: [timed_action()]
  def get_actions_in_range(plan, start_time, end_time)

  # Check for temporal conflicts
  @spec check_conflicts(t()) :: {:ok, []} | {:error, [conflict()]}
  def check_conflicts(plan)

  # Get plan duration
  @spec get_total_duration(t()) :: float()
  def get_total_duration(plan)

  # Get critical path
  @spec get_critical_path(t()) :: [action_id()]
  def get_critical_path(plan)

  # Cancel actions after time
  @spec cancel_after(t(), float()) :: t()
  def cancel_after(plan, timestamp)
end

# Usage Example
plan = AriaEngine.TemporalPlan.new()
|> AriaEngine.TemporalPlan.add_action(%{
    id: "alex_move_1",
    action: :move_to,
    args: ["alex", {8, 4, 0}],
    start_time: 0.0,
    duration: 1.0,
    end_time: 1.0,
    resources: ["alex"],
    preconditions: [{"location", "alex", {4, 4, 0}}],
    effects: [{"location", "alex", {8, 4, 0}}]
  })

conflicts = AriaEngine.TemporalPlan.check_conflicts(plan)
critical_path = AriaEngine.TemporalPlan.get_critical_path(plan)
```

### 8.3. Oban Integration API

#### 8.3.1. AriaEngine.Jobs.GameActionJob

```elixir
defmodule AriaEngine.Jobs.GameActionJob do
  @moduledoc """
  Oban job for executing game actions at precise times.
  """
  use Oban.Worker, queue: :game_actions, max_attempts: 1

  # Schedule a game action
  @spec schedule_action(timed_action(), DateTime.t()) :: {:ok, Oban.Job.t()} | {:error, any()}
  def schedule_action(action, game_start_time)

  # Cancel scheduled action
  @spec cancel_action(String.t()) :: :ok | {:error, any()}
  def cancel_action(action_id)

  # Execute action (Oban callback)
  @spec perform(Oban.Job.t()) :: :ok | {:error, any()}
  def perform(%Oban.Job{args: args})
end

# Usage Example
action = %{
  id: "alex_move_1",
  action: :move_to,
  args: ["alex", {8, 4, 0}],
  start_time: 5.2,
  duration: 1.0
}

{:ok, job} = AriaEngine.Jobs.GameActionJob.schedule_action(
  action,
  game_start_time
)

# Cancel if re-planning
:ok = AriaEngine.Jobs.GameActionJob.cancel_action("alex_move_1")
```

#### 8.3.2. AriaEngine.Jobs.PlannerJob

```elixir
defmodule AriaEngine.Jobs.PlannerJob do
  @moduledoc """
  Background job for running the temporal planner.
  """
  use Oban.Worker, queue: :planner, max_attempts: 3

  # Schedule planning job
  @spec schedule_planning(String.t(), goal(), float()) :: {:ok, Oban.Job.t()}
  def schedule_planning(game_id, goal, current_time)

  # Schedule re-planning job
  @spec schedule_replanning(String.t(), goal(), float()) :: {:ok, Oban.Job.t()}
  def schedule_replanning(game_id, new_goal, current_time)

  # Execute planning (Oban callback)
  @spec perform(Oban.Job.t()) :: :ok | {:error, any()}
  def perform(%Oban.Job{args: args})
end

# Usage Example
{:ok, planning_job} = AriaEngine.Jobs.PlannerJob.schedule_planning(
  "game_123",
  {:rescue_hostage, "alex", {20, 5, 0}},
  0.0
)
```

### 8.4. Game State Management API

#### 8.4.1. ConvictionCrisis.GameState

```elixir
defmodule ConvictionCrisis.GameState do
  @moduledoc """
  Manages the complete game state for Conviction in Crisis scenario.
  """

  # Initialize game state
  @spec initialize() :: t()
  def initialize()

  # Update agent state
  @spec update_agent(t(), String.t(), map()) :: t()
  def update_agent(state, agent_id, updates)

  # Get agent state
  @spec get_agent(t(), String.t()) :: map() | nil
  def get_agent(state, agent_id)

  # Apply action effects
  @spec apply_action_effects(t(), timed_action(), float()) :: t()
  def apply_action_effects(state, action, current_time)

  # Check win conditions
  @spec check_win_condition(t(), goal()) :: :win | :lose | :ongoing
  def check_win_condition(state, goal)

  # Get visible state for UI
  @spec get_display_state(t()) :: map()
  def get_display_state(state)
end

# Usage Example
game_state = ConvictionCrisis.GameState.initialize()
|> ConvictionCrisis.GameState.update_agent("alex", %{position: {6, 4, 0}, hp: 115})

win_status = ConvictionCrisis.GameState.check_win_condition(
  game_state,
  {:rescue_hostage, "alex", {20, 5, 0}}
)
```

#### 8.4.2. ConvictionCrisis.Actions

```elixir
defmodule ConvictionCrisis.Actions do
  @moduledoc """
  Implements all temporal actions for the Conviction Crisis scenario.
  """

  # Temporal move action
  @spec temporal_move(AriaEngine.TemporalState.t(), [String.t() | {integer(), integer(), integer()}], float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def temporal_move(state, [agent_id, target_pos], start_time)

  # Temporal attack action
  @spec temporal_attack(AriaEngine.TemporalState.t(), [String.t()], float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def temporal_attack(state, [attacker_id, target_id], start_time)

  # Temporal skill action
  @spec temporal_skill(AriaEngine.TemporalState.t(), [String.t() | atom() | any()], float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def temporal_skill(state, [caster_id, skill_id, target], start_time)

  # Temporal interact action
  @spec temporal_interact(AriaEngine.TemporalState.t(), [String.t()], float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def temporal_interact(state, [agent_id, object_id], start_time)

  # Temporal defend action
  @spec temporal_defend(AriaEngine.TemporalState.t(), [String.t()], float()) ::
    {:ok, AriaEngine.TemporalState.t(), float()} | {:error, String.t()}
  def temporal_defend(state, [agent_id], start_time)
end

# Usage Example
{:ok, new_state, end_time} = ConvictionCrisis.Actions.temporal_move(
  temporal_state,
  ["alex", {8, 4, 0}],
  0.0
)

{:ok, attack_state, attack_end} = ConvictionCrisis.Actions.temporal_attack(
  new_state,
  ["alex", "enemy_1"],
  2.5
)
```

### 8.5. CLI Interface API

#### 8.5.1. Mix.Tasks.AriaEngine.PlayConvictionCrisis

```elixir
defmodule Mix.Tasks.AriaEngine.PlayConvictionCrisis do
  @moduledoc """
  CLI interface for playing the Conviction Crisis temporal planner test.
  """
  use Mix.Task

  @shortdoc "Play the Conviction Crisis temporal planner test game"

  # Main CLI entry point
  @spec run([String.t()]) :: :ok
  def run(args)

  # Initialize game session
  @spec initialize_game(keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def initialize_game(opts)

  # Start game loop
  @spec start_game_loop(String.t()) :: :ok
  def start_game_loop(game_id)

  # Handle user input
  @spec handle_input(String.t(), String.t()) :: :ok | :quit | :replan
  def handle_input(input, game_id)

  # Display game state
  @spec display_state(String.t()) :: :ok
  def display_state(game_id)
end

# Usage Example
# Command line:
# mix aria_engine.play_conviction_crisis --speed=1.0 --auto=false
```

#### 8.5.2. ConvictionCrisis.Display

```elixir
defmodule ConvictionCrisis.Display do
  @moduledoc """
  Handles all text-based display formatting for the CLI game.
  """

  # Render complete game state
  @spec render_game_state(map(), AriaEngine.TemporalPlan.t(), float()) :: String.t()
  def render_game_state(game_state, plan, current_time)

  # Render agent status
  @spec render_agents(map()) :: String.t()
  def render_agents(agents)

  # Render scheduled actions
  @spec render_scheduled_actions(AriaEngine.TemporalPlan.t(), float()) :: String.t()
  def render_scheduled_actions(plan, current_time)

  # Render conviction choice menu
  @spec render_conviction_choice() :: String.t()
  def render_conviction_choice()

  # Render planning status
  @spec render_planning_status(atom(), float()) :: String.t()
  def render_planning_status(status, planning_time)

  # Clear screen and position cursor
  @spec clear_screen() :: :ok
  def clear_screen()
end

# Usage Example
display_output = ConvictionCrisis.Display.render_game_state(
  game_state,
  current_plan,
  5.2
)
IO.puts(display_output)
```

### 8.6. Monitoring and Metrics API

#### 8.6.1. ConvictionCrisis.Metrics

```elixir
defmodule ConvictionCrisis.Metrics do
  @moduledoc """
  Collects and reports metrics on planner performance.
  """

  # Start metrics collection
  @spec start_collection(String.t()) :: :ok
  def start_collection(game_id)

  # Record planning time
  @spec record_planning_time(String.t(), float()) :: :ok
  def record_planning_time(game_id, duration)

  # Record plan quality metrics
  @spec record_plan_quality(String.t(), AriaEngine.TemporalPlan.t()) :: :ok
  def record_plan_quality(game_id, plan)

  # Record action execution accuracy
  @spec record_execution_accuracy(String.t(), String.t(), float(), float()) :: :ok
  def record_execution_accuracy(game_id, action_id, scheduled_time, actual_time)

  # Record re-planning events
  @spec record_replan_event(String.t(), goal(), goal(), float()) :: :ok
  def record_replan_event(game_id, old_goal, new_goal, replan_time)

  # Get metrics summary
  @spec get_metrics_summary(String.t()) :: map()
  def get_metrics_summary(game_id)
end

# Usage Example
:ok = ConvictionCrisis.Metrics.start_collection("game_123")
:ok = ConvictionCrisis.Metrics.record_planning_time("game_123", 0.125)
metrics = ConvictionCrisis.Metrics.get_metrics_summary("game_123")
```

### 8.7. Complete Usage Example

```elixir
# Complete workflow for running Conviction Crisis
defmodule ConvictionCrisis.Workflow do
  def run_complete_example() do
    # 1. Initialize components
    {:ok, game_id} = ConvictionCrisis.GameState.initialize()
    domain = ConvictionCrisis.Domain.create_conviction_crisis_domain()

    # 2. Start initial planning
    {:ok, initial_plan} = AriaEngine.TemporalPlanner.plan(
      domain,
      game_state,
      {:survive_the_encounter},
      0.0
    )

    # 3. Schedule initial actions
    Enum.each(initial_plan.actions, fn action ->
      AriaEngine.Jobs.GameActionJob.schedule_action(action, DateTime.utc_now())
    end)

    # 4. Start metrics collection
    ConvictionCrisis.Metrics.start_collection(game_id)

    # 5. Present conviction choice at 3 seconds
    Process.sleep(3000)
    chosen_goal = ConvictionCrisis.CLI.present_conviction_choice()

    # 6. Re-plan with new goal
    {:ok, new_plan} = AriaEngine.TemporalPlanner.replan(
      domain,
      game_state,
      chosen_goal,
      initial_plan,
      3.0
    )

    # 7. Continue execution until win/lose
    ConvictionCrisis.GameLoop.run_until_completion(game_id, new_plan)

    # 8. Report metrics
    metrics = ConvictionCrisis.Metrics.get_metrics_summary(game_id)
    ConvictionCrisis.Display.render_final_report(metrics)
  end
end
```
