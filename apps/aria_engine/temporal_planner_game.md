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

### **Choice 1: Morality (rescue_hostage)**

_"Our allies are our strength. We leave no one behind\!"_

- **Goal:** Move a player agent to the hostage's tile before the execution timer runs out.
- **Success Condition:** alex.position \== hostage.position AND world_time \<= 30.0.
- **Likely Plan:** A direct rush. Maya uses Scorch to clear a path, Alex uses Delaying Strike to disable a key defender, and Jordan uses Now\! on Alex to maximize forward movement.

### **Choice 2: Utility (destroy_bridge)**

_"This bridge is their only path. A hard choice now saves countless lives later."_

- **Goal:** Destroy the two bridge pillars to prevent enemy reinforcements.
- **Success Condition:** pillar_1.hp \+ pillar_2.hp \<= 0\.
- **Likely Plan:** A split operation. Alex and Jordan form a defensive line to intercept enemies while Maya moves into position to interact with and cast Scorch on the pillars. Jordan may use Now\! on Maya to accelerate the destruction.

### **Choice 3: Liberty (escape_scenario)**

_"To fight tomorrow, we must survive today. We will retreat and choose our next battlefield."_

- **Goal:** Move all surviving player agents into the designated escape zone.
- **Success Condition:** All surviving agents on :player team have position.x \>= 24\.
- **Likely Plan:** A fighting retreat. Maya uses Scorch to create chokepoints, Alex uses Delaying Strike on the fastest pursuers, and Jordan uses defend to protect the most threatened ally while the team moves toward the map edge.

### **Choice 4: Valor (eliminate_all_enemies)**

_"We will make our stand here\! Show them the iron will of our house\!"_

- **Goal:** Reduce the HP of all agents on the :enemy team to 0\.
- **Success Condition:** The list of agents on the :enemy team is empty.
- **Likely Plan:** A coordinated assault. The planner should identify the highest threats (e.g., archers) and focus fire. Maya uses Scorch for maximum AoE damage, Alex targets key enemies, and Jordan uses Now\! on whichever ally can secure a kill or deal the most effective damage.

## 6. Technical Architecture & Implementation

This section outlines the Elixir-based implementation, focusing on the temporal extensions required to handle time-sensitive actions and goals. The architecture relies on Oban for scheduling, ensuring that actions are executed at the correct time.

### 6.1. Temporal Planning Architecture

The core of the implementation is the integration between the **Temporal GTN Planner** and an **Oban Job Queue**.

1. The Game Loop provides the current state and a goal to the Planner.
2. The Planner generates a **Temporal Plan**, which is a sequence of actions with specific start times and durations.
3. Each action in the plan is scheduled as a timed **Oban Job** (e.g., MoveJob, SkillJob).
4. When a job executes, it updates the Game State.
5. If the goal changes, the Planner **cancels pending jobs** from the old plan and schedules new jobs for the new plan.

### 6.2. Key Implementation Components

- **AriaEngine.TemporalState**: Extends the core State module to handle temporal facts. It can query the state of an object (e.g., alex.hp) at any given point in time.
- **AriaEngine.TemporalDomain**: Defines actions and methods with temporal properties like duration and time-based preconditions.
- **AriaEngine.TemporalPlanner**: The main planning engine. It contains the logic for plan(...) and replan(...), which handles plan invalidation and generation.
- **AriaEngine.TemporalPlan**: A data structure representing the plan itself, containing a list of timed actions and the temporal constraints between them (e.g., "Action A must finish before Action B starts").
- **AriaEngine.Jobs.GameActionJob**: An Oban worker that executes a single game action. It takes the action details (e.g., {agent: "alex", action: :move_to, target: {8, 4, 0}}) and performs the necessary state update.
- **ConvictionCrisis.GameState**: Manages the specific state for this scenario, including initialization, win/loss condition checks, and applying action effects.

### **6.1. UI Mockup & Flow**

### 6.1. User Interface Design

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

### 6.2. CLI Implementation Requirements

The CLI task (`mix aria_engine.play_conviction_crisis`) should demonstrate:

1. **Temporal Planning**: Show how the planner schedules actions over time
2. **Re-entrant Behavior**: Allow mid-game goal changes and observe re-planning
3. **Real-time Execution**: Use Oban to execute actions at precise times
4. **Conflict Resolution**: Handle temporal constraints and resource conflicts
5. **Performance Metrics**: Display planning time, plan quality, execution accuracy

This implementation will serve as both a unit test for the temporal planner and a demonstration of how Aria components work together in a real-time, decision-making system.
