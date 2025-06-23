# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Rules.GoalTuples do
  @moduledoc """
  Rule for fixing goal tuple ordering from {subject, predicate, object} to {predicate, subject, object}.

  Single responsibility: Define transformation logic for reordering goal tuples
  to match the State API format.
  """

  @doc """
  Check if content needs goal tuple transformation.
  """
  @spec needs_transformation?(String.t()) :: boolean()
  def needs_transformation?(source_code) do
    String.contains?(source_code, "{\"") and
      (String.contains?(source_code, "location") or
         String.contains?(source_code, "has") or
         String.contains?(source_code, "state") or
         String.contains?(source_code, "assigned_to"))
  end

  @doc """
  Get transformation rules for goal tuple migration.
  """
  @spec transformation_rules() :: [function()]
  def transformation_rules do
    [
      goal_tuple_reorder_rule("location"),
      goal_tuple_reorder_rule("has"),
      goal_tuple_reorder_rule("has_key"),
      goal_tuple_reorder_rule("state"),
      goal_tuple_reorder_rule("assigned_to"),
      goal_tuple_reorder_rule("status"),
      goal_tuple_reorder_rule("type"),
      goal_tuple_reorder_rule("available"),
      goal_tuple_reorder_rule("capacity"),
      goal_tuple_reorder_rule("weight"),
      goal_tuple_reorder_rule("battery"),
      goal_tuple_reorder_rule("carrying")
    ]
  end

  # Private functions

  defp goal_tuple_reorder_rule(predicate) do
    fn ast_node ->
      case ast_node do
        # Match: {"subject", "predicate", "object"}
        {:{}, meta, [subject, ^predicate, object]} when is_binary(subject) ->
          # Reorder to: {"predicate", "subject", "object"}
          {:{}, meta, [predicate, subject, object]}

        _ ->
          ast_node
      end
    end
  end
end
