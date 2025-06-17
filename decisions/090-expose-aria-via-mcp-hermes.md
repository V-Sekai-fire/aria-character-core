# ADR-090: Expose AriaEngine.Planner via MCP Using Hermes

## Status

**Proposed** (June 17, 2025)

## Context

Aria's `AriaEngine.Planner` provides sophisticated Hierarchical Task Network (HTN) planning with Simple Temporal Network (STN) constraint solving. This temporal planner combines IPyHOP-style HTN planning with STN bridge actions for handling temporal constraints and non-temporal decisions.

The Model Context Protocol (MCP) provides a standardized way to expose planning capabilities to Large Language Models and AI assistants. [Hermes MCP](https://github.com/cloudwalk/hermes-mcp) is a high-performance Elixir MCP implementation that provides native integration with Elixir systems.

Currently, Aria's advanced temporal planning capabilities are only accessible through internal APIs. Exposing the planner through MCP would enable AI assistants to leverage Aria's temporal reasoning for planning tasks.

## Decision

Implement a minimal MCP server using Hermes that exposes only the core `AriaEngine.Planner` functions through 4 focused MCP tools, providing external AI systems with access to Aria's temporal planning capabilities.

## AriaEngine.Planner Interface

The planner provides these core functions for temporal planning:

```elixir
# Plan goals using HTN with STN temporal constraints
AriaEngine.Planner.plan(domain_interface, initial_state, goals, opts, current_time)
# Returns: {:ok, solution_tree} | {:error, reason}

# Validate a plan against domain and state
AriaEngine.Planner.validate_plan(domain_interface, initial_state, solution_tree) 
# Returns: {:ok, final_state} | {:error, reason}

# Execute plan with Run-Lazy-Refineahead
AriaEngine.Planner.execute(domain_interface, initial_state, solution_tree, opts, current_time)
# Returns: {:ok, final_state} | {:error, reason}

# Extract primitive actions from solution tree
AriaEngine.Planner.extract_actions(solution_tree)
# Returns: [plan_step]
```

## Implementation Plan

### Phase 1: MCP Server Foundation (1 day)

- [ ] Add `hermes_mcp` dependency to Aria umbrella project
- [ ] Create `AriaCore.MCPServer` module using `use Hermes.Server`
- [ ] Configure basic server with tools capability (no resources/prompts needed)
- [ ] Add OTP supervision integration with existing Aria supervision tree
- [ ] Implement STDIO transport for CLI-based AI assistant integration

### Phase 2: Planner Tool Implementation (1-2 days)

- [ ] Create `AriaCore.MCP.PlannerTool` component with 4 focused tools:
  - `plan_temporal_actions/5` - Direct mapping to `AriaEngine.Planner.plan/5`
  - `validate_temporal_plan/3` - Direct mapping to `AriaEngine.Planner.validate_plan/3`
  - `execute_temporal_plan/5` - Direct mapping to `AriaEngine.Planner.execute/5`
  - `get_plan_actions/1` - Direct mapping to `AriaEngine.Planner.extract_actions/1`
- [ ] Add comprehensive input validation using Hermes schema macros
- [ ] Implement proper error handling and JSON serialization
- [ ] Add basic logging and telemetry

### Phase 3: Testing & Documentation (0.5 days)

- [ ] Create test suite for MCP tool validation
- [ ] Add client integration examples showing basic usage
- [ ] Document the 4 exposed tools with examples
- [ ] Verify integration with common AI assistants

## Technical Architecture

### Server Structure

```elixir
defmodule AriaCore.MCPServer do
  use Hermes.Server,
    name: "Aria Temporal Planner",
    version: "1.0.0",
    capabilities: [:tools]  # Only tools, no resources/prompts

  # Single planning component
  component AriaCore.MCP.PlannerTool

  def start_link(opts) do
    Hermes.Server.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok, frame), do: {:ok, frame}
end
```

### Planner Tool Implementation

```elixir
defmodule AriaCore.MCP.PlannerTool do
  use Hermes.Server.Component, type: :tool
  
  alias AriaEngine.Planner
  alias Hermes.Server.Response

  # Tool 1: Plan temporal actions
  schema :plan_temporal_actions do
    field :domain_interface, {:required, :map}, 
      description: "Domain with actions and methods"
    field :initial_state, {:required, :map}, 
      description: "Initial state facts"
    field :goals, {:required, {:list, :map}}, 
      description: "List of goals to achieve"
    field :opts, {:optional, {:list, :map}}, 
      description: "Planning options"
    field :current_time, {:optional, :integer}, 
      description: "Current planning time"
  end

  @impl true
  def execute(:plan_temporal_actions, params, frame) do
    case Planner.plan(
      params.domain_interface,
      params.initial_state,
      params.goals,
      Map.get(params, :opts, []),
      Map.get(params, :current_time)
    ) do
      {:ok, solution_tree} ->
        result = %{success: true, solution_tree: solution_tree}
        {:reply, Response.text(Response.tool(), Jason.encode!(result)), frame}
        
      {:error, reason} ->
        error = %{success: false, error: reason}
        {:reply, Response.text(Response.tool(), Jason.encode!(error)), frame}
    end
  end

  # Tool 2: Validate temporal plan
  schema :validate_temporal_plan do
    field :domain_interface, {:required, :map}
    field :initial_state, {:required, :map}
    field :solution_tree, {:required, :map}
  end

  @impl true
  def execute(:validate_temporal_plan, params, frame) do
    case Planner.validate_plan(
      params.domain_interface,
      params.initial_state,
      params.solution_tree
    ) do
      {:ok, final_state} ->
        result = %{success: true, final_state: final_state}
        {:reply, Response.text(Response.tool(), Jason.encode!(result)), frame}
        
      {:error, reason} ->
        error = %{success: false, error: reason}
        {:reply, Response.text(Response.tool(), Jason.encode!(error)), frame}
    end
  end

  # Tool 3: Execute temporal plan
  schema :execute_temporal_plan do
    field :domain_interface, {:required, :map}
    field :initial_state, {:required, :map}
    field :solution_tree, {:required, :map}
    field :opts, {:optional, {:list, :map}}
    field :current_time, {:optional, :integer}
  end

  @impl true
  def execute(:execute_temporal_plan, params, frame) do
    case Planner.execute(
      params.domain_interface,
      params.initial_state,
      params.solution_tree,
      Map.get(params, :opts, []),
      Map.get(params, :current_time)
    ) do
      {:ok, final_state} ->
        result = %{success: true, final_state: final_state}
        {:reply, Response.text(Response.tool(), Jason.encode!(result)), frame}
        
      {:error, reason} ->
        error = %{success: false, error: reason}
        {:reply, Response.text(Response.tool(), Jason.encode!(error)), frame}
    end
  end

  # Tool 4: Get plan actions
  schema :get_plan_actions do
    field :solution_tree, {:required, :map}
  end

  @impl true
  def execute(:get_plan_actions, params, frame) do
    actions = Planner.extract_actions(params.solution_tree)
    result = %{success: true, actions: actions}
    {:reply, Response.text(Response.tool(), Jason.encode!(result)), frame}
  end
end
```

### Transport Configuration

```elixir
# STDIO transport for CLI integration
{AriaCore.MCPServer, transport: :stdio}
```

## MCP Tool Interface

### plan_temporal_actions

**Purpose:** Generate action plans using HTN with temporal constraints

**Input:**
- `domain_interface` - Domain with actions and methods
- `initial_state` - StateV2 with current world facts  
- `goals` - List of goals to achieve
- `opts` - Planning options (optional)
- `current_time` - Current planning time (optional)

**Output:** Solution tree or error

### validate_temporal_plan

**Purpose:** Validate plan against domain and state constraints

**Input:**
- `domain_interface` - Domain used for planning
- `initial_state` - StateV2 with initial facts
- `solution_tree` - Plan to validate

**Output:** Final state or validation error

### execute_temporal_plan

**Purpose:** Execute plan with Run-Lazy-Refineahead

**Input:**
- `domain_interface` - Domain for execution
- `initial_state` - StateV2 starting state
- `solution_tree` - Plan to execute
- `opts` - Execution options (optional)
- `current_time` - Execution time (optional)

**Output:** Final state or execution error

### get_plan_actions

**Purpose:** Extract primitive actions from solution tree

**Input:**
- `solution_tree` - Plan to extract actions from

**Output:** List of primitive action steps

## Success Criteria

- AI assistants can successfully create temporal plans using Aria's planner
- Plans can be validated for consistency and feasibility
- Plans can be executed with proper error handling
- Primitive actions can be extracted for external execution
- Performance remains acceptable for typical planning workloads
- Integration works with common AI development tools

## Benefits

### For AI Development
- **Access to Sophisticated Planning**: AI assistants gain access to HTN + STN temporal planning
- **Standardized Interface**: Consistent MCP interface for planning operations
- **Temporal Reasoning**: Leverage Aria's temporal constraint solving capabilities
- **Hierarchical Planning**: Access to HTN decomposition and method selection

### For Aria Ecosystem
- **External Validation**: External usage provides additional testing of planner
- **Broader Applications**: AI developers can build planning applications using Aria
- **Standard Protocol**: MCP ensures compatibility with AI development ecosystem

### For Architecture
- **Minimal Scope**: Focused implementation reduces maintenance burden
- **Native Integration**: Hermes provides efficient Elixir-native MCP server
- **Direct Mapping**: Simple function mapping reduces complexity
- **OTP Integration**: Leverages Elixir supervision and process management

## Constraints

### Scope Limitations
- **No NPC management** - Focus only on core planning functions
- **No world state resources** - No direct access to world state queries
- **No workflow integration** - No AriaWorkflow or background processing
- **No event management** - No event system integration

### Technical Constraints
- **STDIO transport only** - Single transport mechanism for simplicity
- **Direct function mapping** - Minimal abstraction over planner interface
- **JSON serialization** - All data must be JSON-serializable
- **Synchronous operations** - No async/streaming operations

## Related ADRs

- **ADR-087**: Entity-Agent Timeline Graph Architecture (uses this planner)
- **ADR-089**: Migrate Planner to StateV2 Subject-Predicate-Fact (planner state format)
- **ADR-078**: Timeline Module PC-2 STN Implementation (underlying constraint solving)
- **ADR-029**: MCP Integration GitHub Copilot (previous MCP exploration)
