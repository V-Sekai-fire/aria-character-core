defmodule AriaEngine.BlocksWorld.Domain do
  @moduledoc """
  Blocks World domain implementation based on GTPyhop blocks_gtn example.

  This domain implements the Gupta-Nau optimal blocks-world planning algorithm
  using predicate-based state representation compatible with AriaEngine.StateV2.

  State Representation:
  - pos: {"pos", ["block_a", "table"]} - block_a is on the table
  - pos: {"pos", ["block_a", "block_b"]} - block_a is on block_b
  - pos: {"pos", ["block_a", "hand"]} - block_a is being held
  - clear: {"clear", ["block_a", "true"]} - block_a is clear
  - clear: {"clear", ["block_a", "false"]} - block_a is not clear
  - holding: {"holding", ["hand", "block_a"]} - hand is holding block_a
  - holding: {"holding", ["hand", "false"]} - hand is empty
  """

  alias AriaEngine.Domain
  alias AriaEngine.StateV2
  alias AriaEngine.BlocksWorld.{Actions, Methods, Helpers, StateUtils}

  @doc """
  Build the complete blocks world domain with actions and methods.
  """
  def build() do
    Domain.new("blocks_world")
    |> add_actions()
    |> add_methods()
  end

  @doc """
  Add all blocks world actions to the domain.
  """
  defp add_actions(domain) do
    domain
    |> Domain.add_action(:pickup, &Actions.pickup/2, %{duration: "PT1S"})
    |> Domain.add_action(:unstack, &Actions.unstack/2, %{duration: "PT1S"})
    |> Domain.add_action(:putdown, &Actions.putdown/2, %{duration: "PT1S"})
    |> Domain.add_action(:stack, &Actions.stack/2, %{duration: "PT1S"})
  end

  @doc """
  Add all blocks world methods to the domain.
  """
  defp add_methods(domain) do
    domain
    |> Domain.add_multigoal_method(&Methods.m_moveblocks/2)
    |> Domain.add_task_method("take", &Methods.m_take/2)
    |> Domain.add_task_method("put", &Methods.m_put/2)
  end

  @doc """
  Create an initial blocks world state from a simple configuration.

  ## Examples

      iex> AriaEngine.BlocksWorld.Domain.create_state(%{
      ...>   pos: %{"a" => "b", "b" => "table", "c" => "table"},
      ...>   clear: %{"a" => true, "b" => false, "c" => true},
      ...>   holding: %{"hand" => false}
      ...> })
      %AriaEngine.StateV2{...}
  """
  def create_state(config) do
    StateUtils.from_gtpyhop_format(config)
  end

  @doc """
  Create a multigoal from a simple position specification.

  ## Examples

      iex> AriaEngine.BlocksWorld.Domain.create_goal(%{"c" => "b", "b" => "a", "a" => "table"})
      [{"pos", ["c", "b"]}, {"pos", ["b", "a"]}, {"pos", ["a", "table"]}]
  """
  def create_goal(pos_map) do
    Enum.map(pos_map, fn {block, position} ->
      {"pos", [block, position]}
    end)
  end

  @doc """
  Get all blocks in the state.
  """
  def all_blocks(state) do
    Helpers.all_blocks(state)
  end

  @doc """
  Get all clear blocks in the state.
  """
  def all_clear_blocks(state) do
    Helpers.all_clear_blocks(state)
  end

  @doc """
  Check if a block is done (in its final position and won't need to move).
  """
  def is_done(block, state, goal) do
    Helpers.is_done(block, state, goal)
  end

  @doc """
  Get the status of a block (done, inaccessible, move-to-table, move-to-block, waiting).
  """
  def status(block, state, goal) do
    Helpers.status(block, state, goal)
  end
end
