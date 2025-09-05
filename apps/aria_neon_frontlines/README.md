# Aria Neon Frontlines - Cyberpunk Logistics Warfare Simulator

A real-time multi-agent simulation system for cyberpunk logistics warfare within a single neon-lit city block. Features concurrent execution of cybernetically-enhanced operatives with different archetypes, real-time activity logging, and web-based monitoring through Phoenix dashboard.

## 🎯 Features

- **Multi-Agent Simulation**: Concurrent execution of 50+ cybernetically-enhanced operatives
- **4 Operative Archetypes**: Local Socializer, Block Explorer, Local Achiever, Block Competitor
- **Neon City Block Environment**: Grid-based urban space with buildings, alleys, and strategic chokepoints
- **Real-time Activity Logging**: Process-based broadcasting of operative actions and block state
- **Phoenix Web Dashboard**: Clean interface for simulation monitoring and control
- **TimescaleDB Integration**: Hypertable optimization for simulation event storage
- **Block Transfer Protocol**: Fast, in-memory state hand-off between local destinations
- **Cyberpunk Logistics Warfare**: Supply chain networks, tactical operations, and resource economy

## 🏗️ Architecture

```
┌─────────────────────────────────┐  Process Msgs  ┌─────────────────────────────────┐
│         Phoenix Dashboard       │◄──────────────►│      Elixir Simulation Engine   │
│                                 │   JSON msgs    │                                 │
│ • Operative Status Displays     │                │ • AriaHybridPlanner Domain      │
│ • Simulation Controls           │                │ • Multi-Agent Execution         │
│ • Activity Visualization        │                │ • Block State Synchronization   │
│ • Real-time Metrics             │                │ • TimescaleDB Event Logging     │
│ • WebSocket Connection          │                │ • Cybernetic Operative Mgmt     │
└─────────────────────────────────┘                └─────────────────────────────────┘
         │                                               │
         └────────────────► AriaState ◄──────────────────┘
                           AriaHybridPlanner
                           TimescaleDB
```

## 🚀 Quick Start

### Prerequisites

- Elixir 1.18+
- TimescaleDB (for event storage)
- Modern web browser with WebSocket support

### Installation

1. **Start the Phoenix server:**
   ```bash
   cd apps/aria_neon_frontlines
   mix deps.get
   mix phx.server
   ```

2. **Open the application:**
   - Simulation Dashboard: http://localhost:4000
   - Operative Monitor: http://localhost:4000/operatives

### Testing the System

1. **Open the simulation dashboard** in your browser
2. **Configure operative count** and archetype distribution
3. **Start the simulation** to see cybernetically-enhanced agents in action
4. **Monitor real-time activities** through the web interface
5. **View block transfer events** and logistics operations

## 📋 Operative Archetypes

### Local Socializer (High Player Concurrency)
- **Squad Deployment**: Command cybernetic squads in neon-lit urban warfare
- **Strategic Decisions**: Make tactical choices in high-stakes logistics scenarios
- **Mission Logging**: Track operative activities and decision outcomes

### Block Explorer (High Instance Count)
- **Resource Allocation**: Manage supply chains and distribution networks
- **Logistics Optimization**: Coordinate block-wide resource flows
- **Supply Chain Management**: Oversee warehouses and distribution centers

### Local Achiever (High Transactional Intensity)
- **Mission Planning**: Design HTN task hierarchies for complex operations
- **Operational Oversight**: Monitor and coordinate multiple concurrent missions
- **Performance Tracking**: Measure operative effectiveness and mission success

### Block Competitor (High-Stakes Interaction)
- **Tactical Combat**: Engage in cyberpunk warfare scenarios
- **Resource Management**: Control ammunition and tactical supplies
- **Battlefield Coordination**: Direct firefights and strategic positioning

## 🧪 Testing

### Simulation Test Client

The included test client provides:

- **Operative spawning** with archetype selection
- **Block state testing** with transfer validation
- **Activity logging** with TimescaleDB verification
- **Performance monitoring** for simulation metrics
- **Real-time feedback** on operative status and block dynamics

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test apps/aria_neon_frontlines/test/

# Start server for manual testing
mix phx.server
```

## 🔧 Configuration

### Phoenix Configuration

Key configuration files:
- `config/config.exs` - Main application config
- `config/dev.exs` - Development environment
- `apps/aria_neon_frontlines/config/config.exs` - App-specific config

### Process Messaging Configuration

- **Registry**: Elixir Registry for operative process lookup
- **Block Transfer Protocol**: In-memory state synchronization
- **Supervision**: OTP supervision trees for operative management

## 📁 Project Structure

```
apps/aria_neon_frontlines/
├── lib/
│   ├── aria_neon_frontlines/
│   │   ├── application.ex          # OTP application
│   │   └── web/
│   │       ├── channels/
│   │       │   └── simulation_channel.ex  # Process messaging handler
│   │       ├── controllers/
│   │       │   └── dashboard_controller.ex
│   │       ├── endpoint.ex         # Phoenix endpoint
│   │       ├── gettext.ex          # Internationalization
│   │       ├── router.ex           # Route definitions
│   │       └── user_socket.ex      # Socket configuration
│   └── aria_neon_frontlines.ex
├── priv/
│   └── static/
│       ├── dashboard.html          # Simulation dashboard
│       ├── js/
│       │   └── simulation.js       # Operative monitoring
│       └── block_config.json       # City block definition
├── test/
│   └── simulation_test.html        # Process messaging test client
├── decisions/
│   └── task_with_context.md        # Implementation plan
└── README.md
```

## 🎮 Usage Guide

### Basic Workflow

1. **Configure Simulation**
   - Set operative count and archetype ratios
   - Define city block parameters and supply chains

2. **Start Operatives**
   - Spawn cybernetically-enhanced agents with different archetypes
   - Initialize block state and logistics networks

3. **Monitor Activities**
   - Watch real-time operative actions via dashboard
   - Track block transfers and tactical decisions

4. **Analyze Performance**
   - Review TimescaleDB logs for behavior patterns
   - Generate reports on operative effectiveness

### Advanced Features

- **Concurrent Execution**: 50+ operatives running simultaneously
- **Block Transfer**: Zero-IOPS movement within the neon city block
- **Real-time Broadcasting**: Process-based synchronization of operative states
- **Performance Metrics**: Comprehensive simulation monitoring

## 🔍 Troubleshooting

### Common Issues

**Process Registry Not Found**
- Ensure operative processes are properly registered
- Check Registry configuration in application startup
- Verify process naming conventions

**Simulation Not Starting**
- Confirm TimescaleDB is running and configured
- Check operative archetype configurations
- Verify block state initialization

**Dashboard Not Loading**
- Ensure Phoenix server is running on port 4000
- Check browser console for WebSocket errors
- Verify CORS headers are properly configured

### Debug Tools

- **Browser Console**: Check for JavaScript errors
- **Phoenix Logs**: Monitor server-side simulation activity
- **Process Monitor**: Track operative process lifecycle
- **TimescaleDB Queries**: Inspect event logging

## 📈 Performance

- **50+ Concurrent Operatives**: Multi-agent simulation with cybernetic enhancements
- **Real-time Block Transfers**: Zero IOPS for local destination movement
- **TimescaleDB Hypertables**: Optimized event storage and querying
- **Process Messaging**: Efficient state synchronization across operatives

## 🤝 Contributing

### Development Setup

1. **Clone and setup:**
   ```bash
   git clone <repository>
   cd aria-character-core
   mix deps.get
   ```

2. **Start development server:**
   ```bash
   cd apps/aria_neon_frontlines
   mix phx.server
   ```

3. **Run tests:**
   ```bash
   mix test apps/aria_neon_frontlines/test/
   ```

### Code Organization

- **Backend**: Phoenix Channels for dashboard communication
- **Simulation**: Process-based multi-agent execution engine
- **State Management**: AriaState for block and operative tracking
- **Domain Logic**: AriaHybridPlanner for cyberpunk logistics warfare
- **Storage**: TimescaleDB for event logging and analytics

## 📄 License

This project is part of the aria-character-core umbrella application.

## 🙏 Acknowledgments

- **Phoenix Framework**: Real-time web dashboard backend
- **TimescaleDB**: Time-series database for event storage
- **Aria Ecosystem**: State management and hybrid planning integrations

---

**Ready to deploy cybernetically-enhanced operatives?** Start the Phoenix server and open http://localhost:4000!
