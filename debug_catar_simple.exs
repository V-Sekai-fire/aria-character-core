#!/usr/bin/env elixir

# Simple debug test for CATAR parsing
IO.puts("Starting CATAR debug test...")

# Add the project path
Application.put_env(:elixir, :ansi_enabled, true)

# Load dependencies first 
System.put_env("MIX_ENV", "dev")

# Load the file
Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

# Test the parsing
alias AriaStorage.Parsers.CasyncFormat

data = File.read!("apps/aria_storage/test/support/testdata/flat.catar")
IO.puts("Loaded #{byte_size(data)} bytes from flat.catar")

case CasyncFormat.parse_archive(data) do
  {:ok, result} ->
    IO.puts("Successfully parsed CATAR!")
    IO.puts("Total elements: #{length(result.elements)}")
    
    # Show first few elements in detail
    IO.puts("\n=== FIRST 10 ELEMENTS ===")
    result.elements 
    |> Enum.take(10)
    |> Enum.with_index()
    |> Enum.each(fn {element, idx} ->
      case element do
        %{type: :entry} = entry ->
          mode_str = Integer.to_string(entry.mode, 8)
          IO.puts("#{idx}: ENTRY - mode: #{mode_str}, size: #{entry.size}")
          
        %{type: :filename} = filename ->
          IO.puts("#{idx}: FILENAME - \"#{filename.name}\"")
          
        %{type: :payload} = payload ->
          IO.puts("#{idx}: PAYLOAD - #{byte_size(payload.data)} bytes")
          
        %{type: :symlink} = symlink ->
          IO.puts("#{idx}: SYMLINK - target: \"#{symlink.target}\"")
          
        %{type: :device} = device ->
          IO.puts("#{idx}: DEVICE - major: #{device.major}, minor: #{device.minor}")
          
        %{type: :goodbye} ->
          IO.puts("#{idx}: GOODBYE")
          
        other ->
          IO.puts("#{idx}: #{inspect(other.type)} - #{inspect(other, limit: :infinity, pretty: true)}")
      end
    end)
    
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
