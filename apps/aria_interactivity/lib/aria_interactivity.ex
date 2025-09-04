defmodule AriaInteractivity do
  @moduledoc """
  Aria Interactivity - glTF Interactivity Extension as Temporal Planning Domain

  This module provides the main interface for converting glTF interactivity
  nodes from the Khronos specification into a temporal planning domain that
  can be used with the aria-hybrid-planner.
  """

  @doc """
  Parse glTF interactivity specification and create planning domain.

  ## Examples

      iex> AriaInteractivity.parse_specification()
      {:ok, %Domain{...}}

  """
  def parse_specification do
    # TODO: Implement specification parsing
    {:error, :not_implemented}
  end

  @doc """
  Convert glTF behavior graph to planning problem.

  ## Examples

      iex> graph = %{}
      iex> AriaInteractivity.graph_to_problem(graph)
      {:ok, %PlanningProblem{...}}

  """
  def graph_to_problem(_graph) do
    # TODO: Implement graph conversion
    {:error, :not_implemented}
  end
end
