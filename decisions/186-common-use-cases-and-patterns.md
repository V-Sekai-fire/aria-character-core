# ADR-186: Common Use Cases and Patterns

**Status:** Proposed  
**Date:** 2025-06-25  
**Priority:** HIGH - Developer Guidance

## Overview

**Purpose**: Real-world examples and proven patterns for common AriaEngine scenarios  
**Target Audience**: Developers who completed the Quick Start Guide (ADR-185)  
**Scope**: Practical examples with complete working code

## Dependencies

This ADR depends on completion of the core specification ADRs:

- **ADR-181**: Unified Durative Action Specification and Planner Standardization (authoritative patterns)
- **ADR-182**: Fix Duration Handling Precision Loss (technical implementation)
- **ADR-183**: Planner Standardization Open Problems (architecture standards)
- **ADR-184**: Unified Action Specification Examples (developer reference)
- **ADR-185**: AriaEngine Quick Start Guide (prerequisite knowledge)

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
**Prerequisites**: ADR-185 (Quick Start Guide)  
**Time Investment**: 45-60 minutes for complete understanding

## Implementation Notes

**Awaiting**: Completion of ADRs 181-184 to ensure all examples use authoritative patterns.

**Key Requirements**:

- All action definitions must use ADR-181 attribute patterns
- State management must follow ADR-182 precision handling
- Architecture must align with ADR-183 standards
- Examples must be consistent with ADR-184 reference implementations
- Error handling must follow established patterns
- Resource management must use validated entity requirements
