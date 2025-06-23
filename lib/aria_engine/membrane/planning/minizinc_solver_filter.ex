# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.MiniZincSolverFilter do
  @moduledoc """
  Membrane filter that executes MiniZinc constraint satisfaction planning.

  This filter handles complex temporal planning problems using MiniZinc constraint
  satisfaction. Integrates with the existing MiniZinc infrastructure while providing
  membrane-compatible interfaces and comprehensive error handling.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W033MZCS"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.Planning.Format.StrategyRequest
  alias AriaEngine.Membrane.Planning.Format.PlanningResponse
  alias AriaEngine.MiniZinc.Solver
  alias AriaEngine.MiniZinc.ProblemGenerator

  def_input_pad(:input,
    accepted_format: %Membrane.RemoteStream{content_format: StrategyRequest},
    flow_control: :auto
  )

  def_output_pad(:output,
    accepted_format: %Membrane.RemoteStream{content_format: PlanningResponse},
    flow_control: :auto
  )

  def_options(
    solver_timeout_ms: [
      spec: pos_integer(),
      default: 30_000,
      description: "Maximum time allowed for MiniZinc solving"
    ],
    max_solutions: [
      spec: pos_integer(),
      default: 1,
      description: "Maximum number of solutions to find"
    ],
    optimization_level: [
      spec: :basic | :advanced | :experimental,
      default: :basic,
      description: "MiniZinc optimization level"
    ],
    enable_fallback: [
      spec: boolean(),
      default: true,
      description: "Enable fallback to simpler models on failure"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing MiniZinc Solver Filter")
    Logger.info("🔧 Solver timeout: #{opts.solver_timeout_ms}ms")
    Logger.info("🔧 Max solutions: #{opts.max_solutions}")
    Logger.info("🔧 Optimization level: #{opts.optimization_level}")
    Logger.info("🔧 Fallback enabled: #{opts.enable_fallback}")

    state = %{
      solver_timeout_ms: opts.solver_timeout_ms,
      max_solutions: opts.max_solutions,
      optimization_level: opts.optimization_level,
      enable_fallback: opts.enable_fallback,
      solver_stats: %{
        total_requests: 0,
        successful_solves: 0,
        failed_solves: 0,
        timeout_solves: 0,
        fallback_solves: 0,
        average_solve_time_ms: 0
      }
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    strategy_request = buffer.payload

    Logger.info("🔧 Processing MiniZinc request: #{strategy_request.request_id}")

    start_time = System.monotonic_time(:millisecond)

    try do
      # Check if request is already an error
      if StrategyRequest.error?(strategy_request) do
        Logger.warn("⚠️ Processing error request: #{strategy_request.request_id}")

        # Create error response
        error_response = PlanningResponse.create_error(
          strategy_request.request_id,
          StrategyRequest.error_reason(strategy_request) || "Unknown error",
          "minizinc"
        )

        # Update stats
        updated_stats = update_solver_stats(state.solver_stats, :error, 0)
        new_state = %{state | solver_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: %{
            strategy: "minizinc",
            solve_status: :error,
            request_id: strategy_request.request_id,
            solved_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
      else
        # Perform MiniZinc solving with timeout
        solve_result = solve_with_timeout(strategy_request, state)

        end_time = System.monotonic_time(:millisecond)
        solve_time_ms = end_time - start_time

        case solve_result do
          {:ok, planning_response} ->
            Logger.info("✅ MiniZinc solve successful: #{strategy_request.request_id}")

            # Update solver statistics
            updated_stats = update_solver_stats(state.solver_stats, :success, solve_time_ms)
            new_state = %{state | solver_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: planning_response,
              metadata: %{
                strategy: "minizinc",
                solve_status: :success,
                solve_time_ms: solve_time_ms,
                request_id: strategy_request.request_id,
                solved_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}

          {:error, reason} ->
            Logger.error("❌ MiniZinc solve failed: #{strategy_request.request_id}")
            Logger.error("❌ Reason: #{inspect(reason)}")

            # Try fallback if enabled
            if state.enable_fallback do
              Logger.info("🔄 Attempting fallback solve for: #{strategy_request.request_id}")

              case attempt_fallback_solve(strategy_request, state) do
                {:ok, fallback_response} ->
                  Logger.info("✅ Fallback solve successful: #{strategy_request.request_id}")

                  # Update stats for fallback success
                  updated_stats = update_solver_stats(state.solver_stats, :fallback, solve_time_ms)
                  new_state = %{state | solver_stats: updated_stats}

                  # Create output buffer
                  output_buffer = %Membrane.Buffer{
                    payload: fallback_response,
                    metadata: %{
                      strategy: "minizinc_fallback",
                      solve_status: :fallback_success,
                      solve_time_ms: solve_time_ms,
                      original_error: inspect(reason),
                      request_id: strategy_request.request_id,
                      solved_at: DateTime.utc_now()
                    }
                  }

                  {[buffer: {:output, output_buffer}], new_state}

                {:error, fallback_reason} ->
                  Logger.error("❌ Fallback solve also failed: #{strategy_request.request_id}")

                  # Create error response
                  error_response = PlanningResponse.create_error(
                    strategy_request.request_id,
                    "MiniZinc solve failed: #{inspect(reason)}. Fallback failed: #{inspect(fallback_reason)}",
                    "minizinc"
                  )

                  # Update stats
                  updated_stats = update_solver_stats(state.solver_stats, :error, solve_time_ms)
                  new_state = %{state | solver_stats: updated_stats}

                  # Create output buffer
                  output_buffer = %Membrane.Buffer{
                    payload: error_response,
                    metadata: %{
                      strategy: "minizinc",
                      solve_status: :error,
                      solve_time_ms: solve_time_ms,
                      solve_error: inspect(reason),
                      fallback_error: inspect(fallback_reason),
                      request_id: strategy_request.request_id,
                      solved_at: DateTime.utc_now()
                    }
                  }

                  {[buffer: {:output, output_buffer}], new_state}
              end
            else
              # Create error response without fallback
              error_response = PlanningResponse.create_error(
                strategy_request.request_id,
                "MiniZinc solve failed: #{inspect(reason)}",
                "minizinc"
              )

              # Update stats
              updated_stats = update_solver_stats(state.solver_stats, :error, solve_time_ms)
              new_state = %{state | solver_stats: updated_stats}

              # Create output buffer
              output_buffer = %Membrane.Buffer{
                payload: error_response,
                metadata: %{
                  strategy: "minizinc",
                  solve_status: :error,
                  solve_time_ms: solve_time_ms,
                  solve_error: inspect(reason),
                  request_id: strategy_request.request_id,
                  solved_at: DateTime.utc_now()
                }
              }

              {[buffer: {:output, output_buffer}], new_state}
            end

          {:timeout} ->
            Logger.error("⏰ MiniZinc solve timeout: #{strategy_request.request_id}")

            # Create timeout error response
            error_response = PlanningResponse.create_error(
              strategy_request.request_id,
              "MiniZinc solve timeout after #{state.solver_timeout_ms}ms",
              "minizinc"
            )

            # Update stats
            updated_stats = update_solver_stats(state.solver_stats, :timeout, solve_time_ms)
            new_state = %{state | solver_stats: updated_stats}

            # Create output buffer
            output_buffer = %Membrane.Buffer{
              payload: error_response,
              metadata: %{
                strategy: "minizinc",
                solve_status: :timeout,
                solve_time_ms: solve_time_ms,
                request_id: strategy_request.request_id,
                solved_at: DateTime.utc_now()
              }
            }

            {[buffer: {:output, output_buffer}], new_state}
        end
      end

    rescue
      error ->
        end_time = System.monotonic_time(:millisecond)
        solve_time_ms = end_time - start_time

        Logger.error("❌ MiniZinc solve exception: #{strategy_request.request_id}")
        Logger.error("❌ Exception: #{inspect(error)}")

        # Create exception error response
        error_response = PlanningResponse.create_error(
          strategy_request.request_id,
          "MiniZinc solve exception: #{Exception.message(error)}",
          "minizinc"
        )

        # Update stats
        updated_stats = update_solver_stats(state.solver_stats, :error, solve_time_ms)
        new_state = %{state | solver_stats: updated_stats}

        # Create output buffer
        output_buffer = %Membrane.Buffer{
          payload: error_response,
          metadata: %{
            strategy: "minizinc",
            solve_status: :exception,
            solve_time_ms: solve_time_ms,
            solve_exception: Exception.message(error),
            request_id: strategy_request.request_id,
            solved_at: DateTime.utc_now()
          }
        }

        {[buffer: {:output, output_buffer}], new_state}
    end
  end

  # Private functions

  defp solve_with_timeout(strategy_request, state) do
    # Create task for solving
    task = Task.async(fn ->
      perform_minizinc_solve(strategy_request, state)
    end)

    # Wait for result with timeout
    case Task.yield(task, state.solver_timeout_ms) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:timeout}
    end
  end

  defp perform_minizinc_solve(strategy_request, state) do
    try do
      # Extract planning parameters
      domain = strategy_request.domain
      initial_state = strategy_request.state
      goals = strategy_request.goals
      options = strategy_request.options

      # Generate MiniZinc problem
      problem_result = ProblemGenerator.generate_problem(
        domain,
        initial_state,
        goals,
        options ++ [
          optimization_level: state.optimization_level,
          max_solutions: state.max_solutions
        ]
      )

      case problem_result do
        {:ok, minizinc_model} ->
          # Solve with MiniZinc
          solve_result = Solver.solve(
            minizinc_model,
            timeout_ms: state.solver_timeout_ms,
            max_solutions: state.max_solutions
          )

          case solve_result do
            {:ok, solutions} ->
              # Convert solutions to planning response
              planning_response = convert_solutions_to_response(
                solutions,
                strategy_request.request_id,
                "minizinc"
              )

              {:ok, planning_response}

            {:error, solve_error} ->
              {:error, {:solve_failed, solve_error}}

            {:timeout} ->
              {:error, :solver_timeout}
          end

        {:error, generation_error} ->
          {:error, {:problem_generation_failed, generation_error}}
      end

    rescue
      error ->
        {:error, {:exception, error}}
    end
  end

  defp attempt_fallback_solve(strategy_request, state) do
    try do
      # Try with simplified model
      simplified_options = strategy_request.options ++ [
        optimization_level: :basic,
        max_solutions: 1,
        simplified_model: true
      ]

      # Generate simplified problem
      problem_result = ProblemGenerator.generate_problem(
        strategy_request.domain,
        strategy_request.state,
        strategy_request.goals,
        simplified_options
      )

      case problem_result do
        {:ok, minizinc_model} ->
          # Solve with reduced timeout
          fallback_timeout = div(state.solver_timeout_ms, 2)

          solve_result = Solver.solve(
            minizinc_model,
            timeout_ms: fallback_timeout,
            max_solutions: 1
          )

          case solve_result do
            {:ok, solutions} ->
              # Convert solutions to planning response
              planning_response = convert_solutions_to_response(
                solutions,
                strategy_request.request_id,
                "minizinc_fallback"
              )

              {:ok, planning_response}

            {:error, solve_error} ->
              {:error, {:fallback_solve_failed, solve_error}}

            {:timeout} ->
              {:error, :fallback_timeout}
          end

        {:error, generation_error} ->
          {:error, {:fallback_generation_failed, generation_error}}
      end

    rescue
      error ->
        {:error, {:fallback_exception, error}}
    end
  end

  defp convert_solutions_to_response(solutions, request_id, strategy) do
    # Convert MiniZinc solutions to unified planning response format
    actions = solutions
    |> List.first()  # Take first solution for now
    |> extract_actions_from_solution()
    |> convert_to_unified_actions()

    # Create timeline from actions
    timeline = create_timeline_from_actions(actions)

    # Create planning response
    PlanningResponse.create_success(
      request_id,
      actions,
      timeline,
      strategy,
      %{
        solution_count: length(solutions),
        solver: "minizinc",
        optimization_used: true
      }
    )
  end

  defp extract_actions_from_solution(solution) do
    # Extract action sequence from MiniZinc solution
    # This would parse the MiniZinc output format
    # For now, return empty list as placeholder
    []
  end

  defp convert_to_unified_actions(minizinc_actions) do
    # Convert MiniZinc action format to unified action specification
    Enum.map(minizinc_actions, fn action ->
      %{
        name: action.name,
        parameters: action.parameters,
        start_time: action.start_time,
        duration: action.duration,
        effects: action.effects,
        requirements: action.requirements
      }
    end)
  end

  defp create_timeline_from_actions(actions) do
    # Create timeline events from action sequence
    Enum.flat_map(actions, fn action ->
      [
        %{
          time: action.start_time,
          type: :action_start,
          action: action.name,
          parameters: action.parameters
        },
        %{
          time: action.start_time + action.duration,
          type: :action_end,
          action: action.name,
          parameters: action.parameters
        }
      ]
    end)
    |> Enum.sort_by(& &1.time)
  end

  defp update_solver_stats(stats, result, solve_time_ms) do
    new_total = stats.total_requests + 1

    updated_stats = case result do
      :success ->
        %{stats |
          total_requests: new_total,
          successful_solves: stats.successful_solves + 1
        }

      :fallback ->
        %{stats |
          total_requests: new_total,
          successful_solves: stats.successful_solves + 1,
          fallback_solves: stats.fallback_solves + 1
        }

      :timeout ->
        %{stats |
          total_requests: new_total,
          timeout_solves: stats.timeout_solves + 1
        }

      :error ->
        %{stats |
          total_requests: new_total,
          failed_solves: stats.failed_solves + 1
        }
    end

    # Update average solve time
    if solve_time_ms > 0 do
      current_avg = stats.average_solve_time_ms
      new_avg = ((current_avg * (new_total - 1)) + solve_time_ms) / new_total

      %{updated_stats | average_solve_time_ms: new_avg}
    else
      updated_stats
    end
  end
end
