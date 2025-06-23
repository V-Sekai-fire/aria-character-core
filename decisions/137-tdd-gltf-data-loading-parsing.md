# ADR-137: TDD glTF Data Loading & Parsing

**Status:** Paused  
**Date:** 2025-06-22  
**Paused:** 2025-06-22  
**Pause Reason:** GLTF work temporarily paused to focus on other priorities  
**Priority:** MEDIUM  
**Extracted from:** ADR-135 Phase 2

## Context

This ADR implements Phase 2 of the glTF Scene foundation using Test-Driven Development: Data Loading & Parsing. We need to create modules to load and parse .gltf (JSON) and .glb (binary) files, handle binary data, and provide typed access to buffer data.

This phase depends on the core data structures from ADR-136 and follows strict TDD methodology.

## Decision

Implement glTF data loading and parsing capabilities using strict Test-Driven Development, writing failing tests before any implementation code. Each component will be developed through Red-Green-Refactor cycles.

## TDD Implementation Plan

### 2.1 Gltf.Loader Module (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `AriaEngine.Gltf.Loader.load_file/1` with .gltf file
- [ ] **RED**: Write failing test for .glb binary file loading
- [ ] **RED**: Write failing test for invalid file format handling
- [ ] **RED**: Write failing test for JSON parsing error handling
- [ ] **GREEN**: Implement minimal Loader module to pass tests
- [ ] **REFACTOR**: Clean up file loading implementation

### 2.2 Binary Data Handling (Red-Green-Refactor)

- [ ] **RED**: Write failing test for external .bin file loading
- [ ] **RED**: Write failing test for Base64 data URI parsing
- [ ] **RED**: Write failing test for binary data validation
- [ ] **RED**: Write failing test for buffer boundary checking
- [ ] **GREEN**: Implement binary data handling to pass tests
- [ ] **REFACTOR**: Clean up binary data implementation

### 2.3 AccessorView Module (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `AriaEngine.Gltf.AccessorView.new/2`
- [ ] **RED**: Write failing test for typed data iteration (SCALAR, VEC2, VEC3, VEC4)
- [ ] **RED**: Write failing test for component type handling (BYTE, FLOAT, etc.)
- [ ] **RED**: Write failing test for byteOffset and byteStride calculations
- [ ] **RED**: Write failing test for sparse accessor data merging
- [ ] **GREEN**: Implement minimal AccessorView to pass tests
- [ ] **REFACTOR**: Clean up accessor view implementation

## Success Criteria

- [ ] Gltf.Loader successfully parses valid .gltf and .glb files
- [ ] Binary data handling correctly loads external and embedded data
- [ ] AccessorView provides typed, iterable access to buffer data
- [ ] 100% test coverage achieved through TDD cycles
- [ ] All tests written before implementation (strict RED compliance)
- [ ] Comprehensive error handling for invalid data

## Dependencies

- **ADR-136**: TDD glTF Core Data Structures (provides struct definitions)

## Blocks

- **ADR-138**: TDD Scene Graph Logic (depends on data loading capabilities)

## Related ADRs

- **ADR-135**: TDD glTF Scene Foundation Implementation (parent ADR - tombstoned)
- **ADR-130**: glTF Scene Foundation Implementation Plan (provides scope)
- **ADR-129**: AriaEngine Plans glTF KHR Interactivity Implementation (overall planning)

## Implementation Status

**Status:** Waiting for ADR-136 completion
**Next Step:** Begin 2.1 Gltf.Loader RED cycle after core structures are ready
**Timeline:** TDD approach with immediate feedback and incremental progress
