defmodule AriaEngine.PddlParser.DomainParser.Actions.Parameters do
  @moduledoc """
  Parses action parameters.
  """
  alias AriaEngine.Pddl.Domain.Parameter

  @type parameter :: Parameter.t()

  @spec parse_action_parameters(String.t()) :: [parameter()]
  def parse_action_parameters(content) do
    param_regex = ~r/:parameters\s+\(([\s\S]+?)\)/
    case Regex.run(param_regex, content) do
      [_, params_str] ->
        params_str
        |> String.split(~r/\s+-\s+/, trim: true)
        |> Enum.map(fn part ->
          case String.split(part, " ", parts: 2, trim: true) do
            [names_str, type_str] ->
              names = String.split(names_str, " ", trim: true)
              type = String.to_atom(type_str)
              Enum.map(names, fn name -> Parameter.new(String.to_atom(name), type) end)
            [names_str] ->
              names = String.split(names_str, " ", trim: true)
              Enum.map(names, fn name -> Parameter.new(String.to_atom(name), :object) end)
            _ ->
              []
          end
        end)
        |> List.flatten()
      _ -> []
    end
  end
end
