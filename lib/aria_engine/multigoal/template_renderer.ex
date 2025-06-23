# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Multigoal.TemplateRenderer do
  @moduledoc """
  EEx template renderer for MiniZinc constraint models.

  This module renders MiniZinc constraint models using EEx templates
  for different optimization scenarios. Templates are embedded directly
  in the module to avoid file system dependencies.

  ## Template Types

  - **Spatial Templates**: TSP-style routing optimization
  - **Dependency Templates**: Precedence constraint satisfaction
  - **Parallel Templates**: Multi-agent coordination
  - **Resource Templates**: Conflict-free resource scheduling

  Related: ADR-126 - MiniZinc Multigoal Optimization with Fallback
  """

  require Logger
  require EEx

  @doc """
  Render general optimization template.
  """
  @spec render_general_template(map()) :: {:ok, String.t()} | {:error, term()}
  def render_general_template(data) do
    try do
      model = general_template(data)
      {:ok, model}
    rescue
      error ->
        Logger.warning("General template rendering failed: #{inspect(error)}")
        {:error, {:template_render_failed, error}}
    end
  end

  @doc """
  Render dependency optimization template.
  """
  @spec render_dependency_template(map()) :: {:ok, String.t()} | {:error, term()}
  def render_dependency_template(data) do
    try do
      model = dependency_template(data)
      {:ok, model}
    rescue
      error ->
        Logger.warning("Dependency template rendering failed: #{inspect(error)}")
        {:error, {:template_render_failed, error}}
    end
  end

  @doc """
  Render parallel optimization template.
  """
  @spec render_parallel_template(map()) :: {:ok, String.t()} | {:error, term()}
  def render_parallel_template(data) do
    try do
      model = parallel_template(data)
      {:ok, model}
    rescue
      error ->
        Logger.warning("Parallel template rendering failed: #{inspect(error)}")
        {:error, {:template_render_failed, error}}
    end
  end

  @doc """
  Render resource optimization template.
  """
  @spec render_resource_template(map()) :: {:ok, String.t()} | {:error, term()}
  def render_resource_template(data) do
    try do
      model = resource_template(data)
      {:ok, model}
    rescue
      error ->
        Logger.warning("Resource template rendering failed: #{inspect(error)}")
        {:error, {:template_render_failed, error}}
    end
  end

  # General optimization template
  EEx.function_from_string(
    :defp,
    :general_template,
    """
    % MiniZinc General Optimization Model
    % Generated for multigoal optimization

    % Parameters
    int: num_goals = <%= @num_goals %>;
    int: max_time = num_goals * 8;

    % Goal costs
    array[1..num_goals] of int: goal_costs = [
      <%= for {cost, i} <- Enum.with_index(@goal_costs) do %>
        <%= cost %><%= if i < length(@goal_costs) - 1, do: ", ", else: "" %>
      <% end %>
    ];

    % Simple dependency constraints
    <%= for {goal_index, deps} <- @dependencies do %>
      <%= for dep_index <- deps do %>
    constraint goal_start[<%= dep_index + 1 %>] + goal_costs[<%= dep_index + 1 %>] <= goal_start[<%= goal_index + 1 %>];
      <% end %>
    <% end %>

    % Decision variables
    array[1..num_goals] of var 1..max_time: goal_start;
    array[1..num_goals] of var 1..max_time: goal_end;
    var int: total_actions;
    var int: completion_time;
    var int: parallel_opportunities;

    % Basic constraints
    constraint forall(i in 1..num_goals) (
      goal_end[i] = goal_start[i] + goal_costs[i]
    );

    % Calculate metrics
    constraint total_actions = sum(goal_costs);
    constraint completion_time = max(goal_end);
    constraint parallel_opportunities = max(0, num_goals div 2);

    % Objective: minimize completion time
    solve minimize completion_time;

    % Output
    output [
      "{\\"status\\": \\"SATISFIED\\", ",
      "\\"goal_order\\": [" ++ join(", ", [show(i) | i in 1..num_goals]) ++ "], ",
      "\\"total_actions\\": " ++ show(total_actions) ++ ", ",
      "\\"total_distance\\": " ++ show(num_goals * 3) ++ ", ",
      "\\"completion_time\\": " ++ show(completion_time) ++ ", ",
      "\\"parallel_opportunities\\": " ++ show(parallel_opportunities),
      "}"
    ];
    """,
    [:assigns]
  )

  # Spatial optimization template (TSP-style)
  EEx.function_from_string(
    :defp,
    :spatial_template,
    """
    % MiniZinc Spatial Optimization Model
    % Generated for multigoal optimization

    % Parameters
    int: num_goals = <%= @num_goals %>;
    int: num_locations = <%= @num_locations %>;

    % Distance matrix between locations
    array[1..num_locations, 1..num_locations] of int: distances = [|
    <%= for {row, i} <- Enum.with_index(@distances) do %>
      <%= for {dist, j} <- Enum.with_index(row) do %><%= dist %><%= if j < length(row) - 1, do: ", ", else: "" %><% end %><%= if i < length(@distances) - 1, do: " |", else: " |];" %>
    <% end %>

    % Goal to location mapping
    array[1..num_goals] of 1..num_locations: goal_locations = [
      <%= for {{_index, location}, i} <- Enum.with_index(@goal_locations) do %>
        <%= Enum.find_index(@locations, &(&1 == location)) + 1 %><%= if i < length(@goal_locations) - 1, do: ", ", else: "" %>
      <% end %>
    ];

    % Decision variables
    array[1..num_goals] of var 1..num_goals: goal_order;
    var int: total_distance;
    var int: total_actions;
    var int: completion_time;

    % Constraints
    constraint alldifferent(goal_order);

    % Calculate total travel distance
    constraint total_distance = sum(i in 1..num_goals-1) (
      distances[goal_locations[goal_order[i]], goal_locations[goal_order[i+1]]]
    );

    % Estimate total actions (movement + goal actions)
    constraint total_actions = total_distance + num_goals * 2;

    % Estimate completion time
    constraint completion_time = total_distance * 2 + num_goals * 3;

    % Objective: minimize total distance
    solve minimize total_distance;

    % Output
    output [
      "{\\"status\\": \\"SATISFIED\\", ",
      "\\"goal_order\\": [" ++ join(", ", [show(goal_order[i]) | i in 1..num_goals]) ++ "], ",
      "\\"total_distance\\": " ++ show(total_distance) ++ ", ",
      "\\"total_actions\\": " ++ show(total_actions) ++ ", ",
      "\\"completion_time\\": " ++ show(completion_time) ++ ", ",
      "\\"parallel_opportunities\\": 0",
      "}"
    ];
    """,
    [:assigns]
  )

  # Dependency optimization template
  EEx.function_from_string(
    :defp,
    :dependency_template,
    """
    % MiniZinc Dependency Optimization Model
    % Generated for multigoal optimization with precedence constraints

    % Parameters
    int: num_goals = <%= @num_goals %>;
    int: max_time = num_goals * 10;

    % Action costs for each goal
    array[1..num_goals] of int: action_costs = [
      <%= for {cost, i} <- Enum.with_index(@action_costs) do %>
        <%= cost %><%= if i < length(@action_costs) - 1, do: ", ", else: "" %>
      <% end %>
    ];

    % Decision variables
    array[1..num_goals] of var 1..max_time: goal_start;
    array[1..num_goals] of var 1..max_time: goal_end;
    var int: total_actions;
    var int: completion_time;

    % Basic constraints
    constraint forall(i in 1..num_goals) (
      goal_end[i] = goal_start[i] + action_costs[i]
    );

    % Precedence constraints (dependencies)
    <%= for constraint <- @precedence_constraints do %>
    <%= constraint %>
    <% end %>

    % Calculate metrics
    constraint total_actions = sum(action_costs);
    constraint completion_time = max(goal_end);

    % Objective: minimize completion time
    solve minimize completion_time;

    % Output
    output [
      "{\\"status\\": \\"SATISFIED\\", ",
      "\\"goal_order\\": [" ++ join(", ", [show(i) | i in 1..num_goals]) ++ "], ",
      "\\"total_actions\\": " ++ show(total_actions) ++ ", ",
      "\\"total_distance\\": " ++ show(num_goals * 3) ++ ", ",
      "\\"completion_time\\": " ++ show(completion_time) ++ ", ",
      "\\"parallel_opportunities\\": " ++ show(max(0, num_goals - completion_time div 5)),
      "}"
    ];
    """,
    [:assigns]
  )

  # Parallel optimization template
  EEx.function_from_string(
    :defp,
    :parallel_template,
    """
    % MiniZinc Parallel Optimization Model
    % Generated for multigoal optimization with parallel execution

    % Parameters
    int: num_goals = <%= @num_goals %>;
    int: num_agents = <%= @num_agents %>;
    int: max_time = num_goals * 8;

    % Agent assignments for each goal
    array[1..num_goals] of 1..num_agents: goal_agents = [
      <%= for {{_index, agent}, i} <- Enum.with_index(@agent_assignments) do %>
        <%= hash_agent_to_id(agent, @num_agents) %><%= if i < length(@agent_assignments) - 1, do: ", ", else: "" %>
      <% end %>
    ];

    % Decision variables
    array[1..num_goals] of var 1..max_time: goal_start;
    array[1..num_goals] of var 1..max_time: goal_end;
    array[1..num_agents] of var 1..max_time: agent_finish;
    var int: total_actions;
    var int: completion_time;
    var int: parallel_opportunities;

    % Basic constraints
    constraint forall(i in 1..num_goals) (
      goal_end[i] = goal_start[i] + 3  % Standard goal duration
    );

    % Agent scheduling constraints
    constraint forall(a in 1..num_agents) (
      agent_finish[a] = max([goal_end[i] | i in 1..num_goals where goal_agents[i] = a])
    );

    % No overlapping goals for same agent
    constraint forall(i, j in 1..num_goals where i < j /\\ goal_agents[i] = goal_agents[j]) (
      goal_end[i] <= goal_start[j] \\/ goal_end[j] <= goal_start[i]
    );

    % Calculate metrics
    constraint total_actions = num_goals * 4;
    constraint completion_time = max(agent_finish);
    constraint parallel_opportunities = num_goals - completion_time div 3;

    % Objective: minimize completion time (maximize parallelism)
    solve minimize completion_time;

    % Output
    output [
      "{\\"status\\": \\"SATISFIED\\", ",
      "\\"goal_order\\": [" ++ join(", ", [show(i) | i in 1..num_goals]) ++ "], ",
      "\\"total_actions\\": " ++ show(total_actions) ++ ", ",
      "\\"total_distance\\": " ++ show(num_goals * 3) ++ ", ",
      "\\"completion_time\\": " ++ show(completion_time) ++ ", ",
      "\\"parallel_opportunities\\": " ++ show(parallel_opportunities),
      "}"
    ];
    """,
    [:assigns]
  )

  # Resource optimization template
  EEx.function_from_string(
    :defp,
    :resource_template,
    """
    % MiniZinc Resource Optimization Model
    % Generated for multigoal optimization with resource conflicts

    % Parameters
    int: num_goals = <%= @num_goals %>;
    int: num_resources = <%= @num_resources %>;
    int: max_time = num_goals * 6;

    % Resource conflict matrix
    array[1..num_goals, 1..num_goals] of 0..1: conflicts = [|
    <%= for {row, i} <- Enum.with_index(@conflict_matrix) do %>
      <%= for {conflict, j} <- Enum.with_index(row) do %><%= conflict %><%= if j < length(row) - 1, do: ", ", else: "" %><% end %><%= if i < length(@conflict_matrix) - 1, do: " |", else: " |];" %>
    <% end %>

    % Decision variables
    array[1..num_goals] of var 1..max_time: goal_start;
    array[1..num_goals] of var 1..max_time: goal_end;
    var int: total_actions;
    var int: completion_time;
    var int: parallel_opportunities;

    % Basic constraints
    constraint forall(i in 1..num_goals) (
      goal_end[i] = goal_start[i] + 4  % Standard goal duration with resource overhead
    );

    % Resource conflict constraints
    constraint forall(i, j in 1..num_goals where i < j /\\ conflicts[i,j] = 1) (
      goal_end[i] <= goal_start[j] \\/ goal_end[j] <= goal_start[i]
    );

    % Calculate metrics
    constraint total_actions = num_goals * 4;
    constraint completion_time = max(goal_end);
    constraint parallel_opportunities = max(0, num_goals - sum([conflicts[i,j] | i,j in 1..num_goals where i < j]));

    % Objective: minimize completion time while avoiding conflicts
    solve minimize completion_time;

    % Output
    output [
      "{\\"status\\": \\"SATISFIED\\", ",
      "\\"goal_order\\": [" ++ join(", ", [show(i) | i in 1..num_goals]) ++ "], ",
      "\\"total_actions\\": " ++ show(total_actions) ++ ", ",
      "\\"total_distance\\": " ++ show(num_goals * 3) ++ ", ",
      "\\"completion_time\\": " ++ show(completion_time) ++ ", ",
      "\\"parallel_opportunities\\": " ++ show(parallel_opportunities),
      "}"
    ];
    """,
    [:assigns]
  )

  # Helper function to hash agent names to numeric IDs
  defp hash_agent_to_id(agent, num_agents) do
    agent_hash = :erlang.phash2(agent, num_agents)
    max(1, agent_hash + 1)
  end
end
