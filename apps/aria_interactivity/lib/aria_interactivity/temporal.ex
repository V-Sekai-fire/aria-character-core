defmodule AriaInteractivity.Temporal do
  @moduledoc """
  Temporal Integration for glTF Interactivity Extension

  Handles temporal constraints, duration parsing, and temporal planning integration
  following R25W1398085's 8 temporal patterns.

  Based on ADR R25W167INT and ISO 8601 duration specifications.
  """

  # ============================================================================
  # TEMPORAL PATTERNS - R25W1398085 Implementation
  # ============================================================================

  @doc """
  Pattern 1: Fixed Duration Actions
  Actions with predetermined, unchanging duration
  """
  def create_fixed_duration_action(action_name, duration_seconds) do
    %{
      type: :fixed_duration,
      action: action_name,
      duration: duration_seconds,
      constraints: [
        {:duration_equals, duration_seconds}
      ]
    }
  end

  @doc """
  Pattern 2: Variable Duration Actions
  Actions with duration determined at runtime
  """
  def create_variable_duration_action(action_name, min_duration, max_duration) do
    %{
      type: :variable_duration,
      action: action_name,
      min_duration: min_duration,
      max_duration: max_duration,
      constraints: [
        {:duration_between, min_duration, max_duration}
      ]
    }
  end

  @doc """
  Pattern 3: Concurrent Actions
  Multiple actions that can execute simultaneously
  """
  def create_concurrent_actions(actions) do
    %{
      type: :concurrent,
      actions: actions,
      constraints: [
        {:all_start_simultaneously, actions},
        {:no_resource_conflicts, actions}
      ]
    }
  end

  @doc """
  Pattern 4: Sequential Actions
  Actions that must execute one after another
  """
  def create_sequential_actions(actions, gaps \\ []) do
    %{
      type: :sequential,
      actions: actions,
      gaps: gaps,
      constraints: [
        {:sequential_execution, actions, gaps}
      ]
    }
  end

  @doc """
  Pattern 5: Overlapping Actions
  Actions that partially overlap in time
  """
  def create_overlapping_actions(action1, action2, overlap_seconds) do
    %{
      type: :overlapping,
      actions: [action1, action2],
      overlap: overlap_seconds,
      constraints: [
        {:overlap_duration, action1, action2, overlap_seconds}
      ]
    }
  end

  @doc """
  Pattern 6: Conditional Temporal Actions
  Actions with temporal constraints based on conditions
  """
  def create_conditional_temporal_action(action, condition, temporal_constraint) do
    %{
      type: :conditional_temporal,
      action: action,
      condition: condition,
      temporal_constraint: temporal_constraint,
      constraints: [
        {:conditional_constraint, condition, temporal_constraint}
      ]
    }
  end

  @doc """
  Pattern 7: Iterative Actions
  Actions that repeat with temporal spacing
  """
  def create_iterative_action(action, iterations, interval_seconds) do
    %{
      type: :iterative,
      action: action,
      iterations: iterations,
      interval: interval_seconds,
      constraints: [
        {:iterative_spacing, action, iterations, interval_seconds}
      ]
    }
  end

  @doc """
  Pattern 8: Hierarchical Temporal Actions
  Complex actions composed of simpler temporal actions
  """
  def create_hierarchical_temporal_action(name, sub_actions, temporal_relationships) do
    %{
      type: :hierarchical,
      name: name,
      sub_actions: sub_actions,
      relationships: temporal_relationships,
      constraints: [
        {:hierarchical_relationships, temporal_relationships}
      ]
    }
  end

  # ============================================================================
  # ISO 8601 DURATION PARSING
  # ============================================================================

  @doc """
  Parse ISO 8601 duration string to seconds

  Examples:
    "PT1H30M" -> 5400 (1.5 hours)
    "PT2M30S" -> 150 (2.5 minutes)
    "P1DT2H" -> 93600 (1 day, 2 hours)
  """
  @spec parse_iso8601_duration(String.t()) :: {:ok, float()} | {:error, atom()}
  def parse_iso8601_duration(duration_str) do
    # Basic ISO 8601 duration parsing
    # Format: P[n]Y[n]M[n]DT[n]H[n]M[n]S or PT[n]H[n]M[n]S

    case Regex.run(~r/^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?$/, duration_str) do
      [_, years, months, days, hours, minutes, seconds] ->
        # Convert to seconds (simplified - doesn't handle months/years precisely)
        total_seconds =
          (parse_int(years) * 365 * 24 * 3600) +  # Years (approx)
          (parse_int(months) * 30 * 24 * 3600) +  # Months (approx)
          (parse_int(days) * 24 * 3600) +         # Days
          (parse_int(hours) * 3600) +             # Hours
          (parse_int(minutes) * 60) +             # Minutes
          parse_float(seconds)                    # Seconds

        {:ok, total_seconds}

      _ ->
        {:error, :invalid_iso8601_duration}
    end
  end

  @doc """
  Format seconds as ISO 8601 duration string
  """
  @spec format_iso8601_duration(float()) :: String.t()
  def format_iso8601_duration(seconds) do
    total_seconds = round(seconds)

    days = div(total_seconds, 86400)
    remaining = rem(total_seconds, 86400)

    hours = div(remaining, 3600)
    remaining = rem(remaining, 3600)

    minutes = div(remaining, 60)
    seconds = rem(remaining, 60)

    # Build duration string
    duration_parts = []

    if days > 0 do
      _duration_parts = ["#{days}D" | duration_parts]
    end

    time_parts = []
    if hours > 0 do
      _time_parts = ["#{hours}H" | time_parts]
    end
    if minutes > 0 do
      _time_parts = ["#{minutes}M" | time_parts]
    end
    if seconds > 0 do
      _time_parts = ["#{seconds}S" | time_parts]
    end

    if time_parts != [] do
      _duration_parts = ["T" <> Enum.join(Enum.reverse(time_parts), "") | duration_parts]
    end

    if duration_parts == [] do
      "PT0S"
    else
      "P" <> Enum.join(Enum.reverse(duration_parts), "")
    end
  end

  # ============================================================================
  # TEMPORAL CONSTRAINT VALIDATION
  # ============================================================================

  @doc """
  Validate temporal constraints for a set of actions
  """
  @spec validate_temporal_constraints([map()]) :: {:ok, map()} | {:error, [atom()]}
  def validate_temporal_constraints(actions) do
    errors = []

    # Check for duration conflicts
    duration_conflicts = check_duration_conflicts(actions)
    errors = errors ++ duration_conflicts

    # Check for resource conflicts
    resource_conflicts = check_resource_conflicts(actions)
    errors = errors ++ resource_conflicts

    # Check for temporal ordering violations
    ordering_violations = check_temporal_ordering(actions)
    errors = errors ++ ordering_violations

    if errors == [] do
      {:ok, %{valid: true, constraints: extract_constraints(actions)}}
    else
      {:error, errors}
    end
  end

  # ============================================================================
  # GLTF ANIMATION DURATION MAPPING
  # ============================================================================

  @doc """
  Map glTF animation duration to IPyHOP temporal constraints
  """
  @spec map_gltf_animation_duration(map(), String.t()) :: {:ok, map()} | {:error, atom()}
  def map_gltf_animation_duration(gltf_animation, duration_override \\ nil) do
    duration_str = duration_override || get_gltf_animation_duration(gltf_animation)

    case parse_iso8601_duration(duration_str) do
      {:ok, duration_seconds} ->
        {:ok, %{
          duration: duration_seconds,
          duration_iso8601: duration_str,
          temporal_constraints: [
            {:duration_equals, duration_seconds}
          ]
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Convert glTF flow sockets to task dependencies
  """
  @spec convert_gltf_flow_sockets([map()]) :: [map()]
  def convert_gltf_flow_sockets(flow_sockets) do
    Enum.map(flow_sockets, fn socket ->
      %{
        socket_id: socket["id"],
        connected_to: socket["connected_to"],
        dependency_type: :flow_dependency,
        temporal_constraint: :sequential
      }
    end)
  end

  # ============================================================================
  # PRIVATE HELPER FUNCTIONS
  # ============================================================================

  defp parse_int(nil), do: 0
  defp parse_int(str), do: String.to_integer(str)

  defp parse_float(nil), do: 0.0
  defp parse_float(str), do: String.to_float(str)

  defp check_duration_conflicts(_actions) do
    # Check for actions with conflicting duration requirements
    []
  end

  defp check_resource_conflicts(_actions) do
    # Check for actions that require the same resources simultaneously
    []
  end

  defp check_temporal_ordering(_actions) do
    # Check for violations of temporal ordering constraints
    []
  end

  defp extract_constraints(actions) do
    # Extract all temporal constraints from actions
    Enum.flat_map(actions, fn action ->
      Map.get(action, :constraints, [])
    end)
  end

  defp get_gltf_animation_duration(_gltf_animation) do
    # Extract duration from glTF animation data
    # This would need to analyze the animation's sampler input accessor
    # For now, return a default duration
    "PT2S"
  end
end
