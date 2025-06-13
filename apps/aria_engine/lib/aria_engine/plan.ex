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
      IO.puts("Starting HTN planning with backtracking for #{length(todos)} todos")
    end

    # Use backtracking planning approach
    case try_plan_todos_with_backtracking(domain, state, todos, [], 0, max_depth, verbose) do
      {:ok, _final_state, plan} ->
        if verbose > 0 do
          IO.puts("Planning succeeded with #{length(plan)} steps")
        end
        {:ok, plan}
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
      # Handle task decomposition or string-named action
      {task_name, args} when is_binary(task_name) ->
        # First check if this string name corresponds to an action in the domain
        string_as_atom = String.to_atom(task_name)
        if Domain.has_action?(domain, string_as_atom) do
          process_string_action(domain, state, task_name, string_as_atom, args, depth, verbose)
        else
          process_task(domain, state, task_name, args, depth, verbose)
        end

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

  # Process a task by trying its methods with backtracking support
  @spec process_task(Domain.t(), State.t(), String.t(), list(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp process_task(%Domain{} = domain, %State{} = state, task_name, args, depth, verbose) do
    methods = Domain.get_task_methods(domain, task_name)

    if Enum.empty?(methods) do
      {:error, "No methods found for task: #{task_name}"}
    else
      # Use backtracking to try methods
      case try_task_methods(domain, state, methods, args, depth, @default_max_depth, verbose) do
        {:ok, new_state, planned_actions} ->
          # Convert planned actions back to todos for the main planning loop
          {:ok, new_state, planned_actions}
        {:error, _} = error ->
          error
      end
    end
  end

  # Try task methods until one succeeds (implements HTN backtracking)
  @spec try_task_methods(Domain.t(), State.t(), [Domain.task_method_fn()], list(), integer(), integer(), integer()) ::
    {:ok, State.t(), [todo_item()]} | {:error, String.t()}
  defp try_task_methods(_domain, _state, [], _args, _depth, _max_depth, _verbose) do
    {:error, "All task methods failed"}
  end

  defp try_task_methods(%Domain{} = domain, %State{} = state, [method | rest_methods], args, depth, max_depth, verbose) do
    if verbose > 1 do
      IO.puts("#{String.duplicate("  ", depth)}Trying method...")
    end

    case method.(state, args) do
      false ->
        # Method failed at precondition level, try next one
        if verbose > 1 do
          IO.puts("#{String.duplicate("  ", depth)}Method failed preconditions, trying next...")
        end
        try_task_methods(domain, state, rest_methods, args, depth, max_depth, verbose)

      result when is_list(result) ->
        # Method succeeded, now try to plan the resulting todos with backtracking
        if verbose > 1 do
          IO.puts("#{String.duplicate("  ", depth)}Method produced #{length(result)} todos, attempting to plan...")
        end
        
        case try_plan_todos_with_backtracking(domain, state, result, [], depth + 1, max_depth, verbose) do
          {:ok, final_state, actions} ->
            # Success: this method's todos were successfully planned
            if verbose > 1 do
              IO.puts("#{String.duplicate("  ", depth)}Method succeeded with #{length(actions)} actions")
            end
            {:ok, final_state, actions}
          
          {:error, _reason} ->
            # This method's todos failed to plan, try next method (backtrack)
            if verbose > 1 do
              IO.puts("#{String.duplicate("  ", depth)}Method's todos failed to plan, backtracking...")
            end
            try_task_methods(domain, state, rest_methods, args, depth, max_depth, verbose)
        end

      _ ->
        # Invalid method result
        try_task_methods(domain, state, rest_methods, args, depth, max_depth, verbose)
    end
  end

  # Try to plan a list of todos with backtracking support
  @spec try_plan_todos_with_backtracking(Domain.t(), State.t(), [todo_item()], [plan_step()], integer(), integer(), integer()) ::
    {:ok, State.t(), [plan_step()]} | {:error, String.t()}
  defp try_plan_todos_with_backtracking(_domain, state, [], actions, _depth, _max_depth, _verbose) do
    {:ok, state, Enum.reverse(actions)}
  end

  defp try_plan_todos_with_backtracking(%Domain{} = domain, %State{} = state, [todo | rest_todos], actions, depth, max_depth, verbose) do
    # For tasks, we need to try all methods and see which ones allow the remaining todos to succeed
    case todo do
      {task_name, args} when is_binary(task_name) ->
        string_as_atom = String.to_atom(task_name)
        if Domain.has_action?(domain, string_as_atom) do
          # It's an action, process normally
          case process_todo_for_backtracking(domain, state, todo, depth, max_depth, verbose) do
            {:ok, new_state, new_actions} ->
              combined_actions = Enum.reverse(new_actions) ++ actions
              try_plan_todos_with_backtracking(domain, new_state, rest_todos, combined_actions, depth, max_depth, verbose)
            {:error, _} = error ->
              error
          end
        else
          # It's a task - try each method and see if the full plan (this task + remaining todos) works
          methods = Domain.get_task_methods(domain, task_name)
          if Enum.empty?(methods) do
            {:error, "No methods found for task: #{task_name}"}
          else
            try_task_methods_with_remaining_todos(domain, state, methods, args, rest_todos, actions, depth, max_depth, verbose)
          end
        end
      
      _ ->
        # Not a task, process normally
        case process_todo_for_backtracking(domain, state, todo, depth, max_depth, verbose) do
          {:ok, new_state, new_actions} ->
            combined_actions = Enum.reverse(new_actions) ++ actions
            try_plan_todos_with_backtracking(domain, new_state, rest_todos, combined_actions, depth, max_depth, verbose)
          {:error, _} = error ->
            error
        end
    end
  end
  
  # Try task methods with consideration for remaining todos (cross-task backtracking)
  @spec try_task_methods_with_remaining_todos(Domain.t(), State.t(), [Domain.task_method_fn()], list(), [todo_item()], [plan_step()], integer(), integer(), integer()) ::
    {:ok, State.t(), [plan_step()]} | {:error, String.t()}
  defp try_task_methods_with_remaining_todos(_domain, _state, [], _args, _remaining_todos, _actions, _depth, _max_depth, _verbose) do
    {:error, "All task methods failed"}
  end

  defp try_task_methods_with_remaining_todos(%Domain{} = domain, %State{} = state, [method | rest_methods], args, remaining_todos, actions, depth, max_depth, verbose) do
    if verbose > 0 do
      IO.puts("#{String.duplicate("  ", depth)}Trying method with remaining todos...")
    end

    case method.(state, args) do
      false ->
        # Method failed at precondition level, try next one
        if verbose > 0 do
          IO.puts("#{String.duplicate("  ", depth)}Method failed preconditions, trying next...")
        end
        try_task_methods_with_remaining_todos(domain, state, rest_methods, args, remaining_todos, actions, depth, max_depth, verbose)

      result when is_list(result) ->
        # Method succeeded, now try to plan the resulting todos + remaining todos
        if verbose > 0 do
          IO.puts("#{String.duplicate("  ", depth)}Method produced #{length(result)} todos: #{inspect(result)}")
          IO.puts("#{String.duplicate("  ", depth)}Combined with remaining todos: #{inspect(remaining_todos)}")
        end
        
        combined_todos = result ++ remaining_todos
        case try_plan_todos_with_backtracking(domain, state, combined_todos, actions, depth + 1, max_depth, verbose) do
          {:ok, final_state, final_actions} ->
            # Success: this method allowed the full plan to work
            if verbose > 0 do
              IO.puts("#{String.duplicate("  ", depth)}Method succeeded with full plan of #{length(final_actions)} actions: #{inspect(final_actions)}")
            end
            {:ok, final_state, final_actions}
          
          {:error, reason} ->
            # This method's full plan failed, try next method (backtrack)
            if verbose > 0 do
              IO.puts("#{String.duplicate("  ", depth)}Method's full plan failed: #{reason}, backtracking...")
            end
            try_task_methods_with_remaining_todos(domain, state, rest_methods, args, remaining_todos, actions, depth, max_depth, verbose)
        end

      _ ->
        # Invalid method result
        try_task_methods_with_remaining_todos(domain, state, rest_methods, args, remaining_todos, actions, depth, max_depth, verbose)
    end
  end

  # Process a todo for backtracking (returns actions, doesn't modify the main planning flow)
  @spec process_todo_for_backtracking(Domain.t(), State.t(), todo_item(), integer(), integer(), integer()) ::
    {:ok, State.t(), [plan_step()]} | {:error, String.t()}
  defp process_todo_for_backtracking(%Domain{} = domain, %State{} = state, todo, depth, max_depth, verbose) do
    case todo do
      # Handle string-named action (Run-Lazy-Lookahead: only check when we reach the action)
      {task_name, args} when is_binary(task_name) ->
        string_as_atom = String.to_atom(task_name)
        if Domain.has_action?(domain, string_as_atom) do
          # Lazily check action preconditions
          case check_action_preconditions(domain, state, string_as_atom, args, verbose) do
            {:ok, new_state} ->
              action_step = {task_name, args}  # Preserve original string format
              {:ok, new_state, [action_step]}
            {:error, _} = error ->
              error
          end
        else
          # It's a task, use backtracking task method resolution
          methods = Domain.get_task_methods(domain, task_name)
          if Enum.empty?(methods) do
            {:error, "No methods found for task: #{task_name}"}
          else
            case try_task_methods(domain, state, methods, args, depth, max_depth, verbose) do
              {:ok, new_state, actions} -> {:ok, new_state, actions}
              {:error, _} = error -> error
            end
          end
        end

      # Handle atom-named action
      {action_name, args} when is_atom(action_name) ->
        case check_action_preconditions(domain, state, action_name, args, verbose) do
          {:ok, new_state} ->
            action_step = {action_name, args}
            {:ok, new_state, [action_step]}
          {:error, _} = error ->
            error
        end

      # Handle goals and other todo types
      _ ->
        # For now, delegate to the original process_todo for goals/multigoals
        case process_todo(domain, state, todo, depth, verbose) do
          {:ok, new_state, new_todos} ->
            # Recursively plan the new todos
            try_plan_todos_with_backtracking(domain, new_state, new_todos, [], depth + 1, max_depth, verbose)
          {:action, action_name, args, new_state} ->
            action_step = {action_name, args}
            {:ok, new_state, [action_step]}
          {:error, _} = error ->
            error
        end
    end
  end

  # Run-Lazy-Lookahead: Check action preconditions only when needed
  @spec check_action_preconditions(Domain.t(), State.t(), atom(), list(), integer()) ::
    {:ok, State.t()} | {:error, String.t()}
  defp check_action_preconditions(%Domain{} = domain, %State{} = state, action_name, args, verbose) do
    if verbose > 2 do
      IO.puts("Checking preconditions for action: #{action_name}(#{inspect(args)})")
    end

    # Execute action to check if preconditions are met and get resulting state
    case Domain.execute_action(domain, state, action_name, args) do
      false ->
        {:error, "Action #{action_name} preconditions not met"}
      {:ok, %State{} = new_state} ->
        {:ok, new_state}
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

  # Process an action with string name (preserves original format, planning only)
  @spec process_string_action(Domain.t(), State.t(), String.t(), atom(), list(), integer(), integer()) ::
    {:action, String.t(), list(), State.t()} | {:error, String.t()}
  defp process_string_action(%Domain{} = domain, %State{} = state, original_name, action_atom, args, _depth, verbose) do
    # During planning, we don't execute actions - we just check if they could work
    # and simulate their effects for further planning
    case Domain.execute_action(domain, state, action_atom, args) do
      false ->
        {:error, "Action failed: #{original_name}"}

      {:ok, %State{} = new_state} ->
        if verbose > 1 do
          IO.puts("Planning action: #{original_name}(#{inspect(args)})")
        end
        {:action, original_name, args, new_state}
    end
  end

  # Process an action (planning only, not execution)
  @spec process_action(Domain.t(), State.t(), atom(), list(), integer(), integer()) ::
    {:action, atom(), list(), State.t()} | {:error, String.t()}
  defp process_action(%Domain{} = domain, %State{} = state, action_name, args, _depth, verbose) do
    # During planning, we don't execute actions - we just check if they could work
    # and simulate their effects for further planning
    case Domain.execute_action(domain, state, action_name, args) do
      false ->
        {:error, "Action failed: #{action_name}"}

      {:ok, %State{} = new_state} ->
        if verbose > 1 do
          IO.puts("Planning action: #{action_name}(#{inspect(args)})")
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
