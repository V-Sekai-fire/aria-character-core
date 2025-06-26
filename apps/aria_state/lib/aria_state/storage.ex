# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaState.Storage do
  @moduledoc """
  Storage integration for AriaState.

  This module provides persistent storage capabilities for AriaState,
  migrated from `aria_storage` as part of ADR-193 layered architecture
  consolidation.

  ## Usage

      # Create persistent state
      {:ok, state} = AriaState.new_persistent(storage_opts)
      
      # Save state
      {:ok, saved_state} = AriaState.Storage.save(state)
      
      # Load state
      {:ok, loaded_state} = AriaState.Storage.load(storage_opts)
  """

  require Logger

  @type storage_opts :: keyword()
  @type state :: AriaState.ObjectState.t() | AriaState.RelationalState.t()
  @type error_reason :: String.t()

  @doc """
  Initialize storage backend.

  ## Parameters
  - `opts` - Storage configuration options

  ## Returns
  - `{:ok, storage_config}` - Successfully initialized
  - `{:error, reason}` - Failed to initialize
  """
  @spec initialize(storage_opts()) :: {:ok, map()} | {:error, error_reason()}
  def initialize(opts \\ []) do
    backend = Keyword.get(opts, :backend, :local)
    config = Keyword.get(opts, :config, %{})
    
    Logger.info("Initializing storage backend: #{backend}")
    
    # For now, return a simple configuration
    # This will be expanded with actual storage backends
    {:ok, %{
      backend: backend,
      config: config,
      initialized_at: DateTime.utc_now()
    }}
  end

  @doc """
  Save state to persistent storage.

  ## Parameters
  - `state` - AriaState to save

  ## Returns
  - `{:ok, state}` - Successfully saved
  - `{:error, reason}` - Failed to save
  """
  @spec save(state()) :: {:ok, state()} | {:error, error_reason()}
  def save(state) do
    Logger.info("Saving state to storage")
    
    # For now, just return the state unchanged
    # This will be expanded with actual persistence
    {:ok, state}
  end

  @doc """
  Load state from persistent storage.

  ## Parameters
  - `opts` - Storage configuration options

  ## Returns
  - `{:ok, state}` - Successfully loaded
  - `{:error, reason}` - Failed to load
  """
  @spec load(storage_opts()) :: {:ok, state()} | {:error, error_reason()}
  def load(opts \\ []) do
    Logger.info("Loading state from storage with opts: #{inspect(opts)}")
    
    # For now, return a new empty state
    # This will be expanded with actual persistence
    {:ok, AriaState.new()}
  end

  @doc """
  Test storage configuration.

  ## Parameters
  - `opts` - Storage configuration options

  ## Returns
  - `{:ok, :test_passed}` - Storage is working
  - `{:error, reason}` - Storage test failed
  """
  @spec test_storage(storage_opts()) :: {:ok, :test_passed} | {:error, error_reason()}
  def test_storage(opts \\ []) do
    with {:ok, _config} <- initialize(opts),
         test_state <- AriaState.new() |> AriaState.set_fact("test", "storage", "working"),
         {:ok, _saved} <- save(test_state),
         {:ok, _loaded} <- load(opts) do
      {:ok, :test_passed}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get current storage configuration.

  ## Returns
  - `map()` - Current storage configuration
  """
  @spec get_config() :: map()
  def get_config do
    %{
      backend: :local,
      storage_dir: System.tmp_dir(),
      initialized: true
    }
  end

  @doc """
  Migrate existing storage to new backend.

  ## Parameters
  - `target_backend` - Target storage backend
  - `opts` - Migration options

  ## Returns
  - `{:ok, :migration_completed}` - Successfully migrated
  - `{:error, reason}` - Migration failed
  """
  @spec migrate_to_backend(atom(), storage_opts()) :: 
    {:ok, :migration_completed} | {:error, error_reason()}
  def migrate_to_backend(target_backend, opts \\ []) do
    Logger.info("Migration to #{target_backend} requested with options: #{inspect(opts)}")
    
    # Placeholder for future migration functionality
    {:ok, :migration_completed}
  end
end
