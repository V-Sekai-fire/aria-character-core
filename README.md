# Aria Character Core

**⚠️ ALPHA • v0.2.0 • Research Code • Not Production Ready ⚠️**

AI planning research project exploring intelligent NPC behavior through hybrid HTN+STN planning systems.

NOTE: We use elixir 18.

## Status Overview

| Component            | Status       | Tests       | Notes                                                                           |
| -------------------- | ------------ | ----------- | ------------------------------------------------------------------------------- |
| **MCP Integration**  | ✅ Done      | 7/7 passing | Stdio scheduler interface fully implemented and stable; duration now in seconds |
| **Core Planning**    | ✅ Done      | All passing | HTN/STN algorithms fully implemented and stable                                 |
| **Storage System**   | ⏸️ Postponed | 0/20+       | Chunk distribution work deferred; not currently maintained                      |
| **Temporal Solver**  | ✅ Done      | All passing | STN constraints and temporal scheduling fully implemented and stable            |
| **NPC Management**   | ⏸️ Paused    | Mixed       | Development paused; basic structure exists                                      |
| **Batch Processing** | ⏸️ Paused    | N/A         | Batch helpers and core allocation logic removed; future work paused             |
| **KHR System**       | 🧪 R&D       | N/A         | Experimental research and development ongoing                                   |

**Current Reality:** 333 tests total, 326 passing, 7 failing (primarily MCP integration), 1 skipped.

## Quick Start

```bash
# Prerequisites: Elixir 1.16+, Erlang/OTP 26+
mix deps.get && mix compile
mix test  # Runs only working tests

# Try the scheduler samples
mix schedule.samples  # Default 6 residents
TOWN_SCALE=1 mix schedule.samples    # Small town (1 resident)
TOWN_SCALE=50 mix schedule.samples   # Medium town (50 residents)
TOWN_SCALE=1000 mix schedule.samples # Large city (1000 residents)
```

**Key Limitation:** Most planning and storage systems non-functional.

## What This Is/Isn't

| ✅ This IS                                        | ❌ This is NOT       |
| ------------------------------------------------- | -------------------- |
| Research codebase exploring AI planning           | Playable game        |
| Academic investigation of HTN+STN hybrid planning | Production software  |
| Experimental NPC behavior systems                 | Stable API/framework |
| Development environment for planning algorithms   | Ready for end users  |

## Research Focus

**Core Investigation Areas:**

- **Hybrid Planning:** HTN goal decomposition + STN temporal constraints
- **Temporal Scheduling:** Scheduling with resource conflict detection
- **Parallel Processing:** Flow-based coordination for multi-NPC systems
- **Knowledge Representation:** RDF/SPARQL for NPC decision-making

## MCP Integration

The project includes a working Model Context Protocol (MCP) server that exposes temporal scheduling and pipeline management capabilities.

### Available Tools

| Tool Name                     | Description                                                                              |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| schedule_activities           | Schedule activities using Membrane pipeline architecture with multiple strategy options  |
| validate_scheduling_solutions | Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver |
| configure_pipeline_layout     | Configure and create a new Membrane pipeline with specified topology and elements        |
| setup_element_config          | Validate and setup configuration for pipeline elements                                   |
| start_planning_pipeline       | Start a new planning pipeline with predefined topology                                   |
| stop_planning_pipeline        | Stop an active planning pipeline                                                         |
| get_pipeline_status           | Get detailed status information for a specific pipeline                                  |
| get_pipeline_metrics          | Get overall metrics for the pipeline manager                                             |
| list_active_pipelines         | List all currently active pipelines                                                      |
| send_pipeline_request         | Send a request to a specific active pipeline                                             |

## Scheduler Samples

The project includes comprehensive scheduler samples that demonstrate temporal planning capabilities with scalable community simulations.

### Sample Types

1. **Simple Sequential Activities** - Basic dependency handling and timing calculations
2. **Resource-Constrained Scheduling** - Resource allocation and capacity management  
3. **Complex Dependencies** - Parallel execution and critical path analysis
4. **Entity and Capability Management** - Capability-based task assignment
5. **Simulation Mode** - Predictive scheduling without execution
6. **Smallville Community Simulation** - Emergent autonomous behavior with scalable populations

### Scaling System

The scheduler uses an intelligent scaling system that adjusts resources and opportunities based on town size:

- **Small towns (≤10 residents)**: 1-2 resources per resident, 3-4 opportunities per resident
- **Medium towns (≤100 residents)**: 0.5-1 resource per resident, 2-3 opportunities per resident  
- **Large cities (>100 residents)**: 0.2-0.5 resources per resident, 1-2 opportunities per resident

### Performance Characteristics

| Scale | Residents | Opportunities | Resources | Planning Time |
|-------|-----------|---------------|-----------|---------------|
| Small | 1         | 4             | 2         | ~250ms        |
| Medium| 50        | 125           | 35        | ~300ms        |
| Large | 1000      | 1500          | 300       | ~680ms        |

### Sample Town Resident

```elixir
%Entity{
  id: "isabella_rodriguez",
  type: :resident,
  capabilities: [:hospitality, :event_planning, :social_coordination, :community_networking],
  availability: nil,
  metadata: %{
    occupation: "Cafe Owner", 
    personality: "Outgoing, community-focused",
    interests: [:local_politics, :community_events, :meeting_people],
    social_magnetism: :high
  }
}
```

Isabella demonstrates the system's capability-driven task assignment and emergent behavior patterns. Her hospitality capabilities naturally align her with cafe operations, while her high social magnetism creates opportunities for community interactions. The scheduler automatically matches her with activities like `operate_cafe` (essential work) and `impromptu_cafe_discussion` (social coordination), showing how personality traits and capabilities drive realistic daily schedules.

## Development Priorities

1. **Fix Storage System:** Resolve chunk-based distribution failures

## Contributing

Focus areas for experimental research contributions:

- **Algorithm Implementation:** Complete HTN/STN planning systems
- **Test Recovery:** Fix disabled tests to restore functionality
- **Performance Research:** Solve timeout and scaling issues
- **Integration:** Connect partial systems into working pipelines

## Dependencies

Exploring integration of: AI Planning (HTN/STN) • Temporal Reasoning • Parallel Processing (Flow) • Knowledge Representation (RDF/SPARQL) • Model Context Protocol (MCP) • Content Distribution (Casync-inspired)

---

**License:** MIT • **Copyright:** 2025-present K. S. Ernest (iFire) Lee  
**Disclaimer:** Active research code. Expect incomplete features and non-functional systems.
