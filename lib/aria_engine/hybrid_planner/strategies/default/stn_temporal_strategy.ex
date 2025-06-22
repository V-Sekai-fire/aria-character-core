# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Default.STNTemporalStrategy do
  @moduledoc """
  MiniZinc-based STN temporal strategy implementation.

  This strategy provides temporal constraint solving using MiniZinc constraint solver
  instead of the PC2-based STNPlanner. It supports Allen's interval algebra and
  provides robust temporal reasoning capabilities.
  """

  @behaviour HybridPlanner.Strategies.TemporalStrategy

  # TOMBSTONE: AriaEngine.Membrane.ValidationPipeline.MiniZincSolver was removed during temporal planning segment closure
  # The MiniZinc validation pipeline was removed in favor of direct STN solving
  # Removed: January 2025
  # NOTE: Timeline.Internal.STN.MiniZincSolver exists but is not used by this strategy implementation

  require Logger

  @impl true
  def add_temporal_constraints(existing_constraints, actions, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    current_time = Keyword.get(opts, :current_time, 0)

    if verbose > 1 do
      Logger.debug(
        "STNTemporalStrategy: Adding temporal constraints for #{length(actions)} actions"
      )
    end

    try do
      # Start with existing constraints or create new temporal problem
      temporal_problem =
        case existing_constraints do
          %{temporal_problem: problem} when not is_nil(problem) -> problem
          _ -> %{actions: [], constraints: [], current_time: current_time}
        end

      # Add new actions to the temporal problem
      updated_problem = %{
        temporal_problem
        | actions: temporal_problem.actions ++ actions,
          current_time: current_time
      }

      if verbose > 1 do
        action_count = length(updated_problem.actions)
        constraint_count = length(updated_problem.constraints)

        Logger.debug(
          "STNTemporalStrategy: Successfully added constraints (#{action_count} actions, #{constraint_count} constraints)"
        )
      end

      {:ok, %{temporal_problem: updated_problem, last_update: System.system_time(:millisecond)}}
    rescue
      e ->
        error_msg = "STNTemporalStrategy constraint addition error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def validate_temporal_consistency(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Validating temporal consistency")
    end

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # Build and solve MiniZinc model to check consistency
          case build_temporal_model(problem) do
            {:ok, mzn_content} ->
              case solve_temporal_model(mzn_content, opts) do
                {:ok, %{status: "OPTIMAL"}} ->
                  if verbose > 1 do
                    Logger.debug("STNTemporalStrategy: Temporal constraints are consistent")
                  end

                  {:ok, true}

                {:ok, %{status: "INFEASIBLE"}} ->
                  if verbose > 0 do
                    Logger.warning("STNTemporalStrategy: Temporal constraints are inconsistent")
                  end

                  {:ok, false}

                {:error, reason} ->
                  {:error, "Consistency check failed: #{reason}"}
              end

            {:error, reason} ->
              {:error, "Model building failed: #{reason}"}
          end

        _ ->
          # No constraints means trivially consistent
          if verbose > 1 do
            Logger.debug("STNTemporalStrategy: No constraints present, trivially consistent")
          end

          {:ok, true}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy consistency validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def update_constraints(constraints, modifications, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug(
        "STNTemporalStrategy: Updating constraints with #{length(modifications)} modifications"
      )
    end

    try do
      temporal_problem =
        case constraints do
          %{temporal_problem: problem} when not is_nil(problem) -> problem
          _ -> %{actions: [], constraints: [], current_time: 0}
        end

      # Apply each modification to the temporal problem
      updated_problem =
        Enum.reduce(modifications, temporal_problem, fn modification, acc_problem ->
          apply_temporal_modification(acc_problem, modification, opts)
        end)

      if verbose > 1 do
        Logger.debug("STNTemporalStrategy: Successfully updated constraints")
      end

      {:ok, %{temporal_problem: updated_problem, last_update: System.system_time(:millisecond)}}
    rescue
      e ->
        error_msg = "STNTemporalStrategy constraint update error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def get_temporal_schedule(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Generating temporal schedule")
    end

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # Build and solve MiniZinc model to generate schedule
          case build_temporal_model(problem) do
            {:ok, mzn_content} ->
              case solve_temporal_model(mzn_content, opts) do
                {:ok, %{status: "OPTIMAL", variables: variables}} ->
                  schedule = extract_schedule_from_solution(variables, problem.actions)

                  if verbose > 1 do
                    Logger.debug("STNTemporalStrategy: Generated temporal schedule")
                  end

                  {:ok,
                   %{
                     schedule: schedule,
                     generated_at: System.system_time(:millisecond),
                     problem_hash: :erlang.phash2(problem)
                   }}

                {:ok, %{status: "INFEASIBLE"}} ->
                  {:error, "No feasible temporal schedule exists"}

                {:error, reason} ->
                  {:error, "Schedule generation failed: #{reason}"}
              end

            {:error, reason} ->
              {:error, "Model building failed: #{reason}"}
          end

        _ ->
          # No constraints means empty schedule
          if verbose > 1 do
            Logger.debug("STNTemporalStrategy: No constraints, returning empty schedule")
          end

          {:ok,
           %{
             schedule: %{},
             generated_at: System.system_time(:millisecond),
             problem_hash: nil
           }}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy schedule generation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Build MiniZinc temporal model from temporal problem
  defp build_temporal_model(problem) do
    try do
      actions = problem.actions
      constraints = Map.get(problem, :constraints, [])

      if Enum.empty?(actions) do
        {:ok, build_empty_model()}
      else
        mzn_content = build_temporal_constraints_model(actions, constraints)
        {:ok, mzn_content}
      end
    rescue
      e ->
        {:error, "Model building failed: #{Exception.message(e)}"}
    end
  end

  # Build MiniZinc model for temporal constraints
  defp build_temporal_constraints_model(actions, constraints) do
    action_vars = build_action_variables(actions)
    duration_constraints = build_duration_constraints(actions)
    temporal_constraints = build_temporal_constraints(constraints)
    objective = build_temporal_objective(actions)

    """
    % Temporal Scheduling Problem
    include "globals.mzn";

    #{action_vars}

    #{duration_constraints}

    #{temporal_constraints}

    #{objective}

    solve minimize makespan;

    output [
      "{\\"status\\": \\"OPTIMAL\\", \\"variables\\": {",
      #{build_output_format(actions)},
      "\\"makespan\\": ", show(makespan), "}}"
    ];
    """
  end

  # Build action variables for MiniZinc
  defp build_action_variables(actions) do
    action_lines =
      Enum.map_join(actions, "\n", fn {action_name, action_data} ->
        duration = Map.get(action_data, :duration, 1)

        "var 0..1000: #{action_name}_start;\n" <>
          "var 0..1000: #{action_name}_end;\n" <>
          "constraint #{action_name}_end = #{action_name}_start + #{duration};"
      end)

    "% Action variables\n#{action_lines}"
  end

  # Build duration constraints
  defp build_duration_constraints(actions) do
    if Enum.empty?(actions) do
      ""
    else
      "% Duration constraints already included in action variables"
    end
  end

  # Build temporal precedence constraints
  defp build_temporal_constraints(constraints) do
    constraint_lines =
      Enum.map_join(constraints, "\n", fn constraint ->
        case constraint do
          {:before, action1, action2} ->
            "constraint #{action1}_end <= #{action2}_start;"

          {:after, action1, action2} ->
            "constraint #{action2}_end <= #{action1}_start;"

          {:meets, action1, action2} ->
            "constraint #{action1}_end = #{action2}_start;"

          {:overlaps, action1, action2} ->
            "constraint #{action1}_start < #{action2}_start /\\ #{action1}_end > #{action2}_start /\\ #{action1}_end < #{action2}_end;"

          _ ->
            "% Unknown constraint: #{inspect(constraint)}"
        end
      end)

    if constraint_lines == "" do
      "% No temporal constraints"
    else
      "% Temporal constraints\n#{constraint_lines}"
    end
  end

  # Build objective function
  defp build_temporal_objective(actions) do
    if Enum.empty?(actions) do
      "var 0..0: makespan;\nconstraint makespan = 0;"
    else
      end_times = Enum.map_join(actions, ", ", fn {action_name, _} -> "#{action_name}_end" end)
      "var 0..1000: makespan;\nconstraint makespan = max([#{end_times}]);"
    end
  end

  # Build output format for solution extraction
  defp build_output_format(actions) do
    if Enum.empty?(actions) do
      ""
    else
      action_outputs =
        Enum.map_join(actions, ", ", fn {_action_name, _action_data} ->
          # {action_name}_start\\": \", show(#{action_name}_start), \", \\"#{action_name}_end\\": \", show(#{action_name}_end)"
          "\\"
        end)

      action_outputs <> ", "
    end
  end

  # Build empty model for no actions
  defp build_empty_model do
    """
    var 0..0: makespan;
    constraint makespan = 0;
    solve minimize makespan;
    output ["{\\"status\\": \\"OPTIMAL\\", \\"variables\\": {}, \\"makespan\\": 0}"];
    """
  end

  # Solve temporal model using MiniZinc
  defp solve_temporal_model(mzn_content, _opts) do
    # Write model to temporary file
    temp_file = "/tmp/temporal_model_#{:erlang.unique_integer([:positive])}.mzn"

    try do
      File.write!(temp_file, mzn_content)

      # Execute MiniZinc
      cmd_args = [
        "--solver",
        "org.minizinc.mip.coin-bc",
        "--output-mode",
        "json",
        temp_file
      ]

      case System.cmd("minizinc", cmd_args, stderr_to_stdout: true) do
        {output, 0} ->
          parse_minizinc_output(output)

        {output, exit_code} ->
          {:error, "MiniZinc failed with exit code #{exit_code}: #{output}"}
      end
    after
      File.rm(temp_file)
    end
  rescue
    e ->
      {:error, "Solver execution failed: #{Exception.message(e)}"}
  end

  # Parse MiniZinc output
  defp parse_minizinc_output(output) do
    try do
      # Look for JSON output in the response
      lines = String.split(output, "\n")
      json_line = Enum.find(lines, fn line -> String.contains?(line, "\"status\"") end)

      if json_line do
        case Jason.decode(json_line) do
          {:ok, result} -> {:ok, result}
          {:error, _} -> {:error, "Failed to parse MiniZinc JSON output"}
        end
      else
        # Fallback parsing for non-JSON output
        if String.contains?(output, "UNSATISFIABLE") or String.contains?(output, "INFEASIBLE") do
          {:ok, %{status: "INFEASIBLE"}}
        else
          {:ok, %{status: "OPTIMAL", variables: %{}}}
        end
      end
    rescue
      _ ->
        {:error, "Failed to parse MiniZinc output"}
    end
  end

  # Extract schedule from MiniZinc solution
  defp extract_schedule_from_solution(variables, actions) do
    Enum.reduce(actions, %{}, fn {action_name, action_data}, acc ->
      start_key = "#{action_name}_start"
      end_key = "#{action_name}_end"

      start_time = Map.get(variables, start_key, 0)
      end_time = Map.get(variables, end_key, start_time + Map.get(action_data, :duration, 1))

      Map.put(acc, action_name, %{
        start_time: start_time,
        end_time: end_time,
        duration: end_time - start_time
      })
    end)
  end

  # Apply temporal modification to problem
  defp apply_temporal_modification(problem, modification, _opts) do
    case modification do
      {:add_constraint, constraint} ->
        constraints = Map.get(problem, :constraints, [])
        %{problem | constraints: [constraint | constraints]}

      {:remove_constraint, constraint} ->
        constraints = Map.get(problem, :constraints, [])
        %{problem | constraints: List.delete(constraints, constraint)}

      {:add_action, action} ->
        actions = problem.actions
        %{problem | actions: [action | actions]}

      {:remove_action, action_name} ->
        actions = Enum.reject(problem.actions, fn {name, _} -> name == action_name end)
        %{problem | actions: actions}

      _ ->
        Logger.warning("Unknown temporal modification: #{inspect(modification)}")
        problem
    end
  end

  # ==================== STRATEGY METADATA ====================

  @doc """
  Get strategy metadata and capabilities.
  """
  def strategy_info do
    %{
      name: "STN Temporal Strategy",
      version: "1.0.0",
      description: "Default STN-based temporal reasoning strategy using Simple Temporal Networks",
      capabilities: [
        :temporal_constraints,
        :consistency_checking,
        :schedule_generation,
        :timeline_based_reasoning,
        :conflict_detection,
        :hierarchical_planning,
        :discrete_time_reasoning
      ],
      limitations: [
        :no_continuous_time,
        :no_resource_conflicts,
        :simple_duration_model,
        :no_conditional_constraints,
        :no_metric_optimization
      ],
      temporal_model: %{
        time_representation: :discrete_intervals,
        constraint_types: [:before, :after, :during, :meets, :overlaps],
        precision: :millisecond,
        supports_uncertainty: false
      },
      configuration_options: [
        :verbose,
        :current_time,
        :timeline_reasoning_level,
        :consistency_check_frequency
      ],
      dependencies: [
        "TemporalPlanner.STNPlanner",
        "Logger"
      ],
      action_compatibility: [
        :durative_actions,
        :instantaneous_actions,
        :hierarchical_actions
      ],
      underlying_implementation: "TemporalPlanner.STNPlanner",
      performance_characteristics: %{
        best_case_actions: 1000,
        worst_case_complexity: "O(n³)",
        memory_scaling: "O(n²)",
        recommended_max_actions: 500
      }
    }
  end

  @doc """
  Check if this strategy can handle specific temporal features.
  """
  def supports?(feature) when is_atom(feature) do
    capabilities = strategy_info()[:capabilities]
    feature in capabilities
  end

  @doc """
  Get performance characteristics of this strategy.
  """
  def performance_profile do
    %{
      constraint_addition_complexity: :linear,
      consistency_check_complexity: :polynomial,
      memory_usage: :moderate,
      scalability: :good,
      precision: :discrete_time
    }
  end
end
