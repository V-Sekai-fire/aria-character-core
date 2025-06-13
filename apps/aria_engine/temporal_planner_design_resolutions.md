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
22. ✅ **First Implementation Step**: Start with tests - write MVP acceptance test first
23. ✅ **Intent vs Action Architecture**: Clear distinction between immediate intents and scheduled actions
24. ✅ **Infrastructure Simplification**: SQLite + SecretsMock for zero dependencies (weekend scope)
25. ✅ **Zero External Dependencies**: No servers required beyond base OS + Elixir (2-minute setup)

## Next Steps

1. ✅ **COMPLETED**: All design questions identified and resolved
2. ✅ **COMPLETED**: All design decisions documented and locked in
3. ✅ **COMPLETED**: Infrastructure simplified for zero dependencies
4. 🚀 **READY**: Begin TDD implementation with complete design clarity and zero setup barriers

## Resolution 22: First Implementation Step - Test-Driven Oban Job

**Decision**: Start with the `GameActionJob` Oban worker as the first implementation step, driven by a simple failing test.

**Details**:

- **Chosen Approach**: Begin with `GameActionJob` because it has the lowest risk and highest MVP alignment
- **TDD Starting Point**: Write failing test that schedules a simple action and verifies execution
- **Risk Mitigation**: Oban worker is isolated, testable, and builds on existing infrastructure
- **Progressive Complexity**: Start with simplest possible action (move from A to B) and expand

**Implementation Sequence**:

1. **First Test**: `test "can schedule and execute simple move action"`
2. **First Implementation**: Basic `GameActionJob.perform/1` that updates agent position
3. **First Integration**: Verify Oban job executes at correct time via test
4. **First Expansion**: Add action duration and completion callbacks
5. **Foundation Complete**: Working temporal action execution pipeline

**Rationale Analysis**:

- **✅ LOWEST RISK - Start with Oban Job + Test**:
  - **Existing Infrastructure**: Builds on already-configured Oban setup
  - **Isolated Testing**: Can test job execution without CLI or game loop dependencies
  - **Immediate Validation**: Tests prove temporal scheduling works from day one
  - **Clear Success Criteria**: Job either executes at right time or doesn't
  - **Foundation Building**: Every other component depends on reliable action execution

**Why Not Other Approaches**:
- **Data Structures**: Abstract without proof they work in practice
- **CLI**: Complex integration without core functionality
- **Mix Task**: Shell without substance
- **Code Review**: Analysis paralysis without progress

5. **🟢 LOW-MEDIUM RISK - Start with Oban Job**:
   - **Core Mechanism**: Gets to heart of temporal execution quickly
   - **Concrete Behavior**: Can test actual job scheduling and execution
   - **Integration Point**: Natural place where temporal planning meets execution

6. **🟢 LOWEST RISK - Start with Tests**:
   - **TDD Best Practice**: Drives out exactly what's needed, no more
   - **Clear Success Criteria**: Test passes = feature works
   - **Incremental Progress**: Each test adds concrete functionality
   - **Integration Validation**: Tests force integration issues to surface early
   - **MVP Focused**: Can write test for exact 10-minute demo acceptance criteria

**Recommended First Step**: Start with Tests (Lowest Risk)
- Write failing test for: "Alex moves from {2,3} to {8,3} in real-time with terminal display"
- Forces creation of minimal TemporalState, GameActionJob, and CLI integration
- Provides immediate feedback on what works vs what doesn't
- Aligns perfectly with TDD approach and MVP demo requirements

**Resolution Needed**: Choose the specific first step and create an implementation sequence that builds momentum while following TDD principles.

## Resolution 22: First Implementation Step

**Decision**: Start with writing tests - specifically the MVP acceptance test that drives out all required components.

**Details**:

- **First Test**: Write failing integration test for complete MVP demo scenario
  - Test file: `test/aria_engine/conviction_crisis_integration_test.exs`
  - Test scenario: "Alex moves from {2,3} to {8,3} with real-time terminal display and SPACEBAR interruption"
  - Acceptance criteria: Matches exact 10-minute demo requirements from Resolution 18
- **TDD Sequence**: Let failing test drive out exactly what's needed
  1. **Test Fails**: No modules exist yet
  2. **Create Minimal**: Add just enough code to improve error messages
  3. **Iterate**: Each test run reveals next missing piece
  4. **Integrate**: Test forces all components to work together
- **Risk Mitigation**: Test-first approach prevents over-engineering and ensures integration
- **Momentum Building**: Each test pass provides concrete progress milestone
- **Implementation Order Driven by Test**:
  1. `TemporalState` - As test needs state management
  2. `GameActionJob` - As test needs action execution
  3. `ConvictionCrisis.CLI` - As test needs terminal display
  4. `ConvictionCrisis.GameEngine` - As test needs game loop
  5. Mix task - As test needs entry point

**First Test Structure**:
```elixir
test "MVP demo: Alex moves from {2,3} to {8,3} with real-time display and interruption" do
  # 1. Start game
  # 2. Verify Alex at {2,3}
  # 3. Verify auto-plan to {8,3}
  # 4. Watch real-time movement
  # 5. Interrupt at {5,3}
  # 6. Verify replanning
  # 7. Complete movement to {8,3}
  # 8. Verify "Mission Complete!"
end
```

**Implementation Strategy**: Write comprehensive failing test first, then implement just enough to make it pass - no more, no less.

## Resolution 23: MVP Timing Implementation Strategy

**Decision**: Implement deterministic action timing using simple Euclidean distance calculation with constant movement speed, verified through automated testing.

**Details**:

- **Simple Distance Formula**: `time = distance / speed` where distance = `sqrt((x2-x1)² + (y2-y1)²)`
- **Fixed Movement Speed**: 3.0 units per second for all agents (from Resolution 9)
- **Deterministic Duration**: Same movement always takes exactly the same time
- **Test-Driven Validation**: Automated tests verify timing accuracy within 10ms tolerance
- **Progress Tracking**: Linear interpolation between start and end positions over duration
- **Interruption Support**: Store current position when action interrupted, resume from there

**Implementation Pattern**:

```elixir
def calculate_move_duration(from_pos, to_pos, speed \\ 3.0) do
  distance = :math.sqrt(:math.pow(to_pos.x - from_pos.x, 2) + :math.pow(to_pos.y - from_pos.y, 2))
  distance / speed
end

def calculate_current_position(start_pos, end_pos, start_time, duration, current_time) do
  progress = (current_time - start_time) / duration
  progress = max(0.0, min(1.0, progress))  # Clamp to [0, 1]
  
  %{
    x: start_pos.x + progress * (end_pos.x - start_pos.x),
    y: start_pos.y + progress * (end_pos.y - start_pos.y),
    z: 0.0
  }
end
```

**Timing Reliability Requirements**:
- **Deterministic Calculation**: Identical inputs always produce identical timing
- **Sub-second Precision**: Duration calculations accurate to 0.1 second
- **Measurable Performance**: Automated tests verify real vs expected completion times
- **Graceful Interruption**: Actions can be stopped cleanly at any point with accurate position

**Test Coverage Strategy**:
- Unit tests for duration calculation formulas
- Integration tests for Oban job timing accuracy  
- Property-based tests for movement interpolation
- Performance tests for timing precision under load

## Resolution 24: Absolute Minimum Success Criteria

**Decision**: Define the smallest possible demonstration that proves the temporal planner concept works.

**Details**:

**Core Success Criteria (All Must Work)**:
1. **Temporal State**: Store "Alex is at {2,3} at time 10.5s"
2. **Scheduled Action**: Create "Move Alex to {5,3} starting at 12.0s" 
3. **Oban Execution**: Action executes automatically at scheduled time
4. **State Update**: Alex's position updates correctly when action completes
5. **Simple CLI**: Terminal shows "Alex moving from {2,3} to {5,3} - ETA: 1.2s"
6. **Manual Verification**: Human can observe system working correctly

**Fallback Criteria** (if real-time proves too complex):
1. **Static Planning**: Print out a complete plan without executing it
2. **Timing Calculation**: Show estimated durations for each action  
3. **State Display**: Show current state and planned future state
4. **Proof of Concept**: Demonstrate temporal planning logic without real-time execution

**Success Validation**:
- **Demonstrable**: Can show working system to others in 5 minutes
- **Temporal**: Involves time-based scheduling and execution
- **Plannable**: Shows intelligent sequencing of actions
- **Extensible**: Foundation for adding complexity later

**Weekend Acceptance Test**:
- Run `mix aria_engine.conviction_crisis`
- See Alex move across terminal display in real-time
- Press SPACEBAR to interrupt movement
- Observe replanning and continuation
- Complete with "Mission Complete!" message

## Resolution 25: Research Question Resolution Strategy

**Decision**: Address critical research questions through rapid prototyping during implementation rather than separate investigation phases.

**Details**:

**Research-Through-Implementation Approach**:
- **Question R1 (Oban Precision)**: Test during first GameActionJob implementation
- **Question R2 (Real-time Input)**: Test during CLI development
- **Question R3 (SQLite Performance)**: Monitor during development, optimize if needed

**Rapid Validation Tests**:
```elixir
# R1: Oban timing precision
test "oban scheduling accuracy" do
  scheduled_time = DateTime.utc_now() |> DateTime.add(1, :second)
  start_time = System.monotonic_time(:millisecond)
  
  {:ok, _job} = GameActionJob.new(%{test_timing: true}) 
    |> Oban.insert(scheduled_at: scheduled_time)
  
  # Verify execution within 100ms tolerance
  assert_receive {:job_executed, execution_time}, 2000
  actual_delay = execution_time - start_time
  assert actual_delay < 1100  # 1000ms + 100ms tolerance
end

# R2: Non-blocking input
test "async keyboard input" do
  {:ok, pid} = ConvictionCrisis.CLI.start_link()
  
  # Simulate keypress
  send(pid, {:test_input, "space"})
  
  # Verify received without blocking
  assert_receive {:input_received, "space"}, 50
end

# R3: SQLite performance sampling
test "basic sqlite performance" do
  {time, _result} = :timer.tc(fn ->
    Enum.each(1..100, fn i ->
      TemporalState.update_agent_position("alex", {i, 3, 0})
    end)
  end)
  
  # Should handle 100 updates quickly (100µs per update max)
  assert time < 10_000  # 10ms total for 100 updates
end
```

**Implementation-First Philosophy**:
- Build working code immediately and measure performance
- Adjust design based on actual capabilities discovered
- Fail fast if fundamental assumptions prove wrong
- Use simple implementations first, optimize later if needed

## Resolution Status Summary

✅ **ALL OPEN QUESTIONS RESOLVED**

**Design Questions (All Resolved)**:
1. ✅ **Resolution 1-21**: Core architectural and design decisions locked in
2. ✅ **Resolution 22**: First implementation step decided (Test-driven Oban Job)  
3. ✅ **Resolution 23**: MVP timing implementation strategy defined
4. ✅ **Resolution 24**: Absolute minimum success criteria established
5. ✅ **Resolution 25**: Research questions converted to implementation tests
6. ✅ **Resolution 26**: Implementation risk mitigation strategies prepared

**Critical Dependencies Addressed**:
- ✅ **Infrastructure**: SQLite + SecretsMock setup complete (previous work)
- ✅ **Architecture**: Temporal state, Oban jobs, CLI interface design finalized
- ✅ **Implementation Strategy**: TDD approach with clear first steps
- ✅ **Risk Mitigation**: Fallback plans if temporal precision fails
- ✅ **Success Criteria**: Clear definition of MVP demonstration requirements

**Ready for Implementation**:
- 🚀 **First Step**: Write failing integration test for MVP demo
- 🚀 **Test-Driven**: Let tests drive out exactly what's needed
- 🚀 **Incremental**: Build working system piece by piece
- 🚀 **Measurable**: Validate timing assumptions through real code
- 🚀 **Demonstrable**: Target 10-minute working demo

**No Remaining Open Questions**: All architectural decisions made, implementation strategy defined, risk mitigation prepared. Ready to begin coding the temporal planner with complete design clarity.

**Decision**: Establish clear distinction between Intents (immediate planning commands) and Actions (scheduled executable tasks).

**Details**:

- **Actions** (scheduled in Oban queue with duration and state effects):
  - `move_to` - Agent movement with travel time
  - `attack` - Combat action with cooldown
  - `use_item` - Equipment usage with resource consumption
  - `wait` - Deliberate pause for timing coordination
  - **Properties**: Duration, resource cost, can fail, queued execution, state changes
- **Intents** (immediate commands that modify the planning system):
  - `interrupt` - Cancel current action, trigger replanning
  - `replan` - Recalculate optimal plan from current state
  - `cancel_action` - Remove specific scheduled action
  - `change_goal` - Update objective, trigger full replanning
  - `emergency_stop` - Halt all actions immediately
  - **Properties**: Instantaneous, no duration, modify plan queue, trigger replanning
- **Interruption Flow**:
  1. Player presses SPACEBAR → `interrupt` intent sent
  2. Intent processor cancels current executing action
  3. Agent position updated to current location
  4. Replanning triggered from new position
  5. New actions scheduled to achieve goal
- **Architecture Separation**:
  - **ActionQueue**: Handles scheduled actions with Oban jobs
  - **IntentProcessor**: Handles immediate planning modifications
  - **TemporalPlanner**: Responds to intents by generating new actions
  - **GameEngine**: Processes both intents and action completions
- **Test Implementation**:
  - Actions tested for duration, effects, and completion
  - Intents tested for immediate response and plan modification
  - Integration tested for intent → action → replanning flow

**Critical Design Point**: Interruption is NOT an action that takes time - it's an intent that immediately modifies the temporal plan.

## Resolution 24: Infrastructure Simplification for Weekend Scope

**Decision**: Switch from CockroachDB + OpenBao to SQLite + SecretsMock for weekend temporal planner implementation.

**Details**:

- **Database Change**: Use SQLite instead of CockroachDB for weekend scope
  - **Rationale**: CockroachDB setup requires complex certificate management, distributed configuration, and external services
  - **SQLite Benefits**: Single file database, no setup required, perfect for development and testing
  - **Oban Compatibility**: Oban works perfectly with SQLite via `ecto_sqlite3` adapter
  - **Migration Path**: Can upgrade to CockroachDB post-weekend without code changes (just configuration)
- **Secrets Management Change**: Use existing `AriaSecurity.SecretsMock` instead of OpenBao
  - **Existing Mock Found**: `apps/aria_security/lib/aria_security/secrets_mock.ex` already exists and works
  - **OpenBao Complexity**: Requires PKCS#11 setup, SoftHSM, certificate management, Fly.io deployment
  - **Mock Benefits**: In-memory storage, no external dependencies, perfect for development
  - **Test Configuration**: Already configured to use mock in `config/test.exs`
- **Zero Dependencies Achievement**:
  - **Download**: `git clone https://github.com/user/aria-character-core`
  - **Setup**: `mix deps.get` (downloads all Elixir dependencies automatically)
  - **Run**: `mix aria_engine.conviction_crisis` (works immediately)
  - **No External Services**: No database servers, no secret management servers
- **Weekend Implementation Benefits**:
  - **Faster Development**: No time spent on infrastructure setup
  - **Easier Testing**: No complex server startup/teardown
  - **Portable Demos**: Works on any machine with Elixir installed
  - **Reduced Risk**: Eliminates infrastructure as failure point
- **Post-Weekend Upgrade Path**:
  - **Database**: Change config to CockroachDB, run migrations (zero code changes)
  - **Secrets**: Switch to real OpenBao implementation (same interface)
  - **Infrastructure**: Add complexity only when core functionality proven

**Configuration Changes Required**:
```elixir
# config/dev.exs - Switch to SQLite
config :aria_data, AriaData.QueueRepo,
  adapter: Ecto.Adapters.SQLite3,
  database: "tmp/aria_queue_dev.db"

# config/dev.exs - Use secrets mock
config :aria_security, :secrets_module, AriaSecurity.SecretsMock
```

## Resolution 25: Zero External Dependencies (Beyond Base OS)

**Decision**: Achieve zero external dependencies beyond what comes with a base Windows 11 or macOS installation (excluding standard development tools like GPU drivers).

**Details**:

- **Zero External Services**: No database servers, no secret management servers, no additional infrastructure
  - **Database**: Use SQLite (single file, bundled with system or Elixir)
  - **Secrets**: Use `AriaSecurity.SecretsMock` (in-memory, already implemented)
  - **No External Processes**: Everything runs within the Elixir application
- **Acceptable Base Requirements** (standard for any development):
  - **Elixir/Erlang**: Development environment (like any language runtime)
  - **GPU Drivers**: Standard hardware drivers (like any application)
  - **Git**: Source control (standard development tool)
  - **Terminal/Shell**: Built into all operating systems
- **Automatic Dependencies** (downloaded by tooling):
  - **Mix Dependencies**: All Elixir packages downloaded automatically by `mix deps.get`
  - **No Manual Installation**: User never runs external installers
- **Zero Setup Workflow**:
  1. `git clone https://github.com/user/aria-character-core`
  2. `cd aria-character-core`
  3. `mix deps.get` (automatic download of all dependencies)
  4. `mix aria_engine.conviction_crisis` (runs immediately)
- **Benefits for Weekend Development**:
  - **Immediate Demo**: Anyone can run the temporal planner instantly
  - **No Infrastructure Failures**: Eliminates servers as potential failure points
  - **Cross-Platform**: Works identically on Windows, macOS, Linux
  - **Streamable**: Easy to demonstrate on streams without complex setup
- **Implementation Requirements**:
  - SQLite configuration for all Ecto repos used by temporal planner
  - SecretsMock configuration for all secret management
  - Self-contained file storage (no external S3/blob storage)
  - In-memory caching (no external Redis)

**Success Criteria**: A new developer can go from `git clone` to running temporal planner demo in under 2 minutes on a fresh Windows 11 or macOS machine with only Elixir installed.

## Resolution 26: Implementation Capability Crisis

## Resolution 26: Implementation Risk Mitigation

**Decision**: Accept that temporal planner success is critical to game viability, and implement comprehensive risk mitigation through fallback strategies.

**Details**:

**Critical Success Dependencies**:
- **Precise Action Duration Estimates**: "Moving from A to B takes 3.2 seconds"
- **Reliable Completion Prediction**: "Action will complete at 14:32:15.432"
- **Interruptible Progress Tracking**: "Currently 60% through movement"
- **Real-time ETA Updates**: "Arrival in 1.8 seconds... 1.7... 1.6..."

**Failure Modes Without Working Implementation**:
- **Arbitrary Timing**: Made-up durations that don't match reality
- **Inconsistent Experience**: Actions take random amounts of time
- **Broken Interruption**: Can't interrupt actions reliably
- **No Player Agency**: Unpredictable timing eliminates meaningful decisions
- **Undemonstrable**: Cannot show working game to others

**Risk Mitigation Strategy**:
- **Start with MVP**: Simplest possible working temporal planner
- **Measure Everything**: Instrument all action durations and progress tracking
- **Test Thoroughly**: Automated tests for timing reliability and interruption
- **Fail Fast**: If basic temporal planning doesn't work, pivot immediately

**Fallback Options** (in order of preference):
1. **Simplified Timing**: Use integer seconds instead of sub-second precision
2. **Turn-Based Mode**: Convert to discrete turn system if real-time fails
3. **No-Interruption Mode**: Remove interruption mechanics if timing proves unreliable
4. **Pure Demonstration**: Focus on showing planning concepts rather than real-time gameplay

**Critical Insight**: The temporal planner is not just a feature - it's the foundational technology that makes the entire game concept possible. Without it working reliably, there is no game.

**Decision**: If we cannot successfully implement a working temporal planner, the entire game concept fails because it depends on reliable action timing estimation.

**Details**:

- **Fundamental Dependency**: The "Conviction in Crisis" game concept requires:
  - **Precise Action Duration Estimates**: "Moving from A to B takes 3.2 seconds"
  - **Reliable Completion Prediction**: "Action will complete at 14:32:15.432"
  - **Interruptible Progress Tracking**: "Currently 60% through movement"
  - **Real-time ETA Updates**: "Arrival in 1.8 seconds... 1.7... 1.6..."
- **Implementation-Estimation Paradox**: 
  - **Cannot Estimate Without Implementation**: Time estimation requires working code to measure
  - **Cannot Plan Without Estimation**: Game design requires known action durations
  - **Cannot Test Without Planning**: Validation requires predictable timing
  - **Circular Dependency**: Each element depends on the others working
- **Game Design Brittleness**: 
  - **Streaming Entertainment**: Requires precise timing for tension and viewer engagement
  - **Player Agency**: Interruption windows must be predictable and fair
  - **Tactical Decision**: Player needs accurate time information to make meaningful choices
  - **Real-time Feedback**: CLI display depends on accurate progress calculations
- **Failure Modes Without Working Implementation**:
  - **Arbitrary Timing**: Made-up durations that don't match reality
  - **Inconsistent Experience**: Actions take random amounts of time
  - **Broken Interruption**: Can't interrupt actions reliably
  - **No Player Agency**: Unpredictable timing eliminates meaningful decisions
  - **Undemonstrable**: Cannot show working game to others
- **Success Criteria for Game Viability**:
  - **Deterministic Action Duration**: Same action always takes same time
  - **Sub-second Precision**: Timing accurate to 100ms or better
  - **Reliable Interruption**: SPACEBAR always stops action cleanly
  - **Accurate Progress Display**: Visual progress matches actual completion
  - **Consistent Replanning**: Interrupted actions resume from correct position
- **Implementation-First Approach**: 
  - **Measure Real Performance**: Use actual code execution time for estimates
  - **Iterate Based on Reality**: Adjust game design to match implementation capabilities
  - **Validate Through Testing**: Prove timing reliability through automated tests
  - **Build Confidence Through Demos**: Working code enables convincing demonstrations
- **Risk Mitigation Strategy**:
  - **Start with MVP**: Simplest possible working temporal planner
  - **Measure Everything**: Instrument all action durations and progress tracking
  - **Test Thoroughly**: Automated tests for timing reliability and interruption
  - **Fail Fast**: If basic temporal planning doesn't work, pivot immediately

**Critical Insight**: The temporal planner is not just a feature - it's the foundational technology that makes the entire game concept possible. Without it working reliably, there is no game.
