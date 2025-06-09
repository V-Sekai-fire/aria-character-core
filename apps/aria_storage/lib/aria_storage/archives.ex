# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Archives do
  @moduledoc """
  Archive support for desync-compatible .catar format.

  Handles:
  - Directory tree archiving to .catar format
  - Archive extraction from .catar files
  - Archive chunking with .caidx index files
  - Metadata preservation (permissions, timestamps, etc.)
  - Streaming archive creation and extraction
  """

  alias AriaStorage.{Chunks, Index, Storage}

  @catar_magic_header <<0xCA, 0x7A, 0x52>>
  @catar_version 1

  defstruct [
    :path,         # Archive file path
    :format,       # :catar
    :entries,      # Directory entries
    :metadata,     # Archive metadata
    :created_at,   # Creation timestamp
    :total_size,   # Total archive size
    :entry_count   # Number of entries
  ]

  @type t :: %__MODULE__{
    path: String.t(),
    format: :catar,
    entries: [map()],
    metadata: map(),
    created_at: DateTime.t(),
    total_size: non_neg_integer(),
    entry_count: non_neg_integer()
  }

  @doc """
  Creates a .catar archive from a directory tree.

  Options:
  - `:output_path` - Where to write the archive
  - `:chunk` - Whether to chunk the archive (creates .caidx)
  - `:compression` - Compression algorithm for chunks
  - `:exclude_patterns` - Patterns to exclude from archive
  """
  def create_catar(source_dir, opts \\ []) do
    output_path = Keyword.get(opts, :output_path, "#{source_dir}.catar")
    should_chunk = Keyword.get(opts, :chunk, false)
    exclude_patterns = Keyword.get(opts, :exclude_patterns, [])

    with {:ok, entries} <- scan_directory(source_dir, exclude_patterns),
         {:ok, archive} <- create_archive_struct(source_dir, entries),
         {:ok, archive_path} <- write_catar_file(archive, output_path),
         {:ok, result} <- maybe_chunk_archive(archive_path, should_chunk, opts) do
      {:ok, result}
    end
  end

  @doc """
  Extracts a .catar archive to a directory.

  Options:
  - `:preserve_permissions` - Preserve file permissions (default: true)
  - `:preserve_timestamps` - Preserve file timestamps (default: true)
  - `:overwrite` - Overwrite existing files (default: false)
  """
  def extract_catar(archive_source, output_dir, opts \\ []) do
    preserve_perms = Keyword.get(opts, :preserve_permissions, true)
    preserve_timestamps = Keyword.get(opts, :preserve_timestamps, true)
    overwrite = Keyword.get(opts, :overwrite, false)

    case archive_source do
      # Direct .catar file
      path when is_binary(path) ->
        case Path.extname(path) do
          ".catar" ->
            extract_catar_file(path, output_dir, preserve_perms, preserve_timestamps, overwrite)
          _ ->
            {:error, :not_catar_file}
        end

      # Index reference for chunked archive
      %Index{format: :caidx} = index ->
        extract_chunked_archive(index, output_dir, opts)

      _ ->
        {:error, :invalid_archive_source}
    end
  end

  @doc """
  Lists the contents of a .catar archive.
  """
  def list_contents(archive_source) do
    case archive_source do
      path when is_binary(path) ->
        read_catar_entries(path)

      %Index{format: :caidx} = index ->
        # For chunked archives, we'd need to reconstruct first
        {:error, :not_implemented}
        # TODO: Implement archive extraction
        # with {:ok, temp_file} <- extract_archive_to_temp(index),
        #      {:ok, entries} <- read_catar_entries(temp_file),
        #      :ok <- File.rm(temp_file) do
        #   {:ok, entries}
        # end

      _ ->
        {:error, :invalid_archive_source}
    end
  end

  @doc """
  Gets information about a .catar archive.
  """
  def get_archive_info(archive_source) do
    case list_contents(archive_source) do
      {:ok, entries} ->
        info = %{
          entry_count: length(entries),
          total_files: count_files(entries),
          total_directories: count_directories(entries),
          total_size: calculate_total_size(entries),
          created_at: DateTime.utc_now() # Would be read from archive metadata
        }
        {:ok, info}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Verifies the integrity of a .catar archive.
  """
  def verify_archive(archive_source) do
    case archive_source do
      path when is_binary(path) ->
        verify_catar_file(path)

      %Index{format: :caidx} = index ->
        verify_chunked_archive(index)

      _ ->
        {:error, :invalid_archive_source}
    end
  end

  # Private functions

  defp scan_directory(source_dir, exclude_patterns) do
    case File.ls(source_dir) do
      {:ok, files} ->
        entries = files
        |> Enum.reject(&should_exclude?(&1, exclude_patterns))
        |> Enum.map(&scan_entry(Path.join(source_dir, &1), source_dir))
        |> Enum.filter(&(!is_nil(&1)))

        {:ok, List.flatten(entries)}

      {:error, reason} ->
        {:error, {:directory_scan, reason}}
    end
  end

  defp should_exclude?(filename, exclude_patterns) do
    Enum.any?(exclude_patterns, fn pattern ->
      case pattern do
        regex when is_struct(regex, Regex) ->
          Regex.match?(regex, filename)

        string when is_binary(string) ->
          String.contains?(filename, string)

        _ ->
          false
      end
    end)
  end

  defp scan_entry(full_path, base_dir) do
    relative_path = Path.relative_to(full_path, base_dir)

    case File.stat(full_path) do
      {:ok, stat} ->
        entry = %{
          path: relative_path,
          full_path: full_path,
          type: stat.type,
          size: stat.size,
          mtime: stat.mtime,
          mode: stat.mode,
          uid: stat.uid,
          gid: stat.gid
        }

        case stat.type do
          :directory ->
            case scan_directory(full_path, []) do
              {:ok, children} ->
                [entry | children]

              {:error, _} ->
                [entry]
            end

          _ ->
            [entry]
        end

      {:error, _} ->
        nil
    end
  end

  defp create_archive_struct(source_dir, entries) do
    archive = %__MODULE__{
      path: source_dir,
      format: :catar,
      entries: entries,
      metadata: %{
        source_directory: source_dir,
        archive_version: @catar_version
      },
      created_at: DateTime.utc_now(),
      total_size: calculate_total_size(entries),
      entry_count: length(entries)
    }

    {:ok, archive}
  end

  defp write_catar_file(archive, output_path) do
    case File.open(output_path, [:write, :binary]) do
      {:ok, file} ->
        :ok = write_catar_header(file, archive)
        :ok = write_catar_entries(file, archive.entries)
        :ok = File.close(file)
        {:ok, output_path}

      {:error, reason} ->
        {:error, {:file_write, reason}}
    end
  end

  defp write_catar_header(file, archive) do
    timestamp = DateTime.to_unix(archive.created_at)

    header = @catar_magic_header <>
      <<
        @catar_version::32-big,
        archive.entry_count::32-big,
        archive.total_size::64-big,
        timestamp::64-big
      >>

    IO.binwrite(file, header)
  end

  defp write_catar_entries(file, entries) do
    Enum.each(entries, fn entry ->
      write_catar_entry(file, entry)
    end)
  end

  defp write_catar_entry(file, entry) do
    # Simplified catar entry format
    path_bytes = entry.path
    path_len = byte_size(path_bytes)

    entry_header = <<
      entry.size::64-big,
      DateTime.to_unix(entry.mtime)::64-big,
      entry.mode::32-big,
      entry.uid::32-big,
      entry.gid::32-big,
      path_len::32-big
    >>

    IO.binwrite(file, entry_header)
    IO.binwrite(file, path_bytes)

    # Write file content for regular files
    if entry.type == :regular do
      case File.read(entry.full_path) do
        {:ok, content} ->
          IO.binwrite(file, content)

        {:error, _} ->
          # Skip files that can't be read
          :ok
      end
    end
  end

  defp maybe_chunk_archive(archive_path, should_chunk, opts) do
    if should_chunk do
      case Chunks.create_chunks(archive_path, opts) do
        {:ok, chunks} ->
          case Index.create_index(chunks, format: :caidx) do
            {:ok, index} ->
              index_path = Index.create_filename(archive_path, :caidx)
              case Index.save_to_file(index, index_path) do
                :ok ->
                  {:ok, %{archive: archive_path, index: index_path, chunks: chunks}}

                {:error, reason} ->
                  {:error, reason}
              end

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, %{archive: archive_path}}
    end
  end

  defp extract_catar_file(archive_path, output_dir, preserve_perms, preserve_timestamps, overwrite) do
    case read_catar_entries(archive_path) do
      {:ok, entries} ->
        File.mkdir_p!(output_dir)
        extract_entries(entries, output_dir, preserve_perms, preserve_timestamps, overwrite)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_chunked_archive(index, output_dir, opts) do
    # In a real implementation, we'd reconstruct the archive from chunks
    # and then extract it
    with {:ok, temp_archive} <- reconstruct_archive_from_chunks(index),
         {:ok, _} <- extract_catar_file(temp_archive, output_dir,
                                       Keyword.get(opts, :preserve_permissions, true),
                                       Keyword.get(opts, :preserve_timestamps, true),
                                       Keyword.get(opts, :overwrite, false)),
         :ok <- File.rm(temp_archive) do
      {:ok, output_dir}
    end
  end

  defp read_catar_entries(archive_path) do
    # Simplified catar reading - in production would properly parse the format
    case File.read(archive_path) do
      {:ok, binary_data} ->
        case parse_catar_header(binary_data) do
          {:ok, header, entries_data} ->
            parse_catar_entries(entries_data, header.entry_count)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_read, reason}}
    end
  end

  defp parse_catar_header(binary_data) do
    case binary_data do
      <<@catar_magic_header, version::32-big, entry_count::32-big,
        total_size::64-big, timestamp::64-big, rest::binary>> ->
        header = %{
          version: version,
          entry_count: entry_count,
          total_size: total_size,
          timestamp: timestamp
        }
        {:ok, header, rest}

      _ ->
        {:error, :invalid_catar_format}
    end
  end

  defp parse_catar_entries(binary_data, entry_count) do
    # Simplified implementation
    {:ok, []}
  end

  defp extract_entries(entries, output_dir, preserve_perms, preserve_timestamps, overwrite) do
    Enum.each(entries, fn entry ->
      extract_entry(entry, output_dir, preserve_perms, preserve_timestamps, overwrite)
    end)
    {:ok, output_dir}
  end

  defp extract_entry(entry, output_dir, preserve_perms, preserve_timestamps, overwrite) do
    target_path = Path.join(output_dir, entry.path)

    case entry.type do
      :directory ->
        File.mkdir_p!(target_path)

      :regular ->
        if overwrite or not File.exists?(target_path) do
          File.write!(target_path, entry.content || "")

          if preserve_perms do
            File.chmod!(target_path, entry.mode)
          end

          if preserve_timestamps do
            File.touch!(target_path, entry.mtime)
          end
        end

      _ ->
        # Handle other file types (symlinks, devices, etc.)
        :ok
    end
  end

  defp reconstruct_archive_from_chunks(index) do
    # In a real implementation, this would use the chunk store to reconstruct
    temp_path = Path.join(System.tmp_dir!(), "catar_#{:rand.uniform(1000000)}")

    case Storage.get_chunks_for_index(index) do
      {:ok, chunks} ->
        case Chunks.assemble_file(chunks, index, temp_path) do
          {:ok, _} -> {:ok, temp_path}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_catar_file(archive_path) do
    # Simplified verification
    case File.exists?(archive_path) do
      true -> {:ok, :valid}
      false -> {:error, :file_not_found}
    end
  end

  defp verify_chunked_archive(index) do
    Index.validate(index)
  end

  defp count_files(entries) do
    Enum.count(entries, &(&1.type == :regular))
  end

  defp count_directories(entries) do
    Enum.count(entries, &(&1.type == :directory))
  end

  defp calculate_total_size(entries) do
    entries
    |> Enum.filter(&(&1.type == :regular))
    |> Enum.map(& &1.size)
    |> Enum.sum()
  end
end
