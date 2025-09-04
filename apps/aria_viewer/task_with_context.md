### 1. Current Work

We are implementing a comprehensive real-time IK (Inverse Kinematics) solver system as part of the `aria-character-core` project. This includes both a Phoenix WebSocket backend for IK computation and a Three.js frontend for interactive 3D testing. The system will use existing skeleton proxy infrastructure, temporal planning, and support drag-and-drop VRM model loading for flexible testing. Pose transitions will be smoothed using the 1 euro filter algorithm.

### 2. Key Technical Concepts

- **Phoenix WebSocket Channels**: Real-time bidirectional communication for IK target updates and pose broadcasting
- **Inverse Kinematics (IK)**: Mathematical algorithm for calculating joint positions to reach target positions
- **Temporal Planning**: Using `AriaHybridPlanner` for smooth pose transitions with duration constraints
- **1 Euro Filter**: Real-time signal filtering algorithm for smooth pose interpolation
- **Skeleton Proxy Infrastructure**: Leveraging existing `AriaJoint.HierarchyManager` and `AriaGltf.Skin` for optimized joint hierarchy management
- **VRM Standard**: Following VRM humanoid bone naming conventions
- **Nested Set Optimization**: Using `AriaJoint.HierarchyManager` for 26x faster pose calculations
- **VRM Model Loading**: Loading and parsing VRM files using `AriaGltf` for real skeleton testing
- **Three.js Integration**: 3D frontend for VRM model display, bone selection, and interactive testing
- **Drag & Drop File Loading**: HTML5 drag and drop for loading custom VRM models
- **Architectural Decision Records**: Documenting design choices and rationale

### 3. Relevant Files and Code

**Existing Infrastructure:**

- `apps/aria_joint/lib/aria_joint/hierarchy_manager.ex`: Optimized hierarchy manager with nested set model
- `apps/aria_joint/lib/aria_joint/joint.ex`: Transform hierarchy management with parent-child relationships
- `apps/aria_gltf/lib/aria_gltf/skin.ex`: Skinning functionality with joint hierarchy support
- `apps/aria_gltf/lib/aria_gltf.ex`: VRM/glTF file loading and parsing
- `apps/aria_interactivity/lib/aria_interactivity/temporal.ex`: Temporal constraints and ISO 8601 duration parsing

**Test Models:**

- `VRM1_Constraint_Twist_Sample.vrm`: Complex VRM model with constraint bones and twist joints
- `test.vrma`: VRM Animation file for testing animation integration

**New Application Structure:**

- `apps/aria_viewer/`: New Phoenix application for IK solver backend and frontend
- `apps/aria_viewer/decisions/`: Architectural decision documents
- `IKChannel`: Phoenix Channel for WebSocket communication
- `apps/aria_viewer/priv/static/`: Three.js frontend files
- VRM model loading and skeleton extraction using existing `AriaGltf` infrastructure

### 4. Problem Solving

**Challenges Addressed:**

- **Performance**: Using nested set optimization for efficient transform calculations (26x faster)
- **Accuracy**: Leveraging existing joint hierarchy management instead of mock implementations
- **Standards Compliance**: Following VRM humanoid bone structure for interoperability
- **Temporal Integration**: Incorporating `AriaHybridPlanner` for smooth IK pose transitions
- **Signal Smoothing**: Implementing 1 euro filter for responsive yet smooth pose transitions
- **WebSocket Contract**: Defining clear JSON payload structures for frontend-backend communication
- **Real Model Testing**: Using actual VRM models with complex constraints and animations
- **Interactive Testing**: Creating 3D interface for bone selection, dragging, and visual feedback
- **File Loading**: Implementing drag-and-drop VRM loading for flexible model testing
- **End-to-End Validation**: Complete testing pipeline from user interaction to visual IK results
- **Documentation**: Creating ADR to capture architectural decisions and rationale

**Solutions Implemented:**

- Use existing `AriaJoint.HierarchyManager` for optimized skeleton management
- Integrate `AriaGltf.Skin` for proper joint hierarchy construction from VRM models
- Apply `@task_method` pattern for temporal IK solving actions
- Implement 1 euro filter algorithm for pose transition smoothing
- Define strict JSON contracts for WebSocket communication
- Load real VRM models for comprehensive testing
- Create Three.js frontend with bone interaction capabilities
- Implement drag-and-drop VRM file loading
- Build complete end-to-end testing interface

### 5. Pending Tasks and Next Steps

**Complete Implementation Steps:**

1. **Create `aria_viewer` Phoenix Application**

   - Generate new Phoenix app in umbrella structure
   - Configure dependencies on `aria_ewbik`, `aria_hybrid_planner`, `aria_joint`, `aria_gltf`
   - Set up basic application structure

2. **Create Architectural Decision Document**

   - Create `apps/aria_viewer/decisions/` directory
   - Document WebSocket vs WebRTC choice and rationale
   - Document IK solver architecture and temporal planning integration
   - Document 1 euro filter implementation for pose smoothing
   - Document VRM model loading and skeleton proxy usage
   - Document Three.js frontend integration
   - Document JSON payload contracts and communication protocols

3. **Set up WebSocket Channel Infrastructure**

   - Configure Phoenix Channels in the new application
   - Set up WebSocket endpoint configuration
   - Create basic channel structure

4. **Implement IKChannel WebSocket Handler**

   - Create Phoenix Channel for real-time IK communication
   - Handle `"update_target"` messages with endEffector and position data
   - Validate incoming JSON payload structure
   - Broadcast `"new_pose"` events with calculated joint rotations

5. **Integrate Skeleton Proxy Infrastructure**

   - Use `AriaJoint.HierarchyManager.new()` for optimized hierarchy management
   - Load VRM models using `AriaGltf.load_file()`
   - Extract skeleton from glTF skin using `AriaGltf.Skin.build_joint_hierarchy()`
   - Apply `AriaJoint.HierarchyManager.rebuild_from_nodes()` for functional batch processing

6. **Download and Setup Test Models**

   - Download VRM1_Constraint_Twist_Sample.vrm from three-vrm repository
   - Download test.vrma animation file for validation
   - Store models in appropriate test directory
   - Set up model loading in test environment

7. **Implement IK Solving with Temporal Planning**

   - Integrate `AriaHybridPlanner` for temporal constraints
   - Use `@task_method` pattern for procedural IK actions
   - Calculate joint rotations using `aria_ewbik.solve()`
   - Apply 1 euro filter algorithm for pose transition smoothing

8. **Pose Broadcasting and JSON Contract**

   - Format pose data with VRM bone names and quaternion rotations
   - Implement proper error handling and broadcasting
   - Ensure consistent JSON structure for frontend consumption

9. **Create Three.js Frontend Structure**

   - Set up HTML/CSS/JavaScript files in `apps/aria_viewer/priv/static`
   - Configure three-vrm library for VRM model loading
   - Create basic 3D scene with camera and lighting

10. **Implement VRM Model Loading**

    - Load VRM1_Constraint_Twist_Sample.vrm using three-vrm
    - Display the 3D character in the scene
    - Set up bone hierarchy visualization

11. **Add Bone Selection and Interaction**

    - Implement raycasting for bone selection
    - Add visual feedback for selected bones (highlighting)
    - Create drag handles for IK target manipulation

12. **WebSocket Client Integration**

    - Connect to Phoenix WebSocket channel
    - Send `"update_target"` messages with dragged bone positions
    - Receive `"new_pose"` messages and apply to VRM model

13. **Real-time Pose Updates with 1 Euro Filter**

    - Apply received quaternion rotations to VRM bones
    - Implement 1 euro filter for smooth pose interpolation
    - Handle multiple bone updates simultaneously

14. **Implement Drag & Drop VRM Loading**

    - Add HTML5 drag and drop zone for VRM files
    - Validate dropped files are valid VRM format
    - Load dropped VRM models using three-vrm
    - Replace current model in scene
    - Update bone hierarchy for IK solving

15. **File Validation and Error Handling**

    - Check file type (.vrm extension)
    - Validate VRM format and version
    - Handle loading errors gracefully
    - Provide user feedback for invalid files

16. **Dynamic Model Switching**

    - Preserve IK targets when switching models
    - Update bone selection interface for new model
    - Maintain WebSocket connection during model changes
    - Reset pose when loading new model

17. **Testing Interface and UI Controls**

    - Add UI controls for different test scenarios
    - Bone selection dropdown/picker
    - Position input fields for precise testing
    - Visual feedback for IK solving status
    - Model information display

18. **WebSocket Testing and Validation**

    - Create WebSocket testing client for backend validation
    - Test end-to-end IK solving workflow with real VRM models
    - Validate temporal planning integration
    - Verify VRM-standard pose output

19. **Complete End-to-End Testing**
    - Test drag-and-drop model loading
    - Test bone selection and dragging
    - Test real-time IK solving and pose updates
    - Test with multiple VRM models
    - Validate performance and responsiveness

**Technical Implementation Details:**

- **WebSocket Payload Contract:**

  ```json
  // Incoming: update_target
  {"endEffector": "leftHand", "position": {"x": 0.5, "y": 1.2, "z": 0.3}}

  // Outgoing: new_pose
  {"joints": [
    {"bone": "leftShoulder", "rotation": [0.1, 0.2, 0.3, 0.9]},
    {"bone": "leftUpperArm", "rotation": [0.4, 0.5, 0.6, 0.8]}
  ]}
  ```

- **VRM Model Integration:**

  ```elixir
  # Load VRM model
  {:ok, document} = AriaGltf.load_file("VRM1_Constraint_Twist_Sample.vrm")

  # Extract skeleton
  {:ok, skin} = AriaGltf.Skin.from_json(document.skins |> hd())
  {:ok, joint_hierarchy} = AriaGltf.Skin.build_joint_hierarchy(skin, document.nodes)

  # Create optimized hierarchy manager
  {:ok, manager} = AriaJoint.HierarchyManager.new()
  manager = AriaJoint.HierarchyManager.rebuild_from_nodes(manager, Map.values(joint_hierarchy))
  ```

- **Three.js Frontend Structure:**

  ```javascript
  // Load VRM and set up interaction
  const vrm = await THREE.VRMLoader.loadAsync("model.vrm");
  scene.add(vrm.scene);

  // Bone selection and dragging
  const raycaster = new THREE.Raycaster();
  // ... interaction logic

  // WebSocket communication
  const channel = socket.channel("ik:lobby");
  channel.on("new_pose", (payload) => {
    payload.joints.forEach((joint) => {
      const bone = vrm.humanoid.getBoneNode(joint.bone);
      const smoothedQuat = smoothQuaternion(
        joint.bone,
        joint.rotation,
        timestamp
      );
      bone.quaternion.copy(smoothedQuat);
    });
  });
  ```

- **1 Euro Filter Implementation:**

  ```javascript
  class OneEuroFilter {
    constructor(alpha, minCutoff, beta) {
      this.alpha = alpha;
      this.minCutoff = minCutoff;
      this.beta = beta;
      this.prevValue = null;
      this.prevDeriv = 0;
      this.prevTimestamp = 0;
    }

    filter(value, timestamp) {
      if (this.prevValue === null) {
        this.prevValue = value;
        this.prevTimestamp = timestamp;
        return value;
      }

      const dt = timestamp - this.prevTimestamp;
      const deriv = (value - this.prevValue) / dt;

      const cutoff = this.minCutoff + this.beta * Math.abs(deriv);
      const alpha = this.alpha / (this.alpha + dt * cutoff);

      const filteredValue = alpha * value + (1 - alpha) * this.prevValue;

      this.prevValue = filteredValue;
      this.prevDeriv = deriv;
      this.prevTimestamp = timestamp;

      return filteredValue;
    }
  }
  ```

- **ADR Structure:**

  - Status: Active
  - Context: Real-time IK solver with interactive 3D testing
  - Decision: WebSocket/Phoenix Channels with Three.js frontend and 1 euro filter smoothing
  - Implementation Plan: Detailed steps with technical specifications
  - Success Criteria: Working end-to-end IK system with drag-and-drop model loading

- **Performance Target:** Leverage nested set optimization for real-time IK solving with complex VRM models

This comprehensive task creates a complete real-time IK testing system with both backend computation and interactive 3D frontend, supporting flexible model loading and comprehensive validation of the IK solving pipeline with professional-grade pose smoothing.
