# ADR-076: MCP Server for Aria Commentary System Automation

**Status:** Proposed

**Date:** June 15, 2025

## Context

The Aria commentary randomness system currently requires manual state management, leading to missed interaction updates and inconsistent commentary delivery. The system is designed to accumulate probability points across developer interactions and trigger commentary when thresholds are reached, but the manual tracking approach has proven unreliable.

**Current Problems:**

- Manual state updates are frequently missed, creating gaps in tracking
- No automatic interaction detection or classification
- Threshold proximity monitoring is not automated
- Commentary delivery depends on remembering to check and update state
- System becomes inconsistent when manual updates are skipped

**Technical Requirements:**

- Persistent state management in `.git/info/aria_commentary_state`
- Automatic interaction type classification and scoring
- Threshold monitoring (75 points) with automated commentary delivery
- State persistence across sessions and cold starts
- Integration with existing GitHub Copilot/MCP ecosystem

## Decision

Implement a dedicated MCP (Model Context Protocol) server specifically for automating the Aria commentary system state management. This server will handle automatic state reads/writes, interaction classification, and commentary triggering without requiring manual intervention.

## Implementation Plan

### Phase 1: MCP Server Foundation

- [ ] Research existing MCP server patterns in the project (review ADR-029, ADR-033)
- [ ] Create basic MCP server structure for commentary state management
- [ ] Implement state file read/write operations with proper error handling
- [ ] Add interaction type classification logic based on user request patterns
- [ ] Test basic server functionality with manual state updates

### Phase 2: Automatic State Management

- [ ] Implement automatic state reading at interaction start
- [ ] Add probability accumulation logic based on interaction classification
- [ ] Create threshold monitoring with automatic commentary triggering
- [ ] Implement state reset logic after commentary delivery
- [ ] Add session tracking and cold start handling

### Phase 3: Integration and Testing

- [ ] Integrate MCP server with GitHub Copilot workflow
- [ ] Test commentary system automation across various interaction types
- [ ] Verify state persistence across sessions and restarts
- [ ] Document server API and configuration requirements
- [ ] Create troubleshooting guide for state management issues

### Phase 4: Advanced Features (Optional)

- [ ] Add interaction history analysis and pattern recognition
- [ ] Implement dynamic threshold adjustment based on developer activity
- [ ] Create commentary timing optimization based on context
- [ ] Add developer preference settings for commentary frequency

## Success Criteria

- State file is automatically updated after every developer interaction
- Commentary is delivered automatically when 75-point threshold is reached
- System works consistently across cold starts and session boundaries
- No manual state management is required for normal operation
- Commentary delivery timing feels natural and appropriately spaced

## Consequences

**Positive:**

- Eliminates manual state tracking burden and associated errors
- Ensures consistent commentary system operation
- Provides foundation for more sophisticated commentary features
- Leverages existing MCP infrastructure and patterns

**Negative:**

- Adds complexity with another service/server component
- Requires MCP protocol knowledge for maintenance
- May introduce new failure modes related to server communication
- Additional testing surface for state management edge cases

## Risks

- MCP server integration complexity may exceed expected development time
- State management bugs could corrupt commentary tracking
- Server startup/shutdown timing may affect state persistence
- Integration with GitHub Copilot may have unexpected behavior

## Related ADRs

- **ADR-029**: MCP Integration with GitHub Copilot (foundation)
- **ADR-033**: MCP Integration TDD Completion Criteria (testing patterns)

## Related Instruction Files

- **INST-025**: Aria VTuber personality traits (personality foundation and commentary variety)
- **INST-028**: Aria commentary randomness system (current manual system being automated)
- **INST-027**: Communication preferences and style (commentary tone and naturalness guidelines)

## Notes

This ADR is created in **Proposed** status and will be paused pending further discussion and prioritization against other active development work. The commentary system currently functions with manual updates, so this automation is an enhancement rather than a critical fix.

**Paused Reason:** Needs evaluation against current project priorities and MCP integration complexity assessment.
