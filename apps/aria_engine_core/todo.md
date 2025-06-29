# AriaEngineCore TODO

**@aria_serial:** R25W158CORE

**ADR Reference:** R25W1398085 - Unified Durative Action Specification and Planner Standardization

## Overview

AriaEngineCore provides the foundational temporal planning and execution capabilities for the Aria system. This todo covers implementation of a comprehensive test domain that validates the R25W1398085 unified durative action specification using KHR Interactivity behavior graphs as a realistic testing scenario.

## Completed ✅

### Core API Implementation (Current State)

- [x] AriaEngineCore external API module with proper delegation
- [x] Three main API functions: `plan/3`, `run_lazy/3`, `run_lazy_tree/3`
- [x] Type aliases for external API compatibility
- [x] State management API delegation to AriaEngineCore.State
- [x] Domain management API delegation to AriaEngineCore.Domain
- [x] Solution tree API structure
- [x] Version information and application metadata

### Internal Module Structure

- [x] AriaEngineCore.Planner module integration
- [x] AriaEngineCore.Domain module delegation
- [x] AriaEngineCore.State module delegation
- [x] AriaEngineCore.Plan module for solution trees
- [x] Proper module documentation and examples

## Implementation Plan

### Phase 1: KHR Interactivity Test Domain Implementation (CRITICAL)

**Priority: HIGH - Required for R25W1398085 validation**

- [ ] **KHR Interactivity Test Domain Module**
  - [ ] Create `test/support/khr_interactivity_domain.ex`
  - [ ] Entity definitions: nodes, cameras, animations, behavior_graphs
  - [ ] Resource capabilities: transform, animation_control, event_trigger
  - [ ] All 8 temporal patterns from R25W1398085 specification

- [ ] **Entity-Based Resource Management**
  - [ ] Node entities with transform capabilities
  - [ ] Camera entities with view_control capabilities  
  - [ ] Animation entities with playback_control capabilities
  - [ ] Behavior graph entities with execution_control capabilities
  - [ ] Resource conflict detection and resolution

- [ ] **Temporal Action Patterns Implementation**
  - [ ] **Pattern 1**: Instant actions (trigger_event, set_property)
  - [ ] **Pattern 2**: Floating duration (play_animation, move_camera)
  - [ ] **Pattern 3**: Fixed duration (wait, delay_execution)
  - [ ] **Pattern 4**: Resource deadline (animation_by_time)
  - [ ] **Pattern 5**: Start deadline (begin_sequence_by)
  - [ ] **Pattern 6**: End deadline (complete_by)
  - [ ] **Pattern 7**: Time window (execute_during)
  - [ ] **Pattern 8**: Open intervals (continuous_monitoring)

### Phase 2: AriaGltf Mocking Strategy (HIGH PRIORITY)

**Priority: HIGH - Enables immediate testing without full glTF implementation**

- [ ] **Minimal Mock AriaGltf Modules**
  - [ ] Create `test/support/mock_aria_gltf.ex`
  - [ ] Mock AriaGltf.Document with basic structure
  - [ ] Mock AriaGltf.Scene with node references
  - [ ] Mock AriaGltf.Node with transform data
  - [ ] Mock AriaGltf.Animation with basic timeline

- [ ] **Behavior Graph Mock Integration**
  - [ ] Mock KHR_interactivity extension support
  - [ ] Basic behavior graph node structure
  - [ ] Event system mock implementation
  - [ ] Variable and flow control mocks

- [ ] **Integration Points for Future Connection**
  - [ ] Clear interface boundaries for real AriaGltf
  - [ ] Dependency injection patterns for easy replacement
  - [ ] Version compatibility markers
  - [ ] Migration path documentation

### Phase 3: R25W1398085 Specification Validation (CRITICAL)

**Priority: CRITICAL - Core requirement validation**

- [ ] **Method Type Implementation Validation**
  - [ ] `@action` - Primitive operations (start_animation, set_transform)
  - [ ] `@command` - High-level operations (play_sequence, setup_scene)
  - [ ] `@task_method` - Task decomposition (complex_animation_sequence)
  - [ ] `@unigoal_method` - Single goal achievement (achieve_camera_position)
  - [ ] `@multigoal_method` - Multiple goal coordination (sync_animations)
  - [ ] `@multitodo_method` - Mixed task handling (scene_state_management)

- [ ] **Entity Resource Management Validation**
  - [ ] Resource capability checking (can_animate, can_transform)
  - [ ] Resource conflict detection (multiple animations on same node)
  - [ ] Resource scheduling and allocation
  - [ ] Resource cleanup and release

- [ ] **Temporal Constraint Testing**
  - [ ] Duration constraint validation
  - [ ] Deadline constraint enforcement
  - [ ] Time window constraint checking
  - [ ] Temporal dependency resolution

### Phase 4: Test Suite Implementation (HIGH PRIORITY)

**Priority: HIGH - Comprehensive validation testing**

- [ ] **Domain Integration Tests**
  - [ ] Create `test/aria_engine_core/khr_interactivity_test.exs`
  - [ ] Test all temporal patterns with realistic scenarios
  - [ ] Validate entity resource management
  - [ ] Test method type implementations

- [ ] **Specification Compliance Tests**
  - [ ] R25W1398085 pattern compliance validation
  - [ ] Entity capability enforcement testing
  - [ ] Temporal constraint satisfaction testing
  - [ ] Error handling and recovery testing

- [ ] **Integration Scenario Tests**
  - [ ] Complex multi-entity scenarios
  - [ ] Concurrent animation management
  - [ ] Behavior graph execution flow
  - [ ] Real-time constraint validation

### Phase 5: Documentation and Examples (MEDIUM PRIORITY)

**Priority: MEDIUM - Developer experience and adoption**

- [ ] **KHR Interactivity Domain Documentation**
  - [ ] Complete domain specification document
  - [ ] Entity and resource documentation
  - [ ] Temporal pattern usage examples
  - [ ] Best practices and common patterns

- [ ] **Integration Examples**
  - [ ] Simple scene setup examples
  - [ ] Animation coordination examples
  - [ ] Behavior graph integration examples
  - [ ] Error handling examples

- [ ] **API Usage Documentation**
  - [ ] AriaEngineCore API usage with KHR domain
  - [ ] Planning and execution workflows
  - [ ] Debugging and troubleshooting guides

### Phase 6: Performance and Optimization (LOW PRIORITY)

**Priority: LOW - Performance enhancements after core functionality**

- [ ] **Performance Benchmarking**
  - [ ] Planning performance with complex scenarios
  - [ ] Execution performance with many entities
  - [ ] Memory usage optimization
  - [ ] Concurrent execution performance

- [ ] **Optimization Implementation**
  - [ ] Resource management optimization
  - [ ] Temporal constraint solving optimization
  - [ ] Memory pool management
  - [ ] Execution pipeline optimization

### Phase 7: Real AriaGltf Integration (FUTURE)

**Priority: FUTURE - After aria_gltf Phase 1 completion**

- [ ] **Replace Mock Modules**
  - [ ] Remove mock AriaGltf modules
  - [ ] Integrate with real AriaGltf.Document
  - [ ] Integrate with real AriaGltf.Animation
  - [ ] Integrate with real behavior graph support

- [ ] **Enhanced KHR Interactivity Support**
  - [ ] Full KHR_interactivity extension support
  - [ ] Advanced behavior graph execution
  - [ ] Real-time scene manipulation
  - [ ] Performance optimization with real glTF data

## Test Domain Specification

### KHR Interactivity Test Domain

**Purpose:** Validate R25W1398085 unified durative action specification using realistic 3D scene management scenarios.

**Core Entities (R25W1398085 Compliant):**

```elixir
# Entity Registration (for planning - stored in AriaState)
# Scene Node Entity - uses integer glTF node index
%{
  type: :scene_node,
  id: 0,  # Integer glTF node index per KHR Interactivity spec
  capabilities: [:transform, :visibility, :animation_target]
}

# Camera Entity - uses integer glTF camera index
%{
  type: :camera, 
  id: 0,  # Integer glTF camera index
  capabilities: [:view_control, :projection_control]
}

# Animation Entity - uses integer glTF animation index
%{
  type: :animation,
  id: 0,  # Integer glTF animation index  
  capabilities: [:playback_control, :time_control]
}

# Behavior Graph Entity - custom entity for KHR_interactivity
%{
  type: :behavior_graph,
  id: "interaction_graph",  # String ID for custom entities
  capabilities: [:execution_control, :event_handling]
}
```

**State vs Scene Property Management:**

```elixir
# Planning State (@action methods modify AriaState facts)
# Used for planning-time reasoning and constraint checking
AriaState.set_fact(state, "node_status", 0, "animating")
AriaState.set_fact(state, "target_position", 0, [1.0, 2.0, 3.0])
AriaState.set_fact(state, "animation_playing", 0, true)
AriaState.set_fact(state, "camera_mode", 0, "following")

# Scene Properties (@command methods use pointer/set to modify glTF scene)
# Direct manipulation of actual glTF document during execution
# Uses KHR Interactivity JSON Pointer specification:
# - "/nodes/0/translation" -> [1.0, 2.0, 3.0]
# - "/nodes/0/rotation" -> [0.0, 0.0, 0.0, 1.0] 
# - "/cameras/0/perspective/yfov" -> 0.785398
# - "/animations/0/extensions/KHR_interactivity/isPlaying" -> true
```

**Sample Temporal Patterns (Corrected for R25W1398085):**

1. **Pattern 1 - Instant Action**: 
   ```elixir
   @action true
   def trigger_event(state, [graph_id, event_name])
   ```

2. **Pattern 2 - Floating Duration**: 
   ```elixir
   @action duration: "PT5S"
   def play_animation(state, [animation_id])
   ```

3. **Pattern 4 - Calculated Start (Deadline)**:
   ```elixir
   @action end: "2025-06-29T14:00:00-07:00", duration: "PT2S"
   def move_camera_to(state, [camera_id, target_position])
   ```

4. **Pattern 6 - Calculated End**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", duration: "PT30S"
   def begin_sequence(state, [animation_ids])
   ```

5. **Pattern 7 - Fixed Interval**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", end: "2025-06-29T12:05:00-07:00"
   def monitor_interaction(state, [node_id])
   ```

6. **Pattern 8 - Constraint Validation**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", 
           end: "2025-06-29T12:02:00-07:00", 
           duration: "PT2M"
   def continuous_update(state, [entity_id])
   ```

**Method Type Examples:**

```elixir
# @action - Planning-time state changes (modify AriaState)
@doc "Transforms node position state for planning-time reasoning"
@action duration: "PT3S", requires_entities: [%{type: :scene_node, capabilities: [:transform]}]
def move_node(state, [node_id, target_pos]) do
  state |> AriaState.set_fact("node_position", node_id, target_pos)
  {:ok, state}
end

# @command - Execution-time scene changes (modify glTF via pointers)
@doc "Executes node movement with real glTF scene manipulation and failure handling"
@command true  
def move_node_command(state, [node_id, target_pos]) do
  # Uses pointer/set with "/nodes/#{node_id}/translation" 
  case apply_scene_transformation(node_id, :translation, target_pos) do
    :ok -> {:ok, state}
    {:error, reason} -> {:error, reason}
  end
end

# @task_method - Complex workflow decomposition
@doc "Decomposes complex scene setup into manageable planning steps"
@task_method true
def setup_scene(state, [scene_config]) do
  {:ok, [
    {:register_entities, [scene_config.entities]},
    {"camera_ready", 0, true},  # Goal: camera is ready
    {:position_camera, [0, scene_config.camera_position]},
    {"scene_status", "main", "ready"}  # Goal: scene is ready
  ]}
end

# @unigoal_method - Single goal achievement  
@doc "Achieves specific node position goals through movement actions"
@unigoal_method predicate: "node_position"
def achieve_node_position(state, {node_id, target_position}) do
  {:ok, [
    {:move_node, [node_id, target_position]}
  ]}
end
```

## Success Criteria

### R25W1398085 Validation Success

- [ ] All 8 temporal patterns implemented and tested
- [ ] All 6 method types (@action, @command, etc.) validated
- [ ] Entity-based resource management working correctly
- [ ] Temporal constraints properly enforced
- [ ] Complex multi-entity scenarios executing successfully

### Integration Success

- [ ] Mock AriaGltf modules provide sufficient functionality for testing
- [ ] Clear migration path to real AriaGltf implementation
- [ ] Performance acceptable for development and testing
- [ ] Test suite provides comprehensive coverage

### Documentation Success

- [ ] Clear examples of using AriaEngineCore with KHR domain
- [ ] Comprehensive specification compliance documentation
- [ ] Integration patterns documented for other domains
- [ ] Troubleshooting and debugging guides available

## ADR References and Dependencies

**Primary ADR:** R25W1398085 - Unified Durative Action Specification and Planner Standardization

**Related ADRs:**
- **R25W087E1AE**: Aria Engine Plans glTF KHR Interactivity Implementation
- **R25W1513883**: Comprehensive glTF 2.0 Implementation (aria_gltf dependency)
- **R25W0503071**: KHR Interactivity Systematic Verification Plan

**Technical Dependencies:**
- AriaState - World state representation
- AriaTimeline - Temporal constraint management
- AriaEngineCore.Domain - Domain definition framework
- AriaEngineCore.Planner - Planning algorithm implementation

**Mock Dependencies (Temporary):**
- Mock AriaGltf.Document - Basic glTF document structure
- Mock AriaGltf.Animation - Animation timeline support
- Mock KHR_interactivity - Behavior graph framework

## Implementation Status

- [ ] ✅ AriaEngineCore external API complete and functional
- [ ] 🔄 KHR Interactivity test domain - Ready for implementation
- [ ] ⏳ AriaGltf mocking strategy - Awaiting implementation
- [ ] 📋 R25W1398085 validation suite - Planning complete
- [ ] 🎯 Ready for Phase 1 implementation

## Notes

**Mock Strategy Rationale:** Creating minimal mock AriaGltf modules allows immediate R25W1398085 validation without waiting for aria_gltf Phase 1 completion. The mocks provide essential structures for testing while maintaining clear migration paths to real implementations.

**Test Domain Choice:** KHR Interactivity provides an ideal test case because it combines temporal planning (animations, sequences) with resource management (nodes, cameras) and complex entity relationships (behavior graphs), thoroughly exercising the R25W1398085 specification.

**Future Integration:** When aria_gltf completes Phase 1, the mock modules can be seamlessly replaced with real implementations, and the test domain can be enhanced with full glTF capabilities.
