# ADR-086: TimeStrike Game Domain Model Specification

**Status:** Active  
**Date:** June 16, 2025  
**Priority:** High

## Context

The AriaEngine temporal planner requires a complete, well-defined game domain model to serve as a reference implementation for testing, development, and demonstration purposes. The TimeStrike game provides an ideal domain that showcases temporal planning capabilities through time-sensitive gameplay mechanics.

Based on the current codebase structure (AriaEngine, AriaCoordinate, AriaData) and existing ADR references to TimeStrike, we need a domain that demonstrates:

- Temporal rewind and branching mechanics
- Agent movement and tactical positioning
- Real-time decision making under pressure
- Multi-agent coordination and conflict
- Environmental hazards and opportunities
- Win/loss condition evaluation

## Decision

Define the **TimeStrike** game domain where agents compete to achieve objectives while manipulating time through rewind mechanics and temporal branches. Players must balance immediate tactical advantages against long-term strategic positioning in a time-sensitive battlefield environment.

### Domain Specification

### TimeStrike Domain Specification

#### Core Game Mechanics

**Time Rewind System:**

- Players can initiate temporal rewinds to previous game states
- Each rewind creates a new timeline branch
- Actions taken after rewind affect future outcomes
- Limited rewind charges per match (3-5 uses)
- Rewind costs increase with distance rewound

**Temporal Branches:**

- Multiple timeline states exist simultaneously
- Players can observe potential futures before committing
- Branch collapse occurs when rewind charges are exhausted
- Successful branches become the canonical timeline

#### World Model

**Environment:**

- 3D battlefield using AriaCoordinate system (10x10x3 units)
- Strategic positions: high ground, cover points, objective zones
- Dynamic environmental hazards (temporal storms, gravity wells)
- Temporal anchor points that resist rewind effects
- Spawn zones for player and AI agents

**Entities:**

- **Player Agents:** Controllable units with unique abilities and health
- **AI Opponents:** Autonomous agents with predictable behavior patterns
- **Objectives:** Capturable points, resources, or targets
- **Hazards:** Environmental dangers that damage or disable agents
- **Temporal Anchors:** Fixed points that maintain state through rewinds

#### Agent Capabilities

**Movement Actions:**

- `move_to(position, agent_id)` - Move agent to battlefield coordinates
- `dash(direction, distance, agent_id)` - Rapid movement with cooldown
- `take_cover(cover_point, agent_id)` - Occupy defensive position

**Combat Actions:**

- `attack_target(target_id, agent_id)` - Engage enemy agent
- `use_ability(ability_type, target, agent_id)` - Special tactical abilities
- `heal_ally(ally_id, agent_id)` - Restore allied agent health

**Temporal Actions:**

- `initiate_rewind(rewind_seconds, agent_id)` - Start temporal rewind
- `observe_branch(branch_id, agent_id)` - Preview timeline outcomes
- `commit_branch(branch_id, agent_id)` - Lock in timeline choice

**Objective Actions:**

- `capture_point(objective_id, agent_id)` - Secure battlefield objective
- `defend_position(position, agent_id)` - Hold strategic location
- `extract_resource(resource_id, agent_id)` - Collect tactical resources

#### Temporal Mechanics

**Rewind Constraints:**

- Maximum rewind distance: 30 seconds of game time
- Rewind cooldown: 45 seconds between uses
- Rewind charges: 3 per match, regenerate slowly over time
- Temporal fatigue: Agent performance degrades with excessive rewind use

**Branch Evaluation:**

- Each branch maintains separate game state
- Branch scoring based on objective completion probability
- Automatic branch pruning when resources are exhausted
- Player choice determines which branch becomes reality

### Initial State Examples

#### Scenario 1: Single Agent Resource Rush

**World State:**

```elixir
%{
  agents: [
    %{id: "agent_1", position: {0.0, 0.0, 0.0}, inventory: [], capacity: 10, energy: 100}
  ],
  resource_nodes: [
    %{id: "crystal_1", position: {5.0, 0.0, 0.0}, type: :crystal_shard, quantity: 3},
    %{id: "ore_1", position: {-3.0, 4.0, 0.0}, type: :metal_ore, quantity: 5},
    %{id: "energy_1", position: {2.0, -2.0, 1.0}, type: :energy_cell, quantity: 2}
  ],
  delivery_zones: [
    %{id: "depot_1", position: {0.0, 10.0, 0.0}, accepts: [:crystal_shard, :metal_ore],
      radius: 2.0, operational_hours: {9, 17}}
  ],
  current_time: ~T[10:00:00],
  obstacles: []
}
```

**Goal State:**

- All resources collected and delivered to depot_1
- Agent returns to spawn point
- Total delivery value > 100 points

#### Scenario 2: Multi-Agent Coordination

**World State:**

```elixir
%{
  agents: [
    %{id: "collector", position: {0.0, 0.0, 0.0}, inventory: [], capacity: 15, energy: 100},
    %{id: "transporter", position: {10.0, 0.0, 0.0}, inventory: [], capacity: 20, energy: 100}
  ],
  resource_nodes: [
    %{id: "crystal_field", position: {-5.0, -5.0, 0.0}, type: :crystal_shard, quantity: 8},
    %{id: "ore_deposit", position: {15.0, -3.0, 0.0}, type: :metal_ore, quantity: 12}
  ],
  delivery_zones: [
    %{id: "crystal_depot", position: {-10.0, 10.0, 0.0}, accepts: [:crystal_shard],
      radius: 1.5, operational_hours: {8, 16}},
    %{id: "ore_depot", position: {20.0, 10.0, 0.0}, accepts: [:metal_ore],
      radius: 2.0, operational_hours: {10, 18}}
  ],
  current_time: ~T[11:00:00],
  obstacles: [
    %{id: "wall_1", bounds: {min: {0.0, 2.0, 0.0}, max: {8.0, 4.0, 2.0}}}
  ]
}
```

**Goal State:**

- Crystal collector specializes in crystal_shard collection and delivery
- Transporter handles metal_ore due to higher capacity needs
- Both agents coordinate to avoid conflicts at resource nodes
- All deliveries completed before depot closing times

#### Scenario 3: Time-Critical Energy Cell Recovery

**World State:**

```elixir
%{
  agents: [
    %{id: "rescue_1", position: {0.0, 0.0, 0.0}, inventory: [], capacity: 8, energy: 100},
    %{id: "rescue_2", position: {5.0, 5.0, 0.0}, inventory: [], capacity: 8, energy: 100}
  ],
  resource_nodes: [
    %{id: "crashed_transport", position: {12.0, 8.0, 0.0}, type: :energy_cell,
      quantity: 6, decay_start: ~T[09:30:00]}
  ],
  delivery_zones: [
    %{id: "emergency_depot", position: {1.0, 1.0, 0.0}, accepts: [:energy_cell],
      radius: 1.0, operational_hours: {0, 23}}
  ],
  current_time: ~T[09:45:00],
  obstacles: [
    %{id: "debris_field", bounds: {min: {8.0, 6.0, 0.0}, max: {14.0, 10.0, 1.0}}}
  ]
}
```

**Goal State:**

- Recover maximum energy cells before significant decay (>15 minutes = major value loss)
- Navigate around debris field efficiently
- Coordinate agents to minimize travel time
- Deliver cells while retaining >70% original value

### Solvable Problems

#### Problem 1: Optimal Collection Sequence

**Given:** Single agent, multiple resource nodes, one delivery zone
**Constraint:** Minimize total travel time
**Solution Approach:** Traveling salesman variant with return to depot
**Solvability:** Deterministic solution using nearest-neighbor or exact TSP algorithms

#### Problem 2: Load Balancing with Capacity Constraints

**Given:** Multiple agents with different capacities, resource nodes with varying quantities
**Constraint:** All resources must be collected, respect agent capacity limits
**Solution Approach:** Bin packing optimization with spatial considerations
**Solvability:** Greedy allocation with backtracking for optimization

#### Problem 3: Temporal Coordination with Deadlines

**Given:** Multiple agents, time-sensitive resources, depot operational windows
**Constraint:** Maximize delivered value before deadlines
**Solution Approach:** Priority scheduling with decay function optimization
**Solvability:** Dynamic programming with temporal constraints

#### Problem 4: Multi-Agent Pathfinding with Obstacles

**Given:** Multiple agents, complex obstacle layout, shared destination zones
**Constraint:** Avoid agent collisions, navigate around static obstacles
**Solution Approach:** Cooperative A\* with reservation tables
**Solvability:** Well-established multi-agent pathfinding algorithms

#### Problem 5: Resource Transfer Optimization

**Given:** Agents with complementary capabilities, transfer-allowed resources
**Constraint:** Optimize resource distribution for maximum efficiency
**Solution Approach:** Network flow optimization with spatial costs
**Solvability:** Min-cost max-flow algorithms adapted for spatial domains

### Integration with AriaEngine

#### STN Constraint Modeling

**Temporal Variables:**

- `start_collect[agent, resource]` - Agent begins resource collection
- `finish_collect[agent, resource]` - Agent completes resource collection
- `start_deliver[agent, zone]` - Agent begins delivery process
- `finish_deliver[agent, zone]` - Agent completes delivery

**Constraint Examples:**

```
# Collection duration constraints
finish_collect[agent_1, crystal_1] - start_collect[agent_1, crystal_1] = [2, 5]

# Delivery window constraints
start_deliver[agent_1, depot_1] >= depot_1.open_time
finish_deliver[agent_1, depot_1] <= depot_1.close_time

# Resource decay constraints
finish_deliver[agent_1, depot_1] - energy_cell.collection_time <= 30_minutes
```

#### Coordinate System Integration

Leverage AriaCoordinate for:

- **Distance calculations:** Euclidean distance for movement cost estimation
- **Collision detection:** Agent and obstacle boundary checking
- **Zone membership:** Point-in-polygon tests for delivery zones
- **Pathfinding:** A\* with coordinate-based heuristics

#### Data Model Integration

Use AriaData structures for:

- **Entity persistence:** Agent states, resource node status, world state
- **Event logging:** Action execution history, state transitions
- **Performance metrics:** Solution quality, execution time, resource utilization

## Implementation Plan

- [ ] Define core domain structs and types
- [ ] Implement initial state generators for each scenario
- [ ] Create goal state validation functions
- [ ] Build action execution engine with precondition checking
- [ ] Develop problem generators with guaranteed solvability
- [ ] Integrate with AriaEngine STN constraint modeling
- [ ] Create test suite with solved reference cases
- [ ] Document solution approaches for each problem type

## Success Criteria

1. **Completeness:** All domain elements clearly specified with no ambiguities
2. **Solvability:** Every generated problem has at least one valid solution
3. **Integration:** Seamless operation with existing AriaEngine, AriaCoordinate, and AriaData modules
4. **Scalability:** Domain supports problems ranging from single-agent to complex multi-agent scenarios
5. **Testability:** Reference solutions available for automated validation

## Consequences

**Benefits:**

- Provides concrete testing ground for temporal planning algorithms
- Demonstrates real-world applicability of the AriaEngine system
- Enables performance benchmarking with measurable outcomes
- Supports development of visualization and monitoring tools

**Risks:**

- Domain complexity may exceed initial planning algorithm capabilities
- Performance characteristics may not generalize to other domains
- Maintenance overhead for keeping domain model synchronized with engine capabilities

**Mitigation:**

- Implement domain in phases, starting with simplest scenarios
- Design modular domain components for easy extension and modification
- Maintain clear separation between domain logic and engine integration
