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
    state = StateV2.new()

    # Convert position facts
    state = if Map.has_key?(config, :pos) do
      Enum.reduce(config.pos, state, fn {block, position}, acc_state ->
        StateV2.set_fact(acc_state, block, "pos", position)
      end)
    else
      state
    end

    # Convert clear facts
    state = if Map.has_key?(config, :clear) do
      Enum.reduce(config.clear, state, fn {block, is_clear}, acc_state ->
        StateV2.set_fact(acc_state, block, "clear", to_string(is_clear))
      end)
    else
      state
    end

    # Convert holding facts
    state = if Map.has_key?(config, :holding) do
      Enum.reduce(config.holding, state, fn {hand, held_block}, acc_state ->
        StateV2.set_fact(acc_state, hand, "holding", to_string(held_block))
      end)
    else
      state
    end

    state
  end

  @doc """
  Convert from AriaEngine StateV2 predicate format to GTPyhop format.

  This is useful for debugging and testing compatibility.

  ## Examples

      iex> state = AriaEngine.StateV2.new()
      ...> |> AriaEngine.StateV2.set_fact("a", "pos", "b")
      ...> |> AriaEngine.StateV2.set_fact("b", "pos", "table")
      ...> |> AriaEngine.StateV2.set_fact("c", "pos", "table")
      ...> |> AriaEngine.StateV2.set_fact("a", "clear", "true")
      ...> |> AriaEngine.StateV2.set_fact("b", "clear", "false")
      ...> |> AriaEngine.StateV2.set_fact("c", "clear", "true")
      ...> |> AriaEngine.StateV2.set_fact("hand", "holding", "false")
      iex> AriaEngine.BlocksWorld.StateUtils.to_gtpyhop_format(state)
      %{
        pos: %{"a" => "b", "b" => "table", "c" => "table"},
        clear: %{"a" => true, "b" => false, "c" => true},
        holding: %{"hand" => false}
      }
  """
  def to_gtpyhop_format(state) do
    result = %{}

    # Convert position facts - get all subjects that have "pos" predicate
    pos_subjects = StateV2.get_subjects_with_predicate(state, "pos")
    result = if length(pos_subjects) > 0 do
      pos_map = Enum.into(pos_subjects, %{}, fn block ->
        position = StateV2.get_fact(state, block, "pos")
        {block, position}
      end)
      Map.put(result, :pos, pos_map)
    else
      result
    end

    # Convert clear facts - get all subjects that have "clear" predicate
    clear_subjects = StateV2.get_subjects_with_predicate(state, "clear")
    result = if length(clear_subjects) > 0 do
      clear_map = Enum.into(clear_subjects, %{}, fn block ->
        is_clear_str = StateV2.get_fact(state, block, "clear")
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

    # Convert holding facts - get all subjects that have "holding" predicate
    holding_subjects = StateV2.get_subjects_with_predicate(state, "holding")
    result = if length(holding_subjects) > 0 do
      holding_map = Enum.into(holding_subjects, %{}, fn hand ->
        held_block_str = StateV2.get_fact(state, hand, "holding")
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
