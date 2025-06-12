#!/usr/bin/env elixir

# Debug size calculations in CATAR elements to identify the +85 byte issue

Mix.install([])

defmodule SizeDebug do
  # Copy the exact constants from the main file
  @ca_format_entry 0x1396fabbb8f1411f
  @ca_format_filename 0x17436007e389cc9c
  @ca_format_payload 0x8b9e1d93d6dcffc9
  @ca_format_user 0xf453131aaeeaccb3
  @ca_format_group 0x25eb6ac969dd4a59
  @ca_format_selinux 0xf7267db0afed0629
  @ca_format_symlink 0x664a6fb6830e2c6c
  @ca_format_device 0x78a039a0c2a54c61
  @ca_format_goodbye 0x57446fa533702943

  def debug_size_calculation(element_type, data_size) do
    IO.puts("=== #{element_type} ===")
    IO.puts("Data size: #{data_size}")

    case element_type do
      :entry ->
        # Fixed size, no padding calculation needed
        total_size = 64
        IO.puts("Total size (fixed): #{total_size}")
        {total_size, 0}

      :variable ->
        # Variable length elements
        unpadded_size = 16 + data_size  # Header (16 bytes) + data
        padding_size = rem(8 - rem(unpadded_size, 8), 8)
        padded_size = unpadded_size + padding_size
        
        IO.puts("Unpadded size (16 + #{data_size}): #{unpadded_size}")
        IO.puts("Padding needed: #{padding_size}")
        IO.puts("Padded size: #{padded_size}")
        
        {padded_size, padding_size}
    end
  end

  def analyze_flat_catar() do
    catar_path = "/Users/setup/Developer/aria-character-core/apps/aria_storage/test/support/testdata/flat.catar"
    
    case File.read(catar_path) do
      {:ok, data} ->
        IO.puts("=== ANALYZING flat.catar ===")
        IO.puts("Total file size: #{byte_size(data)} bytes")
        
        # Parse and analyze each element
        analyze_elements(data, 0, [])
        
      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
    end
  end

  defp analyze_elements(<<>>, _offset, acc) do
    IO.puts("\n=== SUMMARY ===")
    IO.puts("Total elements parsed: #{length(acc)}")
    
    total_calculated = Enum.sum(Enum.map(acc, fn {_type, size, _padding} -> size end))
    IO.puts("Total calculated size: #{total_calculated}")
    
    total_padding = Enum.sum(Enum.map(acc, fn {_type, _size, padding} -> padding end))
    IO.puts("Total padding: #{total_padding}")
    
    Enum.reverse(acc)
  end

  defp analyze_elements(data, offset, acc) do
    case data do
      <<size::little-64, type::little-64, rest::binary>> when byte_size(rest) >= (size - 16) ->
        type_name = case type do
          @ca_format_entry -> :entry
          @ca_format_filename -> :filename
          @ca_format_payload -> :payload
          @ca_format_user -> :user
          @ca_format_group -> :group
          @ca_format_selinux -> :selinux
          @ca_format_symlink -> :symlink
          @ca_format_device -> :device
          @ca_format_goodbye -> :goodbye
          _ -> :unknown
        end
        
        data_size = size - 16
        
        IO.puts("\nOffset #{offset}: #{type_name} (0x#{Integer.to_string(type, 16)})")
        IO.puts("  Header size field: #{size}")
        IO.puts("  Data size: #{data_size}")
        
        # Calculate expected padding
        padding = if type_name == :entry do
          IO.puts("  Fixed size element (64 bytes)")
          0
        else
          unpadded = 16 + data_size
          padding_calc = rem(8 - rem(unpadded, 8), 8)
          expected_total = unpadded + padding_calc
          IO.puts("  Unpadded: #{unpadded}, Padding: #{padding_calc}, Expected total: #{expected_total}")
          
          if expected_total != size do
            IO.puts("  *** SIZE MISMATCH: Expected #{expected_total}, got #{size} ***")
          end
          padding_calc
        end
        
        # Skip to next element - consume only the element size (CATAR files do not include padding)
        if byte_size(data) >= size do
          <<_current_element::binary-size(size), remaining_data::binary>> = data
          new_offset = offset + size
          analyze_elements(remaining_data, new_offset, [{type_name, size, padding} | acc])
        else
          IO.puts("Not enough data remaining for element")
          Enum.reverse(acc)
        end
        
      _ ->
        IO.puts("End of data or malformed element at offset #{offset}, remaining: #{byte_size(data)} bytes")
        Enum.reverse(acc)
    end
  end
end

# Run the analysis
SizeDebug.analyze_flat_catar()
