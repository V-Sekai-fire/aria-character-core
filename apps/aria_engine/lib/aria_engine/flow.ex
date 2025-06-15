# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Flow do
  @moduledoc """
  Defines the behaviour for a Flow.
  """
  @callback start_link(any()) :: {:ok, pid()} | {:error, any()}
  @callback child_spec(any()) :: map()

  def start_link(opts) do
    {:ok, spawn_link(fn -> :timer.sleep(:infinity) end)}
  end

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end
end
