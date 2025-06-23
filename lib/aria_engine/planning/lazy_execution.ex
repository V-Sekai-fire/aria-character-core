defmodule AriaEngine.Planning.LazyExecution do
  @moduledoc """
  Simple lazy execution planning strategy.

  This module provides a basic planning approach that generates plans
  by lazily executing actions to achieve goals without complex optimization.
  """

  require Logger

  @doc """
  Generate a plan using lazy execution strategy.

  ## Parameters
  - `domain` - The planning domain
  - `state` - Current state
  - `goals` - List of goals in {subject, predicate, value} format
  - `options` - Planning options

  ## Returns
  - `{:ok, plan}` - Successfully generated plan
  - `{:error, reason}` - Failed to generate plan
  """
  def plan(domain, state, goals, options \\ %{}) do
    try do
      Logger.debug("Starting lazy execution planning for #{length(goals)} goals")

      # Simple goal-by-goal planning
      {actions, final_state} = plan_goals_sequentially(domain, state, goals, options)

      # Calculate plan metrics
      total_time = calculate_total_time(actions)
      total_cost = calculate_total_cost(actions)

      plan = %{
        actions: actions,
        final_state: final_state,
        metrics: %{
          total_actions: length(actions),
          total_time: total_time,
          total_cost: total_cost,
          planning_time: System.monotonic_time(:millisecond)
        },
        strategy: :lazy_execution,
        success: true
      }

      Logger.debug("Lazy execution completed with #{length(actions)} actions")
      {:ok, plan}
    rescue
      error ->
        Logger.error("Lazy execution planning failed: #{inspect(error)}")
        {:error, "Planning failed: #{Exception.message(error)}"}
    end
  end

  # Plan goals one by one in sequence
  defp plan_goals_sequentially(domain, initial_state, goals, options) do
    {actions, final_state} = Enum.reduce(goals, {[], initial_state}, fn goal, {acc_actions, current_state} ->
      case plan_single_goal(domain, current_state, goal, options) do
        {:ok, goal_actions, new_state} ->
          {acc_actions ++ goal_actions, new_state}
        {:error, _reason} ->
          # If we can't achieve a goal, continue with others
          {acc_actions, current_state}
      end
    end)

    {actions, final_state}
  end

  # Plan to achieve a single goal
  defp plan_single_goal(domain, state, {subject, predicate, value}, options) do
    Logger.debug("Planning for goal: #{subject} #{predicate} #{value}")

    # Check if goal is already satisfied
    if goal_satisfied?(state, {subject, predicate, value}) do
      {:ok, [], state}
    else
      # Generate actions to achieve the goal
      actions = generate_actions_for_goal(domain, state, {subject, predicate, value}, options)
      new_state = apply_actions_to_state(state, actions)
      {:ok, actions, new_state}
    end
  end

  # Check if a goal is satisfied in the current state
  defp goal_satisfied?(state, {subject, predicate, value}) do
    case Map.get(state, subject) do
      nil -> false
      entity_state ->
        Map.get(entity_state, predicate) == value
    end
  end

  # Generate actions to achieve a specific goal
  defp generate_actions_for_goal(domain, state, {subject, predicate, value}, options) do
    base_time = Map.get(options, :start_time, 0)

    case predicate do
      "location" ->
        # Generate move action
        current_location = get_current_location(state, subject)
        if current_location != value do
          [%{
            action: "move",
            entity: subject,
            from: current_location,
            to: value,
            start_time: base_time,
            duration: calculate_move_duration(current_location, value),
            cost: calculate_move_cost(current_location, value)
          }]
        else
          []
        end

      "has" ->
        # Generate pickup action
        [%{
          action: "pickup",
          entity: subject,
          object: value,
          start_time: base_time,
          duration: 2,
          cost: 1
        }]

      "state" ->
        # Generate state change action
        [%{
          action: "change_state",
          entity: subject,
          new_state: value,
          start_time: base_time,
          duration: 1,
          cost: 1
        }]

      _ ->
        # Generic action for unknown predicates
        [%{
          action: "achieve",
          entity: subject,
          predicate: predicate,
          value: value,
          start_time: base_time,
          duration: 3,
          cost: 2
        }]
    end
  end

  # Get current location of an entity
  defp get_current_location(state, entity) do
    case Map.get(state, entity) do
      nil -> "unknown"
      entity_state -> Map.get(entity_state, "location", "unknown")
    end
  end

  # Calculate duration for move action
  defp calculate_move_duration(from, to) do
    # Simple distance-based calculation
    cond do
      from == to -> 0
      from == "unknown" or to == "unknown" -> 5
      true -> 3 + :rand.uniform(3)
    end
  end

  # Calculate cost for move action
  defp calculate_move_cost(from, to) do
    # Simple cost calculation
    cond do
      from == to -> 0
      from == "unknown" or to == "unknown" -> 3
      true -> 1 + :rand.uniform(2)
    end
  end

  # Apply actions to state to get new state
  defp apply_actions_to_state(state, actions) do
    Enum.reduce(actions, state, fn action, current_state ->
      apply_single_action(current_state, action)
    end)
  end

  # Apply a single action to state
  defp apply_single_action(state, action) do
    entity = action.entity

    case action.action do
      "move" ->
        put_in(state, [entity, "location"], action.to)

      "pickup" ->
        put_in(state, [entity, "has"], action.object)

      "change_state" ->
        put_in(state, [entity, "state"], action.new_state)

      _ ->
        # For generic actions, just mark as completed
        put_in(state, [entity, action.predicate], action.value)
    end
  end

  # Calculate total execution time
  defp calculate_total_time(actions) do
    if length(actions) == 0 do
      0
    else
      Enum.map(actions, fn action ->
        action.start_time + action.duration
      end)
      |> Enum.max()
    end
  end

  # Calculate total cost
  defp calculate_total_cost(actions) do
    Enum.sum(Enum.map(actions, & &1.cost))
  end

  @doc """
  Validate if lazy execution can handle the given goals.

  ## Parameters
  - `goals` - List of goals to validate

  ## Returns
  - `:ok` - Goals can be handled
  - `{:error, reason}` - Goals cannot be handled
  """
  def validate_goals(goals) when is_list(goals) do
    if length(goals) > 20 do
      {:error, "Too many goals for lazy execution (max 20)"}
    else
      :ok
    end
  end
  def validate_goals(_), do: {:error, "Goals must be a list"}
end
