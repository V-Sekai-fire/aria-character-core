# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.Encoder do
  @moduledoc "Encoder for ARCANA format files.\n\nProvides encoding functions for CAIBX/CAIDX index files, CACNK chunk files,\nand CATAR archive files, maintaining compatibility with casync/desync tools.\n"
  alias AriaStorage.Parsers.CasyncFormat.Constants
  require AriaStorage.Parsers.CasyncFormat.Constants
  @type encode_result :: {:ok, binary()} | {:error, String.t()}
  @doc "Encode index data to binary format (CAIBX/CAIDX).\n\nSupports both blob index (CAIBX) and directory index (CAIDX) formats\nwith bit-exact roundtrip encoding when original table data is preserved.\n"
  @spec encode_index(map()) :: encode_result()
  def encode_index(%{
        format: format,
        _original_table_data: original_table_data,
        feature_flags: feature_flags,
        chunk_size_min: chunk_size_min,
        chunk_size_avg: chunk_size_avg,
        chunk_size_max: chunk_size_max
      })
      when format in [:caibx, :caidx] do
    format_index =
      <<48::little-64, Constants.ca_format_index()::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64>>

    result = format_index <> original_table_data
    {:ok, result}
  end

  def encode_index(%{
        format: format,
        header: _header,
        chunks: chunks,
        feature_flags: feature_flags,
        chunk_size_min: chunk_size_min,
        chunk_size_avg: chunk_size_avg,
        chunk_size_max: chunk_size_max
      })
      when format in [:caibx, :caidx] do
    format_index =
      <<48::little-64, Constants.ca_format_index()::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64>>

    case chunks do
      [] ->
        {:ok, format_index}

      _ ->
        table_items =
          Enum.reduce(chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
            new_offset = current_offset + chunk.size
            item = <<new_offset::little-64>> <> chunk.chunk_id
            {acc <> item, new_offset}
          end)
          |> elem(0)

        table_size = byte_size(table_items) + 48

        format_table_header =
          <<18_446_744_073_709_551_615::little-64, Constants.ca_format_table()::little-64>>

        table_tail =
          <<0::little-64, 0::little-64, 48::little-64, table_size::little-64,
            Constants.ca_format_table_tail_marker()::little-64>>

        result = format_index <> format_table_header <> table_items <> table_tail
        {:ok, result}
    end
  end

  @doc "Encode chunk data to binary format (CACNK).\n\nCreates a CACNK file with proper magic bytes and header information.\n"
  @spec encode_chunk(map()) :: encode_result()
  def encode_chunk(%{header: header, data: data}) do
    magic = <<202, 196, 78>>
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  @doc "Encode archive data to binary format (CATAR).\n\nSupports encoding from elements structure for full compatibility\nwith casync/desync CATAR format.\n"
  @spec encode_archive(map()) :: encode_result()
  def encode_archive(%{format: :catar, elements: elements}) when is_list(elements) do
    encoded_data =
      Enum.reduce(elements, <<>>, fn element, acc ->
        encoded_element = encode_catar_element(element)
        acc <> encoded_element
      end)

    {:ok, encoded_data}
  end

  def encode_archive(%{format: :catar, entries: entries, remaining_data: remaining_data}) do
    case entries do
      [entry | _] ->
        encoded_entry =
          <<entry.size::little-64, entry.type::little-64, entry.flags::little-64, 0::little-64,
            entry.mode::little-64, entry.uid::little-64, entry.gid::little-64,
            entry.mtime::little-64>>

        {:ok, encoded_entry <> remaining_data}

      [] ->
        {:ok, remaining_data}
    end
  end

  def encode_archive(%{format: :catar}) do
    {:error, "CATAR format encoding requires 'elements' field"}
  end

  @spec encode_chunk_header(Constants.chunk_header()) :: binary()
  defp encode_chunk_header(%{
         compressed_size: compressed_size,
         uncompressed_size: uncompressed_size,
         compression: compression,
         flags: flags
       }) do
    compression_type = encode_compression_type(compression)

    <<compressed_size::little-32>> <>
      <<uncompressed_size::little-32>> <> <<compression_type::little-32>> <> <<flags::little-32>>
  end

  defp encode_chunk_header(%{}) do
    <<0::little-32, 0::little-32, 0::little-32, 0::little-32>>
  end

  @spec encode_compression_type(Constants.compression_type()) :: non_neg_integer()
  defp encode_compression_type(compression) do
    case compression do
      :none -> Constants.compression_none()
      :zstd -> Constants.compression_zstd()
      :unknown -> Constants.compression_none()
    end
  end

  @spec encode_catar_element(Constants.catar_element()) :: binary()
  defp encode_catar_element(%{
         type: :entry,
         size: size,
         feature_flags: feature_flags,
         mode: mode,
         uid: uid,
         gid: gid,
         mtime: mtime
       }) do
    uid_gid_data_size = size - 16 - 8 - 8 - 8 - 8

    case uid_gid_data_size do
      4 ->
        <<size::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
          mode::little-64, 0::little-64, gid::little-16, uid::little-16, mtime::little-64>>

      8 ->
        <<size::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
          mode::little-64, 0::little-64, gid::little-32, uid::little-32, mtime::little-64>>

      16 ->
        <<size::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
          mode::little-64, 0::little-64, gid::little-64, uid::little-64, mtime::little-64>>

      _ ->
        cond do
          Bitwise.band(feature_flags, Constants.ca_format_with_16_bit_uids()) != 0 ->
            <<52::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
              mode::little-64, 0::little-64, gid::little-16, uid::little-16, mtime::little-64>>

          Bitwise.band(feature_flags, Constants.ca_format_with_32_bit_uids()) != 0 ->
            <<56::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
              mode::little-64, 0::little-64, gid::little-32, uid::little-32, mtime::little-64>>

          true ->
            <<64::little-64, Constants.ca_format_entry()::little-64, feature_flags::little-64,
              mode::little-64, 0::little-64, gid::little-64, uid::little-64, mtime::little-64>>
        end
    end
  end

  defp encode_catar_element(%{type: :filename, name: name}) do
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size
    <<total_size::little-64, Constants.ca_format_filename()::little-64>> <> name_data
  end

  defp encode_catar_element(%{type: :payload, size: size, data: data}) do
    total_size = 16 + size
    <<total_size::little-64, Constants.ca_format_payload()::little-64>> <> data
  end

  defp encode_catar_element(%{type: :symlink, target: target}) do
    target_data = target <> <<0>>
    target_size = byte_size(target_data)
    total_size = 16 + target_size
    <<total_size::little-64, Constants.ca_format_symlink()::little-64>> <> target_data
  end

  defp encode_catar_element(%{type: :device, major: major, minor: minor}) do
    <<32::little-64, Constants.ca_format_device()::little-64, major::little-64, minor::little-64>>
  end

  defp encode_catar_element(%{type: :goodbye, items: items}) do
    items_data =
      Enum.reduce(items, <<>>, fn item, acc ->
        acc <> <<item.offset::little-64, item.size::little-64, item.hash::little-64>>
      end)

    items_size = byte_size(items_data)
    total_size = 16 + items_size
    <<total_size::little-64, Constants.ca_format_goodbye()::little-64>> <> items_data
  end

  defp encode_catar_element(%{type: :user, name: name}) do
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size
    <<total_size::little-64, Constants.ca_format_user()::little-64>> <> name_data
  end

  defp encode_catar_element(%{type: :group, name: name}) do
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size
    <<total_size::little-64, Constants.ca_format_group()::little-64>> <> name_data
  end

  defp encode_catar_element(%{type: :selinux, context: context}) do
    context_data = context <> <<0>>
    context_size = byte_size(context_data)
    total_size = 16 + context_size
    <<total_size::little-64, Constants.ca_format_selinux()::little-64>> <> context_data
  end

  defp encode_catar_element(%{type: :xattr, data: data}) do
    data_size = byte_size(data)
    total_size = 16 + data_size
    <<total_size::little-64, Constants.ca_format_xattr()::little-64>> <> data
  end

  defp encode_catar_element(%{type: :metadata, format: format_type, size: data_size, data: data}) do
    total_size = 16 + data_size
    <<total_size::little-64, format_type::little-64>> <> data
  end

  defp encode_catar_element(%{type: unknown_type} = element) do
    raise "Unknown CATAR element type: #{inspect(unknown_type)} in element: #{inspect(element)}"
  end
end
