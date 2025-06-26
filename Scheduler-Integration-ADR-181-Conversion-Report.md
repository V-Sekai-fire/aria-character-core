# Scheduler Integration ADR-181 Conversion Report

**Date:** 2025-06-25  
**Status:** Conversion Analysis  
**Priority:** HIGH

## Executive Summary

This report analyzes how to convert section 3.2 Scheduler Integration from an external system approach to an ADR-181 compatible @task_method implementation. The conversion leverages ADR-181's unified durative action specification with entity-capability matching and temporal patterns.

## Current State Analysis

### Section 3.2 Scheduler Integration (From ADR-181-Implementation-Report.md)

**Current Implementation Status:**
- Listed under Phase 3: Planner Integration (Weeks 5-6)
- Part of critical path dependency: **Temporal Specification** → **Durative Action Replacement** → **Scheduler Integration**
- Currently treated as external system integration rather than native @task_method

**Existing Infrastructure (Already Implemented):**
- ✅ **Entity-Capability System**: `apps/aria_scheduler/lib/scheduler/entity_manager.ex`
- ✅ **Temporal Specification System**: `apps/aria_timeline/lib/timeline/interval.ex` 
- ✅ **Goal Format Standardization**: `{predicate, subject, value}` format enforced
- ✅ **Scheduler Application**: `apps/aria_scheduler/` with execution coordination

## ADR-181 @task_method Conversion Strategy

### Understanding @task_method in ADR-181 Context

From ADR-181 specification, @task_method provides hierarchical decomposition for complex workflows:

```elixir
@task_method
@spec task_name(AriaState.t(), [term()]) :: {:ok, [AriaEngine.todo_item()]}
def task_name(state, args) do
  {:ok, [
    # Prerequisites as goals
    {"available", "scheduler", true},
    
    # Setup tasks
    {:initialize_scheduler, []},
    
    # Main scheduling action
    {:execute_schedule, [args]},
    
    # Verification goals
    {"schedule_status", "system", "active"}
  ]}
end
```

### Current External System Approach (To Be Converted)

**Current Pattern (External Integration):**
```elixir
# External system call pattern
def integrate_with_scheduler(state, schedule_data) do
  # External API calls to scheduler service
  case AriaScheduler.External.submit_schedule(schedule_data) do
    {:ok, schedule_id} -> 
      # Update state with external reference
      state |> AriaState.RelationalState.set_fact("external_schedule_id", "system", schedule_id)
    {:error, reason} -> 
      {:error, "External scheduler failed: #{reason}"}
  end
end
```

**Problems with External Approach:**
- No entity-capability validation
- No temporal pattern integration
- No hierarchical decomposition
- External dependency creates failure points
- Cannot leverage ADR-181's unified specification

### Converted ADR-181 @task_method Approach

**New Pattern (Native @task_method):**
```elixir
defmodule AriaEngine.Domains.SchedulerIntegration do
  use AriaEngine.Domain
  
  @type schedule_data :: map()
  @type entity_allocation :: [String.t()]
  
  # Main scheduler integration as @task_method
  @task_method
  @spec integrate_scheduler_workflow(AriaState.t(), [schedule_data()]) :: {:ok, [AriaEngine.todo_item()]}
  def integrate_scheduler_workflow(state, [schedule_data]) do
    {:ok, [
      # Prerequisites - validate scheduler readiness
      {"status", "scheduler_service", "available"},
      {"capacity", "scheduler_service", {:>=, 1}},
      
      # Entity allocation validation
      {:validate_required_entities, [schedule_data]},
      
      # Temporal constraint validation  
      {:validate_temporal_constraints, [schedule_data]},
      
      # Schedule preparation
      {:prepare_schedule_data, [schedule_data]},
      
      # Core scheduling actions (durative)
      {:execute_schedule_allocation, [schedule_data]},
      
      # Verification and monitoring
      {"allocation_status", "scheduler", "active"},
      {:monitor_schedule_execution, [schedule_data]},
      
      # Cleanup and finalization
      {:finalize_schedule_integration, [schedule_data]}
    ]}
  end
  
  # Supporting durative actions with entity requirements
  @action duration: "PT5M",
          requires_entities: [
            %{type: "scheduler_service", capabilities: [:scheduling, :allocation]},
            %{type: "entity_registry", capabilities: [:validation, :lookup]}
          ]
  @spec validate_required_entities(AriaState.t(), [schedule_data()]) :: AriaState.t()
  def validate_required_entities(state, [schedule_data]) do
    # Validate that all entities required by schedule exist and have proper capabilities
    required_entities = extract_entity_requirements(schedule_data)
    
    validation_results = Enum.map(required_entities, fn entity_spec ->
      validate_entity_capability_match(state, entity_spec)
    end)
    
    state
    |> AriaState.RelationalState.set_fact("entity_validation", "scheduler", "complete")
    |> AriaState.RelationalState.set_fact("validation_results", "scheduler", validation_results)
  end
  
  @action duration: "PT2M",
          requires_entities: [
            %{type: "temporal_validator", capabilities: [:temporal_reasoning]},
            %{type: "timeline_service", capabilities: [:interval_validation]}
          ]
  @spec validate_temporal_constraints(AriaState.t(), [schedule_data()]) :: AriaState.t()
  def validate_temporal_constraints(state, [schedule_data]) do
    # Validate temporal patterns using ADR-181's 9-pattern system
    temporal_specs = extract_temporal_specifications(schedule_data)
    
    validation_results = Enum.map(temporal_specs, fn temporal_spec ->
      validate_temporal_pattern(temporal_spec)
    end)
    
    state
    |> AriaState.RelationalState.set_fact("temporal_validation", "scheduler", "complete")
    |> AriaState.RelationalState.set_fact("temporal_results", "scheduler", validation_results)
  end
  
  @action duration: "PT10M",
          requires_entities: [
            %{type: "scheduler_service", capabilities: [:scheduling, :allocation]},
            %{type: "entity_manager", capabilities: [:allocation, :tracking]},
            %{type: "timeline_service", capabilities: [:temporal_scheduling]}
          ]
  @spec execute_schedule_allocation(AriaState.t(), [schedule_data()]) :: AriaState.t()
  def execute_schedule_allocation(state, [schedule_data]) do
    # Core scheduling logic using entity-capability matching
    allocation_plan = create_entity_allocation_plan(state, schedule_data)
    temporal_schedule = create_temporal_schedule(state, schedule_data)
    
    state
    |> AriaState.RelationalState.set_fact("allocation_plan", "scheduler", allocation_plan)
    |> AriaState.RelationalState.set_fact("temporal_schedule", "scheduler", temporal_schedule)
    |> AriaState.RelationalState.set_fact("schedule_status", "scheduler", "executing")
  end
  
  # Monitoring as ongoing durative action
  @action duration: "PT1H",  # Continuous monitoring for 1 hour
          requires_entities: [
            %{type: "monitor_service", capabilities: [:monitoring, :alerting]},
            %{type: "scheduler_service", capabilities: [:status_reporting]}
          ]
  @spec monitor_schedule_execution(AriaState.t(), [schedule_data()]) :: AriaState.t()
  def monitor_schedule_execution(state, [schedule_data]) do
    # Set up continuous monitoring of schedule execution
    monitoring_config = create_monitoring_configuration(schedule_data)
    
    state
    |> AriaState.RelationalState.set_fact("monitoring_active", "scheduler", true)
    |> AriaState.RelationalState.set_fact("monitoring_config", "scheduler", monitoring_config)
  end
  
  # Helper functions for entity and temporal processing
  @spec extract_entity_requirements(schedule_data()) :: [map()]
  defp extract_entity_requirements(schedule_data) do
    # Extract entity requirements from schedule data
    # Convert external format to ADR-181 entity specifications
    schedule_data
    |> Map.get("required_resources", [])
    |> Enum.map(&convert_to_entity_spec/1)
  end
  
  @spec extract_temporal_specifications(schedule_data()) :: [map()]
  defp extract_temporal_specifications(schedule_data) do
    # Extract temporal constraints and convert to ADR-181 9-pattern system
    schedule_data
    |> Map.get("temporal_constraints", [])
    |> Enum.map(&convert_to_temporal_pattern/1)
  end
  
  @spec convert_to_entity_spec(map()) :: map()
  defp convert_to_entity_spec(resource_spec) do
    # Convert external resource specification to ADR-181 entity format
    %{
      type: Map.get(resource_spec, "type", "unknown"),
      capabilities: Map.get(resource_spec, "capabilities", []) |> Enum.map(&String.to_atom/1)
    }
  end
  
  @spec convert_to_temporal_pattern(map()) :: map()
  defp convert_to_temporal_pattern(temporal_constraint) do
    # Convert external temporal format to ADR-181 temporal patterns
    %{
      start: Map.get(temporal_constraint, "start_time"),
      end: Map.get(temporal_constraint, "end_time"), 
      duration: Map.get(temporal_constraint, "duration")
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
```

## Conversion Benefits

### 1. Native ADR-181 Integration

**Before (External System):**
- External API dependencies
- No entity-capability validation
- Manual temporal constraint handling
- Separate failure modes

**After (@task_method):**
- Native hierarchical decomposition
- Automatic entity-capability matching
- Integrated temporal pattern validation
- Unified failure handling and replanning

### 2. Entity-Capability Validation

**Automatic Entity Matching:**
```elixir
# ADR-181 automatically validates entity requirements
@action requires_entities: [
  %{type: "scheduler_service", capabilities: [:scheduling, :allocation]},
  %{type: "entity_registry", capabilities: [:validation, :lookup]}
]
```

**Benefits:**
- Ensures required services are available before scheduling
- Validates capability compatibility
- Automatic resource conflict detection
- Dynamic entity allocation based on availability

### 3. Temporal Pattern Integration

**9-Pattern Temporal System:**
```elixir
# Pattern 5: Duration with Deadline (Calculated Start)
%{end: "2025-06-25T18:00:00-07:00", duration: "PT2H"}  # Must finish by 6 PM, takes 2 hours

# Pattern 7: Start with Duration (Calculated End)  
%{start: "2025-06-25T14:00:00-07:00", duration: "PT1H"}  # Starts at 2 PM, runs for 1 hour
```

**Benefits:**
- Standardized temporal constraint handling
- Automatic start/end time calculation
- Validation of temporal consistency
- Integration with existing timeline system

### 4. Hierarchical Decomposition

**Task Method Structure:**
```elixir
@task_method
def integrate_scheduler_workflow(state, [schedule_data]) do
  {:ok, [
    # Prerequisites → Goals
    {"status", "scheduler_service", "available"},
    
    # Preparation → Tasks  
    {:validate_required_entities, [schedule_data]},
    {:validate_temporal_constraints, [schedule_data]},
    
    # Execution → Durative Actions
    {:execute_schedule_allocation, [schedule_data]},
    
    # Verification → Goals
    {"allocation_status", "scheduler", "active"}
  ]}
end
```

**Benefits:**
- Clear separation of concerns
- Reusable validation components
- Natural failure recovery points
- Automatic verification integration

## Implementation Plan

### Phase 1: Entity Registration Setup (Week 1)

**1.1 Register Scheduler Entities**

```elixir
@spec setup_scheduler_entities(AriaState.t()) :: AriaState.t()
def setup_scheduler_entities(state) do
  state
  |> register_entity("scheduler_service", "scheduler", [:scheduling, :allocation, :coordination])
  |> register_entity("entity_registry", "registry", [:validation, :lookup, :capability_matching])
  |> register_entity("temporal_validator", "validator", [:temporal_reasoning, :constraint_validation])
  |> register_entity("timeline_service", "timeline", [:interval_validation, :temporal_scheduling])
  |> register_entity("monitor_service", "monitor", [:monitoring, :alerting, :status_reporting])
end
```

**1.2 Entity Status Management**

```elixir
# Entity availability tracking
state
|> AriaState.RelationalState.set_fact("status", "scheduler_service", "available")
|> AriaState.RelationalState.set_fact("capacity", "scheduler_service", 10)
|> AriaState.RelationalState.set_fact("current_load", "scheduler_service", 0)
```

### Phase 2: @task_method Implementation (Week 2)

**2.1 Core Task Method**

Implement `integrate_scheduler_workflow/2` as shown above with:
- Entity requirement validation
- Temporal constraint processing
- Schedule allocation execution
- Monitoring and verification

**2.2 Supporting Durative Actions**

Implement supporting actions:
- `validate_required_entities/2`
- `validate_temporal_constraints/2`
- `execute_schedule_allocation/2`
- `monitor_schedule_execution/2`

### Phase 3: Integration Testing (Week 3)

**3.1 End-to-End Workflow Testing**

```elixir
# Test complete scheduler integration workflow
schedule_data = %{
  "required_resources" => [
    %{"type" => "chef", "capabilities" => ["cooking"]},
    %{"type" => "oven", "capabilities" => ["heating"]}
  ],
  "temporal_constraints" => [
    %{"start_time" => "2025-06-25T14:00:00-07:00", "duration" => "PT2H"}
  ]
}

{:ok, plan} = AriaEngine.plan(domain, state, [
  {:integrate_scheduler_workflow, [schedule_data]}
])
```

**3.2 Failure Recovery Testing**

Test scenarios:
- Entity unavailability
- Temporal constraint conflicts
- Resource allocation failures
- Monitoring system failures

### Phase 4: Migration and Documentation (Week 4)

**4.1 External System Migration**

Create migration tools to convert existing external scheduler integrations:

```elixir
defmodule AriaEngine.SchedulerMigration do
  @spec convert_external_schedule(map()) :: {:ok, [AriaEngine.todo_item()]} | {:error, String.t()}
  def convert_external_schedule(external_schedule) do
    # Convert external format to @task_method workflow
    schedule_data = normalize_schedule_format(external_schedule)
    
    {:ok, [
      {:integrate_scheduler_workflow, [schedule_data]}
    ]}
  end
end
```

**4.2 Documentation Updates**

Document the conversion process and new @task_method patterns for scheduler integration.

## Success Criteria

### Functional Requirements

- [ ] Scheduler integration works as native @task_method
- [ ] Entity-capability validation integrated
- [ ] Temporal patterns properly validated
- [ ] Hierarchical decomposition functional
- [ ] Monitoring and verification working

### Performance Requirements

- [ ] Entity validation < 100ms
- [ ] Temporal validation < 50ms  
- [ ] Schedule allocation < 5 minutes
- [ ] Monitoring overhead < 5% CPU

### Quality Requirements

- [ ] 100% test coverage for new @task_method
- [ ] Zero breaking changes for existing scheduler functionality
- [ ] Complete migration documentation
- [ ] Performance benchmarks established

## Risk Assessment

### High Risk Areas

1. **Entity Availability**: Required scheduler entities may not be available
2. **Temporal Conflicts**: Schedule constraints may be impossible to satisfy
3. **Migration Complexity**: Converting existing external integrations
4. **Performance Impact**: Additional validation overhead

### Mitigation Strategies

1. **Entity Fallbacks**: Define alternative entities with compatible capabilities
2. **Temporal Flexibility**: Support multiple temporal patterns for same schedule
3. **Gradual Migration**: Phase conversion with feature flags
4. **Performance Monitoring**: Benchmark and optimize validation steps

## Conclusion

Converting Scheduler Integration from external system to ADR-181 @task_method provides:

**Key Benefits:**
- **Native Integration**: No external dependencies
- **Entity Validation**: Automatic capability matching
- **Temporal Integration**: 9-pattern temporal system
- **Hierarchical Structure**: Natural decomposition and failure recovery
- **Unified Specification**: Consistent with ADR-181 standards

**Implementation Effort:**
- **Timeline**: 4 weeks
- **Complexity**: Medium (leverages existing infrastructure)
- **Risk**: Low (builds on proven ADR-181 patterns)

**Strategic Value:**
- Eliminates external scheduler dependency
- Provides foundation for advanced scheduling features
- Enables sophisticated temporal reasoning
- Supports multi-agent coordination scenarios

The conversion transforms scheduler integration from a brittle external dependency into a robust, native @task_method that fully leverages ADR-181's unified durative action specification and entity-capability system.
