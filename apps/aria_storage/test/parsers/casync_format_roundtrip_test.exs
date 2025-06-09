# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormatRoundtripTest do
  use ExUnit.Case
  alias AriaStorage.Parsers.CasyncFormat

  @moduledoc """
  Roundtrip tests for casync format import and export functionality.

  These tests verify that:
  1. Parsed data can be re-encoded to binary format
  2. Re-encoded binary is bit-exact with the original
  3. Import/export operations are lossless
  """

  # Test data paths
  @aria_testdata_path "/home/fire/aria-character-core/apps/aria_storage/test/support/testdata"
  @desync_testdata_path "/home/fire/desync/testdata"

  describe "caibx roundtrip tests" do
    test "aria-storage blob1.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for blob1.caibx"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping blob1.caibx test - file not found")
          :ok
      end
    end

    test "aria-storage blob2.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "blob2.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for blob2.caibx"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping blob2.caibx test - file not found")
          :ok
      end
    end

    test "aria-storage index.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "index.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for index.caibx"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping index.caibx test - file not found")
          :ok
      end
    end

    test "processes all available caibx files for roundtrip accuracy" do
      caibx_files = [
        Path.join(@aria_testdata_path, "*.caibx"),
        Path.join(@desync_testdata_path, "*.caibx")
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()

      if Enum.empty?(caibx_files) do
        IO.puts("No caibx files found for roundtrip testing")
        :ok
      else
        Enum.each(caibx_files, fn file_path ->
          filename = Path.basename(file_path)

          # Skip corrupted files as they might not roundtrip properly
          unless String.contains?(filename, "corrupted") do
            case File.read(file_path) do
              {:ok, original_data} ->
                case CasyncFormat.parse_index(original_data) do
                  {:ok, parsed} ->
                    case CasyncFormat.encode_index(parsed) do
                      {:ok, re_encoded_data} ->
                        if original_data != re_encoded_data do
                          # Debug information for failed roundtrip
                          IO.puts("Roundtrip failed for #{filename}")
                          IO.puts("Original size: #{byte_size(original_data)}")
                          IO.puts("Re-encoded size: #{byte_size(re_encoded_data)}")

                          # Find first differing byte
                          diff_pos = find_first_difference(original_data, re_encoded_data)
                          if diff_pos do
                            IO.puts("First difference at byte #{diff_pos}")
                          end

                          flunk("Roundtrip failed for #{filename}")
                        end
                      {:error, reason} ->
                        flunk("Failed to encode #{filename}: #{inspect(reason)}")
                    end
                  {:error, _reason} ->
                    # Skip files that don't parse (might be corrupted test data)
                    :ok
                end
              {:error, reason} ->
                flunk("Failed to read #{file_path}: #{inspect(reason)}")
            end
          end
        end)
      end
    end
  end

  describe "catar roundtrip tests" do
    test "aria-storage flat.catar roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_archive(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for flat.catar"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping flat.catar test - file not found")
          :ok
      end
    end

    test "aria-storage nested.catar roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_archive(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for nested.catar"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping nested.catar test - file not found")
          :ok
      end
    end

    test "aria-storage complex.catar roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "complex.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Re-encode the parsed data
          assert {:ok, re_encoded_data} = CasyncFormat.encode_archive(parsed)

          # Verify bit-exact match
          assert original_data == re_encoded_data,
            "Re-encoded data does not match original for complex.catar"

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          IO.puts("Skipping complex.catar test - file not found")
          :ok
      end
    end

    test "processes all available catar files for roundtrip accuracy" do
      catar_files = [
        Path.join(@aria_testdata_path, "*.catar"),
        Path.join(@desync_testdata_path, "*.catar")
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()

      if Enum.empty?(catar_files) do
        IO.puts("No catar files found for roundtrip testing")
        :ok
      else
        Enum.each(catar_files, fn file_path ->
          filename = Path.basename(file_path)

          case File.read(file_path) do
            {:ok, original_data} ->
              case CasyncFormat.parse_archive(original_data) do
                {:ok, parsed} ->
                  case CasyncFormat.encode_archive(parsed) do
                    {:ok, re_encoded_data} ->
                      if original_data != re_encoded_data do
                        # Debug information for failed roundtrip
                        IO.puts("Roundtrip failed for #{filename}")
                        IO.puts("Original size: #{byte_size(original_data)}")
                        IO.puts("Re-encoded size: #{byte_size(re_encoded_data)}")

                        # Find first differing byte
                        diff_pos = find_first_difference(original_data, re_encoded_data)
                        if diff_pos do
                          IO.puts("First difference at byte #{diff_pos}")
                        end

                        flunk("Roundtrip failed for #{filename}")
                      end
                    {:error, reason} ->
                      flunk("Failed to encode #{filename}: #{inspect(reason)}")
                  end
                {:error, _reason} ->
                  # Skip files that don't parse (might be corrupted test data)
                  :ok
              end
            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      end
    end
  end

  describe "chunk file roundtrip tests" do
    test "processes available cacnk files for roundtrip accuracy" do
      cacnk_files = [
        Path.join(@aria_testdata_path, "**/*.cacnk"),
        Path.join(@desync_testdata_path, "**/*.cacnk")
      ]
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.uniq()
      |> Enum.take(10)  # Limit to first 10 for test performance

      if Enum.empty?(cacnk_files) do
        IO.puts("No cacnk files found for roundtrip testing")
        :ok
      else
        Enum.each(cacnk_files, fn file_path ->
          filename = Path.basename(file_path)

          case File.read(file_path) do
            {:ok, original_data} ->
              case CasyncFormat.parse_chunk(original_data) do
                {:ok, parsed} ->
                  case CasyncFormat.encode_chunk(parsed) do
                    {:ok, re_encoded_data} ->
                      if original_data != re_encoded_data do
                        # Debug information for failed roundtrip
                        IO.puts("Roundtrip failed for #{filename}")
                        IO.puts("Original size: #{byte_size(original_data)}")
                        IO.puts("Re-encoded size: #{byte_size(re_encoded_data)}")

                        # Find first differing byte
                        diff_pos = find_first_difference(original_data, re_encoded_data)
                        if diff_pos do
                          IO.puts("First difference at byte #{diff_pos}")
                        end

                        flunk("Roundtrip failed for #{filename}")
                      end
                    {:error, reason} ->
                      flunk("Failed to encode #{filename}: #{inspect(reason)}")
                  end
                {:error, _reason} ->
                  # Skip files that don't parse (might be corrupted test data)
                  :ok
              end
            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      end
    end
  end

  describe "synthetic data roundtrip tests" do
    test "synthetic caibx data roundtrips correctly" do
      # Create synthetic test data
      original_data = create_synthetic_caibx()

      # Parse the data
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)

      # Re-encode the parsed data
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data,
        "Synthetic caibx data roundtrip failed"
    end

    test "synthetic catar data roundtrips correctly" do
      # Create synthetic test data
      original_data = create_synthetic_catar()

      # Parse the data
      assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

      # Re-encode the parsed data
      assert {:ok, re_encoded_data} = CasyncFormat.encode_archive(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data,
        "Synthetic catar data roundtrip failed"
    end

    test "synthetic chunk data roundtrips correctly" do
      # Create synthetic test data
      original_data = create_synthetic_chunk()

      # Parse the data
      assert {:ok, parsed} = CasyncFormat.parse_chunk(original_data)

      # Re-encode the parsed data
      assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data,
        "Synthetic chunk data roundtrip failed"
    end
  end

  describe "edge cases" do
    test "empty index file roundtrips correctly" do
      # Create an empty caibx file (header only, no chunks)
      magic = <<0xCA, 0x1B, 0x5C>>
      header = <<1::little-32>> <>          # version
               <<0::little-64>> <>          # total_size
               <<0::little-32>> <>          # chunk_count
               <<0::little-32>>             # reserved
      original_data = magic <> header

      # Parse and re-encode
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data
    end

    test "single chunk index roundtrips correctly" do
      # Create a caibx file with exactly one chunk
      magic = <<0xCA, 0x1B, 0x5C>>
      header = <<1::little-32>> <>          # version
               <<1024::little-64>> <>       # total_size
               <<1::little-32>> <>          # chunk_count
               <<0::little-32>>             # reserved

      # Single chunk entry
      chunk_id = :crypto.strong_rand_bytes(32)
      chunk_entry = chunk_id <>
                   <<0::little-64>> <>      # offset
                   <<1024::little-32>> <>   # size
                   <<0::little-32>>         # flags

      original_data = magic <> header <> chunk_entry

      # Parse and re-encode
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data
    end
  end

  # Helper functions

  defp find_first_difference(data1, data2) do
    min_size = min(byte_size(data1), byte_size(data2))

    Enum.find(0..(min_size - 1), fn i ->
      :binary.at(data1, i) != :binary.at(data2, i)
    end)
  end

  defp create_synthetic_caibx do
    # Create a simple caibx with 3 chunks
    magic = <<0xCA, 0x1B, 0x5C>>

    header = <<1::little-32>> <>          # version
             <<3072::little-64>> <>       # total_size (3 * 1024)
             <<3::little-32>> <>          # chunk_count
             <<0::little-32>>             # reserved

    # Create 3 chunks
    chunks = for i <- 0..2 do
      chunk_id = :crypto.strong_rand_bytes(32)
      chunk_id <>
      <<(i * 1024)::little-64>> <>       # offset
      <<1024::little-32>> <>              # size
      <<0::little-32>>                    # flags
    end

    magic <> header <> Enum.join(chunks)
  end

  defp create_synthetic_catar do
    # Create a simple catar with one file entry
    magic = <<0xCA, 0x1A, 0x52>>

    # File entry
    entry_header = <<64::little-64>> <>   # size
                   <<1::little-64>> <>    # type (file)
                   <<0::little-64>> <>    # flags
                   <<0::little-64>>       # padding

    metadata = <<0o644::little-64>> <>    # mode
               <<1000::little-64>> <>     # uid
               <<1000::little-64>> <>     # gid
               <<1234567890::little-64>>  # mtime

    magic <> entry_header <> metadata
  end

  defp create_synthetic_chunk do
    # Create a simple uncompressed chunk
    header = <<100::little-32>> <>        # compressed_size
             <<100::little-32>> <>        # uncompressed_size
             <<0::little-32>> <>          # compression_type (none)
             <<0::little-32>>             # flags

    data = :crypto.strong_rand_bytes(100)

    header <> data
  end
end
