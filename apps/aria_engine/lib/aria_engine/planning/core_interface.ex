defmodule AriaEngine.Planning.CoreInterface do
  @moduledoc """
  Provides core planning interfaces for the Aria Engine.
  """

  alias AriaEngine.Planning.Internal
  alias AriaEngine.Core
  alias AriaEngine.Planner
  alias AriaEngine.StateV2
  alias AriaEngine.Pddl.Domain, as: PddlDomain
  alias AriaEngine.Plan

  @type t :: AriaEngine.Planning.HighLevel.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()

  @doc """
  Simple planning interface - finds a plan to achieve the given todos.
  """
  @spec plan(AriaEngine.DomainBehaviour.t(), Core.state(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan(domain, %StateV2{} = state, todos, opts \\[]) do
    # Adapt PDDL domain if necessary
    adapted_domain = case domain do
      %PddlDomain{} -> AriaEngine.Pddl.DomainAdapter.new(domain)
      _ -> domain
    end

    case Plan.plan(adapted_domain, state, todos, opts) do
      {:ok, solution_tree} ->
        {:ok, solution_tree}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Advanced planning interface - returns the full solution tree.
  """
  @spec plan_with_tree(AriaEngine.DomainBehaviour.t(), Core.state(), [todo_item()], keyword()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def plan_with_tree(domain, %StateV2{} = state, todos, opts \\[]) do
    # Adapt PDDL domain if necessary
    adapted_domain = case domain do
      %PddlDomain{} -> AriaEngine.Pddl.DomainAdapter.new(domain)
      _ -> domain
    end
    Plan.plan(adapted_domain, state, todos, opts)
  end

  @doc """
  Executes a plan step by step, returning the final state.
  """
  @spec execute_plan(AriaEngine.DomainBehaviour.t(), Core.state(), [plan_step()]) :: {:ok, Core.state()} | {:error, String.t()}
  def execute_plan(domain, %StateV2{} = initial_state, plan) do
    # Adapt PDDL domain if necessary
    adapted_domain = case domain do
      %PddlDomain{} -> AriaEngine.Pddl.DomainAdapter.new(domain)
      _ -> domain
    end
    Plan.validate_plan(adapted_domain, initial_state, plan)
  end

  @doc """
  Replan from a failure point using AriaEngine.Planner.
  """
  @spec replan(Core.t(), String.t(), keyword()) :: {:ok, Core.t()} | {:error, String.t()}
  def replan(engine, fail_node_id, opts \\[])

  def replan(%Core{solution_tree: solution_tree} = engine, fail_node_id, opts)
      when not is_nil(solution_tree) do

    domain_interface = Internal.to_planner_interface(engine)

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
  @spec validate_plan(Core.t()) :: {:ok, StateV2.t()} | {:error, String.t()}
  def validate_plan(%Core{solution_tree: solution_tree} = engine)
      when not is_nil(solution_tree) do

    domain_interface = Internal.to_planner_interface(engine)
    Planner.validate_plan(domain_interface, engine.initial_state, solution_tree)
  end

  def validate_plan(%Core{solution_tree: nil}) do
    {:error, "No solution tree available for validation"}
  end
end
