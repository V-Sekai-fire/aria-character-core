# R25W057B149: Extract Scheduler and Remove MCP Infrastructure

<!-- @adr_serial R25W057B149 -->

**Status:** Completed ~~(Temporary removal, restoration planned)~~
**Date:** June 18, 2025
**Completion Date:** June 18, 2025
**Priority:** HIGH

## Context

The AriaEngine currently includes MCP (Model Context Protocol) infrastructure that provides a `schedule_activities` tool through external protocol interfaces. However, the MCP layer adds unnecessary complexity for direct Elixir usage, and the valuable scheduling functionality should be available as a clean, standalone module.

The current MCP implementation includes:

- MCP server infrastructure in `lib/aria_engine/mcp/`
- Hermes MCP framework integration
- HTTP transport layer for external tool access
- Mix tasks for MCP interaction

The core scheduling functionality is valuable and should be preserved, but the MCP protocol layer should be removed to simplify the architecture.

**Note (v0.2.0):** This removal is temporary for architectural simplification. MCP restoration is planned for future development phases with improved design.

## Decision

### Extract Scheduler as Standalone Module

Create `AriaEngine.Scheduler` module that provides direct Elixir API access to all scheduling capabilities currently available through the MCP `schedule_activities` tool.

**New API Design:**

```elixir
AriaEngine.Scheduler.schedule_activities(schedule_name, activities, opts \\ [])
```

**Preserved Functionality:**

- Critical Path Method (CPM) scheduling
- Resource conflict detection and analysis
- Circular dependency identification
- Empty activity list handling (returns valid empty schedule)
- Hybrid planner integration with all 6 strategies
- Comprehensive analysis and reporting

### Complete MCP Infrastructure Removal

Remove all MCP-related components:

- Delete `lib/aria_engine/mcp/` directory entirely
- Remove MCP mix tasks (`lib/mix/tasks/mcp.*`)
- Remove `hermes_mcp` dependency from mix.exs
- Clean up any remaining MCP references

## Implementation Plan

### Phase 1: Create Standalone Scheduler ✅

- [x] Extract scheduling logic from MCP tool implementation
- [x] Create `AriaEngine.Scheduler` module with clean API
- [x] Implement `schedule_activities/3` function
- [x] Preserve all existing functionality and analysis capabilities
- [x] Handle empty activity lists correctly (return successful empty plans)

### Phase 2: Remove MCP Infrastructure

- [x] Delete `lib/aria_engine/mcp/` directory
- [x] Remove `lib/mix/tasks/mcp.web.ex`
- [x] Remove `lib/mix/tasks/mcp.stdio.ex`
- [x] Remove `lib/mix/tasks/mcp.hermes_sse.ex`
- [x] Remove `hermes_mcp` dependency from mix.exs
- [x] Clean up any remaining MCP references in codebase

### Phase 3: Testing and Documentation

- [x] Add comprehensive tests for standalone scheduler
- [x] Update any existing code that might reference MCP components
- [x] Verify all scheduling functionality works correctly
- [ ] Update documentation to reflect new direct API

## Success Criteria

### Functional Requirements

- [x] `AriaEngine.Scheduler.schedule_activities/3` provides all functionality of original MCP tool
- [x] Empty activity lists return successful empty schedules
- [x] Resource conflicts are detected and reported
- [x] Circular dependencies are identified
- [x] Hybrid planner integration works correctly (with fallback to basic CPM)
- [x] All analysis features are preserved

### Quality Requirements

- [x] Clean, idiomatic Elixir API design
- [x] Comprehensive error handling
- [x] Performance equivalent to or better than MCP implementation
- [x] No MCP dependencies or references remain

### Integration Requirements

- [x] Module integrates cleanly with existing AriaEngine components
- [x] No breaking changes to core planning functionality
- [x] All tests pass after extraction and removal

## Consequences

### Positive

- **Simplified Architecture:** Removes unnecessary MCP protocol layer
- **Direct Access:** Clean Elixir API for scheduling functionality
- **Reduced Dependencies:** Eliminates external MCP framework dependency
- **Better Performance:** No protocol overhead for internal usage
- **Easier Testing:** Direct function calls instead of protocol simulation

### Negative

- **Lost External Access:** No longer accessible via MCP protocol for external tools
- **Migration Effort:** Any existing MCP clients
