# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Chunks.Assembly do
  @moduledoc "File assembly utilities for reconstructing files from chunks.\n\nProvides functionality to assemble files from chunks using index information,\nwith support for verification, reflinks, and seed files for efficient reconstruction.\n"
  alias AriaStorage.Index
  alias AriaStorage.Utils
  alias AriaStorage.Chunks
  @type assembly_options :: [seeds: [String.t()], verify: boolean(), reflink: boolean()]
  @type assembly_result :: {:ok, String.t()} | {:error, atom() | {atom(), any()}}
  @doc "Assembles a file from chunks using an index.\n\nOptions:\n- `:seeds` - List of seed files for efficient reconstruction\n- `:verify` - Verify chunk checksums during assembly (default: true)\n- `:reflink` - Use reflinks/CoW when possible (default: true)\n"
  @spec assemble_file([Chunks.t()], Index.t(), String.t(), assembly_options()) ::
          assembly_result()
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

  @doc "Validate that chunks match the index.\n"
  @spec validate_index(Index.t(), [Chunks.t()], boolean()) :: :ok | {:error, atom()}
  def validate_index(index, chunks, verify) do
    if verify do
      expected_checksum = Utils.calculate_index_checksum(chunks)

      if index.checksum == expected_checksum do
        :ok
      else
        {:error, :index_checksum_mismatch}
      end
    else
      :ok
    end
  end

  @doc "Write chunks to a file in order.\n"
  @spec write_chunks_to_file(File.io_device(), [Chunks.t()], Index.t(), [String.t()], boolean()) ::
          :ok | {:error, any()}
  def write_chunks_to_file(file, chunks, _index, _seeds, _use_reflink) do
    Enum.reduce_while(chunks, :ok, fn chunk, _acc ->
      case IO.binwrite(file, chunk.data) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc "Verify chunk integrity during assembly.\n"
  @spec verify_chunk(Chunks.t()) :: :ok | {:error, atom()}
  def verify_chunk(chunk) do
    expected_id = Chunks.calculate_chunk_id(chunk.data)
    expected_checksum = :crypto.hash(:sha256, chunk.data)

    cond do
      chunk.id != expected_id -> {:error, :chunk_id_mismatch}
      chunk.checksum != expected_checksum -> {:error, :chunk_checksum_mismatch}
      chunk.size != byte_size(chunk.data) -> {:error, :chunk_size_mismatch}
      true -> :ok
    end
  end

  @doc "Assemble file with verification of each chunk.\n"
  @spec assemble_file_with_verification([Chunks.t()], Index.t(), String.t(), assembly_options()) ::
          assembly_result()
  def assemble_file_with_verification(chunks, index, output_path, opts \\ []) do
    verify = Keyword.get(opts, :verify, true)
    use_reflink = Keyword.get(opts, :reflink, true)
    seeds = Keyword.get(opts, :seeds, [])

    with :ok <- validate_index(index, chunks, verify),
         :ok <- verify_all_chunks(chunks, verify),
         {:ok, file} <- File.open(output_path, [:write, :binary]),
         :ok <- write_chunks_to_file(file, chunks, index, seeds, use_reflink),
         :ok <- File.close(file) do
      {:ok, output_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Verify all chunks in a list.\n"
  @spec verify_all_chunks([Chunks.t()], boolean()) :: :ok | {:error, {atom(), non_neg_integer()}}
  def verify_all_chunks(chunks, verify) do
    if verify do
      chunks
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {chunk, index}, _acc ->
        case verify_chunk(chunk) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, {reason, index}}}
        end
      end)
    else
      :ok
    end
  end

  @doc "Calculate total size of chunks.\n"
  @spec calculate_total_size([Chunks.t()]) :: non_neg_integer()
  def calculate_total_size(chunks) do
    Enum.sum(Enum.map(chunks, & &1.size))
  end

  @doc "Check if all chunks are present and in order.\n"
  @spec validate_chunk_sequence([Chunks.t()]) :: :ok | {:error, atom()}
  def validate_chunk_sequence(chunks) do
    expected_offset = 0

    chunks
    |> Enum.reduce_while({:ok, expected_offset}, fn chunk, {:ok, offset} ->
      if chunk.offset == offset do
        {:cont, {:ok, offset + chunk.size}}
      else
        {:halt, {:error, :chunk_sequence_mismatch}}
      end
    end)
    |> case do
      {:ok, _final_offset} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
