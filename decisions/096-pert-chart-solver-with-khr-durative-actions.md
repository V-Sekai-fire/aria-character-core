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