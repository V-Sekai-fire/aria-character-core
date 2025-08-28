# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributes.Documentation do
  @moduledoc """
  Documentation functions for AriaCore.ActionAttributes attribute system.

  This module contains all the documentation functions for the various
  attribute types supported by the ActionAttributes system.
  """

  @doc """
  @multigoal_method attribute documentation.

  Multigoal methods provide optimization strategies for achieving multiple goals simultaneously.

  ## Examples

      @multigoal_method true
      def optimize_resource_allocation(state, multigoal) do
        # Implementation to reorder or optimize goals
        {:ok, multigoal}
      end
  """
  @spec multigoal_method_attribute_docs() :: :ok
  def multigoal_method_attribute_docs, do: :ok

  @doc """
  @multitodo_method attribute documentation.

  Multitodo methods provide optimization strategies for processing lists of todo items.

  ## Examples

      @multitodo_method true
      def reorder_tasks_for_efficiency(state, todo_list) do
        # Implementation to reorder or optimize todo_list
        {:ok, todo_list}
      end
  """
  @spec multitodo_method_attribute_docs() :: :ok
  def multitodo_method_attribute_docs, do: :ok

  @doc """
  @action attribute documentation.

  ## Supported Attributes

  - `duration`: ISO 8601 duration string or seconds (optional)
  - `start`: ISO 8601 datetime string for fixed start time (optional)
  - `end`: ISO 8601 datetime string for fixed end time (optional)
  - `requires_entities`: List of entity requirements (optional)

  ## Examples

      @action duration: "PT30M",
              requires_entities: [
                %{type: "agent", capabilities: [:cooking]},
                %{type: "kitchen", capabilities: [:food_prep]}
              ]
      def make_soup(state, [soup_id]) do
        # Implementation
      end
  """
  @spec action_attribute_docs() :: :ok
  def action_attribute_docs, do: :ok

  @doc """
  @command attribute documentation.

  Commands are execution-time logic with failure handling according to ADR-181.
  They are used during plan execution to handle real-world failures and provide
  robust execution behavior.

  ## Supported Attributes

  - `duration`: ISO 8601 duration string or seconds (optional)
  - `requires_entities`: List of entity requirements (optional)

  ## Examples

      @command true
      def cook_meal_command(state, [meal_id]) do
        case validate_cooking_equipment(state) do
          :ok ->
            perform_cooking(state, meal_id)
          {:error, reason} ->
            {:error, reason}
        end
      end
  """
  @spec command_attribute_docs() :: :ok
  def command_attribute_docs, do: :ok

  @doc """
  @task_method attribute documentation.

  Task methods provide decomposition strategies for complex workflows.
  According to ADR-181, task methods are for workflow decomposition only
  and do not support priority or goal_pattern fields.

  ## Examples

      @task_method
      def prepare_meal_method(state, [meal_id]) do
        {:ok, [
          {"ingredients_available", meal_id, true},
          {:cook_meal, [meal_id]},
          {"quality_check", meal_id, true}
        ]}
      end
  """
  @spec task_method_attribute_docs() :: :ok
  def task_method_attribute_docs, do: :ok

  @doc """
  @unigoal_method attribute documentation.

  Unigoal methods provide single goal achievement strategies according to ADR-181.
  They handle prerequisite checking, action selection, and verification for one specific goal predicate.

  ## Required Attributes

  - `predicate`: The goal predicate this method handles (required)

  ## Examples

      @unigoal_method predicate: "meal_status"
      def meal_status_goal(state, [subject, value]) when value == "ready" do
        {:ok, [
          # Prerequisites (former preconditions)
          {"ingredient_available", "tomato", true},
          {"equipment_status", "stove_1", "operational"},

          # Main action
          {:cook_meal, [subject]},

          # Verification (former effects)
          {"meal_status", subject, "ready"}
        ]}
      end
  """
  @spec unigoal_method_attribute_docs() :: :ok
  def unigoal_method_attribute_docs, do: :ok
end
