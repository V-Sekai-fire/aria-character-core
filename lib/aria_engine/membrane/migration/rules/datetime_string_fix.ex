# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.Rules.DatetimeStringFix do
  @moduledoc """
  Simple rule module for fixing DateTime.to_iso8601 calls with string arguments.

  This module detects and transforms DateTime.to_iso8601(string_variable) calls
  to just use the string variable directly.
  """

  alias AriaEngine.Membrane.Migration.Format.FileData

  @doc """
  Check if this rule applies to the given file data.
  """
  @spec applies_to_file?(FileData.t()) :: boolean()
  def applies_to_file?(file_data) do
    String.contains?(file_data.content, "DateTime.to_iso8601(")
  end

  @doc """
  Apply the transformation to the file data.
  """
  @spec apply_transformation(FileData.t()) :: FileData.t()
  def apply_transformation(file_data) do
    case Code.string_to_quoted(file_data.content) do
      {:ok, ast} ->
        {new_ast, transformations} = transform_ast(ast, [])

        case Macro.to_string(new_ast) do
          new_content when is_binary(new_content) ->
            %{file_data |
              content: new_content,
              transformations: file_data.transformations ++ transformations
            }
          _ ->
            # If transformation failed, return original
            file_data
        end

      {:error, _} ->
        # If parsing failed, return original
        file_data
    end
  end

  # Private functions

  defp transform_ast(ast, transformations) do
    {new_ast, new_transformations} = Macro.prewalk(ast, transformations, &transform_node/2)
    {new_ast, new_transformations}
  end

  defp transform_node(
         {{:., _, [{:__aliases__, _, [:DateTime]}, :to_iso8601]}, _, [variable]} = node,
         transformations
       ) do
    # Check if the variable looks like it's already a string
    if is_string_variable?(variable) do
      transformation = %{
        rule: :datetime_string_fix,
        original: Macro.to_string(node),
        replacement: Macro.to_string(variable),
        line: get_line_number(node)
      }

      {variable, [transformation | transformations]}
    else
      {node, transformations}
    end
  end

  defp transform_node(node, transformations) do
    {node, transformations}
  end

  defp is_string_variable?({variable_name, _, _}) when is_atom(variable_name) do
    variable_str = Atom.to_string(variable_name)

    # Check if variable name suggests it's already a string
    String.ends_with?(variable_str, ["_dt", "_time"]) or
      String.contains?(variable_str, ["iso8601", "string"])
  end

  defp is_string_variable?(_), do: false

  defp get_line_number({_, meta, _}) when is_list(meta) do
    Keyword.get(meta, :line, 0)
  end

  defp get_line_number(_), do: 0
end
