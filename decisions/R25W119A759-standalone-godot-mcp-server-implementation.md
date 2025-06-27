# R25W119A759: Standalone Godot MCP Server Implementation

<!-- @adr_serial R25W119A759 -->

**Status:** Active (Paused)  
**Date:** June 24, 2025  
**Priority:** HIGH

## Context

Following R25W118994A's libgodot integration, we need a dedicated MCP (Model Context Protocol) server to expose Godot functionality to AI assistants and development tools. This server must be separate from the existing scheduling MCP server to maintain clean separation of concerns.

Key requirements:

- Standalone MCP server dedicated to Godot operations
- Comprehensive tool set based on ee0pdt/Godot-MCP API
- Integration with aria_godot app via Unifex NIFs
- Support for both stdio and SSE transport protocols
- Clean JSON-RPC implementation using Elixir Hermes

## Decision

Create a dedicated Godot MCP server using Elixir Hermes framework, implementing the complete ee0pdt/Godot-MCP API surface with integration to the aria_godot app.

### Architecture Components

1. **New Umbrella App**: `aria_godot_mcp`
2. **Elixir Hermes Integration**: MCP protocol implementation
3. **Tool Registry**: Complete Godot-specific MCP tools
4. **Transport Layer**: Both stdio and SSE support
5. **Bridge Layer**: Integration with aria_godot NIFs

## Implementation Plan

### Phase 1: MCP Server Foundation (HIGH PRIORITY)

**File**: `apps/aria_godot_mcp/mix.exs`

**Missing/Required**:

- [ ] Create aria_godot_mcp umbrella application
- [ ] Add Elixir Hermes MCP dependency
- [ ] Configure aria_godot app dependency
- [ ] Set up Mix tasks for server startup

**Implementation Patterns Needed**:

- [ ] Hermes MCP server configuration
- [ ] Transport protocol setup (stdio/SSE)
- [ ] Tool registration framework

### Phase 2: Node Management Tools (HIGH PRIORITY)

**File**: `apps/aria_godot_mcp/lib/aria_godot_mcp/tools/node_tools.ex`

**Missing/Required**:

- [ ] `get-scene-tree` - Returns scene tree structure
- [ ] `get-node-properties` - Gets properties of specific node
- [ ] `create-node` - Creates new node in scene
- [ ] `delete-node` - Removes node from scene
- [ ] `modify-node` - Updates node properties

**Implementation Patterns Needed**:

- [ ] MCP tool callback structure
- [ ] Node path resolution and validation
- [ ] Property serialization/deserialization
- [ ] Error handling and validation

### Phase 3: Script Management Tools (HIGH PRIORITY)

**File**: `apps/aria_godot_mcp/lib/aria_godot_mcp/tools/script_tools.ex`

**Missing/Required**:

- [ ] `list-project-scripts` - Lists all scripts in project
- [ ] `read-script` - Reads specific script content
- [ ] `modify-script` - Updates script content
- [ ] `create-script` - Creates new script file
- [ ] `analyze-script` - Provides script analysis

**Implementation Patterns Needed**:

- [ ] Script file path handling
- [ ] GDScript content parsing
- [ ] File system operations via libgodot
- [ ] Script validation and syntax checking

### Phase 4: Scene Management Tools (MEDIUM PRIORITY)

**File**: `apps/aria_godot_mcp/lib/aria_godot_mcp/tools/scene_tools.ex`

**Missing/Required**:

- [ ] `list-project-scenes` - Lists all scenes in project
- [ ] `read-scene` - Reads scene structure
- [ ] `create-scene` - Creates new scene file
- [ ] `save-scene` - Saves current scene state

**Implementation Patterns Needed**:

- [ ] Scene file format handling
- [ ] Resource path management
- [ ] Scene tree serialization
- [ ] Dependency tracking

### Phase 5: Project and Editor Tools (MEDIUM PRIORITY)

**File**: `apps/aria_godot_mcp/lib/aria_godot_mcp/tools/project_tools.ex`

**Missing/Required**:

- [ ] `get-project-info` - Gets project metadata and settings
- [ ] `get-project-settings` - Gets project configuration
- [ ] `list-project-resources` - Lists project resources
- [ ] `get-editor-state` - Gets current editor state
- [ ] `run-project` - Runs the project
- [ ] `stop-project` - Stops running project

**Implementation Patterns Needed**:

- [ ] Project file parsing
- [ ] Resource enumeration
- [ ] Process management for project execution
- [ ] State synchronization

### Phase 6: MCP Resources and Transport (LOW PRIORITY)

**File**: `apps/aria_godot_mcp/lib/aria_godot_mcp/resources.ex`

**Missing/Required**:

- [ ] `godot://script/current` - Current script resource
- [ ] `godot://scene/current` - Current scene resource
- [ ] `godot://project/info` - Project info resource
- [ ] Resource URI handling and resolution

**Implementation Patterns Needed**:

- [ ] MCP resource protocol implementation
- [ ] URI scheme handling
- [ ] Resource caching and invalidation
- [ ] Content type negotiation

## Implementation Strategy

### Step 1: Server Foundation

1. Create aria_godot_mcp app with Hermes dependency
2. Set up basic MCP server with stdio transport
3. Implement tool registration framework
4. Create bridge to aria_godot app

### Step 2: Core Tool Implementation

1. Implement node management tools (highest priority)
2. Add script management capabilities
3. Create scene manipulation tools
4. Add project information tools

### Step 3: Advanced Features

1. Implement MCP resources
2. Add SSE transport support
3. Create comprehensive error handling
4. Add logging and monitoring

### Step 4: Integration and Testing

1. Integration tests with aria_godot app
2. End-to-end MCP protocol testing
3. Performance optimization
4. Documentation and examples

### Current Focus: MCP Server Foundation

Starting with basic server setup and tool registration framework, as this provides the foundation for all Godot-specific functionality.

## Success Criteria

- [ ] MCP server starts successfully with stdio transport
- [ ] All ee0pdt/Godot-MCP tools are implemented and functional
- [ ] Integration with aria_godot app works correctly
- [ ] MCP protocol compliance verified
- [ ] Error handling is robust and informative
- [ ] Performance is acceptable for interactive use

## Consequences

**Positive:**

- Dedicated server for Godot operations
- Clean separation from scheduling MCP server
- Complete ee0pdt/Godot-MCP API compatibility
- Flexible transport protocol support
- Reusable for multiple client applications

**Negative:**

- Additional server process to manage
- Complexity of MCP protocol implementation
- Dependency on aria_godot app stability
- Need for comprehensive error handling
- Potential performance bottlenecks

## Related ADRs

- **R25W118994A**: Godot LibGodot Integration via Membrane Unifex (prerequisite)
- **R25W120FE90**: Godot-Aria Integration and Workflow Orchestration (builds on this)
- **R25W0621594**: Reconnect Scheduler to MCP (separate MCP server)
- **R25W06881B3**: Schedule Activities Data Transformer Conversion (MCP patterns)

## References

- [ee0pdt/Godot-MCP API Reference](https://github.com/ee0pdt/Godot-MCP)
- [Elixir Hermes MCP Framework](https://github.com/thmsmlr/hermes)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [MCP Tool Implementation Patterns](https://docs.modelcontextprotocol.io/concepts/tools)
