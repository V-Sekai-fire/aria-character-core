# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.StateUtils do
  alias State

  def from_gtpyhop_format(config) when is_map(config) do
    state = State.new()

    Enum.reduce(config, state, fn {predicate, facts}, acc_state ->
      predicate_str = to_string(predicate)

      Enum.reduce(facts, acc_state, fn {subject, value}, inner_state ->
        subject_str = to_string(subject)
        State.set_fact(inner_state, predicate_str, subject_str, value)
      end)
    end)
  end
end
