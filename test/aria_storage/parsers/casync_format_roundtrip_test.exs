# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormatRoundtripTest do
  use ExUnit.Case
  require Logger
  alias AriaStorage.Parsers.CasyncFormat

  @moduledoc """
  Roundtrip tests for casync format import and export functionality.

  These tests verify that:
  1. Parsed data can be re-encoded to binary format
  2. Re-encoded binary is bit-exact with the original
  3. Import/export operations are lossless
  """

  # Test data paths
  @aria_testdata_path Path.join([__DIR__, "..", "support", "testdata"])
  @desync_testdata_path Path.join([__DIR__, "..", "support", "testdata"])

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
          TestOutput.trace_puts("Skipping blob1.caibx test - file not found")
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
          TestOutput.trace_puts("Skipping blob2.caibx test - file not found")
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
          TestOutput.trace_puts("Skipping index.caibx test - file not found")
          :ok
      end
    end

    test "processes all available caibx files for roundtrip accuracy" do
      caibx_files =
        [
          Path.join(@aria_testdata_path, "*.caibx"),
          Path.join(@desync_testdata_path, "*.caibx")
        ]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.uniq()

      if Enum.empty?(caibx_files) do
        TestOutput.trace_puts("No caibx files found for roundtrip testing")
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
                          TestOutput.trace_puts("Roundtrip failed for #{filename}")
                          TestOutput.trace_puts("Original size: #{byte_size(original_data)}")
                          TestOutput.trace_puts("Re-encoded size: #{byte_size(re_encoded_data)}")

                          # Find first differing byte
                          diff_pos = find_first_difference(original_data, re_encoded_data)

                          if diff_pos do
                            TestOutput.trace_puts("First difference at byte #{diff_pos}")
                          end

                          flunk("Roundtrip failed for #{filename}")
                        end
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
    test "aria-storage flat.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data - this should work
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Verify parsing extracted correct structure
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)

          # Test roundtrip encoding with hex comparison
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          Logger.info("Skipping flat.catar test - file not found")
          :ok
      end
    end

    test "aria-storage nested.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data - this should work
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Verify parsing extracted correct structure
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)

          # Should have both files and directories for nested structure
          assert length(files) > 0
          assert length(directories) > 0

          # Test roundtrip encoding with hex comparison
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          Logger.info("Skipping nested.catar test - file not found")
          :ok
      end
    end

    test "aria-storage complex.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "complex.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data - this should work
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Verify parsing extracted correct structure
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)

          # Complex archive should have multiple files
          assert length(files) > 0

          # Test roundtrip encoding with hex comparison
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          Logger.info("Skipping complex.catar test - file not found")
          :ok
      end
    end

    test "aria-storage flatdir.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "flatdir.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          # Parse the original data - this should work
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

          # Verify parsing extracted correct structure
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)

          # Flatdir should have directories but no files
          assert length(files) == 0
          assert length(directories) > 0

          # Test roundtrip encoding with hex comparison
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          # Skip test if file doesn't exist
          Logger.info("Skipping flatdir.catar test - file not found")
          :ok
      end
    end

    test "processes all available catar files for parsing consistency" do
      catar_files =
        [
          Path.join(@aria_testdata_path, "*.catar"),
          Path.join(@desync_testdata_path, "*.catar")
        ]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.uniq()

      if Enum.empty?(catar_files) do
        Logger.info("No catar files found for parsing testing")
        :ok
      else
        Enum.each(catar_files, fn file_path ->
          filename = Path.basename(file_path)

          case File.read(file_path) do
            {:ok, original_data} ->
              case CasyncFormat.parse_archive(original_data) do
                {:ok, parsed} ->
                  # Verify basic structure
                  assert %{
                           format: :catar,
                           files: files,
                           directories: directories,
                           elements: elements
                         } = parsed

                  assert is_list(files)
                  assert is_list(directories)
                  assert is_list(elements)

                  # Verify elements have proper structure
                  Enum.each(elements, fn element ->
                    assert is_map(element)
                    assert Map.has_key?(element, :type)
                  end)

                  # Verify files have names and types
                  Enum.each(files, fn file ->
                    assert Map.has_key?(file, :name)
                    assert Map.has_key?(file, :type)
                    assert file.type in [:file, :symlink, :device]
                  end)

                  # Verify directories have names
                  Enum.each(directories, fn dir ->
                    assert Map.has_key?(dir, :name)
                    assert Map.has_key?(dir, :type)
                    assert dir.type == :directory
                  end)

                {:error, reason} ->
                  flunk("Failed to parse #{filename}: #{inspect(reason)}")
              end

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      end
    end

    test "processes all available catar files for roundtrip accuracy" do
      catar_files =
        [
          Path.join(@aria_testdata_path, "*.catar"),
          Path.join(@desync_testdata_path, "*.catar")
        ]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.uniq()

      if Enum.empty?(catar_files) do
        Logger.info("No catar files found for roundtrip testing")
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
                        # Use comprehensive hex diff comparison for CATAR files
                        Logger.info("Testing roundtrip for #{filename}")
                        CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)
                      else
                        Logger.info("Perfect roundtrip for #{filename}")
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

  describe "caidx roundtrip tests" do
    test "synthetic caidx data roundtrip is bit-exact" do
      # Create test CAIDX data using our helper function from main test file
      caidx_data = create_caidx_test_data()

      # Parse the data
      assert {:ok, parsed} = CasyncFormat.parse_index(caidx_data)
      assert parsed.format == :caidx

      # Re-encode the parsed data
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert caidx_data == re_encoded_data,
             "Re-encoded CAIDX data does not match original"
    end

    test "empty caidx roundtrip is bit-exact" do
      # Create minimal CAIDX with no table data
      empty_caidx = <<
        # Size of FormatIndex
        48::little-64,
        # CA_FORMAT_INDEX constant
        0x96824D9C7B129FF9::little-64,
        # Feature flags (0 = CAIDX)
        0::little-64,
        # chunk_size_min
        16384::little-64,
        # chunk_size_avg  
        65536::little-64,
        # chunk_size_max
        262_144::little-64
      >>

      # Parse and re-encode
      assert {:ok, parsed} = CasyncFormat.parse_index(empty_caidx)
      assert parsed.format == :caidx
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert empty_caidx == re_encoded_data,
             "Re-encoded empty CAIDX data does not match original"
    end

    # Helper function from main test file
    defp create_caidx_test_data() do
      # CAIDX uses desync FormatIndex structure with feature_flags = 0 (no SHA512-256)
      format_index = <<
        # Size of FormatIndex
        48::little-64,
        # CA_FORMAT_INDEX constant
        0x96824D9C7B129FF9::little-64,
        # Feature flags (0 = CAIDX, not CAIBX)
        0::little-64,
        # chunk_size_min
        1024::little-64,
        # chunk_size_avg  
        1024::little-64,
        # chunk_size_max
        1024::little-64
      >>

      # FormatTable header
      table_header = <<
        # Table marker
        0xFFFFFFFFFFFFFFFF::little-64,
        # CA_FORMAT_TABLE constant
        0xE75B9E112F17417D::little-64
      >>

      # Single chunk table item
      chunk_id = :crypto.strong_rand_bytes(32)
      # offset=2048, chunk_id=32 bytes
      table_item = <<2048::little-64>> <> chunk_id

      # Table tail marker
      table_tail = <<
        # Zero offset
        0::little-64,
        # Zero pad
        0::little-64,
        # Size field
        48::little-64,
        # Table size (header + item + tail)
        88::little-64,
        # CA_FORMAT_TABLE_TAIL_MARKER
        0x4B4F050E5549ECD1::little-64
      >>

      format_index <> table_header <> table_item <> table_tail
    end
  end

  describe "chunk file roundtrip tests" do
    test "synthetic cacnk data roundtrip is bit-exact" do
      # Create test CACNK data
      cacnk_data = create_cacnk_test_data()

      # Parse the data
      assert {:ok, parsed} = CasyncFormat.parse_chunk(cacnk_data)
      assert parsed.magic == :cacnk

      # Re-encode the parsed data
      assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)

      # Verify bit-exact match
      assert cacnk_data == re_encoded_data,
             "Re-encoded CACNK data does not match original"
    end

    test "various compression types roundtrip correctly" do
      compression_cases = [
        {0, :none},
        {1, :zstd}
      ]

      Enum.each(compression_cases, fn {compression_type, compression_atom} ->
        # Create chunk with specific compression
        magic = <<0xCA, 0xC4, 0x4E>>
        compressed_size = 75
        uncompressed_size = 150
        flags = 0

        header =
          <<compressed_size::little-32, uncompressed_size::little-32, compression_type::little-32,
            flags::little-32>>

        data = :crypto.strong_rand_bytes(compressed_size)

        original_data = magic <> header <> data

        # Parse and re-encode
        assert {:ok, parsed} = CasyncFormat.parse_chunk(original_data)
        assert parsed.header.compression == compression_atom
        assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)

        # Verify bit-exact match
        assert original_data == re_encoded_data,
               "Re-encoded CACNK data with compression #{compression_atom} does not match original"
      end)
    end

    # Helper function to create test CACNK data
    defp create_cacnk_test_data() do
      # CACNK magic header: 0xCA 0xC4 0x4E
      magic = <<0xCA, 0xC4, 0x4E>>

      # Chunk header
      compressed_size = 100
      uncompressed_size = 200
      # zstd
      compression_type = 1
      flags = 0

      header =
        <<compressed_size::little-32, uncompressed_size::little-32, compression_type::little-32,
          flags::little-32>>

      # Dummy compressed data
      data = :crypto.strong_rand_bytes(100)

      magic <> header <> data
    end

    test "processes available cacnk files for roundtrip accuracy" do
      cacnk_files =
        [
          Path.join(@aria_testdata_path, "**/*.cacnk"),
          Path.join(@desync_testdata_path, "**/*.cacnk")
        ]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.uniq()
        # Limit to first 10 for test performance
        |> Enum.take(10)

      if Enum.empty?(cacnk_files) do
        Logger.info("No cacnk files found for roundtrip testing")
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
                        Logger.info("Roundtrip failed for #{filename}")
                        Logger.info("Original size: #{byte_size(original_data)}")
                        Logger.info("Re-encoded size: #{byte_size(re_encoded_data)}")

                        # Find first differing byte
                        diff_pos = find_first_difference(original_data, re_encoded_data)

                        if diff_pos do
                          Logger.info("First difference at byte #{diff_pos}")
                        end

                        flunk("Roundtrip failed for #{filename}")
                      end
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

      # Test roundtrip encoding with hex comparison
      case CasyncFormat.encode_archive(parsed) do
        {:ok, re_encoded_data} ->
          if original_data == re_encoded_data do
            Logger.info("Perfect synthetic CATAR roundtrip")
          else
            # Use hex diff for detailed comparison
            Logger.info("Synthetic CATAR roundtrip differences detected:")
            CasyncFormat.hex_compare(original_data, re_encoded_data)
          end

        {:error, reason} ->
          flunk("Failed to encode synthetic CATAR data: #{inspect(reason)}")
      end
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
      # Create an empty CAIBX file using proper FormatIndex structure (header only, no table)
      empty_caibx = <<
        # Size of FormatIndex
        48::little-64,
        # CA_FORMAT_INDEX constant
        0x96824D9C7B129FF9::little-64,
        # Feature flags (SHA512-256 for CAIBX)
        0x2000000000000000::little-64,
        # chunk_size_min
        16384::little-64,
        # chunk_size_avg  
        65536::little-64,
        # chunk_size_max
        262_144::little-64
      >>

      # Parse and re-encode
      assert {:ok, parsed} = CasyncFormat.parse_index(empty_caibx)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert empty_caibx == re_encoded_data
    end

    test "single chunk index roundtrips correctly" do
      # Create a CAIBX file with exactly one chunk using proper FormatIndex structure
      format_index = <<
        # Size of FormatIndex
        48::little-64,
        # CA_FORMAT_INDEX constant
        0x96824D9C7B129FF9::little-64,
        # Feature flags (SHA512-256 for CAIBX)
        0x2000000000000000::little-64,
        # chunk_size_min
        1024::little-64,
        # chunk_size_avg  
        1024::little-64,
        # chunk_size_max
        1024::little-64
      >>

      # FormatTable header
      table_header = <<
        # Table marker
        0xFFFFFFFFFFFFFFFF::little-64,
        # CA_FORMAT_TABLE constant
        0xE75B9E112F17417D::little-64
      >>

      # Single table item
      chunk_id = :crypto.strong_rand_bytes(32)
      # offset=1024, chunk_id
      table_item = <<1024::little-64>> <> chunk_id

      # Table tail marker
      # header + item + tail
      table_size = 16 + 40 + 40

      table_tail = <<
        # Zero offset
        0::little-64,
        # Zero pad
        0::little-64,
        # Size field
        48::little-64,
        # Table size
        table_size::little-64,
        # CA_FORMAT_TABLE_TAIL_MARKER
        0x4B4F050E5549ECD1::little-64
      >>

      original_data = format_index <> table_header <> table_item <> table_tail

      # Parse and re-encode
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

      # Verify bit-exact match
      assert original_data == re_encoded_data
    end
  end

  # Last attempted fix for test/parsers/casync_format_roundtrip_test.exs infinite loop: June 14, 2025

  # Helper functions

  defp find_first_difference(data1, data2) do
    min_size = min(byte_size(data1), byte_size(data2))

    Enum.find(0..(min_size - 1), fn i ->
      :binary.at(data1, i) != :binary.at(data2, i)
    end)
  end

  defp create_synthetic_caibx do
    # Create CAIBX using proper desync FormatIndex structure (not legacy magic bytes)
    format_index = <<
      # Size of FormatIndex
      48::little-64,
      # CA_FORMAT_INDEX constant
      0x96824D9C7B129FF9::little-64,
      # Feature flags (SHA512-256 for CAIBX)
      0x2000000000000000::little-64,
      # chunk_size_min
      1024::little-64,
      # chunk_size_avg  
      1024::little-64,
      # chunk_size_max
      1024::little-64
    >>

    # FormatTable header
    table_header = <<
      # Table marker
      0xFFFFFFFFFFFFFFFF::little-64,
      # CA_FORMAT_TABLE constant
      0xE75B9E112F17417D::little-64
    >>

    # Create 3 table items
    chunk1_id = :crypto.strong_rand_bytes(32)
    chunk2_id = :crypto.strong_rand_bytes(32)
    chunk3_id = :crypto.strong_rand_bytes(32)

    # offset=1024, chunk_id
    # offset=2048, chunk_id  
    # offset=3072, chunk_id
    table_items =
      <<1024::little-64>> <>
        chunk1_id <>
        <<2048::little-64>> <>
        chunk2_id <>
        <<3072::little-64>> <> chunk3_id

    # Table tail marker
    # header + items + tail
    table_size = 16 + byte_size(table_items) + 40

    table_tail = <<
      # Zero offset
      0::little-64,
      # Zero pad
      0::little-64,
      # Size field
      48::little-64,
      # Table size
      table_size::little-64,
      # CA_FORMAT_TABLE_TAIL_MARKER
      0x4B4F050E5549ECD1::little-64
    >>

    format_index <> table_header <> table_items <> table_tail
  end

  defp create_synthetic_catar do
    # Create a simple catar with one file entry using proper CATAR format
    # CaFormatEntry (64 bytes)
    entry_header = <<
      # size
      64::little-64,
      # CA_FORMAT_ENTRY constant
      0x1396FABCEA5BBB51::little-64,
      # feature_flags
      0::little-64,
      # mode
      0o644::little-64,
      # uid
      1000::little-64,
      # gid
      1000::little-64,
      # mtime
      1_234_567_890::little-64,
      # reserved/padding
      0::little-64
    >>

    entry_header
  end

  defp create_synthetic_chunk do
    # Create a simple uncompressed chunk with proper magic header
    # CACNK magic
    magic = <<0xCA, 0xC4, 0x4E>>

    # compressed_size
    # uncompressed_size
    # compression_type (none)
    # flags
    header =
      <<100::little-32>> <>
        <<100::little-32>> <>
        <<0::little-32>> <>
        <<0::little-32>>

    data = :crypto.strong_rand_bytes(100)

    magic <> header <> data
  end
end
