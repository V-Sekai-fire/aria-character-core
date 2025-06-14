# ADR-029: MCP Integration for GitHub Copilot Access

## Status

Superseded by ADR-033

**Note**: This ADR has been superseded by ADR-033, which provides complete TDD completion criteria and focuses on AriaEngine.Domain planning capabilities rather than generic character management.

## Date

2025-06-14

## Context

Aria character core needs to be accessible from GitHub Copilot within VS Code to enable developers to interact with the character system directly from their development environment.
This requires exposing Aria through the Model Context Protocol (MCP) which allows language models to access external tools and services.

## Decision

Implement an MCP server that exposes key Aria functionality as tools that can be invoked by GitHub Copilot using the Hermes MCP library for stdio transport.

## Rationale

- Enables natural language interaction with Aria from within VS Code
- Leverages existing Hermes MCP library with proven stdio support for Elixir
- Provides contextual character assistance during development
- Creates reusable integration pattern for other development environments
- Uses stdio transport for seamless GitHub Copilot integration

## Consequences

### Positive

- Natural language interaction with Aria from VS Code
- Contextual development assistance
- Leverages existing Aria capabilities without reimplementation
- Proven library foundation reduces implementation risk
- Seamless stdio integration with GitHub Copilot

### Negative

- Additional dependency on Hermes MCP library
- Security considerations for MCP tool access
- Performance optimization needed for real-time assistance

## Implementation Details

### Technical Architecture

1. **MCP Server Module**: Create `aria_mcp_server` application within umbrella project
2. **Hermes MCP Integration**: Use [Hermes MCP](https://github.com/cloudwalk/hermes-mcp) library for stdio transport
3. **Protocol Compliance**: Leverage Hermes MCP's MCP specification implementation
4. **Core Functionality Exposure**:
   - Character creation and management
   - Workflow planning and execution
   - File system operations with character context
   - Temporal planning capabilities
5. **VS Code Integration**: Configure as stdio-based MCP server for GitHub Copilot discovery

### Implementation Phases

1. **Phase 1**: Basic MCP server with core character operations using Hermes MCP stdio
2. **Phase 2**: Advanced workflow and planning tool exposure
3. **Phase 3**: Context-aware development assistance tools

### Considerations

- **Library Integration**: Use Hermes MCP's proven stdio implementation
- **Transport Layer**: Stdio transport for GitHub Copilot compatibility
- **Security**: Proper authentication and authorization for MCP tools
- **Completion Criteria**: See ADR-033 for comprehensive TDD objectives and acceptance criteria

## Related Decisions

- Links to ADR-025 (Research Strategy) for development support and tooling
- Supports ADR-026 (Implementation Risk Mitigation) by providing development assistance
- Enables enhanced workflow support for ADR-002 (Oban Queue Design) and ADR-003 (Game Engine Separation)
- **Performance**: Minimize latency for real-time assistance
- **Compatibility**: Maintain backward compatibility with existing Aria interfaces
