# AriaEngineCore TODO

**@aria_serial:** R25W158CORE

**ADR Reference:** R25W1398085 - Unified Durative Action Specification and Planner Standardization

## Overview

AriaEngineCore provides the foundational temporal planning and execution capabilities for the Aria system. This todo covers implementation of a comprehensive test domain that validates the R25W1398085 unified durative action specification using EWBIK (Entirely Wahba's-problem Based Inverse Kinematics) integrated with KHR Interactivity behavior graphs as a realistic testing scenario.

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

### Phase 1: EWBIK Math Solver Ports (FOUNDATION - CRITICAL PRIORITY)

**Priority: CRITICAL - Mathematical foundation for all IK operations**

- [ ] **Quaternion Characteristic Polynomial (QCP) Algorithm Port**
  - [ ] Create `lib/aria_engine_core/math/qcp.ex`
  - [ ] Port `weighted_superpose/4` function from C++ implementation
  - [ ] Implement inner product matrix calculation
  - [ ] Implement characteristic polynomial solving for optimal quaternion
  - [ ] Add numerical stability handling and edge case management
  - [ ] Comprehensive test suite for QCP algorithm accuracy

- [ ] **IKNode3D Hierarchy Management Port**
  - [ ] Create `lib/aria_engine_core/math/ik_node_3d.ex`
  - [ ] Port transform hierarchy management from C++
  - [ ] Implement local/global coordinate space conversions
  - [ ] Add transform propagation and dirty state tracking
  - [ ] Support parent-child bone relationships
  - [ ] Scale management and transform composition

- [ ] **Supporting Mathematical Primitives**
  - [ ] Create `lib/aria_engine_core/math/vector3.ex`
  - [ ] Create `lib/aria_engine_core/math/quaternion.ex`
  - [ ] Create `lib/aria_engine_core/math/transform3d.ex`
  - [ ] Implement all mathematical operations needed by EWBIK
  - [ ] Ensure numerical precision and stability
  - [ ] Performance optimizations for real-time use

### Phase 2: EWBIK Algorithm Implementation (HIGH PRIORITY)

**Priority: HIGH - Core EWBIK solver for multi-effector coordination**

- [ ] **Skeleton Segmentation System**
  - [ ] Create `lib/aria_engine_core/ewbik/segmentation.ex`
  - [ ] Implement bone chain dependency analysis
  - [ ] Create processing order determination
  - [ ] Handle multiple effector hierarchies
  - [ ] Segment validation and error handling

- [ ] **Multi-Effector EWBIK Solver**
  - [ ] Create `lib/aria_engine_core/ewbik/solver.ex`
  - [ ] Implement core EWBIK algorithm with QCP integration
  - [ ] Multi-effector coordination with priority weighting
  - [ ] Iterative solving with convergence criteria
  - [ ] Dampening and stabilization pass implementation
  - [ ] Performance budget management and early termination

- [ ] **Kusudama Constraint System**
  - [ ] Create `lib/aria_engine_core/ewbik/kusudama.ex`
  - [ ] Implement cone-based joint orientation constraints
  - [ ] Continuous constraint boundary handling
  - [ ] Sequence cone and tangent cone validation
  - [ ] Twist limit enforcement
  - [ ] Nearest valid orientation calculation

- [ ] **Motion Propagation Management**
  - [ ] Create `lib/aria_engine_core/ewbik/propagation.ex`
  - [ ] Implement hierarchical effector influence calculation
  - [ ] Motion propagation factor application
  - [ ] Ancestor-descendant weight distribution
  - [ ] Ultimate vs intermediary target handling

### Phase 2.5: Kusudama Constraint Visualization (HIGH PRIORITY)

**Priority: HIGH - Visual debugging and constraint validation for EWBIK**

- [ ] **Hybrid Skin + Morph Constraint Visualization**
  - [ ] Create `lib/aria_engine_core/ewbik/constraint_visualization.ex`
  - [ ] Implement constraint shell geometry generation for Kusudama cones
  - [ ] Design constraint bone hierarchy for skinning constraint shells
  - [ ] Create joint state morph targets for immediate visual feedback
  - [ ] Real-time coordination between EWBIK solver and visualization system

- [ ] **Constraint Shell Geometry System**
  - [ ] Cone geometry generation algorithm for sequence cones
  - [ ] Tangent cone connection mesh generation between sequence cones
  - [ ] Twist limit cylindrical band visualization
  - [ ] Dynamic mesh deformation based on constraint parameters
  - [ ] Performance optimization for real-time constraint updates

- [ ] **Joint State Morph Target System**
  - [ ] Automated generation of constraint state morphs for character joints
  - [ ] Morph weight calculation based on constraint proximity
  - [ ] Temporal smoothing to avoid jarring visual transitions
  - [ ] Integration with existing character mesh morph targets

- [ ] **glTF Integration for Constraint Visualization**
  - [ ] Constraint visualization node hierarchy within glTF scene structure
  - [ ] KHR_animation_pointer usage for real-time constraint updates
  - [ ] KHR_materials_variants for constraint state material switching
  - [ ] Integration with KHR_interactivity behavior graphs for constraint control

- [ ] **Visualization Coordination Pipeline**
  - [ ] Data flow between Kusudama constraint evaluation and visualization
  - [ ] Synchronization of constraint updates with visual feedback
  - [ ] LOD system for constraint visualization (detailed vs simplified)
  - [ ] Error handling when constraint evaluation fails

### Phase 3: EWBIK-Enhanced KHR Interactivity Test Domain (HIGH PRIORITY)

**Priority: HIGH - Realistic IK testing with sophisticated constraint validation**

- [ ] **EWBIK Entity Types for KHR Interactivity**
  - [ ] Create `test/support/ewbik_khr_domain.ex`
  - [ ] EWBIK skeleton entities with multi-effector support
  - [ ] IK effector entities with motion propagation factors
  - [ ] Kusudama constraint entities with cone definitions
  - [ ] Bone hierarchy entities with transform management
  - [ ] Integration with KHR Interactivity node system

- [ ] **Enhanced Temporal Action Patterns with EWBIK**
  - [ ] **Pattern 1**: Instant IK solving (`solve_ik_instant`)
  - [ ] **Pattern 2**: Floating duration IK solving (`solve_ik_over_time`) 
  - [ ] **Pattern 3**: Fixed duration pose transitions (`transition_pose`)
  - [ ] **Pattern 4**: Deadline-constrained reaching (`reach_target_by_deadline`)
  - [ ] **Pattern 5**: Coordinated multi-effector starts (`begin_coordination_by`)
  - [ ] **Pattern 6**: Timed pose sequences (`execute_pose_sequence_until`)
  - [ ] **Pattern 7**: Constraint monitoring windows (`monitor_constraints_during`)
  - [ ] **Pattern 8**: Continuous constraint validation (`validate_constraints_continuously`)

- [ ] **EWBIK-Specific Method Types**
  - [ ] `@action` - EWBIK state updates (set effector targets, constraint parameters)
  - [ ] `@command` - Real IK solving execution with convergence handling
  - [ ] `@task_method` - Complex multi-effector coordination workflows
  - [ ] `@unigoal_method` - Single effector target achievement
  - [ ] `@multigoal_method` - EWBIK-specific multi-effector optimization ONLY
  - [ ] Conservative multigoal usage following R25W1398085 guidelines

### Phase 4: EWBIK Test Scenarios (HIGH PRIORITY)

**Priority: HIGH - Comprehensive EWBIK validation scenarios**

- [ ] **glTF Sample Asset Style IK Test Cases**
  - [ ] Create `SimpleIK.gltf` - Basic IK solving validation (similar to SimpleSkin.gltf/SimpleMorph.gltf)
    - [ ] Single bone chain with 3 joints (shoulder → elbow → wrist)
    - [ ] Single IK effector at wrist with position target
    - [ ] Basic Kusudama constraint on elbow joint (simple cone limit)
    - [ ] Embedded glTF with minimal geometry for visual validation
    - [ ] KHR_interactivity behavior for effector target animation
    - [ ] Test convergence with 5-10 iterations maximum
    - [ ] Validate against known analytical IK solution
  - [ ] Create `SimpleIKConstraints.gltf` - Kusudama constraint validation
    - [ ] Two bone chain with shoulder joint constraint visualization
    - [ ] Cone geometry showing valid movement region
    - [ ] Morph targets for constraint violation feedback
    - [ ] Animated effector target that tests constraint boundaries
    - [ ] Visual validation of constraint enforcement vs violation

- [ ] **Multi-Effector Coordination Tests**
  - [ ] Dual-hand reaching with motion propagation
  - [ ] Full-body IK with spine-to-limb influence
  - [ ] Hierarchical effector priority testing
  - [ ] Conflicting target resolution
  - [ ] Weight distribution validation

- [ ] **Kusudama Constraint Validation Tests**
  - [ ] Cone limit enforcement scenarios
  - [ ] Continuous boundary handling
  - [ ] Constraint violation recovery
  - [ ] Soft vs hard constraint boundaries
  - [ ] Twist limit validation

- [ ] **Performance and Convergence Tests**
  - [ ] Iteration limit testing
  - [ ] Convergence criteria validation
  - [ ] Dampening parameter effects
  - [ ] Stabilization pass benefits
  - [ ] Computational budget management

- [ ] **Complex Integration Scenarios**
  - [ ] Real-time constraint solving
  - [ ] Dynamic effector target updates
  - [ ] Temporal IK sequence coordination
  - [ ] Error handling and graceful degradation

### Phase 5: R25W1398085 Specification Validation with EWBIK (CRITICAL)

**Priority: CRITICAL - Core requirement validation with production-quality IK**

- [ ] **Enhanced Method Type Implementation Validation**
  - [ ] `@action` - EWBIK parameter setting (effector targets, weights, constraints)
  - [ ] `@command` - EWBIK solving execution with failure modes
  - [ ] `@task_method` - Complex IK workflow decomposition (full-body coordination)
  - [ ] `@unigoal_method` - Single effector solving (achieve hand position)
  - [ ] `@multigoal_method` - Multi-effector EWBIK coordination ONLY
  - [ ] `@multitodo_method` - Mixed IK and non-IK task handling

- [ ] **EWBIK Entity Resource Management Validation**
  - [ ] Bone resource capability checking (can_be_ik_controlled)
  - [ ] Effector resource conflict detection (multiple targets on same bone)
  - [ ] Constraint resource allocation (Kusudama limit sharing)
  - [ ] Hierarchical resource dependency management
  - [ ] IK solving resource cleanup and state reset

- [ ] **Advanced Temporal Constraint Testing with EWBIK**
  - [ ] IK convergence time constraint validation
  - [ ] Multi-phase IK sequence deadline enforcement
  - [ ] Real-time constraint satisfaction with iteration limits
  - [ ] Temporal dependency resolution in IK chains
  - [ ] Performance degradation handling under time pressure

### Phase 6: Mock AriaGltf Integration (MEDIUM PRIORITY)

**Priority: MEDIUM - Enables immediate testing without full glTF implementation**

- [ ] **Enhanced Mock AriaGltf Modules for EWBIK**
  - [ ] Create `test/support/mock_aria_gltf_ewbik.ex`
  - [ ] Mock AriaGltf.Document with EWBIK skeleton structure
  - [ ] Mock AriaGltf.Scene with bone hierarchy and effector references
  - [ ] Mock AriaGltf.Node with transform data and constraint metadata
  - [ ] Mock AriaGltf.Animation with EWBIK-aware keyframe support

- [ ] **EWBIK-Enhanced Behavior Graph Mock Integration**
  - [ ] Mock KHR_interactivity extension with IK behavior nodes
  - [ ] EWBIK effector target behavior graph integration
  - [ ] Constraint parameter behavior graph control
  - [ ] IK solving trigger and coordination through behavior graphs
  - [ ] Event system integration for IK completion/failure

### Phase 7: Comprehensive Test Suite Implementation (HIGH PRIORITY)

**Priority: HIGH - Comprehensive EWBIK and R25W1398085 validation**

- [ ] **EWBIK Domain Integration Tests**
  - [ ] Create `test/aria_engine_core/ewbik_khr_interactivity_test.exs`
  - [ ] Test all temporal patterns with realistic IK scenarios
  - [ ] Validate EWBIK entity resource management
  - [ ] Test enhanced method type implementations with multi-effector solving

- [ ] **EWBIK Algorithm Validation Tests**
  - [ ] QCP algorithm accuracy tests with known solutions
  - [ ] Multi-effector coordination correctness validation
  - [ ] Kusudama constraint enforcement testing
  - [ ] Motion propagation calculation verification
  - [ ] Performance and convergence behavior testing

- [ ] **Specification Compliance Tests with EWBIK**
  - [ ] R25W1398085 pattern compliance with complex IK scenarios
  - [ ] EWBIK entity capability enforcement testing
  - [ ] Advanced temporal constraint satisfaction with IK solving
  - [ ] Error handling and recovery testing for IK failures

- [ ] **Production-Quality Integration Scenario Tests**
  - [ ] Complex multi-entity EWBIK scenarios
  - [ ] Concurrent multi-effector coordination
  - [ ] Real-time constraint validation with performance limits
  - [ ] Behavior graph execution flow with EWBIK integration

### Phase 8: Documentation and Examples (MEDIUM PRIORITY)

**Priority: MEDIUM - Developer experience and EWBIK adoption**

- [ ] **EWBIK-Enhanced KHR Interactivity Domain Documentation**
  - [ ] Complete EWBIK domain specification document
  - [ ] EWBIK entity and resource documentation
  - [ ] Multi-effector temporal pattern usage examples
  - [ ] Kusudama constraint best practices and common patterns

- [ ] **EWBIK Integration Examples**
  - [ ] Simple IK setup examples with single effectors
  - [ ] Multi-effector coordination examples
  - [ ] Constraint definition and validation examples
  - [ ] Behavior graph integration with EWBIK examples
  - [ ] Error handling and performance optimization examples

- [ ] **EWBIK API Usage Documentation**
  - [ ] AriaEngineCore API usage with EWBIK domain
  - [ ] IK planning and execution workflows
  - [ ] EWBIK debugging and troubleshooting guides
  - [ ] Performance tuning and optimization guides

### Phase 9: Performance and Optimization (LOW PRIORITY)

**Priority: LOW - Performance enhancements after core EWBIK functionality**

- [ ] **EWBIK Performance Benchmarking**
  - [ ] Multi-effector solving performance with complex scenarios
  - [ ] Kusudama constraint checking performance optimization
  - [ ] Memory usage optimization for large bone hierarchies
  - [ ] Concurrent EWBIK execution performance analysis

- [ ] **EWBIK Optimization Implementation**
  - [ ] QCP algorithm optimization for repeated solving
  - [ ] Constraint checking optimization and caching
  - [ ] Memory pool management for IK solving
  - [ ] EWBIK execution pipeline optimization

### Phase 10: Real AriaGltf Integration (FUTURE)

**Priority: FUTURE - After aria_gltf Phase 1 completion**

- [ ] **Replace Mock Modules with Real EWBIK Integration**
  - [ ] Remove mock AriaGltf modules
  - [ ] Integrate with real AriaGltf.Document and skeleton data
  - [ ] Integrate with real AriaGltf.Animation and EWBIK keyframes
  - [ ] Integrate with real behavior graph support for IK coordination

- [ ] **Enhanced KHR Interactivity Support with Real EWBIK**
  - [ ] Full KHR_interactivity extension support with EWBIK nodes
  - [ ] Advanced behavior graph execution with real-time IK solving
  - [ ] Real-time scene manipulation with EWBIK constraint enforcement
  - [ ] Performance optimization with real glTF data and EWBIK integration

## EWBIK Test Domain Specification

### Enhanced KHR Interactivity Test Domain with EWBIK

**Purpose:** Validate R25W1398085 unified durative action specification using production-quality EWBIK multi-effector inverse kinematics with sophisticated constraint handling.

**EWBIK-Enhanced Core Entities (glTF 2.0 Compliant):**

```elixir
# Scene Node Entity - glTF node index (pelvis root bone)
%{
  type: :scene_node,
  id: 0,  # Integer glTF node index (nodes[0] = pelvis)
  capabilities: [:transform, :joint, :ik_target]
}

# Scene Node Entity - glTF node index (left shoulder bone)
%{
  type: :scene_node,
  id: 5,  # Integer glTF node index (nodes[5] = left_shoulder)
  capabilities: [:transform, :joint, :ik_target]
}

# Scene Node Entity - glTF node index (left hand bone)
%{
  type: :scene_node,
  id: 8,  # Integer glTF node index (nodes[8] = left_hand)
  capabilities: [:transform, :joint, :ik_effector]
}

# Skin Entity - glTF skin index for character skinning
%{
  type: :skin,
  id: 0,  # Integer glTF skin index (skins[0] = character_skin)
  capabilities: [:joint_hierarchy, :skinning]
}

# Mesh Entity - glTF mesh index for skinned character
%{
  type: :mesh,
  id: 0,  # Integer glTF mesh index (meshes[0] = character_mesh)
  capabilities: [:skinned_rendering, :morph_targets]
}
```

**EWBIK Configuration in AriaState (Option A - Single Configuration Object):**

```elixir
# EWBIK solver configuration stored in planner state, not entity properties
AriaState.set_fact(state, "character_rig", "ewbik_config", %{
  default_damp: 0.08726646,  # 5 degrees in radians
  iterations_per_frame: 15.0,
  stabilization_passes: 0,
  bone_node_mapping: %{
    # Map semantic bone names to glTF node indices
    "pelvis" => 0,
    "left_shoulder" => 5,
    "left_elbow" => 6,
    "left_wrist" => 7,
    "left_hand" => 8,
    "right_shoulder" => 9,
    "right_elbow" => 10,
    "right_wrist" => 11,
    "right_hand" => 12
  },
  bone_chains: [
    %{name: "left_arm", node_indices: [5, 6, 7, 8]},  # glTF node indices
    %{name: "right_arm", node_indices: [9, 10, 11, 12]},
    %{name: "spine", node_indices: [0, 1, 2, 3, 4]}
  ]
})

# IK effector configuration in planner state
AriaState.set_fact(state, "left_hand_effector", "ik_config", %{
  target_node_index: 8,  # glTF node index for left_hand
  motion_propagation_factor: 0.5,
  target_weight: 1.0,
  priority: :high
})

# Kusudama constraint configuration in planner state
AriaState.set_fact(state, "shoulder_constraint", "kusudama_config", %{
  constrained_node_index: 5,  # glTF node index for left_shoulder
  limit_cones: [
    %{center: [0, 1, 0], radius: 1.57},  # 90 degrees up
    %{center: [1, 0, 0], radius: 0.785}, # 45 degrees forward
    %{center: [0, 0, 1], radius: 1.047}  # 60 degrees right
  ],
  tangent_cones: [
    %{center: [0.707, 0.707, 0], radius: 0.524}  # 30 degrees between up/forward
  ],
  twist_limits: %{min: -1.57, max: 1.57}  # ±90 degrees
})
```

**EWBIK-Enhanced Temporal Patterns (Corrected for R25W1398085):**

1. **Pattern 1 - Instant IK Solving**: 
   ```elixir
   @action true
   def solve_ik_instant(state, [skeleton_id, effector_targets])
   ```

2. **Pattern 2 - Floating Duration IK Solving**: 
   ```elixir
   @action duration: "PT5S"
   def solve_ik_over_time(state, [skeleton_id, start_pose, end_pose])
   ```

3. **Pattern 4 - Deadline-Constrained Reaching**:
   ```elixir
   @action end: "2025-06-29T14:00:00-07:00", duration: "PT2S"
   def reach_target_by_deadline(state, [effector_id, target_transform])
   ```

4. **Pattern 6 - Timed Pose Sequences**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", calculated_end: true
   def execute_coordinated_pose_sequence(state, [skeleton_id, pose_keyframes])
   ```

5. **Pattern 7 - Constraint Monitoring Windows**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", end: "2025-06-29T12:05:00-07:00"
   def monitor_kusudama_constraints(state, [skeleton_id, constraint_set])
   ```

6. **Pattern 8 - Continuous Constraint Validation**:
   ```elixir
   @action start: "2025-06-29T12:00:00-07:00", 
           end: "2025-06-29T12:02:00-07:00", 
           duration: "PT2M"
   def validate_constraints_continuously(state, [skeleton_id, validation_params])
   ```

**EWBIK-Enhanced Method Type Examples:**

```elixir
# @action - EWBIK parameter setting for planning-time reasoning
@doc "Sets effector target state for EWBIK planning"
@action duration: "PT3S", requires_entities: [%{type: :scene_node, capabilities: [:ik_effector]}]
def set_effector_target(state, [effector_node_index, target_pos, target_rot]) do
  state 
  |> AriaState.set_fact(effector_node_index, "effector_target_position", target_pos)
  |> AriaState.set_fact(effector_node_index, "effector_target_orientation", target_rot)
  {:ok, state}
end

# @command - Real EWBIK solving execution with convergence handling
@doc "Executes EWBIK multi-effector solving with failure modes and constraint validation"
@command true  
def solve_multi_effector_command(state, [skeleton_id, effector_targets, constraints]) do
  case AriaEngineCore.EWBIK.Solver.solve_multi_effector(skeleton_id, effector_targets, constraints) do
    {:ok, bone_transforms, convergence_info} ->
      # Apply transforms to actual scene
      result = apply_bone_transforms(skeleton_id, bone_transforms)
      {:ok, Map.put(state, :convergence_info, convergence_info)}
    
    {:error, :constraint_violation, violating_bones} ->
      {:error, {:constraint_violation, violating_bones}}
    
    {:error, :convergence_failure, iterations_used} ->
      {:error, {:convergence_failure, iterations_used}}
    
    {:error, reason} ->
      {:error, reason}
  end
end

# @task_method - Complex multi-effector coordination workflow decomposition
@doc "Decomposes complex full-body IK coordination into manageable EWBIK planning steps"
@task_method true
def coordinate_full_body_ik(state, [skeleton_id, coordination_config]) do
  {:ok, [
    {:register_effectors, [coordination_config.effectors]},
    {:setup_kusudama_constraints, [coordination_config.constraints]},
    {"effector_targets_set", skeleton_id, coordination_config.targets},  # Goal: all targets set
    {:solve_multi_effector_command, [skeleton_id, coordination_config.targets, coordination_config.constraints]},
    {"ik_solution_valid", skeleton_id, true}  # Goal: valid IK solution achieved
  ]}
end

# @unigoal_method - Single effector target achievement through EWBIK
@doc "Achieves specific effector position goals through EWBIK single-effector solving"
@unigoal_method predicate: "effector_target_position"
def achieve_effector_target(state, {effector_node_index, target_position}) do
  # Use EWBIK to solve for single effector while respecting all constraints
  {:ok, [
    {:set_effector_target, [effector_node_index, target_position, :maintain_current_orientation]},
    {:solve_single_effector_command, [effector_node_index, target_position]}
  ]}
end

# @multigoal_method - EWBIK-specific multi-effector optimization (CONSERVATIVE USAGE)
@doc "Optimizes EWBIK multi-effector coordination - ONLY used for genuine EWBIK optimization scenarios"
@multigoal_method true
def optimize_ewbik_coordination(state, multigoal) do
  # ONLY handle if this is specifically an EWBIK multi-effector problem
  ewbik_goals = Enum.filter(multigoal.goals, fn
    {"effector_target_position", _effector_id, _target} -> true
    {"kusudama_constraints_satisfied", _skeleton_id, _constraint_set} -> true
    _ -> false
  end)
  
  cond do
    # Only handle if we have multiple EWBIK effector goals (conservative usage)
    length(ewbik_goals) >= 2 ->
      case AriaEngineCore.EWBIK.Solver.solve_multi_effector_coordinated(state, ewbik_goals) do
        {:ok, optimized_solution} -> 
          {:ok, %{multigoal | goals: optimized_solution}}
        {:error, reason} -> 
          {:error, reason}
      end
    
    # Not our domain - let default solvers handle it
    true ->
      {:error, :not_ewbik_multigoal}
  end
end
```

**EWBIK Test Scenarios (glTF 2.0 Compliant):**

```elixir
# Scenario 1: Dual-hand coordination with motion propagation
multigoal = %AriaEngine.Multigoal{
  goals: [
    {"effector_target_position", 8, [0.3, 1.2, 0.4]},    # glTF node 8 = left_hand
    {"effector_target_position", 12, [-0.3, 1.2, 0.4]},  # glTF node 12 = right_hand
    {"kusudama_constraints_satisfied", "character_rig", "all_joints"}
  ],
  optimization: :minimize_joint_movement
}

# Scenario 2: Hierarchical effector priorities (spine influences arms)
multigoal = %AriaEngine.Multigoal{
  goals: [
    {"effector_target_position", 4, [0, 1.5, 0]},      # glTF node 4 = head (spine effector)
    {"effector_target_position", 8, [0.5, 1.3, 0.2]},  # glTF node 8 = left_hand
    {"motion_propagation_optimized", "character_rig", "hierarchical"}
  ]
}

# Scenario 3: Kusudama constraint testing with violation recovery
goals = [
  {"effector_target_position", 12, impossible_target_position},  # glTF node 12 = right_hand
  {"kusudama_constraint_violation_check", 9, "cone_limits"},     # glTF node 9 = right_shoulder
  {"kusudama_constraint_recovery", 9, "nearest_valid_orientation"}  # glTF node 9 = right_shoulder
]
```

## Success Criteria

### EWBIK Implementation Success

- [ ] QCP algorithm port correctly solves Wahba's problem for optimal rotations
- [ ] IKNode3D hierarchy management handles complex bone chains
- [ ] EWBIK solver achieves multi-effector coordination with realistic constraints
- [ ] Kusudama constraints provide continuous, natural joint limits
- [ ] Motion propagation system creates realistic hierarchical influence

### R25W1398085 Validation Success with EWBIK

- [ ] All 8 temporal patterns implemented and tested with production-quality IK solving
- [ ] All 6 method types (@action, @command, etc.) validated with complex multi-effector scenarios
- [ ] EWBIK entity-based resource management working correctly with bone/effector conflicts
- [ ] Advanced temporal constraints properly enforced with IK convergence considerations
- [ ] Complex multi-entity EWBIK scenarios executing successfully with realistic performance

### Integration Success

- [ ] Mock AriaGltf modules provide sufficient EWBIK functionality for testing
- [ ] Clear migration path to real AriaGltf implementation with EWBIK support
- [ ] Performance acceptable for development and testing of complex IK scenarios
- [ ] Test suite provides comprehensive coverage of EWBIK capabilities

### Documentation Success

- [ ] Clear examples of using AriaEngineCore with EWBIK domain
- [ ] Comprehensive specification compliance documentation with IK integration
- [ ] EWBIK integration patterns documented for other domains
- [ ] Troubleshooting and debugging guides for EWBIK-specific issues

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

**EWBIK Dependencies:**
- **thirdparty/many_bone_ik** - Source for math algorithm ports
- QCP Algorithm (C++ → Elixir port required)
- IKNode3D Transform Hierarchy (C++ → Elixir port required)
- Kusudama Constraint System (C++ → Elixir port required)

**Mock Dependencies (Temporary):**
- Mock AriaGltf.Document - Basic glTF document structure with EWBIK skeleton support
- Mock AriaGltf.Animation - Animation timeline support with EWBIK keyframes
- Mock KHR_interactivity - Behavior graph framework with EWBIK integration

## Implementation Status

- [ ] ✅ AriaEngineCore external API complete and functional
- [ ] 🔄 EWBIK math solver ports - Critical foundation, ready for implementation
- [ ] 🔧 EWBIK algorithm implementation - Depends on math solvers
- [ ] 📋 EWBIK-enhanced KHR Interactivity test domain - Planning complete
- [ ] 🎯 Ready for Phase 1 EWBIK math solver implementation

## Open Problems

### Kusudama Constraint Visualization Challenges

**Problem 1: Cone Geometry Generation Algorithm**
- **Challenge:** Efficiently generate mesh geometry for arbitrary Kusudama cones with varying radii and orientations
- **Unknown:** Optimal tessellation density for smooth cone visualization vs performance
- **Research Needed:** Handling complex tangent cone connections between sequence cones without visual artifacts
- **Edge Case:** Degenerate cone geometries and numerical stability in cone mesh generation

**Problem 2: Constraint Bone Hierarchy Design**
- **Challenge:** Optimal bone structure for skinning constraint shells without interfering with character skeleton
- **Unknown:** Weight distribution strategy for smooth cone deformation under real-time constraint updates
- **Research Needed:** Integration approach with existing character skeleton to avoid bone naming conflicts
- **Performance Concern:** Minimizing bone hierarchy complexity while maintaining visual accuracy

**Problem 3: Morph Target Creation Workflow**
- **Challenge:** Automated generation of constraint state morphs for arbitrary character meshes
- **Unknown:** Optimal number of morph targets vs visual clarity (normal/warning/violation/recovery states)
- **Research Needed:** Temporal smoothing algorithms to avoid jarring visual transitions during constraint state changes
- **Integration Issue:** Compatibility with existing character mesh morph targets and animation systems

**Problem 4: Real-Time Performance Optimization**
- **Challenge:** Balancing constraint visualization quality with real-time performance requirements
- **Unknown:** Optimal LOD switching distances and simplification strategies for constraint shells
- **Research Needed:** Update frequency optimization (when to recalculate vs interpolate constraint states)
- **Memory Concern:** Efficient memory usage for complex multi-joint constraint scenarios with large bone hierarchies

**Problem 5: glTF Integration Architecture**
- **Challenge:** Constraint visualization node hierarchy organization within glTF scene structure
- **Unknown:** Optimal usage pattern for KHR_animation_pointer with real-time constraint updates
- **Research Needed:** Material switching performance for constraint state visualization using KHR_materials_variants
- **Compatibility Issue:** Integration approach with KHR_interactivity behavior graphs for constraint control

**Problem 6: EWBIK-Visualization Coordination**
- **Challenge:** Efficient data flow between Kusudama constraint evaluation and visualization system
- **Unknown:** Synchronization strategy to ensure constraint updates match visual feedback timing
- **Research Needed:** Error handling approaches when constraint evaluation fails or produces invalid results
- **Performance Trade-off:** Real-time constraint checking frequency vs computational cost

**Problem 7: Mathematical Accuracy vs Visual Clarity**
- **Challenge:** Ensuring constraint visualization accurately represents underlying mathematical constraints
- **Unknown:** Validation methodology to verify visual representation matches Kusudama cone mathematics
- **Research Needed:** Test scenarios for complex multi-joint constraint interactions and visual debugging
- **User Experience:** Balancing mathematical precision with intuitive visual understanding

### EWBIK Implementation Open Problems

**Problem 8: QCP Algorithm Numerical Stability**
- **Challenge:** Maintaining numerical precision during QCP characteristic polynomial solving
- **Unknown:** Optimal handling of edge cases in quaternion optimization (near-singular matrices)
- **Research Needed:** Performance vs accuracy trade-offs in iterative QCP solving

**Problem 9: Multi-Effector Convergence Behavior**
- **Challenge:** Ensuring consistent convergence in complex multi-effector scenarios
- **Unknown:** Optimal iteration limits and dampening strategies for different scenarios
- **Research Needed:** Graceful degradation when convergence fails or constraint violations occur

**Problem 10: Constraint Visualization Testing Framework**
- **Challenge:** Comprehensive testing methodology for constraint visualization accuracy
- **Unknown:** Automated validation approaches for visual constraint representation
- **Research Needed:** Performance benchmarking framework for real-time constraint visualization

## Notes

**EWBIK Integration Rationale:** Integrating production-quality EWBIK provides realistic multi-effector inverse kinematics testing that exercises the full complexity of R25W1398085 specification. The sophisticated constraint handling, multi-effector coordination, and hierarchical motion propagation create authentic scenarios for temporal planning validation.

**Math Solver Port Priority:** The QCP algorithm and IKNode3D hierarchy management are critical foundations that must be ported first. Without these mathematical components, EWBIK integration would be superficial mocking rather than authentic production-quality testing.

**Conservative Multigoal Usage:** @multigoal_method usage follows R25W1398085 guidelines, only applied to genuine EWBIK multi-effector optimization scenarios where the mathematical properties of the problem specifically benefit from coordinated solving.

**Mock Strategy Rationale:** Enhanced mock AriaGltf modules with EWBIK support allow immediate R25W1398085 validation with production-quality IK solving without waiting for aria_gltf Phase 1 completion. The mocks provide essential EWBIK structures while maintaining clear migration paths to real implementations.

**Test Domain Enhancement:** EWBIK integration transforms the KHR Interactivity test domain from simple scene management to sophisticated character animation with realistic constraints, providing comprehensive validation of temporal planning with production-quality subsystems.

**Future Integration:** When aria_gltf completes Phase 1, the enhanced mock modules can be seamlessly replaced with real implementations, and the EWBIK domain can be enhanced with full glTF capabilities including real skeleton data and animation timelines.
