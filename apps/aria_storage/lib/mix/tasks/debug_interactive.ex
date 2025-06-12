defmodule Mix.Tasks.CasyncDebugInteractive do
  @moduledoc """
  Interactive Mix task for debugging casync files parser.

  This task provides an interactive debugging session where you can explore
  casync files step by step, compare different files, and test various scenarios.

  ## Usage

      mix casync_debug_interactive [file_path]

  ## Interactive Commands

      help              Show available commands
      load <file>       Load a new casync file
      info              Show current file information
      parse             Re-parse current file
      elements          Show all elements (CATAR files)
      element <n>       Show specific element details
      chunks            Show all chunks (index files)  
      chunk <n>         Show specific chunk details
      roundtrip         Test roundtrip encoding
      compare <file>    Compare with another file
      hex [offset]      Show hex dump (optionally from offset)
      export <format>   Export analysis (json, hex, text)
      quit              Exit interactive mode

  ## Examples

      # Start interactive session
      mix casync_debug_interactive

      # Start with a specific file
      mix casync_debug_interactive flat.catar

  """

  use Mix.Task
  alias AriaStorage.Parsers.CasyncFormat

  @shortdoc "Interactive debugger for casync files"

  defmodule State do
    defstruct [
      :file_path,
      :binary_data,
      :format,
      :parsed_data,
      :parse_error
    ]
  end

  def run(args) do
    Application.ensure_all_started(:aria_storage)
    
    initial_file = case args do
      [file_path] when file_path != "" -> file_path
      _ -> nil
    end

    state = %State{}
    
    Mix.shell().info("=== AriaStorage Interactive Debugger ===")
    Mix.shell().info("Type 'help' for available commands")
    
    # Load initial file if provided
    state = if initial_file do
      Mix.shell().info("Loading initial file: #{initial_file}")
      load_file(state, initial_file)
    else
      Mix.shell().info("No file loaded. Use 'load <file>' to start.")
      state
    end

    # Start interactive loop
    interactive_loop(state)
  end

  defp interactive_loop(state) do
    prompt = case state.file_path do
      nil -> "aria_debug> "
      file_path -> "aria_debug[#{Path.basename(file_path)}]> "
    end

    case Mix.shell().prompt(prompt) |> String.trim() do
      "quit" -> 
        Mix.shell().info("Goodbye!")
        
      "help" ->
        print_help_commands()
        interactive_loop(state)
        
      "info" ->
        print_file_info(state)
        interactive_loop(state)
        
      "parse" ->
        state = reparse_current_file(state)
        interactive_loop(state)
        
      "elements" ->
        print_elements(state)
        interactive_loop(state)
        
      "chunks" ->
        print_chunks(state)
        interactive_loop(state)
        
      "roundtrip" ->
        test_roundtrip_interactive(state)
        interactive_loop(state)
        
      "hex" ->
        print_hex_dump_interactive(state, 0, 256)
        interactive_loop(state)
        
      "" ->
        interactive_loop(state)
        
      command ->
        state = handle_command(state, command)
        interactive_loop(state)
    end
  end

  defp handle_command(state, command) do
    case String.split(command, " ", parts: 2) do
      ["load", file_path] ->
        load_file(state, String.trim(file_path))
        
      ["element", index_str] ->
        case Integer.parse(index_str) do
          {index, ""} -> 
            print_element_details(state, index - 1)  # Convert to 0-based
            state
          _ ->
            Mix.shell().error("Invalid element index: #{index_str}")
            state
        end
        
      ["chunk", index_str] ->
        case Integer.parse(index_str) do
          {index, ""} -> 
            print_chunk_details(state, index - 1)  # Convert to 0-based
            state
          _ ->
            Mix.shell().error("Invalid chunk index: #{index_str}")
            state
        end
        
      ["hex", offset_str] ->
        case Integer.parse(offset_str) do
          {offset, ""} -> 
            print_hex_dump_interactive(state, offset, 256)
            state
          _ ->
            Mix.shell().error("Invalid hex offset: #{offset_str}")
            state
        end
        
      ["compare", file_path] ->
        compare_files_interactive(state, String.trim(file_path))
        state
        
      ["export", format] ->
        export_analysis(state, String.trim(format))
        state
        
      [unknown_command | _] ->
        Mix.shell().error("Unknown command: #{unknown_command}")
        Mix.shell().info("Type 'help' for available commands")
        state
    end
  end

  defp load_file(state, file_path) do
    case File.exists?(file_path) do
      false ->
        Mix.shell().error("File not found: #{file_path}")
        state
      true ->
        case File.read(file_path) do
          {:ok, binary_data} ->
            Mix.shell().info("Loaded: #{file_path} (#{format_bytes(byte_size(binary_data))})")
            
            # Detect format
            format_result = CasyncFormat.detect_format(binary_data)
            
            case format_result do
              {:ok, format} ->
                Mix.shell().info("Detected format: #{format}")
                
                # Parse the file
                parse_result = case format do
                  format when format in [:caibx, :caidx] -> CasyncFormat.parse_index(binary_data)
                  :cacnk -> CasyncFormat.parse_chunk(binary_data)
                  :catar -> CasyncFormat.parse_archive(binary_data)
                end

                case parse_result do
                  {:ok, parsed_data} ->
                    Mix.shell().info("✓ Parsing successful")
                    %State{
                      file_path: file_path,
                      binary_data: binary_data,
                      format: format,
                      parsed_data: parsed_data,
                      parse_error: nil
                    }
                    
                  {:error, reason} ->
                    Mix.shell().error("✗ Parsing failed: #{reason}")
                    %State{
                      file_path: file_path,
                      binary_data: binary_data,
                      format: format,
                      parsed_data: nil,
                      parse_error: reason
                    }
                end
                
              {:error, reason} ->
                Mix.shell().error("Format detection failed: #{reason}")
                %State{
                  file_path: file_path,
                  binary_data: binary_data,
                  format: nil,
                  parsed_data: nil,
                  parse_error: reason
                }
            end
            
          {:error, reason} ->
            Mix.shell().error("Failed to read file: #{reason}")
            state
        end
    end
  end

  defp reparse_current_file(state) do
    case state.file_path do
      nil ->
        Mix.shell().error("No file loaded")
        state
        
      file_path ->
        Mix.shell().info("Re-parsing #{Path.basename(file_path)}...")
        load_file(%State{}, file_path)
    end
  end

  defp print_file_info(state) do
    case state do
      %State{file_path: nil} ->
        Mix.shell().info("No file loaded")
        
      %State{file_path: file_path, binary_data: binary_data, format: format, parsed_data: parsed_data, parse_error: parse_error} ->
        Mix.shell().info("File: #{file_path}")
        Mix.shell().info("Size: #{format_bytes(byte_size(binary_data))}")
        Mix.shell().info("Format: #{format || "unknown"}")
        
        case {parsed_data, parse_error} do
          {parsed_data, nil} when not is_nil(parsed_data) ->
            Mix.shell().info("Status: ✓ Parsed successfully")
            print_parsed_summary(parsed_data, format)
            
          {nil, reason} ->
            Mix.shell().info("Status: ✗ Parse failed - #{reason}")
            
          _ ->
            Mix.shell().info("Status: Unknown")
        end
    end
  end

  defp print_parsed_summary(parsed_data, format) do
    case format do
      format when format in [:caibx, :caidx] ->
        Mix.shell().info("Chunks: #{length(parsed_data.chunks)}")
        if parsed_data.chunks != [] do
          total_size = parsed_data.chunks |> Enum.map(& &1.size) |> Enum.sum()
          Mix.shell().info("Total content: #{format_bytes(total_size)}")
        end
        
      :cacnk ->
        Mix.shell().info("Compression: #{parsed_data.header.compression}")
        Mix.shell().info("Compressed: #{format_bytes(parsed_data.header.compressed_size)}")
        Mix.shell().info("Uncompressed: #{format_bytes(parsed_data.header.uncompressed_size)}")
        
      :catar ->
        Mix.shell().info("Elements: #{length(parsed_data.elements)}")
        Mix.shell().info("Files: #{length(parsed_data.files)}")
        Mix.shell().info("Directories: #{length(parsed_data.directories)}")
    end
  end

  defp print_elements(state) do
    case state.parsed_data do
      %{format: :catar, elements: elements} ->
        Mix.shell().info("Total elements: #{length(elements)}")
        Mix.shell().info("")
        
        elements
        |> Enum.with_index()
        |> Enum.each(fn {element, index} ->
          summary = case element do
            %{type: :entry, mode: mode, uid: uid, gid: gid} ->
              mode_str = Integer.to_string(mode, 8)
              "Entry (mode=#{mode_str}, uid=#{uid}, gid=#{gid})"
            %{type: :filename, name: name} ->
              "Filename: #{inspect(name)}"
            %{type: :payload, size: size} ->
              "Payload (#{format_bytes(size)})"
            %{type: :symlink, target: target} ->
              "Symlink -> #{inspect(target)}"
            %{type: :device, major: major, minor: minor} ->
              "Device #{major}:#{minor}"
            %{type: :user, name: name} ->
              "User: #{inspect(name)}"
            %{type: :group, name: name} ->
              "Group: #{inspect(name)}"
            %{type: :selinux, context: context} ->
              short_context = if String.length(context) > 30 do
                String.slice(context, 0, 27) <> "..."
              else
                context
              end
              "SELinux: #{inspect(short_context)}"
            %{type: :goodbye, items: items} ->
              "Goodbye (#{length(items)} items)"
            %{type: type} ->
              "#{type}"
          end
          
          Mix.shell().info("#{String.pad_leading(Integer.to_string(index + 1), 3)}. #{summary}")
        end)
        
      _ ->
        Mix.shell().error("Current file is not a CATAR archive or not parsed")
    end
  end

  defp print_chunks(state) do
    case state.parsed_data do
      %{chunks: chunks} when is_list(chunks) ->
        Mix.shell().info("Total chunks: #{length(chunks)}")
        Mix.shell().info("")
        
        chunks
        |> Enum.with_index()
        |> Enum.each(fn {chunk, index} ->
          chunk_id_hex = Base.encode16(chunk.chunk_id, case: :lower) |> String.slice(0, 16)
          Mix.shell().info("#{String.pad_leading(Integer.to_string(index + 1), 3)}. Offset: #{chunk.offset}, Size: #{format_bytes(chunk.size)}, ID: #{chunk_id_hex}...")
        end)
        
      _ ->
        Mix.shell().error("Current file does not contain chunks or not parsed")
    end
  end

  defp print_element_details(state, index) do
    case state.parsed_data do
      %{format: :catar, elements: elements} ->
        if index >= 0 and index < length(elements) do
          element = Enum.at(elements, index)
          Mix.shell().info("Element #{index + 1} details:")
          Mix.shell().info(inspect(element, pretty: true, limit: :infinity))
        else
          Mix.shell().error("Element index out of range: #{index + 1} (1-#{length(elements)})")
        end
        
      _ ->
        Mix.shell().error("Current file is not a CATAR archive or not parsed")
    end
  end

  defp print_chunk_details(state, index) do
    case state.parsed_data do
      %{chunks: chunks} when is_list(chunks) ->
        if index >= 0 and index < length(chunks) do
          chunk = Enum.at(chunks, index)
          Mix.shell().info("Chunk #{index + 1} details:")
          Mix.shell().info(inspect(chunk, pretty: true, limit: :infinity))
        else
          Mix.shell().error("Chunk index out of range: #{index + 1} (1-#{length(chunks)})")
        end
        
      _ ->
        Mix.shell().error("Current file does not contain chunks or not parsed")
    end
  end

  defp test_roundtrip_interactive(state) do
    case {state.binary_data, state.parsed_data, state.format} do
      {binary_data, parsed_data, format} when not is_nil(binary_data) and not is_nil(parsed_data) and not is_nil(format) ->
        Mix.shell().info("Testing roundtrip encoding...")
        
        encode_result = case format do
          format when format in [:caibx, :caidx] -> CasyncFormat.encode_index(parsed_data)
          :cacnk -> CasyncFormat.encode_chunk(parsed_data)
          :catar -> CasyncFormat.encode_archive(parsed_data)
        end

        case encode_result do
          {:ok, encoded_data} ->
            original_size = byte_size(binary_data)
            encoded_size = byte_size(encoded_data)
            
            Mix.shell().info("Original size: #{format_bytes(original_size)}")
            Mix.shell().info("Encoded size:  #{format_bytes(encoded_size)}")
            
            if binary_data == encoded_data do
              Mix.shell().info("✓ Perfect bit-exact roundtrip!")
            else
              size_diff = encoded_size - original_size
              Mix.shell().error("⚠ Content differs (size diff: #{size_diff} bytes)")
              
              # Ask if user wants to see hex diff
              case Mix.shell().prompt("Show hex diff? [y/N] ") |> String.trim() |> String.downcase() do
                answer when answer in ["y", "yes"] ->
                  CasyncFormat.print_hex_diff(binary_data, encoded_data)
                _ ->
                  :ok
              end
            end

          {:error, reason} ->
            Mix.shell().error("✗ Encoding failed: #{reason}")
        end
        
      _ ->
        Mix.shell().error("No valid file loaded and parsed")
    end
  end

  defp print_hex_dump_interactive(state, offset, length) do
    case state.binary_data do
      nil ->
        Mix.shell().error("No file loaded")
        
      binary_data ->
        file_size = byte_size(binary_data)
        
        if offset >= file_size do
          Mix.shell().error("Offset #{offset} is beyond file size #{file_size}")
        else
          actual_length = min(length, file_size - offset)
          hex_data = binary_part(binary_data, offset, actual_length)
          
          Mix.shell().info("Hex dump from offset #{offset} (#{actual_length} bytes):")
          print_hex_dump(hex_data, offset)
        end
    end
  end

  defp compare_files_interactive(state, other_file_path) do
    case File.exists?(other_file_path) do
      false ->
        Mix.shell().error("Comparison file not found: #{other_file_path}")
        state
      true ->
        case state.file_path do
          nil ->
            Mix.shell().error("No file currently loaded")
            state
            
          current_file ->
            Mix.shell().info("Comparing #{Path.basename(current_file)} with #{Path.basename(other_file_path)}")
            
            # Load the other file temporarily
            case File.read(other_file_path) do
              {:ok, other_binary} ->
                current_size = byte_size(state.binary_data)
                other_size = byte_size(other_binary)
                
                Mix.shell().info("File sizes:")
                Mix.shell().info("  Current: #{format_bytes(current_size)}")
                Mix.shell().info("  Other:   #{format_bytes(other_size)}")
                
                case state.binary_data == other_binary do
                  true ->
                    Mix.shell().info("✓ Files are identical")
                  false ->
                    Mix.shell().info("⚠ Files differ")
                    
                    # Try to parse the other file for comparison
                    case CasyncFormat.detect_format(other_binary) do
                      {:ok, other_format} ->
                        Mix.shell().info("Other file format: #{other_format}")
                        
                        case other_format == state.format do
                          true -> Mix.shell().info("✓ Formats match")
                          false -> Mix.shell().info("⚠ Format mismatch: #{state.format} vs #{other_format}")
                        end
                        
                      {:error, reason} ->
                        Mix.shell().error("Could not detect other file format: #{reason}")
                    end
                end
                
                state
                
              {:error, reason} ->
                Mix.shell().error("Failed to read comparison file: #{reason}")
                state
            end
        end
    end
  end

  defp export_analysis(state, format) do
    case {state.parsed_data, format} do
      {nil, _} ->
        Mix.shell().error("No parsed data to export")
        
      {parsed_data, "json"} ->
        json_safe_data = CasyncFormat.to_json_safe(parsed_data)
        json_output = Jason.encode!(json_safe_data, pretty: true)
        filename = "#{Path.basename(state.file_path, Path.extname(state.file_path))}_analysis.json"
        File.write!(filename, json_output)
        Mix.shell().info("JSON analysis exported to: #{filename}")
        
      {_parsed_data, "hex"} when not is_nil(state.binary_data) ->
        filename = "#{Path.basename(state.file_path, Path.extname(state.file_path))}_hexdump.txt"
        hex_output = format_hex_dump_to_string(state.binary_data)
        File.write!(filename, hex_output)
        Mix.shell().info("Hex dump exported to: #{filename}")
        
      {_parsed_data, "text"} ->
        filename = "#{Path.basename(state.file_path, Path.extname(state.file_path))}_analysis.txt"
        text_output = format_analysis_to_string(state)
        File.write!(filename, text_output)
        Mix.shell().info("Text analysis exported to: #{filename}")
        
      {_, unknown_format} ->
        Mix.shell().error("Unknown export format: #{unknown_format}")
        Mix.shell().info("Available formats: json, hex, text")
    end
  end

  defp format_hex_dump_to_string(binary_data) do
    binary_data
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.map(fn {bytes, row} ->
      offset = row * 16
      hex_part = bytes 
        |> Enum.map(&(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
        |> Enum.join(" ")
        |> String.pad_trailing(47)
      
      ascii_part = bytes
        |> Enum.map(fn b -> if b >= 32 and b <= 126, do: <<b>>, else: "." end)
        |> Enum.join()
      
      "#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0") |> String.upcase()}: #{hex_part} |#{ascii_part}|"
    end)
    |> Enum.join("\n")
  end

  defp format_analysis_to_string(state) do
    lines = [
      "=== AriaStorage File Analysis ===",
      "File: #{state.file_path}",
      "Size: #{format_bytes(byte_size(state.binary_data))}",
      "Format: #{state.format}",
      ""
    ]
    
    analysis_lines = case {state.parsed_data, state.format} do
      {%{chunks: chunks}, format} when format in [:caibx, :caidx] ->
        [
          "Chunks: #{length(chunks)}",
          "Feature flags: 0x#{Integer.to_string(state.parsed_data.feature_flags, 16)}",
          "Chunk sizes - min: #{state.parsed_data.chunk_size_min}, avg: #{state.parsed_data.chunk_size_avg}, max: #{state.parsed_data.chunk_size_max}",
          ""
        ]
        
      {%{header: header}, :cacnk} ->
        [
          "Compression: #{header.compression}",
          "Compressed size: #{format_bytes(header.compressed_size)}",
          "Uncompressed size: #{format_bytes(header.uncompressed_size)}",
          "Flags: 0x#{Integer.to_string(header.flags, 16)}",
          ""
        ]
        
      {%{elements: elements, files: files, directories: directories}, :catar} ->
        [
          "Elements: #{length(elements)}",
          "Files: #{length(files)}",
          "Directories: #{length(directories)}",
          ""
        ]
        
      _ ->
        ["Parse failed or no data", ""]
    end
    
    (lines ++ analysis_lines) |> Enum.join("\n")
  end

  defp print_hex_dump(binary, base_offset \\ 0) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.each(fn {bytes, row} ->
      offset = base_offset + row * 16
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

  defp print_help_commands do
    Mix.shell().info("""
    Available commands:
      help              Show this help message
      load <file>       Load a new casync file
      info              Show current file information
      parse             Re-parse current file
      elements          Show all elements (CATAR files)
      element <n>       Show specific element details (1-based index)
      chunks            Show all chunks (index files)  
      chunk <n>         Show specific chunk details (1-based index)
      roundtrip         Test roundtrip encoding
      compare <file>    Compare with another file
      hex [offset]      Show hex dump (optionally from offset)
      export <format>   Export analysis (json, hex, text)
      quit              Exit interactive mode
    """)
  end
end
