#!/usr/bin/env elixir

# Advanced CAIDX decoder using AriaStorage.Parsers.CasyncFormat
# Usage: elixir decode_caidx_advanced.exs

Mix.install([
  {:req, "~> 0.4.0"},
  {:jason, "~> 1.4"},
  {:ezstd, "~> 1.0"}
])

defmodule SimpleCasyncFormat do
  @moduledoc """
  Simplified CasyncFormat parser for testing
  """
  
  # Constants from desync source code
  @ca_format_index 0x96824d9c7b129ff9
  @ca_format_table 0xe75b9e112f17417d
  @ca_format_table_tail_marker 0x4b4f050e5549ecd1
  
  def detect_format(<<format_header_size::little-64, format_type::little-64, feature_flags::little-64, _rest::binary>>) do
    case {format_header_size, format_type} do
      {48, @ca_format_index} -> 
        # More flexible detection: if it's an index file, try to determine based on context
        # The feature flags indicate capabilities, not necessarily the type
        if feature_flags == 0 do
          {:ok, :caidx}  # Basic CAIDX format
        else
          # Could be CAIBX (blob index) or CAIDX with extended features
          # For now, let's call it CAIBX as that's more common with feature flags
          {:ok, :caibx}
        end
      _ ->
        {:error, :unknown_format}
    end
  end
  def detect_format(_), do: {:error, :unknown_format}
  
  def parse_index(binary_data) when is_binary(binary_data) do
    case binary_data do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        remaining_data::binary>> -> 
        if size_field == 48 and type_field == @ca_format_index do
          format_type = if feature_flags == 0, do: :caidx, else: :caibx
          
          case remaining_data do
            <<>> ->
              result = %{
                format: format_type,
                header: %{version: 1, total_size: 0, chunk_count: 0},
                chunks: [],
                feature_flags: feature_flags,
                chunk_size_min: chunk_size_min,
                chunk_size_avg: chunk_size_avg,
                chunk_size_max: chunk_size_max
              }
              {:ok, result}
              
            _ ->
              case parse_format_table_with_items_binary(remaining_data) do
                {:ok, table_items} ->
                  result = %{
                    format: format_type,
                    header: %{
                      version: 1,
                      total_size: calculate_total_size(table_items),
                      chunk_count: length(table_items)
                    },
                    chunks: convert_table_to_chunks(table_items),
                    feature_flags: feature_flags,
                    chunk_size_min: chunk_size_min,
                    chunk_size_avg: chunk_size_avg,
                    chunk_size_max: chunk_size_max
                  }
                  {:ok, result}
                  
                {:error, reason} ->
                  {:error, reason}
              end
          end
        else
          {:error, "Invalid FormatIndex header"}
        end
      _ -> {:error, "Invalid binary data"}
    end
  end
  
  def to_json_safe(result) when is_map(result) do
    result
    |> Map.update(:chunks, [], fn chunks ->
      Enum.map(chunks, fn chunk ->
        chunk
        |> Map.update(:chunk_id, nil, &Base.encode64/1)
      end)
    end)
  end
  def to_json_safe(result), do: result

  def download_and_decompress_chunk(chunk_id_hex, base_url) do
    chunk_dir = String.slice(chunk_id_hex, 0, 4)  # First 4 chars: "31cd"
    chunk_file = "#{chunk_id_hex}.cacnk"  # Full chunk ID with .cacnk extension
    url = "#{base_url}/#{chunk_dir}/#{chunk_file}"
    
    case Req.get(url) do
      {:ok, %{status: 200, body: cacnk_data}} ->
        IO.puts("  Downloaded CACNK file: #{byte_size(cacnk_data)} bytes")
        
        # Save raw CACNK file for debugging
        debug_file = "/tmp/vsekai_decode_advanced/debug_#{String.slice(chunk_id_hex, 0, 8)}.cacnk"
        File.write!(debug_file, cacnk_data)
        IO.puts("  Saved raw CACNK to: #{debug_file}")
        
        # Parse CACNK file format first
        case parse_cacnk_file(cacnk_data) do
          {:ok, %{compression: compression, data: chunk_data}} ->
            IO.puts("  CACNK compression: #{compression}")
            IO.puts("  Compressed data size: #{byte_size(chunk_data)} bytes")
            
            case compression do
              :zstd ->
                # Try to decompress with ezstd
                case :ezstd.decompress(chunk_data) do
                  decompressed_data when is_binary(decompressed_data) ->
                    {:ok, decompressed_data}
                  error ->
                    {:error, {:decompression_failed, error}}
                end
              :none ->
                # Data is not compressed
                {:ok, chunk_data}
              _ ->
                {:error, {:unsupported_compression, compression}}
            end
          {:error, reason} ->
            {:error, {:cacnk_parse_failed, reason}}
        end
      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}
      {:error, reason} ->
        {:error, {:download_failed, reason}}
    end
  rescue
    e -> {:error, {:exception, e}}
  end
  
  defp parse_cacnk_file(binary_data) do
    # Debug: show first 16 bytes of the file
    debug_bytes = binary_data |> :binary.bin_to_list() |> Enum.take(16)
    IO.puts("  First 16 bytes: #{inspect(debug_bytes)}")
    
    case binary_data do
      # CACNK header: 3-byte magic + 4*4 bytes (16 bytes total header)
      <<0xCA, 0xC4, 0x4E, compressed_size::little-32, uncompressed_size::little-32,
        compression_type::little-32, flags::little-32, remaining_data::binary>> ->

        compression = case compression_type do
          0 -> :none
          1 -> :zstd
          _ -> :unknown
        end

        result = %{
          magic: :cacnk,
          compressed_size: compressed_size,
          uncompressed_size: uncompressed_size,
          compression: compression,
          flags: flags,
          data: remaining_data
        }

        {:ok, result}

      # Try to detect if it's just raw compressed data (no CACNK header)
      _ when byte_size(binary_data) > 0 ->
        IO.puts("  No CACNK header found, treating as raw compressed data")
        {:ok, %{
          magic: :raw,
          compressed_size: byte_size(binary_data),
          uncompressed_size: 0,
          compression: :zstd,  # Assume ZSTD compression
          flags: 0,
          data: binary_data
        }}

      _ ->
        {:error, "Invalid CACNK file format"}
    end
  end
  
  defp parse_format_table_with_items_binary(binary_data) do
    IO.puts("  Parsing format table from #{byte_size(binary_data)} bytes of data")
    case binary_data do
      <<table_marker::little-64, table_type::little-64, remaining_data::binary>> ->
        IO.puts("  Table marker: 0x#{Integer.to_string(table_marker, 16)}")
        IO.puts("  Table type: 0x#{Integer.to_string(table_type, 16)}")
        IO.puts("  Expected table type: 0x#{Integer.to_string(@ca_format_table, 16)}")
        IO.puts("  Remaining data for items: #{byte_size(remaining_data)} bytes")
        
        if table_marker == 0xFFFFFFFFFFFFFFFF and table_type == @ca_format_table do
          parse_table_items_binary(remaining_data, [])
        else
          {:error, "Invalid FormatTable header"}
        end
      _ ->
        {:error, "Invalid binary data"}
    end
  end
  
  defp parse_table_items_binary(binary_data, acc) do
    if rem(length(acc), 100) == 0 and length(acc) > 0 do
      IO.puts("  Processing chunk #{length(acc)}...")
    end
    
    case binary_data do
      # Check for table tail marker first (40 bytes total: 8+8+8+8+8)
      <<zero1::little-64, zero2::little-64, size_field::little-64, _table_size::little-64, tail_marker::little-64, _rest::binary>>
      when zero1 == 0 and zero2 == 0 and size_field == 48 and tail_marker == @ca_format_table_tail_marker ->
        IO.puts("  Found table tail marker, parsed #{length(acc)} items")
        {:ok, Enum.reverse(acc)}
        
      # Parse table item (40 bytes: 8 offset + 32 chunk_id)
      <<item_offset::little-64, chunk_id::binary-size(32), remaining_data::binary>> when byte_size(remaining_data) >= 0 ->
        item = %{offset: item_offset, chunk_id: chunk_id}
        parse_table_items_binary(remaining_data, [item | acc])
        
      # Not enough data for a complete item, might be at the tail
      data when byte_size(data) < 40 ->
        IO.puts("  Insufficient data for item (#{byte_size(data)} bytes), checking for tail...")
        case data do
          <<zero1::little-64, zero2::little-64, size_field::little-64, _table_size::little-64, tail_marker::little-64, _rest::binary>>
          when zero1 == 0 and zero2 == 0 and size_field == 48 and tail_marker == @ca_format_table_tail_marker ->
            IO.puts("  Found table tail marker at end, parsed #{length(acc)} items")
            {:ok, Enum.reverse(acc)}
          _ ->
            IO.puts("  Invalid table data at end: #{byte_size(data)} bytes remaining")
            {:error, "Invalid table data - insufficient bytes for item or tail"}
        end
        
      _ ->
        IO.puts("  Invalid table data format, #{byte_size(binary_data)} bytes remaining")
        {:error, "Invalid table data format"}
    end
  end
  
  defp calculate_total_size(items) when length(items) > 0 do
    List.last(items).offset
  end
  defp calculate_total_size(_), do: 0
  
  defp convert_table_to_chunks(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      previous_offset = if index == 0, do: 0, else: Enum.at(items, index - 1).offset
      
      %{
        chunk_id: item.chunk_id,
        offset: previous_offset,
        size: item.offset - previous_offset,
        flags: 0
      }
    end)
  end
end

defmodule AdvancedCaidxDecoder do
  @moduledoc """
  Advanced decoder for CAIDX files using embedded parser
  """

  def main do
    IO.puts("V-Sekai CAIDX Advanced Decoder")
    IO.puts("==============================")
    
    # Try multiple possible URLs for the CAIDX file including CDN services
    # Focus on Windows executable which should be the larger ~300MB file
    urls = [
      "https://raw.githack.com/V-Sekai/casync-v-sekai-game/main/vsekai_game_windows_x86_64.caidx",
      "https://cdn.jsdelivr.net/gh/V-Sekai/casync-v-sekai-game@main/vsekai_game_windows_x86_64.caidx",
      "https://github.com/V-Sekai/casync-v-sekai-game/raw/main/vsekai_game_windows_x86_64.caidx",
      "https://github.com/V-Sekai/casync-v-sekai-game/raw/refs/heads/main/vsekai_game_windows_x86_64.caidx",
      "https://raw.githubusercontent.com/V-Sekai/casync-v-sekai-game/main/vsekai_game_windows_x86_64.caidx"
    ]
    
    output_dir = "/tmp/vsekai_decode_advanced"
    
    # Create output directory
    File.mkdir_p!(output_dir)
    
    # Try each URL until we find one that works
    download_result = Enum.find_value(urls, fn url ->
      IO.puts("Trying URL: #{url}")
      case download_file(url) do
        {:ok, binary_data} when byte_size(binary_data) > 1000 ->
          IO.puts("✓ Found larger file: #{byte_size(binary_data)} bytes")
          {:ok, binary_data}
        {:ok, binary_data} ->
          IO.puts("⚠️  Small file found: #{byte_size(binary_data)} bytes")
          {:small, binary_data}
        {:error, reason} ->
          IO.puts("✗ Failed: #{inspect(reason)}")
          nil
      end
    end)
    
    case download_result do
      {:ok, binary_data} ->
        IO.puts("Downloaded #{byte_size(binary_data)} bytes")
        
        # Check if this looks like a Git LFS pointer file
        if byte_size(binary_data) < 1000 and String.contains?(to_string(binary_data), "git-lfs") do
          IO.puts("⚠️  WARNING: Downloaded file appears to be a Git LFS pointer file!")
          IO.puts("The actual CAIDX file is likely stored in Git LFS and not directly downloadable.")
          IO.puts("File content preview:")
          IO.puts(String.slice(to_string(binary_data), 0, 200))
        end
        
        # Check if this looks like a Git LFS pointer file
        if byte_size(binary_data) < 1000 and String.contains?(to_string(binary_data), "git-lfs") do
          IO.puts("⚠️  WARNING: Downloaded file appears to be a Git LFS pointer file!")
          IO.puts("The actual CAIDX file is likely stored in Git LFS and not directly downloadable.")
          IO.puts("File content preview:")
          IO.puts(String.slice(to_string(binary_data), 0, 200))
        end
        
        # Save original file
        original_file = Path.join(output_dir, "vsekai_game_windows_x86_64.caidx")
        File.write!(original_file, binary_data)
        IO.puts("Saved original file: #{original_file}")
        
        # Detect format first
        case SimpleCasyncFormat.detect_format(binary_data) do
          {:ok, format} ->
            IO.puts("Detected format: #{format}")
            
            # Parse the file
            case SimpleCasyncFormat.parse_index(binary_data) do
              {:ok, parsed_data} ->
                IO.puts("Successfully parsed CAIDX file!")
                
                # Print detailed information
                print_detailed_info(parsed_data)
                
                # Save parsed data
                save_parsed_data(parsed_data, output_dir)
                
                # Generate chunk download script
                generate_chunk_script(parsed_data, output_dir)
                
                # Test downloading and decompressing a chunk
                test_chunk_download(parsed_data, output_dir)
                
                # Download all chunks and assemble the final executable
                assemble_executable(parsed_data, output_dir)
                
                # Test encoding roundtrip
                test_roundtrip(parsed_data, output_dir)
                
              {:error, reason} ->
                IO.puts("Failed to parse CAIDX: #{inspect(reason)}")
                
                # Try to analyze the raw binary for debugging
                analyze_raw_binary(binary_data, output_dir)
            end
            
          {:error, reason} ->
            IO.puts("Failed to detect format: #{inspect(reason)}")
            analyze_raw_binary(binary_data, output_dir)
        end
        
      {:error, reason} ->
        IO.puts("Failed to download: #{inspect(reason)}")
    end
  end
  
  defp download_file(url) do
    case Req.get(url) do
      {:ok, %{status: 200, body: binary_data}} ->
        {:ok, binary_data}
      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp print_detailed_info(data) do
    IO.puts("\n=== DETAILED ANALYSIS ===")
    archive_type = if data.format == :caibx, do: "blob (single file)", else: "directory tree"
    IO.puts("Format: #{data.format} - #{archive_type}")
    IO.puts("Header Version: #{data.header.version}")
    IO.puts("Feature Flags: 0x#{Integer.to_string(data.feature_flags, 16)} (#{data.feature_flags})")
    
    IO.puts("\nChunk Size Configuration:")
    IO.puts("  Minimum: #{format_bytes(data.chunk_size_min)}")
    IO.puts("  Average: #{format_bytes(data.chunk_size_avg)}")
    IO.puts("  Maximum: #{format_bytes(data.chunk_size_max)}")
    
    IO.puts("\nArchive Information:")
    IO.puts("  Type: #{archive_type}")
    IO.puts("  Total Size: #{format_bytes(data.header.total_size)}")
    IO.puts("  Chunk Count: #{data.header.chunk_count}")
    
    if data.header.chunk_count > 0 do
      chunk_sizes = Enum.map(data.chunks, & &1.size)
      avg_size = Enum.sum(chunk_sizes) / length(chunk_sizes)
      min_size = Enum.min(chunk_sizes)
      max_size = Enum.max(chunk_sizes)
      
      IO.puts("\nActual Chunk Statistics:")
      IO.puts("  Minimum Size: #{format_bytes(min_size)}")
      IO.puts("  Average Size: #{format_bytes(round(avg_size))}")
      IO.puts("  Maximum Size: #{format_bytes(max_size)}")
    end
    
    IO.puts("\n=== SAMPLE CHUNKS ===")
    data.chunks
    |> Enum.take(10)
    |> Enum.with_index()
    |> Enum.each(fn {chunk, index} ->
      chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
      IO.puts("#{String.pad_leading(to_string(index + 1), 3)}: #{chunk_id_hex} | #{format_bytes(chunk.size)} @ #{chunk.offset}")
    end)
    
    if length(data.chunks) > 10 do
      IO.puts("... and #{length(data.chunks) - 10} more chunks")
    end
  end
  
  defp format_bytes(bytes) do
    cond do
      bytes >= 1024 * 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
      bytes >= 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 ->
        "#{Float.round(bytes / 1024, 2)} KB"
      true ->
        "#{bytes} bytes"
    end
  end
  
  defp save_parsed_data(data, output_dir) do
    # Save as JSON
    json_file = Path.join(output_dir, "parsed_caidx.json")
    json_data = SimpleCasyncFormat.to_json_safe(data)
    File.write!(json_file, Jason.encode!(json_data, pretty: true))
    IO.puts("\nSaved JSON: #{json_file}")
    
    # Save chunk list as text file (not CSV to avoid confusion)
    chunks_file = Path.join(output_dir, "chunks.txt")
    
    if length(data.chunks) > 0 do
      chunk_lines = data.chunks
      |> Enum.with_index()
      |> Enum.map(fn {chunk, index} ->
        chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
        "#{String.pad_leading(to_string(index + 1), 6)}: #{chunk_id_hex} | offset: #{chunk.offset} | size: #{chunk.size}"
      end)
      
      content = [
        "CAIDX Chunk List",
        "================",
        "Format: #{data.format}",
        "Total chunks: #{length(data.chunks)}",
        "Total size: #{data.header.total_size} bytes",
        "",
        "Chunks:"
      ] ++ chunk_lines
      
      File.write!(chunks_file, Enum.join(content, "\n"))
      IO.puts("Saved chunks: #{chunks_file}")
    else
      File.write!(chunks_file, "No chunks found in this CAIDX file.")
      IO.puts("Saved empty chunks file: #{chunks_file}")
    end
  end
  
  defp generate_chunk_script(data, output_dir) do
    script_file = Path.join(output_dir, "download_chunks.sh")
    
    # Try multiple CDN URLs for better access
    base_urls = [
      "https://raw.githack.com/V-Sekai/casync-v-sekai-game/main/store",
      "https://cdn.jsdelivr.net/gh/V-Sekai/casync-v-sekai-game@main/store",
      "https://github.com/V-Sekai/casync-v-sekai-game/raw/main/store"
    ]
    base_url = List.first(base_urls)
    
    script_content = [
      "#!/bin/bash",
      "# Script to download chunks for V-Sekai game",
      "# Generated from CAIDX analysis",
      "# ",
      "# Chunk storage format: store/XXXX/FULLCHUNKID.cacnk where XXXX are first 4 hex chars",
      "# and FULLCHUNKID is the complete chunk ID with .cacnk extension",
      "",
      "CHUNK_DIR=\"/tmp/vsekai_chunks\"",
      "BASE_URL=\"#{base_url}\"",
      "",
      "mkdir -p \"$CHUNK_DIR\"",
      "cd \"$CHUNK_DIR\"",
      "",
      "echo \"Downloading #{min(5, length(data.chunks))} sample chunks out of #{length(data.chunks)} total chunks...\"",
      "echo \"Full archive size: #{format_bytes(data.header.total_size)}\"",
      ""
    ]
    
    chunk_commands = data.chunks
    |> Enum.take(5)  # Limit to first 5 for demonstration
    |> Enum.with_index()
    |> Enum.map(fn {chunk, index} ->
      chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
      chunk_dir = String.slice(chunk_id_hex, 0, 4)  # First 4 chars like "31cd"
      chunk_file = "#{chunk_id_hex}.cacnk"  # Full chunk ID with .cacnk extension
      
      [
        "echo \"Downloading chunk #{index + 1}/#{min(5, length(data.chunks))}: #{chunk_id_hex}\"",
        "mkdir -p \"#{chunk_dir}\"",
        "curl -L \"${BASE_URL}/#{chunk_dir}/#{chunk_file}\" -o \"#{chunk_dir}/#{chunk_file}\" || echo \"Failed to download #{chunk_id_hex}\""
      ]
    end)
    |> List.flatten()
    
    all_content = script_content ++ chunk_commands ++ ["", "echo \"Download complete!\""]
    File.write!(script_file, Enum.join(all_content, "\n"))
    File.chmod!(script_file, 0o755)
    
    IO.puts("Generated download script: #{script_file}")
  end
  
  defp test_chunk_download(data, output_dir) do
    IO.puts("\n=== TESTING CHUNK DOWNLOAD & DECOMPRESSION ===")
    
    if length(data.chunks) > 0 do
      # Try to download and decompress the first chunk
      first_chunk = List.first(data.chunks)
      chunk_id_hex = Base.encode16(first_chunk.chunk_id, case: :lower)
      
      # Try multiple CDN URLs for better access
      base_urls = [
        "https://raw.githack.com/V-Sekai/casync-v-sekai-game/main/store",
        "https://cdn.jsdelivr.net/gh/V-Sekai/casync-v-sekai-game@main/store",
#        "https://github.com/V-Sekai/casync-v-sekai-game/raw/main/store"
      ]
      
      IO.puts("Attempting to download chunk: #{chunk_id_hex}")
      
      # Try each URL until one works
      result = Enum.find_value(base_urls, fn base_url ->
        IO.puts("  Trying store URL: #{base_url}")
        case SimpleCasyncFormat.download_and_decompress_chunk(chunk_id_hex, base_url) do
          {:ok, decompressed_data} -> {:ok, decompressed_data}
          {:error, {:http_error, 404}} -> nil  # Try next URL
          {:error, reason} -> 
            IO.puts("  Failed with #{base_url}: #{inspect(reason)}")
            nil  # Try next URL
        end
      end)
      
      case result do
        {:ok, decompressed_data} ->
          IO.puts("✓ Successfully downloaded and decompressed chunk!")
          IO.puts("  Decompressed size: #{byte_size(decompressed_data)} bytes")
          
          # Save decompressed chunk for inspection
          chunk_file = Path.join(output_dir, "chunk_#{String.slice(chunk_id_hex, 0, 8)}.bin")
          File.write!(chunk_file, decompressed_data)
          IO.puts("  Saved decompressed chunk to: #{chunk_file}")
          
        nil ->
          IO.puts("✗ Chunk not found in any of the store URLs")
          IO.puts("  This might be expected if the chunk store is not publicly accessible")
      end
    else
      IO.puts("No chunks available to test download")
    end
  end

  defp assemble_executable(data, output_dir) do
    IO.puts("\n=== ASSEMBLING COMPLETE EXECUTABLE ===")
    
    if length(data.chunks) == 0 do
      IO.puts("No chunks to assemble")
      :ok
    else
      output_file = Path.join(output_dir, "vsekai_game.exe")
      total_chunks = length(data.chunks)
      IO.puts("Assembling #{total_chunks} chunks into #{output_file}")
      IO.puts("Expected final size: #{format_bytes(data.header.total_size)}")
      
      # Try multiple CDN URLs for better access
      base_urls = [
        "https://raw.githack.com/V-Sekai/casync-v-sekai-game/main/store",
        "https://cdn.jsdelivr.net/gh/V-Sekai/casync-v-sekai-game@main/store"
      ]
      
      # Open output file for writing
      {:ok, output_handle} = File.open(output_file, [:write, :binary])
      
      try do
        {_final_offset, successful_chunks, failed_chunks} = 
          data.chunks
          |> Enum.with_index()
          |> Enum.reduce({0, 0, 0}, fn {chunk, index}, {current_offset, successful_chunks, failed_chunks} ->
            chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
            
            # Progress indicator
            if rem(index, 10) == 0 or index == total_chunks - 1 do
              progress = Float.round((index + 1) / total_chunks * 100, 1)
              IO.puts("Progress: #{progress}% (#{index + 1}/#{total_chunks}) - Processing chunk #{String.slice(chunk_id_hex, 0, 8)}...")
            end
            
            # Verify offset alignment
            updated_offset = if current_offset != chunk.offset do
              IO.puts("⚠️  Offset mismatch at chunk #{index}: expected #{chunk.offset}, current #{current_offset}")
              # Pad with zeros if we're behind
              if current_offset < chunk.offset do
                padding_size = chunk.offset - current_offset
                IO.puts("   Padding with #{padding_size} zeros")
                IO.binwrite(output_handle, :binary.copy(<<0>>, padding_size))
                chunk.offset
              else
                current_offset
              end
            else
              current_offset
            end
            
            # Try to download and decompress this chunk
            result = Enum.find_value(base_urls, fn base_url ->
              case SimpleCasyncFormat.download_and_decompress_chunk(chunk_id_hex, base_url) do
                {:ok, decompressed_data} -> {:ok, decompressed_data}
                {:error, {:http_error, 404}} -> nil  # Try next URL
                {:error, _reason} -> nil  # Try next URL
              end
            end)
            
            case result do
              {:ok, decompressed_data} ->
                # Verify chunk size matches expected
                actual_size = byte_size(decompressed_data)
                if actual_size != chunk.size do
                  IO.puts("⚠️  Size mismatch for chunk #{String.slice(chunk_id_hex, 0, 8)}: expected #{chunk.size}, got #{actual_size}")
                end
                
                # Write chunk data to output file
                IO.binwrite(output_handle, decompressed_data)
                {updated_offset + actual_size, successful_chunks + 1, failed_chunks}
                
              nil ->
                IO.puts("✗ Failed to download chunk #{String.slice(chunk_id_hex, 0, 8)} from any URL")
                # Write zeros as placeholder
                IO.binwrite(output_handle, :binary.copy(<<0>>, chunk.size))
                {updated_offset + chunk.size, successful_chunks, failed_chunks + 1}
            end
          end)
        
        File.close(output_handle)
        
        # Get final file size
        final_size = File.stat!(output_file).size
        
        IO.puts("\n=== ASSEMBLY COMPLETE ===")
        IO.puts("Output file: #{output_file}")
        IO.puts("Final size: #{format_bytes(final_size)}")
        IO.puts("Expected size: #{format_bytes(data.header.total_size)}")
        IO.puts("Successful chunks: #{successful_chunks}/#{total_chunks}")
        IO.puts("Failed chunks: #{failed_chunks}/#{total_chunks}")
        
        if final_size == data.header.total_size do
          IO.puts("✓ File size matches expected size!")
        else
          IO.puts("⚠️  File size mismatch - assembly may be incomplete")
        end
        
        if failed_chunks > 0 do
          IO.puts("⚠️  Some chunks failed to download - the executable may not work correctly")
          IO.puts("   Failed chunks were filled with zeros as placeholders")
        else
          IO.puts("✓ All chunks downloaded successfully!")
          IO.puts("✓ The assembled executable should be complete and functional")
        end
        
      rescue
        e ->
          File.close(output_handle)
          IO.puts("✗ Error during assembly: #{inspect(e)}")
      end
    end
  end

  defp test_roundtrip(_data, _output_dir) do
    IO.puts("\n=== TESTING ROUNDTRIP ENCODING ===")
    IO.puts("Note: Roundtrip encoding test skipped - using simplified parser")
    
    # For now, we'll skip the roundtrip test since we're using the simplified parser
    # The full implementation in casync_format.ex supports encoding
  end
  
  defp analyze_raw_binary(binary_data, output_dir) do
    IO.puts("\n=== RAW BINARY ANALYSIS ===")
    
    # Save hex dump
    hex_file = Path.join(output_dir, "hexdump.txt")
    hex_lines = binary_data
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.take(32)  # First 512 bytes
    |> Enum.map(fn {bytes, index} ->
      offset = String.pad_leading(Integer.to_string(index * 16, 16), 8, "0")
      hex_part = bytes |> Enum.map(&String.pad_leading(Integer.to_string(&1, 16), 2, "0")) |> Enum.join(" ")
      ascii_part = bytes |> Enum.map(fn b -> if b >= 32 and b <= 126, do: <<b>>, else: "." end) |> Enum.join("")
      "#{offset}: #{String.pad_trailing(hex_part, 47)} |#{ascii_part}|"
    end)
    
    File.write!(hex_file, Enum.join(hex_lines, "\n"))
    IO.puts("Saved hex dump: #{hex_file}")
    
    # Analyze first 64 bytes
    if byte_size(binary_data) >= 48 do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        _rest::binary>> = binary_data
        
      IO.puts("\nHeader Analysis:")
      IO.puts("  Size Field: #{size_field} (expected: 48)")
      IO.puts("  Type Field: 0x#{Integer.to_string(type_field, 16)} (expected: 0x96824d9c7b129ff9)")
      IO.puts("  Feature Flags: #{feature_flags}")
      IO.puts("  Chunk Size Min: #{chunk_size_min}")
      IO.puts("  Chunk Size Avg: #{chunk_size_avg}")
      IO.puts("  Chunk Size Max: #{chunk_size_max}")
    end
  end
end

# Run the advanced decoder
AdvancedCaidxDecoder.main()