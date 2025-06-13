# Temporal Planner Design Resolutions

This document captures the finalized design decisions for the temporal, re-entrant goal-task-network (GTN) planner implementation.

## Resolution 1: State Architecture Migration

**Decision**: Do NOT keep existing state. Migrate all code to use the new temporal state architecture.

**Details**:

- Remove old state structures from existing code
- All modules must use the new temporal state defined in `temporal_planner_data_structures.md`
- Complete migration required - no backwards compatibility with old state

## Resolution 2: Oban Queue Design

**Decision**: Use a unified Oban queue for all actions (not separate queues for temporal actions).

**Details**:

- Single queue handles both temporal and non-temporal actions
- Simpler architecture and easier to manage
- Actions differentiated by their payload/metadata, not by queue separation

## Resolution 3: Game Engine Separation

**Decision**: Separate GameEngine from the planner.

**Details**:

- Clear separation of concerns between planning and game execution
- GameEngine handles game-specific logic and state
- Planner focuses on temporal planning algorithms and stability

## Resolution 4: Mandatory Stability Verification

**Decision**: Always verify stability (not optional).

**Details**:

- Following the pattern of existing GTN implementations where goals are always verified
- Stability verification is a core requirement, not an optional optimization
- Every plan must pass stability checks before execution

## Resolution 5: ConvictionCrisis as Test Domain

**Decision**: Treat ConvictionCrisis as a test domain for the temporal planner.

**Details**:

- ConvictionCrisis serves as the primary test case and validation domain
- Use it to demonstrate and validate all temporal planning features
- Design the domain to exercise all aspects of the temporal planner

## Resolution 6: Game Engine Integration & Real-time Execution

**Decision**: Implement a high-frequency tick-based game loop with Oban integration for VR-style low latency.

**Details**:

- Game Engine runs on a 1ms tick cycle (1000 FPS) to achieve sub-7ms photon-to-photon latency
- Total latency budget: 1ms tick + 2ms processing + 2ms display + 2ms buffer = ~7ms end-to-end
- Oban jobs execute actions at their scheduled times and update game state
- Re-planning triggers: goal changes, action failures, or significant state changes
- Planning occurs asynchronously and doesn't block game execution
- Game state changes are queued and applied during tick updates
- Sub-millisecond precision for temporal action scheduling

## Resolution 7: Conviction Choice Mechanics

**Decision**: Implement choice as a real-time decision with time pressure and default fallback.

**Details**:

- Conviction Choice triggers after initial survive_encounter goal is set
- Game continues running at normal speed (no pause) with a 5-second decision window
- CLI displays choice menu with countdown timer (5.0s, 4.9s, 4.8s...)
- User input (1-4 keys) immediately triggers re-planning with new goal
- If no choice made within 5 seconds, defaults to "Morality" (rescue_hostage)
- Time pressure creates realistic tactical decision-making stress
- Alternative: Add "slow-motion mode" option (0.5x speed) during choice for tactical consideration

## Resolution 8: CLI Implementation Details

**Decision**: Use terminal control sequences with async input handling and ultra-high-frequency updates.

**Details**:

- Use ANSI escape codes to clear/update terminal display
- Async process handles keyboard input without blocking game loop
- Display updates every 1ms synchronized with game ticks for ultra-smooth real-time feedback
- ETA calculations based on current time + remaining action duration with sub-millisecond precision
- User input (SPACE/Q/C) sends messages to main game process with minimal latency
- 1000 FPS refresh rate provides true VR-style responsiveness for temporal planning visualization

## Resolution 9: Action Duration & Movement Calculations

**Decision**: Use Euclidean distance with fixed movement speed.

**Details**:

- Movement speed: 3 units per second for all agents
- Duration formula: `distance = sqrt((x2-x1)² + (y2-y1)² + (z2-z1)²)`, time = distance / 3.0
- Interrupted actions: store progress and resume from current position
- Cooldowns are absolute timers - remain active during re-planning
- Actions validate cooldown availability before being added to plan

## Resolution 10: Map & Terrain System

**Decision**: 3D voxel-based system with layered properties to match 3D coordinates.

**Details**:

- Map stored as 3D voxel grid (25×10×1 initially, expandable for multi-level terrain)
- Each voxel has properties: `:walkable`, `:cover`, `:chasm`, `:escape_zone`, `:elevation`
- 3D coordinates {x, y, z} directly map to voxel positions
- Cover provides 25% damage reduction when target is adjacent to cover voxel
- Movement validation: check each voxel in 3D path for `:walkable` property
- Line-of-sight: 3D bresenham algorithm accounting for elevation and obstacles
- Future extensibility: flying units, multi-story buildings, vertical terrain

## Resolution 11: Oban Queue Idempotency & Intent Rejection

**Decision**: All Oban queue actions must be designed as idempotent intents that can be rejected at execution time.

**Details**:

- **Idempotent Design**: Each action job must be safe to execute multiple times without side effects
  - Actions check current state validity before execution
  - Duplicate executions return early if action is already completed/obsolete
  - State transitions are atomic and conflict-resistant
- **Intent-Based Architecture**: Actions are "intents to act" rather than guaranteed commands
  - Jobs carry sufficient context to validate execution conditions at runtime
  - Actions can be rejected if preconditions are no longer valid
  - Rejection reasons logged for debugging and re-planning triggers
- **Execution-Time Validation**: Actions verify state compatibility before applying effects
  - Agent position validation (ensure agent is at expected location)
  - Resource availability checks (cooldowns, stamina, inventory)
  - Environmental validity (target still exists, path still clear)
  - Goal relevance (action still supports current goal)
- **Graceful Rejection Handling**: Failed actions don't crash the game loop
  - Rejected actions trigger partial re-planning for affected agents
  - State inconsistencies detected and corrected automatically
  - Alternative actions suggested when primary intent fails
- **Cancellation Support**: Actions can be cancelled before execution
  - Re-planning cancels superseded actions via `cancel_action/1`
  - Cancelled actions are marked as `:cancelled` in job status
  - Game state remains consistent during plan transitions

**Implementation Requirements**:

- All `GameActionJob.perform/1` implementations must be idempotent
- Actions return `{:ok, :completed}`, `{:ok, :rejected, reason}`, or `{:error, reason}`
- Rejected actions trigger `TemporalPlanner.replan_partial/2` for affected agents
- Job metadata includes sufficient context for execution-time validation

## Status: All Design Questions Resolved ✅

**Complete Design Coverage**: All architectural and game design questions have been identified and resolved with specific implementation decisions.

**Resolved Categories**:

1. ✅ **State Architecture**: Complete migration to temporal state
2. ✅ **Queue Design**: Unified Oban queue for all actions
3. ✅ **Engine Separation**: Clear separation between GameEngine and planner
4. ✅ **Stability**: Mandatory verification with Lyapunov functions
5. ✅ **Test Domain**: ConvictionCrisis as validation scenario
6. ✅ **Game Engine Integration**: Tick-based loop with Oban scheduling
7. ✅ **Conviction Choice**: User input triggers immediate re-planning
8. ✅ **CLI Implementation**: ANSI terminal with async input handling
9. ✅ **Action Calculations**: Euclidean distance with fixed movement speed
10. ✅ **Map System**: Grid-based with basic terrain properties
11. ✅ **Queue Idempotency**: All actions are idempotent intents that can be rejected

## Next Steps

1. ✅ **COMPLETED**: All design questions identified and resolved
2. ✅ **COMPLETED**: All design decisions documented and locked in
3. 🚀 **READY**: Begin TDD implementation with complete design clarity
