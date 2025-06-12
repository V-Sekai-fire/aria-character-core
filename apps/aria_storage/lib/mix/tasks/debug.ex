defmodule Mix.Tasks.CasyncDebug do
  @moduledoc """
  Mix task for debugging casync files parser.

  This task provides comprehensive debugging capabilities for all casync file formats:
  - .caibx (Content Archive Index for Blobs)
  - .caidx (Content Archive Index for Directories) 
  - .cacnk (Compressed Chunk files)
  - .catar (Archive Container format)

  ## Usage

      mix casync_debug [options] <file_path>

  ## Options

      --format FORMAT     Force specific format detection (caibx, caidx, cacnk, catar)
      --output FORMAT     Output format (text, json, hex) [default: text]
      --roundtrip         Test roundtrip encoding (parse -> encode -> compare)
      --hex-diff          Show hex diff for roundtrip comparison
      --elements          Show detailed element breakdown (for CATAR files)
      --chunks            Show detailed chunk information (for index files)
      --verbose           Enable verbose output
      --help              Show this help message

  ## Examples

      # Basic file analysis
      mix casync_debug apps/aria_storage/test/support/testdata/flat.catar

      # Test roundtrip encoding with hex diff
      mix casync_debug --roundtrip --hex-diff flat.catar

      # Force format detection and show detailed elements
      mix casync_debug --format catar --elements --verbose complex.catar

      # JSON output for programmatic use
      mix casync_debug --output json --chunks index.caibx

      # Compare multiple files
      mix casync_debug --roundtrip *.catar

  """

  use Mix.Task
  alias AriaStorage.Parsers.CasyncFormat

  @shortdoc "Debug and analyze casync files"

  @switches [
    format: :string,
    output: :string,
    roundtrip: :boolean,
    hex_diff: :boolean,
    elements: :boolean,
    chunks: :boolean,
    verbose: :boolean,
    help: :boolean
  ]

  @aliases [
    f: :format,
    o: :output,
    r: :roundtrip,
    h: :help,
    v: :verbose
  ]

  def run(args) do
    Application.ensure_all_started(:aria_storage)
    
    {opts, files, invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    case {opts[:help], invalid, files} do
      {true, _, _} ->
        print_help()

      {_, invalid, _} when invalid != [] ->
        Mix.shell().error("Invalid options: #{Enum.join(invalid, ", ")}")

      {_, _, []} ->
        Mix.shell().error("No files specified. Use --help for usage information.")

      {_, _, files} ->
        # Process each file
        results = Enum.map(files, fn file_path ->
          process_file(file_path, opts)
        end)

        # Summary for multiple files
        case length(files) do
          n when n > 1 -> print_summary(results, opts)
          _ -> :ok
        end
    end
  end

  defp process_file(file_path, opts) do
    case File.exists?(file_path) do
      false ->
        Mix.shell().error("File not found: #{file_path}")
        {:error, :file_not_found}

      true ->
        case opts[:verbose] do
          true -> print_separator()
          _ -> :ok
        end
        
        Mix.shell().info("=== Analyzing #{Path.basename(file_path)} ===")

        case File.read(file_path) do
          {:ok, binary_data} ->
            file_size = byte_size(binary_data)
            Mix.shell().info("File size: #{format_bytes(file_size)}")
            
            # Detect or use forced format
            format_result = case opts[:format] do
              nil -> 
                case CasyncFormat.detect_format(binary_data) do
                  {:ok, format} -> {:ok, format}
                  {:error, reason} -> {:error, reason}
                end
              forced_format when forced_format in ["caibx", "caidx", "cacnk", "catar"] ->
                {:ok, String.to_atom(forced_format)}
              invalid_format ->
                {:error, "Invalid format: #{invalid_format}"}
            end

            case format_result do
              {:ok, format} ->
                Mix.shell().info("Detected format: #{format}")
                analyze_file(binary_data, format, file_path, opts)

              {:error, reason} ->
                Mix.shell().error("Format detection failed: #{reason}")
                {:error, reason}
            end

          {:error, reason} ->
            Mix.shell().error("Failed to read file: #{reason}")
            {:error, reason}
        end
    end
  end

  defp analyze_file(binary_data, format, file_path, opts) do
    # Parse the file
    parse_result = case format do
      format when format in [:caibx, :caidx] -> CasyncFormat.parse_index(binary_data)
      :cacnk -> CasyncFormat.parse_chunk(binary_data)
      :catar -> CasyncFormat.parse_archive(binary_data)
    end

    case parse_result do
      {:ok, parsed} ->
        Mix.shell().info("✓ Parsing successful")
        
        # Show analysis based on output format
        case opts[:output] do
          "json" -> print_json_analysis(parsed, opts)
          "hex" -> print_hex_analysis(binary_data, parsed, opts)
          _ -> print_text_analysis(parsed, format, opts)
        end

        # Perform roundtrip test if requested
        roundtrip_result = case opts[:roundtrip] do
          true -> test_roundtrip(binary_data, parsed, format, opts)
          _ -> nil
        end

        {:ok, %{
          file_path: file_path,
          format: format,
          size: byte_size(binary_data),
          parsed: parsed,
          roundtrip: roundtrip_result
        }}

      {:error, reason} ->
        Mix.shell().error("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  defp print_text_analysis(parsed, format, opts) do
    case format do
      format when format in [:caibx, :caidx] ->
        print_index_analysis(parsed, opts)
      :cacnk ->
        print_chunk_analysis(parsed, opts)
      :catar ->
        print_archive_analysis(parsed, opts)
    end
  end

  defp print_index_analysis(parsed, opts) do
    Mix.shell().info("Format: #{parsed.format}")
    Mix.shell().info("Feature flags: 0x#{Integer.to_string(parsed.feature_flags, 16)}")
    Mix.shell().info("Chunk size - min: #{parsed.chunk_size_min}, avg: #{parsed.chunk_size_avg}, max: #{parsed.chunk_size_max}")
    Mix.shell().info("Total chunks: #{length(parsed.chunks)}")
    
    case parsed.chunks do
      [] -> :ok
      chunks ->
        total_size = chunks |> Enum.map(& &1.size) |> Enum.sum()
        avg_chunk_size = div(total_size, length(chunks))
        Mix.shell().info("Total content size: #{format_bytes(total_size)}")
        Mix.shell().info("Average chunk size: #{format_bytes(avg_chunk_size)}")
    end

    case {opts[:chunks], opts[:verbose]} do
      {true, true} ->
        Mix.shell().info("\n--- Chunk Details ---")
        parsed.chunks
        |> Enum.with_index()
        |> Enum.each(fn {chunk, index} ->
          chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower)
          Mix.shell().info("Chunk #{index + 1}: offset=#{chunk.offset}, size=#{chunk.size}, id=#{String.slice(chunk_id_hex, 0, 16)}...")
        end)
      _ -> :ok
    end
  end

  defp print_chunk_analysis(parsed, opts) do
    Mix.shell().info("Magic: #{parsed.magic}")
    Mix.shell().info("Compression: #{parsed.header.compression}")
    Mix.shell().info("Compressed size: #{format_bytes(parsed.header.compressed_size)}")
    Mix.shell().info("Uncompressed size: #{format_bytes(parsed.header.uncompressed_size)}")
    Mix.shell().info("Flags: 0x#{Integer.to_string(parsed.header.flags, 16)}")
    
    case parsed.header.compressed_size do
      0 -> :ok
      compressed_size ->
        ratio = Float.round(parsed.header.uncompressed_size / compressed_size, 2)
        Mix.shell().info("Compression ratio: #{ratio}:1")
    end

    case opts[:verbose] do
      true -> Mix.shell().info("Data size: #{format_bytes(byte_size(parsed.data))}")
      _ -> :ok
    end
  end

  defp print_archive_analysis(parsed, opts) do
    Mix.shell().info("Format: #{parsed.format}")
    Mix.shell().info("Total elements: #{length(parsed.elements)}")
    Mix.shell().info("Files: #{length(parsed.files)}")
    Mix.shell().info("Directories: #{length(parsed.directories)}")

    # Element type breakdown
    element_counts = Enum.reduce(parsed.elements, %{}, fn element, acc ->
      type = Map.get(element, :type, :unknown)
      Map.update(acc, type, 1, &(&1 + 1))
    end)

    Mix.shell().info("\n--- Element Breakdown ---")
    Enum.each(element_counts, fn {type, count} ->
      Mix.shell().info("#{type}: #{count}")
    end)

    case opts[:elements] do
      true -> print_element_details(parsed.elements, opts)
      _ -> :ok
    end

    case {opts[:verbose], parsed.files} do
      {true, files} when files != [] ->
        Mix.shell().info("\n--- File Details ---")
        Enum.each(files, fn file ->
          type_info = case file.type do
            :file -> "file (#{format_bytes(byte_size(file.content || ""))})"
            :symlink -> "symlink -> #{file.target}"
            :device -> "device #{file.major}:#{file.minor}"
            other -> to_string(other)
          end
          
          mode_str = Integer.to_string(file.mode, 8)
          Mix.shell().info("#{file.path}: #{type_info}, mode=#{mode_str}, uid=#{file.uid}, gid=#{file.gid}")
        end)
      _ -> :ok
    end
  end

  defp print_element_details(elements, _opts) do
    Mix.shell().info("\n--- Element Details ---")
    
    elements
    |> Enum.with_index()
    |> Enum.each(fn {element, index} ->
      case element do
        %{type: :entry, size: size, mode: mode, uid: uid, gid: gid} ->
          mode_str = Integer.to_string(mode, 8)
          Mix.shell().info("#{index + 1}. Entry: size=#{size}, mode=#{mode_str}, uid=#{uid}, gid=#{gid}")
        
        %{type: :filename, name: name} ->
          Mix.shell().info("#{index + 1}. Filename: #{inspect(name)}")
        
        %{type: :payload, size: size} ->
          Mix.shell().info("#{index + 1}. Payload: #{format_bytes(size)}")
        
        %{type: :symlink, target: target} ->
          Mix.shell().info("#{index + 1}. Symlink: -> #{inspect(target)}")
        
        %{type: :device, major: major, minor: minor} ->
          Mix.shell().info("#{index + 1}. Device: #{major}:#{minor}")
        
        %{type: :user, name: name} ->
          Mix.shell().info("#{index + 1}. User: #{inspect(name)}")
        
        %{type: :group, name: name} ->
          Mix.shell().info("#{index + 1}. Group: #{inspect(name)}")
        
        %{type: :selinux, context: context} ->
          context_short = case String.length(context) do
            len when len > 40 -> String.slice(context, 0, 37) <> "..."
            _ -> context
          end
          Mix.shell().info("#{index + 1}. SELinux: #{inspect(context_short)}")
        
        %{type: :goodbye, items: items} ->
          Mix.shell().info("#{index + 1}. Goodbye: #{length(items)} items")
        
        %{type: type} ->
          Mix.shell().info("#{index + 1}. #{type}")
      end
    end)
  end

  defp print_json_analysis(parsed, _opts) do
    json_safe_parsed = CasyncFormat.to_json_safe(parsed)
    json_output = Jason.encode!(json_safe_parsed, pretty: true)
    Mix.shell().info(json_output)
  end

  defp print_hex_analysis(binary_data, _parsed, _opts) do
    Mix.shell().info("\n--- Hex Dump (first 256 bytes) ---")
    hex_data = binary_data |> binary_part(0, min(256, byte_size(binary_data)))
    print_hex_dump(hex_data)
  end

  defp test_roundtrip(original_data, parsed, format, opts) do
    Mix.shell().info("\n--- Roundtrip Test ---")
    
    encode_result = case format do
      format when format in [:caibx, :caidx] -> CasyncFormat.encode_index(parsed)
      :cacnk -> CasyncFormat.encode_chunk(parsed)
      :catar -> CasyncFormat.encode_archive(parsed)
    end

    case encode_result do
      {:ok, encoded_data} ->
        original_size = byte_size(original_data)
        encoded_size = byte_size(encoded_data)
        
        Mix.shell().info("Original size: #{format_bytes(original_size)}")
        Mix.shell().info("Encoded size:  #{format_bytes(encoded_size)}")
        
        result = case original_data == encoded_data do
          true ->
            Mix.shell().info("✓ Perfect bit-exact roundtrip!")
            :perfect_match
          false ->
            size_diff = encoded_size - original_size
            Mix.shell().error("⚠ Content differs (size diff: #{size_diff} bytes)")
            
            case opts[:hex_diff] do
              true ->
                comparison = CasyncFormat.print_hex_diff(original_data, encoded_data)
                {:differences, comparison}
              _ ->
                {:differences, %{size_diff: size_diff}}
            end
        end

        {:ok, result}

      {:error, reason} ->
        Mix.shell().error("✗ Encoding failed: #{reason}")
        {:error, reason}
    end
  end

  defp print_summary(results, _opts) do
    Mix.shell().info("\n" <> String.duplicate("=", 50))
    Mix.shell().info("SUMMARY")
    Mix.shell().info(String.duplicate("=", 50))

    successful = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    total = length(results)
    Mix.shell().info("Processed: #{successful}/#{total} files successfully")

    # Group by format
    format_counts = results
    |> Enum.filter(fn
      {:ok, %{format: _}} -> true
      _ -> false
    end)
    |> Enum.group_by(fn {:ok, %{format: format}} -> format end)
    |> Enum.map(fn {format, files} -> {format, length(files)} end)
    |> Enum.sort()

    if format_counts != [] do
      Mix.shell().info("\nBy format:")
      Enum.each(format_counts, fn {format, count} ->
        Mix.shell().info("  #{format}: #{count} files")
      end)
    end

    # Roundtrip results
    roundtrip_results = results
    |> Enum.filter(fn
      {:ok, %{roundtrip: {:ok, _}}} -> true
      _ -> false
    end)
    |> Enum.map(fn {:ok, %{roundtrip: {:ok, result}}} -> result end)

    if roundtrip_results != [] do
      perfect_count = Enum.count(roundtrip_results, &(&1 == :perfect_match))
      total_roundtrip = length(roundtrip_results)
      
      Mix.shell().info("\nRoundtrip results:")
      Mix.shell().info("  Perfect matches: #{perfect_count}/#{total_roundtrip}")
      
      if perfect_count < total_roundtrip do
        diff_count = total_roundtrip - perfect_count
        Mix.shell().info("  With differences: #{diff_count}/#{total_roundtrip}")
      end
    end
  end

  defp print_hex_dump(binary) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.each(fn {bytes, row} ->
      offset = row * 16
      hex_part = bytes 
        |> Enum.map(&(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
        |> Enum.join(" ")
        |> String.pad_trailing(47)
      
      ascii_part = bytes
        |> Enum.map(fn b -> if b >= 32 and b <= 126, do: <<b>>, else: "." end)
        |> Enum.join()
      
      Mix.shell().info("#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0") |> String.upcase()}: #{hex_part} |#{ascii_part}|")
    end)
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024 do
    "#{Float.round(bytes / 1024, 1)} KB"
  end
  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024 do
    "#{Float.round(bytes / (1024 * 1024), 1)} MB"
  end
  defp format_bytes(bytes) do
    "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
  end

  defp print_separator do
    Mix.shell().info("")
  end

  defp print_help do
    Mix.shell().info(@moduledoc)
  end
end
