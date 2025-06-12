#!/usr/bin/env elixir

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

# Test one specific file to debug the difference
file_path = "/Users/setup/Developer/aria-character-core/apps/aria_storage/test/support/testdata/complex.catar"

case File.read(file_path) do
  {:ok, original_data} ->
    IO.puts("=== DEBUGGING COMPLEX.CATAR HEADER ===")
    
    # Parse just the first entry header
    <<
      size::little-64,
      type::little-64,
      flags::little-64,
      padding1::little-64,
      mode::little-64,
      uid::little-64,
      gid::little-64,
      mtime::little-64,
      _rest::binary
    >> = original_data
    
    IO.puts("Original first entry header:")
    IO.puts("  size: #{size}")
    IO.puts("  type: #{type} (0x#{Integer.to_string(type, 16)})")
    IO.puts("  flags: #{flags} (0x#{Integer.to_string(flags, 16)})")
    IO.puts("  padding1: #{padding1}")
    IO.puts("  mode: #{mode} (0x#{Integer.to_string(mode, 16)})")
    IO.puts("  uid: #{uid}")
    IO.puts("  gid: #{gid}")
    IO.puts("  mtime: #{mtime}")
    
    case CasyncFormat.parse_archive(original_data) do
      {:ok, parsed} ->
        IO.puts("\n=== PARSED FIRST ELEMENT ===")
        first_element = Enum.at(parsed.elements, 0)
        IO.inspect(first_element, label: "First element")
        
        case CasyncFormat.encode_archive(parsed) do
          {:ok, encoded_data} ->
            # Parse the encoded first entry header
            <<
              enc_size::little-64,
              enc_type::little-64,
              enc_flags::little-64,
              enc_padding1::little-64,
              enc_mode::little-64,
              enc_uid::little-64,
              enc_gid::little-64,
              enc_mtime::little-64,
              _enc_rest::binary
            >> = encoded_data
            
            IO.puts("\n=== ENCODED FIRST ENTRY HEADER ===")
            IO.puts("  size: #{enc_size}")
            IO.puts("  type: #{enc_type} (0x#{Integer.to_string(enc_type, 16)})")
            IO.puts("  flags: #{enc_flags} (0x#{Integer.to_string(enc_flags, 16)})")
            IO.puts("  padding1: #{enc_padding1}")
            IO.puts("  mode: #{enc_mode} (0x#{Integer.to_string(enc_mode, 16)})")
            IO.puts("  uid: #{enc_uid}")
            IO.puts("  gid: #{enc_gid}")
            IO.puts("  mtime: #{enc_mtime}")
            
            IO.puts("\n=== DIFFERENCES ===")
            if size != enc_size, do: IO.puts("❌ size: #{size} != #{enc_size}")
            if type != enc_type, do: IO.puts("❌ type: #{type} != #{enc_type}")
            if flags != enc_flags, do: IO.puts("❌ flags: #{flags} != #{enc_flags}")
            if padding1 != enc_padding1, do: IO.puts("❌ padding1: #{padding1} != #{enc_padding1}")
            if mode != enc_mode, do: IO.puts("❌ mode: #{mode} != #{enc_mode}")
            if uid != enc_uid, do: IO.puts("❌ uid: #{uid} != #{enc_uid}")
            if gid != enc_gid, do: IO.puts("❌ gid: #{gid} != #{enc_gid}")
            if mtime != enc_mtime, do: IO.puts("❌ mtime: #{mtime} != #{enc_mtime}")
            
        end
    end
    
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end
