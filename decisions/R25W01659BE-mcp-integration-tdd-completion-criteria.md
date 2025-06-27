# R25W01659BE: MCP Integration TDD Completion Criteria

<!-- @adr_serial R25W01659BE -->

## Status

**Cancelled** - MCP integration is not being implemented

*This ADR has been cancelled along with R25W015D600 as the project has decided not to implement MCP (Model Context Protocol) integration. The focus is on core TimeStrike game functionality through a web interface.*

## Date

2025-06-14

## Cancellation Rationale

This ADR is cancelled because:

1. **Parent ADR Cancelled**: R25W015D600 (MCP Integration) has been cancelled, making TDD criteria unnecessary
2. **Strategic Refocus**: Project is focusing on core game functionality rather than development tooling
3. **Reduced Scope**: Eliminating MCP integration simplifies the project and reduces technical debt
4. **Interface Strategy**: Web interface (Phoenix LiveView) provides sufficient user interaction

## Impact

- No TDD criteria needed for MCP integration
- Testing efforts can focus on core temporal planner and game engine functionality
- Simplified testing surface without MCP server components

## Original Context (Cancelled)

The MCP (Model Context Protocol) integration for GitHub Copilot access (R25W015D600) requires concrete, testable completion criteria to ensure the implementation meets its objectives. Without clear success metrics, the integration could be considered "complete" without actually providing the intended natural language interaction capabilities.

## Original Decision (Cancelled)

Define comprehensive Test-Driven Development (TDD) objectives and completion criteria for the MCP integration that must be satisfied before the feature is considered production-ready.

## Original Context

The MCP (Model Context Protocol) integration for GitHub Copilot access (R25W015D600) requires concrete, testable completion criteria to ensure the implementation meets its objectives. Without clear success metrics, the integration could be considered "complete" without actually providing the intended natural language interaction capabilities.

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
test "GitHub Copilot can play TimeStrike through MCP server with real planner API" do
  # 1. Start TimeStrike MCP server
  {:ok, mcp_pid} = TimeStrikeMcpServer.start_link()

  # 2. Start new TimeStrike game session (matches AriaTimestrike.GameEngine.start_game/0)
  start_game_call = %{
    "name" => "timestrike_start_game",
    "arguments" => %{
      "scenario" => "hostage_rescue"
    }
  }

  {:ok, game_result} = TimeStrikeMcpServer.execute_tool(start_game_call)

  # 3. Verify game initialization matches temporal planner data structures
  assert game_result["success"] == true
  assert game_result["game_state"]["agents"]["Alex"]["position"] == %{"x" => 4, "y" => 4, "z" => 0}
  assert game_result["game_state"]["agents"]["Maya"]["position"] == %{"x" => 3, "y" => 5, "z" => 0}
  assert game_result["game_state"]["agents"]["Jordan"]["position"] == %{"x" => 4, "y" => 6, "z" => 0}
  assert game_result["game_state"]["mission_status"] == "active"
  assert is_binary(game_result["session_id"])

  # 4. Generate solution tree for rescue_hostage goal using AriaEngine.Planner API
  plan_goal_call = %{
    "name" => "timestrike_plan_goal",
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "goal" => %{
        "type" => "rescue_hostage",
        "priority" => 90,
        "deadline" => 30.0,
        "success_condition" => %{
          "type" => "and",
          "conditions" => [
            %{"type" => "predicate", "predicate" => "agent_at_position", "args" => ["alex", %{"x" => 20, "y" => 5, "z" => 0}]},
            %{"type" => "predicate", "predicate" => "world_time_less_than", "args" => [30.0]}
          ]
        }
      }
    }
  }

  {:ok, plan_result} = TimeStrikeMcpServer.execute_tool(plan_goal_call)

  # 5. Verify solution tree structure matches AriaEngine.Plan.solution_tree()
  assert plan_result["success"] == true
  assert is_binary(plan_result["solution_tree"]["root_id"])
  assert is_map(plan_result["solution_tree"]["nodes"])
  assert length(plan_result["primitive_actions"]) > 0

  # Extract first primitive action (should be move_to)
  [first_action | _] = plan_result["primitive_actions"]
  assert first_action["action"] == "move_to"
  assert is_list(first_action["args"])

  # 6. Execute movement command using real TimeStrike action
  move_call = %{
    "name" => "timestrike_move_agent", 
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "agent" => "alex",
      "target_position" => %{"x" => 8, "y" => 4, "z" => 0}
    }
  }

  {:ok, move_result} = TimeStrikeMcpServer.execute_tool(move_call)

  # 7. Verify movement plan matches distance/speed calculation from R25W011BD45
  assert move_result["success"] == true
  assert move_result["timed_action"]["action"] == "move_to"
  assert move_result["timed_action"]["duration"] == 1.0  # 4 units / 4.0 u/s = 1.0s
  assert move_result["timed_action"]["start_time"] > 0
  assert move_result["timed_action"]["end_time"] > move_result["timed_action"]["start_time"]
  assert match?(%{"x" => 4, "y" => 4, "z" => 0}, move_result["current_position"])

  # 8. Interrupt movement mid-action (core re-entrant planning test)
  :timer.sleep(500)  # Let movement start

  interrupt_call = %{
    "name" => "timestrike_interrupt_action",
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "agent" => "alex"
    }
  }

  {:ok, interrupt_result} = TimeStrikeMcpServer.execute_tool(interrupt_call)

  # 9. Verify interruption and replanning using AriaEngine.Plan.replan()
  assert interrupt_result["success"] == true
  # Alex should be partway between {4,4,0} and {8,4,0}
  assert interrupt_result["interrupted_at"]["x"] > 4 and interrupt_result["interrupted_at"]["x"] < 8
  assert interrupt_result["interrupted_at"]["y"] == 4
  assert interrupt_result["new_solution_tree"]["root_id"] != plan_result["solution_tree"]["root_id"]

  # 10. Test conviction choice (goal change triggers full replanning)
  conviction_call = %{
    "name" => "timestrike_make_conviction_choice",
    "arguments" => %{
      "session_id" => game_result["session_id"],
      "new_goal" => "destroy_bridge"
    }
  }

  {:ok, conviction_result} = TimeStrikeMcpServer.execute_tool(conviction_call)

  # 11. Verify complete goal change and new solution tree generation
  assert conviction_result["success"] == true
  assert conviction_result["goal_changed"] == true
  assert conviction_result["new_solution_tree"]["root_id"] != interrupt_result["new_solution_tree"]["root_id"]
  assert length(conviction_result["primitive_actions"]) > 0
end
```

### VS Code Integration Test

```bash
# Manual TimeStrike gameplay test for VS Code with real planner API
# Prerequisites: VS Code with GitHub Copilot extension, TimeStrike MCP server configured

# 1. Start TimeStrike MCP server in stdio mode
mix timestrike_mcp_server --stdio

# 2. Open VS Code with MCP configuration pointing to TimeStrike server
# Expected: GitHub Copilot should discover timestrike_* tools

# 3. In VS Code chat, ask: "@copilot Start a new hostage rescue mission"
# Expected: Copilot uses timestrike_start_game tool
# Expected Result: Shows Alex at {4,4,0}, Maya at {3,5,0}, Jordan at {4,6,0}, hostage at {20,5,0}

# 4. Follow up: "@copilot Plan how to rescue the hostage before 12 seconds"
# Expected: Copilot uses timestrike_plan_goal with rescue_hostage goal
# Expected Result: Shows solution tree with move_to actions, timeline estimates

# 5. Continue: "@copilot Move Alex towards the hostage"
# Expected: Copilot uses timestrike_move_agent with calculated target position
# Expected Result: Shows timed_action with duration=distance/4.0 (Alex's speed), ETA

# 6. While Alex is moving: "@copilot Stop Alex immediately and replan"
# Expected: Copilot uses timestrike_interrupt_action, then timestrike_plan_goal
# Expected Result: Shows Alex's partial position, new solution tree from interrupted position

# 7. Test goal change: "@copilot Alex should destroy the bridge instead"
# Expected: Copilot uses timestrike_make_conviction_choice with "destroy_bridge" goal
# Expected Result: Shows complete replanning, new primitive actions targeting bridge pillars

# 8. Query planner state: "@copilot What's the current solution tree?"
# Expected: Copilot uses timestrike_get_solution_tree
# Expected Result: Shows root_id, node structure, primitive actions matching AriaEngine.Plan format

# 9. Check timing: "@copilot How long until the hostage deadline?"
# Expected: Copilot uses timestrike_get_game_state, calculates remaining time
# Expected Result: Shows current game time vs 30.0s deadline, time pressure context
```

### Success Criteria

- **Tool Discovery**: GitHub Copilot can discover and list all timestrike\_\* MCP tools
- **Game State Management**: Start, query, and manipulate TimeStrike game sessions through natural language
- **Temporal Planning**: Generate solution trees using natural language goal descriptions that match AriaEngine planner API
- **Context Awareness**: MCP server maintains game session state across multiple tool calls
- **Error Handling**: Graceful error responses when tools receive invalid parameters
- **Performance**: Tool execution completes within 2 seconds for typical operations

### Minimum Viable Tools

The following MCP tools must be implemented and tested with real planner data structures:

1. **timestrike_start_game**: Create new TimeStrike game session with agents at starting positions
2. **timestrike_get_game_state**: Query current game state including agent positions, HP, and scheduled actions
3. **timestrike_plan_goal**: Generate solution tree for specified goal using AriaEngine.Planner.plan()
4. **timestrike_move_agent**: Execute move_to action with duration calculation based on distance/speed
5. **timestrike_interrupt_action**: Interrupt current action and trigger replanning from current position
6. **timestrike_get_solution_tree**: Query current solution tree structure and primitive actions
7. **timestrike_make_conviction_choice**: Trigger goal change and full replanning (core re-entrant test)

### Integration Quality Gates

- All MCP tools pass unit tests with mocked dependencies
- Integration test passes with real AriaEngine backend services
- VS Code manual test demonstrates seamless natural language interaction
- Error scenarios handled gracefully (invalid JSON, missing parameters, etc.)
- Performance benchmarks meet sub-2-second response criteria
- All tool schemas match canonical temporal planner data structures

### MCP Tool Schema Alignment

The MCP tool implementations must use the exact data structures defined in `/docs/aria_timestrike/temporal_planner_data_structures.md`:

#### Tool Input/Output Types

```typescript
// Tool: timestrike_plan_goal
interface PlanGoalRequest {
  session_id: string;
  goal: {
    id?: string;
    type: "rescue_hostage" | "destroy_bridge" | "escape_scenario" | "eliminate_all_enemies";
    priority: number;  // 1-100
    deadline: number | "none";  // seconds
    success_condition: GoalCondition;
    agents: string[];  // ["alex", "maya", "jordan"]
  };
}

interface PlanGoalResponse {
  success: boolean;
  solution_tree: {
    root_id: string;
    nodes: Record<string, SolutionNode>;
    blacklisted_commands: string[];
    goal_network: Record<string, string[]>;
  };
  primitive_actions: Array<{
    action: "move_to" | "attack" | "skill_cast" | "interact";
    args: any[];
  }>;
  planning_time_ms: number;
}

// Tool: timestrike_move_agent
interface MoveAgentRequest {
  session_id: string;
  agent: "alex" | "maya" | "jordan";
  target_position: {x: number, y: number, z: number};
}

interface MoveAgentResponse {
  success: boolean;
  timed_action: {
    id: string;
    agent_id: string;
    action: "move_to";
    args: [{x: number, y: number, z: number}];
    start_time: number;
    duration: number;  // distance / agent.move_speed
    end_time: number;
    status: "scheduled" | "executing" | "completed" | "cancelled";
  };
  current_position: {x: number, y: number, z: number};
}

// Tool: timestrike_interrupt_action
interface InterruptActionResponse {
  success: boolean;
  interrupted_at: {x: number, y: number, z: number};
  new_solution_tree: SolutionTree;
  replanning_time_ms: number;
}
```

#### State Representation Alignment

- **Agent Positions**: Always use `{x, y, z}` coordinates matching Godot conventions (ADR-019)
- **Timing**: Use floating-point seconds with sub-second precision (R25W011BD45)  
- **Actions**: Match AriaTimestrike module actions: `:move_to`, `:attack`, `:skill_cast`, `:interact`
- **Solution Trees**: Use AriaEngine.Plan.solution_tree() structure exactly
- **Goals**: Match temporal_planner_data_structures.md goal types and conditions

## Implementation Strategy

### Phase 1: Core Tools Implementation with Real Planner Integration

- Implement minimum viable tools with unit tests using actual AriaEngine.Planner API calls
- Create MCP protocol handlers using Hermes MCP library with TypeScript schema validation
- Validate JSON schema compliance against canonical temporal planner data structures
- Test with real AriaTimestrike.GameEngine and AriaEngine.Plan modules (no mocking)

### Phase 2: Integration Testing with Real Game Sessions

- Set up automated integration tests with live TimeStrike game sessions
- Implement VS Code configuration for MCP server discovery
- Validate tool execution through simulated GitHub Copilot calls using actual solution trees
- Test interruption and replanning scenarios using AriaEngine.Plan.replan()

### Phase 3: User Acceptance Testing with Temporal Planning Validation

- Manual testing with actual VS Code and GitHub Copilot using real game scenarios
- Performance optimization for sub-2-second response with complex solution trees
- Validate that all MCP responses match AriaEngine data structures exactly
- Documentation with examples showing actual solution tree JSON structures

## Acceptance Criteria

### Automated Test Requirements

- All unit tests pass with 100% success rate using real AriaEngine.Planner module
- Integration tests complete without errors using actual TimeStrike game sessions
- Performance tests meet sub-2-second response criteria for solution tree generation
- Error handling tests validate graceful failure modes for invalid goal conditions
- Solution tree structure validation ensures exact match with AriaEngine.Plan.solution_tree() format
- Temporal action timing validation confirms duration calculations match R25W011BD45 formulas

### Manual Test Requirements

- VS Code recognizes and lists timestrike\_\* tools in GitHub Copilot
- Natural language queries successfully invoke appropriate tools with real game state
- Game session state persists correctly across multiple planner interactions
- Interruption and replanning scenarios work with actual AriaEngine.Plan.replan() calls
- Error messages are user-friendly and actionable for temporal planning failures

## Risk Mitigation

### Technical Risks

- **MCP Protocol Changes**: Pin to specific Hermes MCP version, monitor for updates
- **GitHub Copilot API Changes**: Maintain compatibility testing with VS Code updates
- **Planner Performance**: Implement caching for solution trees and connection pooling for AriaEngine services
- **Data Structure Evolution**: Pin to specific temporal planner data structures, version tool schemas accordingly

### User Experience Risks

- **Tool Discovery Failure**: Provide clear configuration documentation with working examples
- **Natural Language Ambiguity**: Design tool schemas to handle common TimeStrike phrasings and game terminology
- **Game State Inconsistency**: Implement robust session management and error recovery for interrupted planning
- **Temporal Planning Complexity**: Provide clear error messages when goals cannot be achieved within time constraints

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

- **Implements**: R25W015D600 (MCP Integration for GitHub Copilot Access) - provides completion criteria
- **Links to**: R25W0135BA2 (Research Strategy) - follows implementation-driven discovery approach
- **Supports**: R25W0143F62 (Implementation Risk Mitigation) - validates integration reliability
- **Builds on**: R25W0101F54 (Test-Driven Development) - applies TDD methodology to MCP integration
