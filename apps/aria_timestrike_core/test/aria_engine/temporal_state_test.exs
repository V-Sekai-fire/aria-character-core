# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TemporalStateTest do
  use ExUnit.Case, async: true

  alias AriaEngine.TemporalState

  describe "Maya's Adaptive Scorch scenario initialization" do
    test "initializes Maya's Adaptive Scorch scenario state" do
      initial_state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
      |> TemporalState.set_temporal_object("vision_range", "maya", 8, 0)
      |> TemporalState.set_temporal_object("position", "alex", {4, 4, 0}, 0)
      |> TemporalState.set_temporal_object("position", "soldier2", {15, 5, 0}, 0)

      assert TemporalState.get_temporal_object(initial_state, "position", "maya", 0) == {3, 5, 0}
      assert TemporalState.get_temporal_object(initial_state, "vision_range", "maya", 0) == 8
    end

    test "supports time-based queries for state history" do
      state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "soldier2", {15, 5, 0}, 0)
      |> TemporalState.set_temporal_object("position", "soldier2", {14, 5, 0}, 10)
      |> TemporalState.set_temporal_object("position", "soldier2", {13, 5, 0}, 20)

      assert TemporalState.get_temporal_object(state, "position", "soldier2", 5) == {15, 5, 0}
      assert TemporalState.get_temporal_object(state, "position", "soldier2", 15) == {14, 5, 0}
      assert TemporalState.query_history(state, "position", "soldier2", 0, 25) == 
             [{0, {15, 5, 0}}, {10, {14, 5, 0}}, {20, {13, 5, 0}}]
    end

    test "supports temporal interpolation for smooth movement queries" do
      state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
      |> TemporalState.set_temporal_object("position", "maya", {8, 5, 0}, 10)

      # Query at intermediate time should interpolate position
      assert TemporalState.get_temporal_object(state, "position", "maya", 5) == {5.5, 5, 0}
      assert TemporalState.get_temporal_object(state, "position", "maya", 7) == {6.5, 5, 0}
    end

    test "handles complex agent state with multiple properties" do
      state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
      |> TemporalState.set_temporal_object("health", "maya", 100, 0)
      |> TemporalState.set_temporal_object("mana", "maya", 50, 0)
      |> TemporalState.set_temporal_object("health", "maya", 85, 15)  # Took damage
      |> TemporalState.set_temporal_object("mana", "maya", 25, 20)   # Cast spell

      assert TemporalState.get_temporal_object(state, "health", "maya", 10) == 100
      assert TemporalState.get_temporal_object(state, "health", "maya", 18) == 85
      assert TemporalState.get_temporal_object(state, "mana", "maya", 25) == 25
    end
  end

  describe "temporal state validation and consistency" do
    test "validates temporal consistency of state transitions" do
      state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
      |> TemporalState.set_temporal_object("position", "maya", {100, 100, 0}, 1)  # Impossible movement

      assert {:error, :impossible_transition} = TemporalState.validate_consistency(state, "maya", movement_speed: 2.0)
    end

    test "supports state rollback to previous valid state" do
      state = TemporalState.new(0)
      |> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
      |> TemporalState.set_temporal_object("position", "maya", {8, 5, 0}, 10)
      |> TemporalState.set_temporal_object("position", "maya", {15, 5, 0}, 20)

      rolled_back_state = TemporalState.rollback_to_time(state, 15)
      
      assert TemporalState.get_temporal_object(rolled_back_state, "position", "maya", 15) == {8, 5, 0}
      assert TemporalState.get_temporal_object(rolled_back_state, "position", "maya", 25) == nil
    end
  end
end
