# ADR-188: Disconnect MCP Servers and Maintain Paused State

**Status:** Active  
**Date:** June 26, 2025  
**Priority:** HIGH  

## Context

The Aria project has MCP (Model Context Protocol) infrastructure that was previously implemented but is currently in various states of disconnection. Based on analysis of the codebase, there are three main MCP server components that need to be properly disconnected and kept in a paused state:

### Current MCP Infrastructure Status

1. **Schedule Activities MCP Server**
   - **Location**: `aria_membrane_pipeline` app
   - **Status**: Implementation gone, infrastructure exists but disconnected
   - **Components**: MCPSource, MCPSink, SchedulePlannerFilter, MCPScheduleFilter
   - **Issue**: References exist in justfile and pipeline components but no active server

2. **Temporal Planning MCP Server**
   - **Location**: Distributed across `aria_hybrid_planner` and `aria_membrane_pipeline`
   - **Status**: Connected to mocks, needs disconnection
   - **Components**: PlanTransformer, HybridCoordinatorV2 integration
   - **Issue**: Mock connections need to be severed

3. **Hybrid Coordinator MCP Server**
   - **Location**: `aria_hybrid_planner` app
   - **Status**: Mock and disconnected
   - **Components**: HybridCoordinatorV2, strategy composition
   - **Issue**: Mock implementations need to be properly disabled

### Historical Context

- **ADR-029**: MCP integration was cancelled for strategic focus
- **ADR-090**: Paused due to superseding implementations
- **ADR-105**: Superseded by ADR-111 for architectural improvements
- **ADR-111**: Active but paused for plan transformer conversion

## Decision

Properly disconnect all MCP server implementations and maintain them in a clean paused state to prevent accidental activation while preserving the infrastructure for potential future use.

## Implementation Plan

### Phase 1: Disconnect Justfile MCP References

- [x] Comment out or disable MCP-related commands in justfile
- [x] Ensure MCP benchmarking and testing commands are non-functional
- [x] Add clear documentation about paused state

### Phase 2: Disconnect Membrane Pipeline MCP Components

- [ ] Ensure MCPSource and MCPSink are not started automatically
- [ ] Verify PipelineManager doesn't create MCP pipelines by default
- [ ] Add configuration flags to prevent accidental MCP pipeline creation
- [ ] Document the disconnected state in module documentation

### Phase 3: Disconnect Plan Transformer Integration

- [ ] Ensure PlanTransformer is not called from any active code paths
- [ ] Verify HybridCoordinatorV2 integration is not automatically triggered
- [ ] Add guards to prevent accidental MCP request processing

### Phase 4: Clean Application Startup

- [ ] Verify no MCP servers are started in supervision trees
- [ ] Ensure application startup doesn't attempt MCP connections
- [ ] Add logging to confirm MCP components remain disconnected

### Phase 5: Documentation and Verification

- [ ] Update all relevant ADRs to reflect disconnected state
- [ ] Document how to re-enable MCP functionality if needed in future
- [ ] Create verification tests to ensure MCP remains disconnected
- [ ] Add monitoring to detect accidental MCP activation

## Success Criteria

### Functional Requirements

- [ ] No MCP servers start automatically during application boot
- [ ] Justfile MCP commands are disabled or clearly marked as non-functional
- [ ] PlanTransformer and related components are not invoked during normal operation
- [ ] All MCP pipeline components remain dormant

### Quality Requirements

- [ ] Clear documentation of disconnected state
- [ ] Preservation of MCP infrastructure for future re-enablement
- [ ] No breaking changes to non-MCP functionality
- [ ] Clean separation between active and paused components

### Verification Requirements

- [ ] Application starts successfully without MCP components
- [ ] No MCP-related errors or warnings during normal operation
- [ ] Infrastructure remains intact for future activation
- [ ] Clear path documented for re-enabling MCP functionality

## Implementation Details

### Justfile Disconnection

Comment out MCP-related commands and add clear documentation:

```just
# MCP commands - DISCONNECTED/PAUSED
# Uncomment and implement when MCP functionality is re-enabled

# mcp:
#     @echo "🚀 MCP functionality is currently PAUSED"
#     @echo "See ADR-188 for disconnection details"

# bench-mcp:
#     @echo "⚡ MCP benchmarking is currently PAUSED"
```

### Pipeline Component Disconnection

Ensure pipeline components have clear disconnection guards:

```elixir
defmodule AriaEngine.Membrane.MCPSource do
  @moduledoc """
  MCP Source component - CURRENTLY DISCONNECTED
  
  This component is part of the paused MCP infrastructure.
  See ADR-188 for disconnection details and re-enablement process.
  """
  
  # Implementation remains but is not actively used
end
```

### Application Configuration

Add configuration to prevent accidental MCP activation:

```elixir
config :aria_character_core,
  mcp_enabled: false,
  mcp_pipeline_auto_start: false
```

## Consequences

### Positive

- **Clean Separation**: Clear distinction between active and paused functionality
- **Infrastructure Preservation**: MCP components remain available for future use
- **No Accidental Activation**: Guards prevent unintended MCP server startup
- **Documentation**: Clear understanding of current state and re-enablement process

### Negative

- **Maintenance Overhead**: Need to maintain disconnected components
- **Potential Drift**: Paused components may become outdated over time
- **Re-enablement Complexity**: Will require effort to reconnect when needed

### Risks

- **Incomplete Disconnection**: Some MCP components might remain partially active
- **Documentation Drift**: Disconnection state might not be clearly communicated
- **Infrastructure Decay**: Long-term pausing might make re-enablement difficult

## Monitoring

### Success Metrics

- **Clean Startup**: Application starts without MCP-related errors
- **No Accidental Activation**: No MCP servers start during normal operation
- **Infrastructure Integrity**: MCP components remain intact and documented
- **Clear Documentation**: Disconnection state is well-documented

### Verification Strategy

- **Startup Monitoring**: Verify no MCP processes start during application boot
- **Component Testing**: Ensure MCP components are properly dormant
- **Documentation Review**: Regular review of disconnection documentation
- **Re-enablement Testing**: Periodic verification that MCP can be re-enabled

## Related ADRs

- **ADR-029**: MCP Integration for GitHub Copilot Access (cancelled)
- **ADR-090**: Expose Aria via MCP Hermes (paused)
- **ADR-105**: Reconnect Scheduler to MCP (superseded)
- **ADR-111**: Schedule Activities Data Transformer Conversion (paused)

## Future Considerations

### Re-enablement Process

When MCP functionality needs to be restored:

1. **Review Infrastructure**: Assess current state of MCP components
2. **Update Dependencies**: Ensure MCP-related dependencies are current
3. **Reconnect Components**: Systematically re-enable MCP pipeline components
4. **Update Configuration**: Enable MCP in application configuration
5. **Test Integration**: Comprehensive testing of MCP functionality
6. **Update Documentation**: Reflect active state in all relevant ADRs

### Maintenance Strategy

While disconnected:

- **Regular Review**: Periodic assessment of MCP component integrity
- **Dependency Updates**: Keep MCP-related dependencies reasonably current
- **Documentation Maintenance**: Ensure disconnection documentation remains accurate
- **Architecture Evolution**: Consider MCP integration in future architectural decisions

This ADR ensures that MCP functionality remains cleanly disconnected while preserving the infrastructure for potential future use, maintaining clear documentation of the current state and re-enablement process.
