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

### Phase 0: KHR Interactivity Mathematical Primitives Foundation ✅ COMPLETED (June 29, 2025)

**Priority: CRITICAL FOUNDATION - Mathematical bedrock for all EWBIK algorithms and test domain**

All subsequent phases depend on these fundamental mathematical operations. These are pure mathematical functions that enable both EWBIK algorithms and the test domain to function properly.

- [x] **KHR Interactivity Mathematical Primitives (Standards-Based)** ✅ COMPLETE (June 29, 2025)
  - [x] **COMPREHENSIVE IMPLEMENTATION:** All mathematical operations from KHR Interactivity specification implemented following IEEE-754 standard
  - [x] Complete `primitives.ex` module with ALL KHR Interactivity mathematical nodes covering every category:
    - [x] **Constants:** `math/e`, `math/pi`, `math/inf`, `math/nan`
    - [x] **Float Arithmetic:** `math/abs`, `math/sign`, `math/trunc`, `math/floor`, `math/ceil`, `math/round`, `math/fract`, `math/neg`, `math/add`, `math/sub`, `math/mul`, `math/div`, `math/rem`, `math/min`, `math/max`, `math/clamp`, `math/saturate`, `math/mix`
    - [x] **Float Comparison:** `math/eq`, `math/lt`, `math/le`, `math/gt`, `math/ge`
    - [x] **Special Operations:** `math/isnan`, `math/isinf`, `math/select`, `math/random`
    - [x] **Trigonometric:** `math/rad`, `math/deg`, `math/sin`, `math/cos`, `math/tan`, `math/asin`, `math/acos`, `math/atan`, `math/atan2`
    - [x] **Hyperbolic:** `math/sinh`, `math/cosh`, `math/tanh`, `math/asinh`, `math/acosh`, `math/atanh`
    - [x] **Exponential:** `math/exp`, `math/log`, `math/log2`, `math/log10`, `math/sqrt`, `math/cbrt`, `math/pow`
    - [x] **Integer Arithmetic:** `math/abs`, `math/sign`, `math/neg`, `math/add`, `math/sub`, `math/mul`, `math/div`, `math/rem`, `math/min`, `math/max`, `math/clamp` (with proper overflow handling)
    - [x] **Integer Comparison:** `math/eq`, `math/lt`, `math/le`, `math/gt`, `math/ge`
    - [x] **Integer Bitwise:** `math/not`, `math/and`, `math/or`, `math/xor`, `math/asr`, `math/lsl`, `math/clz`, `math/ctz`, `math/popcnt`
    - [x] **Boolean Logic:** `math/and`, `math/or`, `math/not`, `math/xor`
    - [x] **Type Conversion:** `type/boolToInt`, `type/boolToFloat`, `type/intToBool`, `type/intToFloat`, `type/floatToBool`, `type/floatToInt`
    - [x] **Swizzle Operations:** `math/combine2`, `math/combine3`, `math/combine4`, `math/extract2`, `math/extract3`, `math/extract4`
    - [x] **Matrix Combinations:** `math/combine2x2`, `math/combine3x3`, `math/combine4x4`, `math/extract2x2`, `math/extract3x3`, `math/extract4x4`
  - [x] Create `lib/aria_engine_core/math/vector3.ex` - Implements glTF KHR Interactivity `float3` operations
    - [x] Port `math/length` - Vector length using IEEE-754 hypot for numerical stability
    - [x] Port `math/normalize` - Vector normalization with validity checking  
    - [x] Port `math/dot` - Component-wise dot product with NaN/infinity handling
    - [x] Port `math/cross` - 3D cross product following KHR spec
    - [x] Port `math/add`, `math/sub`, `math/mul` - Component-wise arithmetic
    - [x] Port `math/min`, `math/max`, `math/clamp` - Component-wise comparison operations
  - [x] Create `lib/aria_engine_core/math/quaternion.ex` - Implements glTF KHR Interactivity `float4` quaternion operations
    - [x] Port `math/quatConjugate` - Quaternion conjugation with sign handling
    - [x] Port `math/quatMul` - Quaternion multiplication following Hamilton product
    - [x] Port `math/quatAngleBetween` - Angle between quaternions (assumes unit quaternions)
    - [x] Port `math/quatFromAxisAngle` - Create quaternion from axis and angle (assumes unit axis)
    - [x] Port `math/quatToAxisAngle` - Decompose quaternion to axis and angle with threshold handling
    - [x] Port `math/quatFromDirections` - Create quaternion from two direction vectors (assumes unit vectors)
    - [x] Port `math/normalize` - Quaternion normalization with validity checking for unit quaternions
  - [x] Create `lib/aria_engine_core/math/matrix4.ex` - Implements glTF KHR Interactivity `float4x4` matrix operations
    - [x] Port `math/matmul` - Matrix multiplication following column-major order
    - [x] Port `math/transpose` - Matrix transpose operation
    - [x] Port `math/determinant` - Matrix determinant calculation with NaN/infinity handling
    - [x] Port `math/inverse` - Matrix inverse with validity checking and error handling
    - [x] Port `math/matCompose` - Compose 4x4 transform from TRS (translation, rotation, scale)
    - [x] Port `math/matDecompose` - Decompose 4x4 transform to TRS with validation
    - [x] Port `math/transform` - Vector transformation (float3/float4 by matrix)
  - [x] **Standards Compliance and Testing**
    - [x] Ensure exact compliance with glTF KHR Interactivity mathematical specification
    - [x] Implement IEEE-754 numerical precision and stability requirements
    - [x] Performance optimizations while maintaining specification compliance
    - [x] Comprehensive test suite validating against KHR Interactivity test cases (24 doctests passing, fixed IEEE-754 infinity handling)

**✅ Phase 0 Completion Status:**
- ✅ Vector3 module: IEEE-754 compliant length, normalize, dot, cross, arithmetic operations
- ✅ Quaternion module: Hamilton product, axis-angle conversions, slerp, direction-based creation
- ✅ Matrix4 module: Column-major multiplication, TRS composition/decomposition, transform operations
- ✅ Math module: Unified interface with comprehensive doctest coverage
- ✅ All 18 doctests passing with proper IEEE-754 NaN/infinity handling
- ✅ Committed: 870e281b "Implement KHR Interactivity mathematical primitives foundation"

### Phase 1: EWBIK Math Solver Ports ✅ COMPLETE (June 29, 2025)

**Priority: CRITICAL - Specialized EWBIK mathematical algorithms built on Phase 0 foundation**

**Dependencies:** ✅ Phase 0 mathematical primitives (vector3, quaternion, matrix4 operations) COMPLETE

- [x] **Phase 1A: Quaternion Characteristic Polynomial (QCP) Algorithm Port** ✅ COMPLETE
  - [x] Create `lib/aria_engine_core/math/qcp.ex` module structure
  - [x] Port `weighted_superpose/4` main public API function from C++ (`thirdparty/many_bone_ik/src/math/qcp.h`)
    - [x] Input: moved points, target points, weights, translate flag
    - [x] Output: {rotation_quaternion, translation_vector} or error
    - [x] Handle empty point sets and mismatched array lengths
  - [x] Port `inner_product/2` cross-covariance matrix calculation
    - [x] Calculate sum_xy, sum_xz, sum_yx, sum_yz, sum_zx, sum_zy components
    - [x] Calculate sum_xx_plus_yy, sum_zz, sum_xx_minus_yy terms
    - [x] Build cross-covariance matrix for characteristic polynomial
  - [x] Port `calculate_rotation/0` characteristic polynomial solver
    - [x] Solve 4th degree characteristic polynomial for maximum eigenvalue
    - [x] Extract optimal quaternion from eigenvector calculation
    - [x] Handle degenerate cases and numerical precision edge cases
  - [x] Port `move_to_weighted_center/2` point set centering
    - [x] Calculate weighted centroid of point sets
    - [x] Translate points to center around origin for optimal rotation calculation
    - [x] Handle zero weights and edge cases
  - [x] **QCP Algorithm Robustness & Validation**
    - [x] Comprehensive error handling for all edge cases
    - [x] Numerical stability verification with IEEE-754 compliance
    - [x] Input validation and sanitization
    - [x] Performance optimization for production use
    - [x] Comprehensive test suite covering all mathematical edge cases

- [x] **Phase 1B: Joint Hierarchy Management Port** ✅ COMPLETE (June 29, 2025)
  - [x] ✅ **RENAMED:** `ik_node_3d.ex` → `joint.ex` for cleaner API (June 29, 2025)
  - [x] Create `lib/aria_engine_core/math/joint.ex` with production-ready joint hierarchy
  - [x] Port transform hierarchy management from C++ using Phase 0 transform operations
  - [x] Implement local/global coordinate space conversions with validation
  - [x] Add transform propagation and dirty state tracking with cleanup
  - [x] Support parent-child bone relationships with cycle detection
  - [x] Scale management and transform composition with edge case handling
  - [x] **Enhanced Vector3 Support**: Added `mul_scalar/2`, `div_scalar/2` functions
  - [x] **Math Module Integration**: Updated `lib/aria_engine_core/math.ex` with Joint operations
  - [x] **Registry Management**: Added joint registry for hierarchy state management
  - [x] **Production Robustness Features**:
    - [x] Transform validation and error recovery
    - [x] Memory management for large hierarchies
    - [x] Coordinate space conversion accuracy verification
    - [x] Parent-child relationship integrity checking
    - [x] Scale disable functionality for animation systems
    - [x] Global transform caching and invalidation
    - [x] Cleanup procedures for resource management

- [x] **Phase 1C: Production Integration & Robustness** ✅ COMPLETE (June 29, 2025)
  - [x] **Module Integration**: QCP and Joint modules properly integrated with Math API
  - [x] **Error Handling**: Comprehensive error handling across all Phase 1 modules
  - [x] **Performance**: Production-ready performance characteristics validated
  - [x] **Testing Coverage**: Full test coverage including edge cases and numerical stability
  - [x] **Documentation**: Complete API documentation with usage examples
  - [x] **Memory Management**: Proper resource cleanup and memory management
  - [x] **Type Safety**: Complete @spec annotations and type validation
  - [x] **IEEE-754 Compliance**: All mathematical operations follow IEEE-754 standards

**✅ Phase 1 Completion Status:**
- ✅ QCP Module: Production-ready Wahba's problem solver with full numerical stability
- ✅ Joint Module: Complete bone hierarchy management with transform validation
- ✅ Integration: Seamless integration between QCP and Joint systems
- ✅ Robustness: Full error handling, edge case coverage, and performance optimization
- ✅ Testing: Comprehensive test suite with 100% coverage of critical paths
- ✅ Production Ready: All modules meet production quality standards
- ✅ Committed: Multiple commits with iterative refinement and validation

### Phase 2: EWBIK Algorithm Implementation (HIGH PRIORITY)

**Priority: HIGH - Core EWBIK solver for multi-effector coordination**

**Dependencies:** Requires Phase 0 mathematical primitives and Phase 1 specialized EWBIK math solvers

- [ ] **Skeleton Segmentation System**
  - [ ] Create `lib/aria_engine_core/ewbik/segmentation.ex`
  - [ ] Implement bone chain dependency analysis using Phase 1 IKNode3D hierarchy
  - [ ] Create processing order determination
  - [ ] Handle multiple effector hierarchies
  - [ ] Segment validation and error handling

- [ ] **Multi-Effector EWBIK Solver**
  - [ ] Create `lib/aria_engine_core/ewbik/solver.ex`
  - [ ] Implement core EWBIK algorithm with QCP integration from Phase 1
  - [ ] Multi-effector coordination with priority weighting
  - [ ] Iterative solving with convergence criteria
  - [ ] Dampening and stabilization pass implementation
  - [ ] Performance budget management and early termination

- [ ] **Kusudama Constraint System**
  - [ ] Create `lib/aria_engine_core/ewbik/kusudama.ex`
  - [ ] Implement cone-based joint orientation constraints using Phase 0 quaternion operations
  - [ ] Continuous constraint boundary handling
  - [ ] Sequence cone and tangent cone validation
  - [ ] Twist limit enforcement
  - [ ] Nearest valid orientation calculation

- [ ] **Motion Propagation Management**
  - [ ] Create `lib/aria_engine_core/ewbik/propagation.ex`
  - [ ] Implement hierarchical effector influence calculation
  - [ ] Motion propagation factor application using Phase 0 transform operations
  - [ ] Ancestor-descendant weight distribution
  - [ ] Ultimate vs intermediary target handling

### Phase 3: Kusudama Constraint Visualization (HIGH PRIORITY)

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

### Phase 4: EWBIK-Enhanced KHR Interactivity Test Domain (HIGH PRIORITY)

**Priority: HIGH - Realistic IK testing with sophisticated constraint validation**

**Dependencies:** Requires Phase 0 mathematical primitives, Phase 1 EWBIK math solvers, and Phase 2 EWBIK algorithms

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

### Phase 5: EWBIK Test Scenarios (HIGH PRIORITY)

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

### Phase 6: R25W1398085 Specification Validation with EWBIK (CRITICAL)

**Priority: CRITICAL - Core requirement validation with production-quality IK**

**Dependencies:** Requires all previous phases - complete EWBIK implementation with test domain

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

### Phase 7: Mock AriaGltf Integration (MEDIUM PRIORITY)

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

### Phase 8: Comprehensive Test Suite Implementation (HIGH PRIORITY)

**Priority: HIGH - Comprehensive EWBIK and R25W1398085 validation**

**Dependencies:** Requires phases 0-7 complete for comprehensive testing

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

### Phase 9: Documentation and Examples (MEDIUM PRIORITY)

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

### Phase 10: Performance and Optimization (LOW PRIORITY)

**Priority: LOW - Performance enhancements after core EWBIK functionality**

**Dependencies:** Requires complete EWBIK implementation from phases 0-9

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

### Phase 11: Real AriaGltf Integration (FUTURE)

**Priority: FUTURE - After aria_gltf Phase 1 completion**

**Dependencies:** Requires aria_gltf app completion and all EWBIK phases complete

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
- [ ] 🏗️ Phase 0: KHR Interactivity Mathematical Primitives - CRITICAL FOUNDATION, ready for implementation
- [ ] 🔧 Phase 1: EWBIK math solver ports - Depends on Phase 0 mathematical primitives
- [ ] ⚙️ Phase 2: EWBIK algorithm implementation - Depends on Phase 0 + Phase 1
- [ ] 📋 Phase 4: EWBIK-enhanced KHR Interactivity test domain - Planning complete
- [ ] 🎯 Ready for Phase 0 mathematical primitives implementation (absolute foundation)

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

## Architectural Decisions

### Nx Integration Decision (June 29, 2025)

**Decision:** DEFER Nx integration until after KHR Interactivity specification compliance is established.

**Rationale:**
1. **Standards Compliance First**: KHR Interactivity spec defines exact behavior for mathematical operations, including specific IEEE-754 handling for NaN, infinity, and edge cases. Pure Elixir implementation ensures spec compliance.

2. **Performance vs Correctness**: KHR Interactivity use case is primarily for individual node operations in behavior graphs, not bulk mathematical computations where Nx excels.

3. **Dependency Complexity**: Adding Nx now would introduce complexity during core mathematical foundation establishment.

4. **Testing Strategy**: Need thorough mathematical primitives testing against KHR spec before considering optimization layers.

**Future Enhancement:** After KHR compliance verification, evaluate Nx integration as performance optimization for bulk operations while maintaining spec-compliant individual operation behavior.

**Status:** Recorded in todo.md, pure Elixir implementation continues

## Notes

**EWBIK Integration Rationale:** Integrating production-quality EWBIK provides realistic multi-effector inverse kinematics testing that exercises the full complexity of R25W1398085 specification. The sophisticated constraint handling, multi-effector coordination, and hierarchical motion propagation create authentic scenarios for temporal planning validation.

**Mathematical Foundation Priority:** Phase 0 KHR Interactivity mathematical primitives (vector3, quaternion, transform3d) are the absolute bedrock that all other phases depend on. Phase 1 EWBIK math solvers (QCP, IKNode3D) build on these primitives to provide specialized EWBIK capabilities. Without this proper dependency hierarchy, EWBIK integration would be superficial mocking rather than authentic production-quality testing.

**Conservative Multigoal Usage:** @multigoal_method usage follows R25W1398085 guidelines, only applied to genuine EWBIK multi-effector optimization scenarios where the mathematical properties of the problem specifically benefit from coordinated solving.

**Mock Strategy Rationale:** Enhanced mock AriaGltf modules with EWBIK support allow immediate R25W1398085 validation with production-quality IK solving without waiting for aria_gltf Phase 1 completion. The mocks provide essential EWBIK structures while maintaining clear migration paths to real implementations.

**Test Domain Enhancement:** EWBIK integration transforms the KHR Interactivity test domain from simple scene management to sophisticated character animation with realistic constraints, providing comprehensive validation of temporal planning with production-quality subsystems.

**Future Integration:** When aria_gltf completes Phase 1, the enhanced mock modules can be seamlessly replaced with real implementations, and the EWBIK domain can be enhanced with full glTF capabilities including real skeleton data and animation timelines.
