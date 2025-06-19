defmodule AriaEngine.MCPTools.Validator do
  @moduledoc """
  Validates parameters for MCP tool calls, including activity structures
  and dependency relationships.
  """

  def validate_params(params) when is_map(params) do
    cond do
      not Map.has_key?(params, "schedule_name") ->
        {:error, "schedule_name is required"}

      not is_binary(params["schedule_name"]) ->
        {:error, "schedule_name is required and must be a string"}

      String.trim(params["schedule_name"]) == "" ->
        {:error, "schedule_name cannot be empty"}

      not Map.has_key?(params, "activities") ->
        {:error, "activities is required"}

      not is_list(params["activities"]) ->
        {:error, "activities must be a list"}

      true ->
        {:ok, params}
    end
  end

  def validate_params(_), do: {:error, "Invalid parameters format"}

  # Validates activities for type safety and circular dependencies.
  def validate_activities(activities) when is_list(activities) do
    try do
      # First validate each activity's structure and types
      case validate_activity_structures(activities) do
        {:ok, validated_activities} ->
          # Then check for circular dependencies
          case detect_circular_dependencies(validated_activities) do
            :ok -> {:ok, validated_activities}
            cycle ->
              case cycle do
                {:error, reason} -> {:error, "Unexpected error during cycle detection: #{reason}"}
                cycle when is_list(cycle) ->
                  {:error, "Circular dependency detected: #{Enum.join(cycle, " → ")} → #{hd(cycle)}"}
                cycle when is_binary(cycle) ->
                  {:error, "Circular dependency detected: #{cycle}"}
                cycle ->
                  {:error, "Circular dependency detected: #{inspect(cycle)}"}
              end
          end
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, "Invalid activity format: #{Exception.message(e)}"}
    end
  end

  def validate_activities(_), do: {:error, "Activities must be a list"}

  # Validates the structure and types of individual activities.
  def validate_activity_structures(activities) do
    validated = Enum.map(activities, &validate_single_activity/1)

    case Enum.find(validated, &match?({:error, _}, &1)) do
      {:error, reason} -> {:error, reason}
      nil -> {:ok, Enum.map(validated, fn {:ok, activity} -> activity end)}
    end
  end

  # Validates a single activity's structure and types.
  def validate_single_activity(activity) when is_map(activity) do
    with {:ok, id} <- validate_id(activity),
         {:ok, duration} <- validate_duration(activity),
         :ok <- validate_dependencies_format(activity["dependencies"]) do

      validated_activity = %{
        "id" => id,
        "duration" => duration,
        "dependencies" => activity["dependencies"] || [],
        "required_capabilities" => activity["required_capabilities"] || [],
        "required_resources" => activity["required_resources"] || []
      }
      {:ok, validated_activity}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "Invalid activity structure"}
    end
  end

  def validate_single_activity(_), do: {:error, "Activity must be a map/object"}

  def validate_id(activity) do
    cond do
      not Map.has_key?(activity, "id") ->
        {:error, "Activity missing required 'id' field"}
      not is_binary(activity["id"]) ->
        {:error, "Activity 'id' must be a string"}
      String.trim(activity["id"]) == "" ->
        {:error, "Activity 'id' cannot be empty"}
      true ->
        {:ok, String.trim(activity["id"])}
    end
  end

  def validate_duration(activity) do
    case Map.get(activity, "duration") do
      nil ->
        {:error, "Activity missing required 'duration' field"}

      duration_str when is_binary(duration_str) ->
        case parse_iso8601_duration(duration_str) do
          {:ok, _parsed} -> {:ok, duration_str}
          {:error, reason} -> {:error, reason}
        end

      duration_map when is_map(duration_map) ->
        with {:ok, start_time} <- parse_datetime(duration_map, "start"),
             {:ok, end_time} <- parse_datetime(duration_map, "end") do
          if DateTime.compare(end_time, start_time) == :gt do
            {:ok, duration_map}
          else
            {:error, "End time must be after start time"}
          end
        end

      duration_int when is_integer(duration_int) ->
        # Backwards compatibility for integer durations (minutes)
        if duration_int >= 0 do
          {:ok, duration_int}
        else
          {:error, "Activity 'duration' must be non-negative, got: #{duration_int}"}
        end

      _ ->
        {:error, "Invalid 'duration' format. Must be an ISO 8601 duration string, a start/end object, or an integer (minutes)."}
    end
  end

  def parse_datetime(map, key) do
    case Map.get(map, key) do
      nil -> {:error, "Missing '#{key}' in duration object"}
      datetime_str when is_binary(datetime_str) ->
        case DateTime.from_iso8601(datetime_str) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, reason} -> {:error, "Invalid '#{key}' datetime format: #{reason}"}
        end
      _ -> {:error, "Invalid '#{key}' format: must be a string"}
    end
  end

  # Parse ISO8601 duration strings like "PT2H30M" without external dependencies
  def parse_iso8601_duration(duration_str) when is_binary(duration_str) do
    # Simple regex-based parser for common ISO8601 duration formats
    # Supports: PT[n]H[n]M[n]S format
    regex = ~r/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$/

    case Regex.run(regex, String.upcase(duration_str)) do
      [_, hours_str, minutes_str, seconds_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)
        seconds = parse_time_component(seconds_str)

        {:ok, %{hours: hours, minutes: minutes, seconds: seconds}}

      [_, hours_str, minutes_str] ->
        hours = parse_time_component(hours_str)
        minutes = parse_time_component(minutes_str)

        {:ok, %{hours: hours, minutes: minutes, seconds: 0}}

      [_, hours_str] ->
        hours = parse_time_component(hours_str)

        {:ok, %{hours: hours, minutes: 0, seconds: 0}}

      _ ->
        {:error, "Invalid ISO 8601 duration format: #{duration_str}. Expected format like PT2H30M or PT90M"}
    end
  end

  def parse_time_component(nil), do: 0
  def parse_time_component(""), do: 0
  def parse_time_component(str) when is_binary(str) do
    case Float.parse(str) do
      {value, ""} -> trunc(value)
      _ -> 0
    end
  end

  # Validates dependencies format.
  def validate_dependencies_format(nil), do: :ok
  def validate_dependencies_format(deps) when is_list(deps) do
    if Enum.all?(deps, &is_binary/1) do
      :ok
    else
      {:error, "Activity 'dependencies' must be a list of strings"}
    end
  end
  def validate_dependencies_format(_), do: {:error, "Activity 'dependencies' must be a list of strings"}

  # Detects circular dependencies using depth-first search.
  def detect_circular_dependencies(activities) do
    # Build dependency graph
    dependency_graph = build_dependency_graph(activities)
    activity_ids = Enum.map(activities, & &1["id"])

    # Check each activity for cycles using DFS
    case find_cycle_in_graph(dependency_graph, activity_ids) do
      nil -> :ok
      cycle ->
        case cycle do
          {:error, reason} -> {:error, "Unexpected error during cycle detection: #{reason}"}
          _ -> {:error, "Circular dependency detected: #{Enum.join(cycle, " → ")} → #{List.first(cycle)}"}
        end
    end
  end

  # Builds a dependency graph from activities.
  def build_dependency_graph(activities) do
    Enum.reduce(activities, %{}, fn activity, graph ->
      activity_id = activity["id"]
      dependencies = activity["dependencies"] || []
      Map.put(graph, activity_id, dependencies)
    end)
  end

  # Finds cycles in the dependency graph using DFS.
  def find_cycle_in_graph(graph, activity_ids) do
    Enum.find_value(activity_ids, fn start_node ->
      visited = MapSet.new()
      path = []
      dfs_detect_cycle(graph, start_node, visited, path)
    end)
  end

  # Depth-first search to detect cycles.
  def dfs_detect_cycle(graph, node, visited, path) do
    cond do
      node in path ->
        # Found a cycle - return the cycle path
        cycle_start_index = Enum.find_index(path, &(&1 == node))
        cycle = Enum.drop(path, cycle_start_index) |> Enum.reverse()
        cycle # Explicit return

      MapSet.member?(visited, node) ->
        # Already visited this node in a different path, no cycle here
        nil

      true ->
        # Continue DFS
        updated_visited = MapSet.put(visited, node)
        updated_path = [node | path]
        dependencies = Map.get(graph, node, [])

        Enum.find_value(dependencies, fn dep ->
          dfs_detect_cycle(graph, dep, updated_visited, updated_path)
        end)
    end
  end
end
