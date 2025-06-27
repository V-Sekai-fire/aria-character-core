# R25W0621594: Reconnect Scheduler to MCP

<!-- @adr_serial R25W0621594 -->

**Status:** Superseded
**Date:** June 19, 2025
**Completion Date:** June 19, 2025
**Superseded Date:** June 20, 2025
**Superseded By:** R25W06881B3 (Schedule Activities Data Transformer Conversion)
**Priority:** HIGH

## Context

The AriaEngine has a fully functional standalone scheduler (`AriaEngine.Scheduler`) and MCP infrastructure (`AriaEngine.MCP.HermesServer`), but they are not connected. The MCP server exists but has no tools registered, while the scheduler provides comprehensive scheduling capabilities that should be accessible via MCP protocol.

Historical context:

- R25W05462DD designed and implemented a complete MCP scheduler interface
- R25W057B149 extracted the scheduler as standalone and "removed" MCP, but actually only removed the tools while leaving the server infrastructure

Current state:

- `AriaEngine.Scheduler` provides full scheduling with entities, resources, simulation, activity logging
- `AriaEngine.MCP.HermesServer` provides MCP server foundation with no tools
- Mix tasks `mcp.stdio` and `mcp.sse` work but serve no tools
- Hermes MCP dependency is present and functional

## Decision

Reconnect the scheduler to MCP by registering the `schedule_activities` tool in the existing MCP server, creating a bridge between MCP protocol and the standalone scheduler module.

### Implementation Approach

**Phase 1: Add MCP Tool Registration**

- Modify `AriaEngine.MCP.HermesServer` to register `schedule_activities` tool
- Create `AriaEngine.MCP.SchedulerTool` module to handle MCP-to-Scheduler conversion
- Implement input/output schema conversion between JSON and Elixir structs

**Phase 2: Protocol Bridge**

- Handle MCP JSON schema validation and conversion
- Bridge between MCP tool calls and `AriaEngine.Scheduler.schedule_activities/3`
- Preserve all existing scheduler functionality and analysis features

**Phase 3: Testing and Documentation**

- Add comprehensive tests for MCP tool functionality
- Update documentation to reflect restored MCP capabilities
- Verify end-to-end MCP protocol communication

### Tool Interface (from R25W05462DD)

**Tool Name:** `schedule_activities`

**Input Schema:**

```json
{
  "schedule_name": {"type": "string", "required": true},
  "activities": {"type": "array", "required": true},
  "resources": {"type": "object", "required": false},
  "constraints": {"type": "object", "required": false}
}
```

**Output Schema:**

```json
{
  "status": "success" | "error",
  "reason": "string",
  "schedule": "array",
  "analysis": "object"
}
```

## Implementation Plan

### Phase 1: Core MCP Tool Integration

- [x] Create `AriaEngine.MCP.SchedulerTool` module
- [x] Implement MCP tool schema and handler functions
- [x] Add tool registration to `AriaEngine.MCP.HermesServer`
- [x] Handle input validation and conversion

### Phase 2: Scheduler Bridge Implementation

- [x] Implement JSON-to-Elixir struct conversion for entities and resources
- [x] Bridge MCP tool calls to `AriaEngine.Scheduler.schedule_activities/3`
- [x] Handle error cases and edge conditions (empty activities, invalid inputs)
- [x] Preserve all scheduler analysis and reporting features

### Phase 3: Testing and Verification

- [x] Add unit tests for MCP tool functionality
- [x] Test empty activity list handling (should return successful empty plans)
- [x] Test complex scheduling scenarios with entities and resources
- [x] Verify MCP protocol compliance and tool discovery

### Phase 4: Documentation and Cleanup

- [ ] Update R25W05462DD to reflect reconnection status
- [ ] Document MCP usage instructions and examples
- [ ] Update README with MCP tool capabilities
- [x] Mark this ADR as completed

### Phase 5: Simple MCP Server Implementation (June 19, 2025)

- [x] Created `Mix.Tasks.Mcp.Stdio.Simple` as working MCP server
- [x] Bypassed Hermes framework compatibility issues
- [x] Implemented proper MCP protocol handling (initialize, tools/list, tools/call)
- [x] Updated Cline configuration to use simple MCP server
- [x] Verified JSON-RPC protocol compliance and tool functionality

### Phase 6: Hermes MCP Framework Removal (June 19, 2025)

- [x] Removed hermes_mcp dependency from mix.exs
- [x] Deleted lib/aria_engine/mcp/hermes_server.ex
- [x] Deleted lib/mix/tasks/mcp.stdio.ex (Hermes-based)
- [x] Deleted lib/mix/tasks/mcp.sse.ex (Hermes-based)
- [x] Deleted test/aria_engine/mcp/hermes_server_test.exs
- [x] Cleaned mix.lock dependencies
- [x] Verified simple MCP server still works without Hermes
- [x] All tests passing (6 tests, 0 failures)

### Phase 7: Robust MCP Server Implementation (June 19, 2025)

- [x] Created `Mix.Tasks.Mcp.Stdio` - robust stdio MCP server
- [x] Created `Mix.Tasks.Mcp.Sse` - HTTP Server-Sent Events MCP server
- [x] Both servers expose identical `schedule_activities` tool functionality
- [x] Comprehensive error handling and MCP protocol compliance
- [x] CORS support for web client access (SSE server)
- [x] Health check endpoint and proper logging
- [x] All tests passing, scheduler tool working correctly

## Success Criteria

### Functional Requirements

- [x] `schedule_activities` tool is discoverable via MCP `tools/list`
- [x] Tool accepts valid JSON input and returns proper JSON output
- [x] Empty activity lists return successful empty plans (not errors)
- [x] Complex scheduling scenarios work with full entity/resource support
- [x] All existing scheduler features accessible via MCP

### Quality Requirements

- [x] Proper error handling for invalid inputs
- [x] MCP protocol compliance (proper JSON-RPC responses)
- [x] Performance suitable for interactive use
- [x] Comprehensive logging for debugging

### Integration Requirements

- [x] Works with existing `mix mcp.stdio` and `mix mcp.sse` tasks
- [x] Compatible with VSCode MCP client integration
- [x] No breaking changes to standalone scheduler API
- [x] Maintains all existing scheduler functionality

## Consequences

### Positive

- **Restored MCP Access:** External tools can use scheduling via MCP protocol
- **Dual API Support:** Both direct Elixir and MCP protocol access available
- **Complete Feature Set:** All scheduler capabilities accessible via MCP
- **External Integration:** VSCode and other MCP clients can use scheduling
- **Minimal Risk:** Adding to existing working components, not changing them

### Negative

- **Additional Complexity:** MCP protocol layer adds conversion overhead
- **Maintenance Burden:** Must maintain both direct and MCP interfaces
- **Testing Overhead:** Need to test both API paths

### Risks

- **Protocol Mismatch:** JSON schema conversion might lose data fidelity
- **Performance Impact:** MCP protocol overhead for complex scheduling
- **Integration Issues:** External MCP clients might not handle responses correctly

## Monitoring

### Success Metrics

- **Tool Discovery:** `tools/list` returns `schedule_activities` tool
- **Response Time:** < 100ms for empty inputs, < 2s for complex schedules
- **Error Rate:** < 1% for valid inputs
- **Protocol Compliance:** All responses follow MCP JSON-RPC format

### Logging Strategy

- **Tool Registration:** Log successful tool registration at startup
- **Request Processing:** Log MCP tool calls and conversion results
- **Scheduler Integration:** Track calls to underlying scheduler module
- **Error Tracking:** Detailed logging for debugging and improvement

## Superseded Notice

**This ADR has been superseded by R25W06881B3** due to architectural improvements that separate data transformation from planning execution.

**Key Changes in R25W06881B3:**

- Convert `schedule_activities` from full execution pipeline to pure data transformer
- Separate MCP layer (data conversion) from domain layer (planning execution)
- Enable individual strategy testing through clean architectural boundaries
- Maintain all validation and conversion logic in dedicated plan converter module

**Migration Path:**

- The MCP tool functionality implemented in this ADR remains functional
- R25W06881B3 provides a cleaner architectural approach for the same capabilities
- Existing MCP clients will need updates for the new response format

## Related ADRs

- **R25W05462DD**: MCP Scheduler Interface Design (original implementation)
- **R25W057B149**: Extract Scheduler and Remove MCP Infrastructure (separation)
- **R25W0472567**: Expose Aria via MCP Hermes (parent MCP architecture)
- **R25W06881B3**: Schedule Activities Data Transformer Conversion (supersedes this ADR)

This ADR successfully restored MCP scheduling functionality, but R25W06881B3 provides a superior architectural approach that separates concerns more cleanly.
