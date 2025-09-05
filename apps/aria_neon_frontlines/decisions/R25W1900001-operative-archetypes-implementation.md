# R25W1900001 - Operative Archetypes Implementation

## Status
Proposed

## Context
The Neon Frontlines City Block simulator requires implementing 4 distinct operative archetypes adapted from the original Vsekai player types, each specialized for cyberpunk logistics warfare within a single urban block environment.

## Decision
Implement 4 operative archetypes with clear behavioral patterns and tactical objectives:

1. **Local Socializer**: Squad deployment and strategic decision-making
2. **Block Explorer**: Resource allocation and logistics optimization
3. **Local Achiever**: Mission planning and HTN task coordination
4. **Block Competitor**: Tactical combat and resource management

## Implementation Plan

### Phase 1: Archetype Base Structure
- [ ] Create `AriaNeonFrontlines.Operative.Archetype` behaviour module
- [ ] Define common interface for all operative types
- [ ] Implement archetype registration and lookup system
- [ ] Add archetype-specific state management

### Phase 2: Local Socializer Implementation
- [ ] Squad deployment mechanics (command_squad)
- [ ] Strategic decision logging (log_tactical_decision)
- [ ] High concurrency handling for multiple squad operations
- [ ] Real-time tactical coordination

### Phase 3: Block Explorer Implementation
- [ ] Resource allocation algorithms (allocate_resources)
- [ ] Logistics optimization for supply chain management
- [ ] Block transfer coordination for resource movement
- [ ] Performance tracking for logistics efficiency

### Phase 4: Local Achiever Implementation
- [ ] HTN task hierarchy design and execution
- [ ] Mission planning and operational oversight
- [ ] Performance metrics and achievement tracking
- [ ] Goal-task chain optimization

### Phase 5: Block Competitor Implementation
- [ ] Tactical combat mechanics (coordinate_firefight)
- [ ] Resource management for ammunition and supplies
- [ ] Battlefield coordination and positioning
- [ ] Competitive scoring and performance analysis

## Archetype Specifications

### Local Socializer (High Player Concurrency)
- **Primary Actions**: command_squad, log_tactical_decision
- **Behavioral Pattern**: Squad-based operations with strategic oversight
- **Performance Metric**: Squad deployment success rate
- **Concurrency**: High - manages multiple concurrent squad operations

### Block Explorer (High Instance Count)
- **Primary Actions**: allocate_resources, transfer_supplies
- **Behavioral Pattern**: Logistics optimization and resource flow management
- **Performance Metric**: Resource allocation efficiency
- **Concurrency**: High - handles multiple resource streams

### Local Achiever (High Transactional Intensity)
- **Primary Actions**: plan_mission, coordinate_tasks
- **Behavioral Pattern**: Mission planning and operational execution
- **Performance Metric**: Mission completion rate and efficiency
- **Concurrency**: Medium - focused on complex task coordination

### Block Competitor (High-Stakes Interaction)
- **Primary Actions**: engage_combat, manage_resources
- **Behavioral Pattern**: Tactical combat and resource competition
- **Performance Metric**: Combat effectiveness and resource control
- **Concurrency**: Medium-High - handles tactical engagements

## Consequences

### Positive
- **Clear Specialization**: Each archetype has distinct tactical role
- **Behavioral Predictability**: Consistent patterns for simulation analysis
- **Performance Tracking**: Measurable metrics for each archetype type
- **Scalability**: Archetype system supports concurrent multi-agent execution

### Negative
- **Implementation Complexity**: 4 distinct behavioral models to maintain
- **Testing Overhead**: Each archetype requires separate validation
- **Balance Challenges**: Ensuring archetypes complement rather than compete
- **State Management**: Complex state tracking across archetype types

## Success Criteria
- [ ] All 4 archetypes implement required behavioral patterns
- [ ] Concurrent execution of 50+ operatives across archetype types
- [ ] Measurable performance metrics for each archetype
- [ ] Clean separation of concerns between archetype implementations
- [ ] Integration with AriaHybridPlanner domain execution

## Related Decisions
- R25W1900000: Neon Frontlines Domain Adaptation
- R25W1900005: Simulation Engine Architecture
- R25W1900006: Performance Monitoring System
