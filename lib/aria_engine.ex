defmodule AriaEngine do
  @moduledoc """
  Unified API for AriaEngine planning and execution.

  This module provides the top-level interface for interacting with the
  Aria planning system, as specified in ADR R25W1398085. It delegates
  to `AriaEngineCore` for core functionality.
  """

  alias AriaEngineCore

  @doc """
  Plan to achieve goals without execution.

  This function only performs planning and returns the solution tree without executing it.
  Use this when you need to inspect or modify the plan before execution.
  """
  @spec plan(AriaEngineCore.domain(), AriaEngineCore.state(), [AriaEngineCore.todo_item()]) ::
          {:ok, AriaEngineCore.solution_tree()} | {:error, atom()}
  def plan(domain, state, goals) do
    AriaEngineCore.plan(domain, state, goals)
  end

  @doc """
  Plan and execute goals with automatic recovery.

  This is the recommended function for most use cases. It combines planning
  and execution with intelligent recovery from failures.
  """
  @spec run_lazy(AriaEngineCore.domain(), AriaEngineCore.state(), [AriaEngineCore.todo_item()]) ::
          {:ok, {AriaEngineCore.state(), AriaEngineCore.solution_tree()}} | {:error, atom()}
  def run_lazy(domain, state, goals) do
    AriaEngineCore.run_lazy(domain, state, goals)
  end

  @doc """
  Execute a pre-made solution tree.

  This function takes a solution tree that was created and validated earlier
  and executes it, returning the final state and updated tree.
  """
  @spec run_lazy_tree(AriaEngineCore.domain(), AriaEngineCore.state(), AriaEngineCore.solution_tree()) ::
          {:ok, {AriaEngineCore.state(), AriaEngineCore.solution_tree()}} | {:error, atom()}
  def run_lazy_tree(domain, state, solution_tree) do
    AriaEngineCore.run_lazy_tree(domain, state, solution_tree)
  end

  @doc """
  Get the domain type for external API compatibility.
  """
  @spec domain() :: module()
  def domain, do: AriaEngineCore.domain()

  @doc """
  Get the state type for external API compatibility.
  """
  @spec state() :: module()
  def state, do: AriaEngineCore.state()

  @doc """
  Get the todo_item type for external API compatibility.
  """
  @spec todo_item() :: module()
  def todo_item, do: AriaEngineCore.todo_item()

  @doc """
  Get the solution_tree type for external API compatibility.
  """
  @spec solution_tree() :: module()
  def solution_tree, do: AriaEngineCore.solution_tree()
end
