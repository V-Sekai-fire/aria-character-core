# ADR-033: MCP Integration TDD Completion Criteria

## Status

Accepted

## Date

2025-06-14

## Context

The MCP (Model Context Protocol) integration for GitHub Copilot access (ADR-029) requires concrete, testable completion criteria to ensure the implementation meets its objectives. Without clear success metrics, the integration could be considered "complete" without actually providing the intended natural language interaction capabilities.

## Decision

Define comprehensive Test-Driven Development (TDD) objectives and completion criteria for the MCP integration that must be satisfied before the feature is considered production-ready.

## Rationale

- **Clear Success Metrics**: Eliminates ambiguity about when the MCP integration is complete
- **Quality Assurance**: Ensures the integration actually works in real GitHub Copilot scenarios
- **Implementation Guidance**: Provides concrete targets for developers to work toward
- **Risk Mitigation**: Catches integration issues before production deployment

## TDD Objectives for Completion

### Core Integration Test

The MCP server implementation is considered complete when the following test scenario passes:

```elixir
test "GitHub Copilot can play TimeStrike through MCP server" do
  # 1. Start TimeStrike MCP server
  {:ok, mcp_pid} = TimeStrikeMcpServer.start_link()

  # 2. Start new TimeStrike game session
  start_game_call = %{
    "name" => "timestrike_start_game",
    "arguments" => %{
      "scenario" => "hostage_rescue",
      "difficulty" => "normal"
    }
  }

  {:ok, game_result} = TimeStrikeMcpServer.execute_tool(start_game_call)

  # 3. Verify game initialization
  assert game_result["success"] == true
  assert game_result["game_state"]["alex"]["position"] == %{"x" => 2, "y" => 3, "z" => 0}
  assert game_result["game_state"]["status"] == "active"
  assert is_binary(game_result["session_id"])

  # 4. Issue movement command
  move_call = %{
    "name" => "timestrike_move_agent",
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "agent" => "alex",
      "target_position" => %{"x" => 8, "y" => 3, "z" => 0}
    }
  }

  {:ok, move_result} = TimeStrikeMcpServer.execute_tool(move_call)

  # 5. Verify movement plan
  assert move_result["success"] == true
  assert move_result["action"]["type"] == "move_to"
  assert move_result["eta_seconds"] > 0
  assert move_result["current_position"] == %{"x" => 2, "y" => 3, "z" => 0}

  # 6. Interrupt movement mid-action
  :timer.sleep(1000)  # Let movement start

  interrupt_call = %{
    "name" => "timestrike_interrupt_action",
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "agent" => "alex"
    }
  }

  {:ok, interrupt_result} = TimeStrikeMcpServer.execute_tool(interrupt_call)

  # 7. Verify interruption and replanning
  assert interrupt_result["success"] == true
  assert interrupt_result["interrupted_at"]["x"] > 2  # Alex moved partway
  assert interrupt_result["new_plan"]["type"] == "replan_from_position"
end
```

### VS Code Integration Test

```bash
# Manual TimeStrike gameplay test for VS Code
# Prerequisites: VS Code with GitHub Copilot extension, TimeStrike MCP server configured

# 1. Start TimeStrike MCP server in stdio mode
mix timestrike_mcp_server --stdio

# 2. Open VS Code with MCP configuration pointing to TimeStrike server
# Expected: GitHub Copilot should discover timestrike_* tools

# 3. In VS Code chat, ask: "@copilot Start a new hostage rescue mission"
# Expected: Copilot uses timestrike_start_game tool, shows game state with Alex at {2,3,0}

# 4. Follow up: "@copilot Move Alex to position {8,3,0}"
# Expected: Copilot uses timestrike_move_agent, shows movement plan with ETA

# 5. While Alex is moving: "@copilot Stop Alex's movement immediately"
# Expected: Copilot uses timestrike_interrupt_action, shows Alex's current position

# 6. Continue: "@copilot What's Alex's current status?"
# Expected: Copilot uses timestrike_get_game_state, shows position and available actions

# 7. Make tactical decision: "@copilot Alex should take the stealth approach"
# Expected: Copilot uses timestrike_make_conviction_choice, triggers replanning
```

### Success Criteria

- **Tool Discovery**: GitHub Copilot can discover and list all aria\_\* MCP tools
- **Character Management**: Create, modify, and query character information through natural language
- **Workflow Planning**: Generate temporal plans using natural language goal descriptions
- **Context Awareness**: MCP server maintains character state across multiple tool calls
- **Error Handling**: Graceful error responses when tools receive invalid parameters
- **Performance**: Tool execution completes within 2 seconds for typical operations

### Minimum Viable Tools

The following MCP tools must be implemented and tested:

1. **aria_create_character**: Create new character with specified attributes
2. **aria_list_characters**: List all available characters and their current state
3. **aria_plan_workflow**: Generate temporal plan for specified goal
4. **aria_execute_action**: Execute a single action from a plan
5. **aria_get_character_state**: Query current state of specified character

### Integration Quality Gates

- All MCP tools pass unit tests with mocked dependencies
- Integration test passes with real Aria backend services
- VS Code manual test demonstrates seamless natural language interaction
- Error scenarios handled gracefully (invalid JSON, missing parameters, etc.)
- Performance benchmarks meet sub-2-second response criteria

## Implementation Strategy

### Phase 1: Core Tools Implementation

- Implement minimum viable tools with unit tests
- Create MCP protocol handlers using Hermes MCP library
- Validate JSON schema compliance for all tool interfaces

### Phase 2: Integration Testing

- Set up automated integration tests with real Aria services
- Implement VS Code configuration for MCP server discovery
- Validate tool execution through simulated GitHub Copilot calls

### Phase 3: User Acceptance Testing

- Manual testing with actual VS Code and GitHub Copilot
- Performance optimization based on real-world usage patterns
- Documentation and troubleshooting guide creation

## Acceptance Criteria

### Automated Test Requirements

- All unit tests pass with 100% success rate
- Integration tests complete without errors
- Performance tests meet sub-2-second response criteria
- Error handling tests validate graceful failure modes

### Manual Test Requirements

- VS Code recognizes and lists aria\_\* tools in GitHub Copilot
- Natural language queries successfully invoke appropriate tools
- Character state persists correctly across multiple interactions
- Error messages are user-friendly and actionable

## Risk Mitigation

### Technical Risks

- **MCP Protocol Changes**: Pin to specific Hermes MCP version, monitor for updates
- **GitHub Copilot API Changes**: Maintain compatibility testing with VS Code updates
- **Performance Degradation**: Implement caching and connection pooling for Aria services

### User Experience Risks

- **Tool Discovery Failure**: Provide clear configuration documentation
- **Natural Language Ambiguity**: Design tool schemas to handle common phrasings
- **State Inconsistency**: Implement robust state management and error recovery

## Consequences

### Positive

- Clear, measurable completion criteria eliminate implementation ambiguity
- Comprehensive testing ensures reliable GitHub Copilot integration
- Quality gates prevent deployment of incomplete or buggy integration
- User acceptance testing validates real-world usability

### Negative

- Additional development time required for comprehensive testing
- Manual testing dependency may slow down release cycles
- Complex test scenarios may be difficult to maintain
- Performance requirements may limit implementation approaches

## Related Decisions

- **Implements**: ADR-029 (MCP Integration for GitHub Copilot Access) - provides completion criteria
- **Links to**: ADR-025 (Research Strategy) - follows implementation-driven discovery approach
- **Supports**: ADR-026 (Implementation Risk Mitigation) - validates integration reliability
- **Builds on**: ADR-022 (Test-Driven Development) - applies TDD methodology to MCP integration
