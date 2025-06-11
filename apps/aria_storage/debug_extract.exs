#!/usr/bin/env elixir

# Debug the binary field extraction
# Usage: elixir -S mix run debug_extract.exs

defmodule DebugExtract do
  alias AriaStorage.Parsers.CasyncFormat

  # Copy the current extract_binary_field function for testing
  defp extract_binary_field(parsed_data, field_name) do
    case Keyword.get(parsed_data, field_name, []) do
      list when is_list(list) ->
        IO.puts("Field #{field_name}: #{inspect(list)}")

        # Convert mixed list of strings and binaries to pure binary
        result = list
        |> Enum.map(fn
          str when is_binary(str) ->
            # Convert string to list of bytes, then back to binary
            bytes = :binary.bin_to_list(str)
            IO.puts("  String #{inspect(str)} -> bytes: #{inspect(bytes)}")
            bytes
          int when is_integer(int) ->
            # Single byte as integer
            IO.puts("  Integer #{int}")
            [int]
          other ->
            # Convert other types to binary and then to byte list
            bytes = :binary.bin_to_list(IO.iodata_to_binary([other]))
            IO.puts("  Other #{inspect(other)} -> bytes: #{inspect(bytes)}")
            bytes
        end)
        |> List.flatten()
        |> :binary.list_to_bin()

        IO.puts("  Final result: #{inspect(result)} (#{byte_size(result)} bytes)")
        IO.puts("  Hex: #{Base.encode16(result)}")
        result

      binary when is_binary(binary) ->
        IO.puts("Field #{field_name}: direct binary #{inspect(binary)}")
        binary

      _ ->
        IO.puts("Field #{field_name}: empty/unknown")
        <<>>
    end
  end

  def run do
    IO.puts("=== Debug Binary Field Extraction ===\n")

    testdata_path = Path.join([__DIR__, "test", "support", "testdata"])
    file_path = Path.join(testdata_path, "blob1.caibx")

    case File.read(file_path) do
      {:ok, data} ->
        IO.puts("File size: #{byte_size(data)} bytes")
        IO.puts("First 16 bytes: #{Base.encode16(binary_part(data, 0, 16))}")
        IO.puts("")

        # Test the ABNF parser directly
        case CasyncFormat.format_index(data) do
          {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
            IO.puts("✅ ABNF parse successful!")
            IO.puts("Raw parsed structure: #{inspect(parsed_list, limit: :infinity)}")
            IO.puts("")

            # Extract the format_index field which contains our data
            format_index_data = Keyword.get(parsed_list, :format_index, [])
            IO.puts("format_index_data: #{inspect(format_index_data)}")
            IO.puts("")

            # Test field extraction
            IO.puts("=== Extracting Fields ===")
            size_field = extract_binary_field(format_index_data, :size_field)
            type_field = extract_binary_field(format_index_data, :type_field)

            IO.puts("")
            IO.puts("=== Converting to Integers ===")
            size_val = :binary.decode_unsigned(size_field, :little)
            type_val = :binary.decode_unsigned(type_field, :little)

            IO.puts("Size: #{size_val}")
            IO.puts("Type: 0x#{Integer.to_string(type_val, 16)}")
            IO.puts("Expected type: 0x#{Integer.to_string(0x96824d9c7b129ff9, 16)}")
            IO.puts("Match: #{type_val == 0x96824d9c7b129ff9}")

          {:error, reason, _rest, _context, _line, _offset} ->
            IO.puts("❌ ABNF parse failed: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("❌ File read error: #{reason}")
    end
  end
end

DebugExtract.run()
