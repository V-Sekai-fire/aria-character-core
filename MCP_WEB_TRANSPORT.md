# Aria Engine MCP Web Transport

This document describes how to use the Aria Engine Model Context Protocol (MCP) server via HTTP web transport instead of stdio.

**Current Status:** The web transport provides HTTP access to the same MCP scheduling capabilities. Note that there are currently some response handling issues in the underlying MCP server that affect both stdio and web transports.

## Starting the Web Server

Start the MCP server in web mode:

```bash
# Start on default port 4000
mix mcp.web

# Start on custom port
mix mcp.web --port 8080
```

The server will be available at `http://localhost:4000` (or your specified port).

## Available Endpoints

### Server Information
```bash
GET /
```
Returns server information and available endpoints.

### Server Capabilities
```bash
GET /capabilities
```
Returns MCP server capabilities and protocol information.

### List Available Tools
```bash
GET /tools
```
Returns all available tools with their schemas.

### Execute Schedule Activities Tool
```bash
POST /tools/schedule_activities
Content-Type: application/json

{
  "schedule_name": "project_name",
  "activities": [
    {
      "id": "task1",
      "name": "Setup",
      "duration": 2,
      "dependencies": []
    },
    {
      "id": "task2",
      "name": "Development", 
      "duration": 5,
      "dependencies": ["task1"]
    }
  ]
}
```

### Generic Tool Execution
```bash
POST /tools/call
Content-Type: application/json

{
  "name": "schedule_activities",
  "arguments": {
    "schedule_name": "test",
    "activities": [...]
  }
}
```

### Health Check
```bash
GET /health
```
Returns server health status.

## Example Usage

### Test Server Availability
```bash
curl http://localhost:4000/
```

### Get Available Tools
```bash
curl http://localhost:4000/tools
```

### Execute Scheduling
```bash
curl -X POST http://localhost:4000/tools/schedule_activities \
  -H "Content-Type: application/json" \
  -d '{
    "schedule_name": "test_project",
    "activities": [
      {
        "id": "task1",
        "name": "Setup",
        "duration": 2,
        "dependencies": []
      },
      {
        "id": "task2",
        "name": "Development",
        "duration": 5,
        "dependencies": ["task1"]
      }
    ]
  }'
```

## Configuration for Cline

The Cline MCP settings have been updated to use the web transport:

```json
{
  "mcpServers": {
    "aria-scheduler": {
      "disabled": false,
      "timeout": 60,
      "type": "stdio",
      "command": "mix",
      "args": ["mcp.web"],
      "cwd": "/Users/setup/Developer/aria-character-core",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

## Benefits of Web Transport

- **Direct HTTP access**: Test with curl, Postman, or any HTTP client
- **Browser accessible**: View capabilities and tools in a web browser
- **Multiple clients**: Multiple clients can connect simultaneously
- **Better debugging**: HTTP logs are easier to trace than stdio
- **Standard protocol**: Uses familiar REST API patterns
- **Development friendly**: Easy to test and integrate with other tools

## Known Issues

The web transport shares the same underlying MCP server implementation, so it currently has the same response handling issues as the stdio transport:

- Response formatting case clause errors in the server wrapper
- The scheduling tool generates correct JSON but the server response handling needs fixes
- See [MCP_INTEGRATION.md](MCP_INTEGRATION.md) for detailed troubleshooting information

## Architecture

The web transport consists of:

- `AriaEngine.MCP.WebTransport`: HTTP server using Plug/Cowboy
- `Mix.Tasks.Mcp.Web`: Mix task to start the web server
- `AriaEngine.MCP.Server`: Core MCP server (shared with stdio transport)
- `AriaEngine.MCP.Tools.ScheduleActivities`: Temporal scheduling tool

The web transport provides the same functionality as the stdio transport but over HTTP, making it more accessible for testing and integration.
