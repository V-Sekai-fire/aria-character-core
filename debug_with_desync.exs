#!/usr/bin/env elixir

# Compare our parser output with desync mtree output
Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

defmodule DesyncComparison do
  def compare_with_desync(file_path) do
    IO.puts("=== Comparing #{Path.basename(file_path)} ===")
    
    # Get desync mtree output
    case System.cmd("desync", ["mtree", file_path]) do
      {desync_output, 0} ->
        desync_entries = parse_desync_mtree(desync_output)
      {error_output, _} ->
        IO.puts("Desync command failed: #{error_output}")
        return
    end
    
    IO.puts("Desync found #{length(desync_entries)} entries:")
    Enum.each(desync_entries, fn entry ->
      IO.puts("  #{entry.name}: #{entry.type} (#{entry.mode}) uid=#{entry.uid} gid=#{entry.gid}")
    end)
    
    # Parse with our parser
    case File.read(file_path) do
      {:ok, data} ->
        case CasyncFormat.parse_archive(data) do
          {:ok, parsed} ->
            IO.puts("\nOur parser found #{length(parsed.elements)} elements")
            IO.puts("Files: #{length(parsed.files)}")
            IO.puts("Directories: #{length(parsed.directories)}")
            
            # Try to match entries
            compare_entries(desync_entries, parsed)
            
            # Test encoding
            case CasyncFormat.encode_archive(parsed) do
              {:ok, encoded} ->
                IO.puts("\nEncoding:")
                IO.puts("  Original size: #{byte_size(data)}")
                IO.puts("  Encoded size: #{byte_size(encoded)}")
                IO.puts("  Difference: #{byte_size(encoded) - byte_size(data)}")
                
              {:error, reason} ->
                IO.puts("Encoding failed: #{reason}")
            end
            
          {:error, reason} ->
            IO.puts("Parsing failed: #{reason}")
        end
        
      {:error, reason} ->
        IO.puts("File read failed: #{reason}")
    end
    
    IO.puts("")
  end
  
  defp parse_desync_mtree(output) do
    output
    |> String.split("\n")
    |> Enum.drop(1)  # Skip #mtree header
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_mtree_line/1)
    |> Enum.reject(&is_nil/1)
  end
  
  defp parse_mtree_line(line) do
    parts = String.split(line, " ")
    case parts do
      [name | attributes] ->
        attrs = parse_attributes(attributes)
        %{
          name: name,
          type: attrs[:type] || "unknown",
          mode: attrs[:mode] || "0000",
          uid: attrs[:uid] || 0,
          gid: attrs[:gid] || 0,
          size: attrs[:size] || 0,
          target: attrs[:target]
        }
      _ ->
        nil
    end
  end
  
  defp parse_attributes(attrs) do
    attrs
    |> Enum.map(fn attr ->
      case String.split(attr, "=", parts: 2) do
        [key, value] ->
          parsed_value = case key do
            "uid" -> String.to_integer(value)
            "gid" -> String.to_integer(value)
            "size" -> String.to_integer(value)
            "mode" -> value
            _ -> value
          end
          {String.to_atom(key), parsed_value}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end
  
  defp compare_entries(desync_entries, parsed) do
    IO.puts("\n=== Entry Comparison ===")
    
    # Group our parsed elements by filename
    filenames = Enum.filter(parsed.elements, &(&1.type == :filename))
    entries = Enum.filter(parsed.elements, &(&1.type == :entry))
    
    IO.puts("Filename elements: #{length(filenames)}")
    IO.puts("Entry elements: #{length(entries)}")
    
    # Simple comparison
    if length(desync_entries) == length(filenames) do
      IO.puts("✓ Entry count matches")
    else
      IO.puts("⚠ Entry count mismatch: desync=#{length(desync_entries)}, ours=#{length(filenames)}")
    end
  end
end

# Test files
test_files = [
  "apps/aria_storage/test/support/testdata/flat.catar",
  "apps/aria_storage/test/support/testdata/complex.catar"
]

Enum.each(test_files, &DesyncComparison.compare_with_desync/1)
