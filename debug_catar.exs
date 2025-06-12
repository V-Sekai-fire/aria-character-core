#!/usr/bin/env elixir

Mix.install([])

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

data = File.read!("apps/aria_storage/test/support/testdata/flat.catar")

case CasyncFormat.parse_archive(data) do
  {:ok, result} ->
    IO.puts("Parsed #{length(result.elements)} elements:")
    
    Enum.with_index(result.elements) 
    |> Enum.take(15) 
    |> Enum.each(fn {element, idx} ->
      case element do
        %{type: :entry} = entry ->
          mode_str = Integer.to_string(entry.mode, 8)
          IO.puts("#{idx}: ENTRY - mode: #{mode_str} (0o#{mode_str}), size: #{entry.size}")
          
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
          IO.puts("#{idx}: #{inspect(other.type)} - #{inspect(other, pretty: true)}")
      end
    end)
    
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end
