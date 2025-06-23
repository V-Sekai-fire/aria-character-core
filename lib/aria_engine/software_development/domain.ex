# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SoftwareDevelopment.Domain do
  alias AriaEngine.Domain

  def build do
    Domain.new("software_development")
    |> Domain.add_action(:write_code, fn state, _args -> {:ok, state} end)
    |> Domain.add_action(:test_code, fn state, _args -> {:ok, state} end)
  end
end
