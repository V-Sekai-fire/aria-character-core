# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Actions.Core do
  @moduledoc """
  Core parsing for actions.
  """
  alias AriaEngine.Pddl.Domain.Action
  alias AriaEngine.PddlParser.DomainParser.Actions.Parameters
  alias AriaEngine.PddlParser.DomainParser.Actions.Duration
  alias AriaEngine.PddlParser.DomainParser.Actions.Condition
  alias AriaEngine.PddlParser.DomainParser.Actions.Effect

  @type parsed_action :: Action.t()

  @spec parse_action(String.t()) :: Action.t()
  def parse_action(action_content) do
    parts = String.split(action_content, " ", trim: true)
    name = List.first(parts)
    Action.new(
      String.to_atom(name),
      Parameters.parse_action_parameters(action_content),
      Duration.parse_action_duration(action_content), # Parse duration
      Condition.parse_action_condition(action_content),
      Effect.parse_action_effect(action_content)
    )
  end
end
