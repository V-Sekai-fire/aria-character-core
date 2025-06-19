defmodule AriaEngine.MCPTools.Handlers do
  @moduledoc """
  Handles incoming MCP tool calls by routing to the appropriate handler function.
  """

  require Logger

  @doc """
  Handles any tool call by routing to the appropriate handler function.
  """
  def handle_tool_call(tool_name, params) when is_binary(tool_name) do
    tool_atom = String.to_atom(tool_name)
    handle_tool_call(tool_atom, params)
  end

  def handle_tool_call(tool_name, params) when is_list(tool_name) do
    # Handle charlist input (convert to string first)
    string_name = List.to_string(tool_name)
    handle_tool_call(string_name, params)
  end

  def handle_tool_call(:schedule_activities, params) do
    handle_schedule_activities_tool_call(params)
  end

  def handle_tool_call(tool_name, _params) do
    Logger.warning("MCPTools: Unknown tool requested: #{inspect(tool_name)}")
    %{
      status: "error",
      reason: "Unknown tool: #{tool_name}",
      schedule: [],
      analysis: %{},
      activity_log: [],
      resource_utilization: %{},
      timeline: [],
      simulation_metadata: %{}
    }
  end

  @doc """
  Handles the schedule_activities tool call with the given parameters.
  """
  def handle_schedule_activities_tool_call(params) do
    try do
      # Validate required parameters
      case AriaEngine.MCPTools.Validator.validate_params(params) do
        {:ok, validated_params} ->
          # Extract and validate parameters
          schedule_name = validated_params["schedule_name"]
          raw_activities = validated_params["activities"] || []

          # Validate activities for type safety and circular dependencies
          case AriaEngine.MCPTools.Validator.validate_activities(raw_activities) do
            {:ok, validated_activities} ->
              activities = AriaEngine.MCPTools.Converter.convert_activities(validated_activities)
              entities = AriaEngine.MCPTools.Converter.convert_entities(validated_params["entities"] || [])
              resources = validated_params["resources"] || %{}
              constraints = validated_params["constraints"] || %{}

              # Prepare scheduler options
              opts = [
                entities: entities,
                resources: resources,
                constraints: constraints,
                simulation_mode: Map.get(constraints, "simulation_mode", true),
                verbose: Map.get(constraints, "verbose", 0),
                log_activities: true
              ]

              # Call the scheduler
              case AriaEngine.Scheduler.schedule_activities(schedule_name, activities, opts) do
                {:ok, simulation_result} ->
                  # Return the complete SimulationResult
                  AriaEngine.MCPTools.Converter.convert_simulation_result_to_map(simulation_result)

                {:error, reason} ->
                  %{
                    status: "error",
                    reason: reason,
                    schedule: [],
                    analysis: %{},
                    activity_log: [],
                    resource_utilization: %{},
                    timeline: [],
                    simulation_metadata: %{}
                  }
              end

            {:error, reason} ->
              %{
                status: "error",
                reason: reason,
                schedule: [],
                analysis: %{},
                activity_log: [],
                resource_utilization: %{},
                timeline: [],
                simulation_metadata: %{}
              }
          end

        {:error, reason} ->
          %{
            status: "error",
            reason: reason,
            schedule: [],
            analysis: %{},
            activity_log: [],
            resource_utilization: %{},
            timeline: [],
            simulation_metadata: %{}
          }
      end
    rescue
      e ->
        Logger.error("MCPTools error: #{Exception.message(e)}")
        %{
          status: "error",
          reason: "Internal error: #{Exception.message(e)}",
          schedule: [],
          analysis: %{},
          activity_log: [],
          resource_utilization: %{},
          timeline: [],
          simulation_metadata: %{}
        }
    end
  end
end
