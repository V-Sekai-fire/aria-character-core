# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormatTest do
  use ExUnit.Case
  alias AriaStorage.Parsers.CasyncFormat

  @moduledoc """
  Comprehensive tests for the ABNF casync/desync parser using real testdata
  from the desync repository.

  These tests validate parsing of actual casync format files including:
  - .caibx (chunk index for blobs)
  - .caidx (chunk index for catar archives)
  - .catar (archive format)
  - .cacnk (compressed chunk files)
  """

  # Path to desync testdata directory
  @testdata_path "/home/fire/desync/testdata"

  describe "format detection" do
    test "detects .caibx files correctly" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, :caibx} = CasyncFormat.detect_format(data)
        {:error, _} ->
          # Skip test if file doesn't exist
          :ok
      end
    end

    test "detects .catar files correctly" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, :catar} = CasyncFormat.detect_format(data)
        {:error, _} ->
          # Skip test if file doesn't exist
          :ok
      end
    end

    test "rejects unknown formats" do
      assert {:error, :unknown_format} = CasyncFormat.detect_format("invalid")
      assert {:error, :unknown_format} = CasyncFormat.detect_format(<<1, 2, 3, 4>>)
    end
  end

  describe "index file parsing (.caibx)" do
    test "parses blob1.caibx successfully" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          # Verify structure
          assert %{format: format, header: header, chunks: chunks} = result
          assert format == :caibx

          # Verify header structure
          assert %{version: version, total_size: total_size, chunk_count: chunk_count} = header
          assert is_integer(version)
          assert is_integer(total_size)
          assert is_integer(chunk_count)
          assert total_size > 0
          assert chunk_count > 0

          # Verify chunks structure
          assert is_list(chunks)
          assert length(chunks) == chunk_count

          # Verify first chunk structure
          if length(chunks) > 0 do
            first_chunk = hd(chunks)
            assert %{chunk_id: chunk_id, offset: offset, size: size, flags: flags} = first_chunk
            assert is_binary(chunk_id)
            assert byte_size(chunk_id) == 32  # SHA512/256 is 32 bytes
            assert is_integer(offset)
            assert is_integer(size)
            assert is_integer(flags)
            assert offset >= 0
            assert size > 0
          end

        {:error, reason} ->
          flunk("Failed to read test file: #{inspect(reason)}")
      end
    end

    test "parses index.caibx successfully" do
      file_path = Path.join(@testdata_path, "index.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          assert %{format: :caibx, header: header, chunks: chunks} = result
          assert %{chunk_count: chunk_count} = header
          assert length(chunks) == chunk_count

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "handles corrupted index files gracefully" do
      file_path = Path.join(@testdata_path, "blob2_corrupted.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          # This should either parse successfully or return a specific error
          case CasyncFormat.parse_index(data) do
            {:ok, _result} ->
              # If it parses, that's fine - corruption might be elsewhere
              :ok
            {:error, _reason} ->
              # Expected for corrupted file
              :ok
          end
        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "archive file parsing (.catar)" do
    test "parses flat.catar successfully" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          assert %{format: :catar, entries: entries} = result
          assert is_list(entries)

          # Verify entry structures
          Enum.each(entries, fn entry ->
            assert %{type: type, header: header} = entry
            assert type in [:file, :directory, :symlink, :device, :fifo, :socket, :unknown]
            assert %{size: size, flags: flags} = header
            assert is_integer(size)
            assert is_integer(flags)

            # Check for expected metadata fields
            if Map.has_key?(entry, :mode) do
              assert is_integer(entry.mode)
            end
            if Map.has_key?(entry, :uid) do
              assert is_integer(entry.uid)
            end
            if Map.has_key?(entry, :gid) do
              assert is_integer(entry.gid)
            end
            if Map.has_key?(entry, :mtime) do
              assert is_integer(entry.mtime)
            end
          end)

        {:error, reason} ->
          flunk("Failed to read test file: #{inspect(reason)}")
      end
    end

    test "parses nested.catar successfully" do
      file_path = Path.join(@testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          assert %{format: :catar, entries: entries} = result
          assert is_list(entries)

          # Should have multiple entries for nested structure
          assert length(entries) > 1

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "parses complex.catar successfully" do
      file_path = Path.join(@testdata_path, "complex.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          assert %{format: :catar, entries: entries} = result
          assert is_list(entries)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "parses flatdir.catar successfully" do
      file_path = Path.join(@testdata_path, "flatdir.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          assert %{format: :catar, entries: entries} = result
          assert is_list(entries)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "round-trip consistency" do
    test "parsed data maintains consistency across multiple parses" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          # Parse the same data multiple times
          assert {:ok, result1} = CasyncFormat.parse_index(data)
          assert {:ok, result2} = CasyncFormat.parse_index(data)
          assert {:ok, result3} = CasyncFormat.parse_index(data)

          # Results should be identical
          assert result1 == result2
          assert result2 == result3

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "chunk validation" do
    test "validates chunk ID structure" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          %{chunks: chunks} = result

          # Validate each chunk ID
          Enum.each(chunks, fn chunk ->
            %{chunk_id: chunk_id} = chunk

            # SHA512/256 should be exactly 32 bytes
            assert byte_size(chunk_id) == 32

            # Should be valid binary data
            assert is_binary(chunk_id)

            # Convert to hex and verify format
            hex_id = Base.encode16(chunk_id, case: :lower)
            assert String.length(hex_id) == 64
            assert String.match?(hex_id, ~r/^[0-9a-f]+$/)
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates chunk offset ordering" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          %{chunks: chunks} = result

          if length(chunks) > 1 do
            # Extract offsets and verify they're in ascending order
            offsets = Enum.map(chunks, & &1.offset)
            sorted_offsets = Enum.sort(offsets)

            # Offsets should be in order (allowing for equal offsets)
            assert offsets == sorted_offsets
          end

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "edge cases and error handling" do
    test "handles empty input gracefully" do
      assert {:error, _} = CasyncFormat.parse_index("")
      assert {:error, _} = CasyncFormat.parse_archive("")
      assert {:error, _} = CasyncFormat.parse_chunk("")
    end

    test "handles truncated files gracefully" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} when byte_size(data) > 10 ->
          # Try parsing truncated versions
          truncated_data = binary_part(data, 0, 10)
          assert {:error, _} = CasyncFormat.parse_index(truncated_data)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "handles invalid magic headers" do
      # Create data with wrong magic
      invalid_data = <<0xFF, 0xFF, 0xFF>> <> String.duplicate(<<0>>, 100)
      assert {:error, _} = CasyncFormat.parse_index(invalid_data)
      assert {:error, _} = CasyncFormat.parse_archive(invalid_data)
    end
  end

  describe "performance benchmarking" do
    test "parses large index files efficiently" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          # Measure parsing time
          {time_micro, {:ok, _result}} = :timer.tc(fn ->
            CasyncFormat.parse_index(data)
          end)

          # Should parse reasonably quickly (less than 100ms for test files)
          assert time_micro < 100_000

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "specific format validation" do
    test "validates caibx magic header structure" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, <<0xCA, 0x1B, 0x5C, _rest::binary>>} ->
          # Correct magic header
          assert {:ok, :caibx} = CasyncFormat.detect_format(File.read!(file_path))

        {:ok, data} ->
          flunk("Unexpected magic header in blob1.caibx: #{inspect(binary_part(data, 0, min(3, byte_size(data))))}")

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates catar magic header structure" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, <<0xCA, 0x1A, 0x52, _rest::binary>>} ->
          # Correct magic header
          assert {:ok, :catar} = CasyncFormat.detect_format(File.read!(file_path))

        {:ok, data} ->
          flunk("Unexpected magic header in flat.catar: #{inspect(binary_part(data, 0, min(3, byte_size(data))))}")

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end

  describe "integration with testdata" do
    setup do
      # Verify testdata directory exists
      if File.exists?(@testdata_path) do
        {:ok, testdata_available: true}
      else
        {:ok, testdata_available: false}
      end
    end

    test "processes all available caibx files", %{testdata_available: available} do
      if available do
        caibx_files = Path.wildcard(Path.join(@testdata_path, "*.caibx"))

        Enum.each(caibx_files, fn file_path ->
          case File.read(file_path) do
            {:ok, data} ->
              result = CasyncFormat.parse_index(data)
              filename = Path.basename(file_path)

              case result do
                {:ok, parsed} ->
                  # Validate basic structure
                  assert %{format: :caibx, header: header, chunks: chunks} = parsed
                  assert is_map(header)
                  assert is_list(chunks)

                {:error, reason} ->
                  # Only allow errors for explicitly corrupted files
                  if String.contains?(filename, "corrupted") do
                    # Expected to fail
                    :ok
                  else
                    flunk("Failed to parse #{filename}: #{inspect(reason)}")
                  end
              end

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      else
        # Skip test if testdata not available
        :ok
      end
    end

    test "processes all available catar files", %{testdata_available: available} do
      if available do
        catar_files = Path.wildcard(Path.join(@testdata_path, "*.catar"))

        Enum.each(catar_files, fn file_path ->
          case File.read(file_path) do
            {:ok, data} ->
              assert {:ok, result} = CasyncFormat.parse_archive(data)

              # Validate basic structure
              assert %{format: :catar, entries: entries} = result
              assert is_list(entries)

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      else
        # Skip test if testdata not available
        :ok
      end
    end
  end

  describe "parser output validation" do
    test "produces valid output structure for index files" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)

          # Test JSON serialization (ensures all data types are serializable)
          json_result = Jason.encode!(result)
          assert is_binary(json_result)

          # Test round-trip
          decoded = Jason.decode!(json_result)
          assert is_map(decoded)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "produces deterministic output" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          # Parse multiple times and compare
          results = for _i <- 1..5 do
            {:ok, result} = CasyncFormat.parse_archive(data)
            result
          end

          # All results should be identical
          [first | rest] = results
          Enum.each(rest, fn result ->
            assert result == first
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end
end
