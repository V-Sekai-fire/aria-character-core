defmodule AriaEngine.PddlParser.DomainParser.Actions.Duration do
  @moduledoc """
  Parses action duration.
  """

  @type duration_value :: integer() | {atom(), atom()} | {atom(), atom(), atom()} | nil

  @spec parse_action_duration(String.t()) :: duration_value()
  def parse_action_duration(content) do
    duration_regex = ~r/:duration\s+\(([\s\S]+?)\)/
    case Regex.run(duration_regex, content) do
      [_, duration_str] ->
        parts = String.split(duration_str, " ", trim: true)
        case parts do
          ["=", "?duration", value_str] ->
            case Integer.parse(value_str) do
              {value, ""} -> value
              _ -> nil
            end
          ["=", "?duration", "(", func_name, arg, ")"] ->
            {String.to_atom(func_name), String.to_atom(arg)}
          ["=", "?duration", "(", func_name, arg1, arg2, ")"] ->
            {String.to_atom(func_name), String.to_atom(arg1), String.to_atom(arg2)}
          _ ->
            nil
        end
      _ -> nil
    end
  end
end
