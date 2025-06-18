# ADR-096: PERT Chart Solver with KHR Durative Actions

**Status:** Proposed  
**Date:** 2025-06-18  
**Priority:** MEDIUM

## Context

Following the successful resolution of KHR goal processing in ADR-095, we now have a working foundation for KHR durative actions. This creates an opportunity to implement practical project management tools using temporal planning.

### Problem Statement

Current project management tools lack integration with AI planning systems. Teams need:

- **Critical path analysis** with automatic dependency resolution
- **Resource scheduling** with conflict detection and optimization
- **Temporal planning** that can adapt to changing requirements
- **MCP integration** for AI assistant access to project planning capabilities

### Opportunity

KHR_interactivity specification provides three durative actions perfect for PERT chart execution:

1. **`variable/interpolate`** - Task progress tracking (0% → 100% over duration)
2. **`pointer/interpolate`** - Resource allocation adjustment over time
3. **`flow/setDelay`** - Dependency scheduling and milestone triggers

### Technical Foundation

- ✅ **HTN Planning**: Proven durative action support in hybrid planner
- ✅ **KHR Integration**: Goal processing pipeline working (ADR-095)
- ✅ **MCP Framework**: Ready for tool integration
- ✅ **Temporal Constraints**: Timeline module supports duration and scheduling

## Decision

Implement a PERT chart solver using KHR durative actions to provide AI-accessible project management capabilities through MCP tools.

### Core Approach

**PERT Chart as HTN Domain**: Model project tasks as HTN methods with durative actions for execution, dependency management, and resource scheduling.

**KHR Durative Mapping**:
- **Task Execution**: `variable/interpolate` for progress tracking
- **Resource Management**: `pointer/interpolate` for allocation adjustments  
- **Dependency Scheduling**: `flow/setDelay` for milestone triggers

**MCP Tool Integration**: Expose project planning capabilities as MCP tools for AI assistant access.

## Implementation Plan

### Phase 1: PERT Chart Data Structures (PRIORITY: HIGH)
- [ ] Define project task representation with dependencies
- [ ] Implement critical path calculation algorithm
- [ ] Add earliest start time (EST) and latest start time (LST) computation
- [ ] Create slack analysis for non-critical tasks
- [ ] Build project network graph representation

### Phase 2: KHR Durative Action Mapping (PRIORITY: HIGH)
- [ ] Map PERT tasks to KHR `variable/interpolate` for progress tracking
- [ ] Use `pointer/interpolate` for dynamic resource allocation
- [ ] Implement `flow/setDelay` for dependency triggers and milestones
- [ ] Create HTN domain for project execution with durative actions
- [ ] Add temporal constraint validation

### Phase 3: HTN Planning Integration (PRIORITY: MEDIUM)
- [ ] Generate HTN plans from PERT chart specifications
- [ ] Implement task decomposition with proper dependency ordering
- [ ] Add resource conflict detection and resolution
- [ ] Create backtracking for schedule optimization
- [ ] Validate plan execution with durative timing

### Phase 4: MCP Tool Development (PRIORITY: MEDIUM)
- [ ] Create `plan_project_pert` MCP tool for project scheduling
- [ ] Add `analyze_critical_path` tool for bottleneck identification
- [ ] Implement `optimize_resources` tool for allocation planning
- [ ] Create `schedule_milestones` tool for deadline management
- [ ] Add project status monitoring and progress reporting

### Phase 5: Advanced Features (PRIORITY: LOW)
- [ ] Monte Carlo simulation for duration uncertainty
- [ ] Resource leveling and smoothing algorithms
- [ ] Multi-project scheduling with shared resources
- [ ] Integration with external project management systems
- [ ] Real-time schedule updates and re-planning

## Technical Specifications

### PERT Chart Representation

```elixir
%Project{
  name: "website_redesign",
  tasks: %{
    "design" => %Task{
      id: "design",
      duration: 5.0,
      dependencies: [],
      resources: ["designer", "ux_researcher"],
      earliest_start: 0.0,
      latest_start: 0.0,
      slack: 0.0
    },
    "development" => %Task{
      id: "development", 
      duration: 8.0,
      dependencies: ["design"],
      resources: ["frontend_dev", "backend_dev"],
      earliest_start: 5.0,
      latest_start: 5.0,
      slack: 0.0
    },
    "testing" => %Task{
      id: "testing",
      duration: 3.0,
      dependencies: ["development"],
      resources: ["qa_engineer"],
      earliest_start: 13.0,
      latest_start: 13.0,
      slack: 0.0
    }
  },
  critical_path: ["design", "development", "testing"],
  total_duration: 16.0
}
```

### KHR Durative Action Plan

```elixir
{:ok, %{
  nodes: %{
    "root" => %{
      task: {"execute_project", ["website_redesign"]},
      is_primitive: false,
      children: ["design_task", "development_task", "testing_task", "resource_monitor"]
    },
    
    "design_task" => %{
      task: {"khr_variable_interpolate", [1, "design_progress", 1.0, 5.0]},
      is_primitive: true,
      start_time: 0.0,
      duration: 5.0,
      effects: [
        {"project", "design_complete", true},
        {"milestone", "design_approved", true}
      ]
    },
    
    "development_task" => %{
      task: {"khr_variable_interpolate", [2, "dev_progress", 1.0, 8.0]},
      is_primitive: true,
      start_time: 5.0,
      duration: 8.0,
      preconditions: [{"project", "design_complete", true}],
      effects: [
        {"project", "development_complete", true},
        {"milestone", "code_ready", true}
      ]
    },
    
    "testing_task" => %{
      task: {"khr_variable_interpolate", [3, "test_progress", 1.0, 3.0]},
      is_primitive: true,
      start_time: 13.0,
      duration: 3.0,
      preconditions: [{"project", "development_complete", true}],
      effects: [
        {"project", "testing_complete", true},
        {"milestone", "launch_ready", true}
      ]
    },
    
    "resource_monitor" => %{
      task: {"khr_pointer_interpolate", [4, "/project/resource_utilization", 0.85, 16.0]},
      is_primitive: true,
      start_time: 0.0,
      duration: 16.0,
      effects: [
        {"resources", "utilization_optimized", true}
      ]
    }
  },
  
  critical_path_analysis: %{
    path: ["design_task", "development_task", "testing_task"],
    total_duration: 16.0,
    bottlenecks: ["development_task"]
  }
}}
```

### MCP Tool Interface

```elixir
# MCP Tool: plan_project_pert
def plan_project_pert(project_spec) do
  # Input: Project specification with tasks and dependencies
  # Output: Executable HTN plan with KHR durative actions
  
  project_spec
  |> parse_project_tasks()
  |> calculate_critical_path()
  |> generate_khr_plan()
  |> validate_temporal_constraints()
end

# Example usage from MCP client:
{
  "tool": "plan_project_pert",
  "arguments": {
    "project": {
      "name": "website_redesign",
      "tasks": [
        {"id": "design", "duration": 5, "dependencies": []},
        {"id": "development", "duration": 8, "dependencies": ["design"]},
        {"id": "testing", "duration": 3, "dependencies": ["development"]}
      ],
      "resources": {
        "designer": 1,
        "developer": 2,
        "qa_engineer": 1
      }
    }
  }
}
```

## Success Criteria

### Functional Requirements
1. **Critical Path Calculation**: Correctly identifies longest path through project network
2. **Durative Execution**: Tasks execute with proper timing, dependencies, and resource allocation
3. **Schedule Optimization**: Finds optimal start times minimizing project duration
4. **Resource Management**: Handles resource conflicts and allocation optimization
5. **MCP Integration**: AI assistants can request and execute project schedules

### Performance Requirements
- **Planning Time**: Generate PERT plans for 50+ task projects in <2 seconds
- **Execution Monitoring**: Real-time progress tracking with <100ms update latency
- **Resource Optimization**: Resolve resource conflicts for 10+ resources in <1 second

### Quality Requirements
- **Schedule Accuracy**: Critical path calculations match industry PERT tools
- **Temporal Consistency**: All durative actions respect dependency constraints
- **Error Handling**: Clear feedback for invalid project specifications
- **Documentation**: Complete examples for common project management scenarios

## Consequences

### Positive
- **AI-Accessible Planning**: First AI assistant integration with professional project management
- **Temporal Intelligence**: Durative actions provide realistic project execution modeling
- **Resource Optimization**: Automatic conflict detection and resolution
- **Industry Standard**: PERT chart compliance ensures compatibility with existing tools
- **Extensible Framework**: Foundation for advanced scheduling algorithms

### Risks
- **Complexity**: PERT algorithms combined with HTN planning may be difficult to debug
- **Performance**: Large projects might exceed reasonable planning time limits
- **Resource Modeling**: Simplified resource representation may not capture real constraints
- **Integration Challenges**: MCP tool interface design affects usability

### Mitigation Strategies
- **Incremental Development**: Start with simple 3-5 task projects, expand gradually
- **Performance Monitoring**: Add timing instrumentation and optimization points
- **Resource Abstraction**: Design extensible resource model for future enhancement
- **User Testing**: Validate MCP tool interface with real project management scenarios

## Related ADRs

- **ADR-095**: Fix KHR Interactivity Planner Goal Processing Pipeline (foundation)
- **ADR-094**: Fix KHR Interactivity Planner Test Architecture (architectural base)
- **ADR-092**: AST to GLTF KHR_interactivity Translation (KHR domain implementation)
- **ADR-091**: Hybrid Planner Dependency Encapsulation (HTN planning system)
- **ADR-090**: Expose Aria via MCP Hermes (MCP integration framework)

## Implementation Notes

### Development Approach
1. **Start Simple**: Begin with 3-task linear projects (design → development → testing)
2. **Add Complexity Gradually**: Introduce parallel tasks, resource constraints, optimization
3. **Validate Each Phase**: Ensure PERT calculations match industry tools before proceeding
4. **MCP Integration Last**: Focus on core algorithms before tool interface design

### Testing Strategy
- **Unit Tests**: PERT algorithm correctness with known project examples
- **Integration Tests**: HTN plan generation and execution with durative actions
- **Performance Tests**: Large project handling and optimization timing
- **MCP Tool Tests**: End-to-end client interaction scenarios

### Documentation Requirements
- **Algorithm Documentation**: PERT calculation methods and critical path analysis
- **KHR Mapping Guide**: How project tasks map to durative actions
- **MCP Tool Reference**: Complete API documentation with examples
- **Project Management Examples**: Common scenarios and best practices

This ADR establishes the foundation for AI-accessible project management through temporal planning with KHR durative actions.
