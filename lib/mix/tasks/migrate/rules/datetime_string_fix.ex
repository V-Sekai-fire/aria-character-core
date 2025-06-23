# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Rules.DatetimeStringFix do
  @moduledoc """
  Rule for fixing DateTime.to_iso8601 calls with string arguments.

  Single responsibility: Define transformation logic for replacing
  DateTime.to_iso8601(string) calls with the string directly, since
  the string is already in ISO8601 format.
  """

  @doc """
  Check if content needs DateTime string fix transformation.
  """
  @spec needs_transformation?(String.t()) :: boolean()
  def needs_transformation?(source_code) do
    String.contains?(source_code, "DateTime.to_iso8601(")
  end

  @doc """
  Get transformation rules for DateTime string fix.
  """
  @spec transformation_rules() :: [function()]
  def transformation_rules do
    [datetime_to_iso8601_string_fix_rule()]
  end

  # Private functions

  defp datetime_to_iso8601_string_fix_rule do
    fn ast_node ->
      case ast_node do
        # Match: DateTime.to_iso8601(variable_name) - check if it's likely a string variable
        {{:., _meta, [{:__aliases__, _alias_meta, [:DateTime]}, :to_iso8601]}, _call_meta,
         [{var_name, var_meta, context}]}
        when is_atom(var_name) and is_atom(context) ->
          var_string = Atom.to_string(var_name)
          if String.contains?(var_string, "_iso8601") or
             String.ends_with?(var_string, "_time") or
             String.ends_with?(var_string, "_dt") do
            # Replace with just the variable since it's already an ISO8601 string
            {var_name, var_meta, context}
          else
            ast_node
          end

        # Match: DateTime.to_iso8601(variable, :extended, nil) - remove the extra parameters
        {{:., _meta, [{:__aliases__, _alias_meta, [:DateTime]}, :to_iso8601]}, _call_meta,
         [{var_name, var_meta, context}, :extended, nil]}
        when is_atom(var_name) and is_atom(context) ->
          # Replace with just the variable
          {var_name, var_meta, context}

        _ ->
          ast_node
      end
    end
  end
end
