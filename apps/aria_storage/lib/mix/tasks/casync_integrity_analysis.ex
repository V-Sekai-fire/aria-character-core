defmodule Mix.Tasks.CasyncIntegrity do
  @moduledoc """
  Comprehensive analysis tool for casync file integrity and hash storage patterns.

  Investigates:
  1. Where the total file size/hash is stored in caibx files
  2. Dual hash system: rolling hash boundaries vs content verification hashes
  3. File assembly integrity checking
  4. Range offset patterns and content verification

  Usage:
      mix casync_integrity apps/aria_storage/test/support/testdata/blob1.caibx
  """

  use Mix.Task

  import Bitwise
  
  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.CasyncDecoder

  @ca_format_sha512_256 0x2000000000000000

  def run([file_path]) do
    IO.puts("🔍 CASYNC INTEGRITY ANALYSIS")
    IO.puts("=" <> String.duplicate("=", 50))

    case File.read(file_path) do
      {:ok, binary_data} ->
        # 1. Analyze file structure
        analyze_file_structure(binary_data, file_path)
        
        # 2. Parse and examine metadata
        case CasyncFormat.parse_index(binary_data) do
          {:ok, parsed_data} ->
            analyze_parsed_structure(parsed_data)
            
            # 3. Investigate chunk boundary patterns
            analyze_chunk_patterns(parsed_data)
            
            # 4. Look for content hash storage
            search_for_content_hashes(parsed_data, binary_data)
            
            # 5. Test file assembly integrity
            if store_path = find_store_path(file_path) do
              test_assembly_integrity(parsed_data, store_path)
            else
              IO.puts("\n⚠️  No corresponding store found for assembly testing")
            end
            
          {:error, reason} ->
            IO.puts("❌ Failed to parse: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to read file: #{inspect(reason)}")
    end
  end

  def run([]) do
    IO.puts(@moduledoc)
  end

  defp analyze_file_structure(binary_data, file_path) do
    IO.puts("\n📁 FILE STRUCTURE ANALYSIS")
    IO.puts("-" <> String.duplicate("-", 30))
    
    file_size = byte_size(binary_data)
    IO.puts("File: #{Path.basename(file_path)}")
    IO.puts("Size: #{format_bytes(file_size)}")
    
    # Look for format headers
    case binary_data do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        rest::binary>> ->
        
        IO.puts("\n🏗️  FormatIndex Header (48 bytes):")
        IO.puts("  Size Field: #{size_field}")
        IO.puts("  Type Field: 0x#{Integer.to_string(type_field, 16)}")
        IO.puts("  Feature Flags: 0x#{Integer.to_string(feature_flags, 16)}")
        
        format_name = if feature_flags == 0, do: "CAIDX", else: "CAIBX"
        hash_algo = if (feature_flags &&& @ca_format_sha512_256) != 0, do: "SHA512/256", else: "SHA256"
        
        IO.puts("  Format: #{format_name} (#{hash_algo})")
        IO.puts("  Min Chunk Size: #{format_bytes(chunk_size_min)}")
        IO.puts("  Avg Chunk Size: #{format_bytes(chunk_size_avg)}")
        IO.puts("  Max Chunk Size: #{format_bytes(chunk_size_max)}")
        
        # Analyze remaining data for FormatTable
        analyze_format_table(rest)
        
      _ ->
        IO.puts("⚠️  Unrecognized file format")
    end
  end

  defp analyze_format_table(binary_data) do
    case binary_data do
      <<0xFFFFFFFFFFFFFFFF::little-64, table_type::little-64, table_data::binary>> ->
        IO.puts("\n📊 FormatTable Header (16 bytes):")
        IO.puts("  Table Marker: 0xFFFFFFFFFFFFFFFF")
        IO.puts("  Table Type: 0x#{Integer.to_string(table_type, 16)}")
        
        analyze_table_items(table_data, 0)
        
      _ ->
        IO.puts("\n⚠️  No FormatTable found (empty index)")
    end
  end

  defp analyze_table_items(binary_data, item_count) do
    case binary_data do
      # Table tail marker (40 bytes)
      <<0::little-64, 0::little-64, 48::little-64, table_size::little-64,
        tail_marker::little-64, _rest::binary>> ->
        IO.puts("\n🔚 Table Tail Marker (40 bytes):")
        IO.puts("  Zero Fields: 0, 0")
        IO.puts("  Size Field: 48")
        IO.puts("  Table Size: #{table_size}")
        IO.puts("  Tail Marker: 0x#{Integer.to_string(tail_marker, 16)}")
        IO.puts("  Total Items: #{item_count}")
        
      # Table item (40 bytes: 8-byte offset + 32-byte chunk_id)
      <<offset::little-64, chunk_id::binary-size(32), rest::binary>> ->
        if item_count < 5 do  # Show first 5 items only
          chunk_id_hex = Base.encode16(chunk_id, case: :lower)
          IO.puts("  Item #{item_count + 1}: offset=#{offset}, chunk_id=#{String.slice(chunk_id_hex, 0, 16)}...")
        end
        analyze_table_items(rest, item_count + 1)
        
      _ ->
        IO.puts("⚠️  Incomplete table data")
    end
  end

  defp analyze_parsed_structure(parsed_data) do
    IO.puts("\n🧱 PARSED STRUCTURE ANALYSIS")
    IO.puts("-" <> String.duplicate("-", 30))
    
    IO.puts("Format: #{parsed_data.format}")
    IO.puts("Feature Flags: 0x#{Integer.to_string(parsed_data.feature_flags, 16)}")
    IO.puts("Chunk Count: #{length(parsed_data.chunks)}")
    
    # Calculate total size from chunks
    calculated_total = if length(parsed_data.chunks) > 0 do
      List.last(parsed_data.chunks).offset
    else
      0
    end
    
    IO.puts("Header Total Size: #{format_bytes(parsed_data.header.total_size)}")
    IO.puts("Calculated Total: #{format_bytes(calculated_total)}")
    
    if parsed_data.header.total_size == calculated_total do
      IO.puts("✅ Size consistency: PASSED")
    else
      IO.puts("❌ Size consistency: FAILED")
    end
  end

  defp analyze_chunk_patterns(parsed_data) do
    IO.puts("\n🧩 CHUNK PATTERN ANALYSIS")
    IO.puts("-" <> String.duplicate("-", 30))
    
    if length(parsed_data.chunks) == 0 do
      IO.puts("No chunks to analyze")
    else
    
    # Analyze chunk ID patterns
    chunk_ids = Enum.map(parsed_data.chunks, & &1.chunk_id)
    
    IO.puts("Total Chunks: #{length(chunk_ids)}")
    IO.puts("Chunk ID Size: #{byte_size(List.first(chunk_ids))} bytes")
    
    # Check for patterns in chunk IDs
    IO.puts("\n🔍 Chunk ID Distribution Analysis:")
    
    # Sample first few bytes of each chunk ID to look for patterns
    first_bytes = Enum.map(chunk_ids, fn chunk_id ->
      :binary.at(chunk_id, 0)
    end)
    
    first_byte_counts = Enum.frequencies(first_bytes)
    unique_first_bytes = map_size(first_byte_counts)
    
    IO.puts("  Unique first bytes: #{unique_first_bytes}/#{length(chunk_ids)}")
    
    if unique_first_bytes < length(chunk_ids) / 2 do
      IO.puts("  ⚠️  Low entropy in first bytes (may indicate rolling hash pattern)")
    else
      IO.puts("  ✅ Good entropy in first bytes")
    end
    
    # Show sample chunk details
    IO.puts("\n📋 Sample Chunks:")
    parsed_data.chunks
    |> Enum.take(5)
    |> Enum.with_index()
    |> Enum.each(fn {chunk, index} ->
      chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
      prev_offset = if index == 0, do: 0, else: Enum.at(parsed_data.chunks, index - 1).offset
      size = chunk.offset - prev_offset
      IO.puts("  #{index + 1}: offset=#{chunk.offset}, size=#{size}, id=#{String.slice(chunk_id_hex, 0, 16)}...")
    end)
    end
  end

  defp search_for_content_hashes(parsed_data, binary_data) do
    IO.puts("\n🔐 CONTENT HASH SEARCH")
    IO.puts("-" <> String.duplicate("-", 30))
    
    # Look for potential content hashes in the binary data
    # Real content hashes might be stored separately from chunk IDs
    
    # Check if there are any additional hash fields in the structure
    expected_table_size = 16 + (length(parsed_data.chunks) * 40) + 40  # header + items + tail
    actual_data_size = byte_size(binary_data) - 48  # subtract FormatIndex header
    
    if actual_data_size > expected_table_size do
      extra_bytes = actual_data_size - expected_table_size
      IO.puts("📏 Extra data found: #{extra_bytes} bytes beyond expected table")
      IO.puts("   This could contain content verification hashes or metadata")
      
      # Extract and analyze extra data
      extra_data = binary_part(binary_data, 48 + expected_table_size, extra_bytes)
      analyze_extra_data(extra_data)
    else
      IO.puts("📏 No extra data beyond standard table structure")
    end
    
    # Check for hash patterns in chunk IDs vs actual content
    IO.puts("\n🔬 Hash Algorithm Analysis:")
    check_hash_algorithms(parsed_data)
  end

  defp analyze_extra_data(extra_data) do
    IO.puts("\n🔍 Extra Data Analysis:")
    IO.puts("  Size: #{byte_size(extra_data)} bytes")
    
    # Look for hash-like patterns (32-byte sequences)
    if rem(byte_size(extra_data), 32) == 0 do
      potential_hashes = div(byte_size(extra_data), 32)
      IO.puts("  Could contain #{potential_hashes} SHA256/SHA512-256 hashes")
    end
    
    # Show hex dump of first 64 bytes
    hex_sample = extra_data
    |> binary_part(0, min(64, byte_size(extra_data)))
    |> Base.encode16(case: :lower)
    |> String.graphemes()
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.join/1)
    |> Enum.chunk_every(16)
    |> Enum.map(&Enum.join(&1, " "))
    |> Enum.join("\n  ")
    
    IO.puts("  Hex sample:\n  #{hex_sample}")
  end

  defp check_hash_algorithms(parsed_data) do
    # Test if chunk IDs follow any known hash patterns
    sample_chunk = List.first(parsed_data.chunks)
    if sample_chunk do
      chunk_id_hex = Base.encode16(sample_chunk.chunk_id, case: :lower)
      IO.puts("  Sample chunk ID: #{chunk_id_hex}")
      
      # Check entropy
      entropy = calculate_entropy(sample_chunk.chunk_id)
      IO.puts("  Entropy: #{Float.round(entropy, 2)}/8.0 bits per byte")
      
      if entropy > 7.5 do
        IO.puts("  ✅ High entropy (consistent with cryptographic hash)")
      else
        IO.puts("  ⚠️  Lower entropy (may be rolling hash or fingerprint)")
      end
    end
  end

  defp test_assembly_integrity(parsed_data, store_path) do
    IO.puts("\n🔧 ASSEMBLY INTEGRITY TEST")
    IO.puts("-" <> String.duplicate("-", 30))
    
    if length(parsed_data.chunks) == 0 do
      IO.puts("No chunks to assemble")
    else
      IO.puts("Store path: #{store_path}")
      IO.puts("Expected total size: #{format_bytes(parsed_data.header.total_size)}")
      
      # Test assembling first few chunks to check integrity patterns
      test_chunks = Enum.take(parsed_data.chunks, min(3, length(parsed_data.chunks)))
      
      total_decompressed = Enum.reduce(test_chunks, 0, fn chunk, acc ->
        chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
        
        case find_and_load_chunk(store_path, chunk_id_hex) do
          {:ok, chunk_data} ->
            case decompress_chunk(chunk_data) do
              {:ok, decompressed} ->
                expected_size = chunk.size  # Use the corrected size field
                actual_size = byte_size(decompressed)
                
                IO.puts("  Chunk #{String.slice(chunk_id_hex, 0, 8)}: #{actual_size} bytes")
                
                if actual_size == expected_size do
                  IO.puts("    ✅ Size matches expected: #{expected_size}")
                else
                  IO.puts("    ❌ Size mismatch: expected #{expected_size}, got #{actual_size}")
                end
                
                acc + actual_size  # Accumulate total bytes
                
              {:error, reason} ->
                IO.puts("    ❌ Decompression failed: #{inspect(reason)}")
                acc
            end
            
          {:error, reason} ->
            IO.puts("    ❌ Chunk not found: #{inspect(reason)}")
            acc
        end
      end)
      
      IO.puts("\nTotal decompressed from sample: #{format_bytes(total_decompressed)}")
      
      # Check for :no_translation error
      test_string_handling(parsed_data)
    end
  end

  defp test_string_handling(parsed_data) do
    IO.puts("\n🔤 STRING HANDLING TEST")
    IO.puts("-" <> String.duplicate("-", 20))
    
    # Test potential :no_translation error sources
    sample_chunk = List.first(parsed_data.chunks)
    if sample_chunk do
      chunk_id_hex = Base.encode16(sample_chunk.chunk_id, case: :lower)
      
      # Test various string operations that might cause :no_translation
      try do
        _test1 = String.to_charlist(chunk_id_hex)
        IO.puts("✅ String.to_charlist works")
      rescue
        error -> IO.puts("❌ String.to_charlist failed: #{inspect(error)}")
      end
      
      try do
        _test2 = :erlang.list_to_binary([1, 2, 3])
        IO.puts("✅ Basic binary operations work")
      rescue
        error -> IO.puts("❌ Binary operations failed: #{inspect(error)}")
      end
      
      try do
        # Test if chunk ID contains non-UTF8 data
        _test3 = String.valid?(chunk_id_hex)
        IO.puts("✅ Chunk ID hex string is valid UTF-8")
      rescue
        error -> IO.puts("❌ UTF-8 validation failed: #{inspect(error)}")
      end
    end
  end

  defp find_and_load_chunk(store_path, chunk_id_hex) do
    chunk_dir = String.slice(chunk_id_hex, 0, 4)
    chunk_file = "#{chunk_id_hex}.cacnk"
    chunk_path = Path.join([store_path, chunk_dir, chunk_file])
    
    case File.read(chunk_path) do
      {:ok, data} -> {:ok, data}
      {:error, :enoent} -> {:error, :chunk_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decompress_chunk(chunk_data) do
    # Try ZSTD decompression (most common in casync)
    case :ezstd.decompress(chunk_data) do
      decompressed when is_binary(decompressed) ->
        {:ok, decompressed}
      _error ->
        # Fall back to trying CACNK format parsing
        case CasyncFormat.parse_chunk(chunk_data) do
          {:ok, %{data: compressed_data, header: header}} ->
            case header.compression do
              :zstd -> :ezstd.decompress(compressed_data)
              :none -> {:ok, compressed_data}
              _ -> {:error, :unsupported_compression}
            end
          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp find_store_path(caibx_path) do
    base_name = Path.basename(caibx_path, ".caibx")
    store_name = "#{base_name}.store"
    store_path = Path.join(Path.dirname(caibx_path), store_name)
    
    if File.exists?(store_path) do
      store_path
    else
      nil
    end
  end

  defp calculate_entropy(binary_data) do
    byte_counts = binary_data
    |> :binary.bin_to_list()
    |> Enum.frequencies()
    
    total_bytes = byte_size(binary_data)
    
    byte_counts
    |> Enum.map(fn {_byte, count} ->
      probability = count / total_bytes
      -probability * :math.log2(probability)
    end)
    |> Enum.sum()
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} bytes"
    end
  end
end
