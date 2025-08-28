# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributes.Macros do
  @moduledoc """
  Macro definitions for AriaCore.ActionAttributes attribute system.

  This module contains all the attribute macros (@action, @command, etc.)
  that provide the syntactic sugar for defining action metadata.
  """

  @doc """
  Defines action metadata for planning-time specifications.

  ## Examples

      @action duration: "PT30M", requires_entities: [%{type: "agent"}]
      def cook_meal(state, [meal_id]) do
        # Implementation
      end
  """
  defmacro action(metadata) do
    quote do
      @action_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end

  @doc """
  Defines command metadata for execution-time logic with failure handling.

  Commands follow ADR-181 execution-time patterns with robust failure handling.

  ## Examples

      @command duration: "PT15M"
      def execute_cooking_command(state, [meal_id]) do
        # Execution logic with failure handling
      end
  """
  defmacro command(metadata) do
    quote do
      @command_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end

  @doc """
  Defines task method metadata for workflow decomposition.

  According to ADR-181, task methods are for workflow decomposition only
  and do not support priority or goal_pattern fields.

  ## Examples

      @task_method
      def prepare_meal_method(state, [meal_id]) do
        # Workflow decomposition logic
      end
  """
  defmacro task_method(metadata \\ true) do
    quote do
      @method_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end

  @doc """
  Defines unigoal method metadata for single goal achievement.

  According to ADR-181, unigoal methods only support the predicate field.
  Priority handling belongs in the planner's method selection logic.

  ## Examples

      @unigoal_method predicate: "meal_status"
      def achieve_meal_ready(state, [subject, value]) do
        # Goal achievement logic
      end
  """
  defmacro unigoal_method(metadata) do
    quote do
      @unigoal_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end

  @doc """
  Defines multigoal method metadata for multiple goal optimization.

  ## Examples

      @multigoal_method true
      def optimize_resource_allocation(state, multigoal) do
        # Multiple goal optimization logic
      end
  """
  defmacro multigoal_method(metadata \\ true) do
    quote do
      @multigoal_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end

  @doc """
  Defines multitodo method metadata for todo list optimization.

  ## Examples

      @multitodo_method true
      def reorder_tasks_for_efficiency(state, todo_list) do
        # Todo list optimization logic
      end
  """
  defmacro multitodo_method(metadata \\ true) do
    quote do
      @multitodo_metadata {unquote(__CALLER__.function), unquote(metadata)}
    end
  end
end
