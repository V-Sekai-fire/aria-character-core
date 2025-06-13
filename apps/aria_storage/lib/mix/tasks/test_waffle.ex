# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.AriaStorage.TestWaffle do
  @moduledoc """
  Test Waffle integration with AriaStorage.

  This task demonstrates and tests the Waffle-based storage system,
  including file uploading, chunking, and retrieval.

  ## Usage

      mix aria_storage.test_waffle [options]

  ## Options

      --backend BACKEND        Storage backend: local, s3, gcs (default: local)
      --bucket BUCKET          S3/GCS bucket name (default: aria-chunks)
      --directory DIR          Local storage directory (default: /tmp/aria-chunks)
      --test-file FILE         Test file to upload (default: creates test file)
      --chunk-size SIZE        Chunk size in bytes (default: 65536)
      --compress               Enable chunk compression
      --verbose                Show detailed output

  ## Examples

      # Test local storage
      mix aria_storage.test_waffle

      # Test S3 storage
      mix aria_storage.test_waffle --backend s3 --bucket my-bucket

      # Test with custom file
      mix aria_storage.test_waffle --test-file ~/large_file.bin --chunk-size 1048576

      # Test with compression
      mix aria_storage.test_waffle --compress --verbose

  """

  use Mix.Task
  alias AriaStorage.Storage

  @shortdoc "Test Waffle integration with AriaStorage"

  @switches [
    backend: :string,
    bucket: :string,
    directory: :string,
    test_file: :string,
    chunk_size: :integer,
    compress: :boolean,
    verbose: :boolean,
    help: :boolean
  ]

  @aliases [
    b: :backend,
    d: :directory,
    f: :test_file,
    c: :chunk_size,
    v: :verbose,
    h: :help
  ]

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      IO.puts(@moduledoc)
    else
      Mix.Task.run("app.start")
      run_test(opts)
    end
  end

  defp run_test(opts) do
    backend = String.to_atom(opts[:backend] || "local")
    test_file = opts[:test_file]
    chunk_size = opts[:chunk_size] || 65536
    compress = opts[:compress] || false
    verbose = opts[:verbose] || false

    storage_opts = [
      backend: backend,
      bucket: opts[:bucket],
      directory: opts[:directory],
      chunk_size: chunk_size,
      compress: compress
    ]

    IO.puts("🧪 AriaStorage Waffle Integration Test")
    IO.puts("=====================================")
    IO.puts("Backend: #{backend}")
    IO.puts("Chunk size: #{format_bytes(chunk_size)}")
    IO.puts("Compression: #{if compress, do: "enabled", else: "disabled"}")
    IO.puts("")

    # Step 1: Configure Waffle
    verbose_log(verbose, "🔧 Configuring Waffle storage...")
    
    config = %{
      storage: backend,
      bucket: opts[:bucket] || "aria-chunks",
      storage_dir_prefix: "test/chunks",
      region: System.get_env("AWS_REGION", "us-east-1")
    }

    case Storage.configure_waffle_storage(config) do
      {:ok, _config} ->
        verbose_log(verbose, "✅ Waffle configured successfully")
      {:error, reason} ->
        IO.puts("❌ Failed to configure Waffle: #{inspect(reason)}")
        System.halt(1)
    end

    # Step 2: Test connectivity
    IO.puts("🔍 Testing storage connectivity...")
    
    case Storage.test_waffle_storage(backend, storage_opts) do
      {:ok, result} ->
        IO.puts("✅ Storage connectivity test passed")
        verbose_log(verbose, "   Status: #{result.status}")
        verbose_log(verbose, "   Message: #{result.message}")
      {:error, result} ->
        IO.puts("❌ Storage connectivity test failed")
        IO.puts("   Error: #{inspect(result.error)}")
        System.halt(1)
    end

    # Step 3: Prepare test file
    {test_file_path, cleanup_needed} = prepare_test_file(test_file, verbose)
    
    try do
      # Step 4: Store file with Waffle
      IO.puts("📤 Storing file with Waffle...")
      start_time = System.monotonic_time(:millisecond)
      
      case Storage.store_file_with_waffle(test_file_path, storage_opts) do
        {:ok, store_result} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          IO.puts("✅ File stored successfully")
          IO.puts("   Index ref: #{store_result.index_ref}")
          IO.puts("   Chunks: #{store_result.chunks_stored}")
          IO.puts("   Original size: #{format_bytes(store_result.total_size)}")
          IO.puts("   Compressed size: #{format_bytes(store_result.compressed_size)}")
          
          compression_ratio = if store_result.total_size > 0 do
            (1 - store_result.compressed_size / store_result.total_size) * 100
          else
            0
          end
          
          IO.puts("   Compression: #{Float.round(compression_ratio, 2)}%")
          IO.puts("   Duration: #{duration}ms")
          
          # Step 5: Retrieve file with Waffle
          IO.puts("")
          IO.puts("📥 Retrieving file with Waffle...")
          retrieve_start_time = System.monotonic_time(:millisecond)
          
          case Storage.get_file_with_waffle(store_result.index_ref, storage_opts) do
            {:ok, retrieve_result} ->
              retrieve_end_time = System.monotonic_time(:millisecond)
              retrieve_duration = retrieve_end_time - retrieve_start_time

              IO.puts("✅ File retrieved successfully")
              IO.puts("   Retrieved size: #{format_bytes(retrieve_result.size)}")
              IO.puts("   Chunks: #{retrieve_result.chunks_count}")
              IO.puts("   Duration: #{retrieve_duration}ms")

              # Step 6: Verify data integrity
              case File.read(test_file_path) do
                {:ok, original_data} ->
                  if original_data == retrieve_result.data do
                    IO.puts("✅ Data integrity verified - files match perfectly")
                  else
                    IO.puts("❌ Data integrity check failed - files don't match")
                    IO.puts("   Original: #{byte_size(original_data)} bytes")
                    IO.puts("   Retrieved: #{byte_size(retrieve_result.data)} bytes")
                  end
                {:error, reason} ->
                  IO.puts("⚠️  Could not verify integrity: #{inspect(reason)}")
              end

            {:error, reason} ->
              IO.puts("❌ Failed to retrieve file: #{inspect(reason)}")
          end

        {:error, reason} ->
          IO.puts("❌ Failed to store file: #{inspect(reason)}")
      end

      # Step 7: List stored files
      IO.puts("")
      IO.puts("📋 Listing Waffle files...")
      
      case Storage.list_waffle_files(backend: backend, limit: 10) do
        {:ok, files} ->
          IO.puts("✅ Found #{length(files)} files")
          Enum.each(files, fn file ->
            verbose_log(verbose, "   - #{file.index_ref} (#{format_bytes(file.size)}) [#{file.backend}]")
          end)
        {:error, reason} ->
          IO.puts("⚠️  Could not list files: #{inspect(reason)}")
      end

    after
      if cleanup_needed do
        File.rm(test_file_path)
        verbose_log(verbose, "🧹 Cleaned up test file")
      end
    end

    IO.puts("")
    IO.puts("🎉 Waffle integration test completed!")
  end

  defp prepare_test_file(nil, verbose) do
    # Create a test file with random data
    test_data = generate_test_data(1024 * 100)  # 100KB
    test_file = Path.join(System.tmp_dir!(), "aria_waffle_test_#{:rand.uniform(10000)}.bin")
    
    File.write!(test_file, test_data)
    verbose_log(verbose, "📝 Created test file: #{test_file} (#{format_bytes(byte_size(test_data))})")
    
    {test_file, true}
  end

  defp prepare_test_file(file_path, verbose) do
    case File.exists?(file_path) do
      true ->
        {:ok, stat} = File.stat(file_path)
        verbose_log(verbose, "📁 Using existing file: #{file_path} (#{format_bytes(stat.size)})")
        {file_path, false}
      false ->
        IO.puts("❌ Test file not found: #{file_path}")
        System.halt(1)
    end
  end

  defp generate_test_data(size) do
    # Generate semi-random data that compresses reasonably well
    base_pattern = "AriaStorage Waffle Test Data - "
    repeated_pattern = String.duplicate(base_pattern, div(size, byte_size(base_pattern)) + 1)
    
    # Add some randomness
    random_suffix = :crypto.strong_rand_bytes(100)
    
    (repeated_pattern <> random_suffix)
    |> binary_part(0, size)
  end

  defp verbose_log(true, message), do: IO.puts(message)
  defp verbose_log(false, _message), do: :ok

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
      bytes >= 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 ->
        "#{Float.round(bytes / 1024, 2)} KB"
      true ->
        "#{bytes} bytes"
    end
  end

  defp format_bytes(_), do: "unknown size"
end
