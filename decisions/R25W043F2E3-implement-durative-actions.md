# 086 - Implement Durative Actions in Aria Engine Solver

<!-- @adr_serial R25W043F2E3 -->

## Status

Completed (June 17, 2025)

## Context

Durative actions are actions that have a duration over time, rather than occurring instantaneously. They can have conditions that must hold throughout their execution, and effects that occur at specific points (e.g., start, end, or during) within their duration. Implementing durative actions is crucial for enhancing the realism and expressiveness of the Aria Engine's planning capabilities, especially for modeling continuous processes and time-extended activities in virtual environments.

Currently, Aria Engine primarily handles instantaneous actions. While the STN (Simple Temporal Network) integration allows for temporal reasoning about the *ordering* and *duration* of instantaneous actions, it does not natively support actions that *themselves* have a duration with internal conditions and effects. This limitation restricts the planner's ability to model complex real-world scenarios where actions unfold over time.

## Decision

To implement support for durative actions within the Aria Engine Solver. This will involve extending the domain representation, modifying the planning algorithm to handle durative actions, and integrating with the existing temporal reasoning framework.

## Implementation Plan

* [x] **Update `AriaEngine.Domain`**:
  * ✅ Define a new structure for durative actions, including their duration, conditions (at start, over all, at end), and effects (at start, at end, over time).
  * ✅ Add methods to `AriaEngine.Domain` for adding and retrieving durative actions.
* [x] **Modify `AriaEngine.Plan.Core` (Planning Algorithm)**:
  * ✅ Extend the planning algorithm to decompose tasks into durative actions.
  * ✅ Develop mechanisms to handle durative action preconditions and effects during planning.
  * ✅ Integrate durative action handling with the existing backtracking and replanning mechanisms.
* [x] **Integrate with `AriaEngine.Timeline.STN`**:
  * ✅ Ensure that durative actions are correctly represented and constrained within the STN.
  * ✅ Develop methods to extract temporal constraints from durative actions and add them to the STN.
  * ✅ Validate the temporal consistency of plans involving durative actions using the STN.
* [x] **Update `AriaEngine.Actions`**:
  * ✅ Provide examples of durative actions that can be added to a domain.
  * ✅ Enhanced Domain.Actions to execute durative actions with temporal precondition validation.
* [x] **Develop Tests**:
  * ✅ Create comprehensive unit and integration tests for durative action definition, planning, and execution.
  * ✅ Include tests for various types of durative action conditions and effects, as well as temporal consistency checks.
  * ✅ Added extensive test suite covering categorical, numeric, and boolean fluents with durative actions.
* [x] **Intermediate/External Conditions & Effects**:
  * ✅ Extend the planner to handle conditions that must hold or effects that occur during an action's duration.
  * ✅ Implement mechanisms for at_start, over_all, and at_end temporal condition validation.

## Consequences/Risks

### Consequences of Not Addressing Durative Actions

* **Limited Modeling Capability**: Inability to accurately represent and plan for real-world scenarios involving time-extended activities (e.g., "traveling," "building," "cooking").
* **Reduced Realism**: NPC behaviors will remain somewhat artificial, as they cannot perform actions that unfold over a period with internal dynamics.
* **Increased Manual Scripting**: Complex temporal interactions will continue to require manual scripting outside the planner, reducing the benefits of automated planning.

### Risks of Implementation

* **Increased Complexity**: Durative actions significantly increase the complexity of the planning algorithm and domain representation.
* **Performance Impact**: Planning with durative actions can be computationally more expensive than with instantaneous actions, potentially affecting real-time performance.
* **Integration Challenges**: Ensuring seamless integration with the existing STN and other planner components will require careful design and implementation.
* **Debugging Complexity**: Debugging plans involving durative actions and temporal constraints can be challenging.

## Success Criteria

* ✅ AriaEngine can successfully define, plan for, and execute plans containing durative actions.
* ✅ The planner correctly handles start, end, and "over all" conditions and effects of durative actions.
* ✅ Temporal consistency of plans with durative actions is correctly validated by the STN.
* ✅ New tests cover the full range of durative action functionalities.
* ✅ The implementation is robust and does not introduce significant performance regressions for existing instantaneous action planning.

## Implementation Summary

**Core Components Implemented:**

* **DurativeAction struct** with support for fixed and range-based durations
* **Temporal condition validation** for at_start, over_all, and at_end conditions
* **Planning integration** with proper recognition and classification of durative vs instantaneous actions
* **Immediate primitive execution** during node expansion with temporal backtracking support
* **STN integration** for temporal constraint management and consistency validation

**Key Features:**

* **Mixed fluent type support:** Categorical (:low, :medium, :high), numeric (10, 50, 100), and boolean (true/false) fluents work seamlessly with durative actions
* **Temporal backtracking:** When durative actions fail due to unmet preconditions, the planner correctly backtracks to alternative methods
* **Timeline constraints:** Durative actions respect temporal deadlines and resource availability constraints
* **Comprehensive validation:** All temporal conditions are validated at appropriate execution phases

**Testing Coverage:**

* Domain integration tests for adding/retrieving durative actions
* STN consistency validation with temporal constraints  
* Planning integration with backtracking scenarios
* Mixed fluent type demonstrations (categorical, numeric, boolean)
* Real-world scenarios like phone charging with resource constraints

The implementation successfully enables time-extended planning scenarios while maintaining compatibility with existing instantaneous action planning capabilities.
