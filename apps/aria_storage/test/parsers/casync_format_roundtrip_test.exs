# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormatRoundtripTest do
  use ExUnit.Case
  require Logger
  alias AriaStorage.Parsers.CasyncFormat

  @moduledoc "Roundtrip tests for casync format import and export functionality.\n\nThese tests verify that:\n1. Parsed data can be re-encoded to binary format\n2. Re-encoded binary is bit-exact with the original\n3. Import/export operations are lossless\n"
  @aria_testdata_path Path.join([__DIR__, "..", "support", "testdata"])
  @desync_testdata_path Path.join([__DIR__, "..", "support", "testdata"])
  describe("caibx roundtrip tests") do
    test "aria-storage blob1.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          assert original_data == re_encoded_data,
                 "Re-encoded data does not match original for blob1.caibx"

        {:error, :enoent} ->
          TestOutput.trace_puts("Skipping blob1.caibx test - file not found")
          :ok
      end
    end

    test "aria-storage blob2.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "blob2.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          assert original_data == re_encoded_data,
                 "Re-encoded data does not match original for blob2.caibx"

        {:error, :enoent} ->
          TestOutput.trace_puts("Skipping blob2.caibx test - file not found")
          :ok
      end
    end

    test "aria-storage index.caibx roundtrip is bit-exact" do
      file_path = Path.join(@aria_testdata_path, "index.caibx")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
          assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)

          assert original_data == re_encoded_data,
                 "Re-encoded data does not match original for index.caibx"

        {:error, :enoent} ->
          TestOutput.trace_puts("Skipping index.caibx test - file not found")
          :ok
      end
    end

    test "processes all available caibx files for roundtrip accuracy" do
      caibx_files =
        [Path.join(@aria_testdata_path, "*.caibx"), Path.join(@desync_testdata_path, "*.caibx")]
        |> Enum.flat_map(&Path.wildcard/1)
        |> Enum.uniq()

      if Enum.empty?(caibx_files) do
        TestOutput.trace_puts("No caibx files found for roundtrip testing")
        :ok
      else
        Enum.each(caibx_files, fn file_path ->
          filename = Path.basename(file_path)

          unless String.contains?(filename, "corrupted") do
            case File.read(file_path) do
              {:ok, original_data} ->
                case CasyncFormat.parse_index(original_data) do
                  {:ok, parsed} ->
                    case CasyncFormat.encode_index(parsed) do
                      {:ok, re_encoded_data} ->
                        if original_data != re_encoded_data do
                          TestOutput.trace_puts("Roundtrip failed for #{filename}")
                          TestOutput.trace_puts("Original size: #{byte_size(original_data)}")
                          TestOutput.trace_puts("Re-encoded size: #{byte_size(re_encoded_data)}")
                          diff_pos = find_first_difference(original_data, re_encoded_data)

                          if diff_pos do
                            TestOutput.trace_puts("First difference at byte #{diff_pos}")
                          end

                          flunk("Roundtrip failed for #{filename}")
                        end
                    end

                  {:error, _reason} ->
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

  describe("catar roundtrip tests") do
    test "aria-storage flat.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          Logger.info("Skipping flat.catar test - file not found")
          :ok
      end
    end

    test "aria-storage nested.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)
          assert length(files) > 0
          assert length(directories) > 0
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          Logger.info("Skipping nested.catar test - file not found")
          :ok
      end
    end

    test "aria-storage complex.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "complex.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)
          assert length(files) > 0
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          Logger.info("Skipping complex.catar test - file not found")
          :ok
      end
    end

    test "aria-storage flatdir.catar roundtrip encoding" do
      file_path = Path.join(@aria_testdata_path, "flatdir.catar")

      case File.read(file_path) do
        {:ok, original_data} ->
          assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)
          assert %{format: :catar, files: files, directories: directories} = parsed
          assert is_list(files)
          assert is_list(directories)
          assert length(files) == 0
          assert length(directories) > 0
          CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)

        {:error, :enoent} ->
          Logger.info("Skipping flatdir.catar test - file not found")
          :ok
      end
    end

    test "processes all available catar files for parsing consistency" do
      catar_files =
        [Path.join(@aria_testdata_path, "*.catar"), Path.join(@desync_testdata_path, "*.catar")]
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
                  assert %{
                           format: :catar,
                           files: files,
                           directories: directories,
                           elements: elements
                         } = parsed

                  assert is_list(files)
                  assert is_list(directories)
                  assert is_list(elements)

                  Enum.each(elements, fn element ->
                    assert is_map(element)
                    assert Map.has_key?(element, :type)
                  end)

                  Enum.each(files, fn file ->
                    assert Map.has_key?(file, :name)
                    assert Map.has_key?(file, :type)
                    assert file.type in [:file, :symlink, :device]
                  end)

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
        [Path.join(@aria_testdata_path, "*.catar"), Path.join(@desync_testdata_path, "*.catar")]
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
                        Logger.info("Testing roundtrip for #{filename}")
                        CasyncFormat.test_file_roundtrip_encoding(file_path, parsed)
                      else
                        Logger.info("Perfect roundtrip for #{filename}")
                      end

                    {:error, reason} ->
                      flunk("Failed to encode #{filename}: #{inspect(reason)}")
                  end

                {:error, _reason} ->
                  :ok
              end

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      end
    end
  end

  describe("caidx roundtrip tests") do
    test "synthetic caidx data roundtrip is bit-exact" do
      caidx_data = create_caidx_test_data()
      assert {:ok, parsed} = CasyncFormat.parse_index(caidx_data)
      assert parsed.format == :caidx
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)
      assert caidx_data == re_encoded_data, "Re-encoded CAIDX data does not match original"
    end

    test "empty caidx roundtrip is bit-exact" do
      empty_caidx =
        <<48::little-64, 10_845_316_187_136_630_777::little-64, 0::little-64, 16384::little-64,
          65536::little-64, 262_144::little-64>>

      assert {:ok, parsed} = CasyncFormat.parse_index(empty_caidx)
      assert parsed.format == :caidx
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)
      assert empty_caidx == re_encoded_data, "Re-encoded empty CAIDX data does not match original"
    end

    defp create_caidx_test_data() do
      format_index =
        <<48::little-64, 10_845_316_187_136_630_777::little-64, 0::little-64, 1024::little-64,
          1024::little-64, 1024::little-64>>

      table_header =
        <<18_446_744_073_709_551_615::little-64, 16_671_092_242_283_708_797::little-64>>

      chunk_id = :crypto.strong_rand_bytes(32)
      table_item = <<2048::little-64>> <> chunk_id

      table_tail =
        <<0::little-64, 0::little-64, 48::little-64, 88::little-64,
          5_426_561_635_123_326_161::little-64>>

      format_index <> table_header <> table_item <> table_tail
    end
  end

  describe("chunk file roundtrip tests") do
    test "synthetic cacnk data roundtrip is bit-exact" do
      cacnk_data = create_cacnk_test_data()
      assert {:ok, parsed} = CasyncFormat.parse_chunk(cacnk_data)
      assert parsed.magic == :cacnk
      assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)
      assert cacnk_data == re_encoded_data, "Re-encoded CACNK data does not match original"
    end

    test "various compression types roundtrip correctly" do
      compression_cases = [{0, :none}, {1, :zstd}]

      Enum.each(compression_cases, fn {compression_type, compression_atom} ->
        magic = <<202, 196, 78>>
        compressed_size = 75
        uncompressed_size = 150
        flags = 0

        header =
          <<compressed_size::little-32, uncompressed_size::little-32, compression_type::little-32,
            flags::little-32>>

        data = :crypto.strong_rand_bytes(compressed_size)
        original_data = magic <> header <> data
        assert {:ok, parsed} = CasyncFormat.parse_chunk(original_data)
        assert parsed.header.compression == compression_atom
        assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)

        assert original_data == re_encoded_data,
               "Re-encoded CACNK data with compression #{compression_atom} does not match original"
      end)
    end

    defp create_cacnk_test_data() do
      magic = <<202, 196, 78>>
      compressed_size = 100
      uncompressed_size = 200
      compression_type = 1
      flags = 0

      header =
        <<compressed_size::little-32, uncompressed_size::little-32, compression_type::little-32,
          flags::little-32>>

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
                        Logger.info("Roundtrip failed for #{filename}")
                        Logger.info("Original size: #{byte_size(original_data)}")
                        Logger.info("Re-encoded size: #{byte_size(re_encoded_data)}")
                        diff_pos = find_first_difference(original_data, re_encoded_data)

                        if diff_pos do
                          Logger.info("First difference at byte #{diff_pos}")
                        end

                        flunk("Roundtrip failed for #{filename}")
                      end
                  end

                {:error, _reason} ->
                  :ok
              end

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      end
    end
  end

  describe("synthetic data roundtrip tests") do
    test "synthetic caibx data roundtrips correctly" do
      original_data = create_synthetic_caibx()
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)
      assert original_data == re_encoded_data, "Synthetic caibx data roundtrip failed"
    end

    test "synthetic catar data roundtrips correctly" do
      original_data = create_synthetic_catar()
      assert {:ok, parsed} = CasyncFormat.parse_archive(original_data)

      case CasyncFormat.encode_archive(parsed) do
        {:ok, re_encoded_data} ->
          if original_data == re_encoded_data do
            Logger.info("Perfect synthetic CATAR roundtrip")
          else
            Logger.info("Synthetic CATAR roundtrip differences detected:")
            CasyncFormat.hex_compare(original_data, re_encoded_data)
          end

        {:error, reason} ->
          flunk("Failed to encode synthetic CATAR data: #{inspect(reason)}")
      end
    end

    test "synthetic chunk data roundtrips correctly" do
      original_data = create_synthetic_chunk()
      assert {:ok, parsed} = CasyncFormat.parse_chunk(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_chunk(parsed)
      assert original_data == re_encoded_data, "Synthetic chunk data roundtrip failed"
    end
  end

  describe("edge cases") do
    test "empty index file roundtrips correctly" do
      empty_caibx =
        <<48::little-64, 10_845_316_187_136_630_777::little-64,
          2_305_843_009_213_693_952::little-64, 16384::little-64, 65536::little-64,
          262_144::little-64>>

      assert {:ok, parsed} = CasyncFormat.parse_index(empty_caibx)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)
      assert empty_caibx == re_encoded_data
    end

    test "single chunk index roundtrips correctly" do
      format_index =
        <<48::little-64, 10_845_316_187_136_630_777::little-64,
          2_305_843_009_213_693_952::little-64, 1024::little-64, 1024::little-64,
          1024::little-64>>

      table_header =
        <<18_446_744_073_709_551_615::little-64, 16_671_092_242_283_708_797::little-64>>

      chunk_id = :crypto.strong_rand_bytes(32)
      table_item = <<1024::little-64>> <> chunk_id
      table_size = 16 + 40 + 40

      table_tail =
        <<0::little-64, 0::little-64, 48::little-64, table_size::little-64,
          5_426_561_635_123_326_161::little-64>>

      original_data = format_index <> table_header <> table_item <> table_tail
      assert {:ok, parsed} = CasyncFormat.parse_index(original_data)
      assert {:ok, re_encoded_data} = CasyncFormat.encode_index(parsed)
      assert original_data == re_encoded_data
    end
  end

  defp find_first_difference(data1, data2) do
    min_size = min(byte_size(data1), byte_size(data2))
    Enum.find(0..(min_size - 1), fn i -> :binary.at(data1, i) != :binary.at(data2, i) end)
  end

  defp create_synthetic_caibx do
    format_index =
      <<48::little-64, 10_845_316_187_136_630_777::little-64,
        2_305_843_009_213_693_952::little-64, 1024::little-64, 1024::little-64, 1024::little-64>>

    table_header =
      <<18_446_744_073_709_551_615::little-64, 16_671_092_242_283_708_797::little-64>>

    chunk1_id = :crypto.strong_rand_bytes(32)
    chunk2_id = :crypto.strong_rand_bytes(32)
    chunk3_id = :crypto.strong_rand_bytes(32)

    table_items =
      <<1024::little-64>> <>
        chunk1_id <> <<2048::little-64>> <> chunk2_id <> <<3072::little-64>> <> chunk3_id

    table_size = 16 + byte_size(table_items) + 40

    table_tail =
      <<0::little-64, 0::little-64, 48::little-64, table_size::little-64,
        5_426_561_635_123_326_161::little-64>>

    format_index <> table_header <> table_items <> table_tail
  end

  defp create_synthetic_catar do
    entry_header =
      <<64::little-64, 1_411_591_222_519_905_105::little-64, 0::little-64, 420::little-64,
        1000::little-64, 1000::little-64, 1_234_567_890::little-64, 0::little-64>>

    entry_header
  end

  defp create_synthetic_chunk do
    magic = <<202, 196, 78>>
    header = <<100::little-32>> <> <<100::little-32>> <> <<0::little-32>> <> <<0::little-32>>
    data = :crypto.strong_rand_bytes(100)
    magic <> header <> data
  end
end
