# ADR-042: Temporal Planner Cold Boot Implementation Order

## Status

Superseded by ADR-049

## Date

2025-06-14

## Superseded

2025-06-15 - Superseded by ADR-049: Enhanced Temporal Planner Implementation with Unified APIs

## Context

Based on the comprehensive analysis of ADRs 034-041, we need a precise Test-Driven Development (TDD) implementation order for the temporal planner that solves the canonical temporal backtracking problem defined in ADR-035. This ADR provides the exact cold boot sequence that builds from the existing codebase foundation toward the complete temporal planning capability.

The implementation must pass ADR-035's "Maya's Adaptive Scorch Coordination" problem, which requires multi-phase backtracking through information gathering, temporal coordination, opportunity windows, and emergency fallback scenarios. The solution builds incrementally using TDD principles with each component validated before proceeding.

**Key Architectural Insight**: The JSON-LD data structure with chibifire.com namespace IS the solution network itself. This semantic representation enables both human-readable temporal plans and machine-processable constraint networks, providing the foundation for all temporal reasoning operations.

## Decision

Implement the temporal planner using strict TDD methodology with the following exact cold boot order, where each step builds verified functionality before advancing to the next level.

## Cold Boot Implementation Order

### Phase 1: JSON-LD Temporal State Foundation (TDD Red-Green-Refactor)

#### Step 1.1: JSON-LD Temporal State Core (Unified Foundation)

**Test First**: ADR-035 canonical problem using unified JSON-LD state representation

```elixir
# test/aria_engine/json_ld_temporal_state_test.exs
defmodule AriaEngine.JsonLdTemporalStateTest do
  use ExUnit.Case, async: true
  
  test "initializes Maya's scenario as JSON-LD temporal state with chibifire.com namespace" do
    # State IS JSON-LD - no separate serialization step
    initial_state = JsonLdTemporalState.new(%{
      "@context" => %{
        "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
        "position" => "https://chibifire.com/vocab/aria/temporal#position",
        "vision_range" => "https://chibifire.com/vocab/aria/temporal#vision_range"
      },
      "@type" => "TemporalState",
      "time" => 0,
      "agents" => %{
        "maya" => %{
          "position" => %{"@value" => [3, 5, 0], "time" => 0},
          "vision_range" => %{"@value" => 8, "time" => 0}
        },
        "alex" => %{
          "position" => %{"@value" => [4, 4, 0], "time" => 0}
        },
        "soldier2" => %{
          "position" => %{"@value" => [15, 5, 0], "time" => 0}
        }
      }
    })
    
    assert JsonLdTemporalState.get_agent_property(initial_state, "maya", "position", 0) == [3, 5, 0]
    assert JsonLdTemporalState.get_agent_property(initial_state, "maya", "vision_range", 0) == 8
  end
  
  test "supports temporal queries and history directly on JSON-LD structure" do
    state = JsonLdTemporalState.new()
    |> JsonLdTemporalState.set_agent_property("soldier2", "position", [15, 5, 0], 0)
    |> JsonLdTemporalState.set_agent_property("soldier2", "position", [14, 5, 0], 10)
    |> JsonLdTemporalState.set_agent_property("soldier2", "position", [13, 5, 0], 20)
    
    assert JsonLdTemporalState.get_agent_property(state, "soldier2", "position", 5) == [15, 5, 0]
    assert JsonLdTemporalState.get_agent_property(state, "soldier2", "position", 15) == [14, 5, 0]
    assert JsonLdTemporalState.query_property_history(state, "soldier2", "position", 0, 25) == 
           [%{"time" => 0, "value" => [15, 5, 0]}, %{"time" => 10, "value" => [14, 5, 0]}, %{"time" => 20, "value" => [13, 5, 0]}]
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/json_ld_temporal_state.ex`

- **Unified representation**: Temporal state IS JSON-LD with chibifire.com namespace
- Time-indexed agent properties stored directly in JSON-LD structure
- Native RDF/SPARQL query support for temporal reasoning
- Historical state reconstruction through JSON-LD graph traversal
- Pass Maya scenario initialization tests with semantic web standards

### Phase 2: Independent Core Components (Parallel Development Enabled)

**Note**: All Phase 2 components can be developed in parallel since they all operate on the unified JSON-LD temporal state from Phase 1.

#### Step 2.1: Timeline Data Structure  

**Test First**: Timeline representation operates on JSON-LD temporal state

```elixir
# test/aria_engine/timeline_test.exs
defmodule AriaEngine.TimelineTest do
  use ExUnit.Case, async: true
  
  test "creates timeline for soldier2 patrol behavior using JSON-LD state" do
    json_ld_state = build_soldier2_patrol_state()  # JSON-LD temporal state
    
    timeline = Timeline.from_json_ld_state(json_ld_state, "soldier2", "position")
    |> Timeline.add_interval(0, 33, [15, 5, 0])    # At start waypoint
    |> Timeline.add_interval(33, 43, :moving)       # Moving to [12,5,0]
    |> Timeline.add_interval(43, 53, [12, 5, 0])    # At second waypoint (10 tick pause)
    |> Timeline.add_interval(53, 63, :moving)       # Moving back to [15,5,0]
    
    assert Timeline.get_value_at(timeline, 5) == [15, 5, 0]
    assert Timeline.get_value_at(timeline, 45) == [12, 5, 0]
    assert Timeline.find_intervals_with_value(timeline, [12, 5, 0]) == [{43, 53}]
  end
  
  test "detects timeline conflicts and overlaps in JSON-LD representation" do
    timeline = Timeline.new("maya", "battery_level")
    |> Timeline.add_interval(0, 30, 100)
    |> Timeline.add_interval(25, 50, 75)  # Overlapping interval
    
    assert {:error, :overlap_conflict} = Timeline.validate(timeline)
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/timeline.ex`

- Operates directly on JSON-LD temporal state structure
- Interval-based timeline representation for state variable changes
- Conflict detection and validation for overlapping intervals  
- Value interpolation for smooth transitions between discrete time points
- Pass soldier2 patrol timeline tests

#### Step 2.2: Simple Temporal Network (STN) Foundation

```elixir
defmodule AriaEngine.Timeline do
  @moduledoc """
  Timeline data structure for temporal planning.
  Represents state variables changing over time with interval-based storage.
  """

  @type t :: %__MODULE__{
    variable: atom(),
    agent: String.t(),
    intervals: [interval()],
    default_value: any()
  }

  @type interval :: %{
    start_time: integer(),
    end_time: integer(),
    value: any()
  }

  @type time_point :: integer()
  @type validation_result :: :ok | {:error, atom()}

  defstruct variable: nil, agent: nil, intervals: [], default_value: nil

  @spec new(atom(), String.t(), any()) :: t()
  def new(variable, agent, default_value \\ nil) do
    %__MODULE__{
      variable: variable,
      agent: agent,
      intervals: [],
      default_value: default_value
    }
  end

  @spec add_interval(t(), integer(), integer(), any()) :: t()
  def add_interval(%__MODULE__{} = timeline, start_time, end_time, value) 
      when start_time < end_time do
    new_interval = %{
      start_time: start_time,
      end_time: end_time,
      value: value
    }
    
    updated_intervals = [new_interval | timeline.intervals]
                       |> Enum.sort_by(& &1.start_time)
    
    %{timeline | intervals: updated_intervals}
  end

  @spec get_value_at(t(), time_point()) :: any()
  def get_value_at(%__MODULE__{} = timeline, time_point) do
    case find_interval_at_time(timeline.intervals, time_point) do
      %{value: value} -> value
      nil -> timeline.default_value
    end
  end

  @spec find_intervals_with_value(t(), any()) :: [{integer(), integer()}]
  def find_intervals_with_value(%__MODULE__{} = timeline, target_value) do
    timeline.intervals
    |> Enum.filter(fn interval -> interval.value == target_value end)
    |> Enum.map(fn interval -> {interval.start_time, interval.end_time} end)
  end

  @spec get_timeline_bounds(t()) :: {integer(), integer()} | nil
  def get_timeline_bounds(%__MODULE__{intervals: []}) do
    nil
  end
  def get_timeline_bounds(%__MODULE__{intervals: intervals}) do
    min_time = intervals |> Enum.map(& &1.start_time) |> Enum.min()
    max_time = intervals |> Enum.map(& &1.end_time) |> Enum.max()
    {min_time, max_time}
  end

  @spec validate(t()) :: validation_result()
  def validate(%__MODULE__{} = timeline) do
    case detect_overlaps(timeline.intervals) do
      [] -> :ok
      _overlaps -> {:error, :overlap_conflict}
    end
  end

  @spec merge_timelines(t(), t()) :: {:ok, t()} | {:error, term()}
  def merge_timelines(%__MODULE__{variable: var, agent: agent} = timeline1,
                     %__MODULE__{variable: var, agent: agent} = timeline2) do
    # Merge two timelines for the same variable and agent
    all_intervals = timeline1.intervals ++ timeline2.intervals
    merged_timeline = %{timeline1 | intervals: all_intervals}
    
    case validate(merged_timeline) do
      :ok -> {:ok, merged_timeline}
      error -> error
    end
  end
  def merge_timelines(_timeline1, _timeline2) do
    {:error, :incompatible_timelines}
  end

  @spec get_state_changes(t()) :: [%{time: integer(), from: any(), to: any()}]
  def get_state_changes(%__MODULE__{} = timeline) do
    sorted_intervals = Enum.sort_by(timeline.intervals, & &1.start_time)
    
    Enum.zip(sorted_intervals, tl(sorted_intervals))
    |> Enum.map(fn {current, next} ->
      %{
        time: next.start_time,
        from: current.value,
        to: next.value
      }
    end)
  end

  @spec interpolate_value(t(), time_point()) :: any()
  def interpolate_value(%__MODULE__{} = timeline, time_point) do
    case find_interpolation_context(timeline.intervals, time_point) do
      {prev_interval, next_interval} ->
        interpolate_between_intervals(prev_interval, next_interval, time_point)
      :no_interpolation ->
        get_value_at(timeline, time_point)
    end
  end

  @spec query_time_range(t(), integer(), integer()) :: [interval()]
  def query_time_range(%__MODULE__{} = timeline, start_time, end_time) do
    timeline.intervals
    |> Enum.filter(fn interval ->
      intervals_overlap?(interval, %{start_time: start_time, end_time: end_time})
    end)
  end

  # Private helper functions

  defp find_interval_at_time(intervals, time_point) do
    Enum.find(intervals, fn interval ->
      time_point >= interval.start_time and time_point < interval.end_time
    end)
  end

  defp detect_overlaps(intervals) do
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time)
    
    Enum.zip(sorted_intervals, tl(sorted_intervals))
    |> Enum.filter(fn {interval1, interval2} ->
      intervals_overlap?(interval1, interval2)
    end)
  end

  defp intervals_overlap?(interval1, interval2) do
    not (interval1.end_time <= interval2.start_time or 
         interval2.end_time <= interval1.start_time)
  end

  defp find_interpolation_context(intervals, time_point) do
    sorted_intervals = Enum.sort_by(intervals, & &1.start_time)
    
    case find_surrounding_intervals(sorted_intervals, time_point) do
      {prev, next} when is_map(prev) and is_map(next) ->
        if can_interpolate?(prev.value, next.value) do
          {prev, next}
        else
          :no_interpolation
        end
      _ -> :no_interpolation
    end
  end

  defp find_surrounding_intervals(intervals, time_point) do
    prev_interval = intervals
                   |> Enum.filter(& &1.end_time <= time_point)
                   |> Enum.max_by(& &1.end_time, fn -> nil end)
    
    next_interval = intervals
                   |> Enum.filter(& &1.start_time >= time_point)
                   |> Enum.min_by(& &1.start_time, fn -> nil end)
    
    {prev_interval, next_interval}
  end

  defp can_interpolate?(value1, value2) do
    # Check if values can be interpolated (e.g., numeric tuples for positions)
    case {value1, value2} do
      {{x1, y1, z1}, {x2, y2, z2}} when is_number(x1) and is_number(x2) -> true
      {n1, n2} when is_number(n1) and is_number(n2) -> true
      _ -> false
    end
  end

  defp interpolate_between_intervals(prev_interval, next_interval, time_point) do
    # Linear interpolation between interval values
    time_total = next_interval.start_time - prev_interval.end_time
    time_elapsed = time_point - prev_interval.end_time
    ratio = if time_total > 0, do: time_elapsed / time_total, else: 0.0
    
    case {prev_interval.value, next_interval.value} do
      {{x1, y1, z1}, {x2, y2, z2}} ->
        {
          x1 + (x2 - x1) * ratio,
          y1 + (y2 - y1) * ratio,
          z1 + (z2 - z1) * ratio
        }
      {n1, n2} when is_number(n1) and is_number(n2) ->
        n1 + (n2 - n1) * ratio
      _ ->
        prev_interval.value  # Fallback to discrete value
    end
  end
end
```

**Test First**: STN constraint representation using JSON-LD temporal state

```elixir
# test/aria_engine/stn_solver_test.exs  
defmodule AriaEngine.STNSolverTest do
  use ExUnit.Case, async: true
  
  test "solves basic temporal constraints for Maya's movement using JSON-LD state" do
    json_ld_state = build_maya_scenario_state()  # JSON-LD temporal state
    
    # Maya must reach position before soldier2 reaches bunker
    constraints = [
      # Maya movement time: 0 <= maya_arrive - start <= 25
      STNConstraint.new(:start, :maya_arrive, 0, 25),  
      # Soldier2 bunker time: 180 <= soldier2_bunker - start <= 200
      STNConstraint.new(:start, :soldier2_bunker, 180, 200),
      # Maya must act before soldier2 reaches safety
      STNConstraint.new(:maya_arrive, :soldier2_bunker, 5, :infinity)
    ]
    
    {:ok, solution} = STNSolver.solve(constraints, json_ld_state)
    
    # Verify solution provides valid time bounds
    assert STNSolver.get_bounds(solution, :start, :maya_arrive) == {0, 25}
    assert STNSolver.get_bounds(solution, :maya_arrive, :soldier2_bunker) >= {5, :infinity}
    assert STNSolver.is_consistent?(solution) == true
  end
  
  test "detects inconsistent temporal constraints" do
    # Impossible constraints: Maya must arrive before she starts
    constraints = [
      STNConstraint.new(:maya_arrive, :start, 1, 10)  # Impossible
    ]
    
    assert {:error, :inconsistent} = STNSolver.solve(constraints)
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/stn_solver.ex`

- Path Consistency (PC-2) algorithm for optimal STN solving performance
- Operates on JSON-LD temporal state for timepoint definitions
- Incremental constraint propagation for dynamic updates
- Inconsistency detection with early termination
- Pass Maya movement timing tests

#### Step 2.3: Goal Decomposition Engine

**Test First**: JSON-LD serialization with chibifire.com namespace as the solution network

```elixir
# test/aria_engine/json_ld_solution_network_test.exs
defmodule AriaEngine.JsonLdSolutionNetworkTest do
  use ExUnit.Case, async: true
  
  test "serializes Maya scenario as JSON-LD solution network" do
    temporal_state = build_maya_scenario_state()
    timelines = build_maya_alex_timelines()
    constraints = build_maya_temporal_constraints()
    
    {:ok, solution_network} = JsonLdSolutionNetwork.serialize(temporal_state, timelines, constraints)
    
    # Verify chibifire.com namespace
    assert solution_network["@context"]["@vocab"] == "https://chibifire.com/vocab/aria/temporal#"
    assert solution_network["@context"]["Timeline"] == "https://chibifire.com/vocab/aria/temporal#Timeline"
    assert solution_network["@context"]["Constraint"] == "https://chibifire.com/vocab/aria/temporal#Constraint"
    
    # Verify solution network structure
    assert solution_network["@type"] == "TemporalSolutionNetwork"
    assert is_list(solution_network["timelines"])
    assert is_list(solution_network["constraints"])
    assert is_map(solution_network["agents"])
  end
  
  test "round-trip serialization preserves Maya scenario semantics" do
    original_state = build_maya_scenario_state()
    
    {:ok, json_ld} = JsonLdSolutionNetwork.serialize(original_state)
    {:ok, reconstructed_state} = JsonLdSolutionNetwork.deserialize(json_ld)
    
    # Verify semantic equivalence
    assert TemporalState.get_temporal_object(reconstructed_state, "position", "maya", 0) == {3, 5, 0}
    assert TemporalState.get_temporal_object(reconstructed_state, "vision_range", "maya", 0) == 8
    assert TemporalState.get_temporal_object(reconstructed_state, "position", "soldier2", 0) == {15, 5, 0}
  end
  
  test "solution network supports RDF queries and reasoning" do
    solution_network = build_maya_solution_network()
    
    # SPARQL-like queries on the solution network
    maya_timelines = JsonLdSolutionNetwork.query(solution_network, """
      SELECT ?timeline WHERE {
        ?timeline rdf:type <https://chibifire.com/vocab/aria/temporal#Timeline> .
        ?timeline <https://chibifire.com/vocab/aria/temporal#agent> "maya" .
      }
    """)
    
    assert length(maya_timelines) >= 2  # position timeline, vision timeline
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/json_ld_solution_network.ex`

```elixir
defmodule AriaEngine.JsonLdSolutionNetwork do
  @moduledoc """
  JSON-LD solution network serialization for temporal plans.
  Uses chibifire.com namespace as the semantic foundation.
  """

  @type temporal_state :: AriaEngine.TemporalState.t()
  @type timeline :: AriaEngine.Timeline.t()
  @type constraint :: AriaEngine.STNSolver.constraint()
  @type solution_network :: %{String.t() => any()}

  @chibifire_context %{
    "@context" => %{
      "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
      "Timeline" => "https://chibifire.com/vocab/aria/temporal#Timeline",
      "Constraint" => "https://chibifire.com/vocab/aria/temporal#Constraint",
      "Agent" => "https://chibifire.com/vocab/aria/temporal#Agent",
      "TemporalState" => "https://chibifire.com/vocab/aria/temporal#TemporalState",
      "BacktrackingPhase" => "https://chibifire.com/vocab/aria/temporal#BacktrackingPhase"
    }
  }

  @spec serialize(temporal_state(), [timeline()], [constraint()]) :: 
    {:ok, solution_network()} | {:error, term()}
  def serialize(temporal_state, timelines \\ [], constraints \\ []) do
    try do
      solution_network = Map.merge(@chibifire_context, %{
        "@type" => "TemporalSolutionNetwork",
        "agents" => serialize_agents(temporal_state),
        "timelines" => Enum.map(timelines, &serialize_timeline/1),
        "constraints" => Enum.map(constraints, &serialize_constraint/1),
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
      })
      {:ok, solution_network}
    rescue
      error -> {:error, error}
    end
  end

  @spec deserialize(solution_network()) :: {:ok, temporal_state()} | {:error, term()}
  def deserialize(solution_network) do
    # Implementation stub - deserialize JSON-LD back to temporal state
    {:error, :not_implemented}
  end

  @spec query(solution_network(), String.t()) :: [map()]
  def query(solution_network, sparql_query) do
    # Implementation stub - SPARQL-like queries on solution network
    []
  end

  @spec from_temporal_plan(map()) :: {:ok, solution_network()} | {:error, term()}
  def from_temporal_plan(temporal_plan) do
    # Implementation stub - serialize complete temporal plan
    {:error, :not_implemented}
  end

  @spec to_temporal_plan(solution_network()) :: {:ok, map()} | {:error, term()}
  def to_temporal_plan(solution_network) do
    # Implementation stub - deserialize to temporal plan
    {:error, :not_implemented}
  end

  # Private helper functions
  defp serialize_agents(temporal_state) do
    # Extract agent data from temporal state
    %{}
  end

  defp serialize_timeline(timeline) do
    # Serialize timeline to JSON-LD format
    %{"@type" => "Timeline"}
  end

  defp serialize_constraint(constraint) do
    # Serialize constraint to JSON-LD format
    %{"@type" => "Constraint"}
  end
end
```

- JSON-LD serialization with chibifire.com namespace
- RDF semantic representation of temporal plans
- Round-trip serialization/deserialization
- SPARQL-compatible query interface
- Pass Maya solution network serialization tests

#### Step 1.5: Simple Temporal Network (STN) Foundation

**Test First**: STN constraint representation and basic solving

```elixir
# test/aria_engine/stn_solver_test.exs  
defmodule AriaEngine.STNSolverTest do
  use ExUnit.Case, async: true
  
  test "solves basic temporal constraints for Maya's movement" do
    # Maya must reach position before soldier2 reaches bunker
    constraints = [
      # Maya movement time: 0 <= maya_arrive - start <= 25
      STNConstraint.new(:start, :maya_arrive, 0, 25),  
      # Soldier2 bunker time: 180 <= soldier2_bunker - start <= 200
      STNConstraint.new(:start, :soldier2_bunker, 180, 200),
      # Maya must act before soldier2 reaches safety
      STNConstraint.new(:maya_arrive, :soldier2_bunker, 5, :infinity)
    ]
    
    {:ok, solution} = STNSolver.solve(constraints)
    
    # Verify solution provides valid time bounds
    assert STNSolver.get_bounds(solution, :start, :maya_arrive) == {0, 25}
    assert STNSolver.get_bounds(solution, :maya_arrive, :soldier2_bunker) >= {5, :infinity}
    assert STNSolver.is_consistent?(solution) == true
  end
  
  test "detects inconsistent temporal constraints" do
    # Impossible constraints: Maya must arrive before she starts
    constraints = [
      STNConstraint.new(:maya_arrive, :start, 1, 10)  # Impossible
    ]
    
    assert {:error, :inconsistent} = STNSolver.solve(constraints)
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/stn_solver.ex`

```elixir
defmodule AriaEngine.STNSolver do
  @moduledoc """
  Simple Temporal Network solver using Path Consistency (PC-2) algorithm.
  Optimized for sparse temporal constraint networks in planning scenarios.
  """

  @type timepoint :: atom()
  @type constraint :: {timepoint(), timepoint(), integer(), integer() | :infinity}
  @type distance_graph :: %{timepoint() => %{timepoint() => {integer(), integer() | :infinity}}}
  @type solution :: {:ok, distance_graph()} | {:error, :inconsistent}

  defstruct constraints: [], timepoints: MapSet.new(), distance_matrix: %{}

  @spec solve([constraint()]) :: solution()
  def solve(constraints) when is_list(constraints) do
    try do
      timepoints = extract_timepoints(constraints)
      initial_matrix = initialize_distance_matrix(timepoints, constraints)
      
      case path_consistency_2(initial_matrix, timepoints) do
        {:ok, solution_matrix} -> {:ok, solution_matrix}
        {:error, :inconsistent} -> {:error, :inconsistent}
      end
    rescue
      _error -> {:error, :inconsistent}
    end
  end

  @spec solve_incremental(distance_graph(), [constraint()]) :: solution()
  def solve_incremental(existing_graph, new_constraints) do
    # Incremental PC-2 algorithm for dynamic constraint addition
    all_timepoints = extract_timepoints_from_graph(existing_graph) 
                    |> MapSet.union(extract_timepoints(new_constraints))
    
    updated_matrix = add_constraints_to_matrix(existing_graph, new_constraints)
    path_consistency_2(updated_matrix, all_timepoints)
  end

  @spec is_consistent?(distance_graph()) :: boolean()
  def is_consistent?(graph) do
    Enum.all?(graph, fn {timepoint, distances} ->
      case Map.get(distances, timepoint) do
        {lower, upper} when lower <= 0 and upper >= 0 -> true
        _ -> false
      end
    end)
  end

  @spec get_bounds(distance_graph(), timepoint(), timepoint()) :: 
    {integer(), integer() | :infinity}
  def get_bounds(graph, from_timepoint, to_timepoint) do
    case get_in(graph, [from_timepoint, to_timepoint]) do
      {lower, upper} -> {lower, upper}
      nil -> {0, :infinity}  # No constraint means unlimited bounds
    end
  end

  # Path Consistency-2 (PC-2) Algorithm Implementation
  @spec path_consistency_2(distance_graph(), MapSet.t()) :: solution()
  defp path_consistency_2(distance_matrix, timepoints) do
    timepoint_list = MapSet.to_list(timepoints)
    
    # Three nested loops for PC-2, but with early termination
    result = Enum.reduce_while(timepoint_list, distance_matrix, fn k, matrix_k ->
      matrix_jk = Enum.reduce_while(timepoint_list, matrix_k, fn j, matrix_j ->
        matrix_ijk = Enum.reduce_while(timepoint_list, matrix_j, fn i, matrix_i ->
          case propagate_constraint(matrix_i, i, j, k) do
            {:ok, updated_matrix} -> {:cont, updated_matrix}
            {:error, :inconsistent} -> {:halt, {:error, :inconsistent}}
          end
        end)
        
        case matrix_ijk do
          {:error, :inconsistent} -> {:halt, {:error, :inconsistent}}
          matrix -> {:cont, matrix}
        end
      end)
      
      case matrix_jk do
        {:error, :inconsistent} -> {:halt, {:error, :inconsistent}}
        matrix -> {:cont, matrix}
      end
    end)
    
    case result do
      {:error, :inconsistent} -> {:error, :inconsistent}
      matrix -> {:ok, matrix}
    end
  end

  @spec propagate_constraint(distance_graph(), timepoint(), timepoint(), timepoint()) ::
    {:ok, distance_graph()} | {:error, :inconsistent}
  defp propagate_constraint(matrix, i, j, k) do
    # Get current bounds
    {ij_lower, ij_upper} = get_matrix_bounds(matrix, i, j)
    {ik_lower, ik_upper} = get_matrix_bounds(matrix, i, k)
    {kj_lower, kj_upper} = get_matrix_bounds(matrix, k, j)
    
    # Calculate new bounds via path through k: i -> k -> j
    new_lower = max(ij_lower, add_bounds(ik_lower, kj_lower))
    new_upper = min(ij_upper, add_bounds(ik_upper, kj_upper))
    
    # Check for inconsistency
    if new_lower > new_upper do
      {:error, :inconsistent}
    else
      updated_matrix = put_in(matrix, [i, j], {new_lower, new_upper})
      {:ok, updated_matrix}
    end
  end

  # Helper functions
  defp extract_timepoints(constraints) do
    Enum.reduce(constraints, MapSet.new(), fn {from, to, _min, _max}, acc ->
      acc |> MapSet.put(from) |> MapSet.put(to)
    end)
  end

  defp extract_timepoints_from_graph(graph) do
    Enum.reduce(graph, MapSet.new(), fn {from, destinations}, acc ->
      destinations_set = destinations |> Map.keys() |> MapSet.new()
      acc |> MapSet.put(from) |> MapSet.union(destinations_set)
    end)
  end

  defp initialize_distance_matrix(timepoints, constraints) do
    # Initialize with infinite bounds, then add constraints
    initial = Enum.reduce(timepoints, %{}, fn from, acc ->
      destinations = Enum.reduce(timepoints, %{}, fn to, dest_acc ->
        if from == to do
          Map.put(dest_acc, to, {0, 0})  # Distance to self is 0
        else
          Map.put(dest_acc, to, {:neg_infinity, :infinity})
        end
      end)
      Map.put(acc, from, destinations)
    end)
    
    # Add actual constraints
    Enum.reduce(constraints, initial, fn {from, to, min_bound, max_bound}, matrix ->
      put_in(matrix, [from, to], {min_bound, max_bound})
    end)
  end

  defp add_constraints_to_matrix(matrix, new_constraints) do
    Enum.reduce(new_constraints, matrix, fn {from, to, min_bound, max_bound}, acc ->
      put_in(acc, [from, to], {min_bound, max_bound})
    end)
  end

  defp get_matrix_bounds(matrix, from, to) do
    case get_in(matrix, [from, to]) do
      {lower, upper} -> {lower, upper}
      nil -> {:neg_infinity, :infinity}
    end
  end

  defp add_bounds(a, b) when a == :neg_infinity or b == :neg_infinity, do: :neg_infinity
  defp add_bounds(a, b) when a == :infinity or b == :infinity, do: :infinity
  defp add_bounds(a, b), do: a + b
end

defmodule AriaEngine.STNConstraint do
  @moduledoc """
  Simple Temporal Network constraint representation.
  """

  @type t :: %__MODULE__{
    from: atom(),
    to: atom(),
    min_bound: integer(),
    max_bound: integer() | :infinity
  }

  defstruct [:from, :to, :min_bound, :max_bound]

  @spec new(atom(), atom(), integer(), integer() | :infinity) :: t()
  def new(from, to, min_bound, max_bound) do
    %__MODULE__{
      from: from,
      to: to,
      min_bound: min_bound,
      max_bound: max_bound
    }
  end
end
```

- Path Consistency (PC-2) algorithm for optimal STN solving performance
- Incremental constraint propagation for dynamic updates
- Inconsistency detection with early termination
**Test First**: Goal decomposition using JSON-LD temporal state

```elixir
# test/aria_engine/goal_decomposer_test.exs
defmodule AriaEngine.GoalDecomposerTest do
  use ExUnit.Case, async: true
  
  test "decomposes eliminate_soldier_patrol into executable tasks using JSON-LD state" do
    json_ld_state = build_maya_scenario_state()  # JSON-LD temporal state
    goal = %{
      "@context" => "https://chibifire.com/vocab/aria/temporal#",
      "@type" => "Goal",
      "type" => "eliminate_soldier_patrol", 
      "target" => "soldier2", 
      "deadline" => 200
    }
    
    {:ok, task_network} = GoalDecomposer.decompose_goal(goal, json_ld_state)
    
    # Verify task breakdown matches ADR-035 specification
    assert length(task_network["tasks"]) >= 4
    assert Enum.any?(task_network["tasks"], &(&1["@type"] == "ReconnaissanceTask"))
    assert Enum.any?(task_network["tasks"], &(&1["@type"] == "HistoricalAnalysisTask"))
    assert Enum.any?(task_network["tasks"], &(&1["@type"] == "CoordinationTask"))
    assert Enum.any?(task_network["tasks"], &(&1["@type"] == "OpportunityExploitationTask"))
    
    # Verify task dependencies in JSON-LD structure
    recon_task = Enum.find(task_network["tasks"], &(&1["@type"] == "ReconnaissanceTask"))
    coord_task = Enum.find(task_network["tasks"], &(&1["@type"] == "CoordinationTask"))
    assert coord_task["depends_on"] == [recon_task["@id"]]
  end
  
  test "generates primitive actions from task breakdown in JSON-LD format" do
    task_network = build_maya_task_network()  # JSON-LD task network
    
    {:ok, primitive_actions} = GoalDecomposer.generate_primitive_actions(task_network)
    
    assert length(primitive_actions) >= 4
    assert Enum.any?(primitive_actions, &(&1["@type"] == "MoveToAction"))
    assert Enum.any?(primitive_actions, &(&1["@type"] == "ScoutAreaAction"))
    assert Enum.any?(primitive_actions, &(&1["@type"] == "CastScorchAction"))
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/goal_decomposer.ex`

- Operates on JSON-LD temporal state and produces JSON-LD task networks
- Hierarchical task network (HTN) decomposition for complex goals
- Task dependency tracking and critical path analysis
- Primitive action generation from high-level tasks
- Pass Maya goal decomposition tests

### Phase 3: Integration Layer (Building on Phase 2 Components)

#### Step 3.1: STN + Timeline Integration

#### Step 2.1: Goal Decomposition Engine

**Test First**: Decompose ADR-035's high-level goal into tasks

```elixir
# test/aria_engine/goal_decomposer_test.exs
defmodule AriaEngine.GoalDecomposerTest do
  use ExUnit.Case, async: true
  
  test "decomposes eliminate_soldier_patrol into executable tasks" do
    initial_state = build_maya_scenario_state()
    goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
    
    {:ok, task_network} = GoalDecomposer.decompose_goal(goal, initial_state)
    
    # Verify task breakdown matches ADR-035 specification
    assert length(task_network.tasks) >= 4
    assert Enum.any?(task_network.tasks, &(&1.type == :reconnaissance_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :historical_analysis_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :coordination_task))
    assert Enum.any?(task_network.tasks, &(&1.type == :opportunity_exploitation_task))
    
    # Verify task dependencies
    recon_task = Enum.find(task_network.tasks, &(&1.type == :reconnaissance_task))
    coord_task = Enum.find(task_network.tasks, &(&1.type == :coordination_task))
    assert coord_task.depends_on == [recon_task.id]
  end
  
  test "generates primitive actions from task breakdown" do
    task_network = build_maya_task_network()
    
    {:ok, primitive_actions} = GoalDecomposer.generate_primitive_actions(task_network)
    
    assert length(primitive_actions) >= 4
    assert Enum.any?(primitive_actions, &(&1.type == :move_to))
    assert Enum.any?(primitive_actions, &(&1.type == :scout_area))
    assert Enum.any?(primitive_actions, &(&1.type == :cast_scorch))
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/goal_decomposer.ex`

```elixir
defmodule AriaEngine.GoalDecomposer do
  @moduledoc """
  Goal-Task-Network (GTN) decomposition engine for temporal planning.
  Breaks down high-level goals into executable task networks.
  """

  @type goal :: %{
    type: atom(),
    target: String.t(),
    deadline: integer(),
    constraints: [map()],
    priority: integer()
  }

  @type task :: %{
    id: String.t(),
    type: atom(),
    depends_on: [String.t()],
    duration: {integer(), integer()},
    resources: [atom()],
    preconditions: [map()],
    effects: [map()]
  }

  @type task_network :: %{
    goal_id: String.t(),
    tasks: [task()],
    dependencies: %{String.t() => [String.t()]},
    critical_path: [String.t()],
    estimated_duration: integer()
  }

  @type primitive_action :: %{
    type: atom(),
    agent: String.t(),
    parameters: map(),
    start_time: integer(),
    end_time: integer(),
    preconditions: [map()],
    effects: [map()]
  }

  @spec decompose_goal(goal(), AriaEngine.TemporalState.t()) :: 
    {:ok, task_network()} | {:error, term()}
  def decompose_goal(goal, initial_state) do
    case goal.type do
      :eliminate_soldier_patrol -> decompose_elimination_goal(goal, initial_state)
      :scout_area -> decompose_scouting_goal(goal, initial_state)
      :coordinate_agents -> decompose_coordination_goal(goal, initial_state)
      _ -> {:error, {:unknown_goal_type, goal.type}}
    end
  end

  @spec generate_primitive_actions(task_network()) :: 
    {:ok, [primitive_action()]} | {:error, term()}
  def generate_primitive_actions(task_network) do
    actions = Enum.flat_map(task_network.tasks, fn task ->
      decompose_task_to_actions(task)
    end)
    
    {:ok, actions}
  end

  # Goal-specific decomposition methods
  @spec decompose_elimination_goal(goal(), AriaEngine.TemporalState.t()) :: 
    {:ok, task_network()}
  defp decompose_elimination_goal(goal, initial_state) do
    base_id = "elimination_#{:rand.uniform(1000)}"
    
    tasks = [
      %{
        id: "#{base_id}_reconnaissance",
        type: :reconnaissance_task,
        depends_on: [],
        duration: {5, 15},
        resources: [:vision, :movement],
        preconditions: [%{type: :agent_available, agent: "maya"}],
        effects: [%{type: :area_scouted, target: goal.target}]
      },
      %{
        id: "#{base_id}_historical_analysis",
        type: :historical_analysis_task,
        depends_on: ["#{base_id}_reconnaissance"],
        duration: {3, 8},
        resources: [:processing],
        preconditions: [%{type: :scout_data_available}],
        effects: [%{type: :pattern_identified, target: goal.target}]
      },
      %{
        id: "#{base_id}_coordination",
        type: :coordination_task,
        depends_on: ["#{base_id}_historical_analysis"],
        duration: {2, 5},
        resources: [:communication],
        preconditions: [%{type: :pattern_identified}],
        effects: [%{type: :coordination_plan_ready}]
      },
      %{
        id: "#{base_id}_opportunity_exploitation",
        type: :opportunity_exploitation_task,
        depends_on: ["#{base_id}_coordination"],
        duration: {1, 3},
        resources: [:combat, :movement],
        preconditions: [%{type: :coordination_plan_ready}, %{type: :opportunity_window}],
        effects: [%{type: :target_eliminated, target: goal.target}]
      }
    ]
    
    dependencies = build_task_dependencies(tasks)
    critical_path = calculate_critical_path(tasks, dependencies)
    estimated_duration = calculate_total_duration(tasks, dependencies)
    
    task_network = %{
      goal_id: base_id,
      tasks: tasks,
      dependencies: dependencies,
      critical_path: critical_path,
      estimated_duration: estimated_duration
    }
    
    {:ok, task_network}
  end

  @spec decompose_scouting_goal(goal(), AriaEngine.TemporalState.t()) :: 
    {:ok, task_network()}
  defp decompose_scouting_goal(goal, _initial_state) do
    # Implementation stub - decompose scouting goals
    {:ok, %{goal_id: "scout", tasks: [], dependencies: %{}, critical_path: [], estimated_duration: 0}}
  end

  @spec decompose_coordination_goal(goal(), AriaEngine.TemporalState.t()) :: 
    {:ok, task_network()}
  defp decompose_coordination_goal(goal, _initial_state) do
    # Implementation stub - decompose coordination goals
    {:ok, %{goal_id: "coord", tasks: [], dependencies: %{}, critical_path: [], estimated_duration: 0}}
  end

  # Task-to-action decomposition
  @spec decompose_task_to_actions(task()) :: [primitive_action()]
  defp decompose_task_to_actions(task) do
    case task.type do
      :reconnaissance_task -> generate_reconnaissance_actions(task)
      :historical_analysis_task -> generate_analysis_actions(task)
      :coordination_task -> generate_coordination_actions(task)
      :opportunity_exploitation_task -> generate_exploitation_actions(task)
      _ -> []
    end
  end

  defp generate_reconnaissance_actions(task) do
    [
      %{
        type: :move_to,
        agent: "maya",
        parameters: %{position: {10, 5, 0}},
        start_time: 0,
        end_time: 5,
        preconditions: [%{type: :agent_available, agent: "maya"}],
        effects: [%{type: :agent_at_position, agent: "maya", position: {10, 5, 0}}]
      },
      %{
        type: :scout_area,
        agent: "maya", 
        parameters: %{area: :patrol_route, radius: 8},
        start_time: 5,
        end_time: 15,
        preconditions: [%{type: :agent_at_position, agent: "maya", position: {10, 5, 0}}],
        effects: [%{type: :area_scouted, area: :patrol_route}]
      }
    ]
  end

  defp generate_analysis_actions(task) do
    [
      %{
        type: :analyze_patterns,
        agent: "maya",
        parameters: %{data_source: :scout_data},
        start_time: 15,
        end_time: 23,
        preconditions: [%{type: :scout_data_available}],
        effects: [%{type: :pattern_identified}]
      }
    ]
  end

  defp generate_coordination_actions(task) do
    [
      %{
        type: :coordinate_with_alex,
        agent: "maya",
        parameters: %{message: :synchronize_timing},
        start_time: 23,
        end_time: 28,
        preconditions: [%{type: :pattern_identified}],
        effects: [%{type: :coordination_plan_ready}]
      }
    ]
  end

  defp generate_exploitation_actions(task) do
    [
      %{
        type: :cast_scorch,
        agent: "maya",
        parameters: %{target: "soldier2", timing: :opportunity_window},
        start_time: 50,
        end_time: 53,
        preconditions: [%{type: :opportunity_window}, %{type: :coordination_plan_ready}],
        effects: [%{type: :target_eliminated, target: "soldier2"}]
      }
    ]
  end

  # Helper functions for task network analysis
  defp build_task_dependencies(tasks) do
    Enum.reduce(tasks, %{}, fn task, acc ->
      Map.put(acc, task.id, task.depends_on)
    end)
  end

  defp calculate_critical_path(tasks, dependencies) do
    # Implementation stub - critical path calculation
    Enum.map(tasks, & &1.id)
  end

  defp calculate_total_duration(tasks, dependencies) do
    # Implementation stub - duration calculation along critical path
    Enum.reduce(tasks, 0, fn task, acc ->
      {min_dur, max_dur} = task.duration
      acc + max_dur  # Conservative estimate
    end)
  end
end
```

- Hierarchical task network (HTN) decomposition for complex goals
- Task dependency tracking and critical path analysis
- Primitive action generation from high-level tasks
- Pass Maya goal decomposition tests

#### Step 2.2: Multi-Agent Coordination

**Test First**: Maya and Alex coordination for the canonical problem

```elixir
# test/aria_engine/coordination_manager_test.exs
defmodule AriaEngine.CoordinationManagerTest do
  use ExUnit.Case, async: true
  
  test "coordinates Maya and Alex for information sharing" do
    initial_state = build_maya_scenario_state()
    agents = ["maya", "alex"]
    
    {:ok, coordination} = CoordinationManager.plan_coordination(agents, initial_state)
    
    # Alex scouts first, Maya acts on shared information
    alex_scout = Enum.find(coordination.actions, &(&1.agent == "alex" and &1.type == :scout_area))
    maya_position = Enum.find(coordination.actions, &(&1.agent == "maya" and &1.type == :move_to))
    
    assert alex_scout.end_time <= maya_position.start_time
    assert maya_position.preconditions[:scout_data_available] == true  
  end
  
  test "ensures no temporal conflicts in coordinated actions" do
    coordination = build_maya_alex_coordination()
    
    conflicts = CoordinationManager.detect_conflicts(coordination)
    
    assert conflicts == []  # No temporal conflicts allowed
  end
  
  test "synchronizes timing windows for opportunity exploitation" do
    # Archer1 blocks line of sight at tick 50, creating opportunity window
    coordination = build_opportunity_coordination()
    
    archer_block_action = find_action(coordination, :archer_movement_block)
    maya_reposition = find_action(coordination, :maya_stealth_reposition)
    
    assert maya_reposition.start_time == archer_block_action.start_time
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/coordination_manager.ex`

```elixir
defmodule AriaEngine.CoordinationManager do
  @moduledoc """
  Multi-agent coordination manager for temporal planning.
  Handles information sharing, action synchronization, and conflict resolution.
  """

  @type agent_id :: String.t()
  @type coordination_plan :: %{
    id: String.t(),
    agents: [agent_id()],
    actions: [action()],
    synchronization_points: [sync_point()],
    information_flow: %{agent_id() => [agent_id()]},
    temporal_constraints: [AriaEngine.STNSolver.constraint()]
  }

  @type action :: %{
    id: String.t(),
    agent: agent_id(),
    type: atom(),
    start_time: integer(),
    end_time: integer(),
    preconditions: [map()],
    effects: [map()],
    resources: [atom()]
  }

  @type sync_point :: %{
    time: integer(),
    agents: [agent_id()],
    type: atom(),
    data_exchange: map()
  }

  @type conflict :: %{
    type: atom(),
    agents: [agent_id()],
    time_range: {integer(), integer()},
    resource: atom(),
    severity: :low | :medium | :high
  }

  @spec plan_coordination([agent_id()], AriaEngine.TemporalState.t()) :: 
    {:ok, coordination_plan()} | {:error, term()}
  def plan_coordination(agents, initial_state) when is_list(agents) do
    base_id = "coordination_#{:rand.uniform(1000)}"
    
    case generate_coordination_strategy(agents, initial_state) do
      {:ok, strategy} ->
        actions = generate_coordinated_actions(strategy, agents)
        sync_points = identify_synchronization_points(actions)
        info_flow = plan_information_flow(agents, actions)
        temporal_constraints = extract_temporal_constraints(actions, sync_points)
        
        coordination_plan = %{
          id: base_id,
          agents: agents,
          actions: actions,
          synchronization_points: sync_points,
          information_flow: info_flow,
          temporal_constraints: temporal_constraints
        }
        
        {:ok, coordination_plan}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec detect_conflicts(coordination_plan()) :: [conflict()]
  def detect_conflicts(coordination_plan) do
    [
      detect_temporal_conflicts(coordination_plan),
      detect_resource_conflicts(coordination_plan),
      detect_information_conflicts(coordination_plan)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  @spec resolve_conflicts(coordination_plan(), [conflict()]) :: 
    {:ok, coordination_plan()} | {:error, term()}
  def resolve_conflicts(coordination_plan, conflicts) do
    Enum.reduce_while(conflicts, {:ok, coordination_plan}, fn conflict, {:ok, plan} ->
      case resolve_single_conflict(plan, conflict) do
        {:ok, updated_plan} -> {:cont, {:ok, updated_plan}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  # Private implementation functions
  
  @spec generate_coordination_strategy([agent_id()], AriaEngine.TemporalState.t()) :: 
    {:ok, map()} | {:error, term()}
  defp generate_coordination_strategy(agents, initial_state) do
    # Analyze agent capabilities and current state
    agent_capabilities = Enum.map(agents, fn agent ->
      {agent, analyze_agent_capabilities(agent, initial_state)}
    end) |> Map.new()
    
    # Generate coordination strategy based on ADR-035 scenario
    strategy = %{
      information_sharing: plan_information_sharing_strategy(agents, agent_capabilities),
      temporal_synchronization: plan_temporal_synchronization(agents),
      opportunity_coordination: plan_opportunity_coordination(agents, initial_state)
    }
    
    {:ok, strategy}
  end

  defp generate_coordinated_actions(strategy, agents) do
    # Generate actions based on Maya-Alex coordination scenario
    maya_actions = generate_maya_actions(strategy)
    alex_actions = generate_alex_actions(strategy)
    
    maya_actions ++ alex_actions
  end

  defp generate_maya_actions(strategy) do
    [
      %{
        id: "maya_initial_position",
        agent: "maya",
        type: :move_to,
        start_time: 0,
        end_time: 5,
        preconditions: [],
        effects: [%{type: :agent_positioned, agent: "maya"}],
        resources: [:movement]
      },
      %{
        id: "maya_wait_for_intel",
        agent: "maya",
        type: :wait_for_information,
        start_time: 5,
        end_time: 25,
        preconditions: [%{type: :agent_positioned, agent: "maya"}],
        effects: [%{type: :scout_data_available}],
        resources: [:communication]
      },
      %{
        id: "maya_exploit_opportunity",
        agent: "maya",
        type: :cast_scorch,
        start_time: 50,
        end_time: 53,
        preconditions: [%{type: :scout_data_available}, %{type: :opportunity_window}],
        effects: [%{type: :target_eliminated, target: "soldier2"}],
        resources: [:combat, :mana]
      }
    ]
  end

  defp generate_alex_actions(strategy) do
    [
      %{
        id: "alex_scout_mission",
        agent: "alex",
        type: :scout_area,
        start_time: 0,
        end_time: 20,
        preconditions: [],
        effects: [%{type: :area_scouted, area: :patrol_route}],
        resources: [:movement, :vision]
      },
      %{
        id: "alex_share_intel",
        agent: "alex",
        type: :share_information,
        start_time: 20,
        end_time: 25,
        preconditions: [%{type: :area_scouted, area: :patrol_route}],
        effects: [%{type: :intel_shared, recipient: "maya"}],
        resources: [:communication]
      }
    ]
  end

  defp identify_synchronization_points(actions) do
    # Find points where agents need to synchronize
    [
      %{
        time: 25,
        agents: ["maya", "alex"],
        type: :information_exchange,
        data_exchange: %{
          from: "alex",
          to: "maya",
          data_type: :scout_report
        }
      },
      %{
        time: 50,
        agents: ["maya"],
        type: :opportunity_window,
        data_exchange: %{
          trigger: :archer_movement_block,
          duration: 3
        }
      }
    ]
  end

  defp plan_information_flow(agents, actions) do
    # Map information dependencies between agents
    %{
      "alex" => ["maya"],  # Alex shares information with Maya
      "maya" => []         # Maya receives but doesn't share in this scenario
    }
  end

  defp extract_temporal_constraints(actions, sync_points) do
    # Convert action timing and sync points to STN constraints
    action_constraints = Enum.flat_map(actions, fn action ->
      [
        # Duration constraint: end_time - start_time = duration
        {String.to_atom(action.id <> "_start"), String.to_atom(action.id <> "_end"),
         action.end_time - action.start_time, action.end_time - action.start_time}
      ]
    end)
    
    sync_constraints = Enum.flat_map(sync_points, fn sync ->
      # Synchronization constraints between agents
      [{:sync_start, String.to_atom("sync_#{sync.time}"), 0, 0}]
    end)
    
    action_constraints ++ sync_constraints
  end

  # Conflict detection functions
  
  defp detect_temporal_conflicts(coordination_plan) do
    # Check for overlapping actions that conflict
    actions_by_agent = Enum.group_by(coordination_plan.actions, & &1.agent)
    
    Enum.flat_map(actions_by_agent, fn {agent, actions} ->
      detect_agent_temporal_conflicts(agent, actions)
    end)
  end

  defp detect_agent_temporal_conflicts(agent, actions) do
    # Sort actions by start time and check for overlaps
    sorted_actions = Enum.sort_by(actions, & &1.start_time)
    
    Enum.zip(sorted_actions, tl(sorted_actions))
    |> Enum.filter(fn {action1, action2} ->
      action1.end_time > action2.start_time  # Overlap detected
    end)
    |> Enum.map(fn {action1, action2} ->
      %{
        type: :temporal_overlap,
        agents: [agent],
        time_range: {action2.start_time, action1.end_time},
        resource: :time,
        severity: :high
      }
    end)
  end

  defp detect_resource_conflicts(coordination_plan) do
    # Check for resource conflicts between agents
    # Implementation stub - would check for shared resource usage
    []
  end

  defp detect_information_conflicts(coordination_plan) do
    # Check for information flow conflicts
    # Implementation stub - would validate information dependencies
    []
  end

  # Conflict resolution functions
  
  defp resolve_single_conflict(coordination_plan, conflict) do
    case conflict.type do
      :temporal_overlap -> resolve_temporal_overlap(coordination_plan, conflict)
      :resource_conflict -> resolve_resource_conflict(coordination_plan, conflict)
      :information_conflict -> resolve_information_conflict(coordination_plan, conflict)
      _ -> {:error, {:unknown_conflict_type, conflict.type}}
    end
  end

  defp resolve_temporal_overlap(coordination_plan, conflict) do
    # Implementation stub - would reschedule conflicting actions
    {:ok, coordination_plan}
  end

  defp resolve_resource_conflict(coordination_plan, conflict) do
    # Implementation stub - would allocate resources or reschedule
    {:ok, coordination_plan}
  end

  defp resolve_information_conflict(coordination_plan, conflict) do
    # Implementation stub - would adjust information flow timing
    {:ok, coordination_plan}
  end

  # Helper functions
  
  defp analyze_agent_capabilities(agent, initial_state) do
    # Analyze what the agent can do based on current state
    %{
      movement: true,
      vision: true,
      combat: agent == "maya",  # Only Maya has combat capabilities
      communication: true
    }
  end

  defp plan_information_sharing_strategy(agents, capabilities) do
    # Plan how agents will share information
    %{
      method: :direct_communication,
      timing: :after_scouting,
      data_types: [:position_data, :patrol_patterns]
    }
  end

  defp plan_temporal_synchronization(agents) do
    %{
      sync_points: [25, 50],  # Times when agents need to coordinate
      tolerance: 2           # Allowed timing variance
    }
  end

  defp plan_opportunity_coordination(agents, initial_state) do
    %{
      opportunity_detection: :environmental_trigger,
      exploitation_agent: "maya",
      support_agents: ["alex"]
    }
  end
end
```

- Multi-agent action coordination with information sharing protocols
- Temporal conflict detection and resolution algorithms
- Synchronization point identification and management
**Test First**: Combine STN solving with timeline constraints using unified JSON-LD state

```elixir
# test/aria_engine/temporal_planner_test.exs
defmodule AriaEngine.TemporalPlannerTest do
  use ExUnit.Case, async: true
  
  test "integrates STN constraints with timeline data using JSON-LD state" do
    json_ld_state = build_maya_scenario_state()  # Unified JSON-LD temporal state
    
    # Timeline constraints from JSON-LD state
    timelines = Timeline.extract_from_json_ld_state(json_ld_state)
    
    # STN constraints for Maya scenario
    stn_constraints = [
      STNConstraint.new(:maya_start, :maya_scout_end, 5, 15),
      STNConstraint.new(:maya_scout_end, :maya_attack, 10, 30),
      STNConstraint.new(:maya_attack, :mission_end, 1, 5)
    ]
    
    {:ok, integrated_plan} = TemporalPlanner.solve_integrated(stn_constraints, timelines, json_ld_state)
    
    # Verify integration maintains both STN and timeline constraints
    assert TemporalPlanner.satisfies_stn_constraints?(integrated_plan, stn_constraints)
    assert TemporalPlanner.satisfies_timeline_constraints?(integrated_plan, timelines)
    assert TemporalPlanner.validates_against_json_ld_state?(integrated_plan, json_ld_state)
  end
  
  test "detects and reports constraint violations between STN and timelines" do
    conflicting_constraints = build_conflicting_constraints()
    timelines = build_soldier2_patrol_timeline()
    
    {:error, conflicts} = TemporalPlanner.solve_integrated(conflicting_constraints, timelines)
    
    assert length(conflicts) >= 1
    assert Enum.any?(conflicts, &(&1.type == :stn_timeline_conflict))
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/temporal_planner.ex`

- Integration layer between STN solver and timeline constraints
- Unified JSON-LD state ensures consistency across components
- Constraint violation detection and reporting
- Solution validation against all constraint types
**Test First**: Integrate goal decomposition with timeline and STN coordination

```elixir
# test/aria_engine/coordination_integration_test.exs
defmodule AriaEngine.CoordinationIntegrationTest do
  use ExUnit.Case, async: true
  
  test "coordinates Maya and Alex using integrated timeline and STN constraints" do
    json_ld_state = build_maya_scenario_state()
    agents = ["maya", "alex"]
    
    # Goal decomposition produces JSON-LD task networks
    {:ok, maya_tasks} = GoalDecomposer.decompose_goal(build_elimination_goal(), json_ld_state)
    {:ok, alex_tasks} = GoalDecomposer.decompose_goal(build_support_goal(), json_ld_state)
    
    # Coordination integrates timelines, STN constraints, and task networks
    {:ok, coordination_plan} = CoordinationManager.plan_integrated_coordination(
      [maya_tasks, alex_tasks], json_ld_state)
    
    # Verify coordination respects all constraint types
    assert CoordinationManager.satisfies_timeline_constraints?(coordination_plan)
    assert CoordinationManager.satisfies_stn_constraints?(coordination_plan)
    assert CoordinationManager.satisfies_task_dependencies?(coordination_plan)
    
    # Information sharing preserved in JSON-LD format
    assert coordination_plan["information_flow"]["alex"]["to"] == ["maya"]
    assert coordination_plan["information_flow"]["alex"]["type"] == "ScoutData"
  end
end
```

**Implementation**: Integrate `CoordinationManager` with Phase 2 components

- Coordinates goal decomposition outputs with STN and timeline constraints
- Multi-agent action coordination using unified JSON-LD state
- Information sharing protocols maintained in semantic format
- Pass Maya-Alex coordination integration tests

### Phase 4: Advanced Constraint Handling

#### Step 4.1: Resource and Synchronization Constraints

**Test First**: Integrate temporal planning with JSON-LD solution network serialization  

```elixir
# test/aria_engine/solution_network_integration_test.exs
defmodule AriaEngine.SolutionNetworkIntegrationTest do
  use ExUnit.Case, async: true
  
  test "serializes complete Maya temporal plan as solution network" do
    initial_state = build_maya_scenario_state()
    goal = build_eliminate_soldier_patrol_goal()
    
    {:ok, temporal_plan} = TemporalPlanner.plan(goal, initial_state)
    {:ok, solution_network} = JsonLdSolutionNetwork.from_temporal_plan(temporal_plan)
    
    # Verify complete solution network with chibifire.com namespace
    assert solution_network["@context"]["@vocab"] == "https://chibifire.com/vocab/aria/temporal#"
    assert solution_network["@type"] == "TemporalSolutionNetwork"
    
    # Solution network contains all planning artifacts
    assert is_list(solution_network["timelines"])
    assert is_list(solution_network["constraints"]) 
    assert is_list(solution_network["backtrackingPhases"])
    assert is_map(solution_network["coordinationPlan"])
  end
  
  test "solution network enables plan replay and analysis" do
    solution_network = build_maya_complete_solution_network()
    
    {:ok, replay_plan} = JsonLdSolutionNetwork.to_temporal_plan(solution_network)
    
    # Verify plan reconstruction preserves semantics
    assert replay_plan.goal.type == :eliminate_soldier_patrol
    assert length(replay_plan.backtrack_phases) >= 3
    assert replay_plan.agents == ["maya", "alex"]
  end
end
```

**Implementation**: Extend JSON-LD solution network for complete temporal plans

- Serialize backtracking phases and plan revisions
- Integrate with temporal constraint solutions
- Support plan replay from solution network
- Pass complete solution network integration tests

#### Step 3.2: STN + Timeline Integration  

**Test First**: Combine STN solving with timeline constraints

```elixir
# test/aria_engine/temporal_planner_test.exs
defmodule AriaEngine.TemporalPlannerTest do
  use ExUnit.Case, async: true
  
  test "integrates STN constraints with timeline representation" do
    # Maya's movement timeline must satisfy temporal constraints
    maya_timeline = build_maya_movement_timeline()
    temporal_constraints = build_maya_temporal_constraints()
    
    {:ok, solution} = TemporalPlanner.solve_with_timelines(maya_timeline, temporal_constraints)
    
    # Timeline values must satisfy STN bounds
    maya_arrival_time = Timeline.find_transition(solution.maya_timeline, :position, {11, 5, 0})
    stn_bounds = STNSolver.get_bounds(solution.stn_solution, :start, :maya_arrive)
    
    assert maya_arrival_time >= elem(stn_bounds, 0)
    assert maya_arrival_time <= elem(stn_bounds, 1)
  end
  
  test "detects timeline violations of temporal constraints" do
    # Maya timeline that violates soldier2 deadline
    invalid_timeline = build_invalid_maya_timeline()
    constraints = build_deadline_constraints()
    
    assert {:error, :constraint_violation} = 
      TemporalPlanner.solve_with_timelines(invalid_timeline, constraints)
  end
end
```

**Implementation**: Create comprehensive temporal planning integration module

**Step 3.2a: Temporal Planner Core**
Create `apps/aria_timestrike_core/lib/aria_engine/temporal_planner.ex`

- High-level planning interface combining STN solver with timelines
- Multi-agent plan generation and coordination orchestration
- Constraint satisfaction verification across all constraint types
- Plan optimality analysis and solution ranking

**Step 3.2b: Constraint Violation Detector**
Create `apps/aria_timestrike_core/lib/aria_engine/constraint_violation_detector.ex`

- Real-time constraint violation monitoring during plan execution
- Violation severity classification and impact analysis
- Trigger conditions for plan revision and backtracking
- Constraint conflict resolution priority determination

**Step 3.2c: Solution Validator**
Create `apps/aria_timestrike_core/lib/aria_engine/solution_validator.ex`

- Comprehensive solution validation across temporal, resource, and sync constraints
- Plan feasibility checking before execution commitment
- Performance estimation and execution time prediction
- Quality metrics calculation for plan comparison

- Pass Maya timeline integration and constraint satisfaction tests

#### Step 3.3: Resource and Synchronization Constraints

**Test First**: Handle vision range and patrol behavior constraints

```elixir
# test/aria_engine/resource_constraint_test.exs
defmodule AriaEngine.ResourceConstraintTest do
  use ExUnit.Case, async: true
  
  test "enforces Maya's vision range limitation" do
    maya_state = %{position: {3, 5, 0}, vision_range: 8}
    soldier2_state = %{position: {15, 5, 0}}  # 12 units away, outside vision
    
    visibility = ResourceConstraint.check_visibility(maya_state, soldier2_state)
    
    assert visibility == false
    assert ResourceConstraint.required_scouting?(maya_state, soldier2_state) == true
  end
  
  test "models soldier2 patrol behavior as synchronization constraint" do
    patrol_constraint = SyncConstraint.new(
      condition: {:position, "soldier2", {12, 5, 0}},
      consequence: {:pause_duration, 10},
      timepoints: [:patrol_waypoint_start, :patrol_waypoint_end]
    )
    
    timeline = build_soldier2_patrol_timeline()
    
    {:ok, activated_constraints} = 
      SyncConstraint.evaluate(patrol_constraint, timeline, 45)  # tick 45
    
    assert length(activated_constraints) == 1
    assert hd(activated_constraints).type == :duration_constraint
    assert hd(activated_constraints).min_duration == 10
  end
end
```

**Implementation**: Create specific resource and synchronization constraint modules

**Step 3.3a: Vision and Line-of-Sight Module**
Create `apps/aria_timestrike_core/lib/aria_engine/vision_constraint.ex`

- Line-of-sight calculation algorithm (Bresenham's line or ray casting)
- Vision range enforcement and validation
- Obstacle detection and shadowing
- Pass Maya line-of-sight visibility tests

**Step 3.3b: Patrol Prediction Module**
Create `apps/aria_timestrike_core/lib/aria_engine/patrol_predictor.ex`

- Deterministic patrol route prediction algorithm
- Waypoint timing calculation with pause behaviors
- Future position queries at arbitrary times
- Pass soldier2 patrol timing prediction tests

**Step 3.3c: Opportunity Window Detection Module**
Create `apps/aria_timestrike_core/lib/aria_engine/opportunity_detector.ex`

- Archer1 line-of-sight blocking detection algorithm
- Temporal opportunity window identification
- Multi-agent interference pattern analysis
- Pass archer1 blocking opportunity tests

**Step 3.3d: Synchronization Constraint Engine**
Create `apps/aria_timestrike_core/lib/aria_engine/sync_constraint_engine.ex`

- Dynamic constraint activation based on state conditions
- When-then rule evaluation for temporal dependencies
- Conditional constraint propagation integration with STN
- Pass Maya synchronization constraint tests

### Phase 4: Backtracking Engine (Building on Phases 1-3)

#### Step 4.1: Conflict Detection and Backtracking Triggers

**Test First**: Detect failures that require backtracking in ADR-035 scenario

```elixir
# test/aria_engine/backtracking_engine_test.exs
defmodule AriaEngine.BacktrackingEngineTest do
  use ExUnit.Case, async: true
  
  test "detects imperfect information conflict requiring reconnaissance" do
    initial_plan = build_naive_maya_plan()  # Maya directly attacks unseen target
    state = build_maya_scenario_state()
    
    {:error, conflict} = BacktrackingEngine.validate_plan(initial_plan, state)
    
    assert conflict.type == :imperfect_information_conflict
    assert conflict.agent == "maya"
    assert conflict.missing_information == [:target_position]
    assert conflict.suggested_backtrack == :deploy_reconnaissance
  end
  
  test "detects temporal coordination conflict with patrol timing" do
    coordination_plan = build_simple_coordination_plan()  # Ignores waypoint pauses
    
    {:error, conflict} = BacktrackingEngine.validate_plan(coordination_plan, state)
    
    assert conflict.type == :temporal_prediction_conflict
    assert conflict.failed_assumption == :linear_patrol_movement
    assert conflict.suggested_backtrack == :exploit_waypoint_pauses
  end
  
  test "triggers multi-phase backtracking for cascading failures" do
    failed_plan = build_cascading_failure_plan()
    
    {:ok, backtrack_phases} = BacktrackingEngine.analyze_failures(failed_plan)
    
    assert length(backtrack_phases) >= 3
    assert Enum.any?(backtrack_phases, &(&1.type == :information_gathering))
    assert Enum.any?(backtrack_phases, &(&1.type == :temporal_coordination))
    assert Enum.any?(backtrack_phases, &(&1.type == :opportunity_exploitation))
  end
end
```

**Implementation**: Create `apps/aria_timestrike_core/lib/aria_engine/backtracking_engine.ex`

- Conflict detection for different failure types
- Backtracking trigger analysis
- Multi-phase backtracking planning
- Pass Maya conflict detection tests

#### Step 4.2: Plan Revision and Alternative Generation

**Test First**: Generate alternative plans through backtracking

```elixir
# test/aria_engine/plan_revision_test.exs
defmodule AriaEngine.PlanRevisionTest do
  use ExUnit.Case, async: true
  
  test "revises plan to include Alex reconnaissance mission" do
    failed_plan = build_imperfect_information_failure()
    
    {:ok, revised_plan} = PlanRevision.backtrack_and_revise(failed_plan)
    
    # New plan includes Alex scouting task
    alex_scout = find_task(revised_plan, :agent, "alex", :type, :scout_area)
    maya_attack = find_task(revised_plan, :agent, "maya", :type, :cast_scorch)
    
    assert alex_scout != nil
    assert maya_attack.start_time > alex_scout.end_time
    assert maya_attack.preconditions[:target_visible] == true
  end
  
  test "exploits waypoint pause timing in revised coordination" do
    temporal_failure_plan = build_temporal_coordination_failure()
    
    {:ok, revised_plan} = PlanRevision.backtrack_and_revise(temporal_failure_plan)
    
    # Maya positioned during soldier2's pause at {12,5,0}
    maya_position = find_task(revised_plan, :agent, "maya", :type, :move_to)
    soldier2_pause = find_constraint(revised_plan, :type, :waypoint_pause)
    
    assert maya_position.target_position == {11, 5, 0}  # Adjacent to pause location
    assert maya_position.arrival_time >= soldier2_pause.start_time
    assert maya_position.arrival_time <= soldier2_pause.end_time
  end
  
  test "generates emergency fallback for bunker approach scenario" do
    emergency_scenario = build_emergency_bunker_scenario()
    
    {:ok, fallback_plan} = PlanRevision.generate_emergency_fallback(emergency_scenario)
    
    # Direct interception before bunker reach
    interception = find_task(fallback_plan, :type, :direct_interception)
    bunker_reach = find_constraint(fallback_plan, :type, :bunker_deadline)
    
    assert interception.execution_time < bunker_reach.deadline
  end
end
```

**Implementation**: Create comprehensive plan revision and backtracking modules

**Step 4.2a: Plan Revision Engine (Constraint Analysis & Modification)**
Create `apps/aria_timestrike_core/lib/aria_engine/plan_revision.ex`

- **Constraint failure analysis**: Identify which specific constraints are violated (no new algorithms)
- **Constraint relaxation**: Systematically loosen constraints that are causing failures
- **Backtracking strategy**: Choose which constraint sets to try (prioritization, not new solving algorithms)
- **Plan quality validation**: Verify revised constraint sets still meet quality requirements
- **Implementation approach**: Analyze failed constraints → Generate relaxed constraint variations → Reuse existing STN solver

**Step 4.2b: Alternative Plan Generator (Constraint Set Exploration)**
Create `apps/aria_timestrike_core/lib/aria_engine/alternative_generator.ex`

- **No new algorithms**: Systematic exploration of different constraint sets using existing STN solver
- **Constraint timing adjustment**: Shift temporal bounds (e.g., `maya_attack_time <= 70` instead of `<= 50`)
- **Resource constraint reallocation**: Change resource allocation values (e.g., `alex_scout_duration = 5` instead of `10`)
- **Temporal window shifting**: Adjust time windows and deadlines within existing constraint framework
- **Quality constraint preservation**: Always include mandatory quality constraints in all alternative sets
- **Implementation approach**: Generate constraint variations → Apply existing STN solver → Filter by quality metrics

**Step 4.2c: Emergency Fallback Planner (Simplified Constraint Sets)**
Create `apps/aria_timestrike_core/lib/aria_engine/emergency_fallback.ex`

- **Minimal constraint sets**: Use simplified constraint sets with relaxed coordination requirements
- **Direct action constraints**: Remove complex coordination constraints, allow independent agent actions
- **Risk tolerance adjustment**: Modify safety and quality constraints to allow higher-risk solutions
- **Time pressure handling**: Use tighter temporal bounds to force immediate action decisions
- **Implementation approach**: Predefined simplified constraint templates → Existing STN solver → Fast resolution
- Pass emergency scenario fallback tests
- Pass Maya plan revision tests

### Phase 5: Performance and Integration (Building on Phases 1-4)

#### Step 5.1: High-Performance Computing Integration

**Test First**: Verify Nx/Flow optimization for large-scale temporal problems

```elixir
# test/aria_engine/high_performance_test.exs
defmodule AriaEngine.HighPerformanceTest do
  use ExUnit.Case, async: true
  
  @tag :performance
  test "Nx tensor operations for Floyd-Warshall optimization" do
    # Large STN with 1000 timepoints  
    large_constraints = build_large_stn_constraints(1000)
    
    {time, {:ok, solution}} = :timer.tc(fn ->
      STNSolver.solve_with_nx(large_constraints)
    end)
    
    # Nx should provide significant speedup
    time_ms = time / 1000
    assert time_ms <= 100.0  # Large STN solved within 100ms
    assert STNSolver.is_consistent?(solution) == true
  end
  
  @tag :performance
  test "Flow parallel constraint propagation" do
    # Multiple independent constraint sets
    constraint_sets = build_parallel_constraint_sets(10)
    
    {time, solutions} = :timer.tc(fn ->
      constraint_sets
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(&ConstraintPropagator.propagate/1)
      |> Enum.to_list()
    end)
    
    # Parallel processing improves throughput
    time_ms = time / 1000
    assert time_ms <= 50.0
    assert length(solutions) == 10
  end
  
  @tag :performance  
  test "GenStage backpressure for real-time constraint updates" do
    # Streaming constraint updates
    {:ok, producer} = ConstraintProducer.start_link([])
    {:ok, consumer} = ConstraintConsumer.start_link([])
    
    GenStage.sync_subscribe(consumer, to: producer)
    
    # High-frequency constraint updates handled with backpressure
    for i <- 1..1000 do
      ConstraintProducer.add_constraint(producer, build_constraint(i))
    end
    
    # All constraints processed without overflow
    :timer.sleep(100)
    assert ConstraintConsumer.processed_count(consumer) == 1000
  end
end
```

**Implementation**: Performance optimization with ADR-041 tech stack

- Nx tensor operations for Floyd-Warshall algorithm
- Flow parallel processing for constraint propagation
- GenStage backpressure for real-time updates
- Pass high-performance computing integration tests

#### Step 5.2: Real-Time Performance Requirements

**Test First**: Verify ADR-035's performance requirements are met

```elixir
# test/aria_engine/performance_test.exs
defmodule AriaEngine.PerformanceTest do
  use ExUnit.Case, async: true
  
  @tag :performance
  test "planning time within 10ms bound for Maya scenario" do
    state = build_maya_scenario_state()
    goal = build_eliminate_soldier_patrol_goal()
    
    {time, {:ok, _plan}} = :timer.tc(fn ->
      TemporalPlanner.plan(goal, state)
    end)
    
    planning_time_ms = time / 1000
    assert planning_time_ms <= 10.0
  end
  
  @tag :performance  
  test "replanning faster than initial planning" do
    initial_plan = build_initial_maya_plan()
    conflict = build_reconnaissance_conflict()
    
    {initial_time, _} = :timer.tc(fn -> TemporalPlanner.plan(goal, state) end)
    {replan_time, _} = :timer.tc(fn -> 
      TemporalPlanner.replan(initial_plan, conflict) 
    end)
    
    assert replan_time < initial_time
  end
  
  @tag :performance
  test "state queries respond within 1ms" do
    state = build_large_temporal_state()  # 1000+ temporal objects
    
    {time, _result} = :timer.tc(fn ->
      TemporalState.get_temporal_object(state, "position", "soldier2", 150)
    end)
    
    query_time_ms = time / 1000
    assert query_time_ms <= 1.0
  end
end
```

**Implementation**: Performance optimization across all modules

- STN solver optimization with sparse matrices
- Timeline indexing for fast queries
- Caching for repeated computations
- Pass all performance requirement tests

#### Step 5.3: Integration with Existing AriaEngine Architecture

**Test First**: Integration with existing game engine and TUI

```elixir
# test/aria_timestrike/temporal_integration_test.exs
defmodule AriaTimestrike.TemporalIntegrationTest do
  use ExUnit.Case, async: true
  
  test "integrates with existing game state management" do
    # Uses existing AriaEngine.TemporalState from aria_timestrike_core
    game_state = AriaTimestrike.GameSupervisor.get_current_state()
    temporal_state = TemporalState.from_game_state(game_state)
    
    assert %AriaEngine.TemporalState{} = temporal_state
    assert temporal_state.agents != %{}
  end
  
  test "executes temporal plans through existing action system" do
    plan = build_maya_temporal_plan()
    
    {:ok, execution_result} = AriaTimestrike.execute_temporal_plan(plan)
    
    # Actions executed through existing AriaEngine.GameActionJob
    assert execution_result.actions_executed > 0
    assert execution_result.total_time_ms < 100
  end
  
  test "displays temporal planning in TUI interface" do
    plan = build_maya_temporal_plan()
    
    tui_output = AriaTimestrike.TuiContentProvider.format_temporal_plan(plan)
    
    assert String.contains?(tui_output, "Maya:")
    assert String.contains?(tui_output, "Alex:")
    assert String.contains?(tui_output, "Timeline:")
  end
end
```

**Implementation**: Create comprehensive integration layer connecting temporal planner with existing AriaEngine architecture

**Step 5.3a: Game State Integration Adapter**
Create `apps/aria_timestrike_core/lib/aria_timestrike/game_state_adapter.ex`

- Bidirectional conversion between AriaEngine game state and TemporalState
- Incremental state synchronization during plan execution
- Game object lifecycle management integration
- State consistency validation across engine boundaries

**Step 5.3b: Action Execution Bridge**
Create `apps/aria_timestrike_core/lib/aria_timestrike/action_executor.ex`

- Temporal action translation to AriaEngine.GameActionJob format
- Action scheduling and timing coordination with game loop
- Failure handling and temporal plan adjustment integration
- Real-time action execution monitoring and feedback

**Step 5.3c: TUI Temporal Plan Display**
Create `apps/aria_timestrike_core/lib/aria_timestrike/tui_content_provider.ex`

- Temporal plan visualization for TUI interface
- Timeline rendering with agent coordination display
- Backtracking phase indication and alternative plan comparison
- Real-time plan execution progress monitoring

**Step 5.3d: OTP Supervision Tree Integration**
Create `apps/aria_timestrike_core/lib/aria_timestrike/supervisor.ex`

- Temporal planner process supervision strategy per ADR-041
- GenServer integration for temporal state management
- GenStage pipeline for constraint propagation with backpressure
- Fault tolerance and graceful degradation for planning failures

- Pass integration tests with existing AriaEngine system

## Verification Criteria

Each phase must pass all tests before proceeding to the next phase:

### Phase 1 Completion Criteria

- ✅ Temporal state initialization for Maya scenario
- ✅ Time-based queries and historical reconstruction
- ✅ Basic timeline representation and conflict detection
- ✅ JSON-LD solution network serialization with chibifire.com namespace
- ✅ STN constraint solving with Floyd-Warshall algorithm

### Phase 2 Completion Criteria  

- ✅ Goal decomposition into ADR-035's required tasks
- ✅ Multi-agent coordination for Maya and Alex
- ✅ Information sharing and timing synchronization
- ✅ Primitive action generation from tasks

### Phase 3 Completion Criteria

- ✅ JSON-LD solution network integration with temporal plans
- ✅ STN + Timeline integration with constraint satisfaction
- ✅ Vision range and line-of-sight modeling
- ✅ Patrol behavior as synchronization constraints
- ✅ Resource constraint validation

### Phase 4 Completion Criteria

- ✅ Conflict detection for all ADR-035 failure scenarios
- ✅ Multi-phase backtracking plan revision  
- ✅ Alternative plan generation through backtracking
- ✅ Emergency fallback planning

### Phase 5 Completion Criteria

- ✅ Nx/Flow high-performance computing integration
- ✅ Planning time ≤ 10ms for Maya scenario
- ✅ Replanning faster than initial planning
- ✅ State queries ≤ 1ms response time
- ✅ Integration with existing AriaEngine architecture

### Final Validation: ADR-035 Canonical Problem Solution

The complete implementation must successfully solve Maya's Adaptive Scorch Coordination:

```elixir
# Final integration test that proves TDD implementation success
test "solves Maya's Adaptive Scorch Coordination completely" do
  initial_state = build_maya_scenario_state()
  goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
  
  {:ok, solution} = TemporalPlanner.solve_canonical_problem(goal, initial_state)
  
  # Verify all ADR-035 requirements satisfied
  assert solution.backtrack_phases >= 3
  assert solution.conflict_types_addressed >= 3  
  assert solution.information_gathering_successful == true
  assert solution.temporal_coordination_successful == true
  assert solution.opportunity_exploitation_successful == true
  assert solution.planning_time_ms <= 10.0
  assert solution.soldier2_eliminated == true
  assert solution.maya_safety_maintained == true
end
```

## Implementation Schedule

**Strict TDD Order**: Each step must pass all tests before proceeding

- **Phase 1**: Foundation (Red-Green-Refactor for data structures)
- **Phase 2**: GTN Core (Red-Green-Refactor for planning logic)  
- **Phase 3**: Constraints (Red-Green-Refactor for temporal reasoning)
- **Phase 4**: Backtracking (Red-Green-Refactor for plan revision)
- **Phase 5**: Performance (Red-Green-Refactor for optimization)

**Success Criteria**: Complete solution to ADR-035's canonical temporal backtracking problem with all performance requirements met.

## Related ADRs

- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md) - **The definitive test case**
- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md) - **Architecture foundation**
- [ADR-040: Temporal Constraint Solver Selection](040-temporal-constraint-solver-selection.md) - **STN solver specification**
- [ADR-041: Temporal Solver Tech Stack Requirements](041-temporal-solver-tech-stack-requirements.md) - **Implementation tech stack**
- [ADR-043: Total Order to Partial Order Transformation](043-total-order-to-partial-order-transformation.md) - **PC-2 parallelization algorithm**
- [ADR-044: Temporal Planner as Auto Battler AI](044-temporal-planner-as-auto-battler-ai.md) - **Accessible explanation for stakeholders**
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md) - **Timeline approach rationale**
- [ADR-038: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md) - **Deprecated**

This cold boot order ensures disciplined TDD implementation that builds verified functionality incrementally toward solving the complete canonical temporal backtracking problem.
