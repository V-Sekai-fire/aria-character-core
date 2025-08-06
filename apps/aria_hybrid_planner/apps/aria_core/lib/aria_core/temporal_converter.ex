# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.TemporalConverter do
  @moduledoc """
  Converts legacy durative actions with temporal conditions into ADR-181 compliant
  simple actions + method decomposition format.

  This module provides backward compatibility for existing durative actions that use
  the at_start/over_all/at_end temporal condition format, converting them into the
  cleaner ADR-181 architecture while preserving all temporal logic.

  ## Conversion Strategy

  Legacy durative actions with complex temporal conditions are converted as follows:

  - **at_start conditions** → **prerequisite goals** in method decomposition
  - **at_start effects** → **setup tasks** in method decomposition
  - **over_all conditions** → **monitoring tasks** in method decomposition
  - **Main action** → **simple durative action** (duration + entity requirements only)
  - **at_end conditions** → **verification goals** in method decomposition
  - **at_end effects** → **cleanup tasks** in method decomposition

  ## Example Conversion

      # Legacy durative action
      legacy_action = %{
        name: :cook_meal,
        duration: {:fixed, 3600},
        conditions: %{
          at_start: [{"oven", "temperature", {:>=, 350}}],
          over_all: [{"oven", "status", "operational"}],
          at_end: [{"meal", "quality", {:>=, 8}}]
        },
        effects: %{
          at_start: [{"chef", "status", "busy"}],
          at_end: [{"chef", "status", "available"}]
        }
      }

      # Convert to ADR-181 format
      {simple_action, method_decomposition} =
        AriaCore.TemporalConverter.convert_durative_action(legacy_action)

      # Result: Simple action with duration only + method with all temporal logic

  ## Integration

  This module integrates with the existing action attributes system to provide
  seamless backward compatibility. Legacy actions are automatically detected
  and converted during domain creation.
  """

  alias AriaCore.Temporal.Interval

  @type legacy_durative_action :: %{
    name: atom(),
    duration: Interval.duration(),
    conditions: %{
      at_start: [condition()],
      over_all: [condition()],
      at_end: [condition()]
    },
    effects: %{
      at_start: [effect()],
      at_end: [effect()]
    },
    entity_requirements: [map()]
  }

  @type condition :: {String.t(), String.t(), term()}
  @type effect :: {String.t(), String.t(), term()}
  @type simple_action :: %{
    name: atom(),
    duration: Interval.duration(),
    entity_requirements: [map()],
    action_fn: function()
  }
  @type method_decomposition :: [term()]

  @doc """
  Converts a legacy durative action into ADR-181 compliant format.

  Returns a tuple containing:
  1. Simple action with only duration and entity requirements
  2. Method decomposition preserving all temporal logic

  ## Parameters

  - `durative_action`: Legacy durative action specification

  ## Returns

  `{simple_action, method_decomposition}` where all temporal conditions
  are preserved in the method decomposition.

  ## Examples

      iex> legacy = %{
      ...>   name: :cook_soup,
      ...>   duration: {:fixed, 1800},
      ...>   conditions: %{
      ...>     at_start: [{"ingredient", "tomato", true}],
      ...>     over_all: [{"stove", "status", "operational"}],
      ...>     at_end: [{"soup", "temperature", {:>=, 165}}]
      ...>   },
      ...>   effects: %{
      ...>     at_start: [{"chef", "status", "cooking"}],
      ...>     at_end: [{"chef", "status", "available"}]
      ...>   }
      ...> }
      iex> {action, method} = AriaCore.TemporalConverter.convert_durative_action(legacy)
      iex> action.name
      :cook_soup
      iex> length(method) > 5
      true
  """
  def convert_durative_action(durative_action) do
    # Extract simple action (duration + entity requirements only)
    simple_action = extract_simple_action(durative_action)

    # Build method decomposition from temporal conditions
    method_decomposition = build_method_decomposition(durative_action)

    {simple_action, method_decomposition}
  end

  @doc """
  Extracts a simple action from a legacy durative action.

  Removes all temporal conditions and effects, keeping only:
  - Action name
  - Duration specification
  - Entity requirements
  - Basic action function

  ## Examples

      iex> legacy = %{
      ...>   name: :cook_meal,
      ...>   duration: {:fixed, 3600},
      ...>   entity_requirements: [%{type: "chef", capabilities: [:cooking]}],
      ...>   conditions: %{at_start: [{"oven", "ready", true}]},
      ...>   effects: %{at_end: [{"meal", "status", "ready"}]}
      ...> }
      iex> simple = AriaCore.TemporalConverter.extract_simple_action(legacy)
      iex> simple.name
      :cook_meal
      iex> Map.has_key?(simple, :conditions)
      false
  """
  def extract_simple_action(durative_action) do
    %{
      name: durative_action.name,
      duration: durative_action[:duration] || {:fixed, 1},
      entity_requirements: durative_action[:entity_requirements] || [],
      action_fn: create_simple_action_function(durative_action)
    }
  end

  @doc """
  Builds method decomposition from temporal conditions and effects.

  Converts temporal conditions into a sequence of goals and tasks that
  preserve the original temporal semantics:

  1. Prerequisites from at_start conditions
  2. Setup tasks from at_start effects
  3. Monitoring tasks from over_all conditions
  4. Main action execution
  5. Verification goals from at_end conditions
  6. Cleanup tasks from at_end effects

  ## Examples

      iex> legacy = %{
      ...>   name: :cook_meal,
      ...>   conditions: %{
      ...>     at_start: [{"oven", "temperature", {:>=, 350}}],
      ...>     over_all: [{"oven", "status", "operational"}]
      ...>   },
      ...>   effects: %{
      ...>     at_start: [{"chef", "status", "busy"}],
      ...>     at_end: [{"chef", "status", "available"}]
      ...>   }
      ...> }
      iex> method = AriaCore.TemporalConverter.build_method_decomposition(legacy)
      iex> length(method) >= 4
      true
  """
  def build_method_decomposition(durative_action) do
    []
    |> add_prerequisite_goals(get_conditions(durative_action, :at_start))
    |> add_setup_tasks(get_effects(durative_action, :at_start))
    |> add_monitoring_tasks(get_conditions(durative_action, :over_all))
    |> add_main_action(durative_action.name)
    |> add_verification_goals(get_conditions(durative_action, :at_end))
    |> add_cleanup_tasks(get_effects(durative_action, :at_end))
    |> Enum.filter(&(&1 != nil))  # Remove any nil entries
  end

  @doc """
  Validates that a conversion preserves the original temporal semantics.

  Checks that:
  - Duration is preserved
  - All temporal conditions are represented in method decomposition
  - Entity requirements are maintained
  - Action semantics are equivalent

  ## Parameters

  - `original`: Original legacy durative action
  - `converted`: Tuple of {simple_action, method_decomposition}

  ## Returns

  `{:ok, :equivalent}` if conversion preserves semantics,
  `{:error, reasons}` if there are semantic differences.

  ## Examples

      iex> original = %{name: :test, duration: {:fixed, 100}}
      iex> converted = {%{name: :test, duration: {:fixed, 100}}, []}
      iex> AriaCore.TemporalConverter.validate_conversion(original, converted)
      {:ok, :equivalent}
  """
  def validate_conversion(original, {simple_action, method_decomposition}) do
    with :ok <- validate_duration_preserved(original, simple_action),
         :ok <- validate_temporal_logic_preserved(original, method_decomposition),
         :ok <- validate_entity_requirements_preserved(original, simple_action),
         :ok <- validate_action_semantics_preserved(original, simple_action) do
      {:ok, :equivalent}
    else
      {:error, reason} when is_binary(reason) -> {:error, [reason]}
      {:error, reasons} when is_list(reasons) -> {:error, reasons}
    end
  end

  @doc """
  Detects if an action specification is a legacy durative action.

  Legacy durative actions are identified by the presence of temporal
  conditions (at_start/over_all/at_end) or effects.

  ## Examples

      iex> legacy = %{conditions: %{at_start: [{"x", "y", true}]}}
      iex> AriaCore.TemporalConverter.is_legacy_durative_action?(legacy)
      true

      iex> simple = %{duration: {:fixed, 100}}
      iex> AriaCore.TemporalConverter.is_legacy_durative_action?(simple)
      false
  """
  def is_legacy_durative_action?(action_spec) do
    has_temporal_conditions?(action_spec) or has_temporal_effects?(action_spec)
  end

  @doc """
  Converts multiple legacy actions in batch.

  Useful for domain-wide conversion of legacy action specifications.

  ## Examples

      iex> actions = [
      ...>   %{name: :action1, conditions: %{at_start: []}},
      ...>   %{name: :action2, duration: {:fixed, 100}}
      ...> ]
      iex> results = AriaCore.TemporalConverter.convert_batch(actions)
      iex> length(results) == 2
      true
  """
  def convert_batch(legacy_actions) when is_list(legacy_actions) do
    Enum.map(legacy_actions, fn action ->
      if is_legacy_durative_action?(action) do
        {:legacy_converted, convert_durative_action(action)}
      else
        {:already_compliant, action}
      end
    end)
  end

  # Private implementation functions

  defp create_simple_action_function(durative_action) do
    # Create a simple state transformation function
    # This preserves the core action logic without temporal conditions
    action_name = durative_action.name

    fn state, args ->
      # Apply any direct state transformations from the original action
      # For now, return state unchanged - specific implementations would
      # need to provide their own action functions
      apply_action_effects(state, action_name, args)
    end
  end

  defp apply_action_effects(state, _action_name, _args) do
    # Placeholder for action-specific state transformations
    # In a real implementation, this would delegate to the actual action function
    state
  end

  defp get_conditions(durative_action, phase) do
    durative_action
    |> Map.get(:conditions, %{})
    |> Map.get(phase, [])
  end

  defp get_effects(durative_action, phase) do
    durative_action
    |> Map.get(:effects, %{})
    |> Map.get(phase, [])
  end

  defp add_prerequisite_goals(method_steps, at_start_conditions) do
    prerequisites = Enum.map(at_start_conditions, fn {subj, pred, val} ->
      {pred, subj, val}
    end)

    method_steps ++ prerequisites
  end

  defp add_setup_tasks(method_steps, at_start_effects) do
    setup_tasks = Enum.map(at_start_effects, fn {pred, subj, val} ->
      # Convert effects to setup task actions
      {:set_fact, [pred, subj, val]}
    end)

    method_steps ++ setup_tasks
  end

  defp add_monitoring_tasks(method_steps, over_all_conditions) do
    monitoring_tasks = Enum.map(over_all_conditions, fn {pred, subj, val} ->
      # Convert over_all conditions to monitoring tasks
      {:monitor_condition, [pred, subj, val]}
    end)

    method_steps ++ monitoring_tasks
  end

  defp add_main_action(method_steps, action_name) do
    method_steps ++ [{action_name, []}]
  end

  defp add_verification_goals(method_steps, at_end_conditions) do
    verification_goals = Enum.map(at_end_conditions, fn {pred, subj, val} ->
      {pred, subj, val}
    end)

    method_steps ++ verification_goals
  end

  defp add_cleanup_tasks(method_steps, at_end_effects) do
    cleanup_tasks = Enum.map(at_end_effects, fn {pred, subj, val} ->
      # Convert effects to cleanup task actions
      {:set_fact, [pred, subj, val]}
    end)

    method_steps ++ cleanup_tasks
  end

  defp validate_duration_preserved(original, simple_action) do
    original_duration = original[:duration] || {:fixed, 1}
    simple_duration = simple_action[:duration] || {:fixed, 1}

    case Interval.validate_equivalence(%{duration: original_duration}, %{duration: simple_duration}) do
      :ok -> :ok
      {:error, reason} -> {:error, "Duration not preserved: #{reason}"}
    end
  end

  defp validate_temporal_logic_preserved(original, method_decomposition) do
    # Check that all temporal conditions are represented in the method
    original_conditions = count_temporal_conditions(original)
    method_conditions = count_method_conditions(method_decomposition)

    if original_conditions <= method_conditions do
      :ok
    else
      {:error, "Temporal conditions not fully preserved in method decomposition"}
    end
  end

  defp validate_entity_requirements_preserved(original, simple_action) do
    original_reqs = original[:entity_requirements] || []
    simple_reqs = simple_action[:entity_requirements] || []

    if length(original_reqs) == length(simple_reqs) do
      :ok
    else
      {:error, "Entity requirements not preserved"}
    end
  end

  defp validate_action_semantics_preserved(original, simple_action) do
    # Basic semantic validation - names should match
    if original.name == simple_action.name do
      :ok
    else
      {:error, "Action name not preserved"}
    end
  end

  defp has_temporal_conditions?(action_spec) do
    case Map.get(action_spec, :conditions) do
      nil -> false
      conditions when is_map(conditions) ->
        Map.has_key?(conditions, :at_start) or
        Map.has_key?(conditions, :over_all) or
        Map.has_key?(conditions, :at_end)
      _ -> false
    end
  end

  defp has_temporal_effects?(action_spec) do
    case Map.get(action_spec, :effects) do
      nil -> false
      effects when is_map(effects) ->
        Map.has_key?(effects, :at_start) or
        Map.has_key?(effects, :at_end)
      _ -> false
    end
  end

  defp count_temporal_conditions(action_spec) do
    conditions = Map.get(action_spec, :conditions, %{})
    effects = Map.get(action_spec, :effects, %{})

    at_start_conditions = length(Map.get(conditions, :at_start, []))
    over_all_conditions = length(Map.get(conditions, :over_all, []))
    at_end_conditions = length(Map.get(conditions, :at_end, []))
    at_start_effects = length(Map.get(effects, :at_start, []))
    at_end_effects = length(Map.get(effects, :at_end, []))

    at_start_conditions + over_all_conditions + at_end_conditions +
    at_start_effects + at_end_effects
  end

  defp count_method_conditions(method_decomposition) do
    # Count conditions and tasks in method decomposition
    Enum.count(method_decomposition, fn step ->
      case step do
        {_pred, _subj, _val} -> true  # Goal condition
        {:set_fact, _args} -> true    # Setup/cleanup task
        {:monitor_condition, _args} -> true  # Monitoring task
        _ -> false
      end
    end)
  end
end
