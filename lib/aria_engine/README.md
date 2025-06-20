# AriaEngine

**⚠️ ALPHA • Research Code • Not Production Ready ⚠️**

> **This module is part of the Aria Character Core research project. Most features are experimental, incomplete, or non-functional. See the root [README.md](../../README.md) for current project status and limitations.**

AriaEngine is the core planning and execution engine for the Aria Character Core system. It provides hierarchical task network (HTN) planning, temporal planning, and workflow execution capabilities.

## Status

| Feature                | Status      | Notes                                      |
|------------------------|------------|--------------------------------------------|
| HTN Planning           | Partial    | Basic decomposition implemented, incomplete |
| Temporal Planning      | Partial    | STN/Timeline code present, performance issues, timeouts |
| Hybrid Planning        | Experimental | Multi-strategy coordination is incomplete  |
| Workflow Execution     | Experimental | Flow/backflow APIs exist, not fully working|
| State Management       | Partial    | Fact-based state present, not robust       |
| MCP Integration        | Partial    | Scheduler interface works, response handling broken |
| Test Coverage          | Partial    | Many tests failing or skipped              |

**Warning:** This module is not suitable for production use. Many features are incomplete or non-functional.

## Overview

AriaEngine combines multiple planning paradigms to enable intelligent character behavior:

- **HTN Planning**: Hierarchical task decomposition using methods and actions
- **Temporal Planning**: Timeline-based planning with temporal constraints
- **Hybrid Planning**: Integration of multiple planning strategies
- **Workflow Execution**: Flow-based processing with backflow optimization
- **State Management**: Fact-based state representation with StateV2

## Core Components

### Planning System

- `AriaEngine.Planner` - Main planning interface
- `AriaEngine.HybridPlanner` - Multi-strategy planning coordinator
- `AriaEngine.Domain` - Domain definition and method management
- `AriaEngine.Plan` - Plan representation and execution

### Temporal Planning

- `AriaEngine.Timeline` - Timeline-based temporal planning
- `AriaEngine.TemporalPlanner` - STN-based constraint solving
- `AriaEngine.TimelineGraph` - Timeline visualization and analysis

### Workflow System

- `AriaEngine.FlowWorkflow` - Flow-based data processing
- `AriaEngine.Scheduler` - Activity scheduling and resource management
- `AriaEngine.FlowAdapter` - Integration with Flow library

### State Management

- `AriaEngine.StateV2` - Fact-based state representation
- `AriaEngine.Validation` - State validation and consistency checking

## Usage

> **Note:** The following examples assume features are implemented. Many APIs are incomplete or non-functional.

### Basic Planning

```elixir
# Define a domain with methods and actions
domain = %AriaEngine.Domain{
  methods: [
    {"travel", ["go_by_car", "go_by_train"]},
    {"go_by_car", ["get_car", "drive", "park"]}
  ],
  actions: [
    {"get_car", [], [{"has_car", true}]},
    {"drive", [{"has_car", true}], [{"at_destination", true}]}
  ]
}

# Create initial state
state = AriaEngine.StateV2.new()
|> AriaEngine.StateV2.add_fact("at", "home")

# Plan to achieve goal
{:ok, plan} = AriaEngine.Planner.plan(domain, state, [{"at", "work"}])
```

### Workflow Processing

```elixir
# Process actions with backflow optimization
activities = [
  %{id: "task1", duration: 60, dependencies: []},
  %{id: "task2", duration: 30, dependencies: ["task1"]}
]

{:ok, result} = AriaEngine.Scheduler.schedule_activities("Project", activities)
```

### Timeline Planning

```elixir
# Create timeline with temporal constraints
# NOTE: The Timeline API uses `Timeline`, not `AriaEngine.Timeline`, and does not have `add_event`.
timeline = Timeline.new()
|> Timeline.add_time_point("start")
|> Timeline.add_time_point("end")
|> Timeline.add_constraint("start", "end", {50, 100})
```

## Architecture

AriaEngine follows a modular architecture with clear separation of concerns:

```
AriaEngine
├── Planning (HTN, Temporal, Hybrid)
├── Execution (Plans, Workflows, Timelines)
├── State (Facts, Validation, Persistence)
└── Integration (Flow, Scheduler, Adapters)
```

## Development

### Running Tests

```bash
mix test test/aria_engine/ --timeout 120
```

### Key Design Principles

- **Fact-based state**: All state is represented as subject-predicate-object facts
- **Hierarchical decomposition**: Complex tasks broken into simpler subtasks
- **Temporal awareness**: Planning considers time constraints and durations
- **Flow integration**: Seamless integration with Flow-based processing
- **Extensible domains**: Easy to define new planning domains and methods

## Related Components

- **AriaAuth**: Authentication and session management
- **AriaStorage**: Persistent storage and archiving
- **AriaSecurity**: Security and secrets management
- **AriaTown**: Game world simulation and NPC behavior

---

**Disclaimer:** Active research code. Expect incomplete features and non-functional systems. See the root [README.md](../../README.md) for current project status.
