# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Predicates do
  @moduledoc """
  Parses the predicates section of a PDDL domain string.
  """

  @type parsed_predicate :: {atom(), [atom()]}

  @spec parse_predicates(String.t()) :: [parsed_predicate()]
  def parse_predicates(preds_str) do
    # Regex to find all ( ... ) blocks
    Regex.scan(~r/\(([^()]*?)\)/, preds_str, capture: :all_but_first)
    |> Enum.map(fn [pred_content] ->
      # pred_content is "at ?x - object ?l - location"
      parts = String.split(pred_content, " ", trim: true)
      [head | tail] = parts
      {String.to_atom(head), Enum.map(tail, &String.to_atom/1)}
    end)
  end
end
