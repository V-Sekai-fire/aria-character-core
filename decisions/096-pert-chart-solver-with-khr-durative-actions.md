# ADR-096: PERT Chart Execution with Hybrid Planner and KHR Durative Actions

**Status:** Proposed  
**Date:** 2025-06-18  
**Priority:** MEDIUM

## Context

Following the successful resolution of KHR goal processing in ADR-095 and the hybrid planner dependency encapsulation in ADR-091, we now have a complete planning infrastructure. This creates an opportunity to implement practical project management tools using the existing hybrid planner API with KHR durative actions.

### Problem Statement

Current project management tools lack integration with AI planning systems. Teams need:

- **Project execution simulation** with real-time progress tracking
- **Critical path execution** with automatic dependency resolution
- **Resource scheduling** with conflict detection and optimization
- **Temporal execution logs** showing project timeline progression
- **MCP integration** for AI assistant access to project execution capabilities

### Opportunity

The existing hybrid planner infrastructure provides everything needed for PERT chart execution:

1. **HybridCoordinatorV2**: Strategy-based planning with temporal constraints
2. **Plan.run_lazy_refineahead**: Execution with step-by-step logging
3. **KHR Durative Actions**: Perfect for construction project simulation
4. **MCP Framework**: Ready for tool integration

### Technical Foundation

- ✅ **Hybrid Planner**: Complete strategy-based planning system (ADR-091)
- ✅ **KHR Integration**: Goal processing pipeline working (ADR-095)
- ✅ **Execution Engine**: Plan.run_lazy_refineahead for step-by-step execution
- ✅ **Temporal Constraints**: STN temporal strategy for scheduling
- ✅ **MCP Framework**: Ready for tool integration

## Decision

Implement a PERT chart execution simulator using the existing hybrid planner API with KHR durative actions to provide AI-accessible project execution capabilities through MCP tools.

### Core Approach

**Use Existing Hybrid Planner**: Leverage HybridCoordinatorV2 instead of creating custom planning logic.

**Construction Domain as HTN Domain**: Model project tasks as HTN methods that decompose into KHR durative actions.

**Execution-Focused**: Use Plan.run_lazy_refineahead to execute projects and return execution logs instead of static plans.

**MCP Tool Integration**: Expose project execution simulation as MCP tools for AI assistant access.

## KHR Interactivity Construction Domain

Based on the KHR_interactivity specification, the following nodes are available for constructing durative actions and task methods:

### Flow Control (Task Methods)
**Sequence**: `flow/sequence` - Execute actions in order
**Branching**: `flow/branch`, `flow/switch` - Conditional execution
**Loops**: `flow/while`, `flow/for`, `flow/doN` - Iterative execution
**Synchronization**: `flow/waitAll`, `flow/multiGate` - Coordination
**Timing**: `flow/throttle` - Rate limiting

### Durative Actions (Core PERT Implementation)
**Variable Interpolation**: `variable/interpolate` - Progress tracking over time
- Maps to: Task execution with progress from 0% to 100%
- Duration: Task duration in seconds
- Use: Critical path task execution

**Pointer Interpolation**: `pointer/interpolate` - Resource allocation over time  
- Maps to: Dynamic resource adjustment during task execution
- Duration: Resource allocation period
- Use: Resource leveling and optimization

**Delay Scheduling**: `flow/setDelay` - Milestone and dependency triggers
- Maps to: Task start scheduling based on dependencies
- Duration: Delay until task can begin
- Use: Dependency management and milestone triggers

### State Management (Task Methods)
**Variables**: `variable/get`, `variable/set`, `variable/setMultiple` - State tracking
**Object Model**: `pointer/get`, `pointer/set` - External system integration
**Animation**: `animation/start`, `animation/stop`, `animation/stopAt` - Timeline control

### Event System (Task Methods)
**Lifecycle**: `event/onStart`, `event/onTick` - System events
**Custom Events**: `event/receive`, `event/send` - Inter-task communication

### Construction Domain Mapping

To be programmed.

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

### PERT Chart Input Data

```elixir
# Standard Construction Project - Minimal Input for PERT Calculation
%ProjectInput{
  name: "house_construction",
  tasks: [
    %{id: "a", description: "Start", duration: 0, dependencies: []},
    %{id: "b", description: "Excavate and pour footers", duration: 4, dependencies: ["a"]},
    %{id: "c", description: "Pour concrete foundation", duration: 2, dependencies: ["b"]},
    %{id: "d", description: "Erect wooden frame including rough roof", duration: 4, dependencies: ["c"]},
    %{id: "e", description: "Lay brickwork", duration: 6, dependencies: ["d"]},
    %{id: "f", description: "Install basement drains and plumbing", duration: 1, dependencies: ["c"]},
    %{id: "g", description: "Pour basement floor", duration: 2, dependencies: ["f"]},
    %{id: "h", description: "Install rough plumbing", duration: 3, dependencies: ["f"]},
    %{id: "i", description: "Install rough wiring", duration: 2, dependencies: ["d"]},
    %{id: "j", description: "Install heating and ventilating", duration: 4, dependencies: ["d", "g"]},
    %{id: "k", description: "Fasten plaster board and plaster", duration: 10, dependencies: ["i", "j", "h"]},
    %{id: "l", description: "Lay finish flooring", duration: 3, dependencies: ["k"]},
    %{id: "m", description: "Install kitchen fixtures", duration: 1, dependencies: ["l"]},
    %{id: "n", description: "Install finish plumbing", duration: 2, dependencies: ["l"]},
    %{id: "o", description: "Finish carpentry", duration: 3, dependencies: ["l"]},
    %{id: "p", description: "Finish roofing and flashing", duration: 2, dependencies: ["e"]},
    %{id: "q", description: "Fasten gutters and downspouts", duration: 1, dependencies: ["p"]},
    %{id: "r", description: "Lay storm drains for rain water", duration: 1, dependencies: ["c"]},
    %{id: "s", description: "Sand and varnish flooring", duration: 2, dependencies: ["o", "r"]},
    %{id: "t", description: "Paint", duration: 3, dependencies: ["m", "n"]},
    %{id: "u", description: "Finish electrical work", duration: 1, dependencies: ["t"]},
    %{id: "v", description: "Finish grading", duration: 2, dependencies: ["q", "r"]},
    %{id: "w", description: "Pour walks and complete landscaping", duration: 5, dependencies: ["v"]},
    %{id: "x", description: "Finish", duration: 0, dependencies: ["s", "u", "w"]}
  ]
}

# PERT Algorithm Output (calculated from input above)
%ProjectAnalysis{
  critical_path: ["a", "b", "c", "d", "i", "j", "k", "l", "o", "s", "x"],
  total_duration: 37,
  task_analysis: %{
    # Critical path tasks (zero slack)
    "a" => %{earliest_start: 0, latest_start: 0, slack: 0},
    "b" => %{earliest_start: 0, latest_start: 0, slack: 0},
    "c" => %{earliest_start: 4, latest_start: 4, slack: 0},
    # Non-critical tasks (with slack)
    "f" => %{earliest_start: 6, latest_start: 9, slack: 3},
    "p" => %{earliest_start: 16, latest_start: 27, slack: 11},
    "r" => %{earliest_start: 6, latest_start: 29, slack: 23}
  }
}
```

### KHR Durative Action Plan

```elixir
# Construction Project Execution with KHR Durative Actions
{:ok, %{
  nodes: %{
    "root" => %{
      task: {"execute_construction_project", ["house_construction"]},
      is_primitive: false,
      children: ["foundation_phase", "framing_phase", "finishing_phase", "resource_monitor"]
    },
    
    # Critical Path: Foundation Phase (0-6 days)
    "foundation_phase" => %{
      task: {"khr_variable_interpolate", [1, "foundation_progress", 1.0, 6.0]},
      is_primitive: true,
      start_time: 0.0,
      duration: 6.0,  # Start → Excavate → Foundation
      effects: [
        {"construction", "foundation_complete", true},
        {"milestone", "foundation_ready", true}
      ]
    },
    
    # Critical Path: Framing Phase (6-26 days)  
    "framing_phase" => %{
      task: {"khr_variable_interpolate", [2, "framing_progress", 1.0, 20.0]},
      is_primitive: true,
      start_time: 6.0,
      duration: 20.0,  # Frame → Wiring → Heating → Plaster
      preconditions: [{"construction", "foundation_complete", true}],
      effects: [
        {"construction", "framing_complete", true},
        {"construction", "rough_systems_complete", true},
        {"milestone", "ready_for_finishing", true}
      ]
    },
    
    # Critical Path: Finishing Phase (26-37 days)
    "finishing_phase" => %{
      task: {"khr_variable_interpolate", [3, "finishing_progress", 1.0, 11.0]},
      is_primitive: true,
      start_time: 26.0,
      duration: 11.0,  # Flooring → Carpentry → Sanding → Completion
      preconditions: [{"construction", "framing_complete", true}],
      effects: [
        {"construction", "finishing_complete", true},
        {"milestone", "house_ready", true}
      ]
    },
    
    # Parallel Resource Management
    "resource_monitor" => %{
      task: {"khr_pointer_interpolate", [4, "/construction/crew_allocation", 0.90, 37.0]},
      is_primitive: true,
      start_time: 0.0,
      duration: 37.0,  # Full project duration
      effects: [
        {"resources", "crew_optimized", true},
        {"resources", "equipment_scheduled", true}
      ]
    },
    
    # Parallel Non-Critical Work (Roofing, Exterior)
    "exterior_work" => %{
      task: {"khr_flow_setDelay", [5, "exterior_completion", 21.0]},
      is_primitive: true,
      start_time: 16.0,  # After brickwork
      duration: 0.1,     # Quick scheduling
      effects: [
        {"exterior", "roofing_scheduled", true},
        {"exterior", "gutters_scheduled", true}
      ]
    }
  },
  
  critical_path_analysis: %{
    path: ["foundation_phase", "framing_phase", "finishing_phase"],
    total_duration: 37.0,
    bottlenecks: ["framing_phase"],  # Longest phase with most dependencies
    slack_opportunities: [
      {"roofing_work", 11.0},      # 11 days slack
      {"storm_drains", 23.0},      # 23 days slack  
      {"basement_drains", 3.0}     # 3 days slack
    ]
  }
}}
```

### Hybrid Planner Execution Flow

```elixir
# MCP Tool: execute_construction_project
def execute_construction_project(project_spec) do
  # Step 1: Create construction domain from project specification
  domain = ConstructionDomain.from_project_spec(project_spec)
  
  # Step 2: Convert project to HTN goals and initial state
  {goals, initial_state} = ConstructionDomain.to_htn_problem(project_spec)
  
  # Step 3: Create hybrid coordinator with default strategies
  coordinator = HybridCoordinatorV2.new_default()
  
  # Step 4: Generate plan using hybrid planner
  case HybridCoordinatorV2.plan(coordinator, domain, initial_state, goals) do
    {:ok, plan} ->
      # Step 5: Execute plan using run_lazy_refineahead
      case Plan.run_lazy_refineahead(domain, initial_state, plan.solution_tree, verbose: 3) do
        {:ok, final_state} ->
          # Step 6: Format execution results for MCP response
          format_execution_results(plan, final_state, project_spec)
        
        {:error, reason} ->
          {:error, "Execution failed: #{reason}"}
      end
    
    {:error, reason} ->
      {:error, "Planning failed: #{reason}"}
  end
end

# Example MCP usage:
{
  "tool": "execute_construction_project",
  "arguments": {
    "project": {
      "name": "house_construction",
      "tasks": [
        {"id": "a", "description": "Start", "duration": 0, "dependencies": []},
        {"id": "b", "description": "Excavate and pour footers", "duration": 4, "dependencies": ["a"]},
        {"id": "c", "description": "Pour concrete foundation", "duration": 2, "dependencies": ["b"]},
        {"id": "d", "description": "Erect wooden frame including rough roof", "duration": 4, "dependencies": ["c"]},
        {"id": "e", "description": "Lay brickwork", "duration": 6, "dependencies": ["d"]},
        {"id": "f", "description": "Install basement drains and plumbing", "duration": 1, "dependencies": ["c"]},
        {"id": "g", "description": "Pour basement floor", "duration": 2, "dependencies": ["f"]},
        {"id": "h", "description": "Install rough plumbing", "duration": 3, "dependencies": ["f"]},
        {"id": "i", "description": "Install rough wiring", "duration": 2, "dependencies": ["d"]},
        {"id": "j", "description": "Install heating and ventilating", "duration": 4, "dependencies": ["d", "g"]},
        {"id": "k", "description": "Fasten plaster board and plaster", "duration": 10, "dependencies": ["i", "j", "h"]},
        {"id": "l", "description": "Lay finish flooring", "duration": 3, "dependencies": ["k"]},
        {"id": "m", "description": "Install kitchen fixtures", "duration": 1, "dependencies": ["l"]},
        {"id": "n", "description": "Install finish plumbing", "duration": 2, "dependencies": ["l"]},
        {"id": "o", "description": "Finish carpentry", "duration": 3, "dependencies": ["l"]},
        {"id": "p", "description": "Finish roofing and flashing", "duration": 2, "dependencies": ["e"]},
        {"id": "q", "description": "Fasten gutters and downspouts", "duration": 1, "dependencies": ["p"]},
        {"id": "r", "description": "Lay storm drains for rain water", "duration": 1, "dependencies": ["c"]},
        {"id": "s", "description": "Sand and varnish flooring", "duration": 2, "dependencies": ["o", "r"]},
        {"id": "t", "description": "Paint", "duration": 3, "dependencies": ["m", "n"]},
        {"id": "u", "description": "Finish electrical work", "duration": 1, "dependencies": ["t"]},
        {"id": "v", "description": "Finish grading", "duration": 2, "dependencies": ["q", "r"]},
        {"id": "w", "description": "Pour walks and complete landscaping", "duration": 5, "dependencies": ["v"]},
        {"id": "x", "description": "Finish", "duration": 0, "dependencies": ["s", "u", "w"]}
      ]
    }
  }
}

# Expected execution log output:
{
  "execution_log": [
    {"time": 0.0, "action": "start_project", "task": "a", "status": "completed"},
    {"time": 0.0, "action": "khr_variable_interpolate", "task": "b", "progress": 0.0, "duration": 4.0},
    {"time": 1.0, "action": "progress_update", "task": "b", "progress": 0.25},
    {"time": 2.0, "action": "progress_update", "task": "b", "progress": 0.50},
    {"time": 3.0, "action": "progress_update", "task": "b", "progress": 0.75},
    {"time": 4.0, "action": "task_complete", "task": "b", "progress": 1.0},
    {"time": 4.0, "action": "khr_variable_interpolate", "task": "c", "progress": 0.0, "duration": 2.0},
    {"time": 6.0, "action": "task_complete", "task": "c", "progress": 1.0},
    {"time": 6.0, "action": "khr_flow_setDelay", "task": "f", "delay": 0.0},
    {"time": 6.0, "action": "khr_variable_interpolate", "task": "d", "progress": 0.0, "duration": 4.0}
  ],
  "critical_path_executed": ["a", "b", "c", "d", "i", "j", "k", "l", "o", "s", "x"],
  "total_execution_time": 37.0,
  "resource_utilization": {
    "crew_allocation": 0.90,
    "equipment_usage": 0.85,
    "material_efficiency": 0.92
  },
  "final_state": {
    "construction": {"house_complete": true},
    "milestones": {"all_phases_complete": true}
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

1. **Use Existing Infrastructure**: Leverage HybridCoordinatorV2 and Plan.run_lazy_refineahead instead of custom implementations
2. **Domain-First**: Create proper Domain.Core structure for construction projects
3. **Execution-Focused**: Prioritize execution logging over static plan generation
4. **Incremental Testing**: Start with simple 3-task projects, expand to full construction example

### Testing Strategy

- **Domain Tests**: Validate construction domain HTN methods and KHR action mapping
- **Hybrid Planner Tests**: Ensure HybridCoordinatorV2 generates valid plans for construction projects
- **Execution Tests**: Verify Plan.run_lazy_refineahead produces expected execution logs
- **MCP Integration Tests**: End-to-end testing of MCP tool with real project specifications

### Documentation Requirements

- **Construction Domain Guide**: How PERT tasks map to HTN methods and KHR durative actions
- **Hybrid Planner Integration**: Using HybridCoordinatorV2 for construction project planning
- **Execution Log Format**: Structure and content of execution results
- **MCP Tool Reference**: Complete API documentation with construction project examples

This ADR establishes AI-accessible project execution simulation using the existing hybrid planner infrastructure with KHR durative actions.
