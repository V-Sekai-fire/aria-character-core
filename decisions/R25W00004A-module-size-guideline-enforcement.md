# Module Size Guideline Enforcement

**Status:** Active  
**Date:** 2025-06-30  
**Serial:** R25W00004A

## Context

The .clinerules specify module size guidelines that are currently violated across the codebase:

- **200-300 lines**: Review and consider splitting (soft threshold)
- **400-500 lines**: Strong recommendation to split (firm threshold)  
- **500+ lines**: Mandatory splitting (hard limit)

Analysis reveals multiple modules violating these guidelines, with several requiring mandatory splitting.

## Violation Analysis (Updated January 7, 2025)

### Extreme Violations (1000+ lines) - **EMERGENCY PRIORITY**

✅ **ALL RESOLVED** - No modules exceed 1000 lines

### Critical Violations (500+ lines) - **MANDATORY SPLITTING**

- ~~`aria_joint/transform/tensor.ex` (653 → 59 lines)~~ - **COMPLETED**
- ~~`aria_gltf/helpers.ex` (640 → 37 lines)~~ - **COMPLETED**
- ~~`aria_math/primitives.ex` (619 → 330 lines)~~ - **COMPLETED**
- ~~`aria_math/vector3/tensor.ex` (570 → 67 lines)~~ - **COMPLETED**
- ~~`aria_timeline/internal/stn/core.ex` (550 → 92 lines)~~ - **COMPLETED**
- ~~`aria_serial/mix/tasks/decode.ex` (515 → 127 lines)~~ - **COMPLETED**
- ~~`aria_gltf/import/parser.ex` (502 → 105 lines)~~ - **COMPLETED**

### Strong Recommendation (400-500 lines)

- ~~`aria_math/primitives/tensor.ex` (493 → 47 lines)~~ - **COMPLETED**
- ~~`aria_timeline/bridge.ex` (480 → 377 lines)~~ - **COMPLETED**
- ~~`aria_gltf/mesh.ex` (480 → 200 lines)~~ - **COMPLETED**
- `aria_gltf.ex` (479 lines)
- `aria_gltf/validation.ex` (477 lines)
- `aria_core/state/relational.ex` (477 lines)
- `aria_storage/casync_decoder.ex` (472 lines)
- `aria_core/temporal/interval.ex` (469 lines)
- `aria_core/unified_domain.ex` (468 lines)
- `aria_qcp/tensor.ex` (464 lines)
- `aria_hybrid_planner/plan.ex` (455 lines)
- `aria_core/temporal_converter.ex` (453 lines)
- `aria_gltf/camera.ex` (447 lines)
- `aria_gltf/skin.ex` (446 lines)
- `aria_math/quaternion/tensor.ex` (445 lines)
- `aria_joint/joint.ex` (444 lines)
- `aria_gltf/accessor.ex` (441 lines)
- `aria_engine_core/plan.ex` (440 lines)
- `aria_gltf/mesh/tensor.ex` (439 lines)
- `aria_storage/parsers/casync_format/archive_parser.ex` (436 lines)
- `aria_core/entity/management.ex` (412 lines)
- `aria_town.ex` (404 lines)
- `aria_timeline_intervals/allen_relations.ex` (402 lines)
- `aria_hybrid_planner/engine_integration.ex` (401 lines)
- `aria_engine_core/planner.ex` (400 lines)

### Recently Resolved ✅

- ~~`aria_math/matrix4/tensor.ex` (1085 → 269 lines)~~ - **COMPLETED**
- ~~`aria_core/action_attributes.ex` (596 → 84 lines)~~ - **COMPLETED**
- ~~`aria_joint/transform/tensor.ex` (653 → 59 lines)~~ - **COMPLETED**

## Implementation Plan

### Phase 0: Emergency Splitting (PRIORITY: CRITICAL)

**Target:** Eliminate extreme violations (1000+ lines)

#### Task 0.1: Split AriaMath.Matrix4.Tensor (1085 lines) ✅ **COMPLETED**

**File:** `apps/aria_math/lib/aria_math/matrix4/tensor.ex`

**Splitting Strategy:**

- [x] **Core operations**: Basic matrix creation, multiplication, inversion (302 lines)
- [x] **Batch operations**: Batch processing for multiple matrices (219 lines)
- [x] **Memory optimization**: Memory-safe operations with chunking (331 lines)
- [x] **Transformations**: Point/vector transformations and specialized matrices (392 lines)

**Implementation Steps:**

1. ✅ Create `matrix4/core.ex` for basic matrix operations
2. ✅ Create `matrix4/batch.ex` for batch processing operations
3. ✅ Create `matrix4/memory.ex` for memory-optimized operations
4. ✅ Create `matrix4/transformations.ex` for transformation utilities
5. ✅ Update main tensor module to delegate appropriately
6. ✅ Verify all mathematical operations remain accurate

**Results:** Successfully split 1085-line module into 4 focused modules:

- **Core** (302 lines): Basic matrix operations, creation, multiplication, inversion
- **Batch** (219 lines): Batch processing operations for multiple matrices
- **Memory** (331 lines): Memory-safe operations with CUDA OOM prevention
- **Transformations** (392 lines): Transformation matrices and point/vector operations
- **Main Tensor** (269 lines): Clean delegation API maintaining backward compatibility

**Status:** ✅ **COMPLETED** - Extreme violation eliminated, all modules under firm threshold

### Phase 1: Mandatory Splitting (PRIORITY: HIGH)

**Target:** Eliminate all 500+ line violations

#### Task 1.1: Split AriaCore.ActionAttributes (596 lines) ✅ **COMPLETED**

**File:** `apps/aria_core/lib/aria_core/action_attributes.ex`

**Splitting Strategy:**

- [x] **Main module**: Macro system and `__using__` logic (77 lines)
- [x] **Documentation module**: All `*_attribute_docs` functions (145 lines)
- [x] **Converters module**: All `convert_*_metadata` functions (145 lines)
- [x] **Registry module**: `create_entity_registry` and `create_temporal_specifications` (79 lines)
- [x] **Macros module**: All attribute macro definitions (115 lines)
- [x] **Compiler module**: Compilation-time processing (274 lines - **SOFT THRESHOLD**)

**Implementation Steps:**

1. ✅ Create `action_attributes/documentation.ex` for docs functions
2. ✅ Create `action_attributes/converters.ex` for metadata conversion
3. ✅ Create `action_attributes/registry.ex` for registry creation
4. ✅ Create `action_attributes/macros.ex` for attribute macros
5. ✅ Create `action_attributes/compiler.ex` for compilation processing
6. ✅ Update main module to delegate to split modules
7. ✅ All unused attribute warnings resolved

**Results:** Successfully split into 6 focused modules. Compiler module at 274 lines falls into soft threshold (200-300 lines) but has focused responsibility with tightly coupled compilation hooks and code generation. Splitting deferred until Domain API stabilizes.

**Status:** ✅ **COMPLETED** - All critical violations resolved, system functional

#### Task 1.2: Split AriaJoint.Transform.Tensor (653 lines) ✅ **COMPLETED**

**File:** `apps/aria_joint/lib/aria_joint/transform/tensor.ex`

**Splitting Strategy:**

- [x] **Core operations**: Basic tensor operations and conversions (137 lines)
- [x] **Operations module**: Transform and coordinate operations (144 lines)
- [x] **Hierarchy module**: Hierarchy propagation and global transforms (224 lines)
- [x] **Advanced module**: IK solving and integration functions (99 lines)

**Implementation Steps:**

1. ✅ Create `tensor/core.ex` for basic tensor operations and conversions
2. ✅ Create `tensor/operations.ex` for transform and coordinate operations
3. ✅ Create `tensor/hierarchy.ex` for hierarchy propagation logic
4. ✅ Create `tensor/advanced.ex` for IK solving and integration functions
5. ✅ Update main tensor module to delegate to split modules
6. ✅ Verify tensor performance benchmarks remain functional

**Results:** Successfully split 653-line module into 4 focused modules:

- **Core** (137 lines): Basic tensor operations, joint conversions, data extraction
- **Operations** (144 lines): Transform applications, coordinate space conversions
- **Hierarchy** (224 lines): Global transform computation, memory-optimized propagation
- **Advanced** (99 lines): IK solving, integration functions, batch operations
- **Main Tensor** (59 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all modules under soft threshold

#### Task 1.3: Split AriaGltf.Helpers (640 lines) ✅ **COMPLETED**

**File:** `apps/aria_gltf/lib/aria_gltf/helpers.ex`

**Splitting Strategy:**

- [x] **Document creation**: Document, scene, and node creation utilities (145 lines)
- [x] **Mesh creation**: Mesh and primitive creation with geometry data (200 lines)
- [x] **Material creation**: PBR material creation and configuration (85 lines)
- [x] **Animation creation**: Animation, channel, and sampler creation (86 lines)
- [x] **Buffer management**: Buffer, buffer view, and accessor management (178 lines)

**Implementation Steps:**

1. ✅ Create `helpers/document_creation.ex` for document and scene utilities
2. ✅ Create `helpers/mesh_creation.ex` for mesh and geometry creation
3. ✅ Create `helpers/material_creation.ex` for PBR material setup
4. ✅ Create `helpers/animation_creation.ex` for animation utilities
5. ✅ Create `helpers/buffer_management.ex` for buffer and accessor management
6. ✅ Update main helpers module to delegate to specialized modules
7. ✅ Verify all glTF creation functionality remains intact

**Results:** Successfully split 640-line module into 5 focused modules:

- **DocumentCreation** (145 lines): Document, scene, and node creation utilities
- **MeshCreation** (200 lines): Mesh primitives and complete geometry creation
- **MaterialCreation** (85 lines): PBR material configuration and setup
- **AnimationCreation** (86 lines): Animation channels, samplers, and interpolation
- **BufferManagement** (178 lines): Buffer, buffer view, and accessor management
- **Main Helpers** (37 lines): Clean delegation API maintaining backward compatibility

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all modules under firm threshold

#### Task 1.4: Split AriaMath.Primitives (619 lines) ✅ **COMPLETED**

**File:** `apps/aria_math/lib/aria_math/primitives.ex`

**Splitting Strategy:**

- [x] **Core primitives**: Basic shapes (box, plane, triangle) (145 lines)
- [x] **Operations**: Transform, merge, and geometric operations (85 lines)
- [x] **Math utilities**: Mathematical utility functions (86 lines)
- [x] **Main module**: Clean delegation API with comprehensive documentation (330 lines)

**Implementation Steps:**

1. ✅ Create `primitives/core.ex` for basic shape generation
2. ✅ Create `primitives/operations.ex` for transform and merge operations
3. ✅ Create `primitives/math_utils.ex` for mathematical utilities
4. ✅ Update main primitives module to delegate to split modules
5. ✅ Fix infinity handling to eliminate arithmetic warnings
6. ✅ Preserve all existing API functionality through delegation
7. ✅ Maintain comprehensive documentation and examples

**Results:** Successfully split 619-line module into 4 focused modules:

- **Core** (145 lines): Basic shape generation (box, plane, triangle)
- **Operations** (85 lines): Transform and merge operations for primitives
- **MathUtils** (86 lines): Mathematical utility functions with proper infinity handling
- **Main Primitives** (330 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all modules under firm threshold

#### Task 1.5: Split AriaMath.Vector3.Tensor (570 lines) ✅ **COMPLETED**

**File:** `apps/aria_math/lib/aria_math/vector3/tensor.ex`

**Splitting Strategy:**

- [x] **Core operations**: Basic vector creation and conversion (95 lines)
- [x] **Math operations**: Mathematical operations (dot, cross, normalize) (118 lines)
- [x] **Batch operations**: Batch processing for multiple vectors (150 lines)
- [x] **Memory optimization**: Memory-safe operations with chunking (140 lines)
- [x] **Monitoring utilities**: Memory monitoring and optimization tools (87 lines)

**Implementation Steps:**

1. ✅ Create `vector3/tensor/core.ex` for basic vector operations
2. ✅ Create `vector3/tensor/math.ex` for mathematical operations
3. ✅ Create `vector3/tensor/batch.ex` for batch processing operations
4. ✅ Create `vector3/tensor/memory.ex` for memory-optimized operations
5. ✅ Create `vector3/tensor/monitoring.ex` for memory monitoring utilities
6. ✅ Update main tensor module to delegate to split modules
7. ✅ Verify all vector operations remain accurate and memory-safe

**Results:** Successfully split 570-line module into 5 focused modules:

- **Core** (95 lines): Basic vector creation, conversion, length, and magnitude
- **Math** (118 lines): Mathematical operations (dot, cross, normalize) with numerical stability
- **Batch** (150 lines): Batch processing operations for multiple vectors
- **Memory** (140 lines): Memory-safe operations with automatic chunking and CPU fallback
- **Monitoring** (87 lines): Memory monitoring and optimization utilities
- **Main Tensor** (67 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all modules under soft threshold

#### Task 1.6: Split Timeline.Internal.STN.Core (550 lines) ✅ **COMPLETED**

**File:** `apps/aria_timeline/lib/timeline/internal/stn/core.ex`

**Splitting Strategy:**

- [x] **Operations module**: Core interval and constraint management (200 lines)
- [x] **Consistency module**: Validation and mathematical consistency checks (150 lines)
- [x] **Scheduling module**: Interval queries and scheduling operations (200 lines)
- [x] **Core delegation**: Clean API maintaining backward compatibility (92 lines)

**Implementation Steps:**

1. ✅ Create `stn/operations.ex` for core add/remove operations
2. ✅ Create `stn/consistency.ex` for validation logic  
3. ✅ Create `stn/scheduling.ex` for interval scheduling
4. ✅ Update main core module to delegate appropriately
5. ✅ Verify STN functionality remains intact

**Results:** Successfully split 550-line module into 3 focused modules:

- **Operations** (200 lines): Core interval and constraint management, time point operations
- **Consistency** (150 lines): STN validation, mathematical consistency checks, classification
- **Scheduling** (200 lines): Interval queries, overlap detection, slot finding, conflict checking
- **Main Core** (92 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all basic STN tests pass

#### Task 1.3: Split Mix.Tasks.Serial.Decode (515 lines) ✅ **COMPLETED**

**File:** `apps/aria_serial/lib/mix/tasks/decode.ex`

**Splitting Strategy:**

- [x] **Mix task interface**: CLI parsing and main run function (127 lines)
- [x] **Display module**: Formatting and output functions (251 lines)
- [x] **Similarity module**: String matching algorithms (242 lines)

**Implementation Steps:**

1. ✅ Create `aria_serial/display.ex` for output formatting
2. ✅ Create `aria_serial/similarity.ex` for string matching
3. ✅ Update mix task to use extracted modules
4. ✅ Test CLI functionality thoroughly

**Results:** Successfully split 515-line module into 3 focused modules:

- **Main Mix Task** (127 lines): CLI interface, option parsing, and coordination logic
- **Display Module** (251 lines): All console output, formatting, calendar display, and help
- **Similarity Module** (242 lines): String matching algorithms (Jaro, Levenshtein, prefix matching)

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all functionality preserved

#### Task 1.8: Split AriaGltf.Import.Parser (502 lines) ✅ **COMPLETED**

**File:** `apps/aria_gltf/lib/aria_gltf/import/parser.ex`

**Splitting Strategy:**

- [x] **Scene parsing**: Asset, scenes, nodes, and cameras (180 lines)
- [x] **Geometry parsing**: Meshes, accessors, buffers, and buffer views (200 lines)
- [x] **Material parsing**: Materials, textures, images, and samplers (150 lines)
- [x] **Animation parsing**: Skins and animations with channels/samplers (105 lines)
- [x] **Main parser**: Coordination and validation logic (105 lines)

**Implementation Steps:**

1. ✅ Create `parser/scene.ex` for scene-related parsing
2. ✅ Create `parser/geometry.ex` for geometry and buffer parsing
3. ✅ Create `parser/material.ex` for material and texture parsing
4. ✅ Create `parser/animation.ex` for animation and skin parsing
5. ✅ Update main parser module to coordinate specialized parsers
6. ✅ Fix Import module to use correct parser functions
7. ✅ Verify all glTF parsing functionality remains intact

**Results:** Successfully split 502-line module into 4 specialized parsers:

- **Scene** (180 lines): Asset, scenes, nodes, cameras parsing with proper validation
- **Geometry** (200 lines): Meshes, primitives, accessors, buffers, buffer views parsing
- **Material** (150 lines): Materials, textures, images, samplers with PBR support
- **Animation** (105 lines): Skins and animations with channels, samplers, targets
- **Main Parser** (105 lines): Document coordination, validation, and error handling

**Status:** ✅ **COMPLETED** - Critical violation eliminated, all modules under firm threshold

#### Task 1.9: Split AriaMath.Primitives.Tensor (493 lines) ✅ **COMPLETED**

**File:** `apps/aria_math/lib/aria_math/primitives/tensor.ex`

**Splitting Strategy:**

- [x] **Core operations**: Conversion and utility functions (103 lines)
- [x] **Shape generation**: Basic shape creation (box, sphere, plane) (304 lines)
- [x] **Operations**: Transform, merge, and manipulation operations (106 lines)
- [x] **Main module**: Clean delegation API maintaining backward compatibility (47 lines)

**Implementation Steps:**

1. ✅ Create `tensor/core.ex` for conversion and utility functions
2. ✅ Create `tensor/shapes.ex` for shape generation with complex sphere subdivision
3. ✅ Create `tensor/operations.ex` for transformation and manipulation operations
4. ✅ Update main tensor module to delegate to split modules
5. ✅ Verify all Nx tensor operations remain accurate and efficient

**Results:** Successfully split 493-line module into 3 focused modules:

- **Core** (103 lines): Conversion functions, bounding box calculations, type definitions
- **Shapes** (304 lines): Complex shape generation including sphere subdivision algorithms
- **Operations** (106 lines): Transform, merge, scale, and translate operations
- **Main Tensor** (47 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Firm threshold violation eliminated, all modules well-organized

#### Task 1.10: Split Timeline.Bridge (480 lines) ✅ **COMPLETED**

**File:** `apps/aria_timeline/lib/timeline/bridge.ex`

**Splitting Strategy:**

- [x] **Management module**: Bridge creation, validation, and type checking (180 lines)
- [x] **Queries module**: Temporal queries and filtering operations (120 lines)
- [x] **Main module**: Clean delegation API maintaining backward compatibility (377 lines)

**Implementation Steps:**

1. ✅ Create `bridge/management.ex` for bridge creation and validation
2. ✅ Create `bridge/queries.ex` for temporal query operations
3. ✅ Update main bridge module to delegate to split modules
4. ✅ Remove unused module attributes and helper functions
5. ✅ Verify all bridge functionality remains intact

**Results:** Successfully split 480-line module into 2 focused modules:

- **Management** (180 lines): Bridge creation, validation, type checking, metadata updates
- **Queries** (120 lines): Temporal queries, filtering, sorting, and range operations
- **Main Bridge** (377 lines): Clean delegation API maintaining full backward compatibility

**Status:** ✅ **COMPLETED** - Firm threshold violation eliminated, clear architectural boundaries

### Phase 2: Firm Threshold Modules (PRIORITY: MEDIUM)

**Target:** Address 400-500 line modules systematically

#### Task 2.1: Split AriaGltf.Mesh (480 lines) ✅ **COMPLETED**

**File:** `apps/aria_gltf/lib/aria_gltf/mesh.ex`

**Splitting Strategy:**

- [x] **Primitive module**: Extract `AriaGltf.Mesh.Primitive` to separate file (280 lines)
- [x] **Main mesh module**: Keep mesh management and validation logic (200 lines)

**Implementation Steps:**

1. ✅ Create `mesh/primitive.ex` for primitive struct and operations
2. ✅ Remove Primitive module from main mesh file
3. ✅ Add proper alias to reference extracted module
4. ✅ Verify compilation and functionality preservation

**Results:** Successfully split 480-line module into 2 focused modules:

- **Primitive** (280 lines): Complete primitive struct, validation, JSON conversion
- **Main Mesh** (200 lines): Mesh management, primitive coordination, validation
- **Clean separation**: Primitive is self-contained with its own validation and creation

**Status:** ✅ **COMPLETED** - Firm threshold violation eliminated, clear architectural boundaries

#### Planning Approach

- [ ] Analyze each 400+ line module for logical splitting points
- [ ] Prioritize by architectural impact and usage frequency
- [ ] Split modules with clear responsibility boundaries first
- [ ] Address tightly coupled modules requiring careful extraction

### Phase 3: Soft Threshold Review (PRIORITY: LOW)

**Target:** Review 200-300 line modules for potential improvements

#### Review Criteria

- [ ] Multiple distinct responsibilities within single module
- [ ] High complexity or cognitive load
- [ ] Frequent modification requiring careful changes
- [ ] Clear benefits from splitting outweigh maintenance overhead

## Success Criteria

### Phase 0 Success ✅ **COMPLETED**

- [x] **Zero modules over 1000 lines** - eliminate all extreme violations
- [x] **Matrix4.Tensor split successful** - 1085 → 269 lines with 4 focused modules
- [x] **ActionAttributes split successful** - 596 → 84 lines with 6 focused modules
- [x] **All functionality preserved** - tests passing, backward compatibility maintained

### Immediate Success (Phase 1) ✅ **COMPLETED**

- [x] **Zero modules over 500 lines** - eliminate all mandatory violations
- [x] **All tests passing** - functionality preserved after splitting
- [x] **Clean module boundaries** - each split module has single responsibility
- [x] **Proper delegation** - main modules coordinate split functionality

### Complete Success (All Phases)  

- [ ] **Consistent module sizes** - most modules under 300 lines
- [ ] **Clear architecture** - module boundaries reflect logical responsibilities
- [ ] **Maintainable codebase** - easier to understand and modify individual modules
- [ ] **Documentation compliance** - all modules follow size guidelines

## Implementation Strategy

### Systematic Approach

1. **Backup original files** with `.bak` extension for safety
2. **Identify logical boundaries** within each large module
3. **Create split modules** with focused responsibilities  
4. **Update main module** to delegate to split modules
5. **Verify functionality** through comprehensive testing
6. **Document split rationale** for future maintenance

### Risk Mitigation

- **Incremental changes** - split one module completely before starting next
- **Comprehensive testing** - verify each split maintains functionality
- **Clear commit messages** - document what was split and why
- **Backup strategy** - preserve original files during transition

## Related ADRs

- **INST-041**: Apps todo file management - provides umbrella structure requirements
- **INST-036**: Elixir module splitting - defines splitting methodology
- **INST-035**: Logical commit grouping - ensures proper change tracking

## Current Focus

**CURRENT PRIORITY:** With all critical violations resolved, focus shifts to **Phase 2: Firm Threshold Modules (400-500 lines)**.

**Phase 1 Complete ✅:** All mandatory violations (500+ lines) have been successfully resolved:

- ✅ **AriaGltf.Import.Parser** (502 → 105 lines) - glTF parsing module with 4 specialized parsers
- ✅ **AriaSerial.Mix.Tasks.Decode** (515 → 127 lines) - CLI task module with Display and Similarity extraction
- ✅ **AriaGltf.Helpers** (640 → 37 lines) - High-impact utility module with 5 specialized helpers
- ✅ **AriaMath.Primitives** (619 → 330 lines) - Core mathematical operations with focused modules
- ✅ **AriaMath.Vector3.Tensor** (570 → 67 lines) - Vector operations with 5 specialized modules
- ✅ **Timeline.Internal.STN.Core** (550 → 92 lines) - Critical temporal planning component
- ✅ **AriaJoint.Transform.Tensor** (653 → 59 lines) - Transform operations with 4 focused modules

**Next Phase:** Focus on 25 modules in the 400-500 line range, starting with highest-impact modules and those with clear responsibility boundaries.

**Success Metrics:**

- ✅ **Phase 0 Complete:** Zero extreme violations (1000+ lines)
- ✅ **Phase 1 Complete:** Zero critical violations (500+ lines)
- 🎯 **Phase 2 Target:** Reduce firm threshold violations (400-500 lines)
- 📊 **Overall Progress:** All mandatory violations resolved, 25 firm threshold modules remaining
