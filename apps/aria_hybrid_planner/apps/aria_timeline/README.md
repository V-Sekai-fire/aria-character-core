# AriaTimeline

Timeline management and temporal reasoning for AriaEngine.

## Overview

AriaTimeline provides comprehensive timeline functionality including:

- **Timeline Management** - Create and manage timelines with interval-based storage
- **Temporal Reasoning** - Allen's interval algebra and temporal constraint solving
- **Agent/Entity System** - Semantic distinction between autonomous agents and passive entities
- **STN Integration** - Simple Temporal Network solving with Path Consistency (PC-2)
- **Bridge Management** - Temporal relations classification and constraint generation
- **LOD Management** - Level of Detail scaling for performance optimization

## Features

### Core Timeline Operations

- Interval creation and management with DateTime support
- Timeline composition, intersection, and union operations
- Temporal constraint solving using STN algorithms
- Bridge-based timeline segmentation

### Agent/Entity Management

- Clear semantic distinction between agents and entities
- Capability management and state transitions
- Property management and ownership tracking
- Dynamic agent/entity role transitions

### Temporal Relations

- Complete Allen's interval algebra implementation
- Language-neutral relation codes for internationalization
- Automatic temporal constraint generation
- Contract violation prevention for STN solving

### Performance Features

- Level of Detail (LOD) management for scalability
- Parallel processing support for large timelines
- Automatic rescaling and unit conversion
- Constant work pattern optimization

## Usage

```elixir
# Create a new timeline
timeline = Timeline.new()

# Create intervals with DateTime
start_time = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
end_time = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
interval = Timeline.Interval.new(start_time, end_time)

# Add interval to timeline
timeline = Timeline.add_interval(timeline, interval)

# Solve temporal constraints
timeline = Timeline.solve(timeline)

# Create agents and entities
agent = Timeline.AgentEntity.create_agent("aria", "Aria VTuber", %{personality: "helpful"})
entity = Timeline.AgentEntity.create_entity("room", "Conference Room", %{capacity: 10})
```

## Dependencies

- `aria_engine_core` - Core engine functionality
- `aria_minizinc_stn` - STN solving with MiniZinc
- `jason` - JSON serialization
- `libgraph` - Graph operations

## Architecture

AriaTimeline is designed as a modular system with clear separation of concerns:

- **Timeline** - Main interface for timeline operations
- **TimelineGraph** - Entity timeline graph with LOD management
- **Timeline.Interval** - Temporal interval representation
- **Timeline.Bridge** - Temporal relations and constraint generation
- **Timeline.AgentEntity** - Agent/entity management system
- **Timeline.Internal.STN** - Simple Temporal Network implementation

## License

MIT License - see LICENSE.md for details.
