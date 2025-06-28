defmodule AriaTimeline.TimelineCore do
  @moduledoc """
  Mock implementation of AriaTimeline.TimelineCore for compilation.

  This module provides the core timeline functionality.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: map()

  @doc """
  Create a new timeline.
  """
  @spec new() :: t()
  def new do
    %{events: [], duration: 0}
  end

  @doc """
  Add an event to the timeline.
  """
  @spec add_event(t(), map()) :: t()
  def add_event(timeline, event) do
    Map.update(timeline, :events, [event], fn events -> [event | events] end)
  end
end
