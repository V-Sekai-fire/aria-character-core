# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Index do
  @moduledoc "Index file handling for desync-compatible format.\n\nSupports:\n- .caibx files (chunk index for blobs)\n- .caidx files (chunk index for catar archives)\n- Efficient index serialization/deserialization\n- Index metadata and validation\n"
  alias AriaStorage.Chunks
  defstruct [:format, :chunks, :total_size, :chunk_count, :created_at, :checksum, :metadata]
  @type format :: :caibx | :caidx
  @type t :: %__MODULE__{
          format: format(),
          chunks: [Chunks.t()],
          total_size: non_neg_integer(),
          chunk_count: non_neg_integer(),
          created_at: DateTime.t(),
          checksum: binary(),
          metadata: map()
        }
  @caibx_magic_header <<202, 27, 92>>
  @caidx_magic_header <<202, 29, 92>>
  @index_version 1
  @doc "Creates a new index from chunks and options.\n\n## Parameters\n- chunks: List of chunks to include in the index\n- opts: Options including format, metadata, etc.\n\n## Returns\n- {:ok, index} on success\n- {:error, reason} on failure\n"
  def create_index(chunks, opts \\ []) do
    format = Keyword.get(opts, :format, :caibx)
    metadata = Keyword.get(opts, :metadata, %{})

    index = %__MODULE__{
      format: format,
      chunks: chunks,
      total_size: Enum.sum(Enum.map(chunks, & &1.size)),
      chunk_count: length(chunks),
      created_at: DateTime.utc_now(),
      checksum: calculate_index_checksum(chunks),
      metadata: metadata
    }

    {:ok, index}
  end

  @doc "Serializes an index to binary format compatible with desync.\n"
  def serialize(%__MODULE__{format: format} = index) do
    magic =
      case format do
        :caibx -> @caibx_magic_header
        :caidx -> @caidx_magic_header
      end

    header = create_header(index)
    chunk_table = create_chunk_table(index.chunks)
    binary_data = magic <> header <> chunk_table
    {:ok, binary_data}
  end

  @doc "Deserializes an index from binary format.\n"
  def deserialize(binary_data) do
    case binary_data do
      <<@caibx_magic_header, rest::binary>> -> parse_index(rest, :caibx)
      <<@caidx_magic_header, rest::binary>> -> parse_index(rest, :caidx)
      _ -> {:error, :invalid_magic_header}
    end
  end

  @doc "Loads an index from a file.\n"
  def load_from_file(file_path) do
    case File.read(file_path) do
      {:ok, binary_data} -> deserialize(binary_data)
      {:error, reason} -> {:error, {:file_read, reason}}
    end
  end

  @doc "Saves an index to a file.\n"
  def save_to_file(index, file_path) do
    with {:ok, binary} <- serialize(index),
         :ok <- File.write(file_path, binary) do
      {:ok, file_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Validates an index structure.\n"
  def validate(%__MODULE__{} = index) do
    with :ok <- validate_chunks(index.chunks),
         :ok <- validate_sizes(index) do
      validate_checksum(index)
    end
  end

  @doc "Creates an index filename based on the original file and format.\n"
  def create_filename(original_file, format) do
    extension =
      case format do
        :caibx -> ".caibx"
        :caidx -> ".caidx"
      end

    original_file <> extension
  end

  @doc "Gets chunk by ID from the index.\n"
  def get_chunk_by_id(%__MODULE__{chunks: chunks}, chunk_id) do
    Enum.find(chunks, &(&1.id == chunk_id))
  end

  @doc "Gets chunks in the range [start_offset, end_offset).\n"
  def get_chunks_in_range(%__MODULE__{chunks: chunks}, start_offset, end_offset) do
    chunks
    |> Enum.filter(fn chunk ->
      chunk_end = chunk.offset + chunk.size
      chunk.offset < end_offset && chunk_end > start_offset
    end)
    |> Enum.sort_by(& &1.offset)
  end

  @doc "Calculates the total compressed size of all chunks.\n"
  def total_compressed_size(%__MODULE__{chunks: chunks}) do
    chunks |> Enum.map(&byte_size(&1.compressed)) |> Enum.sum()
  end

  @doc "Gets compression ratio (compressed / uncompressed).\n"
  def compression_ratio(%__MODULE__{} = index) do
    compressed = total_compressed_size(index)
    uncompressed = index.total_size

    if uncompressed > 0 do
      compressed / uncompressed
    else
      0.0
    end
  end

  defp create_header(index) do
    timestamp = DateTime.to_unix(index.created_at)

    <<@index_version::32-big, index.chunk_count::32-big, index.total_size::64-big,
      timestamp::64-big, byte_size(index.checksum)::16-big, index.checksum::binary>>
  end

  defp create_chunk_table(chunks) do
    Enum.map_join(chunks, "", &serialize_chunk/1)
  end

  defp serialize_chunk(chunk) do
    compressed_size = byte_size(chunk.compressed)

    <<chunk.size::32-big, compressed_size::32-big, chunk.offset::64-big,
      byte_size(chunk.id)::16-big, chunk.id::binary, byte_size(chunk.checksum)::16-big,
      chunk.checksum::binary, chunk.compressed::binary>>
  end

  defp parse_index(binary_data, format) do
    case parse_header(binary_data) do
      {:ok, header, chunk_data} ->
        case parse_chunk_table(chunk_data, header.chunk_count) do
          {:ok, chunks} ->
            index = %__MODULE__{
              format: format,
              chunks: chunks,
              total_size: header.total_size,
              chunk_count: header.chunk_count,
              created_at: DateTime.from_unix!(header.timestamp),
              checksum: header.checksum,
              metadata: %{}
            }

            {:ok, index}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_header(binary_data) do
    case binary_data do
      <<@index_version::32-big, chunk_count::32-big, total_size::64-big, timestamp::64-big,
        checksum_len::16-big, checksum::binary-size(checksum_len), rest::binary>> ->
        header = %{
          chunk_count: chunk_count,
          total_size: total_size,
          timestamp: timestamp,
          checksum: checksum
        }

        {:ok, header, rest}

      _ ->
        {:error, :invalid_header_format}
    end
  end

  defp parse_chunk_table(binary_data, expected_count) do
    parse_chunks(binary_data, expected_count, [])
  end

  defp parse_chunks(_binary_data, 0, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp parse_chunks(binary_data, remaining, acc) when remaining > 0 do
    case parse_single_chunk(binary_data) do
      {:ok, chunk, rest} -> parse_chunks(rest, remaining - 1, [chunk | acc])
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_single_chunk(binary_data) do
    case binary_data do
      <<size::32-big, compressed_size::32-big, offset::64-big, id_len::16-big,
        id::binary-size(id_len), checksum_len::16-big, checksum::binary-size(checksum_len),
        compressed::binary-size(compressed_size), rest::binary>> ->
        case Chunks.decompress_chunk(compressed) do
          {:ok, data} ->
            chunk = %Chunks{
              id: id,
              data: data,
              size: size,
              compressed: compressed,
              offset: offset,
              checksum: checksum
            }

            {:ok, chunk, rest}

          {:error, reason} ->
            {:error, {:decompression_failed, reason}}
        end

      _ ->
        {:error, :invalid_chunk_format}
    end
  end

  defp validate_chunks(chunks) do
    if Enum.all?(chunks, &valid_chunk?/1) do
      :ok
    else
      {:error, :invalid_chunks}
    end
  end

  defp valid_chunk?(chunk) do
    expected_id = Chunks.calculate_chunk_id(chunk.data)
    chunk.id == expected_id
  end

  defp validate_sizes(index) do
    calculated_size = Enum.sum(Enum.map(index.chunks, & &1.size))

    if calculated_size == index.total_size do
      :ok
    else
      {:error, :size_mismatch}
    end
  end

  defp validate_checksum(index) do
    if index.checksum do
      :ok
    else
      {:error, :missing_checksum}
    end
  end

  defp calculate_index_checksum(chunks) do
    chunk_ids = Enum.map(chunks, & &1.id)
    combined = Enum.join(chunk_ids)
    :crypto.hash(:sha256, combined)
  end
end
