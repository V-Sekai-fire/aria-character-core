# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Rules.LoggerConversion do
  @moduledoc """
  Rule for converting IO.puts calls to appropriate Logger calls.

  Single responsibility: Define transformation logic for replacing IO.puts
  with appropriate Logger calls based on context.
  """

  @doc """
  Check if content needs Logger conversion.
  """
  @spec needs_transformation?(String.t()) :: boolean()
  def needs_transformation?(source_code) do
    String.contains?(source_code, "IO.puts(") and
      not String.contains?(source_code, "# Keep IO.puts")
  end

  @doc """
  Get transformation rules for Logger conversion.
  """
  @spec transformation_rules() :: [function()]
  def transformation_rules do
    [io_puts_to_logger_rule()]
  end

  # Private functions

  defp io_puts_to_logger_rule do
    fn ast_node ->
      case ast_node do
        # Match: IO.puts(anything)
        {{:., meta, [{:__aliases__, _alias_meta, [:IO]}, :puts]}, call_meta, [message]} ->
          # Convert to: Logger.info(anything)
          {{:., meta, [{:__aliases__, [alias: false], [:Logger]}, :info]}, call_meta, [message]}

        _ ->
          ast_node
      end
    end
  end
end
