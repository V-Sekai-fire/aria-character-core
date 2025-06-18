# Aria Engine MCP Integration

This document describes how to set up and use the Aria Engine Model Context Protocol (MCP) server for VSCode integration.

## Overview

The Aria Engine MCP server provides temporal scheduling and planning capabilities through the Model Context Protocol, allowing external clients like VSCode to access AriaEngine's sophisticated hybrid temporal planner.

**Current Status:** The MCP server is functional with working tool registration and basic scheduling capabilities. However, there are currently 7 failing integration tests related to response handling that need to be resolved.

## Features

- **Temporal Scheduling**: Critical Path Method (CPM) with hybrid planning
- **Resource Conflict Detection**: Identifies and reports resource allocation conflicts
- **Dependency Analysis**: Detects circular dependencies and invalid references
- **Empty Plan Handling**: Mathematically correct handling of empty activity lists
- **Comprehensive Analysis**: Detailed scheduling analysis and suggestions

## Installation

The MCP server is built into the Aria Character Core project. No additional installation is required.

## VSCode Setup

### 1. Install MCP Extension

Install a VSCode MCP extension that supports the Model Context Protocol (such as the official MCP extension).

### 2. Configure MCP Server

Add the following configuration to your VSCode `settings.json`:

```json
{
  "mcp.servers": {
    "aria-scheduler": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/aria-character-core",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

Replace `/path/to/aria-character-core` with the actual path to your project directory.

### 3. Alternative Configuration

You can also copy the provided `vscode-mcp-config.json` file and merge its contents into your VSCode settings.

## Usage

### Starting the MCP Server

The MCP server can be started in several ways:

#### Via VSCode (Recommended)
The server will start automatically when VSCode connects to it through the MCP extension.

#### Manual Testing
```bash
mix mcp.stdio
```

This starts the server in stdio mode for testing or manual integration.

### Available Tools

#### schedule_activities

Creates temporal schedules using Critical Path Method with comprehensive hybrid planning.

**Input Schema:**
```json
{
  "schedule_name": "string (required)",
  "activities": [
    {
      "id": "string (required)",
      "name": "string (optional)",
      "duration": "number (required)",
      "dependencies": ["string array (optional)"],
      "resources": ["string array (optional)"]
    }
  ],
  "resources": {
    "resource_name": {
      "capacity": "number (optional)"
    }
  },
  "constraints": "object (optional)"
}
```

**Output Schema:**
```json
{
  "status": "success | error",
  "reason": "string",
  "schedule": "array",
  "analysis": {
    "schedule_name": "string",
    "method": "Critical Path Method (CPM)",
    "activities_analyzed": "number",
    "dependencies_found": "number",
    "resource_conflicts": "number",
    "circular_dependencies": "number",
    "hybrid_planner_used": "boolean",
    "issues": ["string array"],
    "suggestions": ["string array"]
  }
}
```

## Examples

### Empty Schedule (Valid Use Case)

**Input:**
```json
{
  "schedule_name": "New Project",
  "activities": [],
  "resources": {},
  "constraints": {}
}
```

**Output:**
```json
{
  "status": "success",
  "reason": "Empty plan successfully generated - valid solution for empty todo list",
  "schedule": [],
  "analysis": {
    "schedule_name": "New Project",
    "method": "Critical Path Method (CPM)",
    "activities_analyzed": 0,
    "hybrid_planner_used": true,
    "empty_plan_reason": "Empty todo list results in empty plan (valid solution)"
  }
}
```

### Complex Project Schedule

**Input:**
```json
{
  "schedule_name": "Website Launch",
  "activities": [
    {
      "id": "design",
      "name": "Design Phase",
      "duration": 5,
      "dependencies": [],
      "resources": ["designer"]
    },
    {
      "id": "develop",
      "name": "Development Phase",
      "duration": 10,
      "dependencies": ["design"],
      "resources": ["developer"]
    },
    {
      "id": "test",
      "name": "Testing Phase",
      "duration": 3,
      "dependencies": ["develop"],
      "resources": ["tester"]
    },
    {
      "id": "deploy",
      "name": "Deployment",
      "duration": 1,
      "dependencies": ["test"],
      "resources": ["developer"]
    }
  ],
  "resources": {
    "designer": {"capacity": 1},
    "developer": {"capacity": 2},
    "tester": {"capacity": 1}
  }
}
```

## Architecture

The MCP integration consists of several components:

- **AriaEngine.MCP.Server**: Hermes-based MCP server with tool registration
- **AriaEngine.MCP.Tools.ScheduleActivities**: Core scheduling tool implementation
- **AriaEngine.MCP.StdioTransport**: Stdio transport for VSCode communication
- **Mix.Tasks.Mcp.Stdio**: Mix task for starting the server

## Testing

Run the MCP integration tests:

```bash
mix test test/aria_engine/mcp/mcp_integration_test.exs
```

## Troubleshooting

### Server Won't Start

1. Ensure all dependencies are installed: `mix deps.get`
2. Check that the project compiles: `mix compile`
3. Verify the path in VSCode configuration is correct

### Tool Not Found

1. Check VSCode MCP extension is properly installed
2. Verify the server configuration in VSCode settings
3. Restart VSCode after configuration changes

### Empty Responses

This is expected behavior for empty activity lists and represents a mathematically correct solution (empty plan for empty input).

### Known Issues

**MCP Integration Test Failures (7 tests):**
- Response handling has case clause matching errors in the MCP server
- The scheduling tool works correctly but response formatting needs fixes
- Tests show the tool generates proper JSON responses but the server wrapper has issues
- See test output for specific `CaseClauseError` details in `AriaEngine.MCP.Server.handle_call/3`

**STN Planner Performance:**
- One test timeout in complex hierarchical planning scenarios
- PC-2 algorithm performance needs optimization for large constraint networks

## Development

### Adding New Tools

1. Create a new tool module in `lib/aria_engine/mcp/tools/`
2. Register the tool in `AriaEngine.MCP.Server`
3. Add the tool to the stdio transport's tool list
4. Update tests and documentation

### Protocol Compliance

The implementation follows the Model Context Protocol specification version 2024-11-05. All JSON-RPC messages are properly formatted and handled according to the MCP standard.

## Related Documentation

- [ADR-097: MCP Scheduler Interface Design](decisions/097-mcp-scheduler-interface-design.md)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Hermes MCP Framework](https://github.com/cloudwalk/hermes-mcp)
