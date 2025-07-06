# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormatTest do
  use ExUnit.Case
  alias AriaStorage.Parsers.CasyncFormat
  @testdata_path Path.join([__DIR__, "..", "support", "testdata"])
  @moduledoc "Comprehensive tests for the ABNF casync/desync parser using real testdata\nfrom the desync repository.\n\nThese tests validate parsing of actual casync format files including:\n- .caibx (chunk index for blobs)\n- .caidx (chunk index for catar archives)\n- .catar (archive format)\n- .cacnk (compressed chunk files)\n"
  def create_caibx_test_data() do
    magic = <<202, 27, 92>>
    version = 1
    total_size = 1024
    chunk_count = 2
    reserved = 0

    header =
      <<version::little-32, total_size::little-64, chunk_count::little-32, reserved::little-32>>

    chunk1_id = :crypto.strong_rand_bytes(32)
    chunk1_offset = 0
    chunk1_size = 512
    chunk1_flags = 0
    chunk2_id = :crypto.strong_rand_bytes(32)
    chunk2_offset = 512
    chunk2_size = 512
    chunk2_flags = 0

    chunk1 =
      chunk1_id <> <<chunk1_offset::little-64, chunk1_size::little-32, chunk1_flags::little-32>>

    chunk2 =
      chunk2_id <> <<chunk2_offset::little-64, chunk2_size::little-32, chunk2_flags::little-32>>

    magic <> header <> chunk1 <> chunk2
  end

  def create_caidx_test_data() do
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

  def create_catar_test_data() do
    entry_size = 64
    entry_type = 1
    entry_flags = 0
    entry_padding = 0
    mode = 33188
    uid = 1000
    gid = 1000
    mtime = 1_640_995_200

    entry_header =
      <<entry_size::little-64, entry_type::little-64, entry_flags::little-64,
        entry_padding::little-64>>

    entry_metadata = <<mode::little-64, uid::little-64, gid::little-64, mtime::little-64>>
    entry_header <> entry_metadata
  end

  def create_cacnk_test_data() do
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

  describe("format detection") do
    test "detects .caibx files correctly" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} -> assert {:ok, :caibx} = CasyncFormat.detect_format(data)
        {:error, _} -> :ok
      end
    end

    test "detects .catar files correctly" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} -> assert {:ok, :catar} = CasyncFormat.detect_format(data)
        {:error, _} -> :ok
      end
    end

    test "detects and parses CAIDX format successfully" do
      caidx_data = create_caidx_test_data()
      assert {:ok, result} = CasyncFormat.parse_index(caidx_data)
      assert result.format == :caidx
      assert result.feature_flags == 0
    end

    test "rejects unknown formats" do
      assert {:error, :unknown_format} = CasyncFormat.detect_format("invalid")
      assert {:error, :unknown_format} = CasyncFormat.detect_format(<<1, 2, 3, 4>>)
    end
  end

  describe("index file parsing (.caibx)") do
    test "parses blob1.caibx successfully" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)
          assert %{format: format, header: header, chunks: chunks} = result
          assert format == :caibx
          assert %{version: version, total_size: total_size, chunk_count: chunk_count} = header
          assert is_integer(version)
          assert is_integer(total_size)
          assert is_integer(chunk_count)
          assert total_size > 0
          assert chunk_count > 0
          assert is_list(chunks)
          assert length(chunks) == chunk_count

          if length(chunks) > 0 do
            first_chunk = hd(chunks)
            assert %{chunk_id: chunk_id, offset: offset, size: size, flags: flags} = first_chunk
            assert is_binary(chunk_id)
            assert byte_size(chunk_id) == 32
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
          :ok
      end
    end

    test "handles corrupted index files gracefully" do
      file_path = Path.join(@testdata_path, "blob2_corrupted.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          case CasyncFormat.parse_index(data) do
            {:ok, _result} -> :ok
            {:error, _reason} -> :ok
          end

        {:error, _} ->
          :ok
      end
    end
  end

  describe("directory index file parsing (.caidx)") do
    test "parses synthetic .caidx data successfully" do
      caidx_data = create_caidx_test_data()
      assert {:ok, result} = CasyncFormat.parse_index(caidx_data)
      assert result.format == :caidx
      assert result.feature_flags == 0
      assert %{header: header, chunks: chunks} = result
      assert is_map(header)
      assert is_list(chunks)
      assert result.chunk_size_min == 1024
      assert result.chunk_size_avg == 1024
      assert result.chunk_size_max == 1024
    end

    test "differentiates CAIDX from CAIBX by feature_flags" do
      caidx_data = create_caidx_test_data()

      caibx_format_index =
        <<48::little-64, 10_845_316_187_136_630_777::little-64,
          2_305_843_009_213_693_952::little-64, 1024::little-64, 1024::little-64,
          1024::little-64>>

      table_data = binary_part(caidx_data, 48, byte_size(caidx_data) - 48)
      caibx_data = caibx_format_index <> table_data
      assert {:ok, caidx_result} = CasyncFormat.parse_index(caidx_data)
      assert caidx_result.format == :caidx
      assert caidx_result.feature_flags == 0
      assert {:ok, caibx_result} = CasyncFormat.parse_index(caibx_data)
      assert caibx_result.format == :caibx
      assert caibx_result.feature_flags == 2_305_843_009_213_693_952
    end

    test "handles empty CAIDX files" do
      empty_caidx =
        <<48::little-64, 10_845_316_187_136_630_777::little-64, 0::little-64, 16384::little-64,
          65536::little-64, 262_144::little-64>>

      assert {:ok, result} = CasyncFormat.parse_index(empty_caidx)
      assert result.format == :caidx
      assert result.header.chunk_count == 0
      assert result.chunks == []
    end
  end

  describe("archive file parsing (.catar)") do
    test "parses flat.catar successfully" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          assert %{format: :catar, files: files, directories: directories, elements: elements} =
                   result

          assert is_list(files)
          assert is_list(directories)
          assert is_list(elements)
          assert length(files) > 0
          assert length(directories) == 0

          Enum.each(files, fn file ->
            assert %{name: name, type: type} = file
            assert is_binary(name)
            assert type in [:file, :symlink, :device]
          end)

        {:error, _} ->
          :ok
      end
    end

    test "parses nested.catar successfully" do
      file_path = Path.join(@testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          assert length(files) > 0
          assert length(directories) > 0

        {:error, _} ->
          :ok
      end
    end

    test "parses complex.catar successfully" do
      file_path = Path.join(@testdata_path, "complex.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          assert length(files) > 0

        {:error, _} ->
          :ok
      end
    end

    test "parses flatdir.catar successfully" do
      file_path = Path.join(@testdata_path, "flatdir.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          assert length(files) == 0
          assert length(directories) > 0

        {:error, _} ->
          :ok
      end
    end

    test "validates CATAR file content extraction" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)

          files_with_content =
            Enum.filter(result.files, fn file ->
              Map.has_key?(file, :content) && file.type == :file
            end)

          Enum.each(files_with_content, fn file ->
            assert is_binary(file.content)
            assert byte_size(file.content) > 0
          end)

        {:error, _} ->
          :ok
      end
    end

    test "validates CATAR symlink detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          symlinks = Enum.filter(result.files, fn file -> file.type == :symlink end)

          Enum.each(symlinks, fn symlink ->
            assert Map.has_key?(symlink, :target)
            assert is_binary(symlink.target)
          end)

        {:error, _} ->
          :ok
      end
    end

    test "validates CATAR device file detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          devices = Enum.filter(result.files, fn file -> file.type == :device end)

          Enum.each(devices, fn device ->
            assert Map.has_key?(device, :major)
            assert Map.has_key?(device, :minor)
            assert is_integer(device.major)
            assert is_integer(device.minor)
          end)

        {:error, _} ->
          :ok
      end
    end

    test "roundtrips CATAR with 16-bit UIDs/GIDs" do
      feature_flags = 1
      mode = 493
      uid = 1000
      gid = 1000
      mtime = 1_678_886_400

      element = %{
        type: :entry,
        size: 52,
        feature_flags: feature_flags,
        mode: mode,
        uid: uid,
        gid: gid,
        mtime: mtime
      }

      archive = %{format: :catar, elements: [element], files: [], directories: []}
      {:ok, encoded_data} = CasyncFormat.encode_archive(archive)
      {:ok, parsed} = CasyncFormat.parse_archive(encoded_data)
      assert parsed.format == :catar
      assert length(parsed.elements) == 1
      assert parsed.elements |> hd |> Map.get(:uid) == uid
      assert parsed.elements |> hd |> Map.get(:gid) == gid
      assert parsed.elements |> hd |> Map.get(:feature_flags) == feature_flags
    end

    test "roundtrips CATAR with 32-bit UIDs/GIDs" do
      feature_flags = 2
      mode = 493
      uid = 1000
      gid = 1000
      mtime = 1_678_886_400

      element = %{
        type: :entry,
        size: 56,
        feature_flags: feature_flags,
        mode: mode,
        uid: uid,
        gid: gid,
        mtime: mtime
      }

      archive = %{format: :catar, elements: [element], files: [], directories: []}
      {:ok, encoded_data} = CasyncFormat.encode_archive(archive)
      {:ok, parsed} = CasyncFormat.parse_archive(encoded_data)
      assert parsed.format == :catar
      assert length(parsed.elements) == 1
      assert parsed.elements |> hd |> Map.get(:uid) == uid
      assert parsed.elements |> hd |> Map.get(:gid) == gid
      assert parsed.elements |> hd |> Map.get(:feature_flags) == feature_flags
    end
  end

  describe("round-trip consistency") do
    test "parsed data maintains consistency across multiple parses" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result1} = CasyncFormat.parse_index(data)
          assert {:ok, result2} = CasyncFormat.parse_index(data)
          assert {:ok, result3} = CasyncFormat.parse_index(data)
          assert result1 == result2
          assert result2 == result3

        {:error, _} ->
          :ok
      end
    end
  end

  describe("chunk validation") do
    test "validates chunk ID structure" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)
          %{chunks: chunks} = result

          Enum.each(chunks, fn chunk ->
            %{chunk_id: chunk_id} = chunk
            assert byte_size(chunk_id) == 32
            assert is_binary(chunk_id)
            hex_id = Base.encode16(chunk_id, case: :lower)
            assert String.length(hex_id) == 64
            assert String.match?(hex_id, ~r/^[0-9a-f]+$/)
          end)

        {:error, _} ->
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
            offsets = Enum.map(chunks, & &1.offset)
            sorted_offsets = Enum.sort(offsets)
            assert offsets == sorted_offsets
          end

        {:error, _} ->
          :ok
      end
    end
  end

  describe("edge cases and error handling") do
    test "handles empty input gracefully" do
      assert {:error, _} = CasyncFormat.parse_index("")

      assert {:ok, %{format: :catar, files: [], directories: [], elements: []}} =
               CasyncFormat.parse_archive("")

      assert {:error, _} = CasyncFormat.parse_chunk("")
    end

    test "handles truncated files gracefully" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} when byte_size(data) > 10 ->
          truncated_data = binary_part(data, 0, 10)
          assert {:error, _} = CasyncFormat.parse_index(truncated_data)

        {:error, _} ->
          :ok
      end
    end

    test "handles invalid magic headers" do
      invalid_data = <<255, 255, 255>> <> String.duplicate(<<0>>, 100)
      assert {:error, _} = CasyncFormat.parse_index(invalid_data)
      assert {:error, _} = CasyncFormat.parse_archive(invalid_data)
    end
  end

  describe("chunk file parsing (.cacnk)") do
    test "parses synthetic .cacnk data successfully" do
      cacnk_data = create_cacnk_test_data()
      assert {:ok, result} = CasyncFormat.parse_chunk(cacnk_data)
      assert %{magic: :cacnk, header: header, data: data} = result

      assert %{
               compressed_size: compressed_size,
               uncompressed_size: uncompressed_size,
               compression: compression,
               flags: flags
             } = header

      assert compressed_size == 100
      assert uncompressed_size == 200
      assert compression == :zstd
      assert flags == 0
      assert is_binary(data)
      assert byte_size(data) == 100
    end

    test "handles .cacnk files from chunk stores" do
      store_path = Path.join(@testdata_path, "blob1.store")

      if File.exists?(store_path) do
        cacnk_files = Path.wildcard(Path.join(store_path, "**/*.cacnk"))

        if length(cacnk_files) > 0 do
          file_path = hd(cacnk_files)

          case File.read(file_path) do
            {:ok, data} ->
              case CasyncFormat.parse_chunk(data) do
                {:ok, result} ->
                  assert %{magic: :cacnk, header: header, data: chunk_data} = result
                  assert is_map(header)
                  assert is_binary(chunk_data)

                  assert %{
                           compressed_size: compressed_size,
                           uncompressed_size: uncompressed_size,
                           compression: compression
                         } = header

                  assert is_integer(compressed_size)
                  assert is_integer(uncompressed_size)
                  assert compression in [:none, :zstd, :unknown]

                {:error, "Invalid chunk file magic"} ->
                  case :ezstd.decompress(data) do
                    decompressed when is_binary(decompressed) ->
                      assert byte_size(decompressed) > 0

                    _ ->
                      assert is_binary(data)
                      assert byte_size(data) > 0
                  end
              end

            {:error, _} ->
              :ok
          end
        end
      end
    end

    test "validates chunk compression detection" do
      test_cases = [{0, :none}, {1, :zstd}, {999, :unknown}]

      Enum.each(test_cases, fn {compression_type, expected_compression} ->
        magic = <<202, 196, 78>>
        header = <<50::little-32, 100::little-32, compression_type::little-32, 0::little-32>>
        data = :crypto.strong_rand_bytes(50)
        chunk_data = magic <> header <> data
        assert {:ok, result} = CasyncFormat.parse_chunk(chunk_data)
        assert result.header.compression == expected_compression
      end)
    end

    test "rejects invalid .cacnk magic headers" do
      invalid_magic = <<255, 255, 255>>
      header = <<100::little-32, 200::little-32, 1::little-32, 0::little-32>>
      data = :crypto.strong_rand_bytes(100)
      invalid_chunk = invalid_magic <> header <> data
      assert {:error, "Invalid chunk file magic"} = CasyncFormat.parse_chunk(invalid_chunk)
    end

    test "handles truncated .cacnk files gracefully" do
      magic = <<202, 196, 78>>
      partial_header = <<100::little-32, 200::little-32>>
      truncated_chunk = magic <> partial_header
      assert {:error, "Invalid chunk file magic"} = CasyncFormat.parse_chunk(truncated_chunk)
    end
  end

  describe("performance benchmarking") do
    test "parses large index files efficiently" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          {time_micro, {:ok, _result}} = :timer.tc(fn -> CasyncFormat.parse_index(data) end)
          assert time_micro < 100_000

        {:error, _} ->
          :ok
      end
    end
  end

  describe("specific format validation") do
    test "validates caibx format detection" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} -> assert {:ok, :caibx} = CasyncFormat.detect_format(data)
        {:error, _} -> :ok
      end
    end

    test "validates catar format detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} -> assert {:ok, :catar} = CasyncFormat.detect_format(data)
        {:error, _} -> :ok
      end
    end
  end

  describe("integration with testdata") do
    setup do
      if File.exists?(@testdata_path) do
        {:ok, testdata_available: true}
      else
        {:ok, testdata_available: false}
      end
    end

    test("processes all available caibx files", %{testdata_available: available}) do
      if available do
        caibx_files = Path.wildcard(Path.join(@testdata_path, "*.caibx"))

        Enum.each(caibx_files, fn file_path ->
          case File.read(file_path) do
            {:ok, data} ->
              result = CasyncFormat.parse_index(data)
              filename = Path.basename(file_path)

              case result do
                {:ok, parsed} ->
                  assert %{format: :caibx, header: header, chunks: chunks} = parsed
                  assert is_map(header)
                  assert is_list(chunks)

                {:error, reason} ->
                  if String.contains?(filename, "corrupted") do
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
        :ok
      end
    end

    test("processes all available catar files", %{testdata_available: available}) do
      if available do
        catar_files = Path.wildcard(Path.join(@testdata_path, "*.catar"))

        Enum.each(catar_files, fn file_path ->
          case File.read(file_path) do
            {:ok, data} ->
              result = CasyncFormat.parse_archive(data)
              filename = Path.basename(file_path)

              case result do
                {:ok, parsed} ->
                  assert %{format: :catar, files: files, directories: directories} = parsed
                  assert is_list(files)
                  assert is_list(directories)

                {:error, reason} ->
                  flunk("Failed to parse #{filename}: #{inspect(reason)}")
              end

            {:error, reason} ->
              flunk("Failed to read #{file_path}: #{inspect(reason)}")
          end
        end)
      else
        :ok
      end
    end
  end

  describe("parser output validation") do
    test "produces valid output structure for index files" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_index(data)
          json_safe_result = CasyncFormat.to_json_safe(result)
          json_result = Jason.encode!(json_safe_result)
          assert is_binary(json_result)
          decoded = Jason.decode!(json_result)
          assert is_map(decoded)

        {:error, _} ->
          :ok
      end
    end

    test "produces deterministic output" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          result1 = CasyncFormat.parse_archive(data)
          result2 = CasyncFormat.parse_archive(data)
          result3 = CasyncFormat.parse_archive(data)
          assert result1 == result2
          assert result2 == result3
          assert {:ok, _} = result1

        {:error, _} ->
          :ok
      end
    end
  end
end
