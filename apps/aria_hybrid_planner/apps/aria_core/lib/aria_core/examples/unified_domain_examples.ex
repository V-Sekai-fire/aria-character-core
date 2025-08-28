# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.Examples.UnifiedDomainExamples do
  use AriaCore.Domain
  use AriaCore.ActionAttributes
  require Logger

  @doc """
  Example action: Cook a meal.
  """
  @action duration: "PT2H", requires_entities: [%{type: "agent", capabilities: [:cooking]}]
  @spec cook_meal(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal(state, [meal_id]) do
    new_state = state |> AriaState.set_fact("meal_status", meal_id, "ready")
    {:ok, new_state}
  end

  @doc """
  Example command: Attempt to cook a meal with a chance of failure.
  """
  @command true
  @spec cook_meal_command(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cook_meal_command(state, [meal_id]) do
    if :rand.uniform() > 0.8 do # 20% chance of failure
      Logger.info("Cooking succeeded for #{meal_id}")
      new_state = state |> AriaState.set_fact("meal_status", meal_id, "ready")
      {:ok, new_state}
    else
      Logger.warning("Cooking failed for #{meal_id}")
      {:error, :cooking_failed}
    end
  end

  @doc """
  Example multigoal method: Optimize cooking batch.
  """
  @multigoal_method true
  @spec optimize_cooking_batch(AriaState.t(), AriaEngineCore.Multigoal.t()) :: {:ok, AriaEngineCore.Multigoal.t()} | {:error, atom()}
  def optimize_cooking_batch(_state, multigoal) do
    Logger.info("Optimizing cooking batch for multigoal: #{inspect(multigoal)}")
    # In a real scenario, this would reorder or combine goals for efficiency
    {:ok, multigoal}
  end

  @doc """
  Example multitodo method: Reorder tasks for efficiency.
  """
  @multitodo_method true
  @spec reorder_tasks_for_efficiency(AriaState.t(), [AriaCore.todo_item()]) :: {:ok, [AriaCore.todo_item()]} | {:error, atom()}
  def reorder_tasks_for_efficiency(_state, todo_list) do
    Logger.info("Reordering todo list for efficiency: #{inspect(todo_list)}")
    # In a real scenario, this would reorder the todo_list
    {:ok, todo_list}
  end

  @spec create_domain() :: AriaCore.Domain.t()
  def create_domain do
    AriaCore.UnifiedDomain.create_from_module(__MODULE__)
  end
end
