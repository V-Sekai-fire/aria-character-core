# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies do
  @doc "Validate that a set of strategies are compatible with each other.\n\nThis ensures that strategies can work together without conflicts.\n"
  @spec validate_strategy_compatibility(map()) :: :ok | {:error, String.t()}
  def validate_strategy_compatibility(strategies) when is_map(strategies) do
    required_strategies = [
      :planning_strategy,
      :temporal_strategy,
      :state_strategy,
      :domain_strategy,
      :logging_strategy,
      :execution_strategy
    ]

    missing = Enum.filter(required_strategies, &(not Map.has_key?(strategies, &1)))

    if length(missing) > 0 do
      {:error, "Missing required strategies: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defmodule PlanningStrategy do
    @moduledoc "Strategy behavior for planning algorithms.\n\nEncapsulates HTN planning logic, task decomposition, and solution tree\nconstruction while remaining agnostic to temporal constraints and execution.\n"
    @type plan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()}
    @type replan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()} | :failure
    @doc "Plan goals using the strategy's planning algorithm.\n\n## Parameters\n- `domain`: Domain definition with actions and methods\n- `state`: Current world state\n- `goals`: List of goals to achieve\n- `opts`: Planning options and configuration\n\n## Returns\n- `{:ok, solution_tree}`: Successful plan\n- `{:error, reason}`: Planning failure with reason\n"
    @callback plan(Domain.Core.t(), AriaEngine.State.t(), [Plan.todo_item()], keyword()) ::
                plan_result()
    @doc "Replan from a failure point using the strategy's replanning logic.\n\n## Parameters\n- `domain`: Domain definition\n- `state`: Current world state at failure point\n- `solution_tree`: Original solution tree\n- `fail_node_id`: ID of the node that failed\n- `opts`: Replanning options\n\n## Returns\n- `{:ok, new_solution_tree}`: Successful replan\n- `{:error, reason}`: Replanning error\n- `:failure`: Cannot replan from this failure point\n"
    @callback replan(
                Domain.Core.t(),
                AriaEngine.State.t(),
                Plan.solution_tree(),
                String.t(),
                keyword()
              ) :: replan_result()
    @doc "Validate a solution tree against domain and state.\n\n## Parameters\n- `domain`: Domain definition\n- `state`: Initial state for validation\n- `solution_tree`: Solution tree to validate\n\n## Returns\n- `{:ok, final_state}`: Valid plan with resulting state\n- `{:error, reason}`: Validation failure\n"
    @callback validate_plan(Domain.Core.t(), AriaEngine.State.t(), Plan.solution_tree()) ::
                {:ok, AriaEngine.State.t()} | {:error, String.t()}
    @doc "Get strategy metadata and capabilities.\n\n## Returns\n- Map containing strategy information including name, capabilities, limitations\n"
    @callback strategy_info() :: map()
  end

  defmodule TemporalStrategy do
    @moduledoc "Strategy behavior for temporal reasoning and constraint management.\n\nEncapsulates STN constraint management, temporal validation, and\ntime-based reasoning while remaining independent of planning algorithms.\n"
    @type temporal_result :: {:ok, map()} | {:error, String.t()}
    @type constraint_result :: {:ok, boolean()} | {:error, String.t()}
    @doc "Add temporal constraints for a set of actions.\n\n## Parameters\n- `constraints`: Current constraint set\n- `actions`: Actions to add constraints for\n- `opts`: Temporal options including current time\n\n## Returns\n- `{:ok, updated_constraints}`: Successfully added constraints\n- `{:error, reason}`: Constraint addition failed\n"
    @callback add_temporal_constraints(map(), [Plan.plan_step()], keyword()) :: temporal_result()
    @doc "Validate temporal consistency of constraints.\n\n## Parameters\n- `constraints`: Constraint set to validate\n- `opts`: Validation options\n\n## Returns\n- `{:ok, true}`: Constraints are consistent\n- `{:ok, false}`: Constraints are inconsistent\n- `{:error, reason}`: Validation error\n"
    @callback validate_temporal_consistency(map(), keyword()) :: constraint_result()
    @doc "Update constraints after plan modification.\n\n## Parameters\n- `constraints`: Current constraint set\n- `modifications`: List of plan modifications\n- `opts`: Update options\n\n## Returns\n- `{:ok, updated_constraints}`: Successfully updated constraints\n- `{:error, reason}`: Update failed\n"
    @callback update_constraints(map(), [term()], keyword()) :: temporal_result()
    @doc "Get temporal schedule from constraints.\n\n## Parameters\n- `constraints`: Constraint set\n- `opts`: Scheduling options\n\n## Returns\n- `{:ok, schedule}`: Valid temporal schedule\n- `{:error, reason}`: Cannot create schedule\n"
    @callback get_temporal_schedule(map(), keyword()) :: temporal_result()
  end

  defmodule StateStrategy do
    @moduledoc "Strategy behavior for state management operations.\n\nEncapsulates state representation, querying, updates, and rollback\noperations while remaining independent of planning logic.\n"
    @type state_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
    @type query_result :: {:ok, term()} | {:error, String.t()}
    @doc "Apply an action to a state.\n\n## Parameters\n- `state`: Current state\n- `action`: Action to apply (atom and arguments)\n- `domain`: Domain for action metadata\n- `opts`: Application options\n\n## Returns\n- `{:ok, new_state}`: Action applied successfully\n- `{:error, reason}`: Action application failed\n"
    @callback apply_action(AriaEngine.State.t(), {atom(), [term()]}, Domain.Core.t(), keyword()) ::
                state_result()
    @doc "Query state for specific information.\n\n## Parameters\n- `state`: State to query\n- `query`: Query specification\n- `opts`: Query options\n\n## Returns\n- `{:ok, result}`: Query successful\n- `{:error, reason}`: Query failed\n"
    @callback query_state(AriaEngine.State.t(), term(), keyword()) :: query_result()
    @doc "Create a checkpoint of the current state.\n\n## Parameters\n- `state`: State to checkpoint\n- `checkpoint_id`: Identifier for the checkpoint\n- `opts`: Checkpoint options\n\n## Returns\n- `{:ok, checkpoint_state}`: Checkpoint created\n- `{:error, reason}`: Checkpoint creation failed\n"
    @callback create_checkpoint(AriaEngine.State.t(), String.t(), keyword()) :: state_result()
    @doc "Rollback to a previous checkpoint.\n\n## Parameters\n- `state`: Current state\n- `checkpoint_id`: Checkpoint to rollback to\n- `opts`: Rollback options\n\n## Returns\n- `{:ok, rollback_state}`: Rollback successful\n- `{:error, reason}`: Rollback failed\n"
    @callback rollback_to_checkpoint(AriaEngine.State.t(), String.t(), keyword()) ::
                state_result()
  end

  defmodule DomainStrategy do
    @moduledoc "Strategy behavior for domain operations and metadata queries.\n\nEncapsulates domain querying, action metadata retrieval, and method\nresolution while remaining independent of state and planning logic.\n"
    @type metadata_result :: {:ok, map()} | {:error, String.t()}
    @type method_result :: {:ok, [term()]} | {:error, String.t()}
    @doc "Get action metadata from domain.\n\n## Parameters\n- `domain`: Domain definition\n- `action_name`: Name of the action\n- `opts`: Metadata query options\n\n## Returns\n- `{:ok, metadata}`: Action metadata retrieved\n- `{:error, reason}`: Metadata retrieval failed\n"
    @callback get_action_metadata(Domain.Core.t(), atom(), keyword()) :: metadata_result()
    @doc "Get available methods for a task.\n\n## Parameters\n- `domain`: Domain definition\n- `task_name`: Name of the task\n- `opts`: Method query options\n\n## Returns\n- `{:ok, methods}`: List of available methods\n- `{:error, reason}`: Method query failed\n"
    @callback get_task_methods(Domain.Core.t(), String.t(), keyword()) :: method_result()
    @doc "Get available methods for a goal.\n\n## Parameters\n- `domain`: Domain definition\n- `goal_spec`: Goal specification\n- `opts`: Method query options\n\n## Returns\n- `{:ok, methods}`: List of available methods\n- `{:error, reason}`: Method query failed\n"
    @callback get_goal_methods(Domain.Core.t(), term(), keyword()) :: method_result()
    @doc "Validate domain consistency.\n\n## Parameters\n- `domain`: Domain to validate\n- `opts`: Validation options\n\n## Returns\n- `{:ok, true}`: Domain is valid\n- `{:error, reason}`: Domain validation failed\n"
    @callback validate_domain(Domain.Core.t(), keyword()) :: {:ok, true} | {:error, String.t()}
  end

  defmodule LoggingStrategy do
    @moduledoc "Strategy behavior for logging and debug output.\n\nEncapsulates all logging, debug output, and progress reporting\nwhile allowing for different logging backends and configurations.\n"
    @type log_level :: :debug | :info | :warning | :error
    @type log_result :: :ok
    @doc "Log a message at the specified level.\n\n## Parameters\n- `level`: Log level (:debug, :info, :warning, :error)\n- `message`: Message to log\n- `metadata`: Additional logging metadata\n- `opts`: Logging options\n\n## Returns\n- `:ok`: Message logged successfully\n"
    @callback log(log_level(), String.t(), map(), keyword()) :: log_result()
    @doc "Log planning progress information.\n\n## Parameters\n- `phase`: Planning phase (e.g., \"decomposition\", \"validation\")\n- `progress`: Progress information\n- `opts`: Progress logging options\n\n## Returns\n- `:ok`: Progress logged successfully\n"
    @callback log_progress(String.t(), map(), keyword()) :: log_result()
    @doc "Log error with context information.\n\n## Parameters\n- `error`: Error message or exception\n- `context`: Context information\n- `opts`: Error logging options\n\n## Returns\n- `:ok`: Error logged successfully\n"
    @callback log_error(String.t() | Exception.t(), map(), keyword()) :: log_result()
    @doc "Configure logging behavior.\n\n## Parameters\n- `config`: Logging configuration\n- `opts`: Configuration options\n\n## Returns\n- `:ok`: Configuration applied successfully\n"
    @callback configure(map(), keyword()) :: log_result()
  end

  defmodule ExecutionStrategy do
    @moduledoc "Strategy behavior for plan execution models.\n\nEncapsulates different execution approaches (lazy refinement, eager\nexecution, step-by-step) while coordinating with other strategies.\n"
    @type execution_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
    @type step_result ::
            {:ok, AriaEngine.State.t()} | {:retry, AriaEngine.State.t()} | {:error, String.t()}
    @doc "Execute a complete solution tree.\n\n## Parameters\n- `solution_tree`: Solution tree to execute\n- `initial_state`: Starting state\n- `strategies`: Map of other strategies to coordinate with\n- `opts`: Execution options\n\n## Returns\n- `{:ok, final_state}`: Execution completed successfully\n- `{:error, reason}`: Execution failed\n"
    @callback execute_plan(Plan.solution_tree(), AriaEngine.State.t(), map(), keyword()) ::
                execution_result()
    @doc "Execute a single step with potential replanning.\n\n## Parameters\n- `step`: Step to execute\n- `current_state`: Current execution state\n- `strategies`: Map of other strategies\n- `opts`: Step execution options\n\n## Returns\n- `{:ok, new_state}`: Step executed successfully\n- `{:retry, state}`: Step should be retried\n- `{:error, reason}`: Step execution failed\n"
    @callback execute_step(term(), AriaEngine.State.t(), map(), keyword()) :: step_result()
    @doc "Handle execution failure with recovery strategies.\n\n## Parameters\n- `failure`: Failure information\n- `current_state`: State at failure point\n- `strategies`: Map of other strategies\n- `opts`: Recovery options\n\n## Returns\n- `{:ok, recovery_state}`: Recovery successful\n- `{:error, reason}`: Recovery failed\n"
    @callback handle_execution_failure(term(), AriaEngine.State.t(), map(), keyword()) ::
                execution_result()
  end

  defmodule Utils do
    @moduledoc "Utilities for strategy composition, validation, and management.\n"
    @doc "Validate that a strategy map contains all required strategies.\n\n## Parameters\n- `strategies`: Map of strategy implementations\n\n## Returns\n- `:ok`: All required strategies present\n- `{:error, missing}`: List of missing strategies\n"
    @spec validate_strategy_map(map()) :: :ok | {:error, [atom()]}
    def validate_strategy_map(strategies) do
      required_strategies = [
        :planning_strategy,
        :temporal_strategy,
        :state_strategy,
        :domain_strategy,
        :logging_strategy,
        :execution_strategy
      ]

      missing = Enum.reject(required_strategies, &Map.has_key?(strategies, &1))

      case missing do
        [] -> :ok
        missing_list -> {:error, missing_list}
      end
    end

    @doc "Create a default strategy map with standard implementations.\n\n## Returns\n- Map with default strategy implementations\n"
    @spec default_strategy_map() :: map()
    def default_strategy_map do
      %{
        planning_strategy: HybridPlanner.Strategies.Default.HTNPlanningStrategy,
        temporal_strategy: HybridPlanner.Strategies.Default.STNTemporalStrategy,
        state_strategy: HybridPlanner.Strategies.Default.StateV2Strategy,
        domain_strategy: HybridPlanner.Strategies.Default.DomainStrategy,
        logging_strategy: HybridPlanner.Strategies.Default.LoggerStrategy,
        execution_strategy: HybridPlanner.Strategies.Default.LazyExecutionStrategy
      }
    end

    @doc "Merge strategy overrides with defaults.\n\n## Parameters\n- `overrides`: Map of strategy overrides\n\n## Returns\n- Complete strategy map with overrides applied\n"
    @spec merge_strategy_overrides(map()) :: map()
    def merge_strategy_overrides(overrides \\ %{}) do
      Map.merge(default_strategy_map(), overrides)
    end
  end
end