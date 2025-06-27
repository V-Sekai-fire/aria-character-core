# R25W1513883: Comprehensive glTF 2.0 Implementation with SimpleSkin/SimpleMorph Animation Support

<!-- @adr_serial R25W1513883 -->

**Status:** Active  
**Date:** 2025-06-26 (Updated: 2025-06-27)  
**Priority:** HIGH

**Note:** This ADR incorporates and supersedes R25W1524A37 (SimpleSkin Animation Import/Export) to provide unified glTF domain implementation.

## Context

The aria-character-core system requires comprehensive glTF 2.0 support to enable 3D character representation, animation, and interactivity. The glTF 2.0 specification provides a standardized format for transmitting and loading 3D content, which is essential for our character system's visual representation and animation capabilities.

Currently, we have a basic `aria_gltf` app with core data structures implemented but lacks critical functionality for animation import/export and robust validation. This implementation must support both the SimpleSkin and SimpleMorph samples from glTF-Sample-Assets, which demonstrate vertex skinning with joint hierarchies, morph target animation (blend shapes), and combined animation workflows.

### Current State Analysis

**Existing Implementation (✅ Completed):**

- Comprehensive `aria_gltf` app with sophisticated data structures
- Complete Document module with full JSON parsing/serialization framework
- Animation module foundation with duration calculation and validation
- Material system including PBR metallic-roughness support
- Scene graph: Scene, Node, Mesh structures with proper relationships
- Core data handling: Asset, Buffer, BufferView, Accessor modules
- Texture system: TextureInfo, NormalTextureInfo, OcclusionTextureInfo
- Application supervision tree and proper Elixir app structure

**Critical Missing Components (❌ Required):**

- Animation Channel and Sampler modules (referenced but not implemented)
- I/O system for file import/export (JSON/GLB parsing)
- Skinning system (joints, inverse bind matrices, vertex weights)
- Image format support (JPG/PNG read/write)
- Tensor operations integration (Nx/TorchX dependencies)
- Comprehensive validation against glTF specification
- SimpleSkin/SimpleMorph sample validation framework

### Requirements from SimpleSkin and SimpleMorph Samples

**SimpleSkin Sample demonstrates:**

- Vertex skinning with joint hierarchies
- Animation channels targeting joint transformations
- Inverse bind matrices for skin deformation
- Timeline-based animation playback
- Frame-accurate mesh state calculation

**SimpleMorph Sample demonstrates:**

- Morph targets (blend shapes) for mesh deformation
- Weight-based blending between base mesh and morph targets
- Animation of morph weights over time
- Multiple simultaneous morph target blending

**Combined Animation Requirements:**

- Simultaneous skinning and morphing operations
- Proper transformation order: Base Mesh → Morph Targets → Skinning → Final Mesh
- Temporal synchronization of both animation types
- Frame-accurate calculation of final vertex positions

### ufbx Validation Standards

ufbx achieves 95% branch coverage through:

- Structured fuzzing for binary and ASCII formats
- Semantic fuzzing for file modifications
- Built-in fuzzing for byte modifications/truncation/out-of-memory
- Validation against reference implementations
- Extensive edge case testing

### Key Requirements from glTF 2.0 Specification

Based on the specification analysis, our domain needs to implement:

1. **Core Data Structures** (Chapter 3.1-3.6)
   - Asset metadata and versioning
   - Scene hierarchy and node transformations
   - Binary data storage (buffers, buffer views, accessors)

2. **Geometry System** (Chapter 3.7)
   - Mesh primitives and attributes
   - Skinning for character animation
   - Morph targets for facial expressions

3. **Animation System** (Chapter 3.11)
   - Keyframe animations for character movement
   - Timeline-based animation control
   - Integration with our existing temporal planning system

4. **Material and Texture System** (Chapter 3.8-3.9)
   - PBR (Physically Based Rendering) materials
   - Texture mapping and sampling
   - Material property animation

## Domain Architecture Requirements

**MANDATORY DEPENDENCIES BY APP:**

**`aria_gltf_core`:**

- **MUST use** minimal dependencies (JSON parsing, validation only)
- **MUST provide** foundational data structures for all other glTF apps

**`aria_gltf_geometry`:**

- **MUST use R25W1398085** for unified durative action specification and temporal coordination
- **MUST use Nx** (https://hex.pm/packages/nx) with `{:torchx, "~> 0.9"}` for efficient tensor operations in mesh transformations
- **MUST depend on** `aria_gltf_core` for data structures

**`aria_gltf_animation`:**

- **MUST use R25W1398085** for unified durative action specification and temporal coordination
- **MUST integrate with** aria_timeline for temporal planning
- **MUST depend on** `aria_gltf_core` for data structures

**`aria_gltf_materials`:**

- **MUST depend on** `aria_gltf_core` and `aria_gltf_images`
- **SHOULD use Nx** for material property processing when applicable

**`aria_gltf_images`:**

- **MUST use** `:image` package (https://hex.pm/packages/image) for JPG/PNG read/write operations
- **MUST use Nx** with `{:torchx, "~> 0.9"}` for image processing and tensor conversion
- **MUST support** JPG and PNG format read/write with quality/compression control

**`aria_gltf_io`:**

- **MUST depend on** `aria_gltf_core` and `aria_gltf_images`
- **MUST support** JSON (.gltf) and binary (.glb) format parsing and export

**Frame-Accurate Mesh State Calculation Pipeline:**
The system must support precise calculation of mesh states at any given timestamp through efficient tensor operations across `aria_gltf_geometry`, `aria_gltf_animation`, and `aria_gltf_images`, enabling frame-accurate animation processing and visual export capabilities.

**MANDATORY SAMPLE ASSET VALIDATION:**

- **MUST validate against SimpleSkin.gltf**: https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/SimpleSkin/glTF-Embedded/SimpleSkin.gltf
- **MUST validate against SimpleMorph.gltf**: https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/SimpleMorph/glTF-Embedded/SimpleMorph.gltf

**Frame-Accurate Processing Requirements:**

**SimpleSkin Joint Animation (via `aria_gltf_geometry` + `aria_gltf_animation`):**

- **Precise joint matrix calculation**: Compute accurate 4x4 transformation matrices for each joint at any timestamp
- **Multi-joint vertex skinning**: Handle vertices influenced by multiple joints with correct weight blending
- **Sub-frame interpolation**: Support animation sampling between keyframes with temporal precision
- **Bone hierarchy validation**: Maintain correct parent-child joint relationships during animation

**SimpleMorph Target Blending (via `aria_gltf_geometry` + `aria_gltf_animation`):**

- **Precise morph weight interpolation**: Calculate accurate morph target weights at any timestamp
- **Vertex position blending**: Blend vertex positions between base mesh and morph targets
- **Multi-target support**: Handle multiple simultaneous morph targets with weight normalization
- **Facial expression accuracy**: Maintain precise control for character facial animations

**Export and Validation Pipeline (via `aria_gltf_images`):**

- **Frame extraction**: Export mesh states as images at arbitrary timestamps for validation
- **Reference comparison**: Compare against known-good reference implementations
- **Temporal consistency**: Ensure smooth animation without temporal artifacts or discontinuities
- **Performance benchmarking**: Measure frame calculation performance for real-time applications

## Decision

We will implement a comprehensive glTF 2.0 system using a **single responsibility app architecture** with six focused Elixir applications within the umbrella project. Each app handles a distinct aspect of glTF processing, enabling independent development, selective deployment, and clear separation of concerns.

### Single Responsibility Apps Architecture

**1. `aria_gltf_core` - Core Data Structures & Validation**

- **Responsibility**: glTF 2.0 specification data structures, JSON schema validation, core types
- **Dependencies**: Minimal - only JSON parsing and validation libraries
- **Why separate**: Pure data layer with no business logic, reusable across other glTF apps

**2. `aria_gltf_geometry` - Mesh & Geometry Processing**

- **Responsibility**: Mesh primitives, vertex attributes, skinning data, morph targets, tensor operations
- **Dependencies**: `aria_gltf_core`, Nx, TorchX for efficient mesh transformations
- **Why separate**: Computationally intensive, different performance characteristics, GPU optimization

**3. `aria_gltf_animation` - Animation System**

- **Responsibility**: Keyframe interpolation, animation channels/samplers, temporal coordination
- **Dependencies**: `aria_gltf_core`, R25W1398085 for temporal planning integration
- **Why separate**: Temporal concerns, integration with aria_timeline, distinct from static geometry

**4. `aria_gltf_materials` - Material & Texture System**

- **Responsibility**: PBR materials, texture management, material property processing
- **Dependencies**: `aria_gltf_core`, `aria_gltf_images` for texture loading
- **Why separate**: Rendering concerns, different from geometry/animation, potential GPU integration

**5. `aria_gltf_images` - Image Format Support**

- **Responsibility**: JPG/PNG read/write, format conversion, Nx tensor integration
- **Dependencies**: `:image` package, Nx, TorchX for image processing
- **Why separate**: Image processing is computationally distinct, reusable across apps

**6. `aria_gltf_io` - File Format I/O**

- **Responsibility**: JSON/GLB parsing, URI resolution, file validation, export functionality
- **Dependencies**: `aria_gltf_core`, `aria_gltf_images` for frame export
- **Why separate**: I/O concerns, different error handling patterns, file system dependencies

### App Dependency Flow

```
aria_gltf_io → aria_gltf_core ← aria_gltf_geometry
                    ↑              ↑
            aria_gltf_animation ← aria_gltf_materials
                                        ↑
                                aria_gltf_images
```

### Implementation Approach

1. **Single Responsibility**: Each app has one clear, well-defined purpose
2. **Independent Development**: Teams can work on different apps simultaneously
3. **Selective Deployment**: Only include needed apps (e.g., headless systems might skip materials)
4. **Clean Dependencies**: Explicit app-to-app dependencies with clear APIs
5. **Performance Optimization**: Each app optimized for its specific workload
6. **Testing Isolation**: Easier to test and validate each component independently

## Implementation Plan

### App 1: `aria_gltf_core` - Core Data Structures (HIGH PRIORITY) ✅

**Location**: `apps/aria_gltf_core/`
**Dependencies**: Minimal (JSON parsing, validation)

**Current Status**: ✅ **SIGNIFICANTLY ADVANCED** - Existing `aria_gltf` app has comprehensive implementation

**Current Implementation Assessment**:

- [x] Complete Document module with JSON parsing/serialization ✅
- [x] Asset, Buffer, BufferView, Accessor modules ✅
- [x] Scene, Node, Mesh structures ✅
- [x] Material system with PBR support ✅
- [x] Texture system (TextureInfo, NormalTextureInfo, OcclusionTextureInfo) ✅
- [x] Animation module foundation with validation ✅
- [x] Application supervision tree ✅

**Required Completion**:

- [x] Animation Channel and Sampler modules (referenced but missing) ✅
- [x] Add Nx/TorchX dependencies for tensor operations ✅
- [ ] Comprehensive JSON schema validation
- [ ] Decide: Extract to separate apps OR enhance existing single app

**Implementation Patterns**:

- [x] Struct definitions with proper field types ✅
- [x] Index-based reference resolution ✅
- [ ] JSON schema validation framework
- [ ] Comprehensive error handling with custom error types
- [ ] Data validation and type checking

### App 2: `aria_gltf_images` - Image Format Support (HIGH PRIORITY)

**Location**: `apps/aria_gltf_images/`
**Dependencies**: `:image`, `nx`, `torchx`

**Required Implementation**:

- [ ] Create new Elixir application: `mix new apps/aria_gltf_images`
- [ ] JPG/PNG read functionality using `:image` package
- [ ] JPG/PNG write functionality with quality/compression control
- [ ] Nx tensor conversion (image data ↔ tensors)
- [ ] Format detection and validation
- [ ] Memory-efficient binary handling

**Implementation Patterns**:

- [ ] Direct binary to Nx tensor conversion
- [ ] Quality/compression parameter handling
- [ ] Format conversion between JPG/PNG
- [ ] Error handling for corrupted/invalid images
- [ ] Streaming support for large images

### App 3: `aria_gltf_geometry` - Mesh & Geometry Processing (HIGH PRIORITY)

**Location**: `apps/aria_gltf_geometry/`
**Dependencies**: `aria_gltf_core`, `nx`, `torchx`

**Required Implementation**:

- [ ] Create new Elixir application: `mix new apps/aria_gltf_geometry`
- [ ] Mesh primitive parsing and validation
- [ ] Vertex attribute handling (POSITION, NORMAL, TEXCOORD, etc.)
- [ ] Index buffer processing with Nx tensors
- [ ] Skinning data structures and joint hierarchy
- [ ] Morph target support with weight management
- [ ] Efficient tensor operations for mesh transformations

**SimpleSkin.gltf Validation Requirements**:

- [ ] Parse joint hierarchy and inverse bind matrices
- [ ] Implement 4x4 joint transformation matrix calculation
- [ ] Handle multi-joint vertex influences with weight blending
- [ ] Validate joint parent-child relationships
- [ ] Test frame-accurate joint matrix interpolation

**SimpleMorph.gltf Validation Requirements**:

- [ ] Parse morph target vertex position data
- [ ] Implement morph target weight blending algorithms
- [ ] Handle multiple simultaneous morph targets
- [ ] Validate morph target weight normalization
- [ ] Test frame-accurate morph weight interpolation

**Implementation Patterns**:

- [ ] Nx-based vertex data access patterns
- [ ] GPU-accelerated mesh transformations via TorchX
- [ ] Skin joint hierarchy validation
- [ ] Morph target weight blending algorithms
- [ ] Geometry validation and bounds checking
- [ ] Frame-accurate state calculation for both skinning and morphing

### App 4: `aria_gltf_animation` - Animation System (MEDIUM PRIORITY)

**Location**: `apps/aria_gltf_animation/`
**Dependencies**: `aria_gltf_core`, R25W1398085, `aria_timeline`

**Required Implementation**:

- [ ] Create new Elixir application: `mix new apps/aria_gltf_animation`
- [ ] Animation channel and sampler structures
- [ ] Keyframe interpolation (LINEAR, STEP, CUBICSPLINE)
- [ ] Animation target validation (translation, rotation, scale, weights)
- [ ] Integration API with aria_timeline and R25W1398085
- [ ] Temporal coordination for frame-accurate playback

**SimpleSkin.gltf Animation Requirements**:

- [ ] Parse joint rotation/translation/scale animation channels
- [ ] Implement quaternion SLERP for smooth joint rotations
- [ ] Handle keyframe timing and interpolation for joint animations
- [ ] Coordinate with R25W1398085 for temporal planning integration
- [ ] Test sub-frame accuracy for joint animation sampling

**SimpleMorph.gltf Animation Requirements**:

- [ ] Parse morph target weight animation channels
- [ ] Implement linear interpolation for morph weights
- [ ] Handle multiple morph target animations simultaneously
- [ ] Validate weight normalization during animation
- [ ] Test sub-frame accuracy for morph weight sampling

**Implementation Patterns**:

- [ ] Clean API for aria_timeline integration
- [ ] Quaternion SLERP for rotation interpolation
- [ ] Morph target weight animation
- [ ] Animation data validation and optimization
- [ ] Timeline-based animation control
- [ ] Frame-accurate temporal sampling for both joint and morph animations

### App 5: `aria_gltf_materials` - Material & Texture System (MEDIUM PRIORITY)

**Location**: `apps/aria_gltf_materials/`
**Dependencies**: `aria_gltf_core`, `aria_gltf_images`

**Required Implementation**:

- [ ] Create new Elixir application: `mix new apps/aria_gltf_materials`
- [ ] PBR metallic-roughness material model
- [ ] Texture and sampler management
- [ ] Material property validation and processing
- [ ] Integration with `aria_gltf_images` for texture loading

**Implementation Patterns**:

- [ ] Texture coordinate mapping
- [ ] Material property interpolation
- [ ] Alpha mode handling (OPAQUE, MASK, BLEND)
- [ ] Texture loading via `aria_gltf_images`
- [ ] Material validation against glTF specification

### App 6: `aria_gltf_io` - File Format I/O (HIGHEST PRIORITY - EXPORT FOCUS)

**Location**: `apps/aria_gltf_io/`
**Dependencies**: `aria_gltf_core`, `aria_gltf_images`

**Required Implementation (Export-First Approach)**:

- [ ] **PHASE 1: Basic Export** - JSON glTF file writing using existing Document.to_json/1
- [ ] **PHASE 1: File Writing** - Save minimal valid .gltf files to disk
- [ ] **PHASE 1: Minimal Scene Export** - Single mesh, single material export
- [ ] **PHASE 2: Enhanced Export** - Multiple meshes, materials, textures
- [ ] **PHASE 3: Import Support** - JSON glTF file parsing and validation
- [ ] **PHASE 3: GLB Support** - Binary format support (header, JSON chunk, binary chunk)
- [ ] **PHASE 3: URI Resolution** - Data URIs, relative paths, external files

**Implementation Patterns (Export-First)**:

- [ ] **Document.to_json/1 integration** - Leverage existing serialization
- [ ] **File system operations** - Reliable file writing with error handling
- [ ] **Minimal scene construction** - Basic cube/triangle mesh generation
- [ ] **Blender validation pipeline** - Automated import testing
- [ ] **Export integration with `aria_gltf_images`** for frame output
- [ ] **Comprehensive error handling** with detailed context

## Implementation Strategy

### Step 1: App Foundation Setup

1. Create new Elixir application: `mix new apps/aria_gltf --app aria_gltf`
2. Configure application in umbrella project (`mix.exs`, dependencies)
3. Set up application supervision tree and main API module
4. Create comprehensive test suite structure with glTF sample files
5. Define public API boundaries and integration points

### Step 2: Core Data Processing

1. Implement buffer and accessor systems for binary data handling
2. Create scene graph and node transformation logic
3. Validate against glTF 2.0 specification requirements
4. Establish error handling patterns and custom error types

### Step 3: Geometry Integration

1. Build mesh and primitive processing capabilities
2. Implement skinning system for character animation
3. Add morph target support for facial expressions
4. Create geometry validation and optimization utilities

### Step 4: Animation Pipeline

1. Design clean integration API for external timeline systems
2. Implement keyframe interpolation algorithms
3. Create animation data structures and validation
4. Provide hooks for aria_timeline integration

### Step 5: Material and I/O Systems

1. Implement PBR material model
2. Add texture and image handling
3. Create file format parsing (JSON/GLB)
4. Implement comprehensive validation and error reporting

### Current Focus: Minimal Export Pipeline for Blender Validation

**Immediate Priority: End-to-End Export Capability**

Focus on getting minimal glTF files exported and validated in Blender before tackling complex features. This provides immediate feedback on implementation correctness and establishes a working baseline.

**Phase 1: Minimal Export Pipeline (HIGHEST PRIORITY)**
1. **Basic I/O System** - JSON glTF export functionality using existing Document.to_json/1
2. **Minimal Scene Export** - Single mesh, single material, basic scene graph
3. **File Writing** - Save valid .gltf files to disk
4. **Blender Import Test** - Verify exported files load correctly in Blender

**Phase 2: Enhanced Export (HIGH PRIORITY)**
5. **Animation Channel/Sampler modules** - Complete missing animation components
6. **Basic Animation Export** - Simple keyframe animations
7. **Material Export Enhancement** - PBR materials with textures

**Phase 3: Advanced Features (MEDIUM PRIORITY)**
8. **SimpleSkin/SimpleMorph Support** - Complex animation validation
9. **Tensor Operations** - Nx/TorchX integration for performance
10. **Architecture Decision** - Single app vs. multi-app based on export experience

**Blender Validation Checkpoints:**
- [ ] Minimal scene (cube mesh) loads in Blender
- [ ] Material properties display correctly
- [ ] Animation plays back smoothly
- [ ] Complex models (SimpleSkin/SimpleMorph) import successfully

## Success Criteria

**Multi-App Architecture:**

- [ ] Six independent applications with single responsibilities
- [ ] Clean API boundaries between apps with minimal coupling
- [ ] Selective deployment capability (use only needed apps)
- [ ] Independent development and testing of each app

**Core Functionality:**

- [ ] Parse and validate standard glTF 2.0 files via `aria_gltf_io`
- [ ] Load character meshes with proper skinning data via `aria_gltf_geometry`
- [ ] Animate characters using glTF animation data via `aria_gltf_animation`
- [ ] Support PBR materials for realistic rendering via `aria_gltf_materials`
- [ ] Handle JPG/PNG read/write operations via `aria_gltf_images`
- [ ] Handle both JSON (.gltf) and binary (.glb) formats

**Integration Requirements:**

- [ ] Provide integration API for temporal planning systems (R25W1398085)
- [ ] Frame-accurate mesh state calculation pipeline
- [ ] Nx/TorchX integration for efficient tensor operations
- [ ] Export functionality for frame extraction and texture processing

**Frame-Accurate Sample Asset Validation:**

- [ ] **SimpleSkin.gltf validation**: Successfully load, parse, and animate with frame-accurate joint transformations
- [ ] **SimpleMorph.gltf validation**: Successfully load, parse, and animate with frame-accurate morph target blending
- [ ] **Temporal precision testing**: Validate sub-frame accuracy for animation sampling between keyframes
- [ ] **Export validation**: Export frame-accurate mesh states as images at arbitrary timestamps
- [ ] **Reference comparison**: Compare results against known-good reference implementations
- [ ] **Performance benchmarking**: Measure frame calculation performance for real-time applications

**Quality Assurance:**

- [ ] Maintain specification compliance for interoperability
- [ ] Comprehensive test coverage with sample glTF files per app
- [ ] Performance optimization for large assets and real-time processing
- [ ] Clear documentation and usage examples for each app
- [ ] Automated testing pipeline with SimpleSkin and SimpleMorph as canonical test cases

## Consequences

### Benefits

**Single Responsibility Architecture:**

- **Independent Development**: Teams can work on different apps simultaneously without conflicts
- **Selective Deployment**: Only include needed apps (e.g., headless systems can skip materials/images)
- **Testing Isolation**: Each app can be tested independently with focused test suites
- **Clear Boundaries**: Well-defined responsibilities prevent feature creep and coupling
- **Performance Optimization**: Each app optimized for its specific computational characteristics

**Technical Advantages:**

- **Standardization**: Adopts industry-standard 3D format with full specification compliance
- **Interoperability**: Compatible with major 3D tools and engines (Blender, Unity, Unreal)
- **Rich Animation**: Supports complex character animations and morph targets
- **Future-Proof**: Extensible format with active development and community support
- **Tensor Integration**: Nx/TorchX integration enables GPU-accelerated processing
- **Image Processing**: Native JPG/PNG support without external dependencies

**Integration Benefits:**

- **Temporal Coordination**: Clean integration with R25W1398085 for frame-accurate processing
- **Modular Reuse**: Apps can be reused across different projects and contexts
- **API Clarity**: Each app provides focused, well-documented APIs
- **Dependency Management**: Clear dependency chains prevent circular dependencies

### Risks

**Architecture Complexity:**

- **Multi-App Coordination**: Need to manage interactions between six separate applications
- **API Design**: Requires careful design of inter-app communication patterns
- **Deployment Complexity**: More apps to configure, deploy, and monitor
- **Version Synchronization**: Need to coordinate versions across related apps

**Technical Challenges:**

- **Performance Overhead**: Inter-app communication may introduce latency
- **Memory Usage**: Large 3D assets may impact system resources across multiple apps
- **Validation Overhead**: Strict specification compliance adds processing cost
- **Integration Testing**: More complex integration testing across app boundaries

**Implementation Risks:**

- **Specification Complexity**: glTF 2.0 is a comprehensive specification with many edge cases
- **Binary Data Processing**: Efficient handling of large binary assets requires optimization
- **Tensor Operations**: GPU processing may require specialized knowledge and debugging
- **Image Format Support**: Need to handle various image formats and quality settings

### Mitigation Strategies

**Architecture Management:**

- **Clear API Contracts**: Define explicit interfaces between apps with comprehensive documentation
- **Incremental Implementation**: Start with core apps, add advanced features progressively
- **Integration Testing**: Comprehensive test suites covering cross-app interactions
- **Version Management**: Coordinated release cycles for related app updates

**Performance Optimization:**

- **Streaming Support**: Implement lazy loading and streaming for large assets
- **Caching Strategies**: Cache frequently accessed data to reduce inter-app communication
- **Profiling**: Regular performance profiling of critical data processing paths
- **GPU Optimization**: Leverage TorchX for computationally intensive operations

**Quality Assurance:**

- **Specification Testing**: Test against official glTF sample models and validator
- **Error Handling**: Comprehensive error handling with detailed context across all apps
- **Documentation**: Clear usage examples and integration guides for each app
- **Community Validation**: Leverage existing glTF tools for validation and compatibility testing

## Related ADRs

- **R25W1524A37**: SimpleSkin Animation Import/Export (MERGED INTO this ADR - animation requirements incorporated)
- **R25W1398085**: Unified Durative Action Specification (MANDATORY - temporal planning foundation)
- **R25W087E1AE**: Aria Engine Plans glTF KHR Interactivity Implementation
- **R25W08877E1**: glTF Scene Foundation Implementation Plan
- **R25W093B1C8**: TDD glTF Scene Foundation Implementation
- **R25W094A7AF**: TDD glTF Core Data Structures
- **R25W095BA8C**: TDD glTF Data Loading Parsing
- **R25W0969BA8**: TDD glTF Scene Graph Logic
- **R25W09751CC**: TDD glTF Mesh Processing

## References

**glTF 2.0 Specification and Tools:**

- [glTF 2.0 Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)
- [glTF 2.0 JSON Schema](https://github.com/KhronosGroup/glTF/tree/master/specification/2.0/schema)
- [glTF Sample Models](https://github.com/KhronosGroup/glTF-Sample-Models)
- [Khronos glTF Validator](https://github.com/KhronosGroup/glTF-Validator)

**Mandatory Sample Assets for Frame-Accurate Validation:**

- [SimpleSkin.gltf](https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/SimpleSkin/glTF-Embedded/SimpleSkin.gltf) - Joint animation and skinning validation
- [SimpleMorph.gltf](https://github.com/KhronosGroup/glTF-Sample-Assets/blob/main/Models/SimpleMorph/glTF-Embedded/SimpleMorph.gltf) - Morph target blending validation

**Technical Dependencies:**

- [Nx Package](https://hex.pm/packages/nx) - Numerical computing for Elixir
- [TorchX Package](https://hex.pm/packages/torchx) - GPU-accelerated tensor operations
- [Image Package](https://hex.pm/packages/image) - JPG/PNG read/write operations
