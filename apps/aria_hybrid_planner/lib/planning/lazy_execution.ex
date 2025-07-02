# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

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
    {actions, final_state} =
      Enum.reduce(goals, {[], initial_state}, fn goal, {acc_actions, current_state} ->
        {:ok, goal_actions, new_state} = plan_single_goal(domain, current_state, goal, options)
        {acc_actions ++ goal_actions, new_state}
      end)

    {actions, final_state}
  end

  # Plan to achieve a single goal
  defp plan_single_goal(domain, state, goal, options) do
    case goal do
      {:action_tuple, action_name, args} ->
        Logger.debug("Executing action tuple: #{action_name} with args #{inspect(args)}")
        execute_action_tuple(domain, state, action_name, args, options)

      {subject, predicate, value} ->
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
  end

  # Execute an action tuple directly with validation
  defp execute_action_tuple(domain, state, action_name, args, options) do
    # Try to call the action function directly on the domain module
    case call_domain_action(domain, action_name, state, args) do
      {:ok, new_state} ->
        action_record = %{
          action: to_string(action_name),
          args: args,
          start_time: Map.get(options, :start_time, 0),
          duration: 1,
          cost: 1
        }
        {:ok, [action_record], new_state}

      {:error, reason} ->
        raise "Action precondition failed: #{reason}"

      _ ->
        raise "Unknown action: #{action_name}"
    end
  end

  # Call a domain action function
  defp call_domain_action(domain, action_name, state, args) do
    # Get the domain module - it could be a struct with a module field or the module itself
    domain_module = case domain do
      %{module: module} -> module
      module when is_atom(module) -> module
      _ -> AriaBlocksWorld.Domain  # Fallback for blocks world
    end

    # Try to call the action function
    if function_exported?(domain_module, action_name, 2) do
      apply(domain_module, action_name, [state, args])
    else
      {:error, :unknown_action}
    end
  end

  # Validate action preconditions
  defp validate_action_preconditions(action_def, state, args) do
    preconditions = Map.get(action_def, :preconditions, [])

    # Check each precondition
    Enum.reduce_while(preconditions, :ok, fn precond, _acc ->
      if check_precondition(precond, state, args) do
        {:cont, :ok}
      else
        {:halt, {:error, "Precondition failed: #{inspect(precond)}"}}
      end
    end)
  end

  # Check a single precondition
  defp check_precondition(precond, state, args) do
    case precond do
      {:clear, subject_index} when is_integer(subject_index) ->
        subject = Enum.at(args, subject_index)
        AriaState.RelationalState.get_fact(state, "clear", subject) == true

      {:on_table, subject_index} when is_integer(subject_index) ->
        subject = Enum.at(args, subject_index)
        AriaState.RelationalState.get_fact(state, "pos", subject) == "table"

      {:holding_nothing} ->
        AriaState.RelationalState.get_fact(state, "holding", "hand") == false

      {:holding, object_index} when is_integer(object_index) ->
        object = Enum.at(args, object_index)
        AriaState.RelationalState.get_fact(state, "holding", "hand") == object

      _ ->
        # Unknown precondition, assume it passes
        true
    end
  end

  # Execute a domain action
  defp execute_domain_action(action_def, state, args, _options) do
    effects = Map.get(action_def, :effects, [])

    # Apply all effects
    new_state = Enum.reduce(effects, state, fn effect, current_state ->
      apply_action_effect(effect, current_state, args)
    end)

    {:ok, new_state}
  end

  # Apply a single action effect
  defp apply_action_effect(effect, state, args) do
    case effect do
      {:set_fact, predicate, subject_index, value} when is_integer(subject_index) ->
        subject = Enum.at(args, subject_index)
        AriaState.RelationalState.set_fact(state, predicate, subject, value)

      {:set_fact, predicate, subject, value} ->
        AriaState.RelationalState.set_fact(state, predicate, subject, value)

      {:remove_fact, predicate, subject_index} when is_integer(subject_index) ->
        subject = Enum.at(args, subject_index)
        AriaState.RelationalState.remove_fact(state, predicate, subject)

      _ ->
        # Unknown effect, ignore
        state
    end
  end

  # Check if a goal is satisfied in the current state
  defp goal_satisfied?(state, {subject, predicate, value}) do
    AriaState.RelationalState.get_fact(state, predicate, subject) == value
  end

  # Generate actions to achieve a specific goal
  defp generate_actions_for_goal(_domain, state, {subject, predicate, value}, options) do
    base_time = Map.get(options, :start_time, 0)

    case predicate do
      "location" ->
        # Generate move action
        current_location = get_current_location(state, subject)

        if current_location != value do
          [
            %{
              action: "move",
              entity: subject,
              from: current_location,
              to: value,
              start_time: base_time,
              duration: calculate_move_duration(current_location, value),
              cost: calculate_move_cost(current_location, value)
            }
          ]
        else
          []
        end

      "has" ->
        # Generate pickup action
        [
          %{
            action: "pickup",
            entity: subject,
            object: value,
            start_time: base_time,
            duration: 2,
            cost: 1
          }
        ]

      "state" ->
        # Generate state change action
        [
          %{
            action: "change_state",
            entity: subject,
            new_state: value,
            start_time: base_time,
            duration: 1,
            cost: 1
          }
        ]

      _ ->
        # Generic action for unknown predicates
        [
          %{
            action: "achieve",
            entity: subject,
            predicate: predicate,
            value: value,
            start_time: base_time,
            duration: 3,
            cost: 2
          }
        ]
    end
  end

  # Get current location of an entity
  defp get_current_location(state, entity) do
    AriaState.RelationalState.get_fact(state, "location", entity) || "unknown"
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
        AriaState.RelationalState.set_fact(state, "location", entity, action.to)

      "pickup" ->
        AriaState.RelationalState.set_fact(state, "has", entity, action.object)

      "change_state" ->
        AriaState.RelationalState.set_fact(state, "state", entity, action.new_state)

      _ ->
        # For generic actions, just mark as completed
        AriaState.RelationalState.set_fact(state, action.predicate, entity, action.value)
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
