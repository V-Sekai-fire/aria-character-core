#!/usr/bin/env elixir

# Test CATAR encoding differences by examining the first entry header fields
Mix.install([])

# Add the apps/aria_storage/lib directory to the code path
Code.append_path("apps/aria_storage/lib")

alias AriaStorage.Parsers.CasyncFormat

file_path = "apps/aria_storage/test/support/testdata/complex.catar"

case File.read(file_path) do
  {:ok, original_data} ->
    IO.puts("=== ANALYZING COMPLEX.CATAR ENCODING ISSUE ===")
    
    # Parse the first entry header manually
    <<
      size::little-64,
      type::little-64,
      flags::little-64,
      padding::little-64,
      mode::little-64,
      uid::little-64,
      gid::little-64,
      mtime::little-64,
      _rest::binary
    >> = original_data
    
    IO.puts("Original first entry header fields:")
    IO.puts("  size: #{size}")
    IO.puts("  type: #{type} (0x#{Integer.to_string(type, 16)})")
    IO.puts("  flags: #{flags} (0x#{Integer.to_string(flags, 16)})")
    IO.puts("  padding: #{padding}")
    IO.puts("  mode: #{mode} (0o#{Integer.to_string(mode, 8)})")
    IO.puts("  uid: #{uid}")
    IO.puts("  gid: #{gid}")
    IO.puts("  mtime: #{mtime}")
    
    # Parse and re-encode
    case CasyncFormat.parse_archive(original_data) do
      {:ok, parsed} ->
        first_element = Enum.at(parsed.elements, 0)
        IO.puts("\nParsed first element:")
        IO.inspect(first_element, limit: :infinity)
        
        case CasyncFormat.encode_archive(parsed) do
          {:ok, encoded_data} ->
            IO.puts("\nEncoded size: #{byte_size(encoded_data)} vs Original: #{byte_size(original_data)}")
            
            # Parse the encoded first entry header
            <<
              enc_size::little-64,
              enc_type::little-64,
              enc_flags::little-64,
              enc_padding::little-64,
              enc_mode::little-64,
              enc_uid::little-64,
              enc_gid::little-64,
              enc_mtime::little-64,
              _enc_rest::binary
            >> = encoded_data
            
            IO.puts("\nEncoded first entry header fields:")
            IO.puts("  size: #{enc_size}")
            IO.puts("  type: #{enc_type} (0x#{Integer.to_string(enc_type, 16)})")
            IO.puts("  flags: #{enc_flags} (0x#{Integer.to_string(enc_flags, 16)})")
            IO.puts("  padding: #{enc_padding}")
            IO.puts("  mode: #{enc_mode} (0o#{Integer.to_string(enc_mode, 8)})")
            IO.puts("  uid: #{enc_uid}")
            IO.puts("  gid: #{enc_gid}")
            IO.puts("  mtime: #{enc_mtime}")
            
            # Show any differences
            IO.puts("\n=== FIELD DIFFERENCES ===")
            if size != enc_size, do: IO.puts("❌ size: #{size} -> #{enc_size}")
            if type != enc_type, do: IO.puts("❌ type: #{type} -> #{enc_type}")
            if flags != enc_flags, do: IO.puts("❌ flags: #{flags} -> #{enc_flags}")
            if padding != enc_padding, do: IO.puts("❌ padding: #{padding} -> #{enc_padding}")
            if mode != enc_mode, do: IO.puts("❌ mode: #{mode} -> #{enc_mode}")
            if uid != enc_uid, do: IO.puts("❌ uid: #{uid} -> #{enc_uid}")
            if gid != enc_gid, do: IO.puts("❌ gid: #{gid} -> #{enc_gid}")
            if mtime != enc_mtime, do: IO.puts("❌ mtime: #{mtime} -> #{enc_mtime}")
            
            if original_data == encoded_data do
              IO.puts("✅ Perfect match!")
            else
              IO.puts("⚠️  Data differs")
            end
            
        end
    end
    
  {:error, reason} ->
    IO.puts("Failed to read file: #{reason}")
end
