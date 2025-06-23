# AriaScheduler

Activity scheduling and domain conversion system providing resource management and temporal coordination.

## Overview

AriaScheduler implements a comprehensive scheduling system that coordinates activities, manages resources, and converts between different domain representations. It serves as the bridge between high-level planning and low-level execution.

## Core Components

### Scheduler Core
- **Core**: Central scheduling coordination and activity management
- **Domain Converter**: Transforms between different domain representations
- **Entity Manager**: Manages entities and their relationships
- **Plan Converter**: Converts plans between formats
- **Resource Manager**: Handles resource allocation and constraints
- **State Manager**: Manages scheduling state and transitions

### Domain Conversion
- **Activity Actions**: Converts activities to executable actions
- **Durative Actions**: Handles time-based action specifications
- **Goal Methods**: Transforms goals into method hierarchies
- **HTN Methods**: Hierarchical task network method conversion
- **KHR Primitives**: glTF KHR interactivity primitive handling

## Dependencies

- **aria_engine_core**: Core state management and domain utilities
- **aria_hybrid_planner**: Planning coordination and strategy management
- **aria_temporal_planner**: Temporal reasoning and constraint solving
- **jason**: JSON encoding/decoding
- **libgraph**: Graph data structures
- **telemetry**: Event tracking and monitoring
- **timex**: Time and duration handling

## Usage

```elixir
# Create scheduler instance
scheduler = AriaScheduler.Core.new()

# Schedule activities
result = AriaScheduler.Core.schedule(scheduler, activities, constraints)

# Convert domain representations
converted = AriaScheduler.DomainConverter.convert(domain, target_format)
```

## Architecture

The scheduler follows a layered architecture:

1. **Coordination Layer**: Core scheduling and resource management
2. **Conversion Layer**: Domain transformation and format conversion
3. **Management Layer**: Entity, resource, and state management
4. **Integration Layer**: Interfaces with planning and temporal systems
