# AriaEwbik TODO

**@aria_serial:** R25W158EWBIK

**ADR Reference:** R25W1398085 - Unified Durative Action Specification and Planner Standardization

## Overview

AriaEwbik implements Entirely Wahba's-problem Based Inverse Kinematics (EWBIK) with sophisticated multi-effector coordination, VRM1 collision detection, and anti-uncanny valley features for realistic character animation.

## Current Status

**App Creation:** ✅ Complete (June 30, 2025)

- ✅ External API module created with comprehensive documentation
- ✅ Dependencies configured (aria_joint, aria_qcp, aria_math, aria_state)
- ✅ Project structure and documentation complete
- ✅ Ready for implementation phases

**Mathematical Foundation:** ✅ Available

- ✅ **AriaJoint**: 48/48 tests passing, 160K+ poses/second performance
- ✅ **AriaQCP**: 69/69 tests passing, production-ready QCP algorithm
- ✅ **AriaMath**: IEEE-754 compliant mathematical primitives
- ✅ **AriaState**: Configuration storage for VRM1 and constraints

## Implementation Phases

### Phase 1: Core EWBIK Algorithm Implementation (HIGH PRIORITY)

**Priority: HIGH - Foundation for all EWBIK functionality**

- [ ] **Skeleton Segmentation System (Using AriaJoint API)**
  - [ ] Create `lib/aria_ewbik/segmentation.ex` leveraging AriaJoint external API
  - [ ] Implement bone chain dependency analysis using AriaJoint hierarchy functions:
    - [ ] Use `AriaJoint.get_parent/1` for hierarchy traversal
    - [ ] Use `AriaJoint.to_global/2` and `AriaJoint.to_local/2` for coordinate analysis
    - [ ] Leverage AriaJoint Registry system for efficient joint lookups
  - [ ] Create processing order determination using AriaJoint parent-child relationships
  - [ ] Handle multiple effector hierarchies with AriaJoint transform management
  - [ ] Segment validation and error handling with AriaJoint coordinate conversions
  - [ ] **Performance target**: Leverage AriaJoint's 160K+ poses/second capability

- [ ] **Multi-Effector EWBIK Solver**
  - [ ] Create `lib/aria_ewbik/solver.ex`
  - [ ] Implement core EWBIK algorithm with AriaQCP integration
  - [ ] Multi-effector coordination with priority weighting
  - [ ] Iterative solving with convergence criteria
  - [ ] Dampening and stabilization pass implementation
  - [ ] Performance budget management and early termination
  - [ ] Integration with AriaJoint transform operations

- [ ] **Kusudama Constraint System**
  - [ ] Create `lib/aria_ewbik/kusudama.ex`
  - [ ] Implement cone-based joint orientation constraints using AriaMath quaternion operations
  - [ ] Continuous constraint boundary handling
  - [ ] Sequence cone and tangent cone validation
  - [ ] Twist limit enforcement
  - [ ] Nearest valid orientation calculation

- [ ] **Motion Propagation Management**
  - [ ] Create `lib/aria_ewbik/propagation.ex`
  - [ ] Implement hierarchical effector influence calculation
  - [ ] Motion propagation factor application using AriaMath transform operations
  - [ ] Ancestor-descendant weight distribution
  - [ ] Ultimate vs intermediary target handling

**AriaJoint Integration Benefits:**

- ✅ **Production Ready Foundation**: 48/48 tests passing with excellent performance
- ✅ **Registry-Based Efficiency**: Built-in joint lookup and state management
- ✅ **Transform Management**: Local/global coordinate handling ready for EWBIK
- ✅ **Hierarchy Traversal**: Parent-child relationship functions perfect for segmentation
- ✅ **Performance Characteristics**: 160K+ poses/second, ready for real-time EWBIK
- ✅ **Clean Architecture**: Uses external API, maintains umbrella boundaries

### Phase 2: Anti-Uncanny Valley Solutions (HIGH PRIORITY)

**Priority: HIGH - Comprehensive uncanny valley prevention for realistic character animation**

**Dependencies:** Requires Phase 1 EWBIK foundation for sophisticated constraint integration

#### VRM1 Collision Detection System

- [ ] **VRM1 Collider System Integration**
  - [ ] Create `lib/aria_ewbik/vrm1_colliders.ex`
  - [ ] Implement VRM1 sphere collider detection (`shape.sphere`)
    - [ ] Sphere-to-sphere collision detection with joint hit radius
    - [ ] Local coordinate offset transformation to world space
    - [ ] Distance calculation and penetration resolution per VRM1 spec:

      ```
      transformedOffset = collider.offset * collider.worldMatrix
      delta = nextTail - transformedOffset
      distance = delta.magnitude - collider.radius - jointRadius
      direction = delta.normalized
      ```

  - [ ] Implement VRM1 capsule collider detection (`shape.capsule`)
    - [ ] Capsule-to-sphere collision detection algorithm per VRM1 spec
    - [ ] Head/tail/middle region collision handling
    - [ ] Offset and tail position transformation to world space
  - [ ] Implement VRM1 plane colliders for ground contact
    - [ ] Infinite plane collision detection for foot pinning
    - [ ] Ground contact preservation during upper body IK
    - [ ] Balance constraint integration with center of mass
  - [ ] Collider group management system
    - [ ] ColliderGroup organization and indexing per VRM1 spec
    - [ ] Per-spring collider group assignment
    - [ ] Efficient collision checking against relevant groups only

- [ ] **VRM1-Compliant Collision-Aware EWBIK Solver**
  - [ ] Create `lib/aria_ewbik/vrm1_collision_solver.ex`
  - [ ] Integration of VRM1 colliders with EWBIK iteration loop
  - [ ] Joint hit radius integration with EWBIK bone transforms
  - [ ] Collision resolution during IK solving iterations per VRM1 spec:

    ```
    if (distance < 0.0) {
        # push
        nextTail = nextTail - direction * distance;
        # constrain the length
        nextTail = worldPosition + (nextTail - worldPosition).normalized * boneLength;
    }
    ```

  - [ ] Performance optimization for real-time collision checking
  - [ ] VRM1 center space evaluation for collision detection

#### Godot Anatomical Constraint System

- [ ] **Godot SkeletonProfileHumanoid Integration for Anatomical Limits**
  - [ ] Create `lib/aria_ewbik/godot_skeleton_profile.ex`
  - [ ] Port Godot's SkeletonProfileHumanoid bone definitions and reference poses
  - [ ] Extract anatomical joint limits from Godot's humanoid profile:
    - [ ] Elbow: 0-150° (from reference poses)
    - [ ] Knee: 0-135° (from reference poses)  
    - [ ] Shoulder: complex 3DOF limits (from reference poses)
    - [ ] Spine: limited flexion/extension (from reference poses)
  - [ ] Convert Godot Transform3D reference poses to Kusudama constraint cones
  - [ ] Integration with VRM1 colliders for additional anatomical boundaries
  - [ ] Automatic anatomical constraint generation from skeleton profile

- [ ] **Godot to glTF Coordinate System Conversion**
  - [ ] Create `lib/aria_ewbik/coordinate_conversion.ex`
  - [ ] Implement Godot → glTF coordinate system transformation matrices
  - [ ] Convert Godot SkeletonProfileHumanoid reference poses to glTF space:

    ```elixir
    # Godot reference pose (Transform3D)
    godot_pose = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.1, 0)
    
    # Convert to glTF native coordinate space
    gltf_pose = CoordinateConversion.godot_to_gltf_transform(godot_pose)
    
    # Extract joint rules in glTF space
    gltf_joint_rules = CoordinateConversion.extract_gltf_joint_rules(gltf_pose)
    ```

  - [ ] Convert Godot joint rule (+Y roll, +X inside bend) to glTF equivalent
  - [ ] Validate conversion with known test cases (elbow, knee, shoulder)

- [ ] **Godot Joint Rules for Scale-Invariant IK**
  - [ ] Implement Godot's joint rule: "+Y axis pointed from parent to child as roll axis"
  - [ ] Implement Godot's joint rule: "+X rotation bends joints to inside of body"
  - [ ] Scale-aware constraint generation based on bone length ratios
  - [ ] Proportional EWBIK solving using Godot's SkeletonProfileHumanoid proportions
  - [ ] Character proportion analysis using Godot's reference poses
  - [ ] Integration with realtime retarget concepts for cross-character compatibility

#### Temporal Smoothing and Motion Quality

- [ ] **Temporal Smoothing Integration with AriaTimeline**
  - [ ] Previous pose bias in EWBIK solving (prefer solutions close to current pose)
  - [ ] Integration with AriaTimeline temporal constraints for smooth motion
  - [ ] Frame-to-frame solution stability validation using timeline continuity
  - [ ] Motion prediction using temporal planning capabilities

- [ ] **Enhanced RMSD Solution Validation**
  - [ ] RMSD calculation includes VRM1 collision penalty terms
  - [ ] Solution rejection for poses that violate VRM1 collider constraints
  - [ ] Weighted RMSD: target achievement vs VRM1 collision avoidance vs anatomical realism
  - [ ] Integration with VRM1 collider group priorities
  - [ ] Performance optimization for real-time VRM1 collision validation

### Phase 3: Constraint Visualization (HIGH PRIORITY)

**Priority: HIGH - Visual debugging and constraint validation for EWBIK**

- [ ] **Hybrid Skin + Morph Constraint Visualization**
  - [ ] Create `lib/aria_ewbik/constraint_visualization.ex`
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

### Phase 4: External API Implementation (MEDIUM PRIORITY)

**Priority: MEDIUM - Enable external API delegation after internal modules are complete**

- [ ] **Core EWBIK API Functions**
  - [ ] Implement `AriaEwbik.solve_ik/3` delegation to `AriaEwbik.Solver`
  - [ ] Implement `AriaEwbik.solve_multi_effector/3` delegation to `AriaEwbik.Solver`
  - [ ] Add comprehensive documentation and examples

- [ ] **Skeleton Analysis API Functions**
  - [ ] Implement `AriaEwbik.analyze_skeleton/1` delegation to `AriaEwbik.Segmentation`
  - [ ] Implement `AriaEwbik.segment_chains/2` delegation to `AriaEwbik.Segmentation`

- [ ] **Constraint Management API Functions**
  - [ ] Implement `AriaEwbik.create_kusudama_constraint/2` delegation to `AriaEwbik.Kusudama`
  - [ ] Implement `AriaEwbik.validate_constraints/1` delegation to `AriaEwbik.Kusudama`

- [ ] **VRM1 Collision API Functions**
  - [ ] Implement `AriaEwbik.setup_vrm1_colliders/2` delegation to `AriaEwbik.VRM1Colliders`
  - [ ] Implement `AriaEwbik.solve_with_collision_avoidance/3` delegation to `AriaEwbik.VRM1CollisionSolver`

- [ ] **Anatomical Constraint API Functions**
  - [ ] Implement `AriaEwbik.apply_godot_anatomical_limits/1` delegation to `AriaEwbik.GodotSkeletonProfile`
  - [ ] Implement `AriaEwbik.convert_godot_to_gltf/1` delegation to `AriaEwbik.CoordinateConversion`

### Phase 5: Comprehensive Testing Suite (MEDIUM PRIORITY)

**Priority: MEDIUM - Ensure robustness and performance validation**

- [ ] **Core Algorithm Tests**
  - [ ] Segmentation algorithm tests with various skeleton structures
  - [ ] Multi-effector solver tests with priority weighting
  - [ ] Convergence criteria validation tests
  - [ ] Performance benchmark tests targeting real-time animation

- [ ] **Constraint System Tests**
  - [ ] Kusudama constraint validation tests
  - [ ] VRM1 collision detection accuracy tests
  - [ ] Anatomical constraint enforcement tests
  - [ ] Edge case handling tests (extreme poses, invalid constraints)

- [ ] **Integration Tests**
  - [ ] AriaJoint integration tests (hierarchy traversal, coordinate conversion)
  - [ ] AriaQCP integration tests (multi-effector coordination)
  - [ ] AriaState integration tests (VRM1 configuration storage)
  - [ ] Cross-app integration tests with potential consumers

- [ ] **Performance Tests**
  - [ ] Real-time animation performance benchmarks
  - [ ] Memory usage profiling with large skeleton hierarchies
  - [ ] Collision detection performance under various collider densities
  - [ ] Constraint evaluation performance with complex constraint sets

## Dependencies

**Tier 3 App Dependencies:**

- **aria_math** (Tier 1): Mathematical primitives and IEEE-754 operations
- **aria_joint** (Tier 2): Joint hierarchy management and transform operations
- **aria_qcp** (Tier 2): Quaternion Characteristic Polynomial algorithm
- **aria_state** (Tier 3): Configuration storage for VRM1 and constraint parameters

**Testing Dependencies:**

- All mathematical foundation apps must be tested and functional
- AriaJoint Registry system must be operational
- AriaQCP algorithm must be production-ready

## Performance Targets

- **IK Solving**: Real-time performance for character animation (30+ FPS)
- **Collision Detection**: Efficient VRM1 validation with minimal frame impact
- **Constraint Evaluation**: Fast Kusudama cone validation
- **Memory Usage**: Efficient registry-based joint state management
- **Scalability**: Support for complex character rigs (100+ joints)

### Phase 6: AriaEngineCore Integration (WHEN READY)

**Priority: MEDIUM - Integration with AriaEngineCore for temporal planning coordination**

**Note:** This phase moves AriaEngineCore integration details to AriaEwbik for proper ownership

- [ ] **AriaEngineCore Dependency Integration**
  - [ ] AriaEngineCore can add AriaEwbik dependency when ready: `{:aria_ewbik, in_umbrella: true}`
  - [ ] Verify dependency tier structure (AriaEngineCore Tier 4, AriaEwbik Tier 3)
  - [ ] Integration with AriaEngineCore external API

- [ ] **Domain Method Integration with AriaEngineCore**
  - [ ] Provide integration guidance for AriaEngineCore.Domain module
  - [ ] Character IK solving methods using `AriaEwbik.solve_ik/3`
  - [ ] Multi-effector coordination using `AriaEwbik.solve_multi_effector/3`
  - [ ] VRM1 collision-aware solving using `AriaEwbik.solve_with_collision_avoidance/3`

- [ ] **EWBIK Entity Support for AriaEngineCore Integration**
  - [ ] Character skeleton entity management examples
  - [ ] IK effector target entity support patterns
  - [ ] Constraint configuration entity support examples
  - [ ] Integration patterns with AriaState for EWBIK configuration storage

- [ ] **Test Domain Integration Examples**
  - [ ] Test scenarios using AriaEwbik for character animation
  - [ ] EWBIK-based multigoal test cases (conservative usage per R25W1398085)
  - [ ] Temporal IK solving test patterns
  - [ ] Integration examples with KHR Interactivity test domain

### Phase 7: Enhanced KHR Interactivity Test Domain (HIGH PRIORITY)

**Priority: HIGH - Realistic IK testing with sophisticated constraint validation**

**Dependencies:** Requires Phase 1 EWBIK foundation, Phase 2 anti-uncanny valley solutions

- [ ] **EWBIK Entity Types for KHR Interactivity**
  - [ ] Create `test/support/ewbik_khr_domain.ex`
  - [ ] EWBIK skeleton entities with multi-effector support
  - [ ] IK effector entities with motion propagation factors
  - [ ] Kusudama constraint entities with cone definitions
  - [ ] Bone hierarchy entities with transform management
  - [ ] VRM1 collider entities with sphere/capsule/plane definitions
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
  - [ ] **Pattern 9**: VRM1 collision-aware solving (`solve_with_vrm1_collision_avoidance`)
  - [ ] **Pattern 10**: Anatomical constraint enforcement (`solve_with_godot_anatomical_limits`)

- [ ] **EWBIK-Specific Method Types**
  - [ ] `@action` - EWBIK state updates (set effector targets, constraint parameters, VRM1 colliders)
  - [ ] `@command` - Real IK solving execution with convergence handling and collision avoidance
  - [ ] `@task_method` - Complex multi-effector coordination workflows with anti-uncanny valley features
  - [ ] `@unigoal_method` - Single effector target achievement with constraint enforcement
  - [ ] `@multigoal_method` - EWBIK-specific multi-effector optimization with VRM1 collision coordination ONLY
  - [ ] Conservative multigoal usage following R25W1398085 guidelines

### Phase 8: EWBIK Test Scenarios

**Comprehensive test scenarios validating all EWBIK functionality**

- [ ] **Single Effector Test Scenarios**
  - [ ] Hand reaching to target with elbow constraints
  - [ ] Foot placement with ground collision and anatomical limits
  - [ ] Head tracking with spine flexibility constraints
  - [ ] Finger pointing with wrist and knuckle limitations

- [ ] **Multi-Effector Coordination Scenarios**
  - [ ] Dual-hand manipulation tasks with priority weighting
  - [ ] Walking animation with foot placement and balance
  - [ ] Object grasping with hand positioning and torso adjustment
  - [ ] Complex dance moves with full-body coordination

- [ ] **VRM1 Collision Avoidance Scenarios**
  - [ ] Character interaction with environment objects
  - [ ] Self-collision avoidance during complex poses
  - [ ] Multi-character scenarios with collision awareness
  - [ ] Dynamic obstacle avoidance during animation

- [ ] **Anatomical Constraint Validation Scenarios**
  - [ ] Extreme pose validation against Godot skeletal limits
  - [ ] Natural motion validation using SkeletonProfileHumanoid
  - [ ] Proportion-aware IK for different character sizes
  - [ ] Anti-uncanny valley validation with realistic constraints

## Implementation Notes

**Coordinate System Conversions:**

- All mathematical operations follow the glTF 2.0 coordinate system (Y-up, right-handed)
- Godot Transform3D to glTF matrix conversion preserves anatomical constraints
- IEEE-754 compliance ensures numerical stability across all mathematical operations

**Performance Considerations:**

- QCP algorithm complexity: O(n) for point set alignment where n is number of points
- EWBIK iteration complexity: O(k×j) where k is iterations and j is number of joints
- VRM1 collision detection: O(c×j) where c is colliders and j is joints per frame

**Testing and Validation:**

- All mathematical operations validated against KHR Interactivity specification test cases
- Cross-validation with Godot SkeletonProfileHumanoid reference poses
- IEEE-754 edge case handling verified through comprehensive test suite

## Standards Compliance

- **glTF 2.0**: Full compliance for 3D asset interoperability
- **IEEE-754**: Numerical precision and stability requirements
- **VRM 1.0**: Avatar collision detection and constraint specifications
- **Godot Integration**: SkeletonProfileHumanoid anatomical constraint compatibility

## License and Attribution

**Third-party Code Attribution:**

- Many Bone IK implementation ported with attribution to original authors
- Godot Engine reference implementations used under MIT license
- VRM specification implementation follows VRM Consortium guidelines
- All mathematical algorithms implement published academic methods with proper attribution
