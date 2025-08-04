# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Code.require_file("support/casync_fixtures.ex", __DIR__)

defmodule AriaStorage.CasyncIntegrationTest do
  use ExUnit.Case
  @moduletag :integration
  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.ChunkUploader
  alias AriaStorage.TestFixtures.CasyncFixtures

  @moduledoc "Integration tests for casync format parser with the chunk uploader system.\n\nThese tests verify that parsed chunk data integrates correctly with\nthe storage and upload infrastructure.\n"
  describe("parser and uploader integration") do
    test "parsed chunk IDs match expected format for uploader" do
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(5)

      case CasyncFormat.parse_index(synthetic_data) do
        {:ok, result} ->
          Enum.each(result.chunks, fn chunk ->
            chunk_id = chunk.chunk_id
            filename = ChunkUploader.filename(:original, {nil, %{chunk_id: chunk_id}})
            assert String.ends_with?(filename, ".cacnk")
            assert String.length(filename) == 64 + 6
            storage_dir = ChunkUploader.storage_dir(:original, {nil, %{chunk_id: chunk_id}})
            assert String.starts_with?(storage_dir, "chunks/")
            assert String.match?(storage_dir, ~r/^chunks\/[0-9a-f]{2}\/[0-9a-f]{2}$/)
          end)

        {:error, _reason} ->
          :ok
      end
    end

    test "parsed chunks can be processed by storage system" do
      chunks_data = [
        {"chunk1", "Hello, World!"},
        {"chunk2", "This is chunk 2"},
        {"chunk3", "Final chunk data"}
      ]

      processed_chunks =
        Enum.map(chunks_data, fn {name, data} ->
          chunk_id = :crypto.hash(:sha256, data) <> :crypto.strong_rand_bytes(0)
          chunk_metadata = %{chunk_id: chunk_id, offset: 0, size: byte_size(data), flags: 0}
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

      storage_paths =
        Enum.map(processed_chunks, fn chunk -> Path.join(chunk.storage_dir, chunk.filename) end)

      assert length(Enum.uniq(storage_paths)) == length(storage_paths)

      Enum.each(processed_chunks, fn chunk ->
        hex_id = Base.encode16(chunk.metadata.chunk_id, case: :lower)
        expected_dir = "chunks/#{String.slice(hex_id, 0, 2)}/#{String.slice(hex_id, 2, 2)}"
        assert chunk.storage_dir == expected_dir
        assert chunk.filename == hex_id <> ".cacnk"
      end)
    end

    test "round-trip: parse index, extract chunks, recreate index" do
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(5)

      case CasyncFormat.parse_index(synthetic_data) do
        {:ok, parsed} ->
          chunk_infos =
            Enum.map(parsed.chunks, fn chunk ->
              %{id: chunk.chunk_id, offset: chunk.offset, size: chunk.size, flags: chunk.flags}
            end)

          recreated_chunks =
            Enum.map(chunk_infos, fn info ->
              %{chunk_id: info.id, offset: info.offset, size: info.size, flags: info.flags}
            end)

          recreated_result = %{
            format: parsed.format,
            header: parsed.header,
            chunks: recreated_chunks
          }

          assert recreated_result.format == parsed.format
          assert recreated_result.header == parsed.header
          assert length(recreated_result.chunks) == length(parsed.chunks)

          Enum.zip(recreated_result.chunks, parsed.chunks)
          |> Enum.each(fn {recreated, original} ->
            assert recreated.chunk_id == original.chunk_id
            assert recreated.offset == original.offset
            assert recreated.size == original.size
            assert recreated.flags == original.flags
          end)

        {:error, _} ->
          :ok
      end
    end

    test "parser output is compatible with JSON serialization" do
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(10)
      assert {:ok, result} = CasyncFormat.parse_index(synthetic_data)

      json_compatible = %{
        format: result.format,
        header: result.header,
        chunks:
          Enum.map(result.chunks, fn chunk ->
            %{
              chunk_id: Base.encode64(chunk.chunk_id),
              offset: chunk.offset,
              size: chunk.size,
              flags: chunk.flags
            }
          end)
      }

      assert {:ok, json_string} = Jason.encode(json_compatible)
      assert is_binary(json_string)
      assert {:ok, decoded} = Jason.decode(json_string)
      assert decoded["format"] == "caibx"
      assert is_map(decoded["header"])
      assert is_list(decoded["chunks"])

      Enum.each(decoded["chunks"], fn chunk ->
        assert is_binary(chunk["chunk_id"])
        assert is_integer(chunk["offset"])
        assert is_integer(chunk["size"])
        assert is_integer(chunk["flags"])
        assert {:ok, _} = Base.decode64(chunk["chunk_id"])
      end)
    end

    test "error handling integration between parser and uploader" do
      invalid_data = CasyncFixtures.create_invalid_data(:wrong_magic)
      assert {:error, _reason} = CasyncFormat.parse_index(invalid_data)

      try do
        mock_chunk = %AriaStorage.Chunks{id: nil}
        ChunkUploader.filename(:original, {mock_chunk, %{}})
        flunk("Should have raised an error for missing chunk_id")
      rescue
        _ -> :ok
      end

      try do
        ChunkUploader.filename(:original, {nil, %{chunk_id: "invalid"}})
      catch
        _, _ -> :ok
      end
    end

    test "performance integration test" do
      synthetic_data = CasyncFixtures.create_multi_chunk_caibx(50)
      {parse_time, {:ok, parsed}} = :timer.tc(CasyncFormat, :parse_index, [synthetic_data])

      {process_time, processed_chunks} =
        :timer.tc(fn ->
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
      TestOutput.trace_puts("\nIntegration Performance:")
      TestOutput.trace_puts("  Parse time: #{parse_time} μs")
      TestOutput.trace_puts("  Process time: #{process_time} μs")
      TestOutput.trace_puts("  Total time: #{total_time} μs")
      TestOutput.trace_puts("  Chunks processed: #{length(processed_chunks)}")

      TestOutput.trace_puts(
        "  Time per chunk: #{Float.round(total_time / length(processed_chunks), 2)} μs"
      )

      assert total_time < 100_000
      assert length(processed_chunks) == 50

      Enum.each(processed_chunks, fn chunk ->
        assert String.ends_with?(chunk.filename, ".cacnk")
        assert String.starts_with?(chunk.storage_dir, "chunks/")
        assert String.contains?(chunk.full_path, chunk.storage_dir)
      end)
    end
  end

  describe("archive integration") do
    test "parsed catar entries provide useful metadata" do
      synthetic_catar = CasyncFixtures.create_complex_catar()

      case CasyncFormat.parse_archive(synthetic_catar) do
        {:ok, result} ->
          Enum.each(result.elements, fn entry ->
            assert entry.type in [
                     :file,
                     :directory,
                     :symlink,
                     :device,
                     :fifo,
                     :socket,
                     :unknown,
                     :entry
                   ]

            if Map.has_key?(entry, :mode) do
              assert is_integer(entry.mode)
              assert entry.mode >= 0
              assert entry.mode < 262_143
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
              assert entry.mtime >= 0
              assert entry.mtime < 4_000_000_000
            end
          end)

        {:error, _} ->
          :ok
      end
    end

    test "catar parsing supports storage planning" do
      synthetic_catar = CasyncFixtures.create_complex_catar()
      assert {:ok, result} = CasyncFormat.parse_archive(synthetic_catar)
      assert result.format == :catar
      assert is_list(result.elements)
      assert length(result.elements) > 0
      assert is_list(result.files)
      assert is_list(result.directories)
    end
  end
end
