# R25W14477B9: Common Use Cases and Patterns

<!-- @adr_serial R25W14477B9 -->

**Status:** Proposed  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Guidance

## Overview

**Purpose**: Real-world examples and proven patterns for common AriaEngine scenarios  
**Target Audience**: Developers who completed the Quick Start Guide (R25W143C7C4)  
**Scope**: Practical examples with complete working code

## Dependencies

This ADR depends on completion of the core specification ADRs:

- **R25W1398085**: Unified Durative Action Specification and Planner Standardization (authoritative patterns)
- **R25W1405B8B**: Fix Duration Handling Precision Loss (technical implementation)
- **R25W141BE8A**: Planner Standardization Open Problems (architecture standards)
- **R25W1421349**: Unified Action Specification Examples (developer reference)
- **R25W143C7C4**: AriaEngine Quick Start Guide (prerequisite knowledge)

## Planned Use Cases

### Use Case 1: Restaurant Kitchen Management

**Scenario**: Manage a restaurant kitchen with multiple chefs, equipment, and orders

**Planned Components**:

- Actions: cook_pasta, grill_chicken, plate_dish
- Goal Methods: fulfill_order, manage_kitchen_workflow
- Task Methods: process_dinner_rush
- Resource Management: chef allocation, equipment scheduling
- Temporal Coordination: order timing and dependencies

### Use Case 2: Meeting Scheduling System

**Scenario**: Schedule meetings with room booking, participant availability, and equipment setup

**Planned Components**:

- Actions: conduct_meeting, setup_equipment, send_invitations
- Goal Methods: schedule_meeting, ensure_room_availability
- Task Methods: organize_daily_standup
- Temporal Constraints: fixed start/end times, duration handling
- Resource Conflicts: room and equipment availability

### Use Case 3: Resource Management System

**Scenario**: Manage shared resources like vehicles, equipment, and personnel across projects

**Planned Components**:

- Actions: transport_equipment, allocate_resource, release_resource
- Goal Methods: move_equipment, assign_resource
- Multigoal Methods: optimize_resource_allocation
- Conflict Resolution: resource contention handling
- Optimization: efficient resource utilization

## Planned Pattern Categories

### Pattern 1: State Validation in Goal Methods

- Always check current state first
- Handle edge cases and invalid states
- Provide meaningful error messages

### Pattern 2: Resource Conflict Resolution

- Entity requirement validation
- Conflict detection and handling
- Resource availability checking

### Pattern 3: Temporal Coordination

- Fixed schedule coordination
- Duration-based planning
- Timeline synchronization

### Pattern 4: Error Recovery

- Retry mechanisms
- Graceful degradation
- Failure handling strategies

## Planned Best Practices

### 1. Always Check Current State

- Verify state before taking action
- Avoid unnecessary operations
- Handle already-achieved goals

### 2. Use Descriptive Error Messages

- Provide actionable error information
- Include context and suggestions
- Help with debugging

### 3. Break Down Complex Operations

- Decompose into manageable steps
- Use task methods for coordination
- Maintain clear separation of concerns

## Success Criteria

After reading this ADR, developers should be able to:

- [ ] Implement restaurant kitchen management with multiple resources
- [ ] Create meeting scheduling systems with temporal constraints
- [ ] Build resource management with conflict resolution
- [ ] Apply common patterns for state validation and error handling
- [ ] Structure complex domains with proper decomposition
- [ ] Handle temporal coordination and resource conflicts

**Complexity Level**: Intermediate  
**Prerequisites**: R25W143C7C4 (Quick Start Guide)  
**Time Investment**: 45-60 minutes for complete understanding

## Implementation Notes

**Awaiting**: Completion of ADRs 181-184 to ensure all examples use authoritative patterns.

**Key Requirements**:

- All action definitions must use R25W1398085 attribute patterns
- State management must follow R25W1405B8B precision handling
- Architecture must align with R25W141BE8A standards
- Examples must be consistent with R25W1421349 reference implementations
- Error handling must follow established patterns
- Resource management must use validated entity requirements
