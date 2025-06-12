# Dual Storage Implementation Plan

## Overview

This document outlines the detailed implementation plan for running Waffle local storage alongside the existing aria_storage desync algorithm as a safety measure. The goal is to implement dual storage that writes to both systems simultaneously while maintaining the option to read from either, allowing for safe transition testing.

## Current Architecture Analysis

### Existing Infrastructure
✅ **Already Available:**
- `WaffleAdapter` - ChunkStore.Behaviour implementation
- `WaffleChunkStore` - Waffle definition for chunk storage  
- `WaffleConfig` - Configuration helpers
- `ChunkUploader` - Waffle uploader definition
- `storage.ex` - Supports multiple chunk stores with fallback mechanisms
- `ChunkStore.Behaviour` - Interface for storage backends

### Current Storage Flow
```
Storage.store_chunks(chunks, opts)
├── get_chunk_stores(opts) -> List of configured stores
├── get_cache_store(opts) -> Optional cache store
└── store_single_chunk(chunk, stores, cache, verify)
    ├── Try cache first (if available)
    └── store_in_primary_stores(chunk, stores)
        └── Try stores in order with fallback
```

## Implementation Plan

### Phase 1: Dual Storage Configuration

#### 1.1 Update Configuration System
**File:** `config/dev.exs`, `config/prod.exs`

Add dual storage configuration:
```elixir
config :aria_storage,
  # Enable dual storage mode
  dual_storage_enabled: true,
  
  # Primary storage (existing desync system)
  chunk_stores: [
    %{type: :desync, backend: :local, path: "priv/storage/chunks"},
    # Add more desync stores as needed
  ],
  
  # Safety storage (Waffle-based)
  safety_stores: [
    %{type: :waffle, backend: :local, path: "priv/safety_storage/chunks"}
  ],
  
  # Dual storage options
  dual_storage_options: %{
    write_to_both: true,           # Write to both systems
    verify_both: true,             # Verify chunks in both systems
    read_preference: :primary,     # :primary, :safety, or :fastest
    fallback_enabled: true,        # Fall back to safety store on primary failure
    comparison_logging: true       # Log differences between systems
  }
```

#### 1.2 Create Dual Storage Manager
**File:** `apps/aria_storage/lib/aria_storage/dual_storage_manager.ex`

```elixir
defmodule AriaStorage.DualStorageManager do
  @moduledoc """
  Manages dual storage operations between primary (desync) and safety (Waffle) systems.
  
  Provides:
  - Dual write operations
  - Read with fallback
  - Comparison and verification
  - Migration support
  """

  alias AriaStorage.{ChunkStore, WaffleAdapter, Chunks}

  defstruct [
    :primary_stores,    # List of primary chunk stores (desync)
    :safety_stores,     # List of safety chunk stores (waffle)
    :options           # Dual storage options
  ]

  @type t :: %__MODULE__{
    primary_stores: [ChunkStore.t()],
    safety_stores: [ChunkStore.t()],
    options: map()
  }

  def new(opts \\ []) do
    %__MODULE__{
      primary_stores: get_primary_stores(opts),
      safety_stores: get_safety_stores(opts),
      options: get_dual_storage_options(opts)
    }
  end

  @doc """
  Stores a chunk in both primary and safety systems.
  """
  def store_chunk_dual(%__MODULE__{} = manager, %Chunks{} = chunk) do
    # Implementation details in Phase 1.3
  end

  @doc """
  Retrieves a chunk with fallback between systems.
  """
  def get_chunk_dual(%__MODULE__{} = manager, chunk_id) do
    # Implementation details in Phase 1.3
  end

  @doc """
  Compares chunk between primary and safety systems.
  """
  def compare_chunk(%__MODULE__{} = manager, chunk_id) do
    # Implementation details in Phase 2.1
  end

  # Private functions for configuration
  defp get_primary_stores(opts), do: # ...
  defp get_safety_stores(opts), do: # ...
  defp get_dual_storage_options(opts), do: # ...
end
```

#### 1.3 Implement Core Dual Operations
**File:** `apps/aria_storage/lib/aria_storage/dual_storage_manager.ex` (continued)

```elixir
  def store_chunk_dual(%__MODULE__{} = manager, %Chunks{} = chunk) do
    primary_result = store_chunk_primary(manager, chunk)
    safety_result = if manager.options.write_to_both do
      store_chunk_safety(manager, chunk)
    else
      {:ok, :skipped}
    end

    case {primary_result, safety_result} do
      {{:ok, primary_meta}, {:ok, safety_meta}} ->
        if manager.options.verify_both do
          verify_dual_storage(manager, chunk)
        else
          {:ok, %{primary: primary_meta, safety: safety_meta}}
        end

      {{:ok, primary_meta}, {:error, safety_error}} ->
        log_safety_storage_error(chunk.id, safety_error)
        {:ok, %{primary: primary_meta, safety: {:error, safety_error}}}

      {{:error, primary_error}, {:ok, safety_meta}} ->
        log_primary_storage_error(chunk.id, primary_error)
        {:error, %{primary_error: primary_error, safety_fallback: safety_meta}}

      {{:error, primary_error}, {:error, safety_error}} ->
        {:error, %{primary: primary_error, safety: safety_error}}
    end
  end

  def get_chunk_dual(%__MODULE__{} = manager, chunk_id) do
    case manager.options.read_preference do
      :primary -> get_chunk_with_fallback(manager, chunk_id, :primary_first)
      :safety -> get_chunk_with_fallback(manager, chunk_id, :safety_first)
      :fastest -> get_chunk_fastest(manager, chunk_id)
    end
  end

  defp get_chunk_with_fallback(manager, chunk_id, :primary_first) do
    case get_chunk_from_primary_stores(manager, chunk_id) do
      {:ok, chunk} -> {:ok, chunk}
      {:error, _} when manager.options.fallback_enabled ->
        get_chunk_from_safety_stores(manager, chunk_id)
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_chunk_with_fallback(manager, chunk_id, :safety_first) do
    case get_chunk_from_safety_stores(manager, chunk_id) do
      {:ok, chunk} -> {:ok, chunk}
      {:error, _} when manager.options.fallback_enabled ->
        get_chunk_from_primary_stores(manager, chunk_id)
      {:error, reason} -> {:error, reason}
    end
  end
```

### Phase 2: Safety and Verification Features

#### 2.1 Implement Comparison System
**File:** `apps/aria_storage/lib/aria_storage/dual_storage_comparator.ex`

```elixir
defmodule AriaStorage.DualStorageComparator do
  @moduledoc """
  Compares chunks between primary and safety storage systems.
  Provides detailed analysis and reports for validation.
  """

  alias AriaStorage.{DualStorageManager, Chunks}

  @doc """
  Compares a single chunk between storage systems.
  """
  def compare_chunk(%DualStorageManager{} = manager, chunk_id) do
    with {:ok, primary_chunk} <- get_chunk_from_primary(manager, chunk_id),
         {:ok, safety_chunk} <- get_chunk_from_safety(manager, chunk_id) do
      
      comparison = %{
        chunk_id: chunk_id,
        primary_exists: true,
        safety_exists: true,
        size_match: primary_chunk.size == safety_chunk.size,
        data_match: primary_chunk.data == safety_chunk.data,
        checksum_match: primary_chunk.checksum == safety_chunk.checksum,
        metadata: %{
          primary_size: primary_chunk.size,
          safety_size: safety_chunk.size,
          primary_checksum: primary_chunk.checksum,
          safety_checksum: safety_chunk.checksum
        }
      }

      result = if comparison.size_match and comparison.data_match do
        :match
      else
        :mismatch
      end

      {:ok, {result, comparison}}
    else
      {:error, :primary_not_found} ->
        case get_chunk_from_safety(manager, chunk_id) do
          {:ok, _} -> {:ok, {:safety_only, %{chunk_id: chunk_id}}}
          {:error, _} -> {:error, :not_found_in_either}
        end

      {:error, :safety_not_found} ->
        {:ok, {:primary_only, %{chunk_id: chunk_id}}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs a batch comparison of multiple chunks.
  """
  def batch_compare(manager, chunk_ids, opts \\ []) do
    concurrency = Keyword.get(opts, :concurrency, 10)
    
    chunk_ids
    |> Task.async_stream(
      fn chunk_id -> {chunk_id, compare_chunk(manager, chunk_id)} end,
      max_concurrency: concurrency,
      timeout: :timer.minutes(5)
    )
    |> Enum.reduce(%{matches: 0, mismatches: 0, primary_only: 0, safety_only: 0, errors: 0, details: []}, fn
      {:ok, {chunk_id, {:ok, {:match, comparison}}}}, acc ->
        %{acc | matches: acc.matches + 1, details: [comparison | acc.details]}

      {:ok, {chunk_id, {:ok, {:mismatch, comparison}}}}, acc ->
        %{acc | mismatches: acc.mismatches + 1, details: [comparison | acc.details]}

      {:ok, {chunk_id, {:ok, {:primary_only, comparison}}}}, acc ->
        %{acc | primary_only: acc.primary_only + 1, details: [comparison | acc.details]}

      {:ok, {chunk_id, {:ok, {:safety_only, comparison}}}}, acc ->
        %{acc | safety_only: acc.safety_only + 1, details: [comparison | acc.details]}

      {:ok, {chunk_id, {:error, reason}}}, acc ->
        error_detail = %{chunk_id: chunk_id, error: reason}
        %{acc | errors: acc.errors + 1, details: [error_detail | acc.details]}

      {:error, reason}, acc ->
        %{acc | errors: acc.errors + 1}
    end)
  end
end
```

#### 2.2 Implement Monitoring and Logging
**File:** `apps/aria_storage/lib/aria_storage/dual_storage_monitor.ex`

```elixir
defmodule AriaStorage.DualStorageMonitor do
  @moduledoc """
  Monitors dual storage operations and provides metrics.
  """

  use GenServer
  require Logger

  @doc """
  Logs storage operation results.
  """
  def log_operation(operation, result, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:log_operation, operation, result, metadata})
  end

  @doc """
  Gets current dual storage statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # GenServer implementation
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = %{
      operations: %{},
      errors: %{},
      start_time: DateTime.utc_now()
    }
    {:ok, state}
  end

  def handle_cast({:log_operation, operation, result, metadata}, state) do
    # Update operation statistics
    # Log significant events
    # Handle alerting if needed
    {:noreply, updated_state}
  end

  def handle_call(:get_stats, _from, state) do
    stats = generate_stats(state)
    {:reply, stats, state}
  end

  defp generate_stats(state) do
    # Calculate statistics from accumulated data
    %{
      uptime: DateTime.diff(DateTime.utc_now(), state.start_time),
      total_operations: calculate_total_ops(state.operations),
      success_rate: calculate_success_rate(state.operations),
      error_rate: calculate_error_rate(state.errors),
      storage_consistency: calculate_consistency_rate(state.operations)
    }
  end
end
```

### Phase 3: Integration with Existing Storage System

#### 3.1 Update Storage Context
**File:** `apps/aria_storage/lib/aria_storage/storage.ex`

Add dual storage support to existing functions:

```elixir
  def store_chunks(chunks, opts \\ []) do
    if dual_storage_enabled?(opts) do
      manager = DualStorageManager.new(opts)
      store_chunks_dual(chunks, manager, opts)
    else
      # Existing implementation
      stores = get_chunk_stores(opts)
      cache = get_cache_store(opts)
      verify = Keyword.get(opts, :verify, true)
      # ... rest of existing code
    end
  end

  defp store_chunks_dual(chunks, manager, opts) do
    verify = Keyword.get(opts, :verify, true)
    
    results = Enum.map(chunks, fn chunk ->
      case DualStorageManager.store_chunk_dual(manager, chunk) do
        {:ok, metadata} ->
          if verify do
            verify_dual_stored_chunk(manager, chunk, metadata)
          else
            {:ok, chunk}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        stored_chunks = Enum.map(results, fn {:ok, chunk} -> chunk end)
        {:ok, stored_chunks}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp dual_storage_enabled?(opts) do
    Keyword.get(opts, :dual_storage, Application.get_env(:aria_storage, :dual_storage_enabled, false))
  end
```

#### 3.2 Create Migration Tools
**File:** `apps/aria_storage/lib/mix/tasks/dual_storage_migrate.ex`

```elixir
defmodule Mix.Tasks.DualStorage.Migrate do
  @moduledoc """
  Migrates chunks between primary and safety storage systems.
  
  Usage:
    mix dual_storage.migrate --direction=to_safety
    mix dual_storage.migrate --direction=to_primary
    mix dual_storage.migrate --direction=compare_all
  """

  use Mix.Task
  alias AriaStorage.{DualStorageManager, DualStorageComparator}

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, 
      strict: [direction: :string, batch_size: :integer, concurrency: :integer]
    )

    direction = Keyword.get(opts, :direction, "compare_all")
    batch_size = Keyword.get(opts, :batch_size, 100)
    concurrency = Keyword.get(opts, :concurrency, 10)

    case direction do
      "to_safety" -> migrate_to_safety(batch_size, concurrency)
      "to_primary" -> migrate_to_primary(batch_size, concurrency)
      "compare_all" -> compare_all_chunks(batch_size, concurrency)
      _ -> Mix.shell().error("Unknown direction: #{direction}")
    end
  end

  defp migrate_to_safety(batch_size, concurrency) do
    # Implementation for migrating chunks from primary to safety storage
  end

  defp migrate_to_primary(batch_size, concurrency) do
    # Implementation for migrating chunks from safety to primary storage
  end

  defp compare_all_chunks(batch_size, concurrency) do
    # Implementation for comparing all chunks between systems
  end
end
```

### Phase 4: Testing and Validation

#### 4.1 Unit Tests
**File:** `apps/aria_storage/test/aria_storage/dual_storage_manager_test.exs`

```elixir
defmodule AriaStorage.DualStorageManagerTest do
  use ExUnit.Case
  alias AriaStorage.{DualStorageManager, Chunks}

  describe "dual storage operations" do
    test "stores chunk in both systems successfully" do
      # Test dual write operations
    end

    test "handles primary storage failure with safety fallback" do
      # Test fallback scenarios
    end

    test "reads from preferred storage system" do
      # Test read preferences
    end

    test "compares chunks between systems" do
      # Test comparison functionality
    end
  end
end
```

#### 4.2 Integration Tests
**File:** `apps/aria_storage/test/integration/dual_storage_integration_test.exs`

```elixir
defmodule AriaStorage.DualStorageIntegrationTest do
  use ExUnit.Case
  
  describe "end-to-end dual storage workflow" do
    test "complete file chunking and storage cycle" do
      # Test full workflow from file input to dual storage
    end

    test "file reconstruction from either storage system" do
      # Test file reconstruction capabilities
    end

    test "migration between storage systems" do
      # Test migration functionality
    end
  end
end
```

### Phase 5: Deployment and Monitoring

#### 5.1 Configuration Management
- Environment-specific configurations
- Feature flags for gradual rollout
- Monitoring and alerting setup

#### 5.2 Performance Testing
- Benchmark dual storage vs single storage
- Identify performance overhead
- Optimize critical paths

#### 5.3 Documentation Updates
- Update API documentation
- Create migration guides
- Update architecture documentation

## Benefits of This Approach

### Safety Benefits
1. **Data Redundancy**: Two independent storage systems prevent data loss
2. **Migration Safety**: Test new system thoroughly before switching
3. **Rollback Capability**: Quick rollback to proven system if issues arise
4. **Verification**: Continuous comparison ensures data integrity

### Technical Benefits
1. **Minimal Risk**: Existing system continues unchanged
2. **Gradual Transition**: Phase-based implementation reduces complexity
3. **Performance Testing**: Real-world performance comparison
4. **Flexible Configuration**: Easy to adjust behavior based on needs

### Operational Benefits
1. **Confidence Building**: Prove new system works before full migration
2. **Learning Opportunity**: Understand differences between systems
3. **Troubleshooting**: Compare systems when issues arise
4. **Capacity Planning**: Understand storage requirements for both systems

## Timeline Estimation

- **Phase 1**: 2-3 days (Core dual storage functionality)
- **Phase 2**: 2-3 days (Safety and verification features)
- **Phase 3**: 1-2 days (Integration with existing system)
- **Phase 4**: 2-3 days (Testing and validation)
- **Phase 5**: 1-2 days (Deployment preparation)

**Total**: 8-13 days for complete implementation

## Next Steps

1. **Start with Phase 1.1**: Update configuration system
2. **Create DualStorageManager skeleton**: Basic structure and interfaces
3. **Implement core dual operations**: Store and retrieve functionality
4. **Add comprehensive testing**: Ensure reliability
5. **Deploy with monitoring**: Gradual rollout with careful observation

This plan provides a comprehensive approach to implementing dual storage while maintaining the safety and reliability of the existing system.
