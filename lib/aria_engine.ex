defmodule AriaEngine do
  @moduledoc "Main AriaEngine module providing utility functions.\n\nThis module contains utility functions that are used across the AriaEngine system.\n"
  alias AriaEngine.State
  alias TimelineGraph
  @type domain :: map()
  @type state :: State.t()
  @type todos :: list()
  @type plan :: term()
  @type opts :: keyword()
  @doc "Creates a new empty multigoal structure.\n"
  @spec create_multigoal() :: Multigoal.t()
  def create_multigoal do
    Multigoal.new()
  end

  @doc "Creates a new empty state using StateV2.\n"
  @spec create_state() :: State.t()
  def create_state do
    State.new()
  end
end