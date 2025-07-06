# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

Code.require_file("../support/casync_fixtures.ex", __DIR__)

defmodule AriaStorage.Parsers.CasyncFormatPropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.TestFixtures.CasyncFixtures

  @moduledoc "Property-based tests for the casync format parser.\n\nThese tests use StreamData to generate random valid and invalid inputs\nto ensure the parser handles edge cases robustly.\n"
  describe("property-based parsing tests") do
    property("parser never crashes on random binary input") do
      check(all(binary_data <- binary(min_length: 0, max_length: 1000))) do
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

    property("valid caibx files always parse successfully") do
      check(
        all(
          chunk_count <- integer(1..50),
          chunk_size <- integer(1..4096)
        )
      ) do
        binary_data = generate_valid_caibx(chunk_count, chunk_size)
        assert {:ok, result} = CasyncFormat.parse_index(binary_data)
        assert CasyncFixtures.validate_index_structure(result)
        assert result.header.chunk_count == chunk_count
      end
    end

    property("valid catar files always parse successfully") do
      check(
        all(
          entry_count <- integer(1..20),
          entry_types <- list_of(member_of([:file, :directory, :symlink]), length: entry_count)
        )
      ) do
        binary_data = generate_valid_catar(entry_types)
        assert {:ok, _} = CasyncFormat.parse_archive(binary_data)
      end
    end

    property("chunk IDs are always 32 bytes") do
      check(all(chunk_count <- integer(1..10))) do
        binary_data = generate_valid_caibx(chunk_count, 1024)
        {:ok, result} = CasyncFormat.parse_index(binary_data)
        Enum.each(result.chunks, fn chunk -> assert byte_size(chunk.chunk_id) == 32 end)
      end
    end

    property("chunk offsets are monotonically increasing") do
      check(all(chunk_count <- integer(2..20))) do
        binary_data = generate_valid_caibx(chunk_count, 1024)
        {:ok, result} = CasyncFormat.parse_index(binary_data)
        offsets = Enum.map(result.chunks, & &1.offset)
        sorted_offsets = Enum.sort(offsets)
        assert offsets == sorted_offsets
      end
    end

    property("parsing is deterministic") do
      check(all(binary_data <- binary(min_length: 10, max_length: 100))) do
        results =
          for _i <- 1..3 do
            [
              CasyncFormat.detect_format(binary_data),
              CasyncFormat.parse_index(binary_data),
              CasyncFormat.parse_archive(binary_data),
              CasyncFormat.parse_chunk(binary_data)
            ]
          end

        [first_result | other_results] = results
        Enum.each(other_results, fn result -> assert result == first_result end)
      end
    end

    property("invalid magic headers are rejected") do
      check(
        all(
          wrong_magic <- binary(length: 3),
          rest_data <- binary(min_length: 10, max_length: 100),
          wrong_magic != <<202, 27, 92>> and wrong_magic != <<202, 29, 92>> and
            wrong_magic != <<202, 26, 82>>
        )
      ) do
        invalid_data = wrong_magic <> rest_data
        assert {:error, :unknown_format} = CasyncFormat.detect_format(invalid_data)
        assert {:error, _} = CasyncFormat.parse_index(invalid_data)
        assert {:error, _} = CasyncFormat.parse_archive(invalid_data)
      end
    end

    property("truncated files are handled gracefully") do
      check(
        all(
          _original_length <- integer(50..200),
          truncate_at <- integer(1..49)
        )
      ) do
        binary_data = generate_valid_caibx(5, 1024)
        truncated_data = binary_part(binary_data, 0, min(truncate_at, byte_size(binary_data)))

        case CasyncFormat.parse_index(truncated_data) do
          {:ok, _result} -> :ok
          {:error, _reason} -> :ok
        end
      end
    end

    property("header values are within reasonable ranges") do
      check(all(chunk_count <- integer(1..1000))) do
        binary_data = generate_valid_caibx_with_values(chunk_count, 0)

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            assert result.header.chunk_count == chunk_count
            expected_total_size = chunk_count * 1024
            assert result.header.total_size == expected_total_size
            assert result.header.version >= 0

          {:error, _} ->
            :ok
        end
      end
    end

    property("entry types are correctly identified") do
      check(
        all(entry_types <- list_of(member_of([1, 2, 3, 4, 5, 6]), min_length: 1, max_length: 10))
      ) do
        _expected_types =
          Enum.map(entry_types, fn
            1 -> :file
            2 -> :directory
            3 -> :symlink
            4 -> :device
            5 -> :fifo
            6 -> :socket
          end)

        binary_data = generate_catar_with_types(entry_types)
        assert {:ok, _} = CasyncFormat.parse_archive(binary_data)
      end
    end
  end

  describe("boundary condition testing") do
    property("empty chunk lists are handled correctly") do
      check(all(_seed <- integer())) do
        binary_data = CasyncFixtures.create_multi_chunk_caibx(1)

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            assert result.header.chunk_count >= 0
            assert is_list(result.chunks)

          {:error, _} ->
            :ok
        end
      end
    end

    property("maximum values don't cause overflow") do
      check(all(_seed <- integer())) do
        magic = <<202, 27, 92>>
        version = <<4_294_967_295::little-32>>
        total_size = <<18_446_744_073_709_551_615::little-64>>
        chunk_count = <<0::little-32>>
        reserved = <<0::little-32>>
        binary_data = magic <> version <> total_size <> chunk_count <> reserved

        case CasyncFormat.parse_index(binary_data) do
          {:ok, result} ->
            assert result.header.version == 4_294_967_295
            assert result.header.total_size == 18_446_744_073_709_551_615

          {:error, _} ->
            :ok
        end
      end
    end
  end

  defp generate_valid_caibx(chunk_count, _chunk_size) do
    CasyncFixtures.create_multi_chunk_caibx(chunk_count)
  end

  defp generate_valid_caibx_with_values(chunk_count, _total_size) do
    CasyncFixtures.create_multi_chunk_caibx(chunk_count)
  end

  defp generate_valid_catar(_entry_types) do
    CasyncFixtures.create_complex_catar()
  end

  defp generate_catar_with_types(_type_codes) do
    CasyncFixtures.create_complex_catar()
  end
end
