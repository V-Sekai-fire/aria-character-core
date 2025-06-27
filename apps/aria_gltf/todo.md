# AriaGltf TODO

## Completed ✅

### Basic Export Functionality
- [x] Create AriaGltf.IO module for file operations
- [x] Implement export_to_file/2 function
- [x] Add validation for glTF documents before export
- [x] Handle file system errors gracefully
- [x] Create tests for export functionality

### Animation Infrastructure (Previously Completed)
- [x] AriaGltf.Animation.Channel Module
- [x] AriaGltf.Animation.Channel.Target Module  
- [x] AriaGltf.Animation.Sampler Module
- [x] Dependencies Updated (Nx, Image)
- [x] ADR R25W1513883 Progress Updated

### Core Foundation Modules (Existing)
- [x] AriaGltf.Document - Root glTF document structure
- [x] AriaGltf.Asset - Asset metadata and version info
- [x] AriaGltf.Scene - Scene graph root nodes
- [x] AriaGltf.Node - Scene graph nodes with transforms
- [x] AriaGltf.Mesh - Geometry and primitive definitions
- [x] AriaGltf.Material - Material properties and textures
- [x] AriaGltf.Accessor - Data accessor definitions
- [x] AriaGltf.Buffer - Raw binary data containers
- [x] AriaGltf.BufferView - Buffer data views and layouts
- [x] AriaGltf.TextureInfo - Texture coordinate mappings

## Next Steps / Future Work (Cold Boot Order)

### Phase 1: Complete Core Foundation (REQUIRED FIRST)
**Priority: CRITICAL - These modules are referenced by Document but missing**

- [ ] **AriaGltf.Image Module** - Image data and URI references
  - [ ] Support for embedded base64 data
  - [ ] External file URI handling
  - [ ] MIME type validation (image/jpeg, image/png)
  - [ ] JSON parsing and serialization

- [ ] **AriaGltf.Sampler Module** - Texture sampling parameters
  - [ ] Filtering modes (NEAREST, LINEAR, etc.)
  - [ ] Wrap modes (CLAMP_TO_EDGE, MIRRORED_REPEAT, REPEAT)
  - [ ] JSON parsing and serialization

- [ ] **AriaGltf.Texture Module** - Texture definitions
  - [ ] Image and sampler index references
  - [ ] Extension support
  - [ ] JSON parsing and serialization

- [ ] **AriaGltf.Camera Module** - Camera definitions
  - [ ] Perspective camera support
  - [ ] Orthographic camera support
  - [ ] JSON parsing and serialization

- [ ] **AriaGltf.Skin Module** - Skeletal animation support
  - [ ] Joint hierarchy definitions
  - [ ] Inverse bind matrices
  - [ ] JSON parsing and serialization

### Phase 2: Enhanced Validation and Quality Assurance
**Priority: HIGH - Required for reliable I/O operations**

- [ ] **Comprehensive glTF Specification Validation**
  - [ ] Asset version and generator validation
  - [ ] Required vs optional field checking
  - [ ] Index reference validation (bounds checking)
  - [ ] Data type and format validation

- [ ] **Schema Validation Against glTF 2.0 Spec**
  - [ ] JSON schema validation
  - [ ] Extension validation
  - [ ] Custom validation rules for complex constraints

- [ ] **Validation Reporting System**
  - [ ] Detailed error messages with context
  - [ ] Warning system for non-standard but valid constructs
  - [ ] Validation report generation

### Phase 3: Import Functionality
**Priority: HIGH - Core I/O capability**

- [ ] **AriaGltf.IO.import_from_file/1 Function**
  - [ ] JSON file parsing
  - [ ] Document structure validation
  - [ ] Error handling and recovery

- [ ] **JSON Parsing and Validation for Imported Files**
  - [ ] Robust JSON parsing with error recovery
  - [ ] Progressive validation (continue on non-critical errors)
  - [ ] Import options (strict vs permissive mode)

- [ ] **Basic Documentation and Examples**
  - [ ] Usage examples for import/export
  - [ ] Common patterns documentation
  - [ ] Error handling guides

### Phase 4: Enhanced I/O Features
**Priority: MEDIUM - Builds on Phase 3**

- [ ] **Malformed glTF File Recovery**
  - [ ] Partial document reconstruction
  - [ ] Missing field inference
  - [ ] Corruption detection and repair

- [ ] **External File Reference Support**
  - [ ] Image file loading (JPEG, PNG)
  - [ ] Buffer file loading (.bin files)
  - [ ] URI resolution and validation
  - [ ] Relative path handling

- [ ] **Helper Functions for Common glTF Patterns**
  - [ ] Scene creation utilities
  - [ ] Mesh generation helpers
  - [ ] Material creation shortcuts
  - [ ] Animation setup utilities

### Phase 5: Advanced Export Features
**Priority: MEDIUM - Enhanced export capabilities**

- [ ] **Buffer Data Embedding**
  - [ ] Base64 encoding for data URIs
  - [ ] Efficient binary data handling
  - [ ] Memory optimization

- [ ] **Image Embedding for Self-contained Files**
  - [ ] Base64 image encoding
  - [ ] MIME type handling
  - [ ] Size optimization

- [ ] **Export Options and Formatting**
  - [ ] Pretty print vs minified JSON
  - [ ] Custom indentation settings
  - [ ] Extension filtering options

### Phase 6: Binary glTF Support
**Priority: MEDIUM - Advanced format support**

- [ ] **Binary glTF (.glb) Export Support**
  - [ ] GLB file format structure
  - [ ] Binary chunk management
  - [ ] JSON + binary data packaging

- [ ] **Binary glTF Import Support**
  - [ ] GLB file parsing
  - [ ] Binary chunk extraction
  - [ ] JSON + binary data separation

### Phase 7: Performance and Optimization
**Priority: LOW - Performance enhancements**

- [ ] **Streaming Support for Large Files**
  - [ ] Incremental parsing
  - [ ] Memory-efficient processing
  - [ ] Progress reporting

- [ ] **Memory-efficient Buffer Handling**
  - [ ] Lazy loading strategies
  - [ ] Buffer pooling
  - [ ] Garbage collection optimization

- [ ] **Progress Callbacks for Long Operations**
  - [ ] Import/export progress tracking
  - [ ] Cancellation support
  - [ ] Time estimation

### Phase 8: Developer Experience and Integration
**Priority: LOW - Quality of life improvements**

- [ ] **Debugging Utilities and Inspection Tools**
  - [ ] Document structure visualization
  - [ ] Validation result formatting
  - [ ] Performance profiling tools

- [ ] **Pretty-printing for glTF Structure Analysis**
  - [ ] Hierarchical document display
  - [ ] Reference relationship mapping
  - [ ] Statistics and summaries

- [ ] **Asset Dependency Tracking**
  - [ ] Reference graph generation
  - [ ] Circular dependency detection
  - [ ] Unused asset identification

- [ ] **Batch Processing Utilities**
  - [ ] Multiple file processing
  - [ ] Batch validation
  - [ ] Format conversion pipelines

- [ ] **Conversion Utilities from Other 3D Formats**
  - [ ] OBJ to glTF conversion
  - [ ] FBX to glTF conversion (if feasible)
  - [ ] Custom format adapters

## Implementation Summary

**Basic Export Functionality (June 27, 2025)**
- Created `AriaGltf.IO` module with comprehensive file export capabilities
- Implemented `export_to_file/2` with proper validation and error handling
- Added directory creation, document validation, and JSON serialization
- Created `create_minimal_document/0` helper for testing and basic usage
- Full test coverage with 14 passing tests including edge cases
- Proper error handling for invalid documents, file system errors, and malformed data

**Animation Infrastructure (Previously Completed)**
- Complete JSON parsing and serialization support for animation channels
- Animation channel validation with proper target and sampler references
- Support for all glTF animation paths: translation, rotation, scale, weights
- Support for all interpolation methods: LINEAR, STEP, CUBICSPLINE
- Comprehensive error handling and glTF 2.0 specification compliance

## Cold Boot Dependency Rationale

**Phase 1 is Critical:** The missing core modules (Image, Sampler, Texture, Camera, Skin) are directly referenced by the Document module. Without these, import functionality will fail with undefined module errors.

**Phase 2 Enables Phase 3:** Comprehensive validation must exist before implementing import functionality to ensure imported documents are valid and safe to process.

**Phase 3 Enables Phase 4+:** Basic import/export must work reliably before adding advanced features like malformed file recovery or external references.

**Phases 5-8 are Independent:** Once core I/O works, advanced features can be implemented in any order based on priority and need.

## Compilation Status
✅ All existing modules compile successfully
⚠️  Missing core modules cause warnings in Document.to_json/1 and from_json/1
✅ All tests passing (14/14) for implemented functionality
🎯 Ready for Phase 1 implementation

The aria_gltf app has solid foundation but requires Phase 1 completion before reliable import/export of real glTF files is possible.
