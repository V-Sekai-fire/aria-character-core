# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Chunks.Core do
  @moduledoc "Core chunking algorithms and chunk creation functionality.\n\nThis module contains the main chunking logic that uses rolling hash\nto create content-defined chunks from files.\n"
  alias AriaStorage.Chunks
  alias AriaStorage.Chunks.RollingHash
  alias AriaStorage.Chunks.Compression
  @default_min_chunk_size 16 * 1024
  @default_avg_chunk_size 64 * 1024
  @default_max_chunk_size 256 * 1024
  @type chunking_options :: [
          min_size: pos_integer(),
          avg_size: pos_integer(),
          max_size: pos_integer(),
          parallel: pos_integer(),
          compression: Compression.compression_algorithm()
        ]
  @type chunking_result :: {:ok, [Chunks.t()]} | {:error, atom() | {atom(), any()}}
  @doc "Creates content-defined chunks from a file using rolling hash algorithm.\n\nOptions:\n- `:min_size` - Minimum chunk size (default: 16KB)\n- `:avg_size` - Average chunk size (default: 64KB)\n- `:max_size` - Maximum chunk size (default: 256KB)\n- `:parallel` - Number of parallel chunking processes (default: CPU count)\n- `:compression` - Compression algorithm (:zstd, :none) (default: :zstd)\n"
  @spec create_chunks(String.t(), chunking_options()) :: chunking_result()
  def create_chunks(file_path, opts \\ []) do
    min_size = Keyword.get(opts, :min_size, @default_min_chunk_size)
    avg_size = Keyword.get(opts, :avg_size, @default_avg_chunk_size)
    max_size = Keyword.get(opts, :max_size, @default_max_chunk_size)
    _parallel = Keyword.get(opts, :parallel, System.schedulers_online())
    compression = Keyword.get(opts, :compression, :zstd)
    validate_chunk_sizes!(min_size, avg_size, max_size)

    case File.stat(file_path) do
      {:ok, %{size: file_size}} ->
        if file_size < max_size do
          create_single_chunk(file_path, compression)
        else
          create_rolling_hash_chunks(file_path, min_size, avg_size, max_size, compression)
        end

      {:error, reason} ->
        {:error, {:file_access, reason}}
    end
  end

  @doc "Finds all chunks in a binary data using the rolling hash algorithm.\n\nThis function is exported for testing and verification purposes.\n\n## Parameters\n  - data: Binary data to chunk\n  - min_size: Minimum chunk size\n  - max_size: Maximum chunk size\n  - discriminator: Boundary discriminator value\n  - compression: Compression algorithm to use for chunks\n\n## Returns\n  - List of chunk structs\n"
  @spec find_all_chunks_in_data(
          binary(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          Compression.compression_algorithm()
        ) :: [Chunks.t()]
  def find_all_chunks_in_data(data, min_size, max_size, discriminator, compression) do
    find_chunks_recursively(data, min_size, max_size, discriminator, compression, 0, [])
  end

  @doc "Create a chunk from binary data with specified offset and compression.\n"
  @spec create_chunk_from_data(binary(), non_neg_integer(), Compression.compression_algorithm()) ::
          {:ok, Chunks.t()} | {:error, any()}
  def create_chunk_from_data(data, offset, compression) do
    case Compression.compress_chunk(data, compression) do
      {:ok, compressed_data} ->
        chunk = %Chunks{
          id: Chunks.calculate_chunk_id(data),
          data: data,
          size: byte_size(data),
          compressed: compressed_data,
          offset: offset,
          checksum: :crypto.hash(:sha256, data)
        }

        {:ok, chunk}

      {:error, _} ->
        chunk = %Chunks{
          id: Chunks.calculate_chunk_id(data),
          data: data,
          size: byte_size(data),
          compressed: data,
          offset: offset,
          checksum: :crypto.hash(:sha256, data)
        }

        {:ok, chunk}
    end
  end

  @spec validate_chunk_sizes!(pos_integer(), pos_integer(), pos_integer()) :: :ok | no_return()
  defp validate_chunk_sizes!(min_size, avg_size, max_size) do
    window_size = RollingHash.window_size()

    cond do
      min_size < window_size ->
        raise ArgumentError, "Minimum chunk size must be >= #{window_size} bytes"

      min_size >= avg_size ->
        raise ArgumentError, "Minimum chunk size must be < average chunk size"

      avg_size >= max_size ->
        raise ArgumentError, "Average chunk size must be < maximum chunk size"

      min_size > avg_size / 4 ->
        raise ArgumentError, "For best results, min should be avg/4"

      max_size < 4 * avg_size ->
        raise ArgumentError, "For best results, max should be 4*avg"

      true ->
        :ok
    end
  end

  @spec create_single_chunk(String.t(), Compression.compression_algorithm()) :: chunking_result()
  defp create_single_chunk(file_path, compression) do
    case File.read(file_path) do
      {:ok, data} ->
        case create_chunk_from_data(data, 0, compression) do
          {:ok, chunk} -> {:ok, [chunk]}
        end

      {:error, reason} ->
        {:error, {:file_read, reason}}
    end
  end

  @spec create_rolling_hash_chunks(
          String.t(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          Compression.compression_algorithm()
        ) :: chunking_result()
  defp create_rolling_hash_chunks(file_path, min_size, avg_size, max_size, compression) do
    discriminator = RollingHash.discriminator_from_avg(avg_size)

    case File.open(file_path, [:read, :binary]) do
      {:ok, file} ->
        try do
          chunks =
            rolling_hash_chunk_file(
              file,
              min_size,
              avg_size,
              max_size,
              discriminator,
              compression,
              0,
              []
            )

          {:ok, Enum.reverse(chunks)}
        after
          File.close(file)
        end

      {:error, reason} ->
        {:error, {:file_open, reason}}
    end
  end

  @spec rolling_hash_chunk_file(
          File.io_device(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          Compression.compression_algorithm(),
          non_neg_integer(),
          [Chunks.t()]
        ) :: [Chunks.t()]
  defp rolling_hash_chunk_file(
         file,
         min_size,
         _avg_size,
         max_size,
         discriminator,
         compression,
         offset,
         acc
       ) do
    case IO.binread(file, :eof) do
      :eof ->
        acc

      data when byte_size(data) <= min_size ->
        case create_chunk_from_data(data, offset, compression) do
          {:ok, chunk} -> [chunk | acc]
        end

      data ->
        chunks = find_all_chunks_in_data(data, min_size, max_size, discriminator, compression)
        chunks ++ acc
    end
  end

  @spec find_chunks_recursively(
          binary(),
          pos_integer(),
          pos_integer(),
          pos_integer(),
          Compression.compression_algorithm(),
          non_neg_integer(),
          [Chunks.t()]
        ) :: [Chunks.t()]
  defp find_chunks_recursively(
         data,
         _min_size,
         _max_size,
         _discriminator,
         _compression,
         current_offset,
         chunks
       )
       when current_offset >= byte_size(data) do
    Enum.reverse(chunks)
  end

  defp find_chunks_recursively(
         data,
         min_size,
         max_size,
         discriminator,
         compression,
         current_offset,
         chunks
       ) do
    remaining_size = byte_size(data) - current_offset

    if remaining_size <= min_size do
      chunk_data = binary_part(data, current_offset, remaining_size)

      case create_chunk_from_data(chunk_data, current_offset, compression) do
        {:ok, chunk} -> Enum.reverse([chunk | chunks])
        _ -> Enum.reverse(chunks)
      end
    else
      chunk_end =
        RollingHash.find_chunk_boundary(data, current_offset, min_size, max_size, discriminator)

      chunk_size = chunk_end - current_offset
      chunk_data = binary_part(data, current_offset, chunk_size)

      case create_chunk_from_data(chunk_data, current_offset, compression) do
        {:ok, chunk} ->
          find_chunks_recursively(
            data,
            min_size,
            max_size,
            discriminator,
            compression,
            chunk_end,
            [chunk | chunks]
          )

        _ ->
          find_chunks_recursively(
            data,
            min_size,
            max_size,
            discriminator,
            compression,
            chunk_end,
            chunks
          )
      end
    end
  end
end
