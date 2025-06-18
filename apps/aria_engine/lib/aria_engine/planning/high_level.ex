# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planning.HighLevel do
  @moduledoc """
  Provides high-level planning and execution functionalities for the Aria Engine.
  """

  alias AriaEngine.Planning.Internal
  alias AriaEngine.Core
  alias AriaEngine.Planner

  @type t :: AriaEngine.Planning.HighLevel.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()

  @doc """
  Plans the goals using IPyHOP-style HTN planning.
  """
  @spec plan_advanced(Core.t(), keyword()) :: {:ok, Core.t()} | {:error, String.t()}
  def plan_advanced(%Core{status: :pending} = engine, opts \\[]) do
    domain_interface = Internal.to_planner_interface(engine)

    case Planner.plan(domain_interface, engine.initial_state, engine.goals, opts) do
      {:ok, solution_tree} ->
        planned_engine = %{engine |
          status: :executing,
          started_at: DateTime.utc_now(),
          solution_tree: solution_tree,
          progress: %{engine.progress |
            total_steps: Planner.plan_cost(solution_tree)
          }
        }

        {:ok, planned_engine}

      {:error, reason} ->
        _failed_engine = %{engine |
          status: :failed,
          error: reason,
          completed_at: DateTime.utc_now()
        }

        {:error, reason}
    end
  end

  @doc """
  Executes the planned solution using Run-Lazy-Refineahead.
  """
  @spec execute(Core.t(), keyword()) :: {:ok, Core.t()} | {:error, String.t()}
  def execute(engine, opts \\[])

  def execute(%Core{status: :executing, solution_tree: solution_tree} = engine, opts)
      when not is_nil(solution_tree) do

    domain_interface = Internal.to_planner_interface(engine)

    case Planner.execute(domain_interface, engine.current_state, solution_tree, opts) do
      {:ok, final_state} ->
        completed_engine = %{engine |
          status: :completed,
          current_state: final_state,
          completed_at: DateTime.utc_now(),
          progress: %{engine.progress |
            completed_steps: engine.progress.total_steps,
            current_step: "completed"
          }
        }

        {:ok, completed_engine}

      {:error, reason} ->
        _failed_engine = %{engine |
          status: :failed,
          error: reason,
          completed_at: DateTime.utc_now()
        }

        {:error, reason}
    end
  end

  def execute(%Core{status: status}, _opts) do
    {:error, "Cannot execute engine in status: #{status}. Must be :executing with a solution tree."}
  end

  @doc """
  Plans and executes in one step.
  """
  @spec run(Core.t(), keyword()) :: {:ok, Core.t()} | {:error, String.t()}
  def run(%Core{} = engine, opts \\[]) do
    with {:ok, planned_engine} <- plan_advanced(engine, opts),
         {:ok, completed_engine} <- execute(planned_engine, opts) do
      {:ok, completed_engine}
    end
  end
end
