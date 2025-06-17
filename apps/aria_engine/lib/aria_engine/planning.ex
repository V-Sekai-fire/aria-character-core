defmodule AriaEngine.Planning do
  @moduledoc """
  Provides core planning and execution functionalities for the Aria Engine.
  """
  alias AriaEngine.Core
  alias AriaEngine.State
  alias AriaEngine.Plan
  alias AriaEngine.Planner

  @type t :: Core.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()

  @doc """
  Plans the goals using IPyHOP-style HTN planning.
  """
  @spec plan_advanced(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def plan_advanced(%Core{status: :pending} = engine, opts \\ []) do
    domain_interface = to_planner_interface(engine)

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
  @spec execute(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def execute(engine, opts \\ [])

  def execute(%Core{status: :executing, solution_tree: solution_tree} = engine, opts)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)

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
  @spec run(t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def run(%Core{} = engine, opts \\ []) do
    with {:ok, planned_engine} <- plan_advanced(engine, opts),
         {:ok, completed_engine} <- execute(planned_engine, opts) do
      {:ok, completed_engine}
    end
  end

  @doc """
  Simple planning interface - finds a plan to achieve the given todos.
  """
  @spec plan(AriaEngine.Domain.t(), Core.state(), [todo_item()], keyword()) :: # Change Core.domain() to Domain.t()
    {:ok, solution_tree()} | {:error, String.t()}
  def plan(%AriaEngine.Domain{} = domain, %State{} = state, todos, opts \\ []) do # Change %Core.Domain{} to %Domain{}
    # The underlying Plan module expects AriaEngine.Domain, so no adapter needed here.
    case Plan.plan(domain, state, todos, opts) do
      {:ok, solution_tree} ->
        {:ok, solution_tree}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Advanced planning interface - returns the full solution tree.
  """
  @spec plan_with_tree(AriaEngine.Domain.t(), Core.state(), [todo_item()], keyword()) :: # Change Core.domain() to Domain.t()
    {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(%AriaEngine.Domain{} = domain, %State{} = state, todos, opts \\ []) do # Change %Core.Domain{} to %Domain{}
    # The underlying Plan module expects AriaEngine.Domain, so no adapter needed here.
    Plan.plan(domain, state, todos, opts)
  end

  @doc """
  Executes a plan step by step, returning the final state.
  """
  @spec execute_plan(AriaEngine.Domain.t(), Core.state(), [plan_step()]) :: {:ok, Core.state()} | {:error, String.t()} # Change Core.domain() to Domain.t()
  def execute_plan(%AriaEngine.Domain{} = domain, %State{} = initial_state, plan) do # Change %Core.Domain{} to %Domain{}
    # The underlying Plan module expects AriaEngine.Domain, so no adapter needed here.
    Plan.validate_plan(domain, initial_state, plan)
  end

  @doc """
  Replan from a failure point using AriaEngine.Planner.
  """
  @spec replan(t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\ [])

  def replan(%Core{solution_tree: solution_tree} = engine, fail_node_id, opts)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)

    case Planner.replan(domain_interface, engine.current_state, solution_tree, fail_node_id, opts) do
      {:ok, new_solution_tree} ->
        updated_engine = %{engine |
          solution_tree: new_solution_tree,
          progress: %{engine.progress |
            total_steps: Planner.plan_cost(new_solution_tree)
          }
        }

        {:ok, updated_engine}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def replan(%Core{solution_tree: nil}, _fail_node_id, _opts) do
    {:error, "No solution tree available for replanning"}
  end

  @doc """
  Validate the current plan.
  """
  @spec validate_plan(t()) :: {:ok, State.t()} | {:error, String.t()}
  def validate_plan(%Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do

    domain_interface = to_planner_interface(engine)
    Planner.validate_plan(domain_interface, engine.initial_state, solution_tree)
  end

  def validate_plan(%Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end

  # Converts AriaEngine definition to planner interface format
  @spec to_planner_interface(t()) :: Planner.domain_interface()
  defp to_planner_interface(%Core{} = engine) do
    %{
      actions: engine.actions,
      task_methods: engine.task_methods,
      unigoal_methods: engine.unigoal_methods,
      multigoal_methods: engine.multigoal_methods
    }
  end
end
