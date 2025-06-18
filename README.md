# Aria Character Core

A high-performance NPC town simulation game featuring intelligent characters powered by hybrid planning, glTF visual scripting, and GPU-inspired parallel processing.

## Overview

Aria Character Core is a sophisticated town simulation where NPCs (Non-Player Characters) exhibit intelligent behavior through:

- **Hybrid Planning**: HTN (Hierarchical Task Network) + STN (Simple Temporal Network) planning for complex NPC decision-making
- **glTF Visual Scripting**: KHR_interactivity extension provides a visual node-based programming language for NPC behaviors
- **High-Performance Processing**: FlowAdapter enables GPU-style convergence patterns for efficient multi-NPC coordination
- **RDF Knowledge Base**: Semantic knowledge representation for rich NPC understanding and relationships
- **Content Distribution**: Casync-based efficient distribution of game assets, behaviors, and updates
- **Secure Authentication**: Macaroon-based tokens with delegation and attenuation for multiplayer access control

## Core Technology Stack

### AriaEngine - Intelligent Planning System
- **Hybrid Planner**: Combines HTN planning for high-level goals with STN temporal constraints
- **Multi-Strategy Architecture**: Pluggable planning strategies (HTN, STN, lazy execution, domain-specific)
- **Real-Time Decision Making**: NPCs can adapt plans dynamically based on changing conditions
- **Temporal Reasoning**: Handle time-sensitive actions, schedules, and resource conflicts

### FlowAdapter - High-Performance Parallel Processing
- **GPU-Style Convergence**: Applies convergence patterns for efficient CPU-based parallel processing
- **Scalable Beyond 2 CPUs**: Push/pull flow control that efficiently utilizes multi-core systems
- **STN Parallel Operations**: Process temporal constraints across multiple NPCs simultaneously
- **Demand-Driven Processing**: Adaptive workload distribution based on system capacity

### glTF KHR_interactivity - Visual Scripting Language
- **Node-Based Programming**: Visual scripting system built on the glTF KHR_interactivity standard
- **Comprehensive Node Library**: Math, animation, state management, events, and flow control nodes
- **Real-Time Interpretation**: Execute visual scripts as NPCs make decisions and react to events
- **Designer-Friendly**: Non-programmers can create complex NPC behaviors through visual scripting

### AriaTown - Knowledge & NPC Management
- **RDF Knowledge Base**: Semantic representation of town state, relationships, and facts
- **SPARQL Queries**: Powerful knowledge retrieval for informed NPC decision-making
- **Time Management**: Coordinated temporal progression across all town systems
- **NPC Lifecycle**: Birth, aging, relationships, careers, and emergent social dynamics

### AriaStorage - Efficient Content Distribution
- **Casync Integration**: Content-addressable storage with chunk-based deduplication
- **Asset Streaming**: Efficiently distribute 3D models, textures, animations, and behavior scripts
- **Version Control**: Delta updates for game content and NPC behavior modifications
- **Distributed Architecture**: Support for CDN-based content delivery

### AriaAuth - Secure Access Control
- **Macaroon Tokens**: Advanced authentication with built-in attenuation and delegation
- **Permission Management**: Fine-grained control over player and NPC capabilities
- **Multiplayer Security**: Secure token sharing for collaborative town experiences
- **API Access Control**: Restrict external tools and modding interfaces appropriately

## Architecture

```
Aria Character Core
├── AriaEngine (Planning & Decision Making)
│   ├── Hybrid Planner (HTN + STN)
│   ├── FlowAdapter (Parallel Processing)
│   ├── Domain Registry (Planning Domains)
│   └── KHR_interactivity (Visual Scripting)
├── AriaTown (Knowledge & NPCs)
│   ├── RDF Knowledge Base
│   ├── NPC Manager
│   ├── Time Manager
│   └── Persistence Manager
├── AriaStorage (Content & Assets)
│   ├── Casync Decoder
│   ├── Chunk Store
│   └── File Management
├── AriaAuth (Security & Access)
│   ├── Macaroon Authentication
│   ├── Session Management
│   └── Permission Control
├── AriaSecurity (Encryption & Secrets)
└── AriaMonitor (Telemetry & Performance)
```

## Key Features

### Intelligent NPC Behavior
- **Goal-Oriented Planning**: NPCs pursue complex, multi-step objectives (career advancement, relationship building, resource acquisition)
- **Temporal Coordination**: NPCs schedule activities, meet deadlines, and coordinate with other characters
- **Adaptive Responses**: React intelligently to player actions, environmental changes, and social dynamics
- **Visual Script Execution**: Behaviors defined through intuitive node-based programming

### Scalable Town Simulation
- **Multi-Core Performance**: FlowAdapter enables efficient simulation of large populations
- **Real-Time Processing**: Hundreds of NPCs can plan and act simultaneously without performance degradation
- **Convergence Optimization**: GPU-inspired algorithms optimize decision-making across character populations
- **Demand-Driven Architecture**: System resources scale automatically with simulation complexity

### Rich Knowledge Representation
- **Semantic Understanding**: NPCs have deep knowledge about their world, relationships, and capabilities
- **Dynamic Learning**: Characters can acquire new knowledge and update their understanding over time
- **Social Networks**: Complex relationship modeling with emotional states, reputation, and influence
- **Economic Simulation**: Supply/demand dynamics, currency, trade, and resource management

### Content Creation & Distribution
- **Visual Scripting Tools**: Create NPC behaviors without programming knowledge
- **Efficient Asset Pipeline**: Stream 3D models, animations, and scripts using content-addressable storage
- **Modding Support**: Community-created content integrates seamlessly with core game systems
- **Live Updates**: Push new behaviors and content without interrupting active simulations

## Game Examples

### NPC Daily Life Simulation
```
• Blacksmith NPC wakes up → checks orders → plans crafting schedule
• Uses temporal planning to balance work, meals, and social time
• Adapts to player requests, resource availability, and town events
• Behavior defined through visual scripts: decision trees, state machines, event handlers
```

### Multi-NPC Coordination
```
• Town festival requires coordination between 20+ NPCs
• FlowAdapter processes all planning decisions in parallel
• Temporal constraints ensure proper event sequencing
• Social dynamics influence participation and role assignments
```

### Player-NPC Interactions
```
• Player requests custom item from craftsman NPC
• NPC plans multi-day production schedule considering resources
• Updates delivery timeline based on material availability
• Macaroon tokens control access to different NPC services
```

## Development

### Setup
```bash
mix deps.get
mix compile
```

### Running the Town Simulation
```bash
iex -S mix
AriaCharacterCore.start_town_simulation()
```

### Testing
```bash
mix test
```

### Performance Testing
```bash
# Test multi-NPC parallel planning
mix test --only integration:flow_adapter

# Test temporal constraint solving
mix test --only integration:stn_performance
```

## Configuration

Town simulation parameters can be configured in `config/`:

```elixir
# config/dev.exs
config :aria_town,
  population_size: 50,
  time_acceleration: 1.0,
  knowledge_base_size: :medium

config :aria_engine,
  max_planning_depth: 8,
  temporal_horizon: 24,  # hours
  parallel_stages: 4
```

## Contributing

This project focuses on creating believable, intelligent NPCs through advanced AI planning and high-performance simulation:

- Use descriptive commit messages focused on NPC behavior improvements
- Test new planning strategies with multiple NPCs to ensure scalability
- Visual scripts should be tested for both correctness and performance
- Follow Elixir/OTP patterns for concurrent, fault-tolerant systems

## License

Copyright (c) 2025-present K. S. Ernest (iFire) Lee  
SPDX-License-Identifier: MIT
