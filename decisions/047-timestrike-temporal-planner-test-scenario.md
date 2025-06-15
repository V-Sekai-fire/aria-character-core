# ADR-047: TimeStrike Temporal Planner Test Scenario

## Status

Accepted

## Context

The AriaTimestrike temporal planner system requires comprehensive testing to validate its ability to handle complex temporal constraints, dynamic replanning, and multi-agent coordination. A self-contained, real-time tactical scenario is needed that can serve as both a unit test and demonstration of the planner's capabilities.

The test scenario must validate the planner's core abilities:

- Decomposing high-level goals into concrete task sequences
- Managing temporal constraints (cast times, cooldowns, timed objectives)
- Re-planning dynamically when goals change abruptly
- Generating logical plans for multiple non-player agents working towards shared objectives

## Decision

We will implement **"TimeStrike"** - a real-time tactical scenario inspired by "Triangle Strategy" that serves as a robust unit test and demonstration platform for the temporal goal-task-network (GTN) planner.

## Architecture Overview

The system consists of three main components operating in a coordinated loop:

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

### Game Environment

- **Grid Size**: 25x10x1 (using 3D coordinates for future extensibility)
- **Key Locations**:
  - Bridge Pillars: (10, 3, 0) and (10, 7, 0), each with 150 HP
  - Hostage: (20, 5, 0)
  - Escape Zone: Any tile where x >= 24
- **Scenario Timers**:
  - Hostage Execution: 12.0 seconds
  - Enemy Reinforcements: 25.0 seconds

### Agent Specifications

| ID         | Team    | HP  | Atk | Def | Move Speed | Position   | Skills          |
| :--------- | :------ | :-- | :-- | :-- | :--------- | :--------- | :-------------- |
| **Alex**   | :player | 120 | 25  | 15  | 4.0 u/s    | (4, 4, 0)  | Delaying Strike |
| **Maya**   | :player | 80  | 35  | 5   | 3.0 u/s    | (3, 5, 0)  | Scorch          |
| **Jordan** | :player | 95  | 10  | 10  | 3.0 u/s    | (4, 6, 0)  | Now!            |
| Soldier 1  | :enemy  | 70  | 20  | 10  | 3.0 u/s    | (15, 4, 0) | -               |
| Soldier 2  | :enemy  | 70  | 20  | 10  | 3.0 u/s    | (15, 5, 0) | -               |
| Soldier 3  | :enemy  | 70  | 20  | 10  | 3.0 u/s    | (15, 6, 0) | -               |
| Archer 1   | :enemy  | 50  | 18  | 5   | 3.0 u/s    | (18, 3, 0) | -               |
| Archer 2   | :enemy  | 50  | 18  | 5   | 3.0 u/s    | (18, 7, 0) | -               |

### Action Library

| Task / Skill    | Caster | Duration / Cast Time        | Cooldown | Description & Effects                                                                    |
| :-------------- | :----- | :-------------------------- | :------- | :--------------------------------------------------------------------------------------- |
| move_to         | Any    | distance / agent.move_speed | -        | Moves agent to target position. Duration = euclidean_distance / agent.move_speed        |
| attack          | Any    | 1.5s                        | -        | Standard attack. Deals (attacker.atk - target.def) damage                               |
| interact        | Any    | 2.0s                        | -        | Interact with world object (e.g., pillar)                                               |
| defend          | Any    | 1.0s (to activate)          | -        | Gain 50% damage reduction for 5s                                                        |
| wait            | Any    | duration                    | -        | Agent does nothing for set time                                                          |
| Delaying Strike | Alex   | 0.0s (instant)              | 10.0s    | Deals 1.5x damage and applies slow effect for 5.0s                                      |
| Scorch          | Maya   | 2.0s                        | 8.0s     | Deals AoE damage in 3x3 square at target location                                       |
| Now!            | Jordan | 0.5s                        | 20.0s    | **Key Re-entrant Test**: Resets ally's action, allowing immediate re-action             |

## The Core Test: The "Conviction Choice"

The test begins with a vague goal: **survive_the_encounter**. The game engine then forces the planner to commit to one of four specific, mutually exclusive goals, triggering the crucial re-planning event.

### Choice 1: Morality (rescue_hostage)

_"Our allies are our strength. We leave no one behind!"_

- **Goal**: Move a player agent to the hostage's tile before execution timer
- **Success Condition**: alex.position == hostage.position AND world_time <= 12.0
- **Expected Strategy**: Direct rush with Maya using Scorch to clear path, Alex using Delaying Strike on defenders, Jordan using Now! on Alex for maximum movement

### Choice 2: Utility (destroy_bridge)

_"This bridge is their only path. A hard choice now saves countless lives later."_

- **Goal**: Destroy both bridge pillars to prevent enemy reinforcements
- **Success Condition**: pillar_1.hp + pillar_2.hp <= 0
- **Expected Strategy**: Split operation with Alex/Jordan forming defensive line while Maya destroys pillars, Jordan using Now! on Maya to accelerate destruction

### Choice 3: Liberty (escape_scenario)

_"To fight tomorrow, we must survive today. We will retreat and choose our next battlefield."_

- **Goal**: Move all surviving player agents into escape zone
- **Success Condition**: All surviving :player agents have position.x >= 24
- **Expected Strategy**: Fighting retreat with Maya creating chokepoints, Alex using Delaying Strike on pursuers, Jordan defending most threatened ally

### Choice 4: Valor (eliminate_all_enemies)

_"We will make our stand here! Show them the iron will of our house!"_

- **Goal**: Reduce HP of all enemy agents to 0
- **Success Condition**: Empty :enemy team agent list
- **Expected Strategy**: Coordinated assault focusing on high-threat targets (archers), Maya using AoE Scorch, Jordan using Now! for optimal damage timing

## CLI Interface Design

The test provides a real-time command-line interface for visualization and interaction:

```
=== TimeStrike - Temporal Planner Test ===
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

### CLI Functionality

The CLI task (`mix aria_engine.play_timestrike`) demonstrates:

1. **Temporal Planning**: Visual scheduling of actions over time
2. **Re-entrant Behavior**: Mid-game "Conviction Choice" triggering new plan generation
3. **Real-time Execution**: Oban-based precise action timing
4. **Performance Metrics**: Planning time and execution accuracy measurements

## Implementation Requirements

### Core Components

1. **Game State Management**: Complete world state tracking with temporal consistency
2. **Planner Integration**: Goal-task-network planner with temporal constraint handling
3. **Action Execution System**: Precise timing using Oban job scheduling
4. **CLI Interface**: Real-time visualization and interaction capabilities

### Testing Validation

The scenario must validate:

- **Temporal Constraint Handling**: Cooldowns, cast times, movement durations
- **Multi-agent Coordination**: Synchronized actions across multiple agents
- **Dynamic Replanning**: Goal changes triggering complete plan regeneration
- **Resource Management**: HP, cooldowns, positioning as planning constraints
- **Time-critical Decision Making**: Hostage rescue timer pressure

## Consequences

### Positive

- Comprehensive temporal planner validation in realistic scenario
- Clear demonstration of planner capabilities for stakeholders
- Reusable test framework for future planner enhancements
- Performance benchmarking capability for optimization efforts
- Interactive learning tool for understanding temporal planning concepts

### Negative

- Significant implementation complexity requiring game engine integration
- Maintenance overhead for keeping test scenario synchronized with planner changes
- Potential brittleness if scenario assumptions don't match planner capabilities
- Resource requirements for real-time execution and visualization

## Related ADRs

- ADR-042: Temporal Planner Cold Boot Implementation Order (foundation for this test)
- ADR-045: Allen's Interval Algebra for Temporal Relationships (temporal constraint framework)
- ADR-046: User-Friendly Temporal Constraint Specification (constraint specification interface)
- ADR-041: Temporal Solver Tech Stack Requirements (technical foundation)

---

*This ADR establishes the comprehensive test scenario for validating the AriaTimestrike temporal planner's capabilities in a realistic, interactive environment.*
