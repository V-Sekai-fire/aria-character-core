## Current Work

Creating a V-Sekai domain simulator that runs the game domain defined in `apps/aria_viewer/decisions/draft_vsekai_domain.exs`. The simulator will execute the 4 player archetypes (Social Explorer, World Hopper, Achiever, Competitor) and log their activities in real-time through a web interface.

## Key Technical Concepts

- **V-Sekai Game Domain**: 4 player archetypes with distinct behaviors and goals
- **AriaHybridPlanner.Domain**: Domain definition framework for game simulation
- **Phoenix Framework**: Web application with real-time capabilities via channels
- **TimescaleDB**: Time-series database for simulation event logging
- **AriaState**: State management for simulation state and agent tracking
- **Multi-agent Simulation**: Concurrent execution of multiple player agents

## Relevant Files and Code

### Game Domain Definition

- `apps/aria_viewer/decisions/draft_vsekai_domain.exs`: Complete Vsekai.GameDomain with 4 player archetypes
  - Social Explorer: join_world → socialize → log_social_event
  - World Hopper: visit_new_world → transfer_to_world
  - Achiever: refine_resource → process_item for resource accumulation
  - Competitor: engage_in_combat → record_match_outcome for ranking

### Existing Infrastructure

- `apps/aria_viewer/lib/aria_viewer_web/channels/ik_channel.ex`: Phoenix channel for real-time communication
- `apps/aria_viewer/priv/static/js/app.js`: WebSocket client setup (can be adapted)
- `apps/aria_viewer/mix.exs`: Phoenix dependencies already configured
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: TimescaleDB setup scripts

### Database Optimization Files

- `apps/aria_viewer/decisions/bitemporal_6nf_postgres.sql`: Bitemporal schema reference
- `apps/aria_viewer/decisions/timescaledb_optimization.sql`: Hypertable optimization patterns

## Problem Solving

### Architecture Decisions Made

1. **Reuse aria_viewer**: Leverage existing Phoenix + WebSocket infrastructure
2. **Multi-agent simulation**: Run concurrent agents with different archetypes
3. **Real-time logging**: Capture all domain actions via Phoenix channels
4. **TimescaleDB integration**: Apply optimizations for simulation event storage
5. **Web dashboard**: Clean interface for simulation monitoring and control

### Technical Challenges Addressed

- **Domain integration**: Move Vsekai.GameDomain into AriaViewer namespace
- **State management**: AriaState.RelationalState for agent and world state
- **Concurrent execution**: Manage multiple agents running simultaneously
- **Event streaming**: Real-time broadcasting of simulation activities
- **Performance monitoring**: Track simulation metrics and agent behavior

## Pending Tasks and Next Steps

### Phase 1: Domain Integration & Simulation Core

1. Move Vsekai.GameDomain into AriaViewer.GameDomain namespace
2. Create simulation engine for multi-agent execution
3. Implement agent archetypes (Social Explorer, World Hopper, Achiever, Competitor)
4. Set up AriaState integration for simulation state
5. Create simulation scheduler for concurrent agent management

### Phase 2: Real-time Simulation & Logging

1. Implement activity logging for all agent actions
2. Add TimescaleDB integration for event storage
3. Create real-time broadcasting via Phoenix channels
4. Build simulation controls (start/stop/pause, agent count adjustment)
5. Implement simulation metrics and performance tracking

### Phase 3: Web Simulation Interface

1. Remove WebGL2 dependencies and 3D components
2. Create simulation dashboard for real-time monitoring
3. Add agent monitoring with individual status displays
4. Implement web-based simulation controls
5. Build activity visualization with charts and graphs

### Phase 4: Analytics & Reporting

1. Create simulation analytics for agent behavior patterns
2. Build historical reports using TimescaleDB data
3. Implement archetype analysis and comparison
4. Add performance metrics and system utilization tracking
5. Create data export capabilities for further analysis

## Implementation Strategy

### Core Simulation Loop

- Initialize multiple agents with different archetypes
- Execute domain actions based on agent goals and current state
- Log all activities with timestamps and metadata
- Broadcast events in real-time via WebSockets
- Maintain simulation state and agent status

### Agent Archetypes Implementation

- **Social Explorer**: World discovery → social interaction → event logging
- **World Hopper**: Multi-world exploration → fast transfers → visit tracking
- **Achiever**: Resource gathering → refinement processing → quantity accumulation
- **Competitor**: Match finding → combat engagement → ranking updates

### Real-time Architecture

- Phoenix channels for simulation event broadcasting
- WebSocket streaming of agent activities
- TimescaleDB for persistent event storage
- Dashboard for live simulation monitoring
- Controls for simulation management

## Success Criteria

- **Multi-agent simulation**: Successfully run 100+ concurrent agents
- **Real-time monitoring**: Live dashboard showing agent activities
- **Complete domain execution**: All 4 archetypes functioning with proper goal-task chains
- **TimescaleDB integration**: Efficient storage and querying of simulation events
- **Web interface**: Intuitive controls and visualization of simulation state
- **Performance**: Maintain simulation performance with multiple concurrent agents

This implementation will create a comprehensive V-Sekai domain simulator that can run complex multi-agent scenarios and provide real-time insights into player behavior patterns across all defined archetypes.
