#!/usr/bin/env elixir

# Debug SELinux encoding specifically
IO.puts("Starting SELinux encoding debug...")

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

# Load test data
data = File.read!("apps/aria_storage/test/support/testdata/flat.catar")
IO.puts("Loaded #{byte_size(data)} bytes from flat.catar")

case CasyncFormat.parse_archive(data) do
  {:ok, result} ->
    IO.puts("Successfully parsed CATAR!")
    IO.puts("Total elements: #{length(result.elements)}")
    
    # Find SELinux elements specifically
    selinux_elements = Enum.filter(result.elements, fn element ->
      Map.get(element, :type) == :selinux
    end)
    
    IO.puts("\n=== SELINUX ELEMENTS ===")
    IO.puts("Found #{length(selinux_elements)} SELinux elements:")
    
    Enum.with_index(selinux_elements)
    |> Enum.each(fn {element, idx} ->
      IO.puts("#{idx + 1}: #{inspect(element)}")
    end)
    
    # Test encoding
    case CasyncFormat.encode_archive(result) do
      {:ok, encoded_data} ->
        IO.puts("\n=== ENCODING RESULTS ===")
        IO.puts("Original size: #{byte_size(data)}")
        IO.puts("Encoded size: #{byte_size(encoded_data)}")
        IO.puts("Size difference: #{byte_size(encoded_data) - byte_size(data)}")
        
        # Check if SELinux elements are preserved
        case CasyncFormat.parse_archive(encoded_data) do
          {:ok, re_parsed} ->
            re_selinux = Enum.filter(re_parsed.elements, fn element ->
              Map.get(element, :type) == :selinux
            end)
            
            IO.puts("\n=== RE-PARSED SELINUX ELEMENTS ===")
            IO.puts("Found #{length(re_selinux)} SELinux elements after roundtrip:")
            
            Enum.with_index(re_selinux)
            |> Enum.each(fn {element, idx} ->
              IO.puts("#{idx + 1}: #{inspect(element)}")
            end)
            
            # Compare contexts
            orig_contexts = Enum.map(selinux_elements, & &1.context)
            new_contexts = Enum.map(re_selinux, & &1.context)
            
            IO.puts("\n=== CONTEXT COMPARISON ===")
            IO.puts("Original contexts: #{inspect(orig_contexts)}")
            IO.puts("Re-parsed contexts: #{inspect(new_contexts)}")
            IO.puts("Contexts match: #{orig_contexts == new_contexts}")
            
          {:error, reason} ->
            IO.puts("❌ Failed to re-parse encoded data: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to encode: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ Failed to parse: #{inspect(reason)}")
end
