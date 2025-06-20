# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies do
  @moduledoc """
  Strategy behavior definitions for hybrid planner dependency encapsulation.
  
  This module defines the behavior contracts for all pluggable strategies used
  by the hybrid planner, implementing the Function as Object pattern with
  dependency injection as outlined in ADR-091.
  
  ## Strategy Types
  
  - **PlanningStrategy**: HTN planning algorithms and decomposition logic
  - **TemporalStrategy**: Temporal constraint management and STN validation
  - **StateStrategy**: State management and manipulation operations
  - **DomainStrategy**: Domain query and metadata operations
  - **LoggingStrategy**: Logging and debugging output management
  - **ExecutionStrategy**: Plan execution and action application
  
  ## Usage
  
  ```elixir
  # Define a custom planning strategy
  defmodule MyHTNStrategy do
    @behaviour HybridPlanner.Strategies.PlanningStrategy
    
    @impl true
    def plan(domain, state, goals, opts) do
      # Custom HTN planning implementation
    end
  end
  
  # Use with HybridCoordinatorV2
coordinator = HybridCoordinatorV2.new(%{
  planning_strategy: MyHTNStrategy,
    temporal_strategy: STNTemporalStrategy,
    # ... other strategies
  })
  ```
  """

  # ==================== STRATEGY VALIDATION ====================

  @doc """
  Validate that a set of strategies are compatible with each other.
  
  This ensures that strategies can work together without conflicts.
  """
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
    
    # Check all required strategies are present
    missing = Enum.filter(required_strategies, &(not Map.has_key?(strategies, &1)))
    
    if length(missing) > 0 do
      {:error, "Missing required strategies: #{inspect(missing)}"}
    else
      :ok
    end
  end

  # ==================== PLANNING STRATEGY ====================

  defmodule PlanningStrategy do
    @moduledoc """
    Strategy behavior for planning algorithms.
    
    Encapsulates HTN planning logic, task decomposition, and solution tree
    construction while remaining agnostic to temporal constraints and execution.
    """

    @type plan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()}
    @type replan_result :: {:ok, Plan.solution_tree()} | {:error, String.t()} | :failure

    @doc """
    Plan goals using the strategy's planning algorithm.
    
    ## Parameters
    - `domain`: Domain definition with actions and methods
    - `state`: Current world state
    - `goals`: List of goals to achieve
    - `opts`: Planning options and configuration
    
    ## Returns
    - `{:ok, solution_tree}`: Successful plan
    - `{:error, reason}`: Planning failure with reason
    """
    @callback plan(Domain.Core.t(), AriaEngine.StateV2.t(), [Plan.todo_item()], keyword()) :: plan_result()

    @doc """
    Replan from a failure point using the strategy's replanning logic.
    
    ## Parameters
    - `domain`: Domain definition
    - `state`: Current world state at failure point
    - `solution_tree`: Original solution tree
    - `fail_node_id`: ID of the node that failed
    - `opts`: Replanning options
    
    ## Returns
    - `{:ok, new_solution_tree}`: Successful replan
    - `{:error, reason}`: Replanning error
    - `:failure`: Cannot replan from this failure point
    """
    @callback replan(Domain.Core.t(), AriaEngine.StateV2.t(), Plan.solution_tree(), String.t(), keyword()) :: replan_result()

    @doc """
    Validate a solution tree against domain and state.
    
    ## Parameters
    - `domain`: Domain definition
    - `state`: Initial state for validation
    - `solution_tree`: Solution tree to validate
    
    ## Returns
    - `{:ok, final_state}`: Valid plan with resulting state
    - `{:error, reason}`: Validation failure
    """
    @callback validate_plan(Domain.Core.t(), AriaEngine.StateV2.t(), Plan.solution_tree()) :: 
      {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}

    @doc """
    Get strategy metadata and capabilities.
    
    ## Returns
    - Map containing strategy information including name, capabilities, limitations
    """
    @callback strategy_info() :: map()
  end

  # ==================== TEMPORAL STRATEGY ====================

  defmodule TemporalStrategy do
    @moduledoc """
    Strategy behavior for temporal reasoning and constraint management.
    
    Encapsulates STN constraint management, temporal validation, and
    time-based reasoning while remaining independent of planning algorithms.
    """

    @type temporal_result :: {:ok, map()} | {:error, String.t()}
    @type constraint_result :: {:ok, boolean()} | {:error, String.t()}

    @doc """
    Add temporal constraints for a set of actions.
    
    ## Parameters
    - `constraints`: Current constraint set
    - `actions`: Actions to add constraints for
    - `opts`: Temporal options including current time
    
    ## Returns
    - `{:ok, updated_constraints}`: Successfully added constraints
    - `{:error, reason}`: Constraint addition failed
    """
    @callback add_temporal_constraints(map(), [Plan.plan_step()], keyword()) :: temporal_result()

    @doc """
    Validate temporal consistency of constraints.
    
    ## Parameters
    - `constraints`: Constraint set to validate
    - `opts`: Validation options
    
    ## Returns
    - `{:ok, true}`: Constraints are consistent
    - `{:ok, false}`: Constraints are inconsistent
    - `{:error, reason}`: Validation error
    """
    @callback validate_temporal_consistency(map(), keyword()) :: constraint_result()

    @doc """
    Update constraints after plan modification.
    
    ## Parameters
    - `constraints`: Current constraint set
    - `modifications`: List of plan modifications
    - `opts`: Update options
    
    ## Returns
    - `{:ok, updated_constraints}`: Successfully updated constraints
    - `{:error, reason}`: Update failed
    """
    @callback update_constraints(map(), [term()], keyword()) :: temporal_result()

    @doc """
    Get temporal schedule from constraints.
    
    ## Parameters
    - `constraints`: Constraint set
    - `opts`: Scheduling options
    
    ## Returns
    - `{:ok, schedule}`: Valid temporal schedule
    - `{:error, reason}`: Cannot create schedule
    """
    @callback get_temporal_schedule(map(), keyword()) :: temporal_result()
  end

  # ==================== STATE STRATEGY ====================

  defmodule StateStrategy do
    @moduledoc """
    Strategy behavior for state management operations.
    
    Encapsulates state representation, querying, updates, and rollback
    operations while remaining independent of planning logic.
    """

    @type state_result :: {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
    @type query_result :: {:ok, term()} | {:error, String.t()}

    @doc """
    Apply an action to a state.
    
    ## Parameters
    - `state`: Current state
    - `action`: Action to apply (atom and arguments)
    - `domain`: Domain for action metadata
    - `opts`: Application options
    
    ## Returns
    - `{:ok, new_state}`: Action applied successfully
    - `{:error, reason}`: Action application failed
    """
    @callback apply_action(AriaEngine.StateV2.t(), {atom(), [term()]}, Domain.Core.t(), keyword()) :: state_result()

    @doc """
    Query state for specific information.
    
    ## Parameters
    - `state`: State to query
    - `query`: Query specification
    - `opts`: Query options
    
    ## Returns
    - `{:ok, result}`: Query successful
    - `{:error, reason}`: Query failed
    """
    @callback query_state(AriaEngine.StateV2.t(), term(), keyword()) :: query_result()

    @doc """
    Create a checkpoint of the current state.
    
    ## Parameters
    - `state`: State to checkpoint
    - `checkpoint_id`: Identifier for the checkpoint
    - `opts`: Checkpoint options
    
    ## Returns
    - `{:ok, checkpoint_state}`: Checkpoint created
    - `{:error, reason}`: Checkpoint creation failed
    """
    @callback create_checkpoint(AriaEngine.StateV2.t(), String.t(), keyword()) :: state_result()

    @doc """
    Rollback to a previous checkpoint.
    
    ## Parameters
    - `state`: Current state
    - `checkpoint_id`: Checkpoint to rollback to
    - `opts`: Rollback options
    
    ## Returns
    - `{:ok, rollback_state}`: Rollback successful
    - `{:error, reason}`: Rollback failed
    """
    @callback rollback_to_checkpoint(AriaEngine.StateV2.t(), String.t(), keyword()) :: state_result()
  end

  # ==================== DOMAIN STRATEGY ====================

  defmodule DomainStrategy do
    @moduledoc """
    Strategy behavior for domain operations and metadata queries.
    
    Encapsulates domain querying, action metadata retrieval, and method
    resolution while remaining independent of state and planning logic.
    """

    @type metadata_result :: {:ok, map()} | {:error, String.t()}
    @type method_result :: {:ok, [term()]} | {:error, String.t()}

    @doc """
    Get action metadata from domain.
    
    ## Parameters
    - `domain`: Domain definition
    - `action_name`: Name of the action
    - `opts`: Metadata query options
    
    ## Returns
    - `{:ok, metadata}`: Action metadata retrieved
    - `{:error, reason}`: Metadata retrieval failed
    """
    @callback get_action_metadata(Domain.Core.t(), atom(), keyword()) :: metadata_result()

    @doc """
    Get available methods for a task.
    
    ## Parameters
    - `domain`: Domain definition
    - `task_name`: Name of the task
    - `opts`: Method query options
    
    ## Returns
    - `{:ok, methods}`: List of available methods
    - `{:error, reason}`: Method query failed
    """
    @callback get_task_methods(Domain.Core.t(), String.t(), keyword()) :: method_result()

    @doc """
    Get available methods for a goal.
    
    ## Parameters
    - `domain`: Domain definition
    - `goal_spec`: Goal specification
    - `opts`: Method query options
    
    ## Returns
    - `{:ok, methods}`: List of available methods
    - `{:error, reason}`: Method query failed
    """
    @callback get_goal_methods(Domain.Core.t(), term(), keyword()) :: method_result()

    @doc """
    Validate domain consistency.
    
    ## Parameters
    - `domain`: Domain to validate
    - `opts`: Validation options
    
    ## Returns
    - `{:ok, true}`: Domain is valid
    - `{:error, reason}`: Domain validation failed
    """
    @callback validate_domain(Domain.Core.t(), keyword()) :: {:ok, true} | {:error, String.t()}
  end

  # ==================== LOGGING STRATEGY ====================

  defmodule LoggingStrategy do
    @moduledoc """
    Strategy behavior for logging and debug output.
    
    Encapsulates all logging, debug output, and progress reporting
    while allowing for different logging backends and configurations.
    """

    @type log_level :: :debug | :info | :warning | :error
    @type log_result :: :ok

    @doc """
    Log a message at the specified level.
    
    ## Parameters
    - `level`: Log level (:debug, :info, :warning, :error)
    - `message`: Message to log
    - `metadata`: Additional logging metadata
    - `opts`: Logging options
    
    ## Returns
    - `:ok`: Message logged successfully
    """
    @callback log(log_level(), String.t(), map(), keyword()) :: log_result()

    @doc """
    Log planning progress information.
    
    ## Parameters
    - `phase`: Planning phase (e.g., "decomposition", "validation")
    - `progress`: Progress information
    - `opts`: Progress logging options
    
    ## Returns
    - `:ok`: Progress logged successfully
    """
    @callback log_progress(String.t(), map(), keyword()) :: log_result()

    @doc """
    Log error with context information.
    
    ## Parameters
    - `error`: Error message or exception
    - `context`: Context information
    - `opts`: Error logging options
    
    ## Returns
    - `:ok`: Error logged successfully
    """
    @callback log_error(String.t() | Exception.t(), map(), keyword()) :: log_result()

    @doc """
    Configure logging behavior.
    
    ## Parameters
    - `config`: Logging configuration
    - `opts`: Configuration options
    
    ## Returns
    - `:ok`: Configuration applied successfully
    """
    @callback configure(map(), keyword()) :: log_result()
  end

  # ==================== EXECUTION STRATEGY ====================

  defmodule ExecutionStrategy do
    @moduledoc """
    Strategy behavior for plan execution models.
    
    Encapsulates different execution approaches (lazy refinement, eager
    execution, step-by-step) while coordinating with other strategies.
    """

    @type execution_result :: {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}
    @type step_result :: {:ok, AriaEngine.StateV2.t()} | {:retry, AriaEngine.StateV2.t()} | {:error, String.t()}

    @doc """
    Execute a complete solution tree.
    
    ## Parameters
    - `solution_tree`: Solution tree to execute
    - `initial_state`: Starting state
    - `strategies`: Map of other strategies to coordinate with
    - `opts`: Execution options
    
    ## Returns
    - `{:ok, final_state}`: Execution completed successfully
    - `{:error, reason}`: Execution failed
    """
    @callback execute_plan(Plan.solution_tree(), AriaEngine.StateV2.t(), map(), keyword()) :: execution_result()

    @doc """
    Execute a single step with potential replanning.
    
    ## Parameters
    - `step`: Step to execute
    - `current_state`: Current execution state
    - `strategies`: Map of other strategies
    - `opts`: Step execution options
    
    ## Returns
    - `{:ok, new_state}`: Step executed successfully
    - `{:retry, state}`: Step should be retried
    - `{:error, reason}`: Step execution failed
    """
    @callback execute_step(term(), AriaEngine.StateV2.t(), map(), keyword()) :: step_result()

    @doc """
    Handle execution failure with recovery strategies.
    
    ## Parameters
    - `failure`: Failure information
    - `current_state`: State at failure point
    - `strategies`: Map of other strategies
    - `opts`: Recovery options
    
    ## Returns
    - `{:ok, recovery_state}`: Recovery successful
    - `{:error, reason}`: Recovery failed
    """
    @callback handle_execution_failure(term(), AriaEngine.StateV2.t(), map(), keyword()) :: execution_result()
  end

  # ==================== STRATEGY COMPOSITION ====================

  defmodule Utils do
    @moduledoc """
    Utilities for strategy composition, validation, and management.
    """

    @doc """
    Validate that a strategy map contains all required strategies.
    
    ## Parameters
    - `strategies`: Map of strategy implementations
    
    ## Returns
    - `:ok`: All required strategies present
    - `{:error, missing}`: List of missing strategies
    """
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

    @doc """
    Create a default strategy map with standard implementations.
    
    ## Returns
    - Map with default strategy implementations
    """
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

    @doc """
    Merge strategy overrides with defaults.
    
    ## Parameters
    - `overrides`: Map of strategy overrides
    
    ## Returns
    - Complete strategy map with overrides applied
    """
    @spec merge_strategy_overrides(map()) :: map()
    def merge_strategy_overrides(overrides \\ %{}) do
      Map.merge(default_strategy_map(), overrides)
    end
  end
end
