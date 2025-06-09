# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan do
  @moduledoc """
  The main GTPyhop planning algorithm implementation.

  This module contains the core planning logic that finds sequences of actions
  to achieve goals through hierarchical task decomposition.

  Example:
  ```elixir
  # Create domain with actions and methods
  domain = AriaEngine.Domain.new("example")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)

  # Create initial state
  initial_state = AriaEngine.State.new()
  |> AriaEngine.State.set_object("location", "robot", "room1")

  # Create goals
  goals = [{"location", "robot", "room2"}]

  # Plan
  case AriaEngine.Plan.plan(domain, initial_state, goals) do
    {:ok, result_plan} -> IO.puts("Found plan: \#{inspect(result_plan)}")
    {:error, reason} -> IO.puts("Planning failed: \#{reason}")
  end
  ```
  """

  alias AriaEngine.{Domain, State, Multigoal}

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), any()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type plan_result :: {:ok, [plan_step()]} | {:error, String.t()}

  @default_max_depth 100
  @default_verbose 0

  @doc """
  Main planning function that finds a plan to achieve the given todos.

  ## Parameters
  - `domain`: The planning domain containing actions and methods
  - `state`: The initial world state
  - `todos`: List of goals, tasks, or multigoals to achieve
  - `options`: Planning options (max_depth, verbose, etc.)

  ## Returns
  - `{:ok, plan}`: A list of action steps that achieve the goals
  - `{:error, reason}`: Planning failure reason
  """
  @spec plan(Domain.t(), State.t(), [todo_item()], keyword()) :: plan_result()
  def plan(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    if verbose > 0 do
      IO.puts("Starting planning with #{length(todos)} todos")
    end

    case find_plan(domain, state, todos, [], 0, max_depth, verbose) do
      {:ok, plan} ->
        if verbose > 0 do
          IO.puts("Planning succeeded with #{length(plan)} steps")
        end
        {:ok, Enum.reverse(plan)}
      {:error, _} = error -> error
    end
  end

  # Internal recursive planning function
  @spec find_plan(Domain.t(), State.t(), [todo_item()], [plan_step()], integer(), integer(), integer()) :: plan_result()
  defp find_plan(_domain, _state, [], plan, _depth, _max_depth, _verbose) do
    # No more todos - planning succeeded
    {:ok, plan}
  end

  defp find_plan(_domain, _state, _todos, _plan, depth, max_depth, _verbose) when depth >= max_depth do
    {:error, "Maximum planning depth exceeded"}
  end

  defp find_plan(%Domain{} = domain, %State{} = state, [todo | rest_todos], plan, depth, max_depth, verbose) do
    if verbose > 1 do
      IO.puts("#{String.duplicate("  ", depth)}Processing todo: #{inspect(todo)}")
    end

    case process_todo(domain, state, todo, depth, verbose) do
      {:ok, new_state, new_todos} ->
        # Continue planning with updated state and todos
        combined_todos = new_todos ++ rest_todos
        find_plan(domain, new_state, combined_todos, plan, depth + 1, max_depth, verbose)

      {:action, action_name, args, new_state} ->
        # Execute action and continue
        action_step = {action_name, args}
        find_plan(domain, new_state, rest_todos, [action_step | plan], depth + 1, max_depth, verbose)

      {:error, _} = error ->
        error
    end
  end

  # Process a single todo item
  @spec process_todo(Domain.t(), State.t(), todo_item(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} |
    {:action, atom(), list(), State.t()} |
    {:error, String.t()}
  defp process_todo(%Domain{} = domain, %State{} = state, todo, depth, verbose) do
    case todo do
      # Handle task decomposition
      {task_name, args} when is_binary(task_name) ->
        process_task(domain, state, task_name, args, depth, verbose)

      # Handle action tuple with atom name
      {action_name, args} when is_atom(action_name) ->
        process_action(domain, state, action_name, args, depth, verbose)

      # Handle single goal
      {predicate, subject, object} ->
        process_goal(domain, state, predicate, subject, object, depth, verbose)

      # Handle multigoal
      %Multigoal{} = multigoal ->
        process_multigoal(domain, state, multigoal, depth, verbose)

      # Handle action (if it's actually an action reference)
      action_name when is_atom(action_name) ->
        process_action(domain, state, action_name, [], depth, verbose)

      _ ->
        {:error, "Unknown todo type: #{inspect(todo)}"}
    end
  end

  # Process a task by trying its methods
  @spec process_task(Domain.t(), State.t(), String.t(), list(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp process_task(%Domain{} = domain, %State{} = state, task_name, args, depth, verbose) do
    methods = Domain.get_task_methods(domain, task_name)

    if Enum.empty?(methods) do
      {:error, "No methods found for task: #{task_name}"}
    else
      try_task_methods(domain, state, methods, args, depth, verbose)
    end
  end

  # Try task methods until one succeeds
  @spec try_task_methods(Domain.t(), State.t(), [Domain.task_method_fn()], list(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp try_task_methods(_domain, _state, [], _args, _depth, _verbose) do
    {:error, "All task methods failed"}
  end

  defp try_task_methods(%Domain{} = domain, %State{} = state, [method | rest_methods], args, depth, verbose) do
    case method.(state, args) do
      false ->
        # Method failed, try next one
        try_task_methods(domain, state, rest_methods, args, depth, verbose)

      result when is_list(result) ->
        # Method succeeded, return new todos
        {:ok, state, result}

      _ ->
        # Invalid method result
        try_task_methods(domain, state, rest_methods, args, depth, verbose)
    end
  end

  # Process a single goal
  @spec process_goal(Domain.t(), State.t(), String.t(), String.t(), any(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp process_goal(%Domain{} = domain, %State{} = state, predicate, subject, object, depth, verbose) do
    # Check if goal is already satisfied
    case State.get_object(state, predicate, subject) do
      ^object ->
        # Goal already satisfied
        {:ok, state, []}

      _ ->
        # Try unigoal methods for this predicate
        methods = Domain.get_unigoal_methods(domain, predicate)

        if Enum.empty?(methods) do
          {:error, "No methods found for goal: #{predicate}"}
        else
          try_unigoal_methods(domain, state, methods, [subject, object], depth, verbose)
        end
    end
  end

  # Try unigoal methods until one succeeds
  @spec try_unigoal_methods(Domain.t(), State.t(), [Domain.goal_method_fn()], list(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp try_unigoal_methods(_domain, _state, [], _args, _depth, _verbose) do
    {:error, "All unigoal methods failed"}
  end

  defp try_unigoal_methods(%Domain{} = domain, %State{} = state, [method | rest_methods], args, depth, verbose) do
    case method.(state, args) do
      false ->
        try_unigoal_methods(domain, state, rest_methods, args, depth, verbose)

      result when is_list(result) ->
        {:ok, state, result}

      _ ->
        try_unigoal_methods(domain, state, rest_methods, args, depth, verbose)
    end
  end

  # Process a multigoal
  @spec process_multigoal(Domain.t(), State.t(), Multigoal.t(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp process_multigoal(%Domain{} = domain, %State{} = state, %Multigoal{} = multigoal, depth, verbose) do
    # Check if multigoal is already satisfied
    if Multigoal.satisfied?(multigoal, state) do
      {:ok, state, []}
    else
      # Try multigoal methods
      methods = Domain.get_multigoal_methods(domain)

      if Enum.empty?(methods) do
        # Fall back to processing individual goals
        unsatisfied = Multigoal.unsatisfied_goals(multigoal, state)
        {:ok, state, unsatisfied}
      else
        try_multigoal_methods(domain, state, methods, [multigoal], depth, verbose)
      end
    end
  end

  # Try multigoal methods until one succeeds
  @spec try_multigoal_methods(Domain.t(), State.t(), [Domain.goal_method_fn()], list(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp try_multigoal_methods(_domain, _state, [], _args, _depth, _verbose) do
    {:error, "All multigoal methods failed"}
  end

  defp try_multigoal_methods(%Domain{} = domain, %State{} = state, [method | rest_methods], args, depth, verbose) do
    case method.(state, args) do
      false ->
        try_multigoal_methods(domain, state, rest_methods, args, depth, verbose)

      result when is_list(result) ->
        {:ok, state, result}

      _ ->
        try_multigoal_methods(domain, state, rest_methods, args, depth, verbose)
    end
  end

  # Process an action
  @spec process_action(Domain.t(), State.t(), atom(), list(), integer(), integer()) ::
    {:action, atom(), list(), State.t()} | {:error, String.t()}
  defp process_action(%Domain{} = domain, %State{} = state, action_name, args, _depth, verbose) do
    case Domain.execute_action(domain, state, action_name, args) do
      false ->
        {:error, "Action failed: #{action_name}"}

      {:ok, %State{} = new_state} ->
        if verbose > 1 do
          IO.puts("Executed action: #{action_name}(#{inspect(args)})")
        end
        {:action, action_name, args, new_state}

      %State{} = new_state ->
        if verbose > 1 do
          IO.puts("Executed action: #{action_name}(#{inspect(args)})")
        end
        {:action, action_name, args, new_state}
    end
  end

  @doc """
  Validates a plan by executing it step by step.

  Returns the final state if successful, or an error if any step fails.
  """
  @spec validate_plan(Domain.t(), State.t(), [plan_step()]) :: {:ok, State.t()} | {:error, String.t()}
  def validate_plan(%Domain{} = domain, %State{} = initial_state, plan) do
    Enum.reduce_while(plan, {:ok, initial_state}, fn {action_name, args}, {:ok, state} ->
      case Domain.execute_action(domain, state, action_name, args) do
        false ->
          {:halt, {:error, "Action #{action_name} failed during validation"}}

        {:ok, %State{} = new_state} ->
          {:cont, {:ok, new_state}}

        %State{} = new_state ->
          {:cont, {:ok, new_state}}
      end
    end)
  end

  @doc """
  Estimates the cost of a plan (simple step count for now).
  """
  @spec plan_cost([plan_step()]) :: non_neg_integer()
  def plan_cost(plan) when is_list(plan) do
    length(plan)
  end
end
