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

**Decision**: 2D grid-based system with optional Z-level hints for future 3D expansion (weekend-scope appropriate).

**Details**:

- **2D Grid Foundation**: Map stored as simple 2D grid (25×10 for ConvictionCrisis)
- **Coordinate System**: {x, y} coordinates with optional :z metadata for future expansion
- **Voxel Properties**: Each grid cell has properties: `:walkable`, `:cover`, `:chasm`, `:escape_zone`
- **Simple Movement**: Euclidean distance calculation in 2D plane
- **Cover Mechanics**: Adjacent to cover provides 25% damage reduction
- **Path Validation**: Check each cell in 2D path for `:walkable` property
- **Line-of-Sight**: Simple 2D bresenham algorithm for visibility checks
- **Future-Ready**: Data structures support Z-coordinate extension without breaking changes

**Weekend Implementation Scope**:

- Focus on 2D grid with clear, simple mechanics
- Z-coordinate stored but not used in calculations initially
- Can be upgraded to full 3D post-weekend without code rewrite

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

## Resolution 12: Real-Time Input System

**Decision**: Implement real-time player input that never pauses the game engine for Twitch streaming compatibility.

**Details**:

- **No Game Pauses**: Game engine maintains 1000 FPS tick rate continuously
- **Interrupt & Queue**: SPACEBAR cancels current action, immediately starts new one
- **Hotkey System**: 1-9 keys for instant tactical responses during action execution
- **Directional Override**: WASD keys instantly redirect movement without stopping
- **Seamless Transitions**: New actions blend smoothly with interrupted ones
- **Sub-millisecond Response**: All inputs processed within single tick (< 1ms)

## Resolution 13: Opportunity Window Mechanics

**Decision**: Create time-pressured decision points that generate excitement and require skill.

**Details**:

- **Opportunity Prompts**: "Press F NOW!" appears for 1.5 seconds with countdown timer
- **Frame-Perfect Timing**: Optimal interventions require 50-100ms precision windows
- **Risk/Reward Moments**: Narrow timing windows where input determines success/failure
- **Focus Burst**: Hold SHIFT during actions for 25% speed boost (limited energy)
- **Cascading Consequences**: Timing choices immediately affect ongoing situation
- **Visual Feedback**: All interventions get instant visual/audio response within 16ms

## Resolution 14: Twitch Streaming Optimization

**Decision**: Design gameplay specifically for streaming entertainment and audience engagement.

**Details**:

- **Visible Tension**: Clear countdown timers create viewer excitement during decision points
- **No Dead Time**: Constant tactical decisions prevent boring "watch AI" moments
- **Clip-Worthy Moments**: High-tension interventions create shareable highlights
- **Commentary Opportunities**: Natural moments for streamers to explain decisions
- **Streaming Engagement Pattern**: Build Tension → Decision Window → Immediate Feedback → Consequence Cascade
- **Future Chat Integration**: Framework ready for viewer voting on tactical options

## Resolution 15: Imperfect Information & Dynamic Opportunities

**Decision**: Deliberately introduce uncertainty and incomplete information to create genuine opportunities for player intervention despite optimal planning.

**Details**:

- **Fog of War**: Planner makes decisions with incomplete battlefield information
  - Enemy positions estimated, not precisely known until line-of-sight
  - Hidden environmental hazards revealed only when approached
  - Agent stamina/health not perfectly predictable under stress
  - Equipment reliability has random failure chances
- **Dynamic Environment**: Battlefield changes during execution create new opportunities
  - Enemies adapt their tactics based on player actions
  - Environmental events (explosions, structural collapse) create new paths/obstacles
  - Time-sensitive opportunities appear (doors closing, reinforcements arriving)
  - Resource scarcity forces suboptimal initial plans
- **Human vs AI Capabilities**: Player excels where AI planning has limitations
  - **Pattern Recognition**: Player spots enemy behavioral patterns AI misses
  - **Intuitive Risk Assessment**: Human judgment on "gut feeling" moments
  - **Creative Problem Solving**: Unconventional approaches AI doesn't consider
  - **Situational Adaptation**: Rapid response to unexpected situations
- **Designed Suboptimality**: AI planner intentionally uses "good enough" solutions
  - Plans optimize for 80% success rather than theoretical perfection
  - Conservative assumptions leave room for player aggressive optimization
  - Multiple viable approaches with different risk/reward profiles
  - AI suggests safe path, player can choose risky shortcuts
- **Information Asymmetry**: Player has access to information the planner lacks
  - Real-time visual assessment of enemy morale and positioning
  - Audio cues (footsteps, radio chatter) that affect tactical decisions
  - Environmental details that change action effectiveness
  - Team member status indicators the planner doesn't perfectly model

**Opportunity Generation Mechanics**:

- **Uncertainty Cascades**: Small unknowns create larger decision points
- **Adaptive Opposition**: Enemies react to player style, creating new challenges
- **Resource Pressure**: Limited resources force prioritization decisions
- **Time Constraints**: Perfect solutions unavailable under time pressure
- **Multi-Objective Tension**: Conflicting goals require player value judgments

## Resolution 16: Friday-Sunday Implementation Scope

**Decision**: Prioritize core temporal planner functionality over polish features for weekend timeline.

**Details**:

- **MUST HAVE (Core MVP)**:
  - Basic temporal state architecture and data structures
  - Simple Oban job scheduling and execution
  - Minimal ConvictionCrisis scenario (fixed map, 2 agents, 1 enemy)
  - Basic CLI with real-time display (no fancy animations)
  - Core stability verification (simplified Lyapunov functions)
  - Essential player input (SPACEBAR interrupt, basic hotkeys)
- **SHOULD HAVE (If Time Permits)**:
  - Full ConvictionCrisis scenario with all agents and enemies
  - Polished CLI with smooth animations and visual effects
  - Complete opportunity window mechanics with timing challenges
  - Comprehensive error handling and edge cases
  - Performance optimization for 1000 FPS target
- **COULD HAVE (Post-Weekend)**:
  - Advanced streaming features (chat integration framework)
  - Complex environmental dynamics and fog of war
  - Sophisticated AI adaptation and pattern recognition
  - Multi-level maps and terrain complexity
  - Extensive testing and documentation
- **WON'T HAVE (Future Versions)**:
  - 3D graphics or complex visual effects
  - Multiplayer support
  - Save/load game functionality
  - Advanced audio system
  - Mobile or web deployment

**Implementation Strategy**:

- **Friday**: Core temporal planner architecture and basic Oban integration
- **Saturday**: ConvictionCrisis game logic and basic CLI interface
- **Sunday**: Player input system and opportunity mechanics integration
- **Buffer**: Use simplified implementations that can be enhanced post-weekend

## Resolution 17: LLM-Assisted Development Time Uncertainty

**Decision**: Acknowledge that LLM assistance makes time estimation extremely unreliable and build adaptive development strategy.

**Details**:

- **Velocity Uncertainty**: LLM assistance can accelerate development 5-50x in some areas, but may not help with others
  - **Fast with LLM**: Data structure design, boilerplate code, algorithm implementation
  - **Unknown Speed**: Complex integrations, debugging edge cases, performance optimization
  - **Still Slow**: Understanding existing codebase, architectural decisions, testing strategies
- **Adaptive Planning Strategy**: Use time-boxed iterations with frequent re-assessment
  - **2-hour time boxes**: Assess progress every 2 hours and adjust scope
  - **Minimum Viable Demos**: Focus on end-to-end working demos at each stage
  - **Scope Flexibility**: Ready to cut features if complexity exceeds LLM assistance
  - **Parallel Development**: Work on multiple approaches simultaneously when uncertain
- **Risk Mitigation**: Plan for both scenarios where LLM helps massively and where it doesn't
  - **High Acceleration Scenario**: Full implementation with polish and advanced features
  - **Low Acceleration Scenario**: Bare minimum MVP with manual fallbacks
  - **Blockers Identified**: Pre-identify areas where LLM might not help (debugging, integration)
- **Success Metrics**: Define success by working demonstrations, not feature completeness
  - **Core Success**: Temporal planner schedules and executes one action via Oban
  - **Enhanced Success**: Player can interrupt and redirect actions in real-time
  - **Full Success**: Complete ConvictionCrisis scenario with all player intervention mechanics
- **Learning Adaptation**: Use weekend as experiment to understand LLM development patterns
  - Track which tasks are accelerated vs remain difficult
  - Document where LLM assistance is most/least effective
  - Build better estimation models for future LLM-assisted projects

**Implementation Approach**:

- Start with smallest possible working demonstration
- Expand incrementally based on actual development velocity
- Always maintain working state for demonstration purposes
- Be prepared to pivot implementation approach if complexity exceeds LLM capability

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
10. ✅ **Map System**: 2D grid-based with future 3D extensibility
11. ✅ **Queue Idempotency**: All actions are idempotent intents that can be rejected
12. ✅ **Real-Time Input**: Never-pause input system for streaming compatibility
13. ✅ **Opportunity Windows**: Time-pressured decision points requiring skill
14. ✅ **Streaming Optimization**: Designed for Twitch entertainment and engagement
15. ✅ **Imperfect Information**: Uncertainty and dynamics create genuine opportunities
16. ✅ **Weekend Scope**: Prioritized implementation plan for Friday-Sunday timeline
17. ✅ **LLM Development**: Adaptive strategy for unpredictable development velocity

## Next Steps

1. ✅ **COMPLETED**: All design questions identified and resolved
2. ✅ **COMPLETED**: All design decisions documented and locked in
3. 🚀 **READY**: Begin TDD implementation with complete design clarity
