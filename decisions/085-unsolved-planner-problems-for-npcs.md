# 085 - Unsolved Planner Problems for NPCs in Virtual Environments

## Status

Proposed

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

The following features are identified as crucial for improving NPC behavior in virtual environments and are proposed for future implementation. The "Effort" is estimated using T-shirt sizing (XS, S, M, L, XL), where XL indicates a very high level of effort, potentially requiring significant research and development, and representing a long-term, high-investment goal. "Significance" indicates the impact on NPC behavior and realism (High, Medium).

*   [ ] **Intermediate/External Conditions & Effects**: **Effort: M, Significance: High** Extend the planner to handle conditions that must hold or effects that occur during an action's duration, and effects triggered by external events.
*   [ ] **Timed Effects/Goals**: **Effort: M, Significance: High** Implement support for effects scheduled at absolute times and goals that must be achieved by specific deadlines.
*   [ ] **Quantifiers (Existential/Universal)**: **Effort: M, Significance: Medium** Implement support for existential (`exists`) and universal (`forall`) quantifiers in conditions and effects for more advanced reasoning.
*   [ ] **Scheduling**: **Effort: L, Significance: High** Develop robust scheduling capabilities to manage NPC routines, activities with deadlines, and temporal coordination of tasks.
*   [ ] **Processes & Events**: **Effort: L, Significance: High** Integrate the ability to model continuous environmental processes and discrete events that influence NPC behavior.
*   [ ] **Multi-Agent Planning (Independent Planners)**: **Effort: XL, Significance: High** Implement mechanisms for **multiple independent planners** to coordinate their actions, including inter-agent communication, negotiation, and distributed conflict resolution. This is a highly complex area involving decentralized decision-making.
*   [ ] **Trajectory Constraints & State Invariants**: **Effort: XL, Significance: High** Enhance pathfinding and action execution to enforce complex spatial and logical constraints (e.g., "stay on path," "don't walk through walls").
*   [ ] **Contingent Planning**: **Effort: XL, Significance: Medium** Introduce support for non-deterministic initial states and sensing actions, allowing NPCs to gather information and react to uncertainty.

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

*   AriaEngine can successfully plan and execute scenarios involving multiple coordinating NPCs.
*   NPCs can adhere to complex schedules and react to time-sensitive events.
*   The planner can handle actions with conditions and effects that span durations or are triggered by external factors.
*   The planner can reason about and react to uncertain information in the environment.
*   The implemented features are robust, scalable, and do not introduce unacceptable performance overhead in typical virtual environment simulations.
*   New test suites are developed to validate the functionality of each implemented feature.
