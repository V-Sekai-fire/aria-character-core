## Current Work

Creating a Neon Frontlines City Block domain simulator that runs the game domain defined in `apps/aria_viewer/decisions/draft_vsekai_domain.exs`. The simulator will execute 4 player archetypes adapted for cyberpunk logistics warfare (Local Socializer, Block Explorer, Local Achiever, Block Competitor) and log their activities in real-time through a web interface within a single neon-lit city block environment.

## Key Technical Concepts

- **Neon Frontlines City Block Game Domain**: 4 player archetypes adapted for cyberpunk logistics warfare within one contained neon-lit urban space
- **AriaHybridPlanner.Domain**: Domain definition framework for cyberpunk simulation
- **godot-enet**: ENet-based real-time networking for simulation transport (dragonhunt02/enet-godot)
- **Phoenix Framework**: Web dashboard for monitoring and control
- **TimescaleDB**: Time-series database for simulation event logging
- **AriaState**: State management for block state and agent tracking
- **Multi-agent Simulation**: Concurrent execution of cybernetically-enhanced operatives
- **Block Transfer**: Fast, in-memory state hand-off between local destinations (adapted from zone transfer concept)

## Relevant Files and Code

### Game Domain Definition

- `apps/aria_viewer/decisions/draft_vsekai_domain.exs`: Complete Vsekai.GameDomain with 4 player archetypes (needs adaptation for Neon Frontlines city block)
  - **The Social Explorer (High Player Concurrency)** → Local Socializer: join_world → command_squad → log_tactical_decision
  - **The World Hopper (High Instance Count)** → Block Explorer: visit_new_world → transfer_supplies (block transfer)
  - **The Achiever (High Transactional Intensity)** → Local Achiever: refine_resource → allocate_resources for logistics optimization
  - **The Competitor (High-Stakes Interaction)** → Block Competitor: engage_in_combat → coordinate_firefight for tactical advantage

### Existing Infrastructure

- `apps/aria_viewer/lib/aria_viewer_web/channels/ik_channel.ex`: Phoenix channel (needs adaptation for simulation)
- `apps/aria_viewer/priv/static/js/app.js`: WebSocket client setup (can be adapted)
- `apps/aria_viewer/mix.exs`: Phoenix dependencies already configured
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: TimescaleDB setup scripts
- `apps/aria_viewer/decisions/V-Sekai System Architecture Plan.md`: Block transfer concept reference

### Database Optimization Files

- `apps/aria_viewer/decisions/bitemporal_6nf_postgres.sql`: Bitemporal schema reference
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: Hypertable optimization patterns

## Neon Frontlines City Block Environment Features

- **Block Map**: Grid-based representation of neon-lit buildings, alleys, and strategic chokepoints
- **Supply Chain Network**: Critical logistics hubs, warehouses, and distribution centers
- **Tactical Operations**: Combat zones, safe houses, and command posts
- **Resource Economy**: Cybernetic enhancements, ammunition, and tactical supplies
- **Operative Networks**: Alliance tracking between cybernetically-enhanced agents

## Problem Solving

### Architecture Decisions Made

1. **Reuse aria_viewer**: Leverage existing Phoenix infrastructure for web dashboard
2. **godot-enet transport**: Use ENet-based networking for simulation transport layer
3. **Multi-agent simulation**: Run concurrent cybernetically-enhanced operatives with different archetypes
4. **Real-time logging**: Capture all domain actions via ENet state synchronization
5. **TimescaleDB integration**: Apply optimizations for simulation event storage
6. **Web dashboard**: Clean interface for simulation monitoring and control
7. **Neon Frontlines ethos**: Single contained environment with cyberpunk logistics warfare dynamics
8. **Block transfer**: Fast, in-memory state hand-off between local destinations

### Technical Challenges Addressed

- **Domain adaptation**: Move Vsekai.GameDomain to AriaViewer.GameDomain with Neon Frontlines modifications
- **State management**: AriaState.RelationalState for operative and block state
- **Concurrent execution**: Manage multiple cybernetically-enhanced agents running simultaneously within block
- **Event streaming**: Real-time broadcasting of simulation activities
- **Performance monitoring**: Track simulation metrics and operative behavior
- **Block transfer implementation**: Fast in-memory movement between local destinations

## Pending Tasks and Next Steps

### Phase 1: Domain Integration & Neon Frontlines City Block Setup

1. Move Vsekai.GameDomain into AriaViewer.GameDomain namespace
2. Adapt domain methods for Neon Frontlines city block environment (block transfer vs world hopping)
3. Create neon city block environment definition (buildings, supply chains, tactical locations)
4. Implement operative archetypes for cyberpunk logistics warfare setting
5. Set up AriaState integration for block simulation state

### Phase 2: Simulation Engine & Operative Behaviors

1. Create simulation engine for multi-agent execution within neon city block
2. Implement Local Socializer archetype (squad deployment, strategic decisions)
3. Implement Block Explorer archetype (resource allocation, logistics optimization)
4. Implement Local Achiever archetype (mission planning, HTN task coordination)
5. Implement Block Competitor archetype (tactical combat, resource management)
6. Build operative scheduler for concurrent cybernetically-enhanced agent management

### Phase 3: Real-time Simulation & Broadcasting

1. Implement ENet server for simulation transport layer (dragonhupt02/enet-godot)
2. Create block state synchronization protocol for operative updates
3. Implement activity logging for all operative actions with block location metadata
4. Add TimescaleDB integration for event storage with hypertables
5. Build simulation controls (start/stop/pause, operative count adjustment)
6. Add performance monitoring and simulation metrics

### Phase 4: Web Simulation Interface

1. Create Phoenix dashboard for monitoring ENet simulation server
2. Implement WebSocket connection to ENet server status and metrics
3. Add operative status displays with individual activity tracking
4. Implement web-based simulation controls (communicate with ENet server)
5. Build activity visualization with charts and graphs for block dynamics

### Phase 5: Analytics & Tactical Insights

1. Create simulation analytics for operative behavior patterns
2. Build historical reports using TimescaleDB data
3. Implement archetype analysis and comparison within block context
4. Add performance metrics and system utilization tracking
5. Create data export capabilities for tactical behavior analysis

## Implementation Strategy

### Core Simulation Loop

- Initialize operatives as cybernetically-enhanced agents with different archetypes
- Execute domain actions based on tactical objectives and logistics state
- Synchronize operative states via ENet protocol for real-time updates
- Log all activities with timestamps and block location metadata
- Broadcast events via ENet for block-wide state synchronization
- Maintain block state and operative status through ENet messaging

### Operative Archetypes Implementation

- **The Social Explorer (High Player Concurrency)**: Squad deployment → strategic decisions → mission logging
- **The World Hopper (High Instance Count)**: Resource allocation → logistics optimization → supply chain management
- **The Achiever (High Transactional Intensity)**: Mission planning → HTN task coordination → operational oversight
- **The Competitor (High-Stakes Interaction)**: Tactical combat → resource management → battlefield coordination

### Real-time Architecture

- **ENet server** (dragonhupt02/enet-godot) for simulation transport and operative synchronization
- **Block state synchronization** protocol for real-time operative updates and block transfers
- **Phoenix dashboard** for monitoring ENet server status and simulation metrics
- **WebSocket connection** from dashboard to ENet server for status updates
- **TimescaleDB** for persistent event storage with block-specific metadata
- **Dashboard controls** for simulation management (communicate with ENet server)

## Success Criteria

- **Multi-agent simulation**: Successfully run 50+ concurrent cybernetically-enhanced operatives
- **Real-time monitoring**: Live dashboard showing block activities and tactical dynamics
- **Complete domain execution**: All 4 archetypes functioning with logistics warfare goal-task chains
- **Block transfer performance**: Zero IOPS for movement within the block (in-memory)
- **TimescaleDB integration**: Efficient storage of operative interaction events
- **Web interface**: Intuitive controls and visualization of block tactical state
- **Performance**: Maintain simulation performance with active cyberpunk logistics operations

This Neon Frontlines city block simulation creates an intense, observable environment where cyberpunk logistics warfare unfolds in real-time, with operatives commanding squads, managing supply chains, coordinating strategies, and engaging in tactical combat. The block transfer mechanism ensures seamless movement between local destinations while maintaining the original architecture's performance benefits.
