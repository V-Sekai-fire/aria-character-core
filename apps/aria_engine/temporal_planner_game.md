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

## **5. Technical API Specification**

This section outlines the Elixir-based implementation, focusing on the temporal extensions required to handle time-sensitive actions and goals. The architecture relies on Oban for scheduling, ensuring that actions are executed at the correct time.

### **5.1. Core Temporal State API (AriaEngine)**

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

### **5.2. Temporal Planning API (AriaEngine)**

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

### **5.3. Action Execution API (Oban)**

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

### **5.4. Scenario-Specific API (ConvictionCrisis)**

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

## **6. Test Interface & Demonstration (CLI)**

To run the test and visualize the planner's decisions, a simple, interactive command-line interface will be used.

### **6.1. UI Mockup & Flow**

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

### **6.2. Core CLI Functionality**

The CLI task (mix aria_engine.play_conviction_crisis) will demonstrate:

1. **Temporal Planning**: Showing how the planner schedules actions over time.
2. **Re-entrant Behavior**: Allowing the user to trigger the "Conviction Choice" mid-game and observing the planner generate a new plan.
3. **Real-time Execution**: Using Oban to execute actions at their precise scheduled times, reflected in the UI.
4. **Performance Metrics**: Displaying key metrics like planning time and plan execution accuracy.
