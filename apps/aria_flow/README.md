# AriaFlow

AriaFlow provides Flow-based parallel processing with Membrane-style elements for the Aria Character Core system.

## Overview

AriaFlow implements Membrane's concepts like pads, filters, buffers, and demand-driven processing using Elixir's Flow library for superior parallel efficiency. This provides a clean separation of concerns between queue management (AriaQueue) and flow processing (AriaFlow).

## Key Features

- **Membrane-style Elements**: Input/output pads with flow control
- **Demand-driven Processing**: Backflow control and backpressure handling
- **Hierarchical Convergence**: GPU-style parallel reduction patterns
- **Flow-based Architecture**: Built on Elixir's Flow for optimal parallel processing
- **Centralized Registry**: Pipeline and element management

## Architecture

```
AriaFlow
├── Backflow - Main processing coordinator with demand control
├── Element - Membrane-style element implementation
└── Application - Supervision tree and registry management
```

## Usage

### Creating Pipelines

```elixir
# Create a processing pipeline
{:ok, _} = AriaFlow.create_pipeline("my_pipeline", stages: 8)

# Process data with backflow control
result = AriaFlow.process_with_backflow("my_pipeline", data, 
  source_fn: &my_source/1,
  filter_fn: &my_filter/1,
  sink_fn: &my_sink/1
)
```

### Creating Elements

```elixir
# Create Membrane-style elements
{:ok, _} = AriaFlow.create_element("processor", :filter, 
  input_pads: [%AriaFlow.ElementPad{name: :input, type: :input}],
  output_pads: [%AriaFlow.ElementPad{name: :output, type: :output}]
)

# Link elements together
AriaFlow.link_elements("source", :output, "processor", :input)
```

### Hierarchical Convergence

```elixir
# GPU-style hierarchical convergence processing
result = AriaFlow.process_with_convergence("convergence_pipeline", data,
  source_fn: &convergence_source/1,
  filter_fn: &convergence_filter/1,
  sink_fn: &convergence_sink/1,
  convergence_fn: &convergence_combine/2
)
```

## Design Principles

AriaFlow follows these architectural decisions from the Aria ADRs:

- **ADR-052**: Replace Membrane with Flow for parallel processing
- **ADR-041**: Temporal solver tech stack requirements
- **ADR-032**: Membrane workflow migration

The system emulates all Membrane design patterns (pads, filters, buffers, demand, linking, etc.) while providing superior parallel efficiency through Flow.

## Dependencies

- `flow` - Elixir's Flow library for parallel processing
- `jason` - JSON encoding/decoding
- Built-in `GenServer` and `Registry` for process management

## Integration

AriaFlow is designed to be used by:

- **AriaEngine**: Game logic and temporal planning
- **AriaQueue**: Job processing and queue management
- **AriaTimestrike**: Real-time game processing

All Flow operations should go through AriaFlow to prevent scheduling oversubscription and provide system-wide coordination.

