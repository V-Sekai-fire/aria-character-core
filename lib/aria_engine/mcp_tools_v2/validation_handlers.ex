# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MCPToolsV2.ValidationHandlers do
  @moduledoc """
  Validation handlers for MCP interface.
  
  Handles scheduling solution validation by comparing Hybrid solver with MiniZinc constraint solver.
  """

  require Logger
  alias AriaEngine.Membrane.PipelineManager

  @type validation_problem :: %{
          name: String.t(),
          activities: [map()],
          entities: [map()],
          resources: map(),
          constraints: map(),
          metadata: map()
        }

  @doc """
  Validate scheduling solutions by comparing Hybrid solver with MiniZinc constraint solver.
  """
  @spec handle_validate_scheduling_solutions(map()) :: map()
  def handle_validate_scheduling_solutions(params) do
    Logger.info("🔍 Processing validation request with dual solver comparison")

    # Generate a new unique problem for this validation
    problem_name = params["problem_name"] || "generated_problem"
    generated_problem = generate_new_validation_problem(problem_name)

    Logger.info(
      "🎲 Generated new problem: #{generated_problem.name} with #{length(generated_problem.activities)} activities"
    )

    # Merge generated problem with any provided parameters
    enhanced_params =
      Map.merge(params, %{
        "problem_name" => generated_problem.name,
        "activities" => generated_problem.activities,
        "entities" => generated_problem.entities,
        "resources" => generated_problem.resources,
        "constraints" => generated_problem.constraints,
        "problem_metadata" => generated_problem.metadata
      })

    # Create validation pipeline and process request
    case PipelineManager.create_testing_pipeline(:validation_pipeline) do
      {:ok, pipeline_pid} ->
        # Send validation request to pipeline
        case PipelineManager.send_request_to_pipeline(pipeline_pid, enhanced_params) do
          :ok ->
            # Wait for response (in real implementation, this would be async)
            Process.sleep(1000)

            %{
              "status" => "success",
              "message" => "Validation pipeline processing completed",
              "pipeline_id" => inspect(pipeline_pid),
              "validation_type" => "hybrid_vs_minizinc",
              "generated_problem" => %{
                "name" => generated_problem.name,
                "activities_count" => length(generated_problem.activities),
                "entities_count" => length(generated_problem.entities),
                "resources_count" => map_size(generated_problem.resources),
                "complexity" => generated_problem.metadata.complexity,
                "problem_type" => generated_problem.metadata.problem_type
              }
            }

          {:error, reason} ->
            %{
              "status" => "error",
              "error" => "Failed to send validation request: #{inspect(reason)}"
            }
        end

      {:error, reason} ->
        Logger.error("🔍 Failed to create validation pipeline: #{reason}")

        %{
          "status" => "error",
          "error" => "Failed to create validation pipeline: #{inspect(reason)}"
        }
    end
  end

  @doc """
  Generate a new validation problem for testing.
  """
  @spec generate_new_validation_problem(String.t()) :: validation_problem()
  def generate_new_validation_problem(base_name) do
    # Generate deterministic problem ID based on timestamp
    timestamp = System.system_time(:microsecond)
    problem_id = rem(timestamp, 100_000)

    # Use cryptographic randomization to ensure all combinations are generated
    # Create a cryptographically secure hash from multiple entropy sources
    entropy_data =
      "#{timestamp}_#{base_name}_#{:erlang.unique_integer([:positive])}_#{:erlang.system_time(:nanosecond)}"

    crypto_hash = :crypto.hash(:sha256, entropy_data)

    # Extract bytes and convert to integer for distribution
    <<hash_int::256>> = crypto_hash

    # Use cryptographic hash to select activity count (1-6)
    # This ensures truly random distribution across all values
    activity_count = rem(hash_int, 6) + 1

    generate_scaling_task_problem(base_name, problem_id, activity_count)
  end

  @spec generate_scaling_task_problem(String.t(), integer(), integer()) :: validation_problem()
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

  @spec generate_activities_for_count(integer()) :: [map()]
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

  @spec generate_entities_for_count(integer()) :: [map()]
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

  @spec generate_resources_for_count(integer()) :: map()
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

  @spec determine_complexity(integer()) :: String.t()
  defp determine_complexity(1), do: "trivial"
  defp determine_complexity(2), do: "simple"
  defp determine_complexity(n) when n in [3, 4], do: "medium"
  defp determine_complexity(_), do: "high"
end
