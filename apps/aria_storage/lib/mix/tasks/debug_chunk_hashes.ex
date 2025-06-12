# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Casync.DebugHashes do
  @moduledoc """
  Debug chunk hash verification by examining the relationship between:
  1. Chunk IDs stored in the caibx/caidx index
  2. SHA512/256 hashes of decompressed chunk data
  3. SHA256 hashes of decompressed chunk data
  4. Potential rolling hash or content-defined chunking IDs
  
  This task helps identify why all chunk hash verifications are failing.
  """
  
  use Mix.Task
  import Bitwise
  alias AriaStorage.Parsers.CasyncFormat
  alias AriaStorage.Chunks

  @shortdoc "Debug chunk hash verification issues"

  def run(args) do
    case args do
      [index_file | _] ->
        debug_chunk_hashes(index_file)
      [] ->
        # Use default test files
        debug_chunk_hashes("blob1.caibx")
    end
  end

  defp debug_chunk_hashes(index_file) do
    IO.puts("🔍 Debugging Chunk Hash Verification")
    IO.puts("=====================================")
    
    # Find the index file
    index_path = find_index_file(index_file)
    store_path = String.replace(index_path, Path.extname(index_path), ".store")
    
    IO.puts("📁 Index file: #{index_path}")
    IO.puts("📁 Store path: #{store_path}")
    
    case File.read(index_path) do
      {:ok, index_data} ->
        case CasyncFormat.parse_index(index_data) do
          {:ok, parsed_data} ->
            IO.puts("✅ Successfully parsed index file")
            IO.puts("📊 Format: #{parsed_data.format}")
            IO.puts("📊 Chunk count: #{length(parsed_data.chunks)}")
            IO.puts("📊 Total size: #{parsed_data.header.total_size} bytes")
            IO.puts("📊 Feature flags: 0x#{Integer.to_string(parsed_data.feature_flags, 16)}")
            
            # Determine hash algorithm based on feature flags
            hash_algorithm = if (parsed_data.feature_flags &&& 0x2000000000000000) != 0 do
              "SHA512/256"
            else
              "SHA256"
            end
            IO.puts("🔧 Expected hash algorithm: #{hash_algorithm}")
            
            # Debug first few chunks
            parsed_data.chunks
            |> Enum.take(5)
            |> Enum.with_index()
            |> Enum.each(fn {chunk, index} ->
              debug_single_chunk(chunk, index, store_path, parsed_data.feature_flags)
            end)
            
          {:error, reason} ->
            IO.puts("❌ Failed to parse index: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to read index file: #{inspect(reason)}")
    end
  end

  defp debug_single_chunk(chunk, index, store_path, feature_flags) do
    chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
    short_id = String.slice(chunk_id_hex, 0, 8)
    
    IO.puts("\n🔍 Chunk #{index + 1}: #{short_id}")
    IO.puts("   ID (hex): #{chunk_id_hex}")
    IO.puts("   Size: #{chunk.size} bytes")
    IO.puts("   Offset: #{chunk.offset}")
    
    # Try to load the chunk file
    chunk_dir = String.slice(chunk_id_hex, 0, 4)
    chunk_file = "#{chunk_id_hex}.cacnk"
    chunk_path = Path.join([store_path, chunk_dir, chunk_file])
    
    case File.read(chunk_path) do
      {:ok, chunk_data} ->
        IO.puts("   ✅ Chunk file found: #{format_bytes(byte_size(chunk_data))}")
        
        # Check if it's raw ZSTD data
        if starts_with_zstd_magic?(chunk_data) do
          IO.puts("   🔧 Raw ZSTD data detected")
          
          case :ezstd.decompress(chunk_data) do
            decompressed when is_binary(decompressed) ->
              IO.puts("   ✅ Decompression successful: #{format_bytes(byte_size(decompressed))}")
              
              # Now test all possible hash calculations
              test_hash_algorithms(chunk.chunk_id, decompressed, feature_flags)
              
              # Test if the chunk ID might be a rolling hash or content-defined boundary hash
              test_content_defined_hash(chunk.chunk_id, decompressed, chunk.offset, chunk.size)
              
            error ->
              IO.puts("   ❌ Decompression failed: #{inspect(error)}")
          end
        else
          IO.puts("   🔧 Not raw ZSTD data, checking for CACNK format...")
          
          case CasyncFormat.parse_chunk(chunk_data) do
            {:ok, %{header: header, data: compressed_data}} ->
              IO.puts("   ✅ CACNK format detected, compression: #{header.compression}")
              
              case decompress_data(compressed_data, header.compression) do
                {:ok, decompressed} ->
                  IO.puts("   ✅ CACNK decompression successful: #{format_bytes(byte_size(decompressed))}")
                  test_hash_algorithms(chunk.chunk_id, decompressed, feature_flags)
                  
                {:error, reason} ->
                  IO.puts("   ❌ CACNK decompression failed: #{inspect(reason)}")
              end
              
            {:error, reason} ->
              IO.puts("   ❌ Not CACNK format: #{inspect(reason)}")
              IO.puts("   🔧 Trying as uncompressed data...")
              test_hash_algorithms(chunk.chunk_id, chunk_data, feature_flags)
          end
        end
        
      {:error, reason} ->
        IO.puts("   ❌ Chunk file not found: #{inspect(reason)}")
    end
  end

  defp test_hash_algorithms(expected_chunk_id, data, feature_flags) do
    IO.puts("   🧪 Testing hash algorithms:")
    
    # SHA256
    sha256_hash = :crypto.hash(:sha256, data)
    sha256_match = sha256_hash == expected_chunk_id
    IO.puts("      SHA256:     #{Base.encode16(sha256_hash, case: :lower)} #{if sha256_match, do: "✅ MATCH", else: "❌"}")
    
    # SHA512/256 (first 32 bytes of SHA512)
    sha512_256_hash = :crypto.hash(:sha512, data) |> binary_part(0, 32)
    sha512_256_match = sha512_256_hash == expected_chunk_id
    IO.puts("      SHA512/256: #{Base.encode16(sha512_256_hash, case: :lower)} #{if sha512_256_match, do: "✅ MATCH", else: "❌"}")
    
    # SHA512 (full)
    sha512_hash = :crypto.hash(:sha512, data)
    sha512_match = sha512_hash == expected_chunk_id
    IO.puts("      SHA512:     #{Base.encode16(sha512_hash, case: :lower)} #{if sha512_match, do: "✅ MATCH", else: "❌"}")
    
    # BLAKE3 (if available)
    try do
      blake3_hash = :crypto.hash(:blake3, data)
      blake3_match = blake3_hash == expected_chunk_id
      IO.puts("      BLAKE3:     #{Base.encode16(blake3_hash, case: :lower)} #{if blake3_match, do: "✅ MATCH", else: "❌"}")
    rescue
      _ -> 
        IO.puts("      BLAKE3:     Not available")
    end
    
    # Expected based on feature flags
    expected_algorithm = if (feature_flags &&& 0x2000000000000000) != 0 do
      "SHA512/256"
    else
      "SHA256"
    end
    
    IO.puts("      Expected:   #{expected_algorithm} based on feature flags")
    
    # Show expected chunk ID
    expected_hex = Base.encode16(expected_chunk_id, case: :lower)
    IO.puts("      Chunk ID:   #{expected_hex}")
  end

  defp test_content_defined_hash(expected_chunk_id, data, offset, size) do
    IO.puts("   🧪 Testing content-defined chunking theories:")
    
    # Test if chunk ID is calculated from our rolling hash algorithm
    calculated_chunk_id = Chunks.calculate_chunk_id(data)
    rolling_hash_match = calculated_chunk_id == expected_chunk_id
    IO.puts("      Our rolling hash: #{Base.encode16(calculated_chunk_id, case: :lower)} #{if rolling_hash_match, do: "✅ MATCH", else: "❌"}")
    
    # Test if chunk ID includes offset information
    offset_data = <<offset::64-little>> <> data
    offset_sha256 = :crypto.hash(:sha256, offset_data)
    offset_sha512_256 = :crypto.hash(:sha512, offset_data) |> binary_part(0, 32)
    
    offset_sha256_match = offset_sha256 == expected_chunk_id
    offset_sha512_256_match = offset_sha512_256 == expected_chunk_id
    
    IO.puts("      SHA256(offset+data):     #{Base.encode16(offset_sha256, case: :lower)} #{if offset_sha256_match, do: "✅ MATCH", else: "❌"}")
    IO.puts("      SHA512/256(offset+data): #{Base.encode16(offset_sha512_256, case: :lower)} #{if offset_sha512_256_match, do: "✅ MATCH", else: "❌"}")
    
    # Test if chunk ID includes size information
    size_data = <<size::32-little>> <> data
    size_sha256 = :crypto.hash(:sha256, size_data)
    size_sha512_256 = :crypto.hash(:sha512, size_data) |> binary_part(0, 32)
    
    size_sha256_match = size_sha256 == expected_chunk_id
    size_sha512_256_match = size_sha512_256 == expected_chunk_id
    
    IO.puts("      SHA256(size+data):       #{Base.encode16(size_sha256, case: :lower)} #{if size_sha256_match, do: "✅ MATCH", else: "❌"}")
    IO.puts("      SHA512/256(size+data):   #{Base.encode16(size_sha512_256, case: :lower)} #{if size_sha512_256_match, do: "✅ MATCH", else: "❌"}")
  end

  defp find_index_file(filename) do
    testdata_path = Path.join([File.cwd!(), "apps", "aria_storage", "test", "support", "testdata"])
    
    # Try various possible locations
    candidates = [
      filename,
      Path.join(testdata_path, filename),
      Path.join(File.cwd!(), filename)
    ]
    
    Enum.find(candidates, &File.exists?/1) || filename
  end

  defp starts_with_zstd_magic?(<<0x28, 0xB5, 0x2F, 0xFD, _::binary>>), do: true
  defp starts_with_zstd_magic?(_), do: false

  defp decompress_data(data, :zstd) do
    case :ezstd.decompress(data) do
      result when is_binary(result) -> {:ok, result}
      error -> {:error, {:zstd_error, error}}
    end
  end
  
  defp decompress_data(data, :none), do: {:ok, data}
  defp decompress_data(_data, compression), do: {:error, {:unsupported_compression, compression}}

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} bytes"
    end
  end
end
