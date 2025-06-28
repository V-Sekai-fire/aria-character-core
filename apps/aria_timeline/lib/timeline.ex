# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline do
  @moduledoc """
  Mock implementation of Timeline for compilation.

  This module provides timeline management functionality.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    intervals: list(),
    metadata: map()
  }

  defstruct intervals: [], metadata: %{}

  @doc """
  Add an interval to a timeline.
  """
  @spec add_interval(t(), map()) :: t()
  def add_interval(timeline, interval) do
    updated_intervals = [interval | timeline.intervals]
    %{timeline | intervals: updated_intervals}
  end

  @doc """
  Remove an interval from a timeline by ID.
  """
  @spec remove_interval(t(), String.t()) :: t()
  def remove_interval(timeline, interval_id) do
    updated_intervals = Enum.reject(timeline.intervals, fn interval ->
      Map.get(interval, :id) == interval_id
    end)
    %{timeline | intervals: updated_intervals}
  end

  @doc """
  Create a new empty timeline.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end
end
