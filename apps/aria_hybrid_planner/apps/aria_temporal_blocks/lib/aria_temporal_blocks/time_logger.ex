# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTemporalBlocks.TimeLogger do
  @moduledoc """
  Temporal planning time logging utilities.

  Provides debug logging for planned action times and execution timing.
  Supports both planning phase timeline logging and execution phase real-time logging.
  """

  require Logger

  @type action_name :: atom() | String.t()
  @type args :: list()
  @type duration :: float()
  @type timestamp :: float()

  @type timeline_entry :: %{
    action: action_name(),
    args: args(),
    start_time: timestamp(),
    end_time: timestamp(),
    duration: duration()
  }

  @type timeline :: [timeline_entry()]

  @doc """
  Log the complete planned timeline after HTN planning is complete.

  Extracts primitive actions from the solution tree and calculates planned
  start/end times based on domain action durations.

  ## Parameters

  - `solution_tree` - The solution tree from AriaHybridPlanner.plan/4
  - `domain` - The domain containing action duration specifications
  - `opts` - Options including `:scheduled_start_time` for absolute scheduling

  ## Options

  - `:scheduled_start_time` - ISO 8601 datetime string for when execution should begin
  - `:use_iso_format` - Boolean to use ISO datetime formatting (default: false)

  ## Example

      {:ok, plan} = AriaHybridPlanner.plan(domain, state, todos)
      AriaTemporalBlocks.TimeLogger.log_planned_timeline(plan.solution_tree, domain,
        scheduled_start_time: "2025-08-04T18:00:00Z", use_iso_format: true)
  """
  @spec log_planned_timeline(AriaEngineCore.Plan.solution_tree(), map(), keyword()) :: :ok
  def log_planned_timeline(solution_tree, domain, opts \\ []) do
    use_iso_format = Keyword.get(opts, :use_iso_format, false)
    scheduled_start_time = Keyword.get(opts, :scheduled_start_time)

    Logger.debug("=== PLANNED TIMELINE ===")

    if scheduled_start_time do
      Logger.debug("Scheduled start time: #{scheduled_start_time}")
    end

    case calculate_timeline(solution_tree, domain, opts) do
      {:ok, timeline} ->
        total_duration = case List.last(timeline) do
          nil -> 0.0
          last_entry ->
            if use_iso_format and scheduled_start_time do
              # Calculate total duration from start time to end time
              start_dt = parse_iso_datetime(scheduled_start_time)
              end_dt = parse_iso_datetime(last_entry.end_time)
              DateTime.diff(end_dt, start_dt, :second)
            else
              last_entry.end_time
            end
        end

        Logger.debug("Total planned duration: #{format_duration(total_duration)}")
        Logger.debug("Actions sequence:")

        Enum.each(timeline, fn entry ->
          start_time_str = if use_iso_format do
            format_iso_time(entry.start_time)
          else
            format_time(entry.start_time)
          end

          end_time_str = if use_iso_format do
            format_iso_time(entry.end_time)
          else
            format_time(entry.end_time)
          end

          Logger.debug("  #{start_time_str} - #{end_time_str}: #{entry.action}(#{format_args(entry.args)}) [#{format_duration(entry.duration)}]")
        end)

        Logger.debug("=== END PLANNED TIMELINE ===")

      {:error, reason} ->
        Logger.debug("Failed to calculate planned timeline: #{inspect(reason)}")
    end

    :ok
  end

  @doc """
  Log timing information for individual action execution.

  Called during action execution to provide real-time timing logs.

  ## Parameters

  - `action_name` - Name of the action being executed
  - `args` - Action arguments
  - `planned_start_time` - When this action was planned to start
  - `actual_start_time` - When execution actually started
  - `planned_duration` - Expected duration from domain
  - `actual_duration` - Actual execution time (optional)

  ## Example

      AriaTemporalBlocks.TimeLogger.log_execution_timing(:pickup, ["block_a"], 0.0, 0.1, 2.0)
  """
  @spec log_execution_timing(action_name(), args(), timestamp(), timestamp(), duration(), duration() | nil) :: :ok
  def log_execution_timing(action_name, args, planned_start_time, actual_start_time, planned_duration, actual_duration \\ nil) do
    actual_end_time = actual_start_time + (actual_duration || planned_duration)
    timing_info = if actual_duration do
      " (actual: #{format_duration(actual_duration)})"
    else
      ""
    end

    Logger.debug("EXEC #{format_time(actual_start_time)} - #{format_time(actual_end_time)}: #{action_name}(#{format_args(args)}) [planned: #{format_duration(planned_duration)}#{timing_info}]")

    # Log timing deviation if significant
    time_deviation = abs(actual_start_time - planned_start_time)
    if time_deviation > 0.1 do
      Logger.debug("  ⚠ Timing deviation: #{format_duration(time_deviation)} from planned start")
    end

    :ok
  end

  @doc """
  Calculate the planned timeline from a solution tree and domain.

  Extracts primitive actions and calculates start/end times based on
  sequential execution and domain-specified durations.

  ## Parameters

  - `solution_tree` - The solution tree containing primitive actions
  - `domain` - The domain with action duration specifications

  ## Returns

  `{:ok, timeline}` with calculated timing information, or `{:error, reason}`.
  """
  @spec calculate_timeline(AriaEngineCore.Plan.solution_tree(), map()) :: {:ok, timeline()} | {:error, String.t()}
  def calculate_timeline(solution_tree, domain) do
    calculate_timeline(solution_tree, domain, [])
  end

  @doc """
  Calculate the planned timeline with options for scheduled start time.

  ## Parameters

  - `solution_tree` - The solution tree containing primitive actions
  - `domain` - The domain with action duration specifications
  - `opts` - Options including `:scheduled_start_time` for absolute scheduling

  ## Options

  - `:scheduled_start_time` - ISO 8601 datetime string for when execution should begin
  - `:use_iso_format` - Boolean to use ISO datetime formatting in output

  ## Returns

  `{:ok, timeline}` with calculated timing information, or `{:error, reason}`.
  """
  @spec calculate_timeline(AriaEngineCore.Plan.solution_tree(), map(), keyword()) :: {:ok, timeline()} | {:error, String.t()}
  def calculate_timeline(solution_tree, domain, opts) do
    scheduled_start_time = Keyword.get(opts, :scheduled_start_time)
    use_iso_format = Keyword.get(opts, :use_iso_format, false)

    try do
      # Extract primitive actions from solution tree
      primitive_actions = AriaEngineCore.Plan.get_primitive_actions_dfs(solution_tree)

      # Determine starting time
      {initial_time, time_format} = if scheduled_start_time do
        start_dt = parse_iso_datetime(scheduled_start_time)
        if use_iso_format do
          {start_dt, :iso_datetime}
        else
          # Convert to seconds since epoch for relative calculations
          {DateTime.to_unix(start_dt), :unix_seconds}
        end
      else
        {0.0, :relative_seconds}
      end

      # Calculate timeline with sequential execution
      {timeline, _} = Enum.reduce(primitive_actions, {[], initial_time}, fn {action_name, args}, {timeline_acc, current_time} ->
        duration = extract_action_duration(domain, action_name, args)

        {start_time, end_time} = case time_format do
          :iso_datetime ->
            # Calculate absolute datetimes
            start_dt = current_time
            end_dt = DateTime.add(start_dt, trunc(duration), :second)
            {DateTime.to_iso8601(start_dt), DateTime.to_iso8601(end_dt)}

          :unix_seconds ->
            # Unix timestamp with relative duration
            end_unix = current_time + duration
            {current_time, end_unix}

          :relative_seconds ->
            # Standard relative timing
            {current_time, current_time + duration}
        end

        entry = %{
          action: action_name,
          args: args,
          start_time: start_time,
          end_time: end_time,
          duration: duration
        }

        next_time = case time_format do
          :iso_datetime ->
            DateTime.add(current_time, trunc(duration), :second)
          _ ->
            current_time + duration
        end

        {[entry | timeline_acc], next_time}
      end)

      {:ok, Enum.reverse(timeline)}
    rescue
      e ->
        {:error, "Failed to calculate timeline: #{inspect(e)}"}
    end
  end

  @doc """
  Extract action duration from domain attributes.

  Parses ISO 8601 durations and handles special cases like parametric durations.

  ## Parameters

  - `domain` - The domain containing action specifications
  - `action_name` - Name of the action
  - `args` - Action arguments (used for parametric durations)

  ## Returns

  Duration in seconds as a float.
  """
  @spec extract_action_duration(map(), action_name(), args()) :: duration()
  def extract_action_duration(domain, action_name, args) do
    # Special handling for wait action - extract duration from args
    if ensure_atom(action_name) == :wait do
      extract_parametric_duration(args)
    else
      # Try to get duration from domain action attributes
      case get_action_duration_attribute(domain, action_name) do
        nil ->
          # No duration specified, use default
          1.0

        duration_spec when is_binary(duration_spec) ->
          # ISO 8601 duration string
          parse_iso8601_duration(duration_spec)

        duration when is_number(duration) ->
          # Numeric duration
          Float.round(duration / 1.0, 1)

        _ ->
          # Unknown format, use default
          1.0
      end
    end
  end

  # Private helper functions

  # Get duration attribute from domain action specs
  @spec get_action_duration_attribute(map(), action_name()) :: String.t() | :parameter | number() | nil
  defp get_action_duration_attribute(domain, action_name) do
    # Try to extract from AriaCore domain structure - actions are stored as strings
    action_key = to_string(action_name)
    case Map.get(domain, :actions, %{}) do
      actions when is_map(actions) ->
        case Map.get(actions, action_key, %{}) do
          %{metadata: %{duration: {:fixed, seconds}}} when is_number(seconds) ->
            # Convert seconds to float
            Float.round(seconds / 1.0, 1)
          %{metadata: %{duration: duration}} ->
            duration
          _ -> nil
        end
      _ -> nil
    end
  end

  # Parse ISO 8601 duration strings like "PT2S" -> 2.0
  @spec parse_iso8601_duration(String.t()) :: duration()
  defp parse_iso8601_duration("PT" <> rest) do
    parse_iso8601_time_part(rest, 0.0)
  end

  defp parse_iso8601_duration(other) do
    Logger.debug("Unknown duration format: #{other}, using default 1.0s")
    1.0
  end

  # Parse the time part of ISO 8601 duration
  @spec parse_iso8601_time_part(String.t(), duration()) :: duration()
  defp parse_iso8601_time_part("", acc), do: acc

  defp parse_iso8601_time_part(rest, acc) do
    case Regex.run(~r/^(\d+(?:\.\d+)?)([HMS])/, rest) do
      [match, value_str, unit] ->
        value = String.to_float(value_str)
        multiplier = case unit do
          "H" -> 3600.0  # hours
          "M" -> 60.0    # minutes
          "S" -> 1.0     # seconds
        end

        remaining = String.replace_prefix(rest, match, "")
        parse_iso8601_time_part(remaining, acc + (value * multiplier))

      nil ->
        Logger.debug("Could not parse duration time part: #{rest}")
        acc
    end
  end

  # Extract duration from parametric actions (e.g., wait action)
  @spec extract_parametric_duration(args()) :: duration()
  defp extract_parametric_duration([duration | _]) when is_number(duration) do
    Float.round(duration / 1.0, 1)
  end

  defp extract_parametric_duration(_) do
    Logger.debug("Could not extract parametric duration, using default 1.0s")
    1.0
  end

  # Ensure action name is an atom for map lookup
  @spec ensure_atom(action_name()) :: atom()
  defp ensure_atom(name) when is_atom(name), do: name
  defp ensure_atom(name) when is_binary(name), do: String.to_atom(name)
  defp ensure_atom(name), do: String.to_atom(to_string(name))

  # Format duration for display
  @spec format_duration(duration() | integer()) :: String.t()
  defp format_duration(duration) when is_integer(duration) do
    format_duration(duration / 1.0)
  end

  defp format_duration(duration) when duration < 60 do
    "#{Float.round(duration, 1)}s"
  end

  defp format_duration(duration) do
    minutes = div(trunc(duration), 60)
    seconds = Float.round(duration - (minutes * 60), 1)
    "#{minutes}m #{seconds}s"
  end

  # Format timestamp for display
  @spec format_time(timestamp()) :: String.t()
  defp format_time(time) do
    "t=#{Float.round(time, 1)}s"
  end

  # Format action arguments for display
  @spec format_args(args()) :: String.t()
  defp format_args(args) do
    args
    |> Enum.map(&inspect/1)
    |> Enum.join(", ")
  end

  # Parse ISO 8601 datetime string to DateTime struct
  @spec parse_iso_datetime(String.t()) :: DateTime.t()
  defp parse_iso_datetime(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, datetime, _offset} -> datetime
      {:error, reason} ->
        Logger.debug("Failed to parse ISO datetime '#{iso_string}': #{reason}")
        DateTime.utc_now()
    end
  end

  # Format ISO time - handles both ISO string and DateTime struct
  @spec format_iso_time(String.t() | DateTime.t()) :: String.t()
  defp format_iso_time(iso_string) when is_binary(iso_string) do
    iso_string
  end

  defp format_iso_time(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  defp format_iso_time(other) do
    # Fallback for unexpected types
    inspect(other)
  end
end
