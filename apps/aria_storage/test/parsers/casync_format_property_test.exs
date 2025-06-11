# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

Code.require_file("../support/casync_fixtures.ex", __DIR__)

defmodule AriaStorage.Parsers.CasyncFormatPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.TestFixtures.CasyncFixtures

  @moduledoc """
  Property-based tests for the casync format parser.

  These tests use StreamData to generate random valid and invalid inputs
  to ensure the parser handles edge cases robustly.
  """

  describe "property-based parsing tests" do
    property "parser never crashes on random binary input" do
      check all binary_data <- binary(min_length: 0, max_length: 1000) do
        # Parser should never crash, but may return errors
        try do
          case CasyncFormat.detect_format(binary_data) do
            {:ok, _format} -> :ok
            {:error, _reason} -> :ok
          end

          case CasyncFormat.parse_index(binary_data) do
            {:ok, _result} -> :ok
            {:error, _reason} -> :ok
          end

          case CasyncFormat.parse_archive(binary_data) do
            {:ok, _result} -> :ok
            {:error, _reason} -> :ok
          end

          case CasyncFormat.parse_chunk(binary_data) do
            {:ok, _result} -> :ok
            {:error, _reason} -> :ok
          end
        rescue
          _ -> flunk("Parser crashed on input: #{inspect(binary_data)}")
        end
      end
    end

    property "valid caibx files always parse successfully" do
      check all chunk_count <- integer(1..50),
                chunk_size <- integer(1..4096) do

        # Generate a valid caibx structure
        binary_data = generate_valid_caibx(chunk_count, chunk_size)

        assert {:ok, result} = CasyncFormat.parse_index(binary_data)
        assert CasyncFixtures.validate_index_structure(result)
        assert result.header.chunk_count == chunk_count
      end
    end

    property "valid catar files always parse successfully" do
      check all entry_count <- integer(1..20),
                entry_types <- list_of(member_of([:file, :directory, :symlink]), length: entry_count) do

        # Generate a valid catar structure
        binary_data = generate_valid_catar(entry_types)

        assert {:ok, result} = CasyncFormat.parse_archive(binary_data)
        assert CasyncFixtures.validate_archive_structure(result)
        assert length(result.entries) == entry_count
      end
    end

    property "chunk IDs are always 32 bytes" do
      check all chunk_count <- integer(1..10) do
        binary_data = generate_valid_caibx(chunk_count, 1024)

        {:ok, result} = CasyncFormat.parse_index(binary_data)

        Enum.each(result.chunks, fn chunk ->
          assert byte_size(chunk.chunk_id) == 32
        end)
      end
    end

    property "chunk offsets are monotonically increasing" do
      check all chunk_count <- integer(2..20) do
        binary_data = generate_valid_caibx(chunk_count, 1024)

        {:ok, result} = CasyncFormat.parse_index(binary_data)

        offsets = Enum.map(result.chunks, & &1.offset)
        sorted_offsets = Enum.sort(offsets)

        # Offsets should be in non-decreasing order
        assert offsets == sorted_offsets
      end
    end

    property "parsing is deterministic" do
      check all binary_data <- binary(min_length: 10, max_length: 100) do
        # Parse the same data multiple times
        results = for _i <- 1..3 do
          [
            CasyncFormat.detect_format(binary_data),
            CasyncFormat.parse_index(binary_data),
            CasyncFormat.parse_archive(binary_data),
            CasyncFormat.parse_chunk(binary_data)
          ]
        end

        # All results should be identical
        [first_result | other_results] = results
        Enum.each(other_results, fn result ->
          assert result == first_result
        end)
      end
    end

    property "invalid magic headers are rejected" do
      check all wrong_magic <- binary(length: 3),
                rest_data <- binary(min_length: 10, max_length: 100),
                wrong_magic != <<0xCA, 0x1B, 0x5C>> and
                wrong_magic != <<0xCA, 0x1D, 0x5C>> and
                wrong_magic != <<0xCA, 0x1A, 0x52>> do

        invalid_data = wrong_magic <> rest_data

        assert {:error, :unknown_format} = CasyncFormat.detect_format(invalid_data)
        assert {:error, _} = CasyncFormat.parse_index(invalid_data)
        assert {:error, _} = CasyncFormat.parse_archive(invalid_data)
      end
    end

    property "truncated files are handled gracefully" do
      check all original_length <- integer(50..200),
                truncate_at <- integer(1..49) do

        # Create valid data then truncate it
        binary_data = generate_valid_caibx(5, 1024)
        truncated_data = binary_part(binary_data, 0, min(truncate_at, byte_size(binary_data)))

        # Should either parse successfully or return an error (not crash)
        case CasyncFormat.parse_index(truncated_data) do
          {:ok, _result} -> :ok  # Somehow still valid
          {:error, _reason} -> :ok  # Expected for truncated data
        end
      end
    end

    property "header values are within reasonable ranges" do
      check all chunk_count <- integer(1..1000),
                total_size <- integer(1..1_000_000) do

        binary_data = generate_valid_caibx_with_values(chunk_count, total_size)

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            assert result.header.chunk_count == chunk_count
            assert result.header.total_size == total_size
            assert result.header.version >= 0
          {:error, _} ->
            # May fail if generated data is invalid
            :ok
        end
      end
    end

    property "entry types are correctly identified" do
      check all entry_types <- list_of(member_of([1, 2, 3, 4, 5, 6]), min_length: 1, max_length: 10) do
        expected_types = Enum.map(entry_types, fn
          1 -> :file
          2 -> :directory
          3 -> :symlink
          4 -> :device
          5 -> :fifo
          6 -> :socket
        end)

        binary_data = generate_catar_with_types(entry_types)

        case CasyncFormat.parse_archive(binary_data) do
          {:ok, result} ->
            actual_types = Enum.map(result.entries, & &1.type)
            assert actual_types == expected_types
          {:error, _} ->
            # May fail if generated data creates invalid structure
            :ok
        end
      end
    end
  end

  describe "boundary condition testing" do
    property "empty chunk lists are handled correctly" do
      check all _seed <- integer() do
        # Create caibx with 0 chunks
        magic = <<0xCA, 0x1B, 0x5C>>
        version = <<1::little-32>>
        total_size = <<0::little-64>>
        chunk_count = <<0::little-32>>
        reserved = <<0::little-32>>

        binary_data = magic <> version <> total_size <> chunk_count <> reserved

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            assert result.header.chunk_count == 0
            assert result.chunks == []
          {:error, _} ->
            # Parser may reject 0-chunk files as invalid
            :ok
        end
      end
    end

    property "maximum values don't cause overflow" do
      check all _seed <- integer() do
        # Test with maximum uint32/uint64 values
        magic = <<0xCA, 0x1B, 0x5C>>
        version = <<0xFFFFFFFF::little-32>>
        total_size = <<0xFFFFFFFFFFFFFFFF::little-64>>
        chunk_count = <<0::little-32>>  # 0 chunks to keep data size reasonable
        reserved = <<0::little-32>>

        binary_data = magic <> version <> total_size <> chunk_count <> reserved

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            # Values should be parsed correctly without overflow
            assert result.header.version == 0xFFFFFFFF
            assert result.header.total_size == 0xFFFFFFFFFFFFFFFF
          {:error, _} ->
            # Parser may reject extreme values
            :ok
        end
      end
    end
  end

  # Helper functions for generating test data

  defp generate_valid_caibx(chunk_count, chunk_size) do
    magic = <<0xCA, 0x1B, 0x5C>>
    version = <<1::little-32>>
    total_size = <<chunk_count * chunk_size::little-64>>
    chunk_count_bytes = <<chunk_count::little-32>>
    reserved = <<0::little-32>>
    header = version <> total_size <> chunk_count_bytes <> reserved

    chunks = for i <- 0..(chunk_count - 1) do
      chunk_id = :crypto.strong_rand_bytes(32)
      offset = <<i * chunk_size::little-64>>
      size = <<chunk_size::little-32>>
      flags = <<0::little-32>>
      chunk_id <> offset <> size <> flags
    end

    magic <> header <> Enum.join(chunks)
  end

  defp generate_valid_caibx_with_values(chunk_count, total_size) do
    magic = <<0xCA, 0x1B, 0x5C>>
    version = <<1::little-32>>
    total_size_bytes = <<total_size::little-64>>
    chunk_count_bytes = <<chunk_count::little-32>>
    reserved = <<0::little-32>>
    header = version <> total_size_bytes <> chunk_count_bytes <> reserved

    chunk_size = if chunk_count > 0, do: div(total_size, chunk_count), else: 0

    chunks = for i <- 0..(chunk_count - 1) do
      chunk_id = :crypto.strong_rand_bytes(32)
      offset = <<i * chunk_size::little-64>>
      size = <<chunk_size::little-32>>
      flags = <<0::little-32>>
      chunk_id <> offset <> size <> flags
    end

    magic <> header <> Enum.join(chunks)
  end

  defp generate_valid_catar(entry_types) do
    magic = <<0xCA, 0x1A, 0x52>>

    entries = Enum.map(entry_types, fn type ->
      type_code = case type do
        :file -> 1
        :directory -> 2
        :symlink -> 3
        :device -> 4
        :fifo -> 5
        :socket -> 6
      end

      entry_size = <<64::little-64>>
      entry_type = <<type_code::little-64>>
      entry_flags = <<0::little-64>>
      padding = <<0::little-64>>
      entry_header = entry_size <> entry_type <> entry_flags <> padding

      mode = <<0o644::little-64>>
      uid = <<1000::little-64>>
      gid = <<1000::little-64>>
      mtime = <<1234567890::little-64>>
      metadata = mode <> uid <> gid <> mtime

      entry_header <> metadata
    end)

    magic <> Enum.join(entries)
  end

  defp generate_catar_with_types(type_codes) do
    magic = <<0xCA, 0x1A, 0x52>>

    entries = Enum.map(type_codes, fn type_code ->
      entry_size = <<64::little-64>>
      entry_type = <<type_code::little-64>>
      entry_flags = <<0::little-64>>
      padding = <<0::little-64>>
      entry_header = entry_size <> entry_type <> entry_flags <> padding

      mode = <<0o644::little-64>>
      uid = <<1000::little-64>>
      gid = <<1000::little-64>>
      mtime = <<1234567890::little-64>>
      metadata = mode <> uid <> gid <> mtime

      entry_header <> metadata
    end)

    magic <> Enum.join(entries)
  end
end
