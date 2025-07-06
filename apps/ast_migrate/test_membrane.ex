# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaEngine.Membrane.Format.TestModule do
  alias AriaEngine.Membrane.Format.PlanningResult

  def test_function do
    AriaEngine.Membrane.Format.PlanningResult.success(%{}, "test", %{}, %{})
  end
end
