# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaJoint.Registry do
  @moduledoc """
  Registry management for Joint nodes.

  Handles node registration, updates, and lookup operations with proper
  error handling and timeout management.
  """

  @registry_name :joint_registry
  @registry_timeout 5000

  @type node_id() :: reference()
  @type joint_error ::
    :registry_unavailable |
    :node_not_found |
    :registry_timeout |
    :registry_sync_failed

  @doc """
  Ensure the registry is available and running.
  """
  @spec ensure_registry() :: :ok | {:error, joint_error()}
  def ensure_registry do
    case Process.whereis(@registry_name) do
      nil ->
        # Try to start registry
        case Registry.start_link(keys: :unique, name: @registry_name) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end
      _pid -> :ok
    end
  end

  @doc """
  Register a node in the registry.
  """
  @spec register_node(AriaJoint.Joint.t()) :: {:ok, pid()} | {:error, joint_error()}
  def register_node(node) do
    case Registry.register(@registry_name, node.id, node) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_registered, _pid}} -> {:error, :node_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Look up a node by ID.
  """
  @spec get_node_by_id(node_id()) :: AriaJoint.Joint.t() | nil
  def get_node_by_id(node_id) do
    case Registry.lookup(@registry_name, node_id) do
      [{_pid, node}] -> node
      [] -> nil
    end
  end

  @doc """
  Update a node in the registry.
  """
  @spec update_node(AriaJoint.Joint.t()) :: :ok | {:error, joint_error()}
  def update_node(node) do
    try do
      case Registry.lookup(@registry_name, node.id) do
        [{_pid, _old_node}] ->
          case Registry.update_value(@registry_name, node.id, fn _old_node -> node end) do
            {_old_value, _new_value} -> :ok
            {:error, reason} -> {:error, reason}
          end

        [] ->
          {:error, :node_not_found}
      end
    rescue
      _error -> {:error, :registry_unavailable}
    end
  end

  @doc """
  Unregister a node from the registry.
  """
  @spec unregister_node(node_id()) :: :ok
  def unregister_node(node_id) do
    Registry.unregister(@registry_name, node_id)
  end

  @doc """
  Check if registry is available with timeout.
  """
  @spec ensure_registry_with_timeout() :: {:ok, pid()} | {:error, joint_error()}
  def ensure_registry_with_timeout do
    try do
      case Process.whereis(@registry_name) do
        nil -> {:error, :registry_unavailable}
        pid when is_pid(pid) -> {:ok, pid}
      end
    rescue
      _error -> {:error, :registry_unavailable}
    end
  end
end
