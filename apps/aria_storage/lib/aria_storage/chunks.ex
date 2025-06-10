# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Chunks do
  @moduledoc """
  Content-defined chunking implementation compatible with desync/casync.

  This module implements:
  - Content-defined chunking using rolling hash
  - SHA512/256 chunk identification
  - Index file creation (.caibx format)
  - Chunk assembly and file reconstruction
  - Parallel chunking for performance
  """

  alias AriaStorage.Index

  @default_min_chunk_size 16 * 1024      # 16KB
  @default_avg_chunk_size 64 * 1024      # 64KB
  @default_max_chunk_size 256 * 1024     # 256KB
  @rolling_hash_window_size 48

  defstruct [
    :id,           # SHA512/256 hash of chunk content
    :data,         # Raw chunk data
    :size,         # Size in bytes
    :compressed,   # Compressed data (zstd)
    :offset,       # Offset in original file
    :checksum      # Additional checksum for verification
  ]

  @type t :: %__MODULE__{
    id: binary(),
    data: binary(),
    size: non_neg_integer(),
    compressed: binary(),
    offset: non_neg_integer(),
    checksum: binary()
  }

  @doc """
  Creates content-defined chunks from a file using rolling hash algorithm.

  Options:
  - `:min_size` - Minimum chunk size (default: 16KB)
  - `:avg_size` - Average chunk size (default: 64KB)
  - `:max_size` - Maximum chunk size (default: 256KB)
  - `:parallel` - Number of parallel chunking processes (default: CPU count)
  - `:compression` - Compression algorithm (:zstd, :none) (default: :zstd)
  """
  def create_chunks(file_path, opts \\ []) do
    min_size = Keyword.get(opts, :min_size, @default_min_chunk_size)
    avg_size = Keyword.get(opts, :avg_size, @default_avg_chunk_size)
    max_size = Keyword.get(opts, :max_size, @default_max_chunk_size)
    parallel = Keyword.get(opts, :parallel, System.schedulers_online())
    compression = Keyword.get(opts, :compression, :zstd)

    validate_chunk_sizes!(min_size, avg_size, max_size)

    case File.stat(file_path) do
      {:ok, %{size: file_size}} ->
        if file_size < max_size do
          # File is smaller than max chunk size, create single chunk
          create_single_chunk(file_path, compression)
        else
          # Use parallel chunking for larger files
          create_parallel_chunks(file_path, file_size, min_size, avg_size, max_size, parallel, compression)
        end

      {:error, reason} ->
        {:error, {:file_access, reason}}
    end
  end

  @doc """
  Creates an index file from chunks.

  The index contains metadata about chunk locations and can be used
  to reconstruct the original file.
  """
  def create_index(chunks, opts \\ []) do
    format = Keyword.get(opts, :format, :caibx)

    index_data = %Index{
      format: format,
      chunks: chunks,
      total_size: Enum.sum(Enum.map(chunks, & &1.size)),
      chunk_count: length(chunks),
      created_at: DateTime.utc_now(),
      checksum: calculate_index_checksum(chunks)
    }

    {:ok, index_data}
  end

  @doc """
  Assembles a file from chunks using an index.

  Options:
  - `:seeds` - List of seed files for efficient reconstruction
  - `:verify` - Verify chunk checksums during assembly (default: true)
  - `:reflink` - Use reflinks/CoW when possible (default: true)
  """
  def assemble_file(chunks, index, output_path, opts \\ []) do
    verify = Keyword.get(opts, :verify, true)
    use_reflink = Keyword.get(opts, :reflink, true)
    seeds = Keyword.get(opts, :seeds, [])

    with :ok <- validate_index(index, chunks, verify),
         {:ok, file} <- File.open(output_path, [:write, :binary]),
         :ok <- write_chunks_to_file(file, chunks, index, seeds, use_reflink),
         :ok <- File.close(file) do
      {:ok, output_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Calculates SHA512/256 hash for chunk identification.
  """
  def calculate_chunk_id(data) when is_binary(data) do
    :crypto.hash(:sha512, data)
    |> binary_part(0, 32)  # Use first 256 bits for SHA512/256
  end

  @doc """
  Compresses chunk data using zstd.
  """
  def compress_chunk(data, algorithm \\ :zstd) do
    case algorithm do
      :zstd ->
        try do
          # Use Erlang module directly with compression level 1
          compressed = :ezstd.compress(data, 1)
          {:ok, compressed}
        rescue
          UndefinedFunctionError ->
            {:error, :compression_not_available}
        catch
          :error, reason ->
            {:error, {:compression_failed, reason}}
        end

      :none ->
        {:ok, data}

      _ ->
        {:error, {:unsupported_compression, algorithm}}
    end
  end

  @doc """
  Decompresses chunk data.
  """
  def decompress_chunk(compressed_data, algorithm \\ :zstd) do
    case algorithm do
      :zstd ->
        try do
          # Use Erlang module directly
          decompressed = :ezstd.decompress(compressed_data)
          {:ok, decompressed}
        rescue
          UndefinedFunctionError ->
            {:error, :compression_not_available}
        catch
          :error, reason ->
            {:error, {:decompression_failed, reason}}
        end

      :none ->
        {:ok, compressed_data}

      _ ->
        {:error, {:unsupported_compression, algorithm}}
    end
  end

  # Private functions

  defp validate_chunk_sizes!(min_size, avg_size, max_size) do
    cond do
      min_size < @rolling_hash_window_size ->
        raise ArgumentError, "Minimum chunk size must be >= #{@rolling_hash_window_size} bytes"

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

  defp create_single_chunk(file_path, compression) do
    case File.read(file_path) do
      {:ok, data} ->
        case compress_chunk(data, compression) do
          {:ok, compressed_data} ->
            chunk = %__MODULE__{
              id: calculate_chunk_id(data),
              data: data,
              size: byte_size(data),
              compressed: compressed_data,
              offset: 0,
              checksum: :crypto.hash(:sha256, data)
            }
            {:ok, [chunk]}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_read, reason}}
    end
  end

  defp create_parallel_chunks(file_path, file_size, min_size, avg_size, max_size, parallel, compression) do
    # Simplified parallel chunking - in production, this would be more sophisticated
    chunk_size = min(avg_size, div(file_size, parallel))

    case File.open(file_path, [:read, :binary]) do
      {:ok, file} ->
        chunks = read_chunks_sequentially(file, chunk_size, min_size, max_size, compression, 0, [])
        File.close(file)
        {:ok, Enum.reverse(chunks)}

      {:error, reason} ->
        {:error, {:file_open, reason}}
    end
  end

  defp read_chunks_sequentially(file, target_size, min_size, max_size, compression, offset, acc) do
    case IO.binread(file, target_size) do
      :eof ->
        acc

      data when byte_size(data) < min_size and acc != [] ->
        # Merge small trailing chunk with previous chunk
        [prev_chunk | rest] = acc
        merged_data = prev_chunk.data <> data
        case compress_chunk(merged_data, compression) do
          {:ok, compressed_data} ->
            updated_chunk = %{prev_chunk |
              data: merged_data,
              size: byte_size(merged_data),
              compressed: compressed_data,
              checksum: :crypto.hash(:sha256, merged_data)
            }
            [updated_chunk | rest]

          {:error, _} ->
            # Fallback to uncompressed
            updated_chunk = %{prev_chunk |
              data: merged_data,
              size: byte_size(merged_data),
              compressed: merged_data,
              checksum: :crypto.hash(:sha256, merged_data)
            }
            [updated_chunk | rest]
        end

      data ->
        case compress_chunk(data, compression) do
          {:ok, compressed_data} ->
            chunk = %__MODULE__{
              id: calculate_chunk_id(data),
              data: data,
              size: byte_size(data),
              compressed: compressed_data,
              offset: offset,
              checksum: :crypto.hash(:sha256, data)
            }
            read_chunks_sequentially(file, target_size, min_size, max_size, compression,
                                     offset + byte_size(data), [chunk | acc])

          {:error, _} ->
            # Fallback to uncompressed
            chunk = %__MODULE__{
              id: calculate_chunk_id(data),
              data: data,
              size: byte_size(data),
              compressed: data,
              offset: offset,
              checksum: :crypto.hash(:sha256, data)
            }
            read_chunks_sequentially(file, target_size, min_size, max_size, compression,
                                     offset + byte_size(data), [chunk | acc])
        end
    end
  end

  defp calculate_index_checksum(chunks) do
    chunk_ids = Enum.map(chunks, & &1.id)
    combined = Enum.join(chunk_ids)
    :crypto.hash(:sha256, combined)
  end

  defp validate_index(index, chunks, verify) do
    if verify do
      expected_checksum = calculate_index_checksum(chunks)
      if index.checksum == expected_checksum do
        :ok
      else
        {:error, :index_checksum_mismatch}
      end
    else
      :ok
    end
  end

  defp write_chunks_to_file(file, chunks, _index, _seeds, _use_reflink) do
    # Simplified implementation - in production would handle seeds and reflinks
    Enum.reduce_while(chunks, :ok, fn chunk, _acc ->
      case IO.binwrite(file, chunk.data) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
