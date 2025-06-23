# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.HTNPlanningFilter do
  @moduledoc """
  Membrane filter that performs HTN (Hierarchical Task Network) planning.

  This filter is the first stage of the decomposed hybrid coordinator pipeline.
  It takes planning requests and produces solution trees using HTN planning
  strategies, then passes the intermediate result to the next stage.

  Pipeline flow: HTNPlanning → TemporalConstraint → TemporalValidation → MiniZinc → Response
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W032HTNP"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.StrategyRequest

  # Define intermediate format for HTN planning results
  defmodule HTNPlanningResult do
    @moduledoc "Intermediate result format for HTN planning stage"

    defstruct [
      :request_id,
      :solution_tree,
      :planning_metadata,
      :original_request,
      :domain,
      :state,
      :goals,
      :options
    ]

    @type t :: %__MODULE__{
      request_id: String.t(),
      solution_tree: map(),
      planning_metadata: map(),
      original_request: StrategyRequest.t(),
      domain: term(),
      state: map(),
      goals: list(),
      options: keyword()
    }
  end

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: StrategyRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: HTNPlanningResult},
    flow_control: :auto
  )

  def_options(
    planning_strategy: [
      spec: module(),
      default: nil,
      description: "HTN planning strategy module to use"
    ],
    logging_strategy: [
      spec: module(),
      default: nil,
      description: "Logging strategy module to use"
    ],
    max_planning_time_ms: [
      spec: pos_integer(),
      default: 30_000,
      description: "Maximum time allowed for HTN planning"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing HTN Planning Filter")
    Logger.info("🔧 Planning strategy: #{inspect(opts.planning_strategy)}")
    Logger.info("🔧 Max planning time: #{opts.max_planning_time_ms}ms")

    state = %{
      planning_strategy: opts.planning_strategy || get_default_planning_strategy(),
      logging_strategy: opts.logging_strategy || get_default_logging_strategy(),
      max_planning_time_ms: opts.max_planning_time_ms,
      planning_stats: %{
        total_requests: 0,
        successful_plans: 0,
        failed_plans: 0,
        average_planning_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    strategy_request = buffer.payload

    # Only process requests for hybrid_coordinator strategy
    if strategy_request.strategy == :hybrid_coordinator do
      Logger.info("🔧 HTN Planning executing request: #{strategy_request.request_id}")

      start_time = System.monotonic_time(:millisecond)

      # Send notification about planning start
      send_notification({:htn_planning_started, strategy_request.request_id})

      try do
        # Execute HTN planning with timeout
        result = execute_htn_planning_with_timeout(strategy_request, state)

        end_time = System.monotonic_time(:millisecond)
        planning_time_ms = end_time - start_time

        case result do
          {:ok, solution_tree} ->
            Logger.info("✅ HTN Planning succeeded for request: #{strategy_request.request_id}")

            # Create HTN planning result
            htn_result = %HTNPlanningResult{
              request_id: strategy_request.request_id,
              solution_tree: solution_tree,
              planning_metadata: %{
                planning_time_ms: planning_time_ms,
                solution_tree_size: count_solution_tree_nodes(solution_tree),
                strategy_used: :htn_planning,
                completed_at: DateTime.utc_now()
              },
              original_request: strategy_request,
              domain: strategy_request.planning_params.domain,
              state: strategy_request.planning_params.state,
              goals: strategy_request.planning_params.goals,
              options: strategy_request.planning_params.options
            }

            # Update statistics
            updated_stats = update_planning_stats(state.planning_stats, :success, planning_time_ms)
            new_state = %{state | planning_stats: updated_stats}

            # Send notification about completion
            send_notification({:htn_planning_completed, strategy_request.request_id, :success})

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: htn_result,
              metadata: %{
                stage: :htn_planning,
                planning_time_ms: planning_time_ms,
                request_id: strategy_request.request_id,
                success: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ HTN Planning failed for request: #{strategy_request.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Update statistics
            updated_stats = update_planning_stats(state.planning_stats, :failure, planning_time_ms)
            new_state = %{state | planning_stats: updated_stats}

            # Send notification about failure
            send_notification({:htn_planning_completed, strategy_request.request_id, {:error, reason}})

            # Create error result (still pass through pipeline for error handling)
            error_result = %HTNPlanningResult{
              request_id: strategy_request.request_id,
              solution_tree: nil,
              planning_metadata: %{
                planning_time_ms: planning_time_ms,
                error_reason: reason,
                strategy_used: :htn_planning,
                failed_at: DateTime.utc_now()
              },
              original_request: strategy_request,
              domain: strategy_request.planning_params.domain,
              state: strategy_request.planning_params.state,
              goals: strategy_request.planning_params.goals,
              options: strategy_request.planning_params.options
            }

            output_buffer = %Membrane.Buffer{
              payload: error_result,
              metadata: %{
                stage: :htn_planning,
                planning_time_ms: planning_time_ms,
                request_id: strategy_request.request_id,
                success: false,
                error_reason: reason
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:timeout} ->
            Logger.warn("⏰ HTN Planning timeout for request: #{strategy_request.request_id}")

            # Update statistics
            updated_stats = update_planning_stats(state.planning_stats, :timeout, planning_time_ms)
            new_state = %{state | planning_stats: updated_stats}

            # Send notification about timeout
            send_notification({:htn_planning_completed, strategy_request.request_id, :timeout})

            # Create timeout result
            timeout_result = %HTNPlanningResult{
              request_id: strategy_request.request_id,
              solution_tree: nil,
              planning_metadata: %{
                planning_time_ms: planning_time_ms,
                timeout_reason: "HTN planning exceeded maximum time limit",
                strategy_used: :htn_planning,
                timeout_at: DateTime.utc_now()
              },
              original_request: strategy_request,
              domain: strategy_request.planning_params.domain,
              state: strategy_request.planning_params.state,
              goals: strategy_request.planning_params.goals,
              options: strategy_request.planning_params.options
            }

            output_buffer = %Membrane.Buffer{
              payload: timeout_result,
              metadata: %{
                stage: :htn_planning,
                planning_time_ms: planning_time_ms,
                request_id: strategy_request.request_id,
                success: false,
                timeout: true
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end

      rescue
        error ->
          end_time = System.monotonic_time(:millisecond)
          planning_time_ms = end_time - start_time

          Logger.error("❌ HTN Planning exception for request: #{strategy_request.request_id}")
          Logger.error("❌ Exception: #{inspect(error)}")

          # Update statistics
          updated_stats = update_planning_stats(state.planning_stats, :exception, planning_time_ms)
          new_state = %{state | planning_stats: updated_stats}

          # Send notification about exception
          send_notification({:htn_planning_completed, strategy_request.request_id, {:exception, error}})

          # Create exception result
          exception_result = %HTNPlanningResult{
            request_id: strategy_request.request_id,
            solution_tree: nil,
            planning_metadata: %{
              planning_time_ms: planning_time_ms,
              exception: Exception.message(error),
              strategy_used: :htn_planning,
              failed_at: DateTime.utc_now()
            },
            original_request: strategy_request,
            domain: strategy_request.planning_params.domain,
            state: strategy_request.planning_params.state,
            goals: strategy_request.planning_params.goals,
            options: strategy_request.planning_params.options
          }

          output_buffer = %Membrane.Buffer{
            payload: exception_result,
            metadata: %{
              stage: :htn_planning,
              planning_time_ms: planning_time_ms,
              request_id: strategy_request.request_id,
              success: false,
              exception: Exception.message(error)
            }
          }

          {[buffer: {:output, output_buffer}], new_state}
      end
    else
      # Pass through requests for other strategies
      Logger.debug("🔄 Passing through request for strategy: #{strategy_request.strategy}")
      {[buffer: {:output, buffer}], state}
    end
  end

  # Private functions

  defp execute_htn_planning_with_timeout(strategy_request, state) do
    planning_params = strategy_request.planning_params
    timeout_ms = min(strategy_request.timeout_ms, state.max_planning_time_ms)

    # Create task for HTN planning execution
    task = Task.async(fn ->
      execute_htn_planning(planning_params, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp execute_htn_planning(planning_params, state) do
    # Extract planning parameters
    domain = planning_params.domain
    state_data = planning_params.state
    goals = planning_params.goals
    options = planning_params.options

    # Log start using logging strategy
    state.logging_strategy.log_progress(
      "htn_planning",
      %{
        status: "started",
        goals: length(goals),
        domain: if(domain, do: domain.name, else: "unknown")
      },
      options
    )

    # Execute HTN planning using planning strategy
    case state.planning_strategy.plan(domain, state_data, goals, options) do
      {:ok, solution_tree} ->
        state.logging_strategy.log_progress(
          "htn_planning",
          %{
            status: "completed_successfully",
            solution_tree_size: count_solution_tree_nodes(solution_tree)
          },
          options
        )

        {:ok, solution_tree}

      {:error, reason} ->
        state.logging_strategy.log_error(
          reason,
          %{phase: "htn_planning"},
          options
        )

        {:error, reason}

      other ->
        error_msg = "Unexpected result from HTN planning strategy: #{inspect(other)}"
        state.logging_strategy.log_error(
          error_msg,
          %{phase: "htn_planning"},
          options
        )

        {:error, error_msg}
    end
  end

  defp count_solution_tree_nodes(solution_tree) do
    case solution_tree do
      %{children: children} when is_list(children) ->
        1 + Enum.sum(Enum.map(children, &count_solution_tree_nodes/1))

      _ ->
        1
    end
  end

  defp update_planning_stats(stats, result_type, planning_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result_type do
      :success ->
        %{stats |
          successful_plans: stats.successful_plans + 1,
          total_requests: new_total
        }

      _ ->
        %{stats |
          failed_plans: stats.failed_plans + 1,
          total_requests: new_total
        }
    end

    # Update average planning time
    current_avg = stats.average_planning_time_ms
    new_avg = ((current_avg * (new_total - 1)) + planning_time_ms) / new_total

    %{updated_stats | average_planning_time_ms: new_avg}
  end

  defp get_default_planning_strategy() do
    # Return a default HTN planning strategy
    # This would be configured based on available strategies
    AriaEngine.Planning.LazyExecution
  end

  defp get_default_logging_strategy() do
    # Return a default logging strategy
    # This could be a simple logger wrapper
    AriaEngine.Membrane.Planning.DefaultLoggingStrategy
  end

  defp send_notification(notification) do
    # Send notification to parent bin
    send(self(), {:child_notification, notification})
  end
end
