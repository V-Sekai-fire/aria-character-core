defmodule HybridPlanner.Strategies.Default.LazyExecutionStrategy do
  @moduledoc "Default lazy execution strategy implementation wrapping existing execution logic.\n\nThis strategy encapsulates the lazy refinement execution model from Plan.Core\nwhile providing the clean strategy interface defined in ADR-091.\n"
  @behaviour HybridPlanner.Strategies.ExecutionStrategy
  require Logger
  @impl true
  def execute_plan(solution_tree, %AriaEngine.State{} = initial_state, _strategies, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      action_count = AriaEngine.Plan.Utils.plan_cost(solution_tree)

      Logger.debug(
        "LazyExecutionStrategy: Starting execution of plan with #{action_count} actions"
      )
    end

    try do
      domain = Map.get(opts, :domain)

      case domain do
        nil ->
          {:error, "Domain required for execution but not provided in options"}

        %Domain.Core{} = domain ->
          Logger.warning(
            "LazyExecutionStrategy: Plan.Core.run_lazy_refineahead/4 not yet implemented"
          )

          case Plan.Core.plan(domain, initial_state, opts) do
            {:ok, final_state} ->
              if verbose > 1 do
                Logger.debug("LazyExecutionStrategy: Execution completed successfully")
              end

              {:ok, final_state}

            {:error, reason} ->
              if verbose > 0 do
                Logger.warning("LazyExecutionStrategy: Execution failed - #{reason}")
              end

              {:error, reason}
          end

        _ ->
          {:error, "Invalid domain type provided for execution"}
      end
    rescue
      e ->
        error_msg = "LazyExecutionStrategy execution error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def execute_step(step, %AriaEngine.State{} = current_state, strategies, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 2 do
      Logger.debug("LazyExecutionStrategy: Executing step #{inspect(step)}")
    end

    try do
      state_strategy = Map.get(strategies, :state_strategy)
      domain = Map.get(opts, :domain)

      case {state_strategy, domain} do
        {nil, _} ->
          {:error, "State strategy required for step execution"}

        {_, nil} ->
          {:error, "Domain required for step execution"}

        {state_strategy, domain} ->
          case step do
            {action_name, args} when is_atom(action_name) ->
              case state_strategy.apply_action(current_state, {action_name, args}, domain, opts) do
                {:ok, new_state} ->
                  if verbose > 2 do
                    Logger.debug("LazyExecutionStrategy: Step executed successfully")
                  end

                  {:ok, new_state}

                {:error, reason} ->
                  if verbose > 1 do
                    Logger.warning("LazyExecutionStrategy: Step execution failed - #{reason}")
                  end

                  {:error, reason}
              end

            _ ->
              {:error, "Unknown step format: #{inspect(step)}"}
          end
      end
    rescue
      e ->
        error_msg = "LazyExecutionStrategy step execution error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def handle_execution_failure(
        failure,
        %AriaEngine.State{} = current_state,
        strategies,
        opts \\ []
      ) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("LazyExecutionStrategy: Handling execution failure: #{inspect(failure)}")
    end

    try do
      planning_strategy = Map.get(strategies, :planning_strategy)
      logging_strategy = Map.get(strategies, :logging_strategy)
      domain = Map.get(opts, :domain)

      case {planning_strategy, domain} do
        {nil, _} ->
          {:error, "Planning strategy required for failure recovery"}

        {_, nil} ->
          {:error, "Domain required for failure recovery"}

        {_planning_strategy, _domain} ->
          if logging_strategy do
            logging_strategy.log_error(
              failure,
              %{phase: "execution", state: "recovery_attempt"},
              opts
            )
          end

          case failure do
            {:action_failed, action_name, reason} ->
              if verbose > 0 do
                Logger.warning("LazyExecutionStrategy: Action #{action_name} failed - #{reason}")
              end

              {:ok, current_state}

            {:temporal_violation, _constraint, reason} ->
              if verbose > 0 do
                Logger.warning("LazyExecutionStrategy: Temporal violation - #{reason}")
              end

              {:ok, current_state}

            _ ->
              if verbose > 0 do
                Logger.warning(
                  "LazyExecutionStrategy: Unknown failure type - #{inspect(failure)}"
                )
              end

              {:error, "Cannot recover from failure: #{inspect(failure)}"}
          end
      end
    rescue
      e ->
        error_msg = "LazyExecutionStrategy failure handling error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @doc "Get strategy metadata and capabilities.\n"
  def strategy_info do
    %{
      name: "Lazy Execution Strategy",
      version: "1.0.0",
      description: "Default lazy refinement execution strategy",
      capabilities: [
        :lazy_refinement,
        :step_by_step_execution,
        :basic_failure_recovery,
        :action_validation
      ],
      limitations: [:no_parallel_execution, :simple_recovery_model, :no_rollback_support],
      underlying_implementation: "Plan.Core.run_lazy_refineahead"
    }
  end

  @doc "Check if this strategy can handle specific execution features.\n"
  def supports?(feature) when is_atom(feature) do
    capabilities = strategy_info()[:capabilities]
    feature in capabilities
  end

  @doc "Get performance characteristics of this strategy.\n"
  def performance_profile do
    %{
      execution_model: :lazy_refinement,
      memory_usage: :low,
      scalability: :good,
      fault_tolerance: :basic,
      parallelization: :none
    }
  end

  @doc "Create execution context for tracking execution state.\n\nThis can be used to maintain execution-specific state across\nmultiple step executions.\n"
  def create_execution_context(initial_state, opts \\ []) do
    %{
      initial_state: initial_state,
      current_state: initial_state,
      executed_steps: [],
      step_count: 0,
      start_time: System.system_time(:millisecond),
      last_step_time: System.system_time(:millisecond),
      opts: opts
    }
  end

  @doc "Update execution context after a step.\n"
  def update_execution_context(context, step, new_state) do
    %{
      context
      | current_state: new_state,
        executed_steps: [step | context.executed_steps],
        step_count: context.step_count + 1,
        last_step_time: System.system_time(:millisecond)
    }
  end

  @doc "Get execution statistics from context.\n"
  def get_execution_stats(context) do
    current_time = System.system_time(:millisecond)
    total_time = current_time - context.start_time

    %{
      total_steps: context.step_count,
      total_time_ms: total_time,
      average_step_time_ms:
        if context.step_count > 0 do
          total_time / context.step_count
        else
          0
        end,
      last_step_time: context.last_step_time,
      execution_rate:
        if total_time > 0 do
          context.step_count / (total_time / 1000)
        else
          0
        end
    }
  end
end