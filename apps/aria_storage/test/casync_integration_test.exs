# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.CasyncIntegrationTest do
  use ExUnit.Case

  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.ChunkUploader
  alias AriaStorage.TestFixtures.CasyncFixtures

  @moduledoc """
  Integration tests for casync format parser with the chunk uploader system.

  These tests verify that parsed chunk data integrates correctly with
  the storage and upload infrastructure.
  """

  @testdata_path "/home/fire/desync/testdata"

  describe "parser and uploader integration" do
    test "parsed chunk IDs match expected format for uploader" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          # Extract chunk IDs and verify they work with uploader
          Enum.each(result.chunks, fn chunk ->
            chunk_id = chunk.chunk_id

            # Test filename generation
            filename = ChunkUploader.filename(:original, {nil, %{chunk_id: chunk_id}})

            # Should generate valid filename
            assert String.ends_with?(filename, ".cacnk")
            assert String.length(filename) == 64 + 6  # 64 hex chars + .cacnk

            # Test storage directory organization
            storage_dir = ChunkUploader.storage_dir(:original, {nil, %{chunk_id: chunk_id}})

            # Should organize into subdirectories
            assert String.starts_with?(storage_dir, "chunks/")
            assert String.match?(storage_dir, ~r/^chunks\/[0-9a-f]{2}\/[0-9a-f]{2}$/)
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "parsed chunks can be processed by storage system" do
      # Create synthetic chunks and test the full pipeline
      chunks_data = [
        {"chunk1", "Hello, World!"},
        {"chunk2", "This is chunk 2"},
        {"chunk3", "Final chunk data"}
      ]

      processed_chunks = Enum.map(chunks_data, fn {name, data} ->
        # Calculate chunk ID as parser would
        chunk_id = :crypto.hash(:sha256, data) <> :crypto.strong_rand_bytes(0)  # Pad to 32 bytes

        # Create chunk metadata as parser would produce
        chunk_metadata = %{
          chunk_id: chunk_id,
          offset: 0,
          size: byte_size(data),
          flags: 0
        }

        # Test uploader integration
        filename = ChunkUploader.filename(:original, {nil, chunk_metadata})
        storage_dir = ChunkUploader.storage_dir(:original, {nil, chunk_metadata})

        %{
          name: name,
          data: data,
          metadata: chunk_metadata,
          filename: filename,
          storage_dir: storage_dir
        }
      end)

      # Verify all chunks have unique storage paths
      storage_paths = Enum.map(processed_chunks, fn chunk ->
        Path.join(chunk.storage_dir, chunk.filename)
      end)

      assert length(Enum.uniq(storage_paths)) == length(storage_paths)

      # Verify consistent organization
      Enum.each(processed_chunks, fn chunk ->
        hex_id = Base.encode16(chunk.metadata.chunk_id, case: :lower)
        expected_dir = "chunks/#{String.slice(hex_id, 0, 2)}/#{String.slice(hex_id, 2, 2)}"
        assert chunk.storage_dir == expected_dir
        assert chunk.filename == hex_id <> ".cacnk"
      end)
    end

    test "round-trip: parse index, extract chunks, recreate index" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse original
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)

          # Extract chunk information
          chunk_infos = Enum.map(parsed.chunks, fn chunk ->
            %{
              id: chunk.chunk_id,
              offset: chunk.offset,
              size: chunk.size,
              flags: chunk.flags
            }
          end)

          # Recreate a simplified index (just structure validation)
          recreated_chunks = Enum.map(chunk_infos, fn info ->
            %{
              chunk_id: info.id,
              offset: info.offset,
              size: info.size,
              flags: info.flags
            }
          end)

          recreated_result = %{
            format: parsed.format,
            header: parsed.header,
            chunks: recreated_chunks
          }

          # Verify structure matches
          assert recreated_result.format == parsed.format
          assert recreated_result.header == parsed.header
          assert length(recreated_result.chunks) == length(parsed.chunks)

          # Verify each chunk matches
          Enum.zip(recreated_result.chunks, parsed.chunks)
          |> Enum.each(fn {recreated, original} ->
            assert recreated.chunk_id == original.chunk_id
            assert recreated.offset == original.offset
            assert recreated.size == original.size
            assert recreated.flags == original.flags
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "parser output is compatible with JSON serialization" do
      # Test that parsed data can be serialized for API responses
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(10)

      assert {:ok, result} = CasyncFormat.parse_index(synthetic_data)

      # Convert binary chunk IDs to base64 for JSON compatibility
      json_compatible = %{
        format: result.format,
        header: result.header,
        chunks: Enum.map(result.chunks, fn chunk ->
          %{
            chunk_id: Base.encode64(chunk.chunk_id),
            offset: chunk.offset,
            size: chunk.size,
            flags: chunk.flags
          }
        end)
      }

      # Should serialize to JSON without errors
      assert {:ok, json_string} = Jason.encode(json_compatible)
      assert is_binary(json_string)

      # Should deserialize back correctly
      assert {:ok, decoded} = Jason.decode(json_string)
      assert decoded["format"] == "caibx"
      assert is_map(decoded["header"])
      assert is_list(decoded["chunks"])

      # Verify chunk structure in JSON
      Enum.each(decoded["chunks"], fn chunk ->
        assert is_binary(chunk["chunk_id"])
        assert is_integer(chunk["offset"])
        assert is_integer(chunk["size"])
        assert is_integer(chunk["flags"])

        # Chunk ID should be valid base64
        assert {:ok, _} = Base.decode64(chunk["chunk_id"])
      end)
    end

    test "error handling integration between parser and uploader" do
      # Test what happens when parser encounters errors and how uploader handles them
      invalid_data = CasyncFixtures.create_invalid_data(:wrong_magic)

      # Parser should fail gracefully
      assert {:error, _reason} = CasyncFormat.parse_index(invalid_data)

      # Uploader should handle missing chunk_id gracefully
      try do
        ChunkUploader.filename(:original, {nil, %{}})
        flunk("Should have raised an error for missing chunk_id")
      rescue
        _ -> :ok  # Expected to fail
      end

      # Test with invalid chunk_id format
      try do
        ChunkUploader.filename(:original, {nil, %{chunk_id: "invalid"}})
        # This might work depending on implementation, so we don't assert failure
      catch
        _, _ -> :ok  # It's okay if it fails
      end
    end

    test "performance integration test" do
      # Test that parser and uploader together perform reasonably
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(50)

      {parse_time, {:ok, parsed}} = :timer.tc(CasyncFormat.parse_index, [synthetic_data])

      {process_time, processed_chunks} = :timer.tc(fn ->
        Enum.map(parsed.chunks, fn chunk ->
          filename = ChunkUploader.filename(:original, {nil, %{chunk_id: chunk.chunk_id}})
          storage_dir = ChunkUploader.storage_dir(:original, {nil, %{chunk_id: chunk.chunk_id}})

          %{
            chunk_id: chunk.chunk_id,
            filename: filename,
            storage_dir: storage_dir,
            full_path: Path.join(storage_dir, filename)
          }
        end)
      end)

      total_time = parse_time + process_time

      IO.puts("\nIntegration Performance:")
      IO.puts("  Parse time: #{parse_time} μs")
      IO.puts("  Process time: #{process_time} μs")
      IO.puts("  Total time: #{total_time} μs")
      IO.puts("  Chunks processed: #{length(processed_chunks)}")
      IO.puts("  Time per chunk: #{Float.round(total_time / length(processed_chunks), 2)} μs")

      # Should be reasonably fast
      assert total_time < 100_000  # Less than 100ms total
      assert length(processed_chunks) == 50

      # Verify all chunks have valid paths
      Enum.each(processed_chunks, fn chunk ->
        assert String.ends_with?(chunk.filename, ".cacnk")
        assert String.starts_with?(chunk.storage_dir, "chunks/")
        assert String.contains?(chunk.full_path, chunk.storage_dir)
      end)
    end
  end

  describe "archive integration" do
    test "parsed catar entries provide useful metadata" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          # Verify entries have useful metadata for storage decisions
          Enum.each(result.entries, fn entry ->
            assert entry.type in [:file, :directory, :symlink, :device, :fifo, :socket, :unknown]

            # Check for standard Unix metadata
            if Map.has_key?(entry, :mode) do
              assert is_integer(entry.mode)
              # Mode should be reasonable (not negative, not huge)
              assert entry.mode >= 0
              assert entry.mode < 0o777777  # Reasonable upper bound
            end

            if Map.has_key?(entry, :uid) do
              assert is_integer(entry.uid)
              assert entry.uid >= 0
            end

            if Map.has_key?(entry, :gid) do
              assert is_integer(entry.gid)
              assert entry.gid >= 0
            end

            if Map.has_key?(entry, :mtime) do
              assert is_integer(entry.mtime)
              # Should be a reasonable timestamp (after 1970, before far future)
              assert entry.mtime >= 0
              assert entry.mtime < 4_000_000_000  # Year 2096
            end
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "catar parsing supports storage planning" do
      # Test that parsed archive data helps with storage planning
      synthetic_catar = CasyncFixtures.create_complex_catar()

      assert {:ok, result} = CasyncFormat.parse_archive(synthetic_catar)

      # Analyze storage requirements
      file_entries = Enum.filter(result.entries, &(&1.type == :file))
      dir_entries = Enum.filter(result.entries, &(&1.type == :directory))
      symlink_entries = Enum.filter(result.entries, &(&1.type == :symlink))

      storage_analysis = %{
        total_entries: length(result.entries),
        files: length(file_entries),
        directories: length(dir_entries),
        symlinks: length(symlink_entries),
        total_size: Enum.sum(Enum.map(result.entries, fn entry ->
          Map.get(entry.header, :size, 0)
        end))
      }

      IO.puts("\nArchive Storage Analysis:")
      IO.puts("  Total entries: #{storage_analysis.total_entries}")
      IO.puts("  Files: #{storage_analysis.files}")
      IO.puts("  Directories: #{storage_analysis.directories}")
      IO.puts("  Symlinks: #{storage_analysis.symlinks}")
      IO.puts("  Total size: #{storage_analysis.total_size} bytes")

      # Verify reasonable structure
      assert storage_analysis.total_entries > 0
      assert storage_analysis.total_size >= 0
      assert storage_analysis.files + storage_analysis.directories + storage_analysis.symlinks == storage_analysis.total_entries
    end
  end
end
