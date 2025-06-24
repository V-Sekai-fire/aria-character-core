# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ExecutorBehaviour do
  @moduledoc """
  Behaviour for MiniZinc execution to enable mocking in tests.
  """

  @callback exec(String.t(), Keyword.t()) :: {:ok, map()} | {:error, term()}
  @callback spawn(String.t(), Keyword.t()) :: {:ok, term()} | {:error, term()}
  @callback check_availability() :: {:ok, String.t()} | {:error, String.t()}
end
