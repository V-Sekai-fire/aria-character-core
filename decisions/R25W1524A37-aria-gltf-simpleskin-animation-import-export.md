# R25W1524A37: aria_gltf SimpleSkin and SimpleMorph Animation Import/Export Implementation

<!-- @adr_serial R25W1524A37 -->

**Status:** Merged into R25W1513883  
**Date:** 2025-06-27  
**Priority:** HIGH

**→ MERGED INTO R25W1513883**: This ADR has been incorporated into R25W1513883 (Comprehensive glTF 2.0 Implementation) to resolve sequencing construction violations and provide unified glTF domain implementation.

## Domain Architecture Requirements

**MANDATORY DEPENDENCIES:**

- **MUST use R25W1398085** (Unified Durative Action Specification) for all glTF domain planning and temporal coordination
- **MUST use aria_gltf for execution** with KHR_interactivity extensions to achieve frame-accurate mesh state calculation
- **MUST use Nx** (https://hex.pm/packages/nx) with `{:torchx, "~> 0.10"}` for efficient tensor operations in mesh transformations
- **MUST support combined animation workflows** including simultaneous skinning and morphing operations

**Frame-Accurate Mesh State Calculation:**
The system must calculate precise vertex positions at any given animation timestamp through the complete transformation pipeline: Base Mesh → Morph Targets → Skinning → Final Mesh State.

## Context

The aria_gltf application currently has basic glTF 2.0 data structures implemented but lacks critical functionality for animation import/export and robust validation. The task requires implementing support for both the SimpleSkin and SimpleMorph samples from glTF-Sample-Assets, which demonstrate vertex skinning with joint hierarchies, morph target animation (blend shapes), and combined animation workflows, along with the ability to export single-frame meshes and validation matching ufbx's fuzzing standards.

### Current State Analysis

**Existing Implementation (✅ Completed):**

- Basic aria_gltf app structure with core data structures
- Document, Asset, Buffer, BufferView, Accessor modules
- Scene, Node, Mesh, Material system foundation
- JSON serialization framework in Document module

**Critical Missing Components (❌ Required):**

- Animation system (channels, samplers, interpolation)
- Skinning system (joints, inverse bind matrices, vertex weights)
- I/O system for file import/export
- Animation playback and frame extraction
- Comprehensive validation and fuzzing framework

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

## Decision

**MERGED INTO R25W1513883**: This decision has been incorporated into R25W1513883's comprehensive glTF implementation plan to avoid sequencing construction violations where both ADRs attempted to modify the same existing `aria_gltf` app simultaneously.

The animation requirements, SimpleSkin/SimpleMorph validation, and ufbx-level testing standards from this ADR are now part of R25W1513883's unified implementation strategy.

## Implementation Plan

### Phase 1: Missing Core Components (HIGH PRIORITY)

**Target**: Complete animation and skinning data structures
**Files**: `apps/aria_gltf/lib/aria_gltf/`

**Missing Animation System**:

- [ ] `animation.ex` - Animation container with channels and samplers
- [ ] `animation/channel.ex` - Animation channel targeting specific nodes/properties
- [ ] `animation/sampler.ex` - Keyframe data and interpolation methods
- [ ] `animation/interpolation.ex` - LINEAR, STEP, CUBICSPLINE interpolation algorithms

**Missing Skinning System**:

- [ ] `skin.ex` - Skin object with joint hierarchy and inverse bind matrices
- [ ] `skinning/joint.ex` - Joint transformation and hierarchy management
- [ ] `skinning/vertex_weights.ex` - Vertex weight processing and validation

**Missing Morph Target System**:

- [ ] `morph_target.ex` - Morph target data structure and validation
- [ ] `morph/weight_animation.ex` - Morph weight animation and blending
- [ ] `morph/blender.ex` - Multi-target weight blending algorithms
- [ ] `morph/validator.ex` - Morph target consistency validation

**Missing Referenced Modules**:

- [ ] `texture.ex` - Texture references and sampling
- [ ] `image.ex` - Image data and format handling
- [ ] `sampler.ex` - Texture sampling parameters
- [ ] `camera.ex` - Camera projection and view parameters

**Implementation Patterns Needed**:

- [ ] Keyframe interpolation algorithms (linear, step, cubic spline)
- [ ] Joint hierarchy traversal and transformation calculation
- [ ] Vertex weight normalization and validation
- [ ] Animation timeline evaluation at arbitrary time points

### Phase 2: I/O System Implementation (HIGH PRIORITY)

**Target**: File import/export functionality
**Files**: `apps/aria_gltf/lib/aria_gltf/io/`

**File Format Support**:

- [ ] `io/parser.ex` - JSON glTF file parsing with validation
- [ ] `io/glb.ex` - GLB binary format support (header, JSON chunk, binary chunk)
- [ ] `io/writer.ex` - glTF file writing and serialization
- [ ] `io/uri.ex` - URI resolution (data URIs, relative paths, external files)

**Validation Framework**:

- [ ] `io/validator.ex` - Comprehensive glTF specification validation
- [ ] `io/error.ex` - Structured error reporting with context
- [ ] `io/schema.ex` - JSON schema validation for glTF documents

**Implementation Patterns Needed**:

- [ ] Streaming binary data parsing for large files
- [ ] Base64 data URI encoding/decoding
- [ ] JSON schema validation with detailed error messages
- [ ] File format detection and version compatibility

### Phase 3: Animation Engine (MEDIUM PRIORITY)

**Target**: Animation playback and frame extraction
**Files**: `apps/aria_gltf/lib/aria_gltf/animation/`

**Animation Playback**:

- [ ] `animation/timeline.ex` - Timeline-based animation control
- [ ] `animation/evaluator.ex` - Animation evaluation at specific time points
- [ ] `animation/blending.ex` - Animation layer blending and composition
- [ ] `animation/frame_extractor.ex` - Single-frame mesh state extraction

**Skinning Calculations**:

- [ ] `skinning/deformer.ex` - CPU-based vertex skinning calculations
- [ ] `skinning/matrix_palette.ex` - Joint matrix palette generation
- [ ] `skinning/bounds.ex` - Animated mesh bounding box calculation

**Morph Target Calculations**:

- [ ] `morph/evaluator.ex` - Morph weight evaluation at specific time points
- [ ] `morph/deformer.ex` - CPU-based morph target blending calculations
- [ ] `morph/pipeline.ex` - Combined morph + skinning transformation pipeline

**Integration Points**:

- [ ] Clean API for aria_timeline integration
- [ ] Frame-accurate mesh export functionality
- [ ] Animation data optimization and caching
- [ ] Combined skinning + morphing workflow coordination

**Implementation Patterns Needed**:

- [ ] Quaternion SLERP for rotation interpolation
- [ ] Matrix transformation composition and optimization
- [ ] Efficient vertex transformation for large meshes
- [ ] Animation curve evaluation and caching
- [ ] Morph weight blending algorithms (linear combination)
- [ ] Transformation pipeline ordering (morph first, then skin)

### Phase 4: Validation and Testing (MEDIUM PRIORITY)

**Target**: ufbx-style validation and fuzzing
**Files**: `apps/aria_gltf/test/`

**Sample Integration**:

- [ ] `test/samples/simple_skin_test.exs` - SimpleSkin sample loading and validation
- [ ] `test/samples/simple_morph_test.exs` - SimpleMorph sample loading and validation
- [ ] `test/samples/combined_animation_test.exs` - Combined skinning + morphing workflows
- [ ] `test/samples/` - Sample glTF files for testing
- [ ] `test/animation/` - Animation-specific test cases
- [ ] `test/skinning/` - Skinning calculation validation
- [ ] `test/morphing/` - Morph target blending validation

**Fuzzing Framework**:

- [ ] `test/fuzz/` - Fuzzing test infrastructure
- [ ] `test/fuzz/binary_fuzz.exs` - Binary data modification fuzzing
- [ ] `test/fuzz/json_fuzz.exs` - JSON structure fuzzing
- [ ] `test/fuzz/semantic_fuzz.exs` - Semantic content fuzzing

**Validation Tests**:

- [ ] Edge case handling (malformed files, boundary conditions)
- [ ] Memory usage and performance benchmarking
- [ ] Cross-platform compatibility testing
- [ ] Reference implementation comparison

**Implementation Patterns Needed**:

- [ ] Property-based testing for animation calculations
- [ ] Fuzzing harness for file format variations
- [ ] Performance profiling and optimization
- [ ] Comprehensive error condition coverage

### Phase 5: Export Functionality (LOW PRIORITY)

**Target**: Single-frame mesh export and animation serialization
**Files**: `apps/aria_gltf/lib/aria_gltf/export/`

**Frame Export**:

- [ ] `export/frame_exporter.ex` - Export animated meshes at specific time points
- [ ] `export/mesh_baker.ex` - Bake animation into static mesh geometry
- [ ] `export/optimization.ex` - Mesh optimization for exported frames

**Animation Export**:

- [ ] `export/animation_writer.ex` - Animation data serialization
- [ ] `export/compression.ex` - Animation data compression and optimization
- [ ] `export/validation.ex` - Exported file validation

**Implementation Patterns Needed**:

- [ ] Efficient mesh geometry baking
- [ ] Animation data compression algorithms
- [ ] Exported file format validation
- [ ] Cross-format compatibility testing

## Implementation Strategy

### Step 1: Core Component Foundation

1. Implement missing animation and skinning modules
2. Complete Document.ex module references
3. Add comprehensive type specifications and validation
4. Create basic test structure for new modules

### Step 2: SimpleSkin Integration

1. Download and integrate SimpleSkin sample files
2. Implement basic JSON parsing for SimpleSkin.gltf
3. Validate data structure loading and parsing
4. Create reference test cases for animation data

### Step 3: Animation Engine Development

1. Implement keyframe interpolation algorithms
2. Add joint hierarchy transformation calculations
3. Create animation timeline evaluation system
4. Develop frame extraction functionality

### Step 4: Validation and Fuzzing

1. Implement comprehensive validation framework
2. Add fuzzing infrastructure for edge case testing
3. Create performance benchmarking suite
4. Validate against ufbx standards

### Step 5: Export and Optimization

1. Implement single-frame mesh export
2. Add animation data serialization
3. Optimize for performance and memory usage
4. Create comprehensive documentation and examples

### Current Focus: Phase 1 - Missing Core Components

Starting with implementing the missing animation and skinning modules that are referenced in Document.ex but don't exist yet. These are fundamental building blocks required for SimpleSkin support.

## Success Criteria

**SimpleSkin Compatibility**:

- [ ] Successfully import SimpleSkin.gltf with all animation data
- [ ] Correctly parse joint hierarchies and inverse bind matrices
- [ ] Accurately evaluate animation at arbitrary time points
- [ ] Export single-frame meshes matching reference implementations

**SimpleMorph Compatibility**:

- [ ] Successfully import SimpleMorph.gltf with all morph target data
- [ ] Correctly parse morph targets and weight animations
- [ ] Accurately evaluate morph weight blending at arbitrary time points
- [ ] Export single-frame morphed meshes matching reference implementations

**Combined Animation Functionality**:

- [ ] Support simultaneous skinning and morphing operations
- [ ] Correct transformation pipeline ordering (morph first, then skin)
- [ ] Frame-accurate calculation of final vertex positions
- [ ] Temporal synchronization of both animation types

**Animation Functionality**:

- [ ] Support all glTF interpolation methods (LINEAR, STEP, CUBICSPLINE)
- [ ] Frame-accurate animation playback
- [ ] Efficient vertex skinning calculations
- [ ] Efficient morph target blending calculations
- [ ] Integration with aria_timeline for temporal control

**Validation Standards**:

- [ ] Pass fuzzing validation equivalent to ufbx's 95% branch coverage
- [ ] Handle malformed files gracefully with detailed error reporting
- [ ] Validate against glTF 2.0 specification compliance
- [ ] Performance benchmarks within acceptable limits

**Export Capabilities**:

- [ ] Export animated meshes at specific time points
- [ ] Maintain mesh topology and material properties
- [ ] Generate valid glTF files that load in standard viewers
- [ ] Optimize exported data for size and performance

## Consequences

### Benefits

- **Complete Animation Support**: Full glTF animation pipeline from import to export
- **Industry Standard Compatibility**: Works with standard glTF tools and viewers
- **Robust Validation**: ufbx-level reliability and error handling
- **Frame Extraction**: Unique capability for single-frame mesh export
- **Integration Ready**: Clean APIs for aria_timeline and other systems

### Risks

- **Implementation Complexity**: Animation and skinning are complex domains
- **Performance Requirements**: Real-time animation evaluation demands optimization
- **Validation Overhead**: Comprehensive validation may impact performance
- **Memory Usage**: Large animated models may require memory optimization
- **Compatibility**: Must maintain compatibility with existing aria_gltf code

### Mitigation Strategies

- Implement core functionality first, optimize later
- Use property-based testing for animation calculations
- Profile and benchmark critical performance paths
- Implement streaming and lazy loading for large assets
- Maintain comprehensive test coverage throughout development

## Related ADRs

- **R25W1513883**: Comprehensive glTF 2.0 Implementation (MERGED INTO - contains all requirements from this ADR)
- **R25W1398085**: Unified Durative Action Specification (MANDATORY - temporal planning foundation)
- **apps/aria_gltf/decisions/R25W087E1AE**: Aria Engine Plans glTF KHR Interactivity Implementation
- **apps/aria_gltf/decisions/R25W08877E1**: glTF Scene Foundation Implementation Plan

## References

- [SimpleSkin Sample](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SimpleSkin)
- [SimpleMorph Sample](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/SimpleMorph)
- [glTF 2.0 Animation Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#animations)
- [glTF 2.0 Skinning Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#skins)
- [glTF 2.0 Morph Targets Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#morph-targets)
- [ufbx Testing Standards](https://github.com/ufbx/ufbx#Testing)
- [glTF Tutorial: Simple Skin](https://github.com/javagl/glTF-Tutorials/blob/master/gltfTutorial/gltfTutorial_019_SimpleSkin.md)
