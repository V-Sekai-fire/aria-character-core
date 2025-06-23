# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Rules.DebugDatetime do
  @moduledoc """
  Debug rule to understand DateTime.to_iso8601 AST patterns.
  """

  require Logger

  @doc """
  Check if content needs debug transformation.
  """
  @spec needs_transformation?(String.t()) :: boolean()
  def needs_transformation?(source_code) do
    String.contains?(source_code, "DateTime.to_iso8601(")
  end

  @doc """
  Get transformation rules for debug.
  """
  @spec transformation_rules() :: [function()]
  def transformation_rules do
    [debug_datetime_rule()]
  end

  # Private functions

  defp debug_datetime_rule do
    fn ast_node ->
      case ast_node do
        # Match any DateTime call
        {{:., _meta, [{:__aliases__, _alias_meta, [:DateTime]}, function_name]}, _call_meta, args} ->
          Logger.info("Found DateTime.#{function_name} with args: #{inspect(args)}")
          ast_node

        _ ->
          ast_node
      end
    end
  end
end
