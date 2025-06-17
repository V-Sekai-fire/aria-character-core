defmodule AriaEngine.PddlParser.ProblemParser.Objects do
  @moduledoc """
  Parses the objects section of a PDDL problem string.
  """
  alias AriaEngine.Pddl.Problem.Object

  @type parsed_object :: Object.t()

  @spec parse_objects(String.t()) :: [parsed_object()]
  def parse_objects(objects_str) do
    objects_str
    |> String.split(~r/\s+-\s+/, trim: true)
    |> Enum.map(fn part ->
      case String.split(part, " ", parts: 2, trim: true) do
        [names_str, type_str] ->
          names = String.split(names_str, " ", trim: true)
          type = String.to_atom(type_str)
          Enum.map(names, fn name -> Object.new(String.to_atom(name), type) end)
        [names_str] -> # Handle objects without explicit type
          names = String.split(names_str, " ", trim: true)
          Enum.map(names, fn name -> Object.new(String.to_atom(name), :object) end) # Default to :object type
        _ -> # Should not happen if trim: true is effective
          []
      end
    end)
    |> List.flatten()
  end
end
