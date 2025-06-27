# R25W08877E1: glTF Scene Foundation Implementation Plan

<!-- @adr_serial R25W08877E1 -->

**Status:** Active (Paused)
**Date:** June 22, 2025
**Priority:** HIGH

## Context

This ADR formalizes the detailed implementation plan for the core glTF Scene foundation, as outlined in R25W087E1AE. A robust and accurate glTF scene graph is the foundational layer upon which all KHR_interactivity nodes will be built. This plan breaks down the required components into actionable, well-defined tasks that can be fed into the AriaEngine planner.

## Decision

Implement the glTF Scene foundation by creating the necessary Elixir data structures, data loading and parsing modules, scene graph logic, and mesh processing utilities. This provides a solid, typed foundation for all subsequent glTF-related development.

## Implementation Plan

### Phase 1: Core Data Structures

- [ ] Define Elixir structs for core glTF components to ensure type safety and structured data access.
  - [ ] **Scene Graph:** `Scene`, `Node` (with `translation`, `rotation`, `scale`, `matrix` properties).
  - [ ] **Geometry:** `Mesh`, `Mesh.Primitive`, `Accessor` (including `sparse` accessors).
  - [ ] **Data Storage:** `Buffer`, `BufferView`.
  - [ ] **Appearance:** `Material` (with `pbrMetallicRoughness`), `Texture`, `Image`, `Sampler`.
  - [ ] **Animation:** `Animation`, `Animation.Channel`, `Animation.Sampler`.
  - [ ] **Cameras:** `Camera` (with `perspective` and `orthographic` properties).
  - [ ] **Skinning:** `Skin`.

### Phase 2: Data Loading & Parsing

- [ ] Implement modules to load and parse `.gltf` (JSON) and `.glb` (binary) files.
  - [ ] **`Gltf.Loader` Module:** Create a module to handle file reading and initial JSON parsing.
  - [ ] **Binary Data Handling:** Implement logic to load data from external `.bin` files and from embedded Base64-encoded data URIs.
  - [ ] **`Gltf.AccessorView` Module:** Develop a helper module to provide a typed, iterable view into raw buffer data based on an `accessor`'s definition, correctly handling `byteOffset`, `componentType`, `type`, and `byteStride`.

### Phase 3: Scene Graph Logic

- [ ] Implement the logic required to interpret and manipulate the scene hierarchy.
  - [ ] **Node Transformations:** Create functions to compute a node's local transformation matrix from its TRS properties (or use its `matrix` property directly).
  - [ ] **Global Transformations:** Implement a function to compute a node's global transformation matrix by traversing the parent hierarchy.
  - [ ] **Scene Traversal:** Build a mechanism to recursively traverse a `scene`'s node graph.

### Phase 4: Mesh and Primitive Processing

- [ ] Develop utilities to translate raw glTF data into usable geometric representations.
  - [ ] **Vertex Data Retrieval:** Implement functions to extract vertex attributes (e.g., `POSITION`, `NORMAL`, `TEXCOORD_0`) for a `Mesh.Primitive` using its `attributes` accessors.
  - [ ] **Indexed Geometry:** Add support for handling the `indices` accessor to correctly assemble indexed primitives.
  - [ ] **Morph Targets:** Implement logic to apply morph target weights to vertex data.
  - [ ] **Skinning:** Implement logic to apply skinning transformations (joints and weights) to vertex data.

## Success Criteria

- [ ] All defined Elixir structs are implemented with corresponding typespecs.
- [ ] The `Gltf.Loader` can successfully parse valid `.gltf` and `.glb` files.
- [ ] The `Gltf.AccessorView` correctly interprets buffer data according to accessor properties.
- [ ] Scene graph traversal and transformation logic correctly computes local and global matrices.
- [ ] Mesh processing utilities can extract and assemble vertex data for rendering.
- [ ] The implementation successfully serves as the foundation for the KHR_interactivity nodes.

## Risks and Mitigation

**Risk**: The glTF specification has subtle complexities that are easy to misinterpret.
**Mitigation**: Adhere strictly to the official glTF 2.0 specification and validate against official sample models. Implement one feature at a time and test it thoroughly.

**Risk**: Performance bottlenecks in data parsing or scene graph traversal.
**Mitigation**: Profile the implementation with large glTF files and optimize critical paths. Defer computation where possible.

## Related ADRs

- **R25W087E1AE**: AriaEngine Plans glTF KHR Interactivity Implementation (Parent ADR)
