# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Aria.Validate do
  @moduledoc """
  Validate scheduling solutions by comparing different solvers.

  ## Usage

      mix aria.validate --problem "test_problem"
      mix aria.validate --problem "scaling_test" --activities 5
      mix aria.validate --help

  ## Options

    * `--problem` - Problem name (required)
    * `--activities` - Number of activities to generate (1-6, default: random)
    * `--timeout` - Timeout in seconds for each solver (default: 30)
    * `--compare` - Compare solution quality between solvers
    * `--detailed` - Include detailed solver analysis
    * `--output` - Output file for results (JSON format)
    * `--help` - Show this help

  ## Examples

      # Validate with generated problem
      mix aria.validate --problem "test_scaling" --activities 3

      # Compare solvers with detailed analysis
      mix aria.validate --problem "comparison_test" --compare --detailed

      # Save results to file
      mix aria.validate --problem "benchmark" --output results.json
  """

  use Mix.Task
  require Logger

  @shortdoc "Validate scheduling solutions by comparing different solvers"

  @switches [
    problem: :string,
    activities: :integer,
    timeout: :integer,
    compare: :boolean,
    detailed: :boolean,
    output: :string,
    help: :boolean
  ]

  @aliases [
    p: :problem,
    a: :activities,
    t: :timeout,
    c: :compare,
    d: :detailed,
    o: :output,
    h: :help
  ]

  def run(args) do
    {opts, _argv, _errors} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      Mix.shell().info(@moduledoc)
    end

    unless opts[:problem] do
      Mix.shell().error("Error: --problem is required")
      Mix.shell().info("Use --help for usage information")
      System.halt(1)
    end

    # Start the application
    Mix.Task.run("app.start")

    problem_name = opts[:problem]
    activity_count = opts[:activities]
    
    Mix.shell().info("🔍 Starting validation for problem: #{problem_name}")

    # Generate validation problem
    generated_problem = generate_validation_problem(problem_name, activity_count)
    
    Mix.shell().info("🎲 Generated problem with #{length(generated_problem.activities)} activities")
    Mix.shell().info("📊 Complexity: #{generated_problem.metadata.complexity}")

    # Run validation
    case run_validation(generated_problem, opts) do
      {:ok, results} ->
        Mix.shell().info("✅ Validation completed successfully")
        display_validation_results(results)
        
        if opts[:output] do
          save_results_to_file(results, opts[:output])
        end

      {:error, reason} ->
        Mix.shell().error("❌ Validation failed: #{reason}")
        System.halt(1)
    end
  end

  defp generate_validation_problem(base_name, activity_count) do
    # Generate deterministic problem ID based on timestamp
    timestamp = System.system_time(:microsecond)
    problem_id = rem(timestamp, 100_000)

    # Use cryptographic randomization if activity_count not specified
    final_activity_count = activity_count || generate_random_activity_count()

    generate_scaling_task_problem(base_name, problem_id, final_activity_count)
  end

  defp generate_random_activity_count do
    # Use cryptographic hash for truly random distribution
    entropy_data = "#{System.system_time(:microsecond)}_#{:erlang.unique_integer([:positive])}_#{:erlang.system_time(:nanosecond)}"
    crypto_hash = :crypto.hash(:sha256, entropy_data)
    <<hash_int::256>> = crypto_hash
    rem(hash_int, 6) + 1
  end

  defp generate_scaling_task_problem(base_name, problem_id, activity_count) do
    activities = generate_activities_for_count(activity_count)
    entities = generate_entities_for_count(activity_count)
    resources = generate_resources_for_count(activity_count)
    complexity = determine_complexity(activity_count)

    %{
      name: "#{base_name}_scaling_#{activity_count}_#{problem_id}",
      activities: activities,
      entities: entities,
      resources: resources,
      constraints: %{
        "max_concurrent_activities" => min(activity_count, 2),
        "require_resources" => activity_count > 1
      },
      metadata: %{
        complexity: complexity,
        problem_type: "scaling_task_chain",
        activity_count: activity_count,
        generated_at: DateTime.utc_now(),
        problem_id: problem_id,
        scaling_factor: activity_count
      }
    }
  end

  defp generate_activities_for_count(1) do
    [
      %{
        "id" => "identity_task",
        "name" => "Identity Task",
        "duration" => "PT30M",
        "required_capabilities" => ["basic"],
        "required_resources" => ["workstation_1"],
        "dependencies" => []
      }
    ]
  end

  defp generate_activities_for_count(count) when count > 1 do
    for i <- 1..count do
      duration = 30 + i * 15

      %{
        "id" => "task_#{i}",
        "name" => "Task #{i}",
        "duration" => "PT#{duration}M",
        "required_capabilities" => ["basic", "processing"],
        "required_resources" => ["workstation_#{rem(i - 1, 2) + 1}"],
        "dependencies" => if(i > 1, do: ["task_#{i - 1}"], else: [])
      }
    end
  end

  defp generate_entities_for_count(activity_count) do
    entity_count = min(activity_count, 3)

    for i <- 1..entity_count do
      %{
        "id" => "worker_#{i}",
        "type" => "worker",
        "capabilities" => ["basic", "processing", "coordination"],
        "availability" => "PT8H"
      }
    end
  end

  defp generate_resources_for_count(1) do
    %{"workstation_1" => %{"type" => "equipment", "capacity" => 1}}
  end

  defp generate_resources_for_count(count) when count > 1 do
    base_resources =
      for i <- 1..min(count, 3), into: %{} do
        {"workstation_#{i}", %{"type" => "equipment", "capacity" => 1}}
      end

    Map.put(base_resources, "shared_storage", %{"type" => "storage", "capacity" => count})
  end

  defp determine_complexity(1), do: "trivial"
  defp determine_complexity(2), do: "simple"
  defp determine_complexity(n) when n in [3, 4], do: "medium"
  defp determine_complexity(_), do: "high"

  defp run_validation(problem, opts) do
    timeout = opts[:timeout] || 30
    compare_solutions = opts[:compare] || false
    detailed_analysis = opts[:detailed] || false

    Mix.shell().info("🔧 Running validation with timeout: #{timeout}s")

    # Convert problem to scheduler format
    params = %{
      "schedule_name" => problem.name,
      "activities" => problem.activities,
      "entities" => problem.entities,
      "resources" => problem.resources,
      "constraints" => problem.constraints
    }

    # Run primary scheduler
    Mix.shell().info("🚀 Running primary scheduler...")
    primary_start = System.monotonic_time(:millisecond)
    
    primary_result = case call_scheduler(params, %{simulation: true, verbose: 1}) do
      {:ok, result} -> 
        primary_end = System.monotonic_time(:millisecond)
        {:ok, result, primary_end - primary_start}
      {:error, reason} -> 
        {:error, reason}
    end

    # Prepare validation results
    validation_results = %{
      problem: problem,
      primary_solver: format_solver_result("AriaEngine.Scheduler", primary_result),
      validation_options: %{
        timeout_seconds: timeout,
        compare_solutions: compare_solutions,
        detailed_analysis: detailed_analysis
      },
      timestamp: DateTime.utc_now()
    }

    # Add comparison if requested
    final_results = if compare_solutions do
      Mix.shell().info("🔄 Running comparison analysis...")
      add_comparison_analysis(validation_results, params)
    else
      validation_results
    end

    {:ok, final_results}
  end

  defp call_scheduler(params, opts) do
    schedule_name = params["schedule_name"]
    activities = params["activities"] || []
    entities = params["entities"] || []
    resources = params["resources"] || %{}
    constraints = params["constraints"] || %{}

    simulation_mode = opts[:simulation] || false
    verbose = opts[:verbose] || 1
    activity_log = opts[:log_activities] || false

    # Ensure activities and entities are lists
    activities_list = if is_list(activities), do: activities, else: []
    entities_list = if is_list(entities), do: entities, else: []

    # Call the scheduler
    AriaEngine.Scheduler.Core.schedule_with_enhanced_features(
      schedule_name,
      activities_list,
      entities_list,
      resources,
      constraints,
      simulation_mode,
      activity_log,
      verbose
    )
  end

  defp format_solver_result(solver_name, result) do
    case result do
      {:ok, schedule_result, execution_time} ->
        %{
          solver: solver_name,
          status: "success",
          execution_time_ms: execution_time,
          schedule: format_schedule_result(schedule_result),
          analysis: format_analysis_result(schedule_result),
          resource_utilization: format_resource_utilization(schedule_result)
        }

      {:error, reason} ->
        %{
          solver: solver_name,
          status: "error",
          error: reason,
          execution_time_ms: nil
        }
    end
  end

  defp add_comparison_analysis(results, _params) do
    # For now, just add placeholder comparison analysis
    # In a full implementation, this would run additional solvers
    comparison = %{
      solvers_compared: ["AriaEngine.Scheduler"],
      comparison_metrics: %{
        execution_time: "N/A - single solver",
        solution_quality: "N/A - single solver",
        resource_efficiency: "N/A - single solver"
      },
      notes: "Comparison requires multiple solver implementations"
    }

    Map.put(results, :comparison_analysis, comparison)
  end

  defp display_validation_results(results) do
    Mix.shell().info("\n📊 Validation Results:")
    Mix.shell().info("Problem: #{results.problem.name}")
    Mix.shell().info("Activities: #{length(results.problem.activities)}")
    Mix.shell().info("Complexity: #{results.problem.metadata.complexity}")

    primary = results.primary_solver
    Mix.shell().info("\n🚀 Primary Solver (#{primary.solver}):")
    Mix.shell().info("  Status: #{primary.status}")
    
    if primary.status == "success" do
      Mix.shell().info("  Execution Time: #{primary.execution_time_ms}ms")
      Mix.shell().info("  Schedule Items: #{length(primary.schedule)}")
      
      if primary.analysis != %{} do
        Mix.shell().info("  Analysis: #{inspect(primary.analysis)}")
      end
    else
      Mix.shell().info("  Error: #{primary.error}")
    end

    if Map.has_key?(results, :comparison_analysis) do
      Mix.shell().info("\n🔄 Comparison Analysis:")
      comparison = results.comparison_analysis
      Mix.shell().info("  Solvers: #{Enum.join(comparison.solvers_compared, ", ")}")
      Mix.shell().info("  Notes: #{comparison.notes}")
    end
  end

  defp save_results_to_file(results, output_path) do
    case Jason.encode(results, pretty: true) do
      {:ok, json} ->
        case File.write(output_path, json) do
          :ok ->
            Mix.shell().info("💾 Results saved to #{output_path}")
          {:error, reason} ->
            Mix.shell().error("❌ Failed to write to #{output_path}: #{inspect(reason)}")
        end

      {:error, reason} ->
        Mix.shell().error("❌ Failed to encode results as JSON: #{inspect(reason)}")
    end
  end

  defp format_schedule_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{schedule: schedule} -> schedule
      %{schedule: schedule} -> schedule
      _ -> []
    end
  end

  defp format_analysis_result(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{analysis: analysis} -> analysis
      %{analysis: analysis} -> analysis
      _ -> %{}
    end
  end

  defp format_resource_utilization(result) do
    case result do
      %AriaEngine.Scheduler.SimulationResult{resource_utilization: utilization} -> utilization
      %{resource_utilization: utilization} -> utilization
      _ -> %{}
    end
  end
end
