# R25W159DECX: Port V-Sekai Many Bone IK to Elixir with Multi-Backend Nx Acceleration and Real-time GLTF2 Integration

<!-- @adr_serial R25W159DECX -->

**Status:** Active  
**Date:** June 27, 2025  
**Priority:** HIGH

## Context

We need to port the V-Sekai many_bone_ik system (https://github.com/V-Sekai/many_bone_ik) to Elixir with modern Nx acceleration for real-time inverse kinematics simulation. This system will integrate with our existing aria_gltf infrastructure to provide complete avatar simulation with GLTF2 export capabilities.

The V-Sekai many_bone_ik system provides sophisticated multi-chain IK solving with Kusudama constraint systems, supporting FABRIK, CCD, and EWBIK algorithms. Our implementation will leverage Nx's multi-backend architecture for GPU acceleration while maintaining compatibility across different hardware configurations.

## Decision

Create a separate `aria_many_bone_ik` umbrella application that integrates with `aria_gltf` for complete IK-driven avatar simulation with real-time GLTF2 export capabilities.

**Architecture Decision:** Separate application with clean API boundaries to aria_gltf, leveraging multi-backend Nx for maximum performance flexibility.

## Implementation Plan

### Phase 1: Complete aria_gltf Foundation (PREREQUISITE - Weeks 1-2)

**Priority: CRITICAL - Must complete before IK development**

- [ ] **Complete missing aria_gltf core modules** (per R25W158APPS TODO)
  - [ ] AriaGltf.Image Module - Image data and URI references
  - [ ] AriaGltf.Sampler Module - Texture sampling parameters  
  - [ ] AriaGltf.Texture Module - Texture definitions
  - [ ] AriaGltf.Camera Module - Camera definitions
  - [ ] **AriaGltf.Skin Module** - Skeletal animation support (CRITICAL for IK)
- [ ] **Implement import functionality**
  - [ ] AriaGltf.IO.import_from_file/1 function
  - [ ] JSON parsing and validation for imported files
  - [ ] Basic documentation and examples
- [ ] **Validate SimpleSkin/SimpleMorph loading**
  - [ ] Test loading SimpleSkin.gltf from glTF-Sample-Assets
  - [ ] Test loading SimpleMorph.gltf from glTF-Sample-Assets
  - [ ] Ensure solid foundation for IK integration

### Phase 2: aria_many_bone_ik Foundation (Weeks 2-3)

- [ ] **Create new umbrella application**
  - [ ] Mix project setup with comprehensive dependencies
  - [ ] Multi-backend Nx configuration (TorchX, EXLA, BinaryBackend)
  - [ ] Application supervision tree
  - [ ] Basic project structure and documentation

- [ ] **Nx Mathematical Foundation**
  - [ ] **Vector3D operations with Nx.Defn**
    - [ ] Addition, subtraction, multiplication, division
    - [ ] Dot product, cross product, normalization
    - [ ] Distance calculations and magnitude operations
    - [ ] Batch operations for multiple vectors
  - [ ] **Quaternion operations with Nx.Defn**
    - [ ] Quaternion multiplication and conjugation
    - [ ] Rotation composition and interpolation (SLERP)
    - [ ] Conversion to/from rotation matrices
    - [ ] Batch quaternion operations
  - [ ] **Transform3D using Nx.LinAlg**
    - [ ] 4x4 transformation matrix operations
    - [ ] Matrix composition and decomposition
    - [ ] Efficient transformation chains
    - [ ] Batch transformation processing
  - [ ] **Backend-agnostic implementations**
    - [ ] Runtime backend detection and selection
    - [ ] Graceful degradation strategies
    - [ ] Performance profiling per backend

### Phase 3: Constraint System Implementation (Weeks 3-4)

- [ ] **Kusudama3D Constraint System with Nx acceleration**
  - [ ] **Open cone geometry implementation**
    - [ ] Cone definition with axis and angle parameters
    - [ ] Point-in-cone testing using vectorized operations
    - [ ] Cone intersection and union calculations
  - [ ] **Constraint violation detection**
    - [ ] Efficient batch constraint checking
    - [ ] Multi-joint constraint validation
    - [ ] Constraint priority and weighting systems
  - [ ] **Constraint projection algorithms**
    - [ ] Project rotations onto constraint surfaces
    - [ ] Minimal rotation adjustments for constraint satisfaction
    - [ ] Smooth constraint enforcement

- [ ] **Joint limits and collision avoidance**
  - [ ] **Ray-based collision detection using Nx**
    - [ ] Ray-sphere and ray-capsule intersection tests
    - [ ] Batch collision detection for multiple rays
    - [ ] Spatial acceleration structures
  - [ ] **Joint angle limits**
    - [ ] Euler angle constraints
    - [ ] Quaternion-based limits
    - [ ] Smooth limit enforcement

### Phase 4: IK Algorithm Implementation (Weeks 4-6)

- [ ] **FABRIK (Forward and Backward Reaching IK) Solver**
  - [ ] **Forward reaching phase with Nx tensors**
    - [ ] Efficient chain traversal from end effector to root
    - [ ] Distance constraint satisfaction
    - [ ] Batch processing for multiple chains
  - [ ] **Backward reaching phase with Nx tensors**
    - [ ] Root-to-end traversal with position correction
    - [ ] Joint constraint integration
    - [ ] Convergence detection and iteration limits
  - [ ] **Multi-chain coordination**
    - [ ] Sub-base resolution for complex skeletons
    - [ ] Chain priority and weighting systems
    - [ ] Constraint integration across chains

- [ ] **CCD (Cyclic Coordinate Descent) Solver**
  - [ ] **Vectorized joint rotation optimization**
    - [ ] Per-joint angle calculation for target reaching
    - [ ] Efficient rotation composition
    - [ ] Batch angle calculations for multiple joints
  - [ ] **Constraint-aware solving**
    - [ ] Joint limit enforcement during optimization
    - [ ] Kusudama constraint integration
    - [ ] Smooth convergence with damping

- [ ] **EWBIK (Exponentially Weighted Backward IK) Solver**
  - [ ] **Advanced weighting system with Nx**
    - [ ] Exponential weight distribution along chains
    - [ ] Dynamic weight adjustment based on constraints
    - [ ] Multi-objective optimization with weighted goals
  - [ ] **Sophisticated convergence properties**
    - [ ] Smooth motion generation
    - [ ] Stability analysis and control
    - [ ] Advanced damping and regularization

### Phase 5: Real-time Architecture (Weeks 6-7)

- [ ] **IKSolver GenServer coordination**
  - [ ] **Real-time solving with Nx backend**
    - [ ] Frame-based update cycles
    - [ ] Asynchronous solving with result caching
    - [ ] Priority-based task scheduling
  - [ ] **Performance optimization**
    - [ ] Memory pooling for tensors
    - [ ] Efficient data structure updates
    - [ ] Garbage collection optimization
  - [ ] **Backend selection and fallback**
    - [ ] Runtime performance monitoring
    - [ ] Automatic backend switching
    - [ ] Graceful degradation strategies

- [ ] **Frame rate optimization**
  - [ ] **Target frame rate management**
    - [ ] Adaptive quality scaling
    - [ ] Time budget allocation
    - [ ] Frame dropping strategies
  - [ ] **Memory-efficient tensor management**
    - [ ] Tensor reuse and pooling
    - [ ] Lazy evaluation strategies
    - [ ] Memory pressure monitoring

### Phase 6: aria_gltf Integration (Weeks 7-8)

- [ ] **Export integration with aria_gltf**
  - [ ] **IK solutions → AriaGltf.Skin transformations**
    - [ ] Joint matrix calculation from IK poses
    - [ ] Inverse bind matrix integration
    - [ ] Smooth animation data generation
  - [ ] **Real-time animation data generation**
    - [ ] Frame-accurate pose capture
    - [ ] Animation track creation
    - [ ] Keyframe optimization and compression
  - [ ] **Capsule visualization as glTF primitives**
    - [ ] IK point representation as capsule meshes
    - [ ] Constraint visualization geometry
    - [ ] Debug rendering for IK chains

- [ ] **Import integration with aria_gltf**
  - [ ] **Load glTF skeletons into IK system**
    - [ ] Joint hierarchy parsing
    - [ ] Bone length and orientation extraction
    - [ ] Constraint setup from glTF metadata
  - [ ] **Convert glTF joint hierarchy to IK chains**
    - [ ] Automatic chain detection and segmentation
    - [ ] End effector identification
    - [ ] Constraint inference from joint structure

### Phase 7: Testing and Validation (Weeks 8-9)

- [ ] **Multi-backend testing and validation**
  - [ ] **TorchX backend validation**
    - [ ] GPU acceleration testing
    - [ ] Performance benchmarking
    - [ ] Memory usage analysis
  - [ ] **EXLA backend validation**
    - [ ] XLA/TPU optimization testing
    - [ ] Compilation performance analysis
    - [ ] Numerical accuracy validation
  - [ ] **BinaryBackend validation**
    - [ ] CPU fallback functionality
    - [ ] Cross-platform compatibility
    - [ ] Performance baseline establishment

- [ ] **Real-time performance validation**
  - [ ] **Frame rate measurement across backends**
    - [ ] Consistent 60fps+ targeting
    - [ ] Frame time variance analysis
    - [ ] Latency measurement and optimization
  - [ ] **Memory usage optimization**
    - [ ] Memory leak detection
    - [ ] Allocation pattern analysis
    - [ ] Garbage collection impact assessment
  - [ ] **Algorithm accuracy validation**
    - [ ] Comparison with reference implementations
    - [ ] Numerical stability testing
    - [ ] Constraint satisfaction verification

## Technical Architecture

### aria_many_bone_ik App Structure

```
apps/aria_many_bone_ik/
├── lib/aria_many_bone_ik/
│   ├── math/                    # Nx-accelerated 3D mathematics
│   │   ├── vector3d.ex         # Vector operations with Nx.Defn
│   │   ├── quaternion.ex       # Quaternion math with Nx.Defn
│   │   └── transform3d.ex      # Matrix operations with Nx.LinAlg
│   ├── constraints/            # Kusudama constraint system
│   │   ├── kusudama3d.ex       # Cone constraint implementation
│   │   ├── open_cone3d.ex      # Open cone geometry
│   │   └── ray3d.ex            # Ray-based collision detection
│   ├── solvers/                # IK algorithm implementations
│   │   ├── fabrik.ex           # FABRIK solver with Nx
│   │   ├── ccd.ex              # CCD solver with Nx
│   │   └── ewbik.ex            # EWBIK solver with Nx
│   ├── core/                   # Core IK data structures
│   │   ├── ik_bone.ex          # Individual bone representation
│   │   ├── ik_chain.ex         # Bone chain management
│   │   └── ik_effector.ex      # End effector definitions
│   ├── runtime/                # Real-time coordination
│   │   ├── ik_solver.ex        # GenServer coordination
│   │   └── performance.ex      # Performance monitoring
│   └── export/                 # aria_gltf integration
│       ├── gltf_integration.ex # Export to aria_gltf
│       └── animation_export.ex # Animation data generation
├── mix.exs                     # Multi-backend Nx dependencies
├── README.md                   # Comprehensive documentation
└── test/                       # Comprehensive test suite
```

### Multi-Backend Nx Strategy

**Backend Configuration:**

- **TorchX**: Primary backend for GPU acceleration (CUDA/ROCm)
- **EXLA**: XLA/TPU support for high-performance computing
- **BinaryBackend**: CPU fallback for maximum compatibility

**Runtime Backend Selection:**

```elixir
# Automatic backend detection and selection
backend = case Nx.default_backend() do
  {Torchx.Backend, _} -> :torchx
  {EXLA.Backend, _} -> :exla
  {Nx.BinaryBackend, _} -> :binary
end

# Performance-based backend switching
optimal_backend = AriaIK.Performance.select_optimal_backend(skeleton_complexity)
```

**Graceful Degradation:**

- GPU unavailable → Fall back to EXLA
- EXLA unavailable → Fall back to BinaryBackend
- Maintain functionality across all configurations

### Integration with aria_gltf

**Export Pipeline:**

```
IK Solution → Joint Matrices → AriaGltf.Skin → Animation Tracks → GLTF2 Export
```

**Import Pipeline:**

```
GLTF2 Import → AriaGltf.Skin → Joint Hierarchy → IK Chain Setup → Ready for Solving
```

**Real-time Integration:**

- Live IK solving feeds directly into aria_gltf export pipeline
- Frame-accurate animation generation
- Capsule visualization for debugging and constraint display

## Success Criteria

### Technical Requirements

- [ ] **All three IK algorithms implemented with Nx acceleration**
  - [ ] FABRIK solver with multi-chain support
  - [ ] CCD solver with constraint integration
  - [ ] EWBIK solver with advanced weighting
- [ ] **Multi-backend Nx support with graceful degradation**
  - [ ] TorchX backend for GPU acceleration
  - [ ] EXLA backend for XLA/TPU optimization
  - [ ] BinaryBackend for CPU fallback
- [ ] **Full Kusudama constraint system**
  - [ ] Open cone constraint geometry
  - [ ] Constraint violation detection and projection
  - [ ] Multi-joint constraint coordination
- [ ] **Seamless aria_gltf integration**
  - [ ] Import glTF skeletons into IK system
  - [ ] Export IK solutions as glTF animations
  - [ ] Real-time capsule visualization

### Performance Targets

- [ ] **TorchX Backend**: GPU-accelerated, targeting 120fps+ for typical skeletons (20-50 bones)
- [ ] **EXLA Backend**: XLA-optimized, targeting 60fps+ for complex skeletons (50-100 bones)
- [ ] **BinaryBackend**: CPU fallback, targeting 30fps+ for basic skeletons (10-20 bones)
- [ ] **Memory efficiency**: Minimal allocation during real-time updates (<1MB/frame)
- [ ] **Latency**: Sub-16ms solve times for real-time applications

### Integration Requirements

- [ ] **Load glTF skeletons from aria_gltf**
  - [ ] Parse joint hierarchies and constraints
  - [ ] Convert to IK chain representations
  - [ ] Maintain bone naming and metadata
- [ ] **Export IK solutions as glTF animations**
  - [ ] Frame-accurate animation tracks
  - [ ] Smooth interpolation between poses
  - [ ] Compression and optimization
- [ ] **Real-time capsule visualization**
  - [ ] IK points as glTF capsule primitives
  - [ ] Constraint visualization geometry
  - [ ] Debug rendering for development

### Validation Requirements

- [ ] **Algorithm accuracy validation**
  - [ ] Compare against V-Sekai reference implementation
  - [ ] Numerical stability across backends
  - [ ] Constraint satisfaction verification
- [ ] **Performance benchmarking**
  - [ ] Frame rate consistency across backends
  - [ ] Memory usage optimization
  - [ ] Scalability testing with complex skeletons
- [ ] **Integration testing**
  - [ ] End-to-end IK → GLTF2 pipeline
  - [ ] SimpleSkin/SimpleMorph compatibility
  - [ ] Real-time performance validation

## Risks and Mitigation

**Risk**: Nx backends may not achieve real-time performance for complex skeletons  
**Mitigation**: Multi-backend strategy with graceful degradation, early profiling, adaptive quality scaling

**Risk**: Integration complexity with aria_gltf may introduce bugs  
**Mitigation**: Clean API boundaries, incremental integration, comprehensive testing

**Risk**: Backend availability varies across deployment environments  
**Mitigation**: Runtime detection, automatic fallback, clear documentation of requirements

**Risk**: Memory usage may be excessive for real-time applications  
**Mitigation**: Tensor pooling, lazy evaluation, memory pressure monitoring

## Related ADRs

- **R25W158APPS**: AriaGltf TODO tracking (PREREQUISITE - must complete Phase 1)
- **R25W1513883**: glTF 2.0 Specification Implementation (foundation for integration)
- **R25W087E1AE**: Aria Engine Plans glTF KHR Interactivity Implementation (future integration)
- **R25W0969BA8**: TDD glTF Scene Graph Logic (testing approach)
- **R25W1398085**: Unified Durative Action Specification (temporal planning integration)

## Dependencies

**External Dependencies:**

- **Nx**: Numerical computing foundation
- **TorchX**: GPU acceleration backend
- **EXLA**: XLA/TPU optimization backend
- **aria_gltf**: GLTF2 import/export integration

**Reference Implementation:**

- **V-Sekai many_bone_ik**: https://github.com/V-Sekai/many_bone_ik
- **glTF Sample Assets**: SimpleSkin.gltf and SimpleMorph.gltf for validation

## Notes

This implementation represents a significant advancement in real-time IK capabilities for the Aria ecosystem. The multi-backend Nx approach ensures maximum performance across different hardware configurations while maintaining clean integration with our existing glTF infrastructure.

The separate application architecture allows for independent development and testing while providing clean API boundaries for integration with aria_gltf and future AriaEngine temporal planning systems.

Success will demonstrate the viability of Elixir/Nx for high-performance real-time graphics and animation applications, potentially opening new possibilities for the broader ecosystem.
