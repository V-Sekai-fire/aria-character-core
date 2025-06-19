# Aria Engine MCP Integration

This directory contains the Model Context Protocol (MCP) server implementation for Aria Engine, providing temporal scheduling and planning capabilities through standardized protocol interfaces.

## Overview

The MCP integration uses the Hermes MCP framework to provide a clean, protocol-compliant server foundation without any tools registered initially. This serves as a foundation for future tool additions.

## Architecture

- **`hermes_server.ex`** - Main MCP server implementation using Hermes framework
- **Mix Tasks** - Transport-specific server launchers

## Supported Transports

### stdio Transport
For VSCode MCP client integration using stdin/stdout communication.

```bash
mix mcp.stdio
```

**VSCode Configuration:**
```json
{
  "mcp.servers": {
    "aria-scheduler": {
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/path/to/aria-character-core"
    }
  }
}
```

### SSE Transport
For web clients using Server-Sent Events over HTTP.

```bash
mix mcp.sse
mix mcp.sse --port 4000
```

**Available Endpoints:**
- `GET /mcp/sse` - SSE endpoint for MCP protocol communication
- `GET /health` - Health check endpoint

**Web Client Example:**
```javascript
const eventSource = new EventSource('http://localhost:4000/mcp/sse');

eventSource.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('MCP message:', data);
};
```

## Current State

- ✅ MCP server foundation implemented
- ✅ stdio transport for VSCode integration
- ✅ SSE transport for web clients
- ✅ Proper protocol compliance via Hermes framework
- ⚠️ **No tools registered** - This is a foundation server

## Future Tool Development

Tools can be added by:

1. Implementing tool handlers in `hermes_server.ex`
2. Registering tools in the server capabilities
3. Adding tool schemas and execution logic

The current implementation provides the foundation for adding temporal scheduling and planning tools in the future.

## Dependencies

- `hermes_mcp` - MCP server framework providing transport and protocol compliance
- Standard Elixir/Phoenix dependencies for HTTP support

## Testing

```bash
# Test stdio transport (will wait for MCP client input)
mix mcp.stdio

# Test SSE transport
mix mcp.sse
curl -N -H "Accept: text/event-stream" http://localhost:4000/mcp/sse

# Health check
curl http://localhost:4000/health
