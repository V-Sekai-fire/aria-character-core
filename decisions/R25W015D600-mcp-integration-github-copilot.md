# R25W015D600: MCP Integration for GitHub Copilot Access

<!-- @adr_serial R25W015D600 -->

## Status

**Cancelled** - MCP integration is not being implemented

**Note**: This ADR has been cancelled as the project has decided not to implement MCP (Model Context Protocol) integration. The focus is on the core TimeStrike game and temporal planner implementation through a web interface (Phoenix LiveView) as defined in ADR-068 and ADR-069.

## Date

2025-06-14

## Cancellation Rationale

This ADR is cancelled because:

1. **Strategic Focus**: The project is prioritizing core game functionality (TimeStrike) over developer tooling integration
2. **Interface Decision**: The web interface approach (ADR-068, ADR-069) provides sufficient user interaction without need for IDE integration
3. **Complexity Reduction**: Avoiding MCP integration reduces project scope and technical complexity
4. **Resource Allocation**: Development resources are better allocated to core temporal planner and game engine implementation

## Original Context (Cancelled)

Aria character core needs to be accessible from GitHub Copilot within VS Code to enable developers to interact with the character system directly from their development environment.
This requires exposing Aria through the Model Context Protocol (MCP) which allows language models to access external tools and services.

## Original Decision (Cancelled)

Implement an MCP server that exposes key Aria functionality as tools that can be invoked by GitHub Copilot using the Hermes MCP library for stdio transport.

## Consequences of Cancellation

### Positive

- Reduced project complexity and scope
- Focus on core game functionality
- Simplified architecture without MCP server components
- Faster development timeline for MVP features

### Negative

- No GitHub Copilot/VS Code integration for development assistance
- Loss of potential development workflow automation
- No natural language interface within IDE

## Impact on Related ADRs

- **R25W01659BE**: Also cancelled (MCP TDD criteria no longer needed)
- **R25W017DEAF**: Updated to remove MCP integration references
- **ADR-076**: Cancelled (MCP server for commentary automation not needed)
- **R25W044B3F2**: Updated to remove MCP integration from uncertainty analysis
