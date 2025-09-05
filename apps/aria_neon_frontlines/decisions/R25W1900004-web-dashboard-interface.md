# R25W1900004 - Web Dashboard Interface

## Status
Proposed

## Context
The Neon Frontlines City Block simulator requires a Phoenix-based web dashboard for real-time monitoring and control of cybernetically-enhanced operatives, providing intuitive visualization of block activities and simulation management capabilities.

## Decision
Implement a Phoenix web dashboard with the following components:

1. **Operative Status Displays**: Real-time tracking of individual operative activities
2. **Simulation Controls**: Start/stop/pause functionality with operative count adjustment
3. **Activity Visualization**: Charts and graphs showing block dynamics
4. **WebSocket Integration**: Bidirectional communication with simulation engine

## Implementation Plan

### Phase 1: Dashboard Foundation
- [ ] Create Phoenix dashboard controller and routes
- [ ] Implement basic HTML layout with operative status sections
- [ ] Add WebSocket channel for real-time updates
- [ ] Set up dashboard authentication and access control

### Phase 2: Operative Monitoring
- [ ] Build individual operative status displays
- [ ] Implement real-time position tracking on block map
- [ ] Add operative activity history and current actions
- [ ] Create operative performance metrics visualization

### Phase 3: Simulation Controls
- [ ] Implement start/stop/pause simulation buttons
- [ ] Add operative count adjustment controls
- [ ] Build archetype distribution configuration
- [ ] Create simulation speed and timing controls

### Phase 4: Activity Visualization
- [ ] Implement block map with operative positions
- [ ] Add activity charts and performance graphs
- [ ] Create transfer event visualization
- [ ] Build real-time metrics dashboard

### Phase 5: WebSocket Integration
- [ ] Set up bidirectional WebSocket communication
- [ ] Implement real-time operative state updates
- [ ] Add simulation control command handling
- [ ] Build connection status monitoring

## Dashboard Components

### Operative Status Panel
- **Individual Cards**: Each operative with current status and location
- **Activity Feed**: Real-time stream of operative actions
- **Performance Metrics**: Success rates and efficiency indicators
- **Archetype Grouping**: Visual separation by operative type

### Simulation Control Panel
- **Primary Controls**: Start, stop, pause, resume buttons
- **Operative Management**: Spawn new operatives, adjust counts
- **Configuration**: Archetype ratios and simulation parameters
- **Status Indicators**: Simulation health and performance metrics

### Block Visualization
- **Interactive Map**: Grid-based representation of city block
- **Operative Positions**: Real-time location tracking
- **Destination Highlights**: Active transfer zones and combat areas
- **Activity Heatmap**: Concentration of operative activities

### Metrics Dashboard
- **Performance Charts**: Operative efficiency and transfer rates
- **System Health**: Memory usage, process counts, response times
- **Activity Analytics**: Archetype performance comparisons
- **Historical Trends**: Simulation progress over time

## Technical Specifications

### WebSocket Communication
- **Channel**: `AriaNeonFrontlinesWeb.SimulationChannel`
- **Message Types**: Operative updates, simulation controls, metrics
- **Update Frequency**: Real-time with configurable throttling
- **Error Handling**: Connection recovery and state synchronization

### Frontend Technologies
- **Framework**: Phoenix LiveView for reactive updates
- **Visualization**: D3.js or Chart.js for metrics and maps
- **Styling**: Tailwind CSS for responsive design
- **State Management**: LiveView assigns for component state

### Performance Targets
- **Update Latency**: Sub-100ms for operative status updates
- **Concurrent Users**: Support for multiple dashboard viewers
- **Memory Usage**: Efficient state management for long sessions
- **Scalability**: Linear performance with operative count

## User Experience

### Dashboard Layout
```
┌─────────────────────────────────────────────────┐
│ Simulation Controls    [START] [PAUSE] [STOP]   │
├─────────────────────┬───────────────────────────┤
│ Operative Status    │ Block Map & Activity     │
│ • Operative #001    │ • Real-time positions     │
│ • Operative #002    │ • Transfer events         │
│ • ...               │ • Activity heatmap        │
├─────────────────────┼───────────────────────────┤
│ Performance Metrics │ Activity Charts          │
│ • Transfer Rate     │ • Operative efficiency   │
│ • System Health     │ • Archetype comparison   │
└─────────────────────┴───────────────────────────┘
```

### Interaction Patterns
- **Click Operative**: View detailed status and activity history
- **Drag Controls**: Adjust simulation parameters in real-time
- **Zoom Map**: Focus on specific block areas for detailed view
- **Filter Display**: Show/hide operative types and activities

## Consequences

### Positive
- **Real-time Visibility**: Complete operational awareness of simulation
- **Intuitive Controls**: Easy simulation management and configuration
- **Performance Insights**: Comprehensive metrics and analytics
- **User Experience**: Professional interface for monitoring complex simulation

### Negative
- **Development Complexity**: Multiple frontend technologies integration
- **Performance Overhead**: Real-time updates impact on simulation performance
- **Browser Limitations**: Web-based interface constraints
- **Maintenance Burden**: Frontend code requires separate maintenance

## Success Criteria
- [ ] Real-time display of 50+ operative statuses and positions
- [ ] Intuitive simulation controls with immediate response
- [ ] Comprehensive activity visualization and metrics
- [ ] Stable WebSocket communication with error recovery
- [ ] Professional UI supporting multiple concurrent viewers

## Related Decisions
- R25W1900003: Real-time Broadcasting System
- R25W1900005: Simulation Engine Architecture
- R25W1900006: Performance Monitoring System
