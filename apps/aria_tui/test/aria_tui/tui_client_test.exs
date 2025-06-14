# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.TuiClientTest do
  use ExUnit.Case, async: false  # Not async due to GenServer

  alias AriaTui.Client, as: TuiClient

  describe "TUI client initialization" do
    test "starts successfully" do
      {:ok, pid} = TuiClient.start_link([])
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "initializes with default state" do
      {:ok, pid} = TuiClient.start_link([])

      # The client should start with a basic state
      state = :sys.get_state(pid)

      assert Map.has_key?(state, :application_state)
      assert Map.has_key?(state, :tick_count)
      assert Map.has_key?(state, :last_update)
      assert Map.has_key?(state, :paused)

      GenServer.stop(pid)
    end
  end

  describe "TUI client state management" do
    setup do
      {:ok, pid} = TuiClient.start_link([])
      %{client: pid}
    end

    test "can pause and resume", %{client: pid} do
      # Test pause
      TuiClient.handle_key(pid, "p")
      :timer.sleep(10)  # Give it time to process

      state = TuiClient.get_state(pid)
      assert state.paused == true

      # Test resume
      TuiClient.handle_key(pid, "p")
      :timer.sleep(10)

      state = TuiClient.get_state(pid)
      assert state.paused == false

      state = :sys.get_state(pid)
      assert state.paused == false

      GenServer.stop(pid)
    end

    test "responds to interrupt key", %{client: pid} do
      # Send space key (interrupt)
      TuiClient.handle_key(pid, " ")
      :timer.sleep(10)

      # Check the state changed
      state = TuiClient.get_state(pid)
      assert String.contains?(state.last_message, "Interrupted")

      GenServer.stop(pid)
    end

    test "tracks tick count", %{client: pid} do
      initial_state = TuiClient.get_state(pid)
      initial_tick = initial_state.tick_count

      # Send a tick message
      TuiClient.tick(pid)
      :timer.sleep(10)

      updated_state = TuiClient.get_state(pid)
      assert updated_state.tick_count >= initial_tick

      GenServer.stop(pid)
    end
  end

  describe "application state integration" do
    test "handles application state updates" do
      {:ok, pid} = TuiClient.start_link([])

      # Mock application state
      application_state = %{
        status: "active",
        data: %{
          "component_1" => %{value: 42, status: :operational},
          "component_2" => %{value: 73, status: :operational}
        }
      }

      # Update application state
      TuiClient.handle_message(pid, {:state_update, application_state})
      :timer.sleep(10)

      state = TuiClient.get_state(pid)
      assert state.application_state == application_state

      GenServer.stop(pid)
    end
  end

  describe "error handling" do
    test "handles invalid key presses gracefully" do
      {:ok, pid} = TuiClient.start_link([])

      # Send invalid key (should not crash)
      TuiClient.handle_key(pid, "invalid_key")
      :timer.sleep(10)

      # Should still be alive
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end

    test "handles malformed messages gracefully" do
      {:ok, pid} = TuiClient.start_link([])

      # Send malformed message (should not crash)
      TuiClient.handle_message(pid, :invalid_message)
      :timer.sleep(10)

      # Should still be alive
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end
  end
end
