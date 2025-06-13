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

- **`grid_map_size`**: `{width: 25, height: 10}` representing coordinates `(x: 0-24, y: 0-9)`.
- **`map_layout`**: A 2D array where each cell has properties:
  - `walkable`: (boolean)
  - `cover_value`: (integer, e.g., 25% damage reduction)
  - `is_chasm`: (boolean)
  - `is_escape_zone`: (boolean, true if `x >= 24`)
- **Key Locations**:
  - **Bridge Area**: `x` from 3 to 21 inclusive.
  - **Pillars**:
    - `pillar_1`: `{position: (10, 3), hp: 150}`
    - `pillar_2`: `{position: (10, 7), hp: 150}`
  - **Hostage**: `(20, 5)`
- **World Timers & Flags** (values in seconds):
  - `world_time`: (float) Starts at 0.0, advanced by the Game Engine.
  - `hostage_execution_timer`: `30.0`
  - `enemy_reinforcement_timer`: `45.0`

### 3.2. Agent State (Characters & Enemies)

A list of agent structs, each with the following properties:

| Property         | Type                   | Description                                                    |
| ---------------- | ---------------------- | -------------------------------------------------------------- |
| `id`             | Atom/Symbol            | Unique identifier (e.g., `:alex`, `:enemy_1`)               |
| `team`           | Atom/Symbol            | `:player` or `:enemy`                                          |
| `position`       | `{x: int, y: int}`     | Current grid coordinates.                                      |
| `hp`             | Integer                | Current health points.                                         |
| `max_hp`         | Integer                | Maximum health points.                                         |
| `attack_power`   | Integer                | Base damage dealt by the `attack` task.                        |
| `defense`        | Integer                | Flat damage reduction from incoming attacks.                   |
| `move_speed`     | Integer                | Squares per second the agent can move.                         |
| `skills`         | List of Skill Structs  | The agent's available special abilities.                       |
| `active_effects` | List of Effect Structs | Active buffs/debuffs (e.g., `{effect: :slow, duration: 5.0}`). |
| `current_task`   | Task Struct or `nil`   | The task the agent is currently executing.                     |

### 3.3. Initial Scenario Constants

| Character | ID       | HP  | Atk | Def | Move Speed | Position  | Skills            |
| --------- | -------- | --- | --- | --- | ---------- | --------- | ----------------- |
| Alex      | `:alex`  | 120 | 25  | 15  | 4          | `(4, 4)`  | `Delaying Strike` |
| Maya      | `:maya`  | 80  | 35  | 5   | 3          | `(3, 5)`  | `Scorch`          |
| Jordan    | `:jordan`| 95  | 10  | 10  | 3          | `(4, 6)`  | `Now!`            |
| Soldier 1 | `:enemy_1`   | 70  | 20  | 10  | 3          | `(15, 4)` | N/A               |
| Soldier 2 | `:enemy_2`   | 70  | 20  | 10  | 3          | `(15, 5)` | N/A               |
| Soldier 3 | `:enemy_3`   | 70  | 20  | 10  | 3          | `(15, 6)` | N/A               |
| Archer 1  | `:enemy_4`   | 50  | 18  | 5   | 3          | `(18, 3)` | N/A               |
| Archer 2  | `:enemy_5`   | 50  | 18  | 5   | 3          | `(18, 7)` | N/A               |

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
