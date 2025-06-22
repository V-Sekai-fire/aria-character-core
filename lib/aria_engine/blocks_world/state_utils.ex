defmodule AriaEngine.BlocksWorld.StateUtils do
  @moduledoc """
  Utilities for converting between GTPyhop state format and AriaEngine StateV2 predicate format.

  This module handles the conversion between the dictionary-based state representation
  used in GTPyhop and the predicate-based representation used in AriaEngine.StateV2.
  """

  alias AriaEngine.StateV2

  @doc """
  Convert from GTPyhop format to AriaEngine StateV2 predicate format.

  ## Examples

      iex> AriaEngine.BlocksWorld.StateUtils.from_gtpyhop_format(%{
      ...>   pos: %{"a" => "b", "b" => "table", "c" => "table"},
      ...>   clear: %{"a" => true, "b" => false, "c" => true},
      ...>   holding: %{"hand" => false}
      ...> })
      %AriaEngine.StateV2{
        facts: %{
          "pos" => [["a", "b"], ["b", "table"], ["c", "table"]],
          "clear" => [["a", "true"], ["b", "false"], ["c", "true"]],
          "holding" => [["hand", "false"]]
        }
      }
  """
  def from_gtpyhop_format(config) do
    facts = %{}

    # Convert position facts
    facts = if Map.has_key?(config, :pos) do
      pos_facts = Enum.map(config.pos, fn {block, position} ->
        [block, position]
      end)
      Map.put(facts, "pos", pos_facts)
    else
      facts
    end

    # Convert clear facts
    facts = if Map.has_key?(config, :clear) do
      clear_facts = Enum.map(config.clear, fn {block, is_clear} ->
        [block, to_string(is_clear)]
      end)
      Map.put(facts, "clear", clear_facts)
    else
      facts
    end

    # Convert holding facts
    facts = if Map.has_key?(config, :holding) do
      holding_facts = Enum.map(config.holding, fn {hand, held_block} ->
        [hand, to_string(held_block)]
      end)
      Map.put(facts, "holding", holding_facts)
    else
      facts
    end

    StateV2.new(facts)
  end

  @doc """
  Convert from AriaEngine StateV2 predicate format to GTPyhop format.

  This is useful for debugging and testing compatibility.

  ## Examples

      iex> state = AriaEngine.StateV2.new(%{
      ...>   "pos" => [["a", "b"], ["b", "table"], ["c", "table"]],
      ...>   "clear" => [["a", "true"], ["b", "false"], ["c", "true"]],
      ...>   "holding" => [["hand", "false"]]
      ...> })
      iex> AriaEngine.BlocksWorld.StateUtils.to_gtpyhop_format(state)
      %{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      }
  """
  def to_gtpyhop_format(state) do
    result = %{}

    # Convert position facts
    result = if StateV2.has_predicate?(state, "pos") do
      pos_facts = StateV2.get_all_facts(state, "pos")
      pos_map = Enum.into(pos_facts, %{}, fn [block, position] ->
        {block, position}
      end)
      Map.put(result, :pos, pos_map)
    else
      result
    end

    # Convert clear facts
    result = if StateV2.has_predicate?(state, "clear") do
      clear_facts = StateV2.get_all_facts(state, "clear")
      clear_map = Enum.into(clear_facts, %{}, fn [block, is_clear_str] ->
        is_clear = case is_clear_str do
          "true" -> true
          "false" -> false
          _ -> String.to_existing_atom(is_clear_str)
        end
        {block, is_clear}
      end)
      Map.put(result, :clear, clear_map)
    else
      result
    end

    # Convert holding facts
    result = if StateV2.has_predicate?(state, "holding") do
      holding_facts = StateV2.get_all_facts(state, "holding")
      holding_map = Enum.into(holding_facts, %{}, fn [hand, held_block_str] ->
        held_block = case held_block_str do
          "false" -> false
          block -> block
        end
        {hand, held_block}
      end)
      Map.put(result, :holding, holding_map)
    else
      result
    end

    result
  end

  @doc """
  Get the position of a block in the state.

  ## Examples

      iex> state = AriaEngine.BlocksWorld.StateUtils.from_gtpyhop_format(%{
      ...>   pos: %{"a" => "b", "b" => "table"}
      ...> })
      iex> AriaEngine.BlocksWorld.StateUtils.get_position(state, "a")
      "b"
      iex> AriaEngine.BlocksWorld.StateUtils.get_position(state, "b")
      "table"
  """
  def get_position(state, block) do
    case StateV2.get_fact(state, "pos", block) do
      {:ok, position} -> position
      :not_found -> nil
    end
  end

  @doc """
  Check if a block is clear.

  ## Examples

      iex> state = AriaEngine.BlocksWorld.StateUtils.from_gtpyhop_format(%{
      ...>   clear: %{"a" => true, "b" => false}
      ...> })
      iex> AriaEngine.BlocksWorld.StateUtils.is_clear?(state, "a")
      true
      iex> AriaEngine.BlocksWorld.StateUtils.is_clear?(state, "b")
      false
  """
  def is_clear?(state, block) do
    case StateV2.get_fact(state, "clear", block) do
      {:ok, "true"} -> true
      {:ok, "false"} -> false
      :not_found -> false
    end
  end

  @doc """
  Get what the hand is holding.

  ## Examples

      iex> state = AriaEngine.BlocksWorld.StateUtils.from_gtpyhop_format(%{
      ...>   holding: %{"hand" => "a"}
      ...> })
      iex> AriaEngine.BlocksWorld.StateUtils.get_holding(state)
      "a"

      iex> state = AriaEngine.BlocksWorld.StateUtils.from_gtpyhop_format(%{
      ...>   holding: %{"hand" => false}
      ...> })
      iex> AriaEngine.BlocksWorld.StateUtils.get_holding(state)
      false
  """
  def get_holding(state) do
    case StateV2.get_fact(state, "holding", "hand") do
      {:ok, "false"} -> false
      {:ok, block} -> block
      :not_found -> false
    end
  end

  @doc """
  Set the position of a block in the state.
  """
  def set_position(state, block, position) do
    StateV2.set_fact(state, "pos", block, position)
  end

  @doc """
  Set whether a block is clear.
  """
  def set_clear(state, block, is_clear) do
    StateV2.set_fact(state, "clear", block, to_string(is_clear))
  end

  @doc """
  Set what the hand is holding.
  """
  def set_holding(state, held_block) do
    StateV2.set_fact(state, "holding", "hand", to_string(held_block))
  end
end
