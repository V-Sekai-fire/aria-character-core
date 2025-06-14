# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.SystemDomain do
  @moduledoc """
  System domain for TUI observability and system monitoring.
  
  This domain provides actions and methods for observing system state,
  handling observation intents, and managing system metrics through
  the symbolic planner interface.
  """

  alias AriaEngine.{Domain, State}
  require Logger

  @doc """
  Creates the system domain with observation actions and methods.
  """
  @spec create_domain() :: Domain.t()
  def create_domain do
    Domain.new("system_tui")
    |> Domain.add_action(:observe_system_metrics, &observe_system_metrics/2)
    |> Domain.add_action(:observe_tui_state, &observe_tui_state/2)
    |> Domain.add_action(:update_observation_intent, &update_observation_intent/2)
    |> Domain.add_task_methods("observe_world_state", [
      &observe_world_state_method/2
    ])
    |> Domain.add_unigoal_method("observation_completed", &ensure_observation_completed/2)
    |> Domain.add_unigoal_method("system_status_known", &ensure_system_status_known/2)
  end

  # Actions for observation intents

  @doc """
  Observe system metrics with potential for failure.
  This represents an observation intent that may fail due to system issues.
  """
  @spec observe_system_metrics(State.t(), [atom()]) :: State.t() | false
  def observe_system_metrics(state, [metric_type]) do
    case metric_type do
      :cpu_usage ->
        if :rand.uniform() > 0.05 do  # 95% success rate
          cpu_value = 10.0 + :rand.uniform() * 30.0  # Simulate realistic CPU usage
          state
          |> State.set_object("system_metric", "cpu_usage", cpu_value)
          |> State.set_object("observation_status", "cpu_usage", "success")
          |> State.set_object("observation_timestamp", "cpu_usage", :os.system_time(:second))
        else
          Logger.warning("Failed to observe CPU usage - sensor unavailable")
          state
          |> State.set_object("observation_status", "cpu_usage", "failed")
          |> State.set_object("observation_error", "cpu_usage", "sensor_unavailable")
        end

      :memory_usage ->
        if :rand.uniform() > 0.03 do  # 97% success rate
          memory_value = 30.0 + :rand.uniform() * 40.0  # Simulate realistic memory usage
          state
          |> State.set_object("system_metric", "memory_usage", memory_value)
          |> State.set_object("observation_status", "memory_usage", "success")
          |> State.set_object("observation_timestamp", "memory_usage", :os.system_time(:second))
        else
          Logger.warning("Failed to observe memory usage - permission denied")
          state
          |> State.set_object("observation_status", "memory_usage", "failed")
          |> State.set_object("observation_error", "memory_usage", "permission_denied")
        end

      :network_status ->
        if :rand.uniform() > 0.10 do  # 90% success rate
          network_status = if :rand.uniform() > 0.2, do: "connected", else: "limited"
          state
          |> State.set_object("system_metric", "network_status", network_status)
          |> State.set_object("observation_status", "network_status", "success")
          |> State.set_object("observation_timestamp", "network_status", :os.system_time(:second))
        else
          Logger.warning("Failed to observe network status - timeout")
          state
          |> State.set_object("observation_status", "network_status", "failed")
          |> State.set_object("observation_error", "network_status", "timeout")
        end

      _ ->
        Logger.warning("Unknown metric type: #{metric_type}")
        false
    end
  end

  @doc """
  Observe TUI-specific state information.
  """
  @spec observe_tui_state(State.t(), [atom()]) :: State.t() | false
  def observe_tui_state(state, [tui_aspect]) do
    case tui_aspect do
      :terminal_size ->
        # Simulate terminal size observation
        {width, height} = get_terminal_size()
        state
        |> State.set_object("tui_metric", "terminal_width", width)
        |> State.set_object("tui_metric", "terminal_height", height)
        |> State.set_object("observation_status", "terminal_size", "success")

      :display_mode ->
        # Simulate display mode observation
        mode = if :rand.uniform() > 0.3, do: "enhanced", else: "compact"
        state
        |> State.set_object("tui_metric", "display_mode", mode)
        |> State.set_object("observation_status", "display_mode", "success")

      _ ->
        Logger.warning("Unknown TUI aspect: #{tui_aspect}")
        false
    end
  end

  @doc """
  Update an observation intent status.
  """
  @spec update_observation_intent(State.t(), [String.t()]) :: State.t() | false
  def update_observation_intent(state, [intent_id, status]) do
    state
    |> State.set_object("observation_intent", intent_id, status)
    |> State.set_object("observation_updated", intent_id, :os.system_time(:second))
  end

  # Task methods

  @doc """
  Method to observe world state through multiple observation intents.
  """
  @spec observe_world_state_method(State.t(), [atom()]) :: [tuple()] | false
  def observe_world_state_method(_state, [observation_type]) do
    case observation_type do
      :system_metrics ->
        [
          {:observe_system_metrics, [:cpu_usage]},
          {:observe_system_metrics, [:memory_usage]},
          {:observe_system_metrics, [:network_status]}
        ]

      :tui_state ->
        [
          {:observe_tui_state, [:terminal_size]},
          {:observe_tui_state, [:display_mode]}
        ]

      :comprehensive ->
        [
          {:observe_system_metrics, [:cpu_usage]},
          {:observe_system_metrics, [:memory_usage]},
          {:observe_tui_state, [:terminal_size]}
        ]

      _ ->
        Logger.warning("Unknown observation type: #{observation_type}")
        false
    end
  end

  # Unigoal methods

  @doc """
  Ensure an observation has been completed successfully.
  """
  @spec ensure_observation_completed(State.t(), [String.t()]) :: [tuple()] | false
  def ensure_observation_completed(state, [observation_id]) do
    case State.get_object(state, "observation_status", observation_id) do
      "success" ->
        []  # Already completed

      "failed" ->
        # Retry the observation
        case determine_observation_action(observation_id) do
          {:ok, action, params} -> [{action, params}]
          :error -> false
        end

      nil ->
        # No observation yet, start one
        case determine_observation_action(observation_id) do
          {:ok, action, params} -> [{action, params}]
          :error -> false
        end

      _ ->
        false
    end
  end

  @doc """
  Ensure system status is known through observations.
  """
  @spec ensure_system_status_known(State.t(), [String.t()]) :: [tuple()] | false
  def ensure_system_status_known(state, [system_component]) do
    case State.get_object(state, "system_status", system_component) do
      nil ->
        # Need to observe system status
        [{"observe_world_state", [:system_metrics]}]

      "unknown" ->
        # Need to re-observe
        [{"observe_world_state", [:system_metrics]}]

      _ ->
        []  # Status already known
    end
  end

  # Helper functions

  defp get_terminal_size do
    # Try to get actual terminal size, fallback to defaults
    case :io.columns() do
      {:ok, width} ->
        case :io.rows() do
          {:ok, height} -> {width, height}
          {:error, _} -> {width, 24}  # Default height
        end
      {:error, _} ->
        {80, 24}  # Default terminal size
    end
  end

  defp determine_observation_action(observation_id) do
    case observation_id do
      "cpu_usage" -> {:ok, :observe_system_metrics, [:cpu_usage]}
      "memory_usage" -> {:ok, :observe_system_metrics, [:memory_usage]}
      "network_status" -> {:ok, :observe_system_metrics, [:network_status]}
      "terminal_size" -> {:ok, :observe_tui_state, [:terminal_size]}
      "display_mode" -> {:ok, :observe_tui_state, [:display_mode]}
      _ -> :error
    end
  end
end
