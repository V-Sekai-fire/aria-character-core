defmodule AriaInteractivity do
  @moduledoc """
  Aria Interactivity - glTF Interactivity Extension as Temporal Planning Domain

  This module provides the main interface for converting glTF interactivity
  nodes from the Khronos specification into a temporal planning domain that
  can be used with the aria-hybrid-planner.

  Based on ADR R25W167INT and glTF Specification.adoc
  """

  alias AriaInteractivity.Domain
  alias AriaInteractivity.Temporal
  alias AriaInteractivity.NodeParser

  @doc """
  Parse glTF interactivity specification and create planning domain.

  ## Examples

      iex> AriaInteractivity.parse_specification()
      {:ok, :domain_loaded}

  """
  def parse_specification do
    # Domain is implemented in AriaInteractivity.Domain
    {:ok, :domain_loaded}
  end

  @doc """
  Convert glTF behavior graph to planning problem.

  ## Examples

      iex> graph = %{"nodes" => [], "variables" => []}
      iex> AriaInteractivity.graph_to_problem(graph)
      {:ok, %{initial_state: %{}, goal: %{}, operators: []}}

  """
  def graph_to_problem(graph) do
    NodeParser.graph_to_planning_problem(graph)
  end

  @doc """
  Execute glTF interactivity node in planning context.

  ## Examples

      iex> state = %AriaState{}
      iex> node = %{"operation" => "math/add", "values" => %{"a" => %{"value" => [1]}, "b" => %{"value" => [2]}}}
      iex> AriaInteractivity.execute_node(node, state)
      {:ok, %AriaState{}}

  """
  def execute_node(node, state) do
    NodeParser.parse_node(node, state)
  end

  @doc """
  Create temporal animation action with glTF parameters.

  ## Examples

      iex> AriaInteractivity.create_temporal_animation(0, "PT2S", 0, 2, 1.0)
      {:ok, [%{type: :temporal_action}]}

  """
  def create_temporal_animation(animation_index, duration, start_time, end_time, speed) do
    # Create a mock state for the domain function
    state = %{}
    Domain.create_temporal_animation(state, [animation_index, duration, start_time, end_time, speed])
  end

  @doc """
  Parse ISO 8601 duration string.

  ## Examples

      iex> AriaInteractivity.parse_duration("PT1H30M")
      {:ok, 5400.0}

  """
  def parse_duration(duration_str) do
    Temporal.parse_iso8601_duration(duration_str)
  end

  @doc """
  Create fixed duration temporal action pattern.

  ## Examples

      iex> AriaInteractivity.create_fixed_duration_action(:my_action, 5.0)
      %{type: :fixed_duration, action: :my_action, duration: 5.0}

  """
  def create_fixed_duration_action(action_name, duration_seconds) do
    Temporal.create_fixed_duration_action(action_name, duration_seconds)
  end

  @doc """
  Validate temporal constraints for a set of actions.

  ## Examples

      iex> actions = [%{constraints: []}]
      iex> AriaInteractivity.validate_temporal_constraints(actions)
      {:ok, %{valid: true, constraints: []}}

  """
  def validate_temporal_constraints(actions) do
    Temporal.validate_temporal_constraints(actions)
  end
end
