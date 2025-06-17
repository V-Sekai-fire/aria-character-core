defmodule AriaEngine.PddlParser.DomainParser.Actions.Effect do
  @moduledoc """
  Parses action effect.
  """
  alias AriaEngine.PddlParser.Core

  @spec parse_action_effect(String.t()) :: list() | nil
  def parse_action_effect(content) do
    effect_regex = ~r/:effect\s+\(([\s\S]+?)\)/
    case Regex.run(effect_regex, content) do
      [_, effect_str] -> Core.parse_expression(effect_str)
      _ -> nil
    end
  end
end
