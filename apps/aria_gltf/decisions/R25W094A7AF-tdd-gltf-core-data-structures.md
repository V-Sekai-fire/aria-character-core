# R25W094A7AF: TDD glTF Core Data Structures

<!-- @adr_serial R25W094A7AF -->

**Status:** Paused  
**Date:** 2025-06-22  
**Paused:** 2025-06-22  
**Pause Reason:** GLTF work temporarily paused to focus on other priorities  
**Priority:** HIGH  
**Extracted from:** R25W093B1C8 Phase 1

## Context

This ADR implements Phase 1 of the glTF Scene foundation using Test-Driven Development: Core Data Structures. We need to create the fundamental Elixir structs for glTF components (Scene, Node, Mesh, Buffer, Material, etc.) using strict TDD methodology.

Following Martin Fowler's TDD principles, each struct will be developed through Red-Green-Refactor cycles, ensuring test-driven API design and type safety.

## Decision

Implement all core glTF data structures using strict Test-Driven Development, writing failing tests before any implementation code. Each component will be developed through Red-Green-Refactor cycles.

## TDD Implementation Plan

### 1.1 Scene Struct (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Scene{}` struct creation
- [ ] **RED**: Write failing test for scene with nodes list
- [ ] **RED**: Write failing test for scene name validation
- [ ] **GREEN**: Implement minimal Scene struct to pass tests
- [ ] **REFACTOR**: Clean up Scene struct implementation

### 1.2 Node Struct (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Node{}` struct creation
- [ ] **RED**: Write failing test for TRS properties (translation, rotation, scale)
- [ ] **RED**: Write failing test for matrix property (alternative to TRS)
- [ ] **RED**: Write failing test for children nodes list
- [ ] **RED**: Write failing test for mesh reference
- [ ] **GREEN**: Implement minimal Node struct to pass tests
- [ ] **REFACTOR**: Clean up Node struct implementation

### 1.3 Mesh and Primitive Structs (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Mesh{}` struct creation
- [ ] **RED**: Write failing test for mesh primitives list
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Mesh.Primitive{}` struct
- [ ] **RED**: Write failing test for primitive attributes map
- [ ] **RED**: Write failing test for primitive indices reference
- [ ] **GREEN**: Implement minimal Mesh and Primitive structs
- [ ] **REFACTOR**: Clean up mesh-related implementations

### 1.4 Buffer and Accessor Structs (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Buffer{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.BufferView{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Accessor{}` struct
- [ ] **RED**: Write failing test for accessor componentType and type validation
- [ ] **RED**: Write failing test for sparse accessor support
- [ ] **GREEN**: Implement minimal buffer and accessor structs
- [ ] **REFACTOR**: Clean up data structure implementations

### 1.5 Material and Texture Structs (Red-Green-Refactor)

- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Material{}` struct
- [ ] **RED**: Write failing test for PBR metallic roughness properties
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Texture{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Image{}` struct
- [ ] **RED**: Write failing test for `%AriaEngine.Gltf.Sampler{}` struct
- [ ] **GREEN**: Implement minimal material and texture structs
- [ ] **REFACTOR**: Clean up appearance-related implementations

## Success Criteria

- [ ] All core glTF structs implemented with typespecs
- [ ] 100% test coverage achieved through TDD cycles
- [ ] All tests written before implementation (strict RED compliance)
- [ ] Clean, test-driven API design
- [ ] Type safety validated through comprehensive tests

## Dependencies

- **R25W089FC2D**: Unified Durative Action Specification (provides planning foundation)

## Blocks

- **R25W095BA8C**: TDD Data Loading & Parsing (depends on these core structures)

## Related ADRs

- **R25W093B1C8**: TDD glTF Scene Foundation Implementation (parent ADR - tombstoned)
- **R25W08877E1**: glTF Scene Foundation Implementation Plan (provides scope)
- **R25W087E1AE**: AriaEngine Plans glTF KHR Interactivity Implementation (overall planning)

## Implementation Status

**Status:** Ready to begin TDD implementation
**Next Step:** Start with 1.1 Scene Struct RED cycle
**Timeline:** TDD approach with immediate feedback and incremental progress
