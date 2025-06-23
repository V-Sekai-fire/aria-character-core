# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Multigoal.ConstraintBuilder do
  @moduledoc """
  MiniZinc constraint model builder for multigoal optimization.

  This module generates MiniZinc constraint models for different types
  of multigoal optimization problems. It uses EEx templates to create
  constraint models tailored to specific optimization scenarios.

  ## Model Types

  - **Spatial Models**: Minimize travel distance and movement costs
  - **Dependency Models**: Respect preconditions and minimize completion time
  - **Parallel Models**: Maximize concurrent execution opportunities
  - **Resource Models**: Minimize conflicts and maximize utilization

  ## Usage

      iex> state = State.new()
      iex> goals = [{"location", "robot", "station_1"}]
      iex> AriaEngine.Multigoal.ConstraintBuilder.build_spatial_model(state, goals)
      {:ok, "% MiniZinc spatial optimization model..."}

  Related: ADR-126 - MiniZinc Multigoal Optimization with Fallback
  """

  require Logger
  alias State

  @type goal :: {State.subject(), State.predicate(), State.fact_value()}

  @doc """
  Build general optimization constraint model.

  Generates a MiniZinc model for general multigoal optimization that
  balances completion time, resource conflicts, and parallel opportunities.
  """
  @spec build_general_model(State.t(), [goal()]) :: {:ok, String.t()} | {:error, term()}
  def build_general_model(_state, goals) do
    try do
      # Extract general optimization information
      model_data = %{
        num_goals: length(goals),
        goals: goals,
        goal_costs: estimate_goal_costs(goals),
        dependencies: analyze_simple_dependencies(goals),
        optimization_type: :general
      }

      case AriaEngine.Multigoal.TemplateRenderer.render_general_template(model_data) do
        {:ok, model} -> {:ok, model}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        Logger.warning("General model building failed: #{inspect(error)}")
        {:error, {:general_model_build_failed, error}}
    end
  end

  @doc """
  Build dependency optimization constraint model.

  Generates a MiniZinc model for respecting goal dependencies and
  minimizing total completion time.
  """
  @spec build_dependency_model(State.t(), [goal()]) :: {:ok, String.t()} | {:error, term()}
  def build_dependency_model(state, goals) do
    try do
      # Analyze goal dependencies
      dependencies = analyze_goal_dependencies(state, goals)
      precedence_constraints = build_precedence_constraints(dependencies)
      action_costs = estimate_action_costs(goals)

      model_data = %{
        num_goals: length(goals),
        dependencies: dependencies,
        precedence_constraints: precedence_constraints,
        action_costs: action_costs,
        goals: goals
      }

      case AriaEngine.Multigoal.TemplateRenderer.render_dependency_template(model_data) do
        {:ok, model} -> {:ok, model}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        Logger.warning("Dependency model building failed: #{inspect(error)}")
        {:error, {:dependency_model_build_failed, error}}
    end
  end

  @doc """
  Build parallel optimization constraint model.

  Generates a MiniZinc model for maximizing concurrent goal achievement
  and minimizing total completion time.
  """
  @spec build_parallel_model(State.t(), [goal()]) :: {:ok, String.t()} | {:error, term()}
  def build_parallel_model(state, goals) do
    try do
      # Identify parallelization opportunities
      parallel_groups = identify_parallel_groups(state, goals)
      agent_assignments = analyze_agent_assignments(goals)
      synchronization_points = find_synchronization_points(parallel_groups)

      model_data = %{
        num_goals: length(goals),
        num_agents: count_agents(goals),
        parallel_groups: parallel_groups,
        agent_assignments: agent_assignments,
        synchronization_points: synchronization_points,
        goals: goals
      }

      case AriaEngine.Multigoal.TemplateRenderer.render_parallel_template(model_data) do
        {:ok, model} -> {:ok, model}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        Logger.warning("Parallel model building failed: #{inspect(error)}")
        {:error, {:parallel_model_build_failed, error}}
    end
  end

  @doc """
  Build resource optimization constraint model.

  Generates a MiniZinc model for minimizing resource conflicts and
  maximizing utilization efficiency.
  """
  @spec build_resource_model(State.t(), [goal()]) :: {:ok, String.t()} | {:error, term()}
  def build_resource_model(state, goals) do
    try do
      # Analyze resource requirements
      resources = extract_resources(state, goals)
      resource_requirements = analyze_resource_requirements(goals, resources)
      conflict_matrix = build_conflict_matrix(resource_requirements)

      model_data = %{
        num_goals: length(goals),
        num_resources: length(resources),
        resources: resources,
        resource_requirements: resource_requirements,
        conflict_matrix: conflict_matrix,
        goals: goals
      }

      case AriaEngine.Multigoal.TemplateRenderer.render_resource_template(model_data) do
        {:ok, model} -> {:ok, model}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error ->
        Logger.warning("Resource model building failed: #{inspect(error)}")
        {:error, {:resource_model_build_failed, error}}
    end
  end

  # General model helpers

  defp estimate_goal_costs(goals) do
    goals
    |> Enum.map(fn {_subject, predicate, _value} ->
      case predicate do
        # Movement actions
        "location" -> 5
        # Pickup/manipulation actions
        "has" -> 3
        # State change actions
        "state" -> 4
        # Assignment actions
        "assigned_to" -> 2
        # Default action cost
        _ -> 3
      end
    end)
  end

  defp analyze_simple_dependencies(goals) do
    goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, _value}, index} ->
      # Simple dependency analysis - same subject goals depend on each other
      deps =
        goals
        |> Enum.with_index()
        |> Enum.filter(fn {{dep_subject, dep_predicate, _dep_value}, dep_index} ->
          dep_index != index and subject == dep_subject and predicate != dep_predicate
        end)
        |> Enum.map(fn {_goal, dep_index} -> dep_index end)

      {index, deps}
    end)
  end

  # Dependency model helpers

  defp analyze_goal_dependencies(state, goals) do
    goals
    |> Enum.with_index()
    |> Enum.map(fn {goal, index} ->
      deps = find_goal_dependencies(goal, goals, state)
      {index, deps}
    end)
  end

  defp find_goal_dependencies({subject, predicate, value}, goals, _state) do
    # Analyze what other goals this goal depends on
    goals
    |> Enum.with_index()
    |> Enum.filter(fn {{dep_subject, dep_predicate, dep_value}, _index} ->
      # Simple dependency heuristics
      cond do
        # Same subject, different predicate (e.g., get key before open door)
        subject == dep_subject and predicate != dep_predicate ->
          true

        # Key-door dependencies
        predicate == "state" and value == "open" and
          dep_predicate == "has_key" and dep_value == true ->
          true

        # Location dependencies (must have item before moving it)
        predicate == "location" and
          dep_predicate == "has" and String.contains?(subject, to_string(dep_value)) ->
          true

        true ->
          false
      end
    end)
    |> Enum.map(fn {_goal, index} -> index end)
  end

  defp build_precedence_constraints(dependencies) do
    dependencies
    |> Enum.flat_map(fn {goal_index, dep_indices} ->
      Enum.map(dep_indices, fn dep_index ->
        "constraint goal_start[#{dep_index + 1}] < goal_start[#{goal_index + 1}];"
      end)
    end)
  end

  defp estimate_action_costs(goals) do
    goals
    |> Enum.map(fn {_subject, predicate, _value} ->
      case predicate do
        # Movement actions
        "location" -> 5
        # Pickup/manipulation actions
        "has" -> 3
        # State change actions
        "state" -> 4
        # Default action cost
        _ -> 2
      end
    end)
  end

  # Parallel model helpers

  defp identify_parallel_groups(_state, goals) do
    # Group goals that can be executed in parallel
    goals
    |> Enum.with_index()
    |> Enum.group_by(fn {{subject, predicate, value}, _index} ->
      # Group by agent/worker for parallel execution
      cond do
        String.contains?(subject, "robot") -> extract_agent_id(subject)
        String.contains?(subject, "worker") -> extract_agent_id(subject)
        String.contains?(subject, "agent") -> extract_agent_id(subject)
        predicate == "assigned_to" -> value
        true -> "default_agent"
      end
    end)
    |> Map.values()
    |> Enum.filter(fn group -> length(group) > 1 end)
  end

  defp extract_agent_id(subject) do
    # Extract agent identifier from subject string
    case Regex.run(~r/(robot|worker|agent)_?(\d+)/, subject) do
      [_full, type, id] -> "#{type}_#{id}"
      _ -> subject
    end
  end

  defp analyze_agent_assignments(goals) do
    goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, value}, index} ->
      agent =
        cond do
          String.contains?(subject, ["robot", "worker", "agent"]) -> subject
          predicate == "assigned_to" -> value
          true -> "default_agent"
        end

      {index, agent}
    end)
  end

  defp find_synchronization_points(parallel_groups) do
    # Identify points where parallel execution must synchronize
    parallel_groups
    |> Enum.with_index()
    |> Enum.flat_map(fn {group, group_index} ->
      if length(group) > 1 do
        # Last goal in each group is a synchronization point
        last_goal_index = group |> List.last() |> elem(1)
        [{group_index, last_goal_index}]
      else
        []
      end
    end)
  end

  defp count_agents(goals) do
    goals
    |> Enum.map(fn {subject, predicate, value} ->
      cond do
        String.contains?(subject, ["robot", "worker", "agent"]) -> subject
        predicate == "assigned_to" -> value
        true -> "default_agent"
      end
    end)
    |> Enum.uniq()
    |> length()
  end

  # Resource model helpers

  defp extract_resources(_state, goals) do
    # Extract all resources mentioned in goals
    # Note: State doesn't have get_all_facts/1, so we focus on goal resources
    goal_resources =
      goals
      |> Enum.filter(fn {subject, predicate, value} ->
        predicate == "has" or
          String.contains?(subject, ["tool", "resource"]) or
          String.contains?(to_string(value), ["tool", "resource", "workstation"])
      end)
      |> Enum.flat_map(fn {subject, _predicate, value} ->
        [subject, to_string(value)]
      end)

    goal_resources
    |> Enum.filter(&String.contains?(&1, ["tool", "resource", "workstation"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp analyze_resource_requirements(goals, resources) do
    goals
    |> Enum.with_index()
    |> Enum.map(fn {{subject, predicate, value}, index} ->
      required_resources = []

      # Check if goal requires specific resources
      required_resources =
        if predicate == "has" and
             String.contains?(to_string(value), ["tool", "resource"]) do
          [to_string(value) | required_resources]
        else
          required_resources
        end

      required_resources =
        if String.contains?(subject, ["tool", "resource"]) do
          [subject | required_resources]
        else
          required_resources
        end

      # Map to resource indices
      resource_indices =
        required_resources
        |> Enum.map(fn resource -> Enum.find_index(resources, &(&1 == resource)) end)
        |> Enum.filter(&(&1 != nil))

      {index, resource_indices}
    end)
  end

  defp build_conflict_matrix(resource_requirements) do
    num_goals = length(resource_requirements)

    for i <- 0..(num_goals - 1) do
      for j <- 0..(num_goals - 1) do
        if i == j do
          0
        else
          {_i_index, i_resources} = Enum.at(resource_requirements, i)
          {_j_index, j_resources} = Enum.at(resource_requirements, j)

          # Check if goals share any resources
          shared_resources = i_resources -- (i_resources -- j_resources)
          if length(shared_resources) > 0, do: 1, else: 0
        end
      end
    end
  end
end
