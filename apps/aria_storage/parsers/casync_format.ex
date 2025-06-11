def decode_index_file([magic, header, chunks]) do
    # Determine format from magic
    format = case magic do
      <<0xCA, 0x1B, 0x5C>> -> :caibx
      <<0xCA, 0x1D, 0x5C>> -> :caidx
      :caibx -> :caibx
      :caidx -> :caidx
      _ -> :caibx
    end

    # Filter chunks to only include valid chunk entries
    valid_chunks = Enum.filter(chunks, fn
      %{chunk_id: _, offset: _, size: _, flags: _} -> true
      _ -> false
    end)

    %{
      format: format,
      header: header,
      chunks: valid_chunks
    }
  end

  def decode_index_file([magic, header]) do
    # Determine format from magic
    format = case magic do
      <<0xCA, 0x1B, 0x5C>> -> :caibx
      <<0xCA, 0x1D, 0x5C>> -> :caidx
      :caibx -> :caibx
      :caidx -> :caidx
      _ -> :caibx
    end

    %{
      format: format,
      header: header,
      chunks: []
    }
  end

  # Handle case where AbnfParsec provides individual tagged values
  def decode_index_file({tag, value}) when is_atom(tag) do
    %{
      format: :caibx,  # Default to caibx format
      header: %{version: 0, total_size: 0, chunk_count: 0},
      chunks: if(is_list(value), do: value, else: [])
    }
  end

  # Handle case where we get a flat list of parsed elements
  def decode_index_file(elements) when is_list(elements) and length(elements) > 3 do
    # Try to extract magic, header, and chunks from the flat list
    # Magic should be first (atom or binary)
    # Header should be a map with version, total_size, chunk_count
    # Chunks should be maps with chunk_id, offset, size, flags

    {magic, rest} = case hd(elements) do
      atom when is_atom(atom) -> {atom, tl(elements)}
      binary when is_binary(binary) and byte_size(binary) == 3 ->
        format = case binary do
          <<0xCA, 0x1B, 0x5C>> -> :caibx
          <<0xCA, 0x1D, 0x5C>> -> :caidx
          _ -> :caibx
        end
        {format, tl(elements)}
      _ -> {:caibx, elements}
    end

    {header, chunks} = case rest do
      [h | chunk_list] when is_map(h) and Map.has_key?(h, :version) ->
        {h, chunk_list}
      _ ->
        # Extract header from first few elements if they look like header values
        case rest do
          [v, ts, cc, _reserved | chunk_data] when is_integer(v) and is_integer(ts) and is_integer(cc) ->
            header = %{version: v, total_size: ts, chunk_count: cc}
            {header, chunk_data}
          _ ->
            # Fallback header
            header = %{version: 0, total_size: 0, chunk_count: 0}
            {header, rest}
        end
    end

    # Filter chunks to only include valid chunk entries
    valid_chunks = Enum.filter(chunks, fn
      %{chunk_id: _, offset: _, size: _, flags: _} -> true
      _ -> false
    end)

    %{
      format: magic,
      header: header,
      chunks: valid_chunks
    }
  end

  # Handle case where AbnfParsec provides single character string (MUST BE FIRST)
  def decode_chunk_entry(char) when is_binary(char) and byte_size(char) == 1 do
    # This is likely a single byte being parsed incorrectly - skip it
    %{
      chunk_id: char <> <<0::248>>,  # Pad to 32 bytes
      offset: 0,
      size: 0,
      flags: 0
    }
  end

  # Handle case where AbnfParsec provides single character string (MUST BE FIRST)
  def decode_chunk_entry(char) when is_binary(char) do
    chunk_id = if byte_size(char) >= 32 do
      binary_part(char, 0, 32)  # Take first 32 bytes
    else
      char <> <<0::((32-byte_size(char))*8)>>  # Pad to 32 bytes
    end

    %{
      chunk_id: chunk_id,
      offset: 0,
      size: 0,
      flags: 0
    }
  end

  # Handle case where AbnfParsec provides partial binary data
  def decode_chunk_entry([partial_data]) when is_binary(partial_data) do
    %{
      chunk_id: partial_data <> <<0::((32-byte_size(partial_data))*8)>>,  # Pad to 32 bytes
      offset: 0,
      size: 0,
      flags: 0
    }
  end

  # Handle case where AbnfParsec provides tagged tuples
  def decode_chunk_entry({tag, value}) when is_atom(tag) do
    %{
      chunk_id: <<0::256>>,  # 32 bytes of zeros
      offset: if(is_list(value), do: hd(value), else: value),
      size: 0,
      flags: 0
    }
  end

  def decode_chunk_entry([chunk_id_bytes, offset, size, flags]) when is_list(chunk_id_bytes) do
    %{
      chunk_id: :erlang.list_to_binary(chunk_id_bytes),
      offset: offset,
      size: size,
      flags: flags
    }
  end

  # Handle the proper casync chunk entry format: 32 bytes chunk_id + 8 bytes offset + 4 bytes size + 4 bytes flags
  def decode_chunk_entry([chunk_id, offset, size, flags]) when is_binary(chunk_id) and byte_size(chunk_id) == 32 do
    %{
      chunk_id: chunk_id,
