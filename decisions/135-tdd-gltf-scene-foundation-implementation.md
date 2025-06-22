# ADR-135: TDD glTF Scene Foundation Implementation

**Status:** Active  
**Date:** 2025-06-22  
**Priority:** HIGH  
**Replaces:** ADR-130 implementation approach

## Context

ADR-130 provides a comprehensive implementation plan for the glTF Scene foundation, but lacks a test-driven development methodology. Following Martin Fowler's TDD principles, we need a test-first approach that drives API design through failing tests, ensures reliable implementation, and provides immediate feedback during development.

This ADR transforms ADR-130's implementation plan into a rigorous TDD workflow with Red-Green-Refactor cycles for each component.

## Decision

Implement the glTF Scene foundation using strict Test-Driven Development, writing failing tests before any implementation code. Each component will be developed through Red-Green-Refactor cycles, ensuring test-driven API design and comprehensive coverage.

## TDD Implementation Plan

### Phase 1: Core Data Structures (TDD)

#### 1.1 Scene Struct (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Scene{}` struct creation
- [ ] **RED**: Write failing test for scene with nodes list
- [ ] **RED**: Write failing test for scene name validation
- [ ] **GREEN**: Implement minimal Scene struct to pass tests
- [ ] **REFACTOR**: Clean up Scene struct implementation

#### 1.2 Node Struct (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Node{}` struct creation
- [ ] **RED**: Write failing test for TRS properties (translation, rotation, scale)
- [ ] **RED**: Write failing test for matrix property (alternative to TRS)
- [ ] **RED**: Write failing test for children nodes list
- [ ] **RED**: Write failing test for mesh reference
- [ ] **GREEN**: Implement minimal Node struct to pass tests
- [ ] **REFACTOR**: Clean up Node struct implementation

#### 1.3 Mesh and Primitive Structs (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Mesh{}` struct creation
- [ ] **RED**: Write failing test for mesh primitives list
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Mesh.Primitive{}` struct
- [ ] **RED**: Write failing test for primitive attributes map
- [ ] **RED**: Write failing test for primitive indices reference
- [ ] **GREEN**: Implement minimal Mesh and Primitive structs
- [ ] **REFACTOR**: Clean up mesh-related implementations

#### 1.4 Buffer and Accessor Structs (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Buffer{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.BufferView{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Accessor{}` struct
- [ ] **RED**: Write failing test for accessor componentType and type validation
- [ ] **RED**: Write failing test for sparse accessor support
- [ ] **GREEN**: Implement minimal buffer and accessor structs
- [ ] **REFACTOR**: Clean up data structure implementations

#### 1.5 Material and Texture Structs (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Material{}` struct
- [ ] **RED**: Write failing test for PBR metallic roughness properties
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Texture{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Image{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Sampler{}` struct
- [ ] **GREEN**: Implement minimal material and texture structs
- [ ] **REFACTOR**: Clean up appearance-related implementations

### Phase 2: Data Loading & Parsing (TDD)

#### 2.1 Gltf.Loader Module (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `AriaEngine.Gltf.Loader.load_file/1` with .gltf file
- [ ] **RED**: Write failing test for .glb binary file loading
- [ ] **RED**: Write failing test for invalid file format handling
- [ ] **RED**: Write failing test for JSON parsing error handling
- [ ] **GREEN**: Implement minimal Loader module to pass tests
- [ ] **REFACTOR**: Clean up file loading implementation

#### 2.2 Binary Data Handling (Red-Green-Refactor)
- [ ] **RED**: Write failing test for external .bin file loading
- [ ] **RED**: Write failing test for Base64 data URI parsing
- [ ] **RED**: Write failing test for binary data validation
- [ ] **RED**: Write failing test for buffer boundary checking
- [ ] **GREEN**: Implement binary data handling to pass tests
- [ ] **REFACTOR**: Clean up binary data implementation

#### 2.3 AccessorView Module (Red-Green-Refactor)
- [ ] **RED**: Write failing test for `AriaEngine.Gltf.AccessorView.new/2`
- [ ] **RED**: Write failing test for typed data iteration (SCALAR, VEC2, VEC3, VEC4)
- [ ] **RED**: Write failing test for component type handling (BYTE, FLOAT, etc.)
- [ ] **RED**: Write failing test for byteOffset and byteStride calculations
- [ ] **RED**: Write failing test for sparse accessor data merging
- [ ] **GREEN**: Implement minimal AccessorView to pass tests
- [ ] **REFACTOR**: Clean up accessor view implementation

### Phase 3: Scene Graph Logic (TDD)

#### 3.1 Node Transformations (Red-Green-Refactor)
- [ ] **RED**: Write failing test for TRS to matrix conversion
- [ ] **RED**: Write failing test for matrix property usage (bypassing TRS)
- [ ] **RED**: Write failing test for identity transformation handling
- [ ] **RED**: Write failing test for transformation composition
- [ ] **GREEN**: Implement transformation logic to pass tests
- [ ] **REFACTOR**: Clean up transformation calculations

#### 3.2 Global Transformations (Red-Green-Refactor)
- [ ] **RED**: Write failing test for parent-child transformation chain
- [ ] **RED**: Write failing test for root node global transformation
- [ ] **RED**: Write failing test for deep hierarchy transformation
- [ ] **RED**: Write failing test for transformation caching
- [ ] **GREEN**: Implement global transformation logic
- [ ] **REFACTOR**: Clean up hierarchy traversal

#### 3.3 Scene Traversal (Red-Green-Refactor)
- [ ] **RED**: Write failing test for depth-first scene traversal
- [ ] **RED**: Write failing test for breadth-first scene traversal
- [ ] **RED**: Write failing test for node visitor pattern
- [ ] **RED**: Write failing test for traversal with transformation accumulation
- [ ] **GREEN**: Implement scene traversal mechanisms
- [ ] **REFACTOR**: Clean up traversal implementation

### Phase 4: Mesh and Primitive Processing (TDD)

#### 4.1 Vertex Data Retrieval (Red-Green-Refactor)
- [ ] **RED**: Write failing test for POSITION attribute extraction
- [ ] **RED**: Write failing test for NORMAL attribute extraction
- [ ] **RED**: Write failing test for TEXCOORD_0 attribute extraction
- [ ] **RED**: Write failing test for missing attribute handling
- [ ] **GREEN**: Implement vertex data extraction
- [ ] **REFACTOR**: Clean up attribute processing

#### 4.2 Indexed Geometry (Red-Green-Refactor)
- [ ] **RED**: Write failing test for indices accessor processing
- [ ] **RED**: Write failing test for triangle assembly from indices
- [ ] **RED**: Write failing test for non-indexed primitive handling
- [ ] **RED**: Write failing test for index bounds validation
- [ ] **GREEN**: Implement indexed geometry support
- [ ] **REFACTOR**: Clean up indexing logic

#### 4.3 Morph Targets (Red-Green-Refactor)
- [ ] **RED**: Write failing test for morph target weight application
- [ ] **RED**: Write failing test for multiple morph targets
- [ ] **RED**: Write failing test for morph target attribute blending
- [ ] **GREEN**: Implement morph target processing
- [ ] **REFACTOR**: Clean up morphing implementation

#### 4.4 Skinning Support (Red-Green-Refactor)
- [ ] **RED**: Write failing test for joint and weight attribute processing
- [ ] **RED**: Write failing test for skin matrix calculation
- [ ] **RED**: Write failing test for vertex skinning transformation
- [ ] **GREEN**: Implement skinning logic
- [ ] **REFACTOR**: Clean up skinning implementation

## TDD Success Criteria

### Test Coverage Requirements
- [ ] **100% line coverage** achieved incrementally through TDD cycles
- [ ] **All edge cases tested** before implementation
- [ ] **API design driven by tests** rather than implementation convenience
- [ ] **Comprehensive error handling** validated through failing tests

### Red-Green-Refactor Compliance
- [ ] **No implementation without failing test** - strict RED phase compliance
- [ ] **Minimal implementation** in GREEN phase - just enough to pass tests
- [ ] **Clean code** achieved through REFACTOR phase
- [ ] **Test-driven API design** - interfaces emerge from test requirements

### Integration Validation
- [ ] **Component integration tests** validate module interactions
- [ ] **End-to-end glTF loading tests** validate complete pipeline
- [ ] **Performance benchmarks** ensure acceptable processing speed
- [ ] **Memory usage validation** prevents resource leaks

## Implementation Guidelines

### TDD Cycle Discipline
1. **RED**: Write the smallest failing test that describes desired behavior
2. **GREEN**: Write the minimal code to make the test pass (no more)
3. **REFACTOR**: Clean up code while keeping tests green
4. **REPEAT**: Continue with next failing test

### Test Quality Standards
- **Descriptive test names** that explain the behavior being tested
- **Single assertion per test** for clear failure diagnosis
- **Test data isolation** to prevent test interdependencies
- **Mock external dependencies** to focus on unit behavior

### API Design Principles
- **Test-driven interfaces** - let tests drive the API shape
- **Minimal public surface** - expose only what tests require
- **Clear error handling** - test error conditions explicitly
- **Type safety** - leverage Elixir typespecs driven by test requirements

## Risks and Mitigation

**Risk**: TDD overhead slows initial development
**Mitigation**: Front-loaded test investment pays dividends in debugging time and confidence

**Risk**: Over-testing implementation details
**Mitigation**: Focus tests on behavior and public interfaces, not internal implementation

**Risk**: Test maintenance burden
**Mitigation**: Keep tests simple, focused, and well-organized with clear naming

## Related ADRs

- **ADR-130**: glTF Scene Foundation Implementation Plan (provides scope and requirements)
- **ADR-129**: AriaEngine Plans glTF KHR Interactivity Implementation (parent planning ADR)
- **ADR-131**: Unified Durative Action Specification (provides planning foundation)

## Implementation Status

**Status:** Ready to begin TDD implementation
**Next Step:** Start with Phase 1.1 - Scene Struct RED cycle
**Timeline:** TDD approach with immediate feedback and incremental progress
