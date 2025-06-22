defmodule AriaEngine.BlocksWorld.Actions do
  @moduledoc """
  Blocks World primitive actions implementation.

  This module implements the four basic blocks world actions:
  - pickup: Pick up a block from the table
  - unstack: Remove a block from on top of another block
  - putdown: Place a held block on the table
  - stack: Place a held block on top of another block

  All actions use predicate-based state representation compatible with AriaEngine.StateV2.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.BlocksWorld.StateUtils

  @doc """
  Pick up a block from the table.

  Preconditions:
  - Block must be on the table
  - Block must be clear
  - Hand must be empty

  Effects:
  - Block position changes from table to hand
  - Hand is now holding the block
  - Block is no longer clear (since it's being held)
  """
  def pickup(state, [block]) do
    with {:ok, position} <- StateV2.get_fact(state, "pos", block),
         {:ok, "true"} <- StateV2.get_fact(state, "clear", block),
         {:ok, "false"} <- StateV2.get_fact(state, "holding", "hand") do

      if position == "table" do
        state
        |> StateV2.set_fact("pos", block, "hand")
        |> StateV2.set_fact("holding", "hand", block)
        |> StateV2.set_fact("clear", block, "false")
        |> then(&{:ok, &1})
      else
        {:error, "Block #{block} is not on the table (position: #{position})"}
      end
    else
      {:ok, "false"} -> {:error, "Block #{block} is not clear"}
      {:ok, held_block} when held_block != "false" -> {:error, "Hand is already holding #{held_block}"}
      :not_found -> {:error, "Block #{block} not found in state"}
    end
  end

  @doc """
  Remove a block from on top of another block.

  Preconditions:
  - Block1 must be on top of Block2
  - Block1 must be clear
  - Hand must be empty

  Effects:
  - Block1 position changes from Block2 to hand
  - Hand is now holding Block1
  - Block1 is no longer clear (since it's being held)
  - Block2 becomes clear
  """
  def unstack(state, [block1, block2]) do
    with {:ok, position} <- StateV2.get_fact(state, "pos", block1),
         {:ok, "true"} <- StateV2.get_fact(state, "clear", block1),
         {:ok, "false"} <- StateV2.get_fact(state, "holding", "hand") do

      if position == block2 do
        state
        |> StateV2.set_fact("pos", block1, "hand")
        |> StateV2.set_fact("holding", "hand", block1)
        |> StateV2.set_fact("clear", block1, "false")
        |> StateV2.set_fact("clear", block2, "true")
        |> then(&{:ok, &1})
      else
        {:error, "Block #{block1} is not on top of #{block2} (position: #{position})"}
      end
    else
      {:ok, "false"} -> {:error, "Block #{block1} is not clear"}
      {:ok, held_block} when held_block != "false" -> {:error, "Hand is already holding #{held_block}"}
      :not_found -> {:error, "Block #{block1} not found in state"}
    end
  end

  @doc """
  Place a held block on the table.

  Preconditions:
  - Hand must be holding the block

  Effects:
  - Block position changes from hand to table
  - Hand becomes empty
  - Block becomes clear
  """
  def putdown(state, [block]) do
    with {:ok, held_block} <- StateV2.get_fact(state, "holding", "hand") do
      if held_block == block do
        state
        |> StateV2.set_fact("pos", block, "table")
        |> StateV2.set_fact("holding", "hand", "false")
        |> StateV2.set_fact("clear", block, "true")
        |> then(&{:ok, &1})
      else
        {:error, "Hand is not holding #{block} (holding: #{held_block})"}
      end
    else
      :not_found -> {:error, "Hand holding state not found"}
    end
  end

  @doc """
  Place a held block on top of another block.

  Preconditions:
  - Hand must be holding block1
  - Block2 must be clear

  Effects:
  - Block1 position changes from hand to block2
  - Hand becomes empty
  - Block1 becomes clear
  - Block2 is no longer clear
  """
  def stack(state, [block1, block2]) do
    with {:ok, held_block} <- StateV2.get_fact(state, "holding", "hand"),
         {:ok, "true"} <- StateV2.get_fact(state, "clear", block2) do

      if held_block == block1 do
        state
        |> StateV2.set_fact("pos", block1, block2)
        |> StateV2.set_fact("holding", "hand", "false")
        |> StateV2.set_fact("clear", block1, "true")
        |> StateV2.set_fact("clear", block2, "false")
        |> then(&{:ok, &1})
      else
        {:error, "Hand is not holding #{block1} (holding: #{held_block})"}
      end
    else
      {:ok, "false"} -> {:error, "Block #{block2} is not clear"}
      :not_found -> {:error, "State information not found"}
    end
  end
end
