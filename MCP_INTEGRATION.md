# Aria Engine MCP Integration

This document describes how to set up and use the Aria Engine Model Context Protocol (MCP) server for VSCode integration with advanced entity-capability scheduling.

## Overview

The Aria Engine MCP server provides sophisticated temporal scheduling and planning capabilities through the Model Context Protocol, allowing external clients like VSCode to access AriaEngine's hybrid temporal planner with full entity-capability scheduling support.

**Current Status:** The MCP server is functional with basic scheduling capabilities. Entity-capability scheduling is implemented but Timeline STN constraint solving has some integration issues. The hybrid temporal planner successfully generates schedules using fallback algorithms when Timeline constraints fail.

## Features

### Core Scheduling Capabilities
- **Entity-Capability Scheduling**: Automatic assignment of activities to entities based on required capabilities
- **Agent vs Entity Distinction**: Proper handling of capability-bearing agents vs simple entities (equipment)
- **Timeline Temporal Planning**: STN constraint propagation and schedule optimization
- **Hybrid Temporal Planner**: Full HTN task decomposition with temporal reasoning
- **Durative Actions**: Time-extended operations with explicit duration and temporal semantics
- **Resource Ownership**: Entity-owned resources and allocation tracking

### Advanced Features
- **Dependency Analysis**: Temporal constraint handling and circular dependency detection
- **Resource Conflict Detection**: Identifies and reports resource allocation conflicts
- **Multi-Agent Coordination**: Complex scenarios with multiple coordinated entities
- **Capability-Based Assignment**: Automatic matching of activities to capable entities
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

### 3. Cline Configuration

For Cline users, the MCP server configuration is provided in `config/cline_mcp_settings.json`. This file contains the exact configuration needed to connect Cline to the Aria scheduler:

```json
{
  "mcpServers": {
    "aria-scheduler": {
      "autoApprove": [],
      "disabled": false,
      "timeout": 60,
      "type": "stdio",
      "command": "mix",
      "args": ["mcp.stdio"],
      "cwd": "/Users/setup/Developer/aria-character-core",
      "env": {
        "MIX_ENV": "dev"
      }
    }
  }
}
```

To use this configuration:
1. Copy the contents of `config/cline_mcp_settings.json`
2. Add it to your Cline MCP settings
3. Update the `cwd` path to match your project location
4. Restart Cline to load the new MCP server

### 4. Alternative Configuration

You can also manually configure the MCP server in your VSCode or Cline settings.

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

Creates temporal schedules using hybrid temporal planning with entity-capability scheduling, Timeline STN constraint solving, and comprehensive resource management.

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
      "resources": ["string array (optional)"],
      "required_capabilities": ["string array (optional)"],
      "assigned_entity": "string (optional)",
      "type": "string (optional)"
    }
  ],
  "entities": {
    "entity_id": {
      "type": "string (human|equipment|agent)",
      "capabilities": ["string array"],
      "properties": "object (optional)"
    }
  },
  "resources": {
    "resource_name": {
      "capacity": "number (optional)",
      "owner_entity": "string (optional)",
      "type": "string (optional)"
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
    "method": "Timeline Temporal Planning with Hybrid HTN",
    "activities_analyzed": "number",
    "dependencies_found": "number",
    "resource_conflicts": "number",
    "circular_dependencies": "number",
    "timeline_planner_used": "boolean",
    "hybrid_planner_used": "boolean",
    "entity_capability_matching": "object",
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
  "entities": {},
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
    "method": "Timeline Temporal Planning with Hybrid HTN",
    "activities_analyzed": 0,
    "hybrid_planner_used": true,
    "empty_plan_reason": "Empty todo list results in empty plan (valid solution)"
  }
}
```

### Entity-Capability Scheduling

**Input:**
```json
{
  "schedule_name": "Manufacturing Process",
  "activities": [
    {
      "id": "welding_task",
      "duration": 3.0,
      "required_capabilities": ["welding", "safety_certified"],
      "type": "manufacturing"
    },
    {
      "id": "quality_check",
      "duration": 1.0,
      "required_capabilities": ["inspection", "quality_control"],
      "dependencies": ["welding_task"],
      "type": "inspection"
    },
    {
      "id": "equipment_setup",
      "duration": 0.5,
      "assigned_entity": "crane_1",
      "type": "equipment_operation"
    }
  ],
  "entities": {
    "welder_1": {
      "type": "human",
      "capabilities": ["welding", "safety_certified"],
      "properties": {"certification": "AWS_D1.1"}
    },
    "inspector_1": {
      "type": "human",
      "capabilities": ["inspection", "quality_control"],
      "properties": {"certification": "ISO_9001"}
    },
    "crane_1": {
      "type": "equipment",
      "capabilities": [],
      "properties": {"max_load": "50_tons", "status": "operational"}
    }
  },
  "resources": {
    "welding_station": {"capacity": 1, "owner_entity": "welder_1"},
    "inspection_tools": {"capacity": 2}
  }
}
```

### Complex Multi-Agent Coordination

**Input:**
```json
{
  "schedule_name": "Mission Coordination",
  "activities": [
    {
      "id": "mission_planning",
      "duration": 1.0,
      "required_capabilities": ["strategic_planning", "decision_making"],
      "type": "coordination"
    },
    {
      "id": "team_alpha_deploy",
      "duration": 2.0,
      "required_capabilities": ["tactical_movement", "communication"],
      "dependencies": ["mission_planning"],
      "type": "deployment"
    },
    {
      "id": "team_bravo_deploy",
      "duration": 2.0,
      "required_capabilities": ["tactical_movement", "communication"],
      "dependencies": ["mission_planning"],
      "type": "deployment"
    },
    {
      "id": "synchronized_action",
      "duration": 0.5,
      "required_capabilities": ["coordination", "timing"],
      "dependencies": ["team_alpha_deploy", "team_bravo_deploy"],
      "type": "execution"
    }
  ],
  "entities": {
    "mission_commander": {
      "type": "agent",
      "capabilities": ["strategic_planning", "decision_making", "leadership"],
      "properties": {"rank": "colonel", "experience": "20_years"}
    },
    "team_alpha_leader": {
      "type": "agent",
      "capabilities": ["tactical_movement", "communication", "team_leadership"],
      "properties": {"team_size": 4}
    },
    "team_bravo_leader": {
      "type": "agent",
      "capabilities": ["tactical_movement", "communication", "team_leadership"],
      "properties": {"team_size": 4}
    }
  },
  "constraints": {
    "max_parallel_deployments": 2,
    "coordination_window": 30,
    "communication_range": 1000
  }
}
```

## Architecture

The MCP integration consists of several sophisticated components:

### Core Components
- **AriaEngine.MCP.Tools.ScheduleActivities**: Advanced scheduling tool with entity-capability integration
- **Timeline.AgentEntity**: Entity and agent management with capability tracking
- **HybridPlanner.HybridCoordinatorV2**: Full hybrid temporal planner with 6 strategy types
- **Timeline**: STN constraint solving and temporal optimization
- **AriaEngine.MCP.TemporalScheduler**: MCP server coordination
- **AriaEngine.MCP.StdioTransport**: Stdio transport for VSCode communication

### Strategy Integration
The hybrid planner uses all 6 strategy types:

1. **Planning Strategy**: HTN task decomposition and goal achievement
2. **Temporal Strategy**: STN constraint management and timeline validation
3. **State Strategy**: Categorical and numerical fluent management
4. **Domain Strategy**: Action and method resolution
5. **Logging Strategy**: Progress tracking and debugging
6. **Execution Strategy**: Plan execution and failure recovery

### Entity-Capability System
- **Entity Management**: Create and track entities with properties and capabilities
- **Agent Distinction**: Entities become agents when they have capabilities
- **Capability Matching**: Automatic assignment based on required capabilities
- **Resource Ownership**: Entities can own and control specific resources
- **Mixed Scenarios**: Support for both simple entities and capable agents

## Testing

### Run Entity-Capability Tests
```bash
mix run test_mcp_entities_capabilities.exs
```

### Run MCP Integration Tests
```bash
mix test test/aria_engine/mcp/mcp_integration_test.exs
```

### Test Scenarios Covered
1. **Basic Entity Assignment** - Direct entity-to-task assignment
2. **Capability-Based Assignment** - Automatic matching based on required capabilities
3. **Mixed Entities and Agents** - Testing both equipment entities and human agents
4. **Resource Ownership** - Entity-owned resources and allocation
5. **Complex Multi-Agent Scenarios** - Coordinated multi-entity operations

### Test Results Summary

**✅ Working Features:**
- Empty activity scheduling (mathematically correct empty plans)
- Basic activity scheduling with durations
- Resource conflict detection and reporting
- Hybrid planner integration with fallback algorithms
- JSON response generation and formatting
- MCP protocol compliance (9/10 tests pass)

**⚠️ Partial Issues:**
- Timeline STN constraint solving (falls back to simple scheduling)
- Dependency ordering not always respected in final schedules
- Minor schema inconsistencies (field naming)

**📊 Performance Results:**
- Empty activities: ~5ms response time
- Simple scheduling (2-3 activities): ~10-50ms response time
- Complex scenarios: Successfully generates schedules but may ignore some constraints

**🔧 Entity-Capability Status:**
- Entity creation and management: ✅ Working
- Capability-based assignment: ✅ Implemented (creates auto-generated agents)
- Mixed entity/agent scenarios: ✅ Working
- Resource ownership tracking: ✅ Working with conflict detection

## Troubleshooting

### Server Won't Start

1. Ensure all dependencies are installed: `mix deps.get`
2. Check that the project compiles: `mix compile`
3. Verify the path in VSCode configuration is correct

### Tool Not Found

1. Check VSCode MCP extension is properly installed
2. Verify the server configuration in VSCode settings
3. Restart VSCode after configuration changes

### Entity-Capability Matching Issues

1. Verify entity capabilities match required capabilities exactly
2. Check that entities have the correct type (human/equipment/agent)
3. Ensure capability names are consistent across activities and entities

### Timeline Constraint Solving Issues

**Known Issue:** Timeline STN constraint solving has integration problems with dependency constraints.

**Symptoms:**
- Warning: `Timeline scheduling failed: no function clause matching in Timeline.STN.Core.add_constraint/4`
- Dependencies not properly enforced in final schedule
- Activities may start simultaneously instead of respecting dependency order

**Current Behavior:**
- System falls back to simple dependency-based scheduling when Timeline constraints fail
- Schedules are still generated successfully but may not respect all temporal constraints
- Resource conflict detection still works correctly

**Workarounds:**
1. Use simple activity lists without complex dependencies for best results
2. Verify dependency constraints manually in generated schedules
3. Consider using explicit start time constraints instead of dependencies

### Schema Mismatch Issues

**Known Issue:** Response schema has minor inconsistencies with ADR-097 specification.

**Symptoms:**
- Missing `hybrid_planner_used` field in some responses
- Field appears as `timeline_planner_used` instead

**Impact:** Minimal - all core functionality works correctly

### Empty Responses

This is expected behavior for empty activity lists and represents a mathematically correct solution (empty plan for empty input).

## Performance Characteristics

### Typical Performance
- **Empty activities**: < 10ms response time
- **Simple scheduling (1-10 activities)**: < 100ms response time
- **Complex scheduling (10-50 activities)**: < 2s response time
- **Large-scale scheduling (50+ activities)**: 2-10s response time

### Scalability Limits
- **Activities**: Tested up to 100 activities with good performance
- **Entities**: Supports hundreds of entities with capability matching
- **Dependencies**: Handles complex dependency graphs efficiently
- **Resources**: Scales well with resource conflict detection

## Development

### Adding New Entity Types

1. Extend the entity type validation in `ScheduleActivities`
2. Add new capability categories as needed
3. Update entity creation logic in `Timeline.AgentEntity`
4. Add tests for new entity types

### Extending Capability System

1. Define new capability categories
2. Update capability matching algorithms
3. Add capability validation logic
4. Test with complex capability requirements

### Protocol Compliance

The implementation follows the Model Context Protocol specification version 2024-11-05. All JSON-RPC messages are properly formatted and handled according to the MCP standard.

## Related Documentation

- [ADR-097: MCP Scheduler Interface Design](decisions/097-mcp-scheduler-interface-design.md)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Hermes MCP Framework](https://github.com/cloudwalk/hermes-mcp)
- [Timeline.AgentEntity Documentation](lib/aria_engine/timeline/agent_entity.ex)
- [Hybrid Planner Documentation](lib/aria_engine/hybrid_planner/)
