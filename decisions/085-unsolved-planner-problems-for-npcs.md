# 085 - Unsolved Planner Problems for NPCs in Virtual Environments

## Status

Active (June 17, 2025)

## Context

AriaEngine is a powerful Hierarchical Task Network (HTN) and temporal planner. However, for creating realistic and dynamic NPC behavior in complex virtual environments like an NPC town, VRChat, Roblox, Fortnite, Resonite, and Minecraft, there are several advanced planning features and problem types that AriaEngine does not currently support or explicitly implement. This ADR outlines these limitations and their relevance to NPC behavior, serving as a roadmap for future development.

The current limitations prevent the creation of NPCs that can:
*   Coordinate effectively in groups.
*   Follow complex, time-sensitive routines.
*   React dynamically to environmental changes or uncertain information.
*   Exhibit highly robust and believable physical interactions within the environment.

## Decision

To formally document these unsolved problems and their relevance to NPC behavior as a roadmap for future planner development within AriaEngine. This will guide future architectural decisions and implementation efforts to enhance NPC intelligence and realism.

## Implementation Plan

This roadmap focuses on systematic enhancement of AriaEngine's NPC planning capabilities, organized into implementation phases based on current system readiness and impact potential.

### Phase 1: Foundation Completion (IMMEDIATE PRIORITY)

*   [x] ~~**Intermediate/External Conditions & Effects**: **Effort: M, Significance: High**~~ → **Completed via ADR-086**
    - ✅ Durative actions with at_start, over_all, and at_end conditions implemented
    - ✅ Temporal condition validation during action execution  
    - ✅ Integration with STN for temporal constraint management

*   [x] ~~**Quantifiers Support (Existential/Universal)**: **Effort: M, Significance: Medium**~~ → **Completed (June 17, 2025)**
    - ✅ Implemented `exists?` and `forall?` quantifiers in AriaEngine.State module
    - ✅ Extended condition evaluation system to support existential and universal logic
    - ✅ Added quantifier support to durative action precondition validation
    - ✅ Enabled complex NPC reasoning patterns like "find any available chair" or "ensure all doors are locked"
    - ✅ Comprehensive test suites validate both standalone quantifiers and durative action integration

*   [ ] **Enhanced Scheduling**: **Effort: L, Significance: High** → **Architecture sketched, implementation incomplete**
    - 🏗️ Function signatures exist in TimelineGraph module (`schedule_routine/4`, `resolve_schedule_conflicts/4`, `add_environmental_process/3`)
    - ⚠️ Core functionality is placeholder only - all functions return placeholders or empty results
    - ⚠️ `detect_schedule_conflicts()` always returns `[]` with comment "return no conflicts to enable basic functionality"
    - ⚠️ `get_scheduled_routines()` returns empty list with comment "For now, return empty list as placeholder"
    - ⚠️ `find_next_available_slot()` always returns `{:error, :no_available_slot}` 
    - ❌ No actual scheduling logic or conflict resolution implemented
    - ❌ Zero test coverage for scheduling functionality
    - 📋 Requires STN interval query system integration for actual implementation

### Phase 2: Environmental Dynamics (FUTURE IMPLEMENTATION)

*   [ ] **Enhanced Timed Effects/Goals**: **Effort: M, Significance: High** → **See ADR-087: Entity-Agent Timeline Graph Architecture**
    - Extend current temporal support for absolute time scheduling
    - Implement deadline-based goal achievement with failure handling
    - Add time-triggered effects independent of action execution
    - **Note**: ADR-087's living timelines naturally handle time-based effects through automatic timeline growth

*   [ ] **Processes & Events**: **Effort: L, Significance: High** → **See ADR-087: Entity-Agent Timeline Graph Architecture**
    - Integrate continuous environmental processes (weather, resource depletion)
    - Implement discrete event system for environmental changes
    - Add event-driven NPC behavior triggers and responses
    - **Note**: ADR-087's environmental timeline integration automatically propagates events through entity networks

### Phase 3: Advanced Coordination (RESEARCH PROJECTS)

*   [ ] **Multi-Agent Planning**: **Effort: XL, Significance: High** → **See ADR-087: Entity-Agent Timeline Graph Architecture**
    - Design distributed planning architecture for multiple independent NPCs
    - Implement inter-agent communication, negotiation, and conflict resolution
    - Add coordination mechanisms for group activities and shared resources
    - **Note**: ADR-087's timeline bridging architecture enables automatic multi-agent coordination through connected timelines rather than requiring explicit central planning

*   [ ] **Trajectory Constraints & State Invariants**: **Effort: XL, Significance: High** 
    - Enhance pathfinding with complex spatial and logical constraints
    - Implement navigation mesh integration and collision avoidance
    - Add dynamic obstacle handling and path replanning

*   [ ] **Contingent Planning**: **Effort: XL, Significance: Medium** 
    - Introduce non-deterministic initial states and uncertainty modeling
    - Implement sensing actions and belief state management
    - Add adaptive planning for unknown or changing environments

## Consequences/Risks

### Consequences of Not Addressing These Problems:
*   **Limited NPC Realism**: NPCs will remain largely reactive or follow simple, pre-scripted routines, lacking the dynamic and adaptive behavior seen in more advanced virtual worlds.
*   **Reduced Immersion**: The inability of NPCs to interact realistically with each other and the environment will detract from the overall immersion of the virtual experience.
*   **Scalability Challenges**: Manually scripting complex coordinated behaviors for many NPCs becomes unmanageable.

### Risks of Implementation:
*   **Increased Complexity**: Implementing these advanced planning features will significantly increase the complexity of the AriaEngine core.
*   **Performance Overhead**: Advanced planning can be computationally intensive, potentially impacting real-time performance in large-scale virtual environments.
*   **Integration Challenges**: Integrating new planning paradigms (e.g., multi-agent coordination) with the existing HTN and temporal planning framework may pose significant architectural challenges.

## Success Criteria

### Phase 1 Success Criteria (Foundation Completion)
*   ✅ AriaEngine supports durative actions with temporal conditions (completed via ADR-086)
*   ✅ Condition system supports existential (`exists`) and universal (`forall`) quantifiers for advanced reasoning
*   ❌ NPCs can follow complex, scheduled routines using STN-based scheduling system (placeholder functions only)
*   ❌ Scheduling system handles resource conflicts and temporal coordination effectively (no actual implementation)
*   ✅ Phase 1 features integrate seamlessly with existing HTN and temporal planning architecture
*   ❌ Comprehensive test suites validate quantifier and scheduling functionality (zero scheduling tests exist)

### Long-term Success Criteria (Phases 2-3)
*   NPCs can react dynamically to environmental processes and discrete events
*   Multiple NPCs can coordinate effectively in shared virtual environments  
*   Advanced spatial constraints and pathfinding integrate with planning system
*   Uncertainty handling enables adaptive NPC behavior in unknown situations
*   All implemented features maintain acceptable performance in real-time virtual environments

## Related ADRs

- **ADR-087**: Entity-Agent Timeline Graph Architecture (proposed solution for Enhanced Scheduling, Multi-Agent Planning, Processes & Events, and Enhanced Timed Effects/Goals)
- **ADR-086**: Implement Durative Actions (completed foundation work)
- **ADR-084**: Domain Method Naming Refactor (prerequisite for Phase 1 implementation)
- **ADR-075**: Complete Temporal Planning Solver
- **ADR-078**: Timeline Module PC-2 STN Implementation
