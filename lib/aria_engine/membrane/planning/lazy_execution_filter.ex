# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.LazyExecutionFilter do
  @moduledoc """
  Membrane filter that executes lazy execution planning for simple problems.

  This filter handles straightforward planning problems using the lazy execution
  strategy. Integrates with the existing LazyExecution infrastructure while providing
  membrane-compatible interfaces and comprehensive error handling.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033LAZY"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.StrategyRequest
  alias AriaEngine.Membrane.Planning.Format.PlanningResponse
  alias AriaEngine.Planning.LazyExecution

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: StrategyRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_options(
    execution_timeout_ms: [
      spec: pos_integer(),
      default: 10_000,
      description: "Maximum time allowed for lazy execution"
    ],
    max_depth: [
      spec: pos_integer(),
      default: 100,
      description: "Maximum search depth for lazy execution"
    ],
    enable_refinement: [
      spec: boolean(),
      default: true,
      description: "Enable plan refinement during execution"
    ],
    enable_backtracking: [
      spec: boolean(),
      default: true,
      description: "Enable backtracking on planning failures"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing Lazy Execution Filter")
    Logger.info("🔧 Execution timeout: #{opts.execution_timeout_ms}ms")
    Logger.info("🔧 Max depth: #{opts.max_depth}")
    Logger.info("🔧 Refinement enabled: #{opts.enable_refinement}")
    Logger.info("🔧 Backtracking enabled: #{opts.enable_backtracking}")

    state = %{
      execution_timeout_ms: opts.execution_timeout_ms,
      max_depth: opts.max_depth,
      enable_refinement: opts.enable_refinement,
      enable_backtracking: opts.enable_backtracking,
      execution_stats: %{
        total_requests: 0,
        successful_executions: 0,
        failed_executions: 0,
        timeout_executions: 0,
        refined_executions: 0,
        average_execution_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    strategy_request = buffer.payload

    Logger.info("🔧 Processing lazy execution request: #{strategy_request.request_id}")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Check if request is already an error
      if StrategyRequest.error?(strategy_request) do
        Logger.warn("⚠️ Processing error request: #{strategy_request.request_id}")

        # Create error response
        error_response = PlanningResponse.create_error(
          strategy_request.request_id,
          StrategyRequest.error_reason(strategy_request) || "Unknown error",
          "lazy_execution"
        )

        # Update stats
        updated_stats = update_execution_stats(state.execution_stats, :error, 0)
        new_state = %{state | execution_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: %{
            strategy: "lazy_execution",
            execution_status: :error,
            request_id: strategy_request.request_id,
            executed_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
      else
        # Perform lazy execution with timeout
        execution_result = execute_with_timeout(strategy_request, state)

        end_time = System.monotonic_time(:millisecond)
        execution_time_ms = end_time - start_time

        case execution_result do
          {:ok, planning_response} ->
            Logger.info("✅ Lazy execution successful: #{strategy_request.request_id}")

            # Update execution statistics
            updated_stats = update_execution_stats(state.execution_stats, :success, execution_time_ms)
            new_state = %{state | execution_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: planning_response,
              metadata: %{
                strategy: "lazy_execution",
                execution_status: :success,
                execution_time_ms: execution_time_ms,
                request_id: strategy_request.request_id,
                executed_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:ok, planning_response, :refined} ->
            Logger.info("✅ Lazy execution successful with refinement: #{strategy_request.request_id}")

            # Update execution statistics for refined execution
            updated_stats = update_execution_stats(state.execution_stats, :refined, execution_time_ms)
            new_state = %{state | execution_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: planning_response,
              metadata: %{
                strategy: "lazy_execution",
                execution_status: :refined_success,
                execution_time_ms: execution_time_ms,
                request_id: strategy_request.request_id,
                executed_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ Lazy execution failed: #{strategy_request.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Create error response
            error_response = PlanningResponse.create_error(
              strategy_request.request_id,
              "Lazy execution failed: #{inspect(reason)}",
              "lazy_execution"
            )

            # Update stats
            updated_stats = update_execution_stats(state.execution_stats, :error, execution_time_ms)
            new_state = %{state | execution_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: error_response,
              metadata: %{
                strategy: "lazy_execution",
                execution_status: :error,
                execution_time_ms: execution_time_ms,
                execution_error: inspect(reason),
                request_id: strategy_request.request_id,
                executed_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:timeout} ->
            Logger.error("⏰ Lazy execution timeout: #{strategy_request.request_id}")

            # Create timeout error response
            error_response = PlanningResponse.create_error(
              strategy_request.request_id,
              "Lazy execution timeout after #{state.execution_timeout_ms}ms",
              "lazy_execution"
            )

            # Update stats
            updated_stats = update_execution_stats(state.execution_stats, :timeout, execution_time_ms)
            new_state = %{state | execution_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: error_response,
              metadata: %{
                strategy: "lazy_execution",
                execution_status: :timeout,
                execution_time_ms: execution_time_ms,
                request_id: strategy_request.request_id,
                executed_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        execution_time_ms = end_time - start_time

        Logger.error("❌ Lazy execution exception: #{strategy_request.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Create exception error response
        error_response = PlanningResponse.create_error(
          strategy_request.request_id,
          "Lazy execution exception: #{Exception.message(error)}",
          "lazy_execution"
        )

        # Update stats
        updated_stats = update_execution_stats(state.execution_stats, :error, execution_time_ms)
        new_state = %{state | execution_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: %{
            strategy: "lazy_execution",
            execution_status: :exception,
            execution_time_ms: execution_time_ms,
            execution_exception: Exception.message(error),
            request_id: strategy_request.request_id,
            executed_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp execute_with_timeout(strategy_request, state) do
    # Create task for execution
    task = Task.async(fn ->
      perform_lazy_execution(strategy_request, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, state.execution_timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp perform_lazy_execution(strategy_request, state) do
    try do
      # Extract planning parameters
      domain = strategy_request.domain
      initial_state = strategy_request.state
      goals = strategy_request.goals
      options = strategy_request.options

      # Prepare execution options
      execution_options = options ++ [
        max_depth: state.max_depth,
        enable_refinement: state.enable_refinement,
        enable_backtracking: state.enable_backtracking
      ]

      # Execute lazy planning
      execution_result = LazyExecution.plan(
        domain,
        initial_state,
        goals,
        execution_options
      )

      case execution_result do
        {:ok, plan} ->
          # Convert plan to planning response
          planning_response = convert_plan_to_response(
            plan,
            strategy_request.request_id,
            "lazy_execution"
          )

          {:ok, planning_response}

        {:ok, plan, :refined} ->
          # Convert refined plan to planning response
          planning_response = convert_plan_to_response(
            plan,
            strategy_request.request_id,
            "lazy_execution"
          )

          {:ok, planning_response, :refined}

        {:error, execution_error} ->
          {:error, {:execution_failed, execution_error}}

        {:timeout} ->
          {:error, :execution_timeout}
      end

    rescue
      error ->
        {:error, {:exception, error}}
    end
  end

  defp convert_plan_to_response(plan, request_id, strategy) do
    # Convert lazy execution plan to unified planning response format
    actions = extract_actions_from_plan(plan)
    timeline = create_timeline_from_plan(plan)

    # Create planning response
    PlanningResponse.create_success(
      request_id,
      actions,
      timeline,
      strategy,
      %{
        plan_length: length(actions),
        execution_method: "lazy",
        refinement_used: plan.refined || false
      }
    )
  end

  defp extract_actions_from_plan(plan) do
    # Extract action sequence from lazy execution plan
    case plan do
      %{actions: actions} when is_list(actions) ->
        Enum.map(actions, &convert_to_unified_action/1)

      %{plan: action_list} when is_list(action_list) ->
        Enum.map(action_list, &convert_to_unified_action/1)

      actions when is_list(actions) ->
        Enum.map(actions, &convert_to_unified_action/1)

      _ ->
        []
    end
  end

  defp convert_to_unified_action(action) do
    # Convert lazy execution action format to unified action specification
    case action do
      {action_name, parameters} ->
        %{
          name: action_name,
          parameters: parameters || [],
          start_time: 0,  # Lazy execution doesn't track timing
          duration: 1,    # Default duration
          effects: [],    # Would be derived from domain
          requirements: []
        }

      %{name: name} = action_map ->
        %{
          name: name,
          parameters: Map.get(action_map, :parameters, []),
          start_time: Map.get(action_map, :start_time, 0),
          duration: Map.get(action_map, :duration, 1),
          effects: Map.get(action_map, :effects, []),
          requirements: Map.get(action_map, :requirements, [])
        }

      action_name when is_atom(action_name) ->
        %{
          name: action_name,
          parameters: [],
          start_time: 0,
          duration: 1,
          effects: [],
          requirements: []
        }

      _ ->
        %{
          name: :unknown_action,
          parameters: [],
          start_time: 0,
          duration: 1,
          effects: [],
          requirements: []
        }
    end
  end

  defp create_timeline_from_plan(plan) do
    # Create timeline events from lazy execution plan
    actions = extract_actions_from_plan(plan)

    actions
    |> Enum.with_index()
    |> Enum.flat_map(fn {action, index} ->
      start_time = index
      end_time = index + action.duration

      [
        %{
          time: start_time,
          type: :action_start,
          action: action.name,
          parameters: action.parameters
        },
        %{
          time: end_time,
          type: :action_end,
          action: action.name,
          parameters: action.parameters
        }
      ]
    end)
    |> Enum.sort_by(& &1.time)
  end

  defp update_execution_stats(stats, result, execution_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result do
      :success ->
        %{stats |
          total_requests: new_total,
          successful_executions: stats.successful_executions + 1
        }

      :refined ->
        %{stats |
          total_requests: new_total,
          successful_executions: stats.successful_executions + 1,
          refined_executions: stats.refined_executions + 1
        }

      :timeout ->
        %{stats |
          total_requests: new_total,
          timeout_executions: stats.timeout_executions + 1
        }

      :error ->
        %{stats |
          total_requests: new_total,
          failed_executions: stats.failed_executions + 1
        }
    end

    # Update average execution time
    if execution_time_ms > 0 do
      current_avg = stats.average_execution_time_ms
      new_avg = ((current_avg * (new_total - 1)) + execution_time_ms) / new_total

      %{updated_stats | average_execution_time_ms: new_avg}
    else
      updated_stats
    end
  end
end
