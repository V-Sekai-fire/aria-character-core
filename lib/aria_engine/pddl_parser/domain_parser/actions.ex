# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Actions do
  @moduledoc """
  Parses the actions section of a PDDL domain string.
  """
  alias AriaEngine.Pddl.Domain.Action
  alias AriaEngine.PddlParser.DomainParser.Actions.Parameters
  alias AriaEngine.PddlParser.DomainParser.Actions.Duration
  alias AriaEngine.PddlParser.DomainParser.Actions.Condition
  alias AriaEngine.PddlParser.DomainParser.Actions.Effect

  @spec parse_action(String.t()) :: Action.t()
  def parse_action(action_content) do
    parts = String.split(action_content, " ", trim: true)
    name = List.first(parts)
    Action.new(
      String.to_atom(name),
      Parameters.parse_action_parameters(action_content),
      Duration.parse_action_duration(action_content), # Pass duration
      Condition.parse_action_condition(action_content),
      Effect.parse_action_effect(action_content)
    )
  end
end
