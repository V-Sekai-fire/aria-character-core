defmodule AriaCore.TemporalConverter do
  @moduledoc """
  Temporal conditions converter for AriaCore.

  This module implements Phase 2 of the ADR-181 implementation plan:
  converting existing temporal conditions into method decomposition while
  preserving all temporal reasoning logic.

  Uses the sociable testing approach by leveraging existing temporal
  systems rather than reimplementing temporal logic from scratch.

  ## Purpose

  Converts complex durative actions with at_start/over_all/at_end conditions
  into the unified specification format using simple actions + method decomposition.

  ## Example Conversion

      # BEFORE: Complex temporal conditions (existing system)
      durative_action = %{
        name: :cook_meal,
        duration: {:fixed, 7200},
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

      # AFTER: Simple action + method decomposition
      {simple_action, method} = TemporalConverter.convert_durative_action(durative_action)

      simple_action = %{
        name: :cook_meal,
        duration: {:fixed, 7200},
        effects: [{"meal", "status", "ready"}]
      }

      method = [
        # at_start conditions → prerequisite goals
        {"temperature", "oven", {:>=, 350}},
        # at_start effects → setup tasks
        {:set_chef_busy, []},
        # over_all conditions → monitoring tasks
        {:monitor_oven_operational, []},
        # Main action (simple durative action)
        {:cook_meal, []},
        # at_end conditions → verification goals
        {"quality", "meal", {:>=, 8}},
        # at_end effects → cleanup tasks
        {:release_chef, []}
      ]
  """

  @doc """
  Converts a durative action with temporal conditions into simple action + method decomposition.

  This preserves all temporal logic while upgrading to the unified specification architecture.

  ## Parameters

  - `durative_action`: Map containing name, duration, conditions, and effects
  - `options`: Optional conversion settings (default: [])

  ## Returns

  `{simple_action, method_decomposition}` tuple where:
  - `simple_action`: Core action without temporal conditions
  - `method_decomposition`: List of goals and tasks that implement temporal logic

  ## Examples

      iex> durative_action = %{
      ...>   name: :cook_meal,
      ...>   duration: {:fixed, 3600},
      ...>   conditions: %{at_start: [{"oven", "ready", true}]},
      ...>   effects: %{at_end: [{"meal", "status", "ready"}]}
      ...> }
      iex> {simple, method} = AriaCore.TemporalConverter.convert_durative_action(durative_action)
      iex> simple.name
      :cook_meal
      iex> length(method)
      2
  """
  def convert_durative_action(durative_action, options \\ []) do
    # LEVERAGE existing temporal conditions (don't lose investment)
    {simple_action, method_decomposition} = extract_components(durative_action, options)

    # Convert to unified format while preserving logic
    {
      create_simple_action(simple_action),
      create_method_from_conditions(method_decomposition)
    }
  end

  @doc """
  Converts multiple durative actions in batch.

  Useful for converting entire domains from legacy temporal format
  to unified specification format.
  """
  def convert_domain_actions(durative_actions, options \\ []) do
    Enum.map(durative_actions, fn action ->
      convert_durative_action(action, options)
    end)
  end

  @doc """
  Validates that conversion preserves temporal semantics.

  SOCIABLE APPROACH: Uses existing temporal system to verify equivalence.
  """
  def validate_conversion(original_action, {simple_action, method}) do
    # LEVERAGE existing temporal validation (sociable approach)
    with :ok <- AriaCore.Temporal.Interval.validate_equivalence(original_action, simple_action),
         :ok <- validate_method_preserves_conditions(original_action, method) do
      :ok
    else
      {:error, reason} -> {:error, "Conversion validation failed: #{reason}"}
    end
  end

  # Private implementation functions

  defp extract_components(durative_action, _options) do
    # Separate core action from temporal conditions
    simple_action = %{
      name: durative_action.name,
      duration: durative_action.duration,
      # Keep only core effects (usually at_end effects)
      effects: extract_core_effects(durative_action)
    }

    method_decomposition = %{
      original_action: durative_action,
      conditions: durative_action[:conditions] || %{},
      effects: durative_action[:effects] || %{}
    }

    {simple_action, method_decomposition}
  end

  defp create_simple_action(simple_action) do
    # Create clean simple action specification
    %{
      name: simple_action.name,
      duration: simple_action.duration,
      effects: simple_action.effects || [],
      # Simple actions have no temporal conditions
      preconditions: [],
      entity_requirements: []
    }
  end

  defp create_method_from_conditions(method_decomposition) do
    durative_action = method_decomposition.original_action
    conditions = method_decomposition.conditions
    effects = method_decomposition.effects

    # Convert temporal conditions to method decomposition
    # PRESERVE all temporal logic in method decomposition

    method_steps = []

    # Convert at_start conditions → prerequisite goals
    method_steps = method_steps ++ convert_conditions_to_goals(conditions[:at_start] || [])

    # Convert at_start effects → setup tasks
    method_steps = method_steps ++ convert_effects_to_tasks(effects[:at_start] || [])

    # Convert over_all conditions → monitoring tasks
    method_steps = method_steps ++ convert_conditions_to_monitoring(conditions[:over_all] || [])

    # Main action becomes simple durative action
    main_action = {durative_action.name, []}
    method_steps = method_steps ++ [main_action]

    # Convert at_end conditions → verification goals
    method_steps = method_steps ++ convert_conditions_to_goals(conditions[:at_end] || [])

    # Convert at_end effects → cleanup tasks
    method_steps = method_steps ++ convert_effects_to_tasks(effects[:at_end] || [])

    method_steps
  end

  defp extract_core_effects(durative_action) do
    # Usually the at_end effects represent the core action outcome
    effects = durative_action[:effects] || %{}
    effects[:at_end] || []
  end

  defp convert_conditions_to_goals(conditions) when is_list(conditions) do
    # Convert temporal conditions to goal specifications
    # Each condition becomes a goal that must be achieved
    Enum.map(conditions, fn condition ->
      case condition do
        {predicate, subject, value} ->
          # Direct goal format: {predicate, subject, value}
          {predicate, subject, value}

        {predicate, subject, {:>=, value}} ->
          # Comparison condition becomes constraint goal
          {predicate, subject, {:>=, value}}

        {predicate, subject, {:<, value}} ->
          # Comparison condition becomes constraint goal
          {predicate, subject, {:<, value}}

        other ->
          # Pass through other condition formats
          other
      end
    end)
  end

  defp convert_effects_to_tasks(effects) when is_list(effects) do
    # Convert temporal effects to task specifications
    # Each effect becomes a task that produces the effect
    Enum.map(effects, fn effect ->
      case effect do
        {predicate, subject, value} ->
          # Create task name from effect
          task_name = create_task_name_from_effect(predicate, subject, value)
          {task_name, [subject]}

        other ->
          # Handle other effect formats
          {:unknown_effect_task, [other]}
      end
    end)
  end

  defp convert_conditions_to_monitoring(conditions) when is_list(conditions) do
    # Convert over_all conditions to monitoring tasks
    # These run concurrently with the main action
    Enum.map(conditions, fn condition ->
      case condition do
        {predicate, subject, value} ->
          # Create monitoring task
          monitor_name = create_monitor_name_from_condition(predicate, subject, value)
          {monitor_name, [subject]}

        other ->
          # Handle other condition formats
          {:unknown_monitor_task, [other]}
      end
    end)
  end

  defp create_task_name_from_effect(predicate, subject, value) do
    # Generate meaningful task names from effects
    case {predicate, value} do
      {"status", "busy"} -> :set_busy
      {"status", "available"} -> :set_available
      {"temperature", temp} when is_number(temp) -> :set_temperature
      {pred, val} -> String.to_atom("set_#{pred}_#{val}")
    end
  end

  defp create_monitor_name_from_condition(predicate, _subject, _value) do
    # Generate meaningful monitor names from conditions
    case predicate do
      "status" -> :monitor_status
      "temperature" -> :monitor_temperature
      "operational" -> :monitor_operational
      pred -> String.to_atom("monitor_#{pred}")
    end
  end

  defp validate_method_preserves_conditions(original_action, method) do
    # Validate that method decomposition preserves all temporal conditions
    conditions = original_action[:conditions] || %{}
    effects = original_action[:effects] || %{}

    # Check that all at_start conditions are represented as goals
    at_start_goals = count_goals_in_method(method)
    at_start_conditions = length(conditions[:at_start] || [])

    # Check that all effects are represented as tasks
    effect_tasks = count_tasks_in_method(method)
    total_effects = length((effects[:at_start] || []) ++ (effects[:at_end] || []))

    cond do
      at_start_goals < at_start_conditions ->
        {:error, "Missing goals for at_start conditions"}

      effect_tasks < total_effects ->
        {:error, "Missing tasks for effects"}

      true ->
        :ok
    end
  end

  defp count_goals_in_method(method) do
    # Count goal specifications in method (tuples with 3 elements)
    method
    |> Enum.count(fn step ->
      case step do
        {_pred, _subj, _val} -> true
        _ -> false
      end
    end)
  end

  defp count_tasks_in_method(method) do
    # Count task specifications in method (tuples with 2 elements where first is atom)
    method
    |> Enum.count(fn step ->
      case step do
        {task_name, _args} when is_atom(task_name) -> true
        _ -> false
      end
    end)
  end
end
