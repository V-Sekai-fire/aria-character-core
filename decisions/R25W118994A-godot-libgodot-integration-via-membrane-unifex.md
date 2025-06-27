# R25W118994A: Godot LibGodot Integration via Membrane Unifex

<!-- @adr_serial R25W118994A -->

**Status:** Active (Paused)  
**Date:** June 24, 2025  
**Priority:** HIGH

## Context

The project requires integration with Godot Engine to enable game development capabilities within the Aria ecosystem. The libgodot feature (PR #90510) provides a way to embed Godot as a library, allowing host applications to control Godot instances programmatically.

Key requirements:

- Embed Godot Engine as a library within Elixir applications
- Control Godot lifecycle (startup, iteration, shutdown) from Elixir
- Manipulate scenes, nodes, and scripts programmatically
- Safe interop between Elixir and C++ libgodot code
- Cross-platform support (Linux, macOS, Windows)

## Decision

Implement Godot integration using libgodot via Membrane Unifex NIFs, leveraging V-Sekai's proven libgodot bundling approach.

### Architecture Components

1. **New Umbrella App**: `aria_godot`
2. **LibGodot Integration**: Use V-Sekai's libgodot_project bundling
3. **Membrane Unifex NIFs**: Safe Elixir-C++ interop layer
4. **Godot Instance Management**: Lifecycle control and state management

## Implementation Plan

### Phase 1: Project Structure and Dependencies (HIGH PRIORITY)

**File**: `apps/aria_godot/mix.exs`

**Missing/Required**:

- [ ] Create aria_godot umbrella application
- [ ] Add Membrane Unifex dependency
- [ ] Configure libgodot shared library integration
- [ ] Set up cross-platform build configuration

**Implementation Patterns Needed**:

- [ ] Unifex NIF module structure
- [ ] LibGodot shared library loading
- [ ] Cross-platform library path resolution

### Phase 2: LibGodot Integration (HIGH PRIORITY)

**File**: `apps/aria_godot/c_src/godot_nif.cpp`

**Missing/Required**:

- [ ] Integrate V-Sekai libgodot bundled library
- [ ] Implement GodotInstance lifecycle management
- [ ] Create C++ wrapper functions for Unifex
- [ ] Handle libgodot initialization and cleanup

**Implementation Patterns Needed**:

- [ ] GodotInstance creation via gdextension_create_godot_instance
- [ ] Safe resource management and cleanup
- [ ] Error handling and status reporting

### Phase 3: Elixir NIF Interface (MEDIUM PRIORITY)

**File**: `apps/aria_godot/lib/aria_godot/engine.ex`

**Missing/Required**:

- [ ] Elixir module wrapping Unifex NIFs
- [ ] GodotInstance GenServer for state management
- [ ] Scene and node manipulation functions
- [ ] Script reading and modification capabilities

**Implementation Patterns Needed**:

- [ ] GenServer lifecycle management
- [ ] Unifex function bindings
- [ ] Error handling and supervision

### Phase 4: Core Godot Operations (MEDIUM PRIORITY)

**File**: `apps/aria_godot/lib/aria_godot/scene.ex`

**Missing/Required**:

- [ ] Scene tree traversal and manipulation
- [ ] Node creation, modification, deletion
- [ ] Property getting and setting
- [ ] Scene loading and saving

**Implementation Patterns Needed**:

- [ ] Scene tree data structures
- [ ] Node property serialization
- [ ] Resource path handling

## Implementation Strategy

### Step 1: Environment Setup

1. Create aria_godot umbrella app with Unifex dependency
2. Integrate V-Sekai libgodot bundled libraries
3. Configure cross-platform build system
4. Set up basic NIF compilation

### Step 2: Core Integration

1. Implement basic GodotInstance lifecycle NIFs
2. Create Elixir wrapper modules
3. Add GenServer for instance management
4. Implement basic scene operations

### Step 3: Extended Functionality

1. Add comprehensive scene manipulation
2. Implement script operations
3. Add project management functions
4. Create resource handling capabilities

### Current Focus: Project Structure Setup

Starting with aria_godot app creation and libgodot integration, as this provides the foundation for all subsequent functionality.

## Success Criteria

- [ ] aria_godot app compiles successfully on all target platforms
- [ ] GodotInstance can be created, started, and shutdown from Elixir
- [ ] Basic scene operations work (get scene tree, create nodes)
- [ ] Memory management is safe (no leaks or crashes)
- [ ] Integration tests pass for core functionality

## Consequences

**Positive:**

- Enables Godot game development within Aria ecosystem
- Provides foundation for MCP server implementation
- Leverages proven libgodot integration approach
- Safe interop via Membrane Unifex

**Negative:**

- Adds complexity with C++ compilation requirements
- Platform-specific build configuration needed
- Dependency on external libgodot library
- Potential memory management challenges

## Related ADRs

- **R25W119A759**: Standalone Godot MCP Server Implementation (depends on this ADR)
- **R25W120FE90**: Godot-Aria Integration and Workflow Orchestration (depends on this ADR)
- **R25W070D1AF**: Membrane Planning Pipeline Integration (related membrane usage)

## References

- [Godot LibGodot PR #90510](https://github.com/godotengine/godot/pull/90510)
- [V-Sekai libgodot_project](https://github.com/V-Sekai/libgodot_project/tree/libvsekai)
- [Membrane Unifex Documentation](https://github.com/membraneframework/unifex)
