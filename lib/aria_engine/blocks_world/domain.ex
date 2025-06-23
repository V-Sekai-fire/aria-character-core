# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.Domain do
  alias AriaEngine.Domain

  def build do
    Domain.new("blocks_world")
    |> Domain.add_action(:pickup, &AriaEngine.BlocksWorld.Actions.pickup/2)
    |> Domain.add_action(:putdown, &AriaEngine.BlocksWorld.Actions.putdown/2)
  end
end