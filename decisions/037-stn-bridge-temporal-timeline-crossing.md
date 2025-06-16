# ADR-037: STN Bridge Architecture for Temporal Timeline Crossing

**Status:** Active  
**Date:** June 16, 2025  
**Priority:** High - Core architectural understanding

## Context

The AriaEngine planner uses Simple Temporal Networks (STNs) with a specialized "STN bridge"
architecture to handle temporal planning across different timelines and temporal contexts. This concept
is fundamental to the system's ability to coordinate actions that span multiple temporal domains, but the
mechanism and its practical value need clear documentation with concrete examples.

## What Are STN Bridges?

STN bridges are temporal coordination mechanisms that allow the planner to establish temporal
relationships between events that exist in different timeline contexts. They act as "connectors" that
maintain temporal consistency while crossing between different temporal domains.

### Core Concept

An STN bridge consists of:

1. **Bridge Points**: Specific temporal anchors that can exist in multiple timelines
2. **Temporal Constraints**: Rules that govern how time flows between connected timelines  
3. **Synchronization Logic**: Mechanisms to maintain consistency across timeline boundaries
4. **Validation Framework**: Ensuring temporal relationships remain valid across bridges

## Modern Real-World Examples

### Example 1: International Business Meeting Coordination

**Scenario**: A global company needs to coordinate a product launch across multiple time zones.

**Without STN Bridges** (Traditional approach):

- Meeting scheduled for "3 PM EST"
- Each region manually converts to local time
- Risk of confusion, missed meetings, scheduling conflicts
- No automatic validation of availability across zones

**With STN Bridges**:

- **Bridge Points**: The meeting event exists as a shared temporal anchor
- **Timeline Context A**: New York office (EST timeline)
- **Timeline Context B**: London office (GMT timeline)  
- **Timeline Context C**: Tokyo office (JST timeline)
- **Temporal Constraints**: Meeting must occur simultaneously across all timelines
- **Validation**: System ensures the chosen time doesn't conflict with local business hours,
  holidays, or existing commitments in any timeline

```text
Bridge: Global_Meeting_Event
├── EST_Timeline: 3:00 PM (primary anchor)
├── GMT_Timeline: 8:00 PM (auto-calculated)
└── JST_Timeline: 5:00 AM+1 (auto-calculated, flagged as outside business hours)
```

### Example 2: Supply Chain Coordination

**Scenario**: Manufacturing process that spans multiple facilities with different operational schedules.

**Timeline Context A**: Raw material supplier (operates 24/7)
**Timeline Context B**: Manufacturing facility (Mon-Fri, 6 AM - 10 PM)
**Timeline Context C**: Shipping logistics (operates on delivery windows)

**STN Bridge Implementation**:

- **Bridge Points**: Material delivery, production start, shipping deadline
- **Temporal Constraints**:
  - Material must arrive 2 hours before production starts
  - Production must complete 4 hours before shipping window
  - Account for different weekend/holiday schedules

```
Bridge: Production_Pipeline
├── Supplier_Timeline: Material ready (any time)
├── Factory_Timeline: Production window (6 AM - 10 PM, weekdays only)
└── Shipping_Timeline: Pickup window (2 PM - 6 PM daily)

Constraints:
- Material_Ready + 2h ≤ Production_Start
- Production_End + 4h ≤ Shipping_Pickup
- Production_Start must be within factory operating hours
```

### Example 3: Content Creator Streaming Schedule

**Scenario**: A content creator streams on multiple platforms with different audience peak times.

**Timeline Context A**: Twitch (primarily US audience, peak 7-11 PM EST)
**Timeline Context B**: YouTube (global audience, multiple peak windows)
**Timeline Context C**: Personal schedule (content creator's local time)

**STN Bridge Implementation**:

- **Bridge Points**: Stream start, content preparation, audience engagement windows
- **Temporal Constraints**:
  - Stream must hit peak hours for primary platform
  - Allow preparation time in creator's personal timeline
  - Consider audience overlap between platforms

```
Bridge: Multi_Platform_Stream
├── Creator_Timeline: 8 PM local (preparation complete)
├── Twitch_Timeline: 9 PM EST (peak audience)
└── YouTube_Timeline: 2 AM GMT (secondary audience peak)

Constraints:
- Preparation_Complete + 30min ≤ Stream_Start
- Stream_Start must overlap with Twitch_Peak_Hours
- Stream duration should capture both audience windows
```

## Technical Implementation in AriaEngine

### STN Bridge Architecture

```elixir
defmodule AriaEngine.Planner.STNBridge do
  @moduledoc """
  Manages temporal relationships across different timeline contexts.
  
  Bridges enable coordination between:
  - Game world timelines (combat, exploration, dialogue)
  - Real-world constraints (streaming schedule, player availability)
  - System timelines (server maintenance, update windows)
  """
  
  defstruct [
    :bridge_id,
    :anchor_points,      # Temporal events that exist across timelines
    :timeline_contexts,  # Different temporal domains being connected
    :constraints,        # Temporal relationships that must be maintained
    :validation_rules    # Logic for ensuring temporal consistency
  ]
end
```

### Bridge Validation Process

1. **Temporal Consistency Check**: Verify that all constraints can be satisfied simultaneously across all connected timelines
2. **Resource Availability**: Ensure required resources exist in all relevant timeline contexts
3. **Priority Resolution**: Handle conflicts when timelines have competing constraints
4. **Fallback Planning**: Generate alternative plans when primary temporal relationships cannot be satisfied

## Benefits of STN Bridges

### 1. **Temporal Coordination Across Domains**

- Automatically handles complex timing relationships
- Reduces manual coordination overhead
- Prevents temporal conflicts before they occur

### 2. **Scalable Timeline Management**

- Add new timeline contexts without rewriting existing logic
- Bridge constraints automatically propagate across all connected timelines
- Modular approach allows independent timeline updates

### 3. **Robust Conflict Resolution**

- Systematic approach to handling temporal conflicts
- Clear prioritization mechanisms
- Automatic generation of alternative solutions

### 4. **Real-World Integration**

- Seamlessly coordinate virtual and real-world timing constraints
- Handle different calendar systems, time zones, and scheduling contexts
- Maintain consistency across hybrid virtual/physical experiences

## Decision

Implement STN bridges as the core mechanism for temporal coordination in AriaEngine, with the following architecture:

1. **Bridge Definition Layer**: Define temporal relationships between timeline contexts
2. **Constraint Propagation**: Automatically update constraints across connected timelines  
3. **Validation Engine**: Ensure temporal consistency before committing to plans
4. **Conflict Resolution**: Systematic handling of temporal conflicts with fallback options

## Implementation Plan

- [x] Document STN bridge concept and real-world applications
- [ ] Implement bridge definition data structures
- [ ] Create constraint propagation algorithms
- [ ] Build temporal validation framework
- [ ] Add conflict resolution mechanisms
- [ ] Integrate with existing STN planner
- [ ] Create comprehensive test suite with real-world scenarios
- [ ] Document API for defining custom bridges

## Success Criteria

1. **Clear Understanding**: Development team can explain STN bridges using real-world examples
2. **Practical Implementation**: System can handle complex temporal coordination scenarios
3. **Validation Completeness**: All temporal relationships are validated before plan execution
4. **Performance**: Bridge calculations complete within acceptable time limits for real-time planning
5. **Extensibility**: New timeline contexts can be added without system redesign

## Consequences

### Positive

- **Robust Temporal Planning**: Systematic approach to complex timing coordination
- **Real-World Integration**: Natural handling of mixed virtual/physical timing constraints
- **Scalable Architecture**: Easy to extend with new timeline contexts and constraints
- **Conflict Prevention**: Issues identified and resolved during planning phase

### Negative

- **Implementation Complexity**: Requires sophisticated temporal reasoning algorithms
- **Performance Overhead**: Additional validation and constraint checking
- **Learning Curve**: Developers need to understand temporal coordination concepts

## Related ADRs

- **ADR-034**: Definitive Temporal Planner Architecture (parent ADR)
- **ADR-036**: Evolving AriaEngine Planner Blueprint (implementation context)

## Change Log

### June 16, 2025

- Initial documentation of STN bridge concept
- Added comprehensive real-world examples
- Defined technical architecture and benefits
