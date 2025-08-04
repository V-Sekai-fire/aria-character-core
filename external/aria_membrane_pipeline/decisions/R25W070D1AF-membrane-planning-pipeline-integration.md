# R25W070D1AF: Membrane Planning Pipeline Integration

<!-- @adr_serial R25W070D1AF -->

**Status:** Proposed
**Date:** June 20, 2025  
**Priority:** HIGH

## Context

R25W0670D79 successfully implemented the MCP strategy testing interface using Membrane Framework, providing:

- Complete pipeline architecture with 5 core elements
- MCPSource, EchoFilter, ScheduleFilter, ResponseFilter, MCPSink
- PipelineManager for lifecycle control
- MCPToolsV2 integration
- Comprehensive testing framework (59/59 tests passing)

However, the actual planning integration components (PlanFilter and PlannerSink) were designed but not implemented. The current pipeline uses EchoFilter for testing, but production requires actual planning execution.

### Current State

**Implemented (R25W0670D79)**:

```
MCPSource → ScheduleFilter → EchoFilter → ResponseFilter → MCPSink
```

**Missing for Production**:

```
MCPSource → PlanFilter → PlannerSink → ResponseFilter → MCPSink
```

### Gap Analysis

The testing interface is complete, but we need:

1. **PlanFilter**: Convert MCPRequest to PlanningParams using existing HybridPlanner.PlanTransformer
2. **PlannerSink**: Execute actual planning via HybridCoordinatorV2
3. **Integration Testing**: End-to-end pipeline with real planning execution
4. **Performance Optimization**: Ensure pipeline can handle production loads

## Decision

Implement the production planning pipeline components to enable actual planning execution through the Membrane Framework architecture established in R25W0670D79.

## Implementation Plan

### Phase 1: PlanFilter Implementation

**File**: `lib/aria_engine/membrane/plan_filter.ex`

**Missing Implementation**:

- [ ] Membrane.Filter behavior with proper input/output pads
- [ ] Integration with existing `AriaEngine.HybridPlanner.PlanTransformer`
- [ ] Error handling for conversion failures
- [ ] Telemetry for transformation metrics
- [ ] Comprehensive test suite

**Key Requirements**:

- Input: MCPRequest format from MCPSource
- Output: PlanningParams format for PlannerSink
- Use existing `PlanTransformer.convert_to_planning_params/1`
- Handle validation errors gracefully
- Emit telemetry for monitoring

### Phase 2: PlannerSink Implementation

**File**: `lib/aria_engine/membrane/planner_sink.ex`

**Missing Implementation**:

- [ ] Membrane.Sink behavior with input pad and output pad
- [ ] Integration with HybridCoordinatorV2 for actual planning
- [ ] Strategy selection and execution
- [ ] Performance metrics collection
- [ ] Error recovery and timeout handling
- [ ] Comprehensive test suite

**Key Requirements**:

- Input: PlanningParams format from PlanFilter
- Output: PlanningResult format for ResponseFilter
- Execute planning via `HybridCoordinatorV2.plan/5`
- Handle planning timeouts and errors
- Collect detailed performance metrics

### Phase 3: Production Pipeline Integration

**Tasks**:

- [ ] Update PipelineManager to support production topology
- [ ] Add production pipeline configuration to MCPToolsV2
- [ ] Implement pipeline switching (testing vs production)
- [ ] Add production-specific telemetry and monitoring
- [ ] Performance testing and optimization

### Phase 4: End-to-End Testing

**Tasks**:

- [ ] Integration tests with real planning scenarios
- [ ] Performance benchmarking against existing MCP interface
- [ ] Load testing with concurrent requests
- [ ] Error recovery testing
- [ ] Memory usage and leak detection

## Success Criteria

### Functional Requirements

- [ ] **PlanFilter**: Successfully converts MCPRequest to PlanningParams
- [ ] **PlannerSink**: Executes planning via HybridCoordinatorV2
- [ ] **End-to-End**: Complete pipeline processes real planning requests
- [ ] **Error Handling**: Graceful handling of conversion and planning errors
- [ ] **Telemetry**: Comprehensive metrics for all pipeline stages

### Performance Requirements

- [ ] **Throughput**: Match or exceed existing MCP interface performance
- [ ] **Latency**: End-to-end processing under 5 seconds for typical requests
- [ ] **Memory**: Pipeline memory usage under 100MB per instance
- [ ] **Concurrency**: Handle at least 10 concurrent planning requests

### Integration Requirements

- [ ] **Backward Compatibility**: Existing MCP tools continue to work
- [ ] **Strategy Support**: All 6 HybridCoordinator strategies supported
- [ ] **Configuration**: Dynamic pipeline configuration via MCP tools
- [ ] **Monitoring**: Production-ready telemetry and logging

## Implementation Details

### PlanFilter Architecture

```elixir
defmodule AriaEngine.Membrane.PlanFilter do
  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{MCPRequest, PlanningParams}
  alias AriaEngine.HybridPlanner.PlanTransformer

  def_input_pad :input, accepted_format: MCPRequest
  def_output_pad :output, accepted_format: PlanningParams

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    %Buffer{payload: mcp_request} = buffer
    
    case transform_mcp_request(mcp_request) do
      {:ok, planning_params} ->
        output_buffer = %Buffer{payload: planning_params}
        {[buffer: {:output, output_buffer}], state}
        
      {:error, reason} ->
        # Handle conversion error
        error_params = create_error_planning_params(mcp_request, reason)
        output_buffer = %Buffer{payload: error_params}
        {[buffer: {:output, output_buffer}], state}
    end
  end

  defp transform_mcp_request(%MCPRequest{} = request) do
    mcp_params = %{
      "schedule_name" => request.schedule_name,
      "activities" => request.activities,
      "entities" => request.entities,
      "resources" => request.resources,
      "constraints" => request.constraints
    }

    case PlanTransformer.convert_to_planning_params(mcp_params) do
      {:ok, {domain, state, goals}} ->
        planning_params = %PlanningParams{
          domain: domain,
          state: state,
          goals: goals,
          options: [],
          request_id: request.request_id,
          conversion_metadata: %{
            original_activities: length(request.activities),
            converted_at: DateTime.utc_now()
          }
        }
        {:ok, planning_params}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

### PlannerSink Architecture

```elixir
defmodule AriaEngine.Membrane.PlannerSink do
  use Membrane.Filter

  alias AriaEngine.Membrane.Format.{PlanningParams, PlanningResult}
  alias HybridPlanner.HybridCoordinatorV2

  def_input_pad :input, accepted_format: PlanningParams
  def_output_pad :output, accepted_format: PlanningResult

  def_options coordinator: [
    spec: HybridCoordinatorV2.t(),
    description: "HybridCoordinatorV2 instance for planning execution"
  ]

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    %Buffer{payload: planning_params} = buffer
    start_time = System.monotonic_time(:microsecond)

    case execute_planning(state.coordinator, planning_params) do
      {:ok, result} ->
        planning_result = %PlanningResult{
          status: :success,
          result: result,
          execution_metadata: %{
            executed_at: DateTime.utc_now(),
            coordinator_version: "v2"
          },
          request_id: planning_params.request_id,
          performance_metrics: %{
            execution_time_ms: div(System.monotonic_time(:microsecond) - start_time, 1000)
          }
        }

        output_buffer = %Buffer{payload: planning_result}
        {[buffer: {:output, output_buffer}], state}

      {:error, reason} ->
        # Handle planning error
        error_result = create_error_planning_result(planning_params, reason, start_time)
        output_buffer = %Buffer{payload: error_result}
        {[buffer: {:output, output_buffer}], state}
    end
  end

  defp execute_planning(coordinator, %PlanningParams{} = params) do
    case HybridCoordinatorV2.plan(coordinator, params.domain, params.state, params.goals, params.options) do
      {:ok, plan} -> {:ok, plan}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

## Related ADRs

- **R25W0670D79**: MCP Strategy Testing Interface (foundation - COMPLETED)
  - Provides complete testing pipeline: MCPSource → ScheduleFilter → EchoFilter → ResponseFilter → MCPSink
  - Establishes Membrane Framework architecture and format definitions
  - All 59/59 tests passing for pipeline elements and management
- **R25W058D6B9**: Reconnect Scheduler with Hybrid Planner (planning integration)
- **R25W069348D**: Hybrid Coordinator V3 Implementation (future coordinator version)

## Consequences

### Positive

- **Production Ready**: Enables actual planning execution through pipeline
- **Performance**: Maintains existing planning performance with added benefits
- **Scalability**: Process isolation enables concurrent planning requests
- **Monitoring**: Detailed telemetry for production planning operations
- **Flexibility**: Can switch between testing and production pipelines

### Risks

- **Integration Complexity**: Connecting existing planning system to pipeline
- **Performance Overhead**: Pipeline communication may add latency
- **Error Handling**: Complex error scenarios across pipeline stages
- **Memory Usage**: Multiple processes may increase memory footprint

### Mitigation Strategies

- **Incremental Testing**: Test each component individually before integration
- **Performance Benchmarking**: Compare against existing MCP interface
- **Comprehensive Error Handling**: Handle all error scenarios gracefully
- **Memory Monitoring**: Track memory usage across pipeline processes

## Timeline

**Week 1**: PlanFilter implementation and testing
**Week 2**: PlannerSink implementation and testing  
**Week 3**: Production pipeline integration and configuration
**Week 4**: End-to-end testing and performance optimization

This implementation will complete the production-ready Membrane Framework pipeline for MCP planning, building on the solid testing foundation established in R25W0670D79.
