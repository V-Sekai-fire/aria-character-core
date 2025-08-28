# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.Mocks.ExecutorBehaviour do
  @moduledoc """
  Mock implementation of AriaMinizincExecutor.ExecutorBehaviour for testing.

  Provides configurable responses for testing different execution scenarios
  without requiring actual MiniZinc installation.
  """

  use Mox

  defmock(AriaMinizincExecutor.Mocks.ExecutorBehaviour, for: AriaMinizincExecutor.ExecutorBehaviour)
end
