# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.CasyncDecode do
  @moduledoc """
  Advanced casync file decoder and analyzer.

  This task provides comprehensive decoding and analysis capabilities for all casync file formats:
  - .caibx (Content Archive Index for Blobs)
  - .caidx (Content Archive Index for Directories)
  - .catar (Archive Container format)
  - .cacnk (Compressed Chunk files)

  Usage:
    mix casync_decode                          # Process all files with stores in testdata
    mix casync_decode --file blob1.caibx       # Process specific file (auto-find store)
    mix casync_decode --file blob1.caibx --store blob1.store  # Process with specific store
    mix casync_decode --output /tmp/output     # Custom output directory

  Options:
    --file     Specific casync file to process (relative to testdata)
    --store    Store directory to use (relative to testdata, auto-detected if not specified)
    --output   Output directory (default: /tmp/aria_storage_decode)
    --help     Show this help

  Note: Index files (.caibx/.caidx) require a corresponding .store directory.
  Archive files (.catar) can be processed independently.
  """

  use Mix.Task
  import Bitwise
  alias AriaStorage.Parsers.CasyncFormat

  @shortdoc "Decode and analyze casync files"

  def run(args) do
    Mix.Task.run("app.start")
    
    {opts, _, _} = OptionParser.parse(args, 
      switches: [file: :string, store: :string, output: :string, help: :boolean],
      aliases: [f: :file, s: :store, o: :output, h: :help]
    )

    if opts[:help] do
      IO.puts(@moduledoc)
      System.halt(0)
    end

    IO.puts("V-Sekai CAIDX Advanced Decoder")
    IO.puts("==============================")
    
    testdata_path = "apps/aria_storage/test/support/testdata"
    output_dir = opts[:output] || "/tmp/aria_storage_decode"
    
    unless File.exists?(testdata_path) do
      IO.puts("❌ No testdata directory found at: #{testdata_path}")
      IO.puts("Please ensure the testdata directory exists.")
      System.halt(1)
    end

    File.mkdir_p!(output_dir)
    IO.puts("📁 Output directory: #{output_dir}")

    IO.puts("AriaStorage Casync Decoder")
    IO.puts("==========================")

    case opts[:file] do
      nil ->
        process_all_files(testdata_path, output_dir)
      filename ->
        process_specific_file(testdata_path, filename, opts[:store], output_dir)
    end
  end

  defp process_all_files(testdata_path, output_dir) do
    # Look for all supported index files
    patterns = ["*.caibx", "*.caidx", "*.catar"]
    
    index_files = patterns
    |> Enum.flat_map(&Path.wildcard(Path.join(testdata_path, &1)))
    |> Enum.sort()

    if length(index_files) == 0 do
      IO.puts("❌ No .caibx, .caidx, or .catar files found in testdata")
      System.halt(1)
    end

    IO.puts("Found #{length(index_files)} index file(s):")
    Enum.each(index_files, &IO.puts("  - #{Path.basename(&1)}"))
    
    # Process each file, checking if store is needed based on file type
    Enum.with_index(index_files, 1)
    |> Enum.each(fn {file_path, index} ->
      IO.puts("\n" <> String.duplicate("=", 60))
      IO.puts("Processing #{index}/#{length(index_files)}: #{Path.basename(file_path)}")
      IO.puts(String.duplicate("=", 60))
      
      file_ext = Path.extname(file_path) |> String.downcase()
      
      if file_ext == ".catar" do
        # CATAR files don't need stores
        IO.puts("🗂️  CATAR file - no store required")
        process_index_file_from_path(file_path, nil, output_dir)
      else
        # Index files need stores
        store_path = find_store_for_file(file_path)
        
        if store_path do
          IO.puts("🗄️  Found store: #{Path.basename(store_path)}")
          process_index_file_from_path(file_path, store_path, output_dir)
        else
          IO.puts("❌ No store found for #{Path.basename(file_path)} - skipping")
          IO.puts("Expected store: #{Path.basename(file_path, Path.extname(file_path))}.store")
        end
      end
    end)
  end

  defp process_specific_file(testdata_path, filename, store_name, output_dir) do
    file_path = Path.join(testdata_path, filename)
    
    unless File.exists?(file_path) do
      IO.puts("❌ File not found: #{file_path}")
      list_available_files(testdata_path)
      System.halt(1)
    end

    file_ext = Path.extname(file_path) |> String.downcase()
    
    if file_ext == ".catar" do
      # CATAR files don't need stores
      IO.puts("🗂️  CATAR file - no store required")
      process_index_file_from_path(file_path, nil, output_dir)
    else
      # Index files need stores
      store_path = case store_name do
        nil -> find_store_for_file(file_path)
        store -> 
          store_full_path = Path.join(testdata_path, store)
          if File.exists?(store_full_path), do: store_full_path, else: nil
      end

      unless store_path do
        IO.puts("❌ No store directory found!")
        IO.puts("Available stores:")
        list_available_stores(testdata_path)
        if store_name do
          IO.puts("Specified store '#{store_name}' does not exist.")
        else
          IO.puts("Auto-detected store for '#{filename}' not found.")
          IO.puts("Please specify a store with --store option.")
        end
        System.halt(1)
      end

      IO.puts("🗄️  Using store: #{Path.basename(store_path)}")
      process_index_file_from_path(file_path, store_path, output_dir)
    end
  end

  defp find_store_for_file(file_path) do
    # Try to find store by replacing extension with .store
    base_name = Path.basename(file_path, Path.extname(file_path))
    store_path = Path.join(Path.dirname(file_path), "#{base_name}.store")
    
    if File.exists?(store_path) and File.dir?(store_path) do
      store_path
    else
      nil
    end
  end

  defp list_available_files(testdata_path) do
    patterns = ["*.caibx", "*.caidx", "*.catar"]
    
    files = patterns
    |> Enum.flat_map(&Path.wildcard(Path.join(testdata_path, &1)))
    |> Enum.map(&Path.basename/1)
    |> Enum.sort()

    if length(files) > 0 do
      IO.puts("\nAvailable files:")
      Enum.each(files, &IO.puts("  - #{&1}"))
    end
  end

  defp list_available_stores(testdata_path) do
    case File.ls(testdata_path) do
      {:ok, entries} ->
        stores = entries
        |> Enum.filter(fn entry ->
          entry_path = Path.join(testdata_path, entry)
          File.dir?(entry_path) and String.ends_with?(entry, ".store")
        end)
        |> Enum.sort()

        if length(stores) > 0 do
          Enum.each(stores, &IO.puts("  - #{&1}"))
        else
          IO.puts("  (no .store directories found)")
        end
      _ ->
        IO.puts("  (error reading directory)")
    end
  end

  defp process_index_file_from_path(file_path, store_path, output_dir) do
    case File.read(file_path) do
      {:ok, binary_data} ->
        process_index_file(binary_data, file_path, output_dir, store_path)
      {:error, reason} ->
        IO.puts("❌ Failed to read #{file_path}: #{inspect(reason)}")
    end
  end

  defp process_index_file(binary_data, file_path, output_dir, store_path) do
    IO.puts("📁 Processing: #{Path.basename(file_path)}")
    IO.puts("📊 File size: #{format_bytes(byte_size(binary_data))}")
    
    if store_path do
      IO.puts("🗄️  Store: #{Path.basename(store_path)}")
    else
      IO.puts("🗄️  Store: Not required")
    end

    # Check if this looks like a Git LFS pointer file
    if byte_size(binary_data) < 1000 and String.contains?(to_string(binary_data), "git-lfs") do
      IO.puts("⚠️  WARNING: File appears to be a Git LFS pointer file!")
      IO.puts("The actual file content is stored in Git LFS.")
      IO.puts("File content preview:")
      IO.puts(String.slice(to_string(binary_data), 0, 200))
      :git_lfs_file
    end

    # Save original file to output
    file_output_dir = Path.join(output_dir, Path.basename(file_path, Path.extname(file_path)))
    File.mkdir_p!(file_output_dir)
    
    original_file = Path.join(file_output_dir, Path.basename(file_path))
    File.write!(original_file, binary_data)
    IO.puts("💾 Saved original: #{original_file}")

    # Detect file type and use appropriate parser
    file_ext = Path.extname(file_path) |> String.downcase()
    
    parse_result = case file_ext do
      ".catar" ->
        IO.puts("🗂️  Detected CATAR archive format")
        CasyncFormat.parse_archive(binary_data)
      
      ext when ext in [".caidx", ".caibx"] ->
        IO.puts("📇 Detected #{String.upcase(String.trim_leading(ext, "."))} index format")
        CasyncFormat.parse_index(binary_data)
      
      _ ->
        IO.puts("🔍 Unknown extension '#{file_ext}', trying index parser first...")
        case CasyncFormat.parse_index(binary_data) do
          {:ok, _} = result -> result
          {:error, _} ->
            IO.puts("🔍 Index parsing failed, trying archive parser...")
            CasyncFormat.parse_archive(binary_data)
        end
    end
    
    case parse_result do
      {:ok, parsed_data} ->
        IO.puts("✅ Successfully parsed!")
        
        # Print detailed information
        print_detailed_info(parsed_data)
        
        # Save parsed data
        save_parsed_data(parsed_data, file_output_dir)
        
        # Handle format-specific operations
        case parsed_data.format do
          :catar ->
            # CATAR files don't need chunk downloads or store access
            IO.puts("📁 CATAR archive processed - extracting directory structure...")
            extract_catar_structure(parsed_data, file_output_dir)
            
          format when format in [:caidx, :caibx] ->
            # Generate chunk download script
            generate_chunk_script(parsed_data, file_output_dir)
            
            # Test local chunk access (only if store is provided)
            if store_path do
              test_local_chunk_access(parsed_data, store_path, file_output_dir)
            else
              IO.puts("⚠️  No store directory available for chunk testing")
            end
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to parse: #{inspect(reason)}")
        
        # Try to analyze the raw binary for debugging
        analyze_raw_binary(binary_data, file_output_dir)
    end
  end

  defp test_local_chunk_access(data, store_path, output_dir) do
    IO.puts("\n=== TESTING LOCAL CHUNK ACCESS ===")
    
    if length(data.chunks) == 0 do
      IO.puts("No chunks to test")
    else
      # Test the first chunk
      first_chunk = List.first(data.chunks)
      chunk_id_hex = Base.encode16(first_chunk.chunk_id, case: :lower)
      
      # Look for chunk in store using casync naming convention
      chunk_dir = String.slice(chunk_id_hex, 0, 4)
      chunk_file = "#{chunk_id_hex}.cacnk"
      chunk_path = Path.join([store_path, chunk_dir, chunk_file])
      
      IO.puts("🔍 Looking for chunk: #{chunk_id_hex}")
      IO.puts("📍 Expected path: #{chunk_path}")
      
      if File.exists?(chunk_path) do
        case File.read(chunk_path) do
          {:ok, chunk_data} ->
            IO.puts("✅ Found local chunk!")
            IO.puts("📊 Chunk size: #{format_bytes(byte_size(chunk_data))}")
            
            # Check if this is a CACNK wrapped chunk or raw compressed data
            case CasyncFormat.parse_chunk(chunk_data) do
              {:ok, %{header: header, data: compressed_data}} ->
                # Standard CACNK format with wrapper header
                IO.puts("🗜️  Compression: #{header.compression}")
                
                case decompress_chunk_data(compressed_data, header.compression) do
                  {:ok, decompressed_data} ->
                    IO.puts("✅ Successfully decompressed!")
                    IO.puts("📊 Decompressed size: #{format_bytes(byte_size(decompressed_data))}")
                    
                    # Save for inspection
                    chunk_output = Path.join(output_dir, "chunk_#{String.slice(chunk_id_hex, 0, 8)}.bin")
                    File.write!(chunk_output, decompressed_data)
                    IO.puts("💾 Saved to: #{chunk_output}")
                    
                  {:error, reason} ->
                    IO.puts("❌ Decompression failed: #{inspect(reason)}")
                end
                
              {:error, "Invalid chunk file magic"} ->
                # Try direct ZSTD decompression (raw compressed data without CACNK wrapper)
                IO.puts("🔍 No CACNK header found, trying raw ZSTD decompression...")
                
                case decompress_chunk_data(chunk_data, :zstd) do
                  {:ok, decompressed_data} ->
                    IO.puts("✅ Successfully decompressed raw ZSTD data!")
                    IO.puts("📊 Compressed size: #{format_bytes(byte_size(chunk_data))}")
                    IO.puts("📊 Decompressed size: #{format_bytes(byte_size(decompressed_data))}")
                    
                    # Save for inspection
                    chunk_output = Path.join(output_dir, "chunk_#{String.slice(chunk_id_hex, 0, 8)}.bin")
                    File.write!(chunk_output, decompressed_data)
                    IO.puts("💾 Saved to: #{chunk_output}")
                    
                  {:error, reason} ->
                    IO.puts("❌ Raw ZSTD decompression failed: #{inspect(reason)}")
                    
                    # Try as uncompressed data
                    IO.puts("🔍 Trying as uncompressed data...")
                    chunk_output = Path.join(output_dir, "chunk_#{String.slice(chunk_id_hex, 0, 8)}_raw.bin")
                    File.write!(chunk_output, chunk_data)
                    IO.puts("💾 Saved raw data to: #{chunk_output}")
                end
                
              {:error, reason} ->
                IO.puts("❌ Failed to parse chunk: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            IO.puts("❌ Failed to read chunk: #{inspect(reason)}")
        end
      else
        IO.puts("❌ Chunk not found in local store")
        
        # List what's actually in the store
        if File.exists?(store_path) do
          IO.puts("\n📋 Store contents:")
          case File.ls(store_path) do
            {:ok, entries} ->
              entries 
              |> Enum.sort()
              |> Enum.take(10)
              |> Enum.each(fn entry ->
                entry_path = Path.join(store_path, entry)
                if File.dir?(entry_path) do
                  case File.ls(entry_path) do
                    {:ok, files} -> IO.puts("  📁 #{entry}/ (#{length(files)} files)")
                    _ -> IO.puts("  📁 #{entry}/ (error reading)")
                  end
                else
                  IO.puts("  📄 #{entry}")
                end
              end)
            _ -> IO.puts("  (error reading store)")
          end
        end
      end
    end
  end

  defp decompress_chunk_data(data, :zstd) do
    case :ezstd.decompress(data) do
      result when is_binary(result) -> {:ok, result}
      error -> {:error, {:zstd_error, error}}
    end
  end

  defp decompress_chunk_data(data, :none), do: {:ok, data}
  defp decompress_chunk_data(_data, compression), do: {:error, {:unsupported_compression, compression}}

  defp print_detailed_info(data) do
    IO.puts("\n=== DETAILED ANALYSIS ===")
    archive_type = case data.format do
      :caibx -> "blob (single file)"
      :caidx -> "directory tree"
      :catar -> "tar-like archive"
      other -> "#{other}"
    end
    
    IO.puts("📄 Format: #{data.format} - #{archive_type}")
    
    case data.format do
      :catar ->
        # CATAR format has different structure
        IO.puts("📊 Archive Information:")
        IO.puts("  Type: #{archive_type}")
        IO.puts("  Total Size: #{format_bytes(data.total_size)}")
        IO.puts("  Files: #{length(data.files)}")
        IO.puts("  Directories: #{length(data.directories)}")
        
        if length(data.files) > 0 do
          total_content_size = data.files
          |> Enum.filter(&Map.get(&1, :content))
          |> Enum.map(fn file -> 
            content = Map.get(file, :content)
            if content, do: byte_size(content), else: 0
          end)
          |> Enum.sum()
          
          IO.puts("  Content Size: #{format_bytes(total_content_size)}")
          
          IO.puts("\n📁 Sample Files:")
          data.files
          |> Enum.take(10)
          |> Enum.with_index()
          |> Enum.each(fn {file, index} ->
            content = Map.get(file, :content)
            size_str = if content, do: format_bytes(byte_size(content)), else: "no content"
            mode_str = if Map.get(file, :mode), do: Integer.to_string(Map.get(file, :mode), 8), else: "unknown"
            file_type = case file.type do
              :device -> " [device #{file.major},#{file.minor}]"
              type -> " [#{type}]"
            end
            name = Map.get(file, :name) || Map.get(file, :path, "unnamed")
            IO.puts("#{String.pad_leading(to_string(index + 1), 3)}: #{name}#{file_type} | #{size_str} (mode: #{mode_str})")
          end)
          
          if length(data.files) > 10 do
            IO.puts("... and #{length(data.files) - 10} more files")
          end
        end
        
        if length(data.directories) > 0 do
          IO.puts("\n📂 Sample Directories:")
          data.directories
          |> Enum.take(10)
          |> Enum.with_index()
          |> Enum.each(fn {dir, index} ->
            mode_str = if Map.get(dir, :mode), do: Integer.to_string(Map.get(dir, :mode), 8), else: "unknown"
            name = Map.get(dir, :name) || Map.get(dir, :path, "unnamed")
            IO.puts("#{String.pad_leading(to_string(index + 1), 3)}: #{name} (mode: #{mode_str})")
          end)
          
          if length(data.directories) > 10 do
            IO.puts("... and #{length(data.directories) - 10} more directories")
          end
        end
        
      format when format in [:caidx, :caibx] ->
        # Index format has chunks
        IO.puts("🔖 Header Version: #{data.header.version}")
        IO.puts("🏁 Feature Flags: 0x#{Integer.to_string(data.feature_flags, 16)} (#{data.feature_flags})")
        
        IO.puts("\n📏 Chunk Size Configuration:")
        IO.puts("  Minimum: #{format_bytes(data.chunk_size_min)}")
        IO.puts("  Average: #{format_bytes(data.chunk_size_avg)}")
        IO.puts("  Maximum: #{format_bytes(data.chunk_size_max)}")
        
        IO.puts("\n📊 Archive Information:")
        IO.puts("  Type: #{archive_type}")
        IO.puts("  Total Size: #{format_bytes(data.header.total_size)}")
        IO.puts("  Chunk Count: #{data.header.chunk_count}")
        
        if data.header.chunk_count > 0 do
          chunk_sizes = Enum.map(data.chunks, & &1.size)
          avg_size = Enum.sum(chunk_sizes) / length(chunk_sizes)
          min_size = Enum.min(chunk_sizes)
          max_size = Enum.max(chunk_sizes)
          
          IO.puts("\n📈 Actual Chunk Statistics:")
          IO.puts("  Minimum Size: #{format_bytes(min_size)}")
          IO.puts("  Average Size: #{format_bytes(round(avg_size))}")
          IO.puts("  Maximum Size: #{format_bytes(max_size)}")
        end
        
        IO.puts("\n🧩 Sample Chunks:")
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
  end
  
  defp format_bytes(bytes) when is_integer(bytes) do
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
  
  defp format_bytes(_), do: "unknown size"
  
  defp save_parsed_data(data, output_dir) do
    # Save as JSON
    json_file = Path.join(output_dir, "parsed_data.json")
    
    json_data = case data.format do
      :catar ->
        # CATAR format has different structure
        %{
          format: data.format,
          total_size: data.total_size,
          files: Enum.map(data.files, fn file ->
            content = Map.get(file, :content)
            %{
              path: Map.get(file, :path) || Map.get(file, :name, "unnamed"),
              size: if(content, do: byte_size(content), else: 0),
              mode: Map.get(file, :mode),
              type: Map.get(file, :type, :unknown),
              has_content: not is_nil(content)
            }
          end),
          directories: Enum.map(data.directories, fn dir ->
            %{
              path: Map.get(dir, :path) || Map.get(dir, :name, "unnamed"),
              mode: Map.get(dir, :mode)
            }
          end),
          element_count: length(data.elements)
        }
        
      format when format in [:caidx, :caibx] ->
        # Index format structure
        %{
          format: data.format,
          header: data.header,
          feature_flags: data.feature_flags,
          chunk_size_min: data.chunk_size_min,
          chunk_size_avg: data.chunk_size_avg,
          chunk_size_max: data.chunk_size_max,
          chunks: Enum.map(data.chunks, fn chunk ->
            %{
              chunk_id: Base.encode16(chunk.chunk_id, case: :lower),
              offset: chunk.offset,
              size: chunk.size
            }
          end)
        }
    end
    
    File.write!(json_file, Jason.encode!(json_data, pretty: true))
    IO.puts("💾 Saved JSON: #{json_file}")
    
    case data.format do
      :catar ->
        # Save file list for CATAR
        files_file = Path.join(output_dir, "files.txt")
        if length(data.files) > 0 do
          file_lines = data.files
          |> Enum.map(fn file ->
            content = Map.get(file, :content)
            size_str = if content, do: byte_size(content), else: 0
            mode_str = if Map.get(file, :mode), do: Integer.to_string(Map.get(file, :mode), 8), else: "unknown"
            path = Map.get(file, :path) || Map.get(file, :name, "unnamed")
            file_type = case Map.get(file, :type) do
              :device -> " [device #{Map.get(file, :major, "?")},#{Map.get(file, :minor, "?")}]"
              type when type != nil -> " [#{type}]"
              _ -> ""
            end
            "#{path}#{file_type} (#{size_str} bytes, mode: #{mode_str})"
          end)
          
          File.write!(files_file, Enum.join(file_lines, "\n"))
          IO.puts("💾 Saved file list: #{files_file}")
        else
          File.write!(files_file, "No files found in archive")
          IO.puts("💾 Saved empty file list: #{files_file}")
        end
        
        # Save directory list for CATAR
        dirs_file = Path.join(output_dir, "directories.txt")
        if length(data.directories) > 0 do
          dir_lines = data.directories
          |> Enum.map(fn dir ->
            mode_str = if Map.get(dir, :mode), do: Integer.to_string(Map.get(dir, :mode), 8), else: "unknown"
            path = Map.get(dir, :path) || Map.get(dir, :name, "unnamed")
            "#{path} (mode: #{mode_str})"
          end)
          
          File.write!(dirs_file, Enum.join(dir_lines, "\n"))
          IO.puts("💾 Saved directory list: #{dirs_file}")
        else
          File.write!(dirs_file, "No directories found in archive")
          IO.puts("💾 Saved empty directory list: #{dirs_file}")
        end
        
      format when format in [:caidx, :caibx] ->
        # Save chunk list for index formats
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
          IO.puts("💾 Saved chunks: #{chunks_file}")
        else
          File.write!(chunks_file, "No chunks found in index")
          IO.puts("💾 Saved empty chunk list: #{chunks_file}")
        end
    end
  end
  
  defp generate_chunk_script(data, output_dir) do
    script_file = Path.join(output_dir, "download_chunks.sh")
    
    base_url = "https://raw.githack.com/V-Sekai/casync-v-sekai-game/main/store"
    
    script_content = [
      "#!/bin/bash",
      "# Chunk download script",
      "# Generated from CAIDX analysis",
      "",
      "CHUNK_DIR=\"./chunks\"",
      "BASE_URL=\"#{base_url}\"",
      "",
      "mkdir -p \"$CHUNK_DIR\"",
      "cd \"$CHUNK_DIR\"",
      "",
      "echo \"Downloading sample chunks...\"",
      ""
    ]
    
    chunk_commands = data.chunks
    |> Enum.take(3)  # Limit to first 3 for sample
    |> Enum.with_index()
    |> Enum.map(fn {chunk, index} ->
      chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
      chunk_dir = String.slice(chunk_id_hex, 0, 4)
      chunk_file = "#{chunk_id_hex}.cacnk"
      
      [
        "echo \"Downloading chunk #{index + 1}: #{chunk_id_hex}\"",
        "mkdir -p \"#{chunk_dir}\"",
        "curl -L \"${BASE_URL}/#{chunk_dir}/#{chunk_file}\" -o \"#{chunk_dir}/#{chunk_file}\" 2>/dev/null || echo \"  Failed\""
      ]
    end)
    |> List.flatten()
    
    all_content = script_content ++ chunk_commands ++ ["", "echo \"Sample download complete\""]
    File.write!(script_file, Enum.join(all_content, "\n"))
    File.chmod!(script_file, 0o755)
    
    IO.puts("💾 Generated script: #{script_file}")
  end
  
  defp extract_catar_structure(parsed_data, output_dir) do
    IO.puts("\n=== CATAR ARCHIVE EXTRACTION ===")
    
    # Create extraction directory
    extract_dir = Path.join(output_dir, "extracted")
    File.mkdir_p!(extract_dir)
    
    # Extract files and directories
    IO.puts("📁 Directories found: #{length(parsed_data.directories)}")
    Enum.each(parsed_data.directories, fn dir ->
      path = Map.get(dir, :path) || Map.get(dir, :name, "unnamed")
      dir_path = Path.join(extract_dir, path)
      File.mkdir_p!(dir_path)
      mode_str = if Map.get(dir, :mode), do: Integer.to_string(Map.get(dir, :mode), 8), else: "unknown"
      IO.puts("  📂 #{path} (mode: #{mode_str})")
    end)
    
    IO.puts("📄 Files found: #{length(parsed_data.files)}")
    Enum.each(parsed_data.files, fn file ->
      path = Map.get(file, :path) || Map.get(file, :name, "unnamed")
      file_path = Path.join(extract_dir, path)
      
      # Ensure parent directory exists
      parent_dir = Path.dirname(file_path)
      File.mkdir_p!(parent_dir)
      
      content = Map.get(file, :content)
      
      # Write file content if available
      if content do
        File.write!(file_path, content)
        
        # Set file permissions if available
        mode = Map.get(file, :mode)
        if mode do
          # Convert mode to octal permissions (mask to get standard permissions)
          perm = mode &&& 0o777
          if perm > 0 do
            File.chmod!(file_path, perm)
          end
        end
        
        mode_str = if mode, do: Integer.to_string(mode, 8), else: "0644"
        IO.puts("  📝 #{path} (#{format_bytes(byte_size(content))}, mode: #{mode_str})")
      else
        file_type = case Map.get(file, :type) do
          :device -> " [device #{Map.get(file, :major, "?")},#{Map.get(file, :minor, "?")}]"
          type when type != nil -> " [#{type}]"
          _ -> ""
        end
        IO.puts("  📝 #{path}#{file_type} (no content available)")
      end
    end)
    
    # Save structure info
    structure_file = Path.join(output_dir, "catar_structure.json")
    structure_info = %{
      format: "catar",
      total_size: parsed_data.total_size,
      directories: Enum.map(parsed_data.directories, fn dir ->
        %{
          path: Map.get(dir, :path) || Map.get(dir, :name, "unnamed"),
          mode: Map.get(dir, :mode)
        }
      end),
      files: Enum.map(parsed_data.files, fn file ->
        content = Map.get(file, :content)
        %{
          path: Map.get(file, :path) || Map.get(file, :name, "unnamed"),
          size: if(content, do: byte_size(content), else: 0),
          mode: Map.get(file, :mode),
          type: Map.get(file, :type),
          has_content: not is_nil(content)
        }
      end)
    }
    
    File.write!(structure_file, Jason.encode!(structure_info, pretty: true))
    IO.puts("💾 Structure saved to: #{structure_file}")
    IO.puts("📁 Files extracted to: #{extract_dir}")
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
    IO.puts("💾 Saved hex dump: #{hex_file}")
    
    # Basic header analysis
    if byte_size(binary_data) >= 48 do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        _rest::binary>> = binary_data
        
      IO.puts("\n🔍 Header Analysis:")
      IO.puts("  Size Field: #{size_field}")
      IO.puts("  Type Field: 0x#{Integer.to_string(type_field, 16)}")
      IO.puts("  Feature Flags: #{feature_flags}")
      IO.puts("  Chunk Size Min: #{chunk_size_min}")
      IO.puts("  Chunk Size Avg: #{chunk_size_avg}")
      IO.puts("  Chunk Size Max: #{chunk_size_max}")
    end
  end
end
