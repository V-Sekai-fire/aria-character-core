defmodule AriaEngine.PddlParser.Core.Utils do
  @moduledoc """
  Utility functions for PDDL parsing.
  """

  @type literal_value :: atom() | integer() | float()

  @doc """
  Parses a string into an atom, integer, or float based on its content.
  Handles PDDL variables (starting with '?').
  """
  @spec parse_literal(String.t()) :: literal_value()
  def parse_literal(str) do
    cond do
      String.starts_with?(str, "?") -> String.to_atom(str) # Variables
      String.match?(str, ~r/^\d+\.\d+$/) -> String.to_float(str) # Floats (e.g., "20.0")
      String.match?(str, ~r/^\d+$/) -> String.to_integer(str) # Integers (e.g., "20")
      true -> String.to_atom(str) # Atoms
    end
  end

  @doc """
  Converts a value to a string. If the value is an atom, it converts it to a string.
  Otherwise, it returns the value as is (assuming it's already a string or can be inspected).
  """
  @spec to_string_if_atom(atom() | String.t() | any()) :: String.t()
  def to_string_if_atom(val) when is_atom(val), do: Atom.to_string(val)
  def to_string_if_atom(val) when is_binary(val), do: val
  def to_string_if_atom(val), do: inspect(val) # Fallback for other types
end
