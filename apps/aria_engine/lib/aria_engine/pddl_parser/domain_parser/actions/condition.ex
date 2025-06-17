defmodule AriaEngine.PddlParser.DomainParser.Actions.Condition do
  @moduledoc """
  Parses action condition.
  """
  alias AriaEngine.PddlParser.Core

  @spec parse_action_condition(String.t()) :: list() | nil
  def parse_action_condition(content) do
    condition_regex = ~r/:condition\s+\(([\s\S]+?)\)/
    case Regex.run(condition_regex, content) do
      [_, cond_str] -> Core.parse_expression(cond_str)
      _ -> nil
    end
  end
end
