# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN.MiniZincSolver do
  @moduledoc """
  MiniZinc-based STN solver that delegates to the dedicated AriaMinizincStn app.

  This module maintains the existing interface while delegating all actual
  STN solving to the specialized aria_minizinc_stn application.
  """
  alias Timeline.Internal.STN
  require Logger

  @doc """
  Solves an STN using MiniZinc constraint solver via delegation.

  Returns an updated STN with consistency information and potentially
  tightened constraints based on the MiniZinc solution.
  """
  @spec solve_stn(STN.t()) :: STN.t()
  def solve_stn(stn) do
    case AriaMinizincStn.solve_stn(stn) do
      {:ok, updated_stn} ->
        updated_stn

      {:error, reason} ->
        Logger.warning("STN solving failed: #{reason}")
        %{stn | consistent: false}
    end
  end
end
