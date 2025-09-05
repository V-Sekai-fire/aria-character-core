## Current Work

Creating a City Block V-Sekai domain simulator that runs the game domain defined in `apps/aria_viewer/decisions/draft_vsekai_domain.exs`. The simulator will execute 4 player archetypes adapted for urban community dynamics (Local Socializer, Block Explorer, Local Achiever, Block Competitor) and log their activities in real-time through a web interface within a single city block environment.

## Key Technical Concepts

- **City Block Game Domain**: 4 player archetypes adapted for local community interactions within one contained urban space
- **AriaHybridPlanner.Domain**: Domain definition framework for urban simulation
- **godot-enet**: ENet-based real-time networking for simulation transport (dragonhunt02/enet-godot)
- **Phoenix Framework**: Web dashboard for monitoring and control
- **TimescaleDB**: Time-series database for simulation event logging
- **AriaState**: State management for block state and agent tracking
- **Multi-agent Simulation**: Concurrent execution of community member agents
- **Block Transfer**: Fast, in-memory state hand-off between local destinations (adapted from zone transfer concept)

## Relevant Files and Code

### Game Domain Definition

- `apps/aria_viewer/decisions/draft_vsekai_domain.exs`: Complete Vsekai.GameDomain with 4 player archetypes (needs adaptation for city block)
  - Social Explorer → Local Socializer: join_world → socialize → log_social_event
  - World Hopper → Block Explorer: visit_new_world → transfer_to_world (block transfer)
  - Achiever → Local Achiever: refine_resource → process_item for resource accumulation
  - Competitor → Block Competitor: engage_in_combat → record_match_outcome for ranking

### Existing Infrastructure

- `apps/aria_viewer/lib/aria_viewer_web/channels/ik_channel.ex`: Phoenix channel (needs adaptation for simulation)
- `apps/aria_viewer/priv/static/js/app.js`: WebSocket client setup (can be adapted)
- `apps/aria_viewer/mix.exs`: Phoenix dependencies already configured
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: TimescaleDB setup scripts
- `apps/aria_viewer/decisions/V-Sekai System Architecture Plan.md`: Block transfer concept reference

### Database Optimization Files

- `apps/aria_viewer/decisions/bitemporal_6nf_postgres.sql`: Bitemporal schema reference
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: Hypertable optimization patterns

## City Block Environment Features

- **Block Map**: Grid-based representation of buildings and streets
- **Business Registry**: Local businesses with owners and specialties
- **Community Events**: Scheduled gatherings and block activities
- **Resource Economy**: Block-level goods and services
- **Social Networks**: Relationship tracking between block residents

## Problem Solving

### Architecture Decisions Made

1. **Reuse aria_viewer**: Leverage existing Phoenix infrastructure for web dashboard
2. **godot-enet transport**: Use ENet-based networking for simulation transport layer
3. **Multi-agent simulation**: Run concurrent agents with different archetypes
4. **Real-time logging**: Capture all domain actions via ENet state synchronization
5. **TimescaleDB integration**: Apply optimizations for simulation event storage
6. **Web dashboard**: Clean interface for simulation monitoring and control
7. **City block ethos**: Single contained environment with local community dynamics
8. **Block transfer**: Fast in-memory state hand-off between local destinations

### Technical Challenges Addressed

- **Domain adaptation**: Move Vsekai.GameDomain to AriaViewer.GameDomain with city block modifications
- **State management**: AriaState.RelationalState for agent and block state
- **Concurrent execution**: Manage multiple agents running simultaneously within block
- **Event streaming**: Real-time broadcasting of simulation activities
- **Performance monitoring**: Track simulation metrics and agent behavior
- **Block transfer implementation**: Fast in-memory movement between local destinations

## Pending Tasks and Next Steps

### Phase 1: Domain Integration & City Block Setup

1. Move Vsekai.GameDomain into AriaViewer.GameDomain namespace
2. Adapt domain methods for city block environment (block transfer vs world hopping)
3. Create city block environment definition (buildings, businesses, locations)
4. Implement agent archetypes for local community setting
5. Set up AriaState integration for block simulation state

### Phase 2: Simulation Engine & Agent Behaviors

1. Create simulation engine for multi-agent execution within city block
2. Implement Local Socializer archetype (cafe visits, neighbor interactions)
3. Implement Block Explorer archetype (local discovery, block transfers)
4. Implement Local Achiever archetype (business success, service provision)
5. Implement Block Competitor archetype (community leadership, local rivalries)
6. Build agent scheduler for concurrent block resident management

### Phase 3: Real-time Simulation & Broadcasting

1. Implement ENet server for simulation transport layer (dragonhunt02/enet-godot)
2. Create block state synchronization protocol for agent updates
3. Implement activity logging for all agent actions with block location metadata
4. Add TimescaleDB integration for event storage with hypertables
5. Build simulation controls (start/stop/pause, agent count adjustment)
6. Add performance monitoring and simulation metrics

### Phase 4: Web Simulation Interface

1. Create Phoenix dashboard for monitoring ENet simulation server
2. Implement WebSocket connection to ENet server status and metrics
3. Add agent status displays with individual activity tracking
4. Implement web-based simulation controls (communicate with ENet server)
5. Build activity visualization with charts and graphs for block dynamics

### Phase 5: Analytics & Community Insights

1. Create simulation analytics for agent behavior patterns
2. Build historical reports using TimescaleDB data
3. Implement archetype analysis and comparison within block context
4. Add performance metrics and system utilization tracking
5. Create data export capabilities for community behavior analysis

## Implementation Strategy

### Core Simulation Loop

- Initialize agents as block residents with different archetypes
- Execute domain actions based on local goals and community state
- Synchronize agent states via ENet protocol for real-time updates
- Log all activities with timestamps and block location metadata
- Broadcast events via ENet for block-wide state synchronization
- Maintain block state and resident status through ENet messaging

### Agent Archetypes Implementation

- **Local Socializer**: Cafe visits → neighbor socialization → community event logging
- **Block Explorer**: Local discovery → block transfers → destination exploration
- **Local Achiever**: Business operations → service provision → community reputation
- **Block Competitor**: Community leadership → event organization → local influence

### Real-time Architecture

- **ENet server** (dragonhunt02/enet-godot) for simulation transport and agent synchronization
- **Block state synchronization** protocol for real-time agent updates and block transfers
- **Phoenix dashboard** for monitoring ENet server status and simulation metrics
- **WebSocket connection** from dashboard to ENet server for status updates
- **TimescaleDB** for persistent event storage with block-specific metadata
- **Dashboard controls** for simulation management (communicate with ENet server)

## Success Criteria

- **Multi-agent simulation**: Successfully run 50+ concurrent block residents
- **Real-time monitoring**: Live dashboard showing block activities and social dynamics
- **Complete domain execution**: All 4 archetypes functioning with local goal-task chains
- **Block transfer performance**: Zero IOPS for movement within the block (in-memory)
- **TimescaleDB integration**: Efficient storage of community interaction events
- **Web interface**: Intuitive controls and visualization of block community state
- **Performance**: Maintain simulation performance with active community interactions

This city block simulation creates an intimate, observable environment where community dynamics unfold in real-time, with agents forming relationships, competing for local status, and participating in block-level activities. The block transfer mechanism ensures seamless movement between local destinations while maintaining the original architecture's performance benefits.
