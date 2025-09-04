# R25W167IK - Real-Time IK Solver with Interactive 3D Web Interface

## Status

Active

## Context

The aria-character-core project requires a comprehensive real-time Inverse Kinematics (IK) solver system with interactive 3D testing capabilities. The system needs to:

- Provide real-time IK computation for VRM character models
- Support interactive bone manipulation through a web interface
- Integrate with existing skeleton proxy infrastructure (AriaJoint.HierarchyManager)
- Use temporal planning for smooth pose transitions (AriaHybridPlanner)
- Implement 1 euro filter algorithm for pose smoothing
- Support drag-and-drop VRM model loading
- Follow VRM humanoid bone naming conventions
- Leverage nested set optimization for 26x faster pose calculations

## Decision

Implement a Phoenix WebSocket backend with Three.js frontend for real-time IK solving and interactive 3D testing.

**Architecture:**

- **Backend:** Phoenix Channels for real-time bidirectional communication
- **Frontend:** Three.js with three-vrm library for VRM model display and interaction
- **Communication:** WebSocket-based JSON payload contracts
- **IK Solving:** Integration with AriaEwbik using existing skeleton infrastructure
- **Pose Smoothing:** 1 euro filter algorithm for responsive yet smooth transitions
- **Model Loading:** Drag-and-drop VRM file loading with validation

## Implementation Plan

### Phase 1: Backend Infrastructure (Current)

- [x] Create `aria_viewer` Phoenix application
- [x] Configure Phoenix Channels and WebSocket endpoint
- [x] Implement IKChannel for real-time communication
- [x] Set up basic application structure and dependencies

### Phase 2: Skeleton Integration

- [ ] Integrate AriaJoint.HierarchyManager for optimized skeleton management
- [ ] Load VRM models using AriaGltf.Skin.build_joint_hierarchy()
- [ ] Apply nested set optimization for performance
- [ ] Implement VRM bone name mapping

### Phase 3: IK Solving Engine

- [ ] Integrate AriaEwbik.solve() for joint rotation calculations
- [ ] Implement temporal planning with AriaHybridPlanner
- [ ] Add 1 euro filter for pose transition smoothing
- [ ] Support multiple end effector targets simultaneously

### Phase 4: WebSocket Communication

- [ ] Define strict JSON payload contracts
- [ ] Implement error handling and validation
- [ ] Add broadcasting for pose updates
- [ ] Support model loading messages

### Phase 5: Three.js Frontend

- [ ] Set up HTML/CSS/JavaScript structure
- [ ] Configure three-vrm library for VRM loading
- [ ] Implement 3D scene with camera and lighting
- [ ] Add bone selection and visual feedback

### Phase 6: Interactive Features

- [ ] Implement raycasting for bone selection
- [ ] Add drag handles for IK target manipulation
- [ ] Connect WebSocket client to Phoenix backend
- [ ] Real-time pose updates with smoothing

### Phase 7: Drag & Drop Model Loading

- [ ] HTML5 drag and drop zone implementation
- [ ] VRM file validation and error handling
- [ ] Dynamic model switching
- [ ] Bone hierarchy updates for new models

### Phase 8: Testing and Validation

- [ ] Download VRM1_Constraint_Twist_Sample.vrm test model
- [ ] End-to-end IK solving validation
- [ ] Performance testing with complex VRM models
- [ ] WebSocket communication testing

## Technical Specifications

### WebSocket Payload Contracts

**Incoming Messages:**

```json
// Update IK target
{
  "endEffector": "leftHand",
  "position": {"x": 0.5, "y": 1.2, "z": 0.3}
}

// Load VRM model
{
  "model_path": "/path/to/model.vrm"
}
```

**Outgoing Messages:**

```json
// New pose data
{
  "joints": [
    { "bone": "leftShoulder", "rotation": [0.1, 0.2, 0.3, 0.9] },
    { "bone": "leftUpperArm", "rotation": [0.4, 0.5, 0.6, 0.8] }
  ]
}
```

### VRM Integration Architecture

```elixir
# Dependencies required (add to mix.exs)
defp deps do
  [
    {:phoenix, "~> 1.7"},
    {:phoenix_pubsub, "~> 1.1"},
    {:phoenix_html, "~> 3.0"},
    {:phoenix_live_view, "~> 0.18"},
    {:plug_cowboy, "~> 2.5"},
    {:jason, "~> 1.2"},
    {:mox, "~> 1.0", only: [:test]},  # Required for WebSocket testing
    {:aria_ewbik, in_umbrella: true},
    {:aria_hybrid_planner, in_umbrella: true},
    {:aria_joint, in_umbrella: true},
    {:aria_gltf, in_umbrella: true}
  ]
end

# Load VRM model
{:ok, document} = AriaGltf.load_file("VRM1_Constraint_Twist_Sample.vrm")
{:ok, skin} = AriaGltf.Skin.from_json(document.skins |> hd())
{:ok, joint_hierarchy} = AriaGltf.Skin.build_joint_hierarchy(skin, document.nodes)

# Create optimized hierarchy manager
{:ok, manager} = AriaJoint.HierarchyManager.new()
manager = AriaJoint.HierarchyManager.rebuild_from_nodes(manager, Map.values(joint_hierarchy))
```

### 1 Euro Filter Implementation

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
    // Implementation for smooth pose interpolation
  }
}
```

## Success Criteria

- [ ] **Real-time IK Solving:** Sub-100ms response time for IK target updates
- [ ] **VRM Compatibility:** Full support for VRM 1.0 humanoid bone structure
- [ ] **Interactive Testing:** Bone selection, dragging, and visual feedback
- [ ] **Model Loading:** Drag-and-drop VRM loading with validation
- [ ] **Pose Smoothing:** 1 euro filter providing responsive yet smooth transitions
- [ ] **WebSocket Reliability:** Stable bidirectional communication
- [ ] **Performance:** 26x faster pose calculations using nested set optimization
- [ ] **End-to-End Testing:** Complete workflow from user interaction to visual IK results

## Risks and Mitigations

### Performance Risks

- **Risk:** Complex VRM models with constraints may impact real-time performance
- **Mitigation:** Use nested set optimization and profile performance with test models

### WebSocket Complexity

- **Risk:** Real-time bidirectional communication may introduce synchronization issues
- **Mitigation:** Implement proper error handling and message validation

### Browser Compatibility

- **Risk:** Three.js and WebSocket support across different browsers
- **Mitigation:** Test on multiple browsers and provide fallbacks

### VRM Model Variations

- **Risk:** Different VRM models may have varying bone structures
- **Mitigation:** Implement robust bone name mapping and validation

## Related ADRs

- **R25W159DECX:** Port V-Sekai many bone IK Nx acceleration
- **R25W1406B2C:** Nx tensor integration Aria math joint gltf QCP
- **R25W141BE8A:** Planner standardization open problems
- **R25W0365EF2:** Complete temporal planning solver

## Timeline

- **Phase 1-2:** Backend infrastructure and skeleton integration (Week 1)
- **Phase 3-4:** IK solving engine and WebSocket communication (Week 2)
- **Phase 5-6:** Three.js frontend and interactive features (Week 3)
- **Phase 7-8:** Drag & drop loading and testing (Week 4)

## Monitoring and Metrics

- **IK Response Time:** Target <100ms for target updates
- **WebSocket Latency:** Monitor round-trip message times
- **Model Load Time:** Track VRM loading and processing performance
- **Pose Update Frequency:** Maintain 30+ FPS for smooth animation
- **Memory Usage:** Monitor for memory leaks during model switching

This ADR establishes the architectural foundation for a comprehensive real-time IK testing system that integrates seamlessly with the existing aria-character-core infrastructure while providing powerful interactive 3D testing capabilities.
