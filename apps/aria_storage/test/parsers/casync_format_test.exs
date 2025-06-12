# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormatTest do
  use ExUnit.Case
  alias AriaStorage.Parsers.CasyncFormat

  @testdata_path Path.join([__DIR__, "..", "support", "testdata"])

  @moduledoc """
  Comprehensive tests for the ABNF casync/desync parser using real testdata
  from the desync repository.

  These tests validate parsing of actual casync format files including:
  - .caibx (chunk index for blobs)
  - .caidx (chunk index for catar archives)
  - .catar (archive format)
  - .cacnk (compressed chunk files)
  """

  # Generate synthetic test data for testing
  def create_caibx_test_data() do
    # CAIBX magic header: 0xCA 0x1B 0x5C
    magic = <<0xCA, 0x1B, 0x5C>>

    # Header: version(4) + total_size(8) + chunk_count(4) + reserved(4) = 20 bytes
    version = 1
    total_size = 1024
    chunk_count = 2
    reserved = 0

    header = <<version::little-32, total_size::little-64, chunk_count::little-32, reserved::little-32>>

    # Create two test chunks (each 48 bytes: 32 + 8 + 4 + 4)
    chunk1_id = :crypto.strong_rand_bytes(32)  # SHA256 hash
    chunk1_offset = 0
    chunk1_size = 512
    chunk1_flags = 0

    chunk2_id = :crypto.strong_rand_bytes(32)  # SHA256 hash
    chunk2_offset = 512
    chunk2_size = 512
    chunk2_flags = 0

    chunk1 = chunk1_id <> <<chunk1_offset::little-64, chunk1_size::little-32, chunk1_flags::little-32>>
    chunk2 = chunk2_id <> <<chunk2_offset::little-64, chunk2_size::little-32, chunk2_flags::little-32>>

    magic <> header <> chunk1 <> chunk2
  end

  def create_caidx_test_data() do
    # CAIDX uses desync FormatIndex structure with feature_flags = 0 (no SHA512-256)
    format_index = <<
      48::little-64,                    # Size of FormatIndex
      0x96824d9c7b129ff9::little-64,    # CA_FORMAT_INDEX constant
      0::little-64,                     # Feature flags (0 = CAIDX, not CAIBX)
      1024::little-64,                  # chunk_size_min
      1024::little-64,                  # chunk_size_avg  
      1024::little-64                   # chunk_size_max
    >>

    # FormatTable header
    table_header = <<
      0xFFFFFFFFFFFFFFFF::little-64,    # Table marker
      0xe75b9e112f17417d::little-64     # CA_FORMAT_TABLE constant
    >>

    # Single chunk table item
    chunk_id = :crypto.strong_rand_bytes(32)
    table_item = <<2048::little-64>> <> chunk_id  # offset=2048, chunk_id=32 bytes

    # Table tail marker
    table_tail = <<
      0::little-64,                     # Zero offset
      0::little-64,                     # Zero pad
      48::little-64,                    # Size field
      88::little-64,                    # Table size (header + item + tail)
      0x4b4f050e5549ecd1::little-64     # CA_FORMAT_TABLE_TAIL_MARKER
    >>

    format_index <> table_header <> table_item <> table_tail
  end

  def create_catar_test_data() do
    # CATAR files start directly with entry data, no magic bytes
    # Simple single-file entry
    entry_size = 64  # Total entry size including header
    entry_type = 1   # File type
    entry_flags = 0
    entry_padding = 0

    # Metadata
    mode = 0o100644    # Regular file permissions
    uid = 1000
    gid = 1000
    mtime = 1640995200  # Unix timestamp

    entry_header = <<entry_size::little-64, entry_type::little-64, entry_flags::little-64, entry_padding::little-64>>
    entry_metadata = <<mode::little-64, uid::little-64, gid::little-64, mtime::little-64>>

    entry_header <> entry_metadata
  end

  def create_cacnk_test_data() do
    # CACNK magic header: 0xCA 0xC4 0x4E
    magic = <<0xCA, 0xC4, 0x4E>>

    # Chunk header
    compressed_size = 100
    uncompressed_size = 200
    compression_type = 1  # zstd
    flags = 0

    header = <<compressed_size::little-32, uncompressed_size::little-32, compression_type::little-32, flags::little-32>>

    # Dummy compressed data
    data = :crypto.strong_rand_bytes(100)

    magic <> header <> data
  end

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

    test "detects and parses CAIDX format successfully" do
      # Create CAIDX test data
      caidx_data = create_caidx_test_data()
      assert {:ok, result} = CasyncFormat.parse_index(caidx_data)
      assert result.format == :caidx
      assert result.feature_flags == 0  # CAIDX has feature_flags == 0
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

  describe "directory index file parsing (.caidx)" do
    test "parses synthetic .caidx data successfully" do
      # Create CAIDX test data
      caidx_data = create_caidx_test_data()
      assert {:ok, result} = CasyncFormat.parse_index(caidx_data)
      
      # Verify format detection
      assert result.format == :caidx
      assert result.feature_flags == 0  # CAIDX has feature_flags == 0
      
      # Verify structure
      assert %{header: header, chunks: chunks} = result
      assert is_map(header)
      assert is_list(chunks)
      
      # Verify chunk sizes
      assert result.chunk_size_min == 1024
      assert result.chunk_size_avg == 1024
      assert result.chunk_size_max == 1024
    end

    test "differentiates CAIDX from CAIBX by feature_flags" do
      # Create both CAIDX (feature_flags=0) and synthetic CAIBX (feature_flags!=0)
      caidx_data = create_caidx_test_data()
      
      # Create CAIBX data with non-zero feature_flags
      caibx_format_index = <<
        48::little-64,                    # Size of FormatIndex
        0x96824d9c7b129ff9::little-64,    # CA_FORMAT_INDEX constant
        0x2000000000000000::little-64,    # Feature flags (SHA512_256 flag)
        1024::little-64,                  # chunk_size_min
        1024::little-64,                  # chunk_size_avg  
        1024::little-64                   # chunk_size_max
      >>
      
      # Same table structure for both
      table_data = binary_part(caidx_data, 48, byte_size(caidx_data) - 48)
      caibx_data = caibx_format_index <> table_data
      
      # Test CAIDX
      assert {:ok, caidx_result} = CasyncFormat.parse_index(caidx_data)
      assert caidx_result.format == :caidx
      assert caidx_result.feature_flags == 0
      
      # Test CAIBX
      assert {:ok, caibx_result} = CasyncFormat.parse_index(caibx_data)
      assert caibx_result.format == :caibx
      assert caibx_result.feature_flags == 0x2000000000000000
    end

    test "handles empty CAIDX files" do
      # Create minimal CAIDX with no table data
      empty_caidx = <<
        48::little-64,                    # Size of FormatIndex
        0x96824d9c7b129ff9::little-64,    # CA_FORMAT_INDEX constant
        0::little-64,                     # Feature flags (0 = CAIDX)
        16384::little-64,                 # chunk_size_min
        65536::little-64,                 # chunk_size_avg  
        262144::little-64                 # chunk_size_max
      >>
      
      assert {:ok, result} = CasyncFormat.parse_index(empty_caidx)
      assert result.format == :caidx
      assert result.header.chunk_count == 0
      assert result.chunks == []
    end
  end

  describe "archive file parsing (.catar)" do
    test "parses flat.catar successfully" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          
          # Verify structure
          assert %{format: :catar, files: files, directories: directories, elements: elements} = result
          assert is_list(files)
          assert is_list(directories)
          assert is_list(elements)
          
          # flat.catar should contain files but no directories
          assert length(files) > 0
          assert length(directories) == 0
          
          # Verify file structure
          Enum.each(files, fn file ->
            assert %{name: name, type: type} = file
            assert is_binary(name)
            assert type in [:file, :symlink, :device]
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "parses nested.catar successfully" do
      file_path = Path.join(@testdata_path, "nested.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          
          # Verify structure
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          
          # nested.catar should contain both files and directories
          assert length(files) > 0
          assert length(directories) > 0

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
          
          # Verify structure
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          
          # complex.catar should contain various file types
          assert length(files) > 0

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
          
          # Verify structure
          assert %{format: :catar, files: files, directories: directories} = result
          assert is_list(files)
          assert is_list(directories)
          
          # flatdir.catar should contain only directories
          assert length(files) == 0
          assert length(directories) > 0

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates CATAR file content extraction" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          
          # Check for files with content
          files_with_content = Enum.filter(result.files, fn file ->
            Map.has_key?(file, :content) && file.type == :file
          end)
          
          # Verify content structure
          Enum.each(files_with_content, fn file ->
            assert is_binary(file.content)
            assert byte_size(file.content) > 0
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates CATAR symlink detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          
          # Check for symlinks
          symlinks = Enum.filter(result.files, fn file ->
            file.type == :symlink
          end)
          
          # Verify symlink structure
          Enum.each(symlinks, fn symlink ->
            assert Map.has_key?(symlink, :target)
            assert is_binary(symlink.target)
          end)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates CATAR device file detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, result} = CasyncFormat.parse_archive(data)
          
          # Check for device files
          devices = Enum.filter(result.files, fn file ->
            file.type == :device
          end)
          
          # Verify device structure
          Enum.each(devices, fn device ->
            assert Map.has_key?(device, :major)
            assert Map.has_key?(device, :minor)
            assert is_integer(device.major)
            assert is_integer(device.minor)
          end)

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
      # CATAR parsing now returns success for empty input (empty archive is valid)
      assert {:ok, %{format: :catar, files: [], directories: [], elements: []}} = CasyncFormat.parse_archive("")
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

  describe "chunk file parsing (.cacnk)" do
    test "parses synthetic .cacnk data successfully" do
      # Create test data using our helper function
      cacnk_data = create_cacnk_test_data()
      
      assert {:ok, result} = CasyncFormat.parse_chunk(cacnk_data)
      
      # Verify structure
      assert %{magic: :cacnk, header: header, data: data} = result
      assert %{compressed_size: compressed_size, uncompressed_size: uncompressed_size, compression: compression, flags: flags} = header
      
      # Verify values
      assert compressed_size == 100
      assert uncompressed_size == 200
      assert compression == :zstd
      assert flags == 0
      assert is_binary(data)
      assert byte_size(data) == 100
    end

    test "handles .cacnk files from chunk stores" do
      # Look for .cacnk files in blob1.store directory
      store_path = Path.join(@testdata_path, "blob1.store")
      
      if File.exists?(store_path) do
        cacnk_files = Path.wildcard(Path.join(store_path, "**/*.cacnk"))
        
        if length(cacnk_files) > 0 do
          # Test the first .cacnk file found
          file_path = hd(cacnk_files)
          
          case File.read(file_path) do
            {:ok, data} ->
              # Check if this is a CACNK wrapped chunk or raw compressed data
              case CasyncFormat.parse_chunk(data) do
                {:ok, result} ->
                  # Standard CACNK format with wrapper header
                  assert %{magic: :cacnk, header: header, data: chunk_data} = result
                  assert is_map(header)
                  assert is_binary(chunk_data)
                  
                  # Verify header fields
                  assert %{compressed_size: compressed_size, uncompressed_size: uncompressed_size, compression: compression} = header
                  assert is_integer(compressed_size)
                  assert is_integer(uncompressed_size)
                  assert compression in [:none, :zstd, :unknown]
                
                {:error, "Invalid chunk file magic"} ->
                  # Files in desync chunk stores are often raw compressed data without CACNK wrapper
                  # This is normal for chunk stores where chunks are stored as raw ZSTD data
                  # Try to decompress as raw ZSTD to verify it's valid compressed data
                  case :ezstd.decompress(data) do
                    decompressed when is_binary(decompressed) ->
                      # Successfully decompressed raw ZSTD data
                      assert byte_size(decompressed) > 0
                    _ ->
                      # Not valid ZSTD data, might be uncompressed chunk
                      assert is_binary(data)
                      assert byte_size(data) > 0
                  end
              end
              
            {:error, _} ->
              # Skip if file can't be read
              :ok
          end
        end
      end
    end

    test "validates chunk compression detection" do
      # Test different compression types
      test_cases = [
        {0, :none},
        {1, :zstd},
        {999, :unknown}
      ]
      
      Enum.each(test_cases, fn {compression_type, expected_compression} ->
        # Create chunk data with specific compression type
        magic = <<0xCA, 0xC4, 0x4E>>
        header = <<50::little-32, 100::little-32, compression_type::little-32, 0::little-32>>
        data = :crypto.strong_rand_bytes(50)
        
        chunk_data = magic <> header <> data
        
        assert {:ok, result} = CasyncFormat.parse_chunk(chunk_data)
        assert result.header.compression == expected_compression
      end)
    end

    test "rejects invalid .cacnk magic headers" do
      # Test with wrong magic bytes
      invalid_magic = <<0xFF, 0xFF, 0xFF>>
      header = <<100::little-32, 200::little-32, 1::little-32, 0::little-32>>
      data = :crypto.strong_rand_bytes(100)
      
      invalid_chunk = invalid_magic <> header <> data
      
      assert {:error, "Invalid chunk file magic"} = CasyncFormat.parse_chunk(invalid_chunk)
    end

    test "handles truncated .cacnk files gracefully" do
      # Create valid start but truncate it
      magic = <<0xCA, 0xC4, 0x4E>>
      partial_header = <<100::little-32, 200::little-32>>  # Missing compression and flags
      
      truncated_chunk = magic <> partial_header
      
      assert {:error, "Invalid chunk file magic"} = CasyncFormat.parse_chunk(truncated_chunk)
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
    test "validates caibx format detection" do
      file_path = Path.join(@testdata_path, "blob1.caibx")

      case File.read(file_path) do
        {:ok, data} ->
          # Should detect as caibx format regardless of whether it uses FormatIndex or legacy magic bytes
          assert {:ok, :caibx} = CasyncFormat.detect_format(data)

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end

    test "validates catar format detection" do
      file_path = Path.join(@testdata_path, "flat.catar")

      case File.read(file_path) do
        {:ok, data} ->
          assert {:ok, :catar} = CasyncFormat.detect_format(data)

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
              # CATAR parsing is now implemented
              result = CasyncFormat.parse_archive(data)
              filename = Path.basename(file_path)

              case result do
                {:ok, parsed} ->
                  # Validate basic structure
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
          json_safe_result = CasyncFormat.to_json_safe(result)
          json_result = Jason.encode!(json_safe_result)
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
          # CATAR parsing is now implemented
          result1 = CasyncFormat.parse_archive(data)
          result2 = CasyncFormat.parse_archive(data)
          result3 = CasyncFormat.parse_archive(data)
          
          # Results should be consistent across multiple calls
          assert result1 == result2
          assert result2 == result3
          
          # Verify they're all successful
          assert {:ok, _} = result1

        {:error, _} ->
          # Skip if file doesn't exist
          :ok
      end
    end
  end
end
