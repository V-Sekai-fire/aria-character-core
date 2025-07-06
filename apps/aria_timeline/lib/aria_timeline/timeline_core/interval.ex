# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline.TimelineCore.Interval do
  @moduledoc """
  Mock implementation of AriaTimeline.TimelineCore.Interval for compilation.

  This module provides interval management functionality for timelines.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: %__MODULE__{
    id: String.t(),
    start_time: DateTime.t(),
    end_time: DateTime.t() | nil,
    data: map()
  }

  defstruct [:id, :start_time, :end_time, :data]

  @doc """
  Create a new interval.
  """
  @spec new(DateTime.t(), DateTime.t() | nil, map()) :: t()
  def new(start_time, end_time, data \\ %{}) do
    %__MODULE__{
      id: generate_id(),
      start_time: start_time,
      end_time: end_time,
      data: data
    }
  end

  defp generate_id do
    "interval_#{System.unique_integer([:positive])}"
  end
end
