# Temporal Planner Design Resolutions

This document captures the finalized design decisions for the temporal, re-entrant goal-task-network (GTN) planner implementation.

## Resolution 1: State Architecture Migration

**Decision**: Do NOT keep existing state. Migrate all code to use the new temporal state architecture.

**Details**:

- Remove old state structures from existing code
- All modules must use the new temporal state defined in `temporal_plan- **Contradiction Resolution Process**:

- **CONTRADICTION IDENTIFIED**: Resolution 14 "No Dead Time" conflicts with realistic military operations
  - **Problem**: Real warfare has natural lulls (5 minutes action, months idle) that create strategic tension
  - **Current Resolution**: "Constant tactical decisions prevent boring 'watch AI' moments"
  - **Contradiction**: Eliminates realistic downtime that builds anticipation and makes action meaningful
  - **RESOLUTION**: Created Resolution 21 to replace "No Dead Time" with "Meaningful Downtime"
  - **Result**: Now honors realistic military pacing while maintaining streaming engagement_data_structures.md`
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

## Resolution 18: Concrete MVP Definition

**Decision**: Define exactly what constitutes success for the weekend project, leveraging existing AriaEngine infrastructure and focusing on temporal extensions.

**Details**:

- **MVP Success Criteria (All Must Work)**:

  1. **Temporal State Extension**: Extend existing `AriaEngine.State` to include time and action scheduling
  2. **Oban Job Integration**: One `GameActionJob` schedules and executes a timed action
  3. **Real-Time CLI**: Terminal display shows action progress with timestamps
  4. **Player Interruption**: SPACEBAR cancels scheduled action, triggers re-planning
  5. **Basic Stability**: Simple Lyapunov function validates action reduces distance to goal

- **MVP Technical Stack (Leveraging Existing Code)**:

  - **Base**: Existing `AriaEngine.State`, `AriaEngine.Domain`, `AriaEngine.Plan`
  - **Extensions**: `TemporalState` (extends State), `GameActionJob` (Oban worker)
  - **New Modules**: `ConvictionCrisis.CLI`, `ConvictionCrisis.GameEngine`
  - **Infrastructure**: Existing `AriaQueue`, `AriaData.QueueRepo`, Oban setup

- **MVP ConvictionCrisis Scenario (Ultra-Minimal)**:

  - **Map**: 10×6 grid, Alex starts at {2,3}, goal: reach {8,3}
  - **Action**: `move_to` only - no combat, skills, or enemies
  - **Duration**: Movement takes `distance / 3.0` seconds (existing calculation pattern)
  - **Display**: ASCII grid updated every 100ms showing Alex's position as 'A'

- **MVP Data Structures (Minimal Extensions)**:

```elixir
# Extend existing AriaEngine.State
defmodule TemporalState do
  @enforce_keys [:state, :current_time, :scheduled_actions]
  defstruct [:state, :current_time, scheduled_actions: []]
end

# Simple timed action
@type timed_action :: %{
  id: String.t(),
  agent: String.t(),
  action: atom(),
  args: list(),
  start_time: DateTime.t(),
  duration: float(),
  status: :scheduled | :executing | :completed
}
```

- **MVP Implementation Files (5 new files maximum)**:

  1. `lib/aria_engine/temporal_state.ex` - Temporal state wrapper
  2. `lib/aria_engine/jobs/game_action_job.ex` - Oban worker
  3. `lib/aria_engine/conviction_crisis/game_engine.ex` - Game loop
  4. `lib/aria_engine/conviction_crisis/cli.ex` - Terminal interface
  5. `lib/mix/tasks/aria_engine.conviction_crisis.ex` - Mix task entry point

- **Weekend Acceptance Test (10-minute demo)**:

  1. Run: `mix aria_engine.conviction_crisis`
  2. See: ASCII grid with Alex ('A') at position {2,3}
  3. Game: Auto-plans movement to {8,3}, shows "Moving to {8,3} - ETA: 2.0s"
  4. Watch: Alex position updates in real-time across grid
  5. Interrupt: Press SPACEBAR at {5,3} - Alex stops, shows "Replanning from {5,3}"
  6. Continue: New plan generated, Alex continues to {8,3}
  7. Success: "Mission Complete!" when Alex reaches goal

- **Success Definition**: If this 10-minute demo runs reliably using existing AriaEngine infrastructure with minimal new code, the temporal planner MVP is complete.

- **Post-MVP Extensions (If Time Permits)**:
  - Add simple enemy at {6,3} that Alex must avoid
  - Add conviction choice: "1: Stealth, 2: Combat, 3: Diplomacy"
  - Add basic action cooldowns and stamina

## Resolution 19: 3D Coordinates with Godot Conventions

**Decision**: Use 3D coordinates with Godot engine conventions for future compatibility, but keep all movement on Z=0 for weekend implementation speed.

**Details**:

- **Godot Coordinate System**: Follow Godot's right-handed 3D coordinate system
  - **X-axis**: Points right (positive = east, negative = west)
  - **Y-axis**: Points up (positive = up/north, negative = down/south)
  - **Z-axis**: Points toward camera (positive = forward/out, negative = backward/into screen)
- **2D Movement on Z=0 Plane**: All ConvictionCrisis action happens on Z=0 for simplicity
  - Agents move in X-Y plane only: `{x, y, 0}`
  - Map coordinates: X=0-24 (width), Y=0-9 (height), Z=0 (ground level)
  - Distance calculation: `sqrt((x2-x1)² + (y2-y1)²)` (Z difference always 0)
- **Future 3D Extensibility**: Data structures ready for multi-level expansion
  - Z coordinate stored in all position data
  - Distance function can handle full 3D when needed
  - Map system designed to add Z-levels without code rewrite
- **Godot-Compatible Movement**: Positions translate directly to Godot Vector3
  - AriaEngine `{5, 3, 0}` → Godot `Vector3(5, 3, 0)`
  - No coordinate transformation needed for future Godot integration
  - Camera perspective and physics align with Godot conventions

**Weekend Implementation Benefits**:

- **Speed**: 2D pathfinding and collision is much faster to implement
- **Debugging**: Easier to visualize and debug in 2D ASCII display
- **Compatibility**: Future upgrade to 3D Godot frontend requires no coordinate changes
- **Mathematical Simplicity**: Distance calculations avoid Z-axis complexity

**Data Structure Pattern**:

```elixir
# All positions use 3D coordinates with Z=0
position: {12, 5, 0}  # Godot-compatible Vector3
movement_speed: 3.0   # units per second in X-Y plane
target: {18, 7, 0}    # destination coordinates
```

## Resolution 21: Realistic Tension Pacing (Corrects Resolution 14)

**Decision**: Replace "No Dead Time" with "Meaningful Downtime" that builds tension and makes action sequences more impactful.

**Details**:

- **Realistic Military Pacing**: Honor the "5 minutes of terror, months of boredom" nature of real operations
  - **Preparation Phases**: Planning, equipment checks, intel gathering create anticipation
  - **Travel Phases**: Movement to objectives with growing tension but limited action
  - **Contact Phases**: Intense bursts of tactical decision-making and combat
  - **Aftermath Phases**: Dealing with consequences, regrouping, medical aid
- **Streaming-Optimized Downtime**: Transform "boring" moments into engaging content
  - **Intel Analysis**: Player reviews enemy patterns, discusses tactical options
  - **Equipment Decisions**: Choose loadouts, review team member specializations
  - **Route Planning**: Player can override AI suggestions with manual path selection
  - **Moral Dilemmas**: Conviction choices during calm moments have more weight
  - **Environmental Storytelling**: Discover backstory elements that affect decision-making
- **Tension Building Mechanics**: Use downtime to amplify upcoming action
  - **Countdown Timers**: "Infiltration begins in 30 seconds..." creates anticipation
  - **Intelligence Updates**: New information changes tactical considerations
  - **Equipment Failures**: Gear malfunctions during quiet moments create pressure
  - **Communication Intercepts**: Overhear enemy plans that affect player strategy
- **Player Agency During Lulls**: Prevent passive watching with meaningful choices
  - **Observation Windows**: Player spots details the AI planner might miss
  - **Psychological Choices**: How to keep team morale up during waiting periods
  - **Contingency Planning**: "What if X goes wrong?" preparation phases
  - **Resource Management**: Allocate limited supplies between team members
- **Streaming Engagement During Downtime**:
  - **Commentary Moments**: Natural breaks for streamers to explain context
  - **Audience Polls**: "Which route should we take?" during planning phases
  - **Theory Crafting**: Discuss potential enemy responses and counter-strategies
  - **Character Development**: Learn team member backstories that affect gameplay

**Corrected Streaming Pattern**:
Build Tension (Extended) → Brief Explosion of Action → Consequence Processing (Extended) → New Intelligence → Repeat

**Implementation**:

- Remove "constant tactical decisions" requirement
- Add "meaningful preparation phases" between action sequences
- Design downtime activities that engage both player and stream audience
- Use realistic pacing to make action sequences feel more impactful by contrast

## Resolution 20: Design Consistency Verification

**Decision**: Explicitly verify that all design resolutions are consistent and non-contradictory with each other.

**Details**:

- **Timing Consistency Check**:
  - ✅ 1ms tick cycle (Resolution 6) is compatible with 1000 FPS CLI updates (Resolution 8)
  - ✅ 5-second conviction choice window (Resolution 7) works with real-time never-pause system (Resolution 12)
  - ✅ Sub-millisecond scheduling precision is achievable with Oban job timing
- **Architecture Consistency Check**:
  - ✅ Separated GameEngine (Resolution 3) integrates properly with unified Oban queue (Resolution 2)
  - ✅ Temporal state migration (Resolution 1) supports idempotent Oban actions (Resolution 11)
  - ✅ MVP definition (Resolution 18) aligns with weekend scope priorities (Resolution 16)
- **Player Experience Consistency Check**:
  - ✅ Real-time input (Resolution 12) enhances streaming optimization (Resolution 14)
  - ✅ Opportunity windows (Resolution 13) work with imperfect information design (Resolution 15)
  - ✅ Never-pause gameplay supports both tactical decisions and entertainment value
- **Technical Implementation Consistency Check**:
  - ✅ 3D Godot coordinates (Resolution 19) compatible with 2D grid map system (Resolution 10)
  - ✅ Euclidean distance calculations (Resolution 9) work with Z=0 plane movement
  - ✅ LLM development uncertainty (Resolution 17) addressed by flexible MVP scope (Resolution 16, 18)
- **Domain Integration Consistency Check**:
  - ✅ ConvictionCrisis test domain (Resolution 5) exercises all temporal planner features
  - ✅ CLI implementation (Resolution 8) supports all required player interactions
  - ✅ Stability verification (Resolution 4) integrates with real-time execution constraints

**Contradiction Resolution Process**:

- **Identified Zero Contradictions**: All 19 previous resolutions are mutually compatible
- **Performance Alignment**: High-frequency updates, real-time input, and stability checks all support same goals
- **Scope Alignment**: Weekend timeline, MVP definition, and LLM uncertainty all properly balanced
- **Experience Alignment**: Streaming optimization, player agency, and tactical depth all reinforce each other
- **Technical Alignment**: All architectural decisions support the same temporal planner vision

**Future Consistency Maintenance**:

- Any new design decisions must be checked against all existing resolutions
- Changes to existing resolutions require consistency re-verification
- Implementation discoveries that create conflicts must trigger design resolution updates

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
18. ✅ **MVP Definition**: Concrete success criteria using existing infrastructure
19. ✅ **3D Coordinates**: Godot conventions with Z=0 plane for weekend speed
20. ✅ **Design Consistency**: All resolutions verified as mutually compatible and non-contradictory
21. ✅ **Realistic Pacing**: Meaningful downtime that builds tension (corrects Resolution 14)

## Next Steps

1. ✅ **COMPLETED**: All design questions identified and resolved
2. ✅ **COMPLETED**: All design decisions documented and locked in
3. 🚀 **READY**: Begin TDD implementation with complete design clarity

## Open Questions

### Q22: What Should Be the Very First Implementation Step?

**Question**: With all design decisions locked in, what concrete action should we take as the absolute first step to begin implementation?

**Context**: We have comprehensive design resolutions but need to decide the specific starting point for TDD implementation. Should we:

1. **Start with Data Structures**: Create `TemporalState` module first to establish the foundation?
2. **Start with Tests**: Write the first failing test that drives out the MVP demo?
3. **Start with Oban Job**: Create `GameActionJob` worker as the core execution mechanism?
4. **Start with CLI**: Build the terminal interface to visualize progress?
5. **Start with Mix Task**: Create the entry point `mix aria_engine.conviction_crisis`?
6. **Start with Existing Code Review**: Examine current AriaEngine modules to understand integration points?

**Decision Factors**:
- **TDD Approach**: Which starting point best supports test-driven development?
- **Risk Mitigation**: Which approach identifies integration issues earliest?
- **Momentum Building**: Which creates the most encouraging early progress?
- **Dependency Chain**: Which starting point has the fewest external dependencies?
- **MVP Alignment**: Which most directly advances toward the 10-minute demo acceptance criteria?

**Resolution Needed**: Choose the specific first step and create an implementation sequence that builds momentum while following TDD principles.
