# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Planner do
  @moduledoc """
  Core IPyHOP-style Hierarchical Task Network (HTN) planner.

  This module contains the pure planning logic separated from domain-specific
  functionality. It provides:

  - IPyHOP-style HTN planning with solution trees
  - Reentrant planning from failure points
  - Run-Lazy-Refineahead execution with replanning
  - Goal-task network decomposition
  - Blacklisting and alternative method selection

  This is the core planning engine that can work with any domain definition
  that provides the required actions and methods.
  """

  alias AriaEngine.{Domain, State, Plan}

  # Core planner types
  @type planner_opts :: keyword()
  @type planner_result :: {:ok, Plan.solution_tree()} | {:error, String.t()}
  @type execution_result :: {:ok, State.t()} | {:error, String.t()}
  @type replan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()} | :failure

  # Domain interface types
  @type domain_interface :: %{
    actions: %{atom() => function()},
    task_methods: %{String.t() => [function()]},
    unigoal_methods: %{String.t() => [function()]},
    multigoal_methods: [function()]
  }

  @doc """
  Plan goals using IPyHOP-style HTN planning.

  This is the core planning function that takes a domain interface and
  produces a solution tree for achieving the given goals.

  ## Parameters
  - `domain_interface`: Map containing actions and methods
  - `initial_state`: Starting state for planning
  - `goals`: List of goals to achieve
  - `opts`: Planning options (max_depth, verbose, etc.)

  ## Returns
  - `{:ok, solution_tree}`: Complete solution tree
  - `{:error, reason}`: Planning failure
  """
  @spec plan(domain_interface(), State.t(), [Plan.todo_item()], planner_opts()) :: planner_result()
  def plan(domain_interface, %State{} = initial_state, goals, opts \\ []) do
    set_logger_level_from_opts(opts)
    # Convert domain interface to Domain struct for compatibility with Plan module
    domain = interface_to_domain(domain_interface)

    # Use the existing Plan module for actual planning
    Plan.plan(domain, initial_state, goals, opts)
  end

  @doc """
  Execute a solution tree with Run-Lazy-Refineahead.

  This executes the planned solution with automatic replanning on failures.

  ## Parameters
  - `domain_interface`: Map containing actions and methods
  - `initial_state`: Starting execution state
  - `solution_tree`: Solution tree from planning
  - `opts`: Execution options

  ## Returns
  - `{:ok, final_state}`: Successful execution
  - `{:error, reason}`: Execution failure
  """
  @spec execute(domain_interface(), State.t(), Plan.solution_tree(), planner_opts()) :: execution_result()
  def execute(domain_interface, %State{} = initial_state, solution_tree, opts \\ []) do
    set_logger_level_from_opts(opts)
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)

    # Use the existing Plan module for execution
    Plan.run_lazy_refineahead(domain, initial_state, solution_tree, opts)
  end

  @doc """
  Replan from a failure point in the solution tree.

  ## Parameters
  - `domain_interface`: Map containing actions and methods
  - `current_state`: Current state at failure point
  - `solution_tree`: Existing solution tree with failure
  - `fail_node_id`: ID of the failed node
  - `opts`: Replanning options

  ## Returns
  - `{:ok, new_solution_tree}`: Successfully replanned
  - `{:error, reason}`: Replanning failure
  - `:failure`: No alternatives available
  """
  @spec replan(domain_interface(), State.t(), Plan.solution_tree(), String.t(), planner_opts()) :: replan_result()
  def replan(domain_interface, %State{} = current_state, solution_tree, fail_node_id, opts \\ []) do
    set_logger_level_from_opts(opts)
    # Convert domain interface to Domain struct
    domain = interface_to_domain(domain_interface)

    # Use the existing Plan module for replanning
    Plan.replan(domain, current_state, solution_tree, fail_node_id, opts)
  end

  @doc """
  Validate a plan against the domain and initial state.

  ## Parameters
  - `domain_interface`: Domain interface with actions and methods
  - `initial_state`: Starting state for validation
  - `solution_tree`: Solution tree or plan to validate

  ## Returns
  - `{:ok, final_state}`: Plan is valid, returns final state
  - `{:error, reason}`: Plan validation failed
  """
  @spec validate_plan(domain_interface(), State.t(), Plan.solution_tree()) ::
    {:ok, State.t()} | {:error, String.t()}
  def validate_plan(domain_interface, initial_state, solution_tree) do
    domain = interface_to_domain(domain_interface)
    Plan.validate_plan(domain, initial_state, solution_tree)
  end

  @doc """
  Extract primitive actions from a solution tree.

  ## Parameters
  - `solution_tree`: Solution tree to extract actions from

  ## Returns
  List of primitive action steps
  """
  @spec extract_actions(Plan.solution_tree()) :: [Plan.plan_step()]
  def extract_actions(solution_tree) do
    Plan.get_primitive_actions_dfs(solution_tree)
  end

  @doc """
  Get statistics about a solution tree.

  ## Parameters
  - `solution_tree`: Solution tree to analyze

  ## Returns
  Map with tree statistics
  """
  @spec tree_stats(Plan.solution_tree()) :: map()
  def tree_stats(solution_tree) do
    Plan.tree_stats(solution_tree)
  end

  @doc """
  Calculate the cost (number of primitive actions) of a solution tree.

  ## Parameters
  - `solution_tree`: Solution tree to calculate cost for

  ## Returns
  Number of primitive actions in the tree
  """
  @spec plan_cost(Plan.solution_tree()) :: non_neg_integer()
  def plan_cost(solution_tree) do
    Plan.plan_cost(solution_tree)
  end

  @doc """
  Create a domain interface from an AriaEngine.Domain struct.

  This is a convenience function for converting Domain structs to the
  domain interface format expected by the planner.

  ## Parameters
  - `domain`: Domain struct to convert

  ## Returns
  Domain interface map
  """
  @spec domain_to_interface(Domain.t()) :: domain_interface()
  def domain_to_interface(%Domain{} = domain) do
    %{
      actions: domain.actions,
      task_methods: domain.task_methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: domain.multigoal_methods
    }
  end

  # Private helper functions

  # Convert domain interface back to Domain struct for compatibility with Plan module
  @spec interface_to_domain(domain_interface()) :: Domain.t()
  defp interface_to_domain(interface) do
    %Domain{
      name: "planner_domain",
      actions: Map.get(interface, :actions, %{}),
      task_methods: Map.get(interface, :task_methods, %{}),
      unigoal_methods: Map.get(interface, :unigoal_methods, %{}),
      multigoal_methods: Map.get(interface, :multigoal_methods, [])
    }
  end

  # Set Logger level from opts (internal planner verbosity)
  defp set_logger_level_from_opts(opts) do
    cond do
      Keyword.has_key?(opts, :log_level) ->
        Logger.configure(level: Keyword.get(opts, :log_level))
      Keyword.get(opts, :verbose, false) ->
        Logger.configure(level: :debug)
      true ->
        Logger.configure(level: :info)
    end
  end
end
