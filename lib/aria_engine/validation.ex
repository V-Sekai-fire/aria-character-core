defmodule Validation do
  @moduledoc "Provides validation functions for the Aria Engine definition.\n"
  alias Core
  @type t :: Core.t()
  @type todo_item :: Core.todo_item()
  @type action_fn :: Core.action_fn()
  @type task_method_fn :: Core.task_method_fn()
  @type goal_method_fn :: Core.goal_method_fn()
  @doc "Validates the AriaEngine definition.\n"
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%Core{} = engine) do
    errors = []

    errors =
      if String.trim(engine.id) == "" do
        ["Engine ID cannot be empty" | errors]
      else
        errors
      end

    errors = validate_goals(engine.goals, errors)
    errors = validate_actions(engine.actions, errors)
    errors = validate_task_methods(engine.task_methods, errors)
    errors = validate_unigoal_methods(engine.unigoal_methods, errors)

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  defp validate_goals(goals, errors) do
    Enum.reduce(goals, errors, fn goal, acc ->
      case goal do
        {pred, subj, _fact_value} when is_binary(pred) and is_binary(subj) -> acc
        {task_name, args} when is_binary(task_name) and is_list(args) -> acc
        {action_name, args} when is_atom(action_name) and is_list(args) -> acc
        _ -> ["Invalid goal format: #{inspect(goal)}" | acc]
      end
    end)
  end

  defp validate_actions(actions, errors) do
    Enum.reduce(actions, errors, fn {name, action_fn}, acc ->
      cond do
        not is_atom(name) -> ["Action name must be atom: #{inspect(name)}" | acc]
        not is_function(action_fn, 2) -> ["Action must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_task_methods(task_methods, errors) do
    Enum.reduce(task_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) ->
          ["Task method name must be string: #{inspect(name)}" | acc]

        not is_list(method_fns) ->
          ["Task methods must be list: #{name}" | acc]

        not Enum.all?(method_fns, &is_function(&1, 2)) ->
          ["All task methods must be function/2: #{name}" | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_unigoal_methods(unigoal_methods, errors) do
    Enum.reduce(unigoal_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) ->
          ["Unigoal method name must be string: #{inspect(name)}" | acc]

        not is_list(method_fns) ->
          ["Unigoal methods must be list: #{name}" | acc]

        not Enum.all?(method_fns, &is_function(&1, 2)) ->
          ["All unigoal methods must be function/2: #{name}" | acc]

        true ->
          acc
      end
    end)
  end
end