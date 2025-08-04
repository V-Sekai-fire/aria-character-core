# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.IndexParser do
  @moduledoc "Parser for CAIBX/CAIDX index files in the ARCANA format.\n\nHandles parsing of Content Archive Index files for both blobs (CAIBX)\nand directories (CAIDX) using direct binary pattern matching.\n"
  require AriaStorage.Parsers.CasyncFormat.Constants
  import AriaStorage.Parsers.CasyncFormat.Constants
  alias AriaStorage.Parsers.CasyncFormat.Constants
  @type parse_result :: {:ok, map()} | {:error, String.t()}
  @doc "Parse a caibx/caidx index file from binary data.\n\nFormat structure based on desync source:\n- FormatIndex header (48 bytes)\n- FormatTable with variable number of items (40 bytes each)\n- Table tail marker\n"
  @spec parse_index(binary()) :: parse_result()
  def parse_index(binary_data) when is_binary(binary_data) do
    case binary_data do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        remaining_data::binary>> ->
        if size_field == 48 and type_field == ca_format_index() do
          format_type =
            if feature_flags == 0 do
              :caidx
            else
              :caibx
            end

          case remaining_data do
            <<>> ->
              result = %{
                format: format_type,
                header: %{version: 1, total_size: 0, chunk_count: 0},
                chunks: [],
                feature_flags: feature_flags,
                chunk_size_min: chunk_size_min,
                chunk_size_avg: chunk_size_avg,
                chunk_size_max: chunk_size_max,
                _original_table_data: <<>>
              }

              {:ok, result}

            _ ->
              case parse_format_table_with_items_binary(remaining_data) do
                {:ok, table_items} ->
                  result = %{
                    format: format_type,
                    header: %{
                      version: 1,
                      total_size: calculate_total_size(table_items),
                      chunk_count: length(table_items)
                    },
                    chunks: convert_table_to_chunks(table_items),
                    feature_flags: feature_flags,
                    chunk_size_min: chunk_size_min,
                    chunk_size_avg: chunk_size_avg,
                    chunk_size_max: chunk_size_max,
                    _original_table_data: remaining_data
                  }

                  {:ok, result}

                {:error, reason} ->
                  {:error, reason}
              end
          end
        else
          {:error,
           "Invalid FormatIndex header: size=#{size_field}, type=0x#{Integer.to_string(type_field, 16)}"}
        end

      _ ->
        {:error, "Invalid binary data: insufficient data for FormatIndex header"}
    end
  end

  @spec parse_format_table_with_items_binary(binary()) ::
          {:ok, [Constants.table_item()]} | {:error, String.t()}
  defp parse_format_table_with_items_binary(binary_data) do
    case binary_data do
      <<table_marker::little-64, table_type::little-64, remaining_data::binary>> ->
        if table_marker == 18_446_744_073_709_551_615 and table_type == ca_format_table() do
          parse_table_items_binary(remaining_data, [])
        else
          {:error,
           "Invalid FormatTable header: marker=0x#{Integer.to_string(table_marker, 16)}, type=0x#{Integer.to_string(table_type, 16)}"}
        end

      _ ->
        {:error, "Invalid binary data: insufficient data for FormatTable header"}
    end
  end

  @spec parse_table_items_binary(binary(), [Constants.table_item()]) ::
          {:ok, [Constants.table_item()]} | {:error, String.t()}
  defp parse_table_items_binary(binary_data, acc) do
    case binary_data do
      <<zero1::little-64, zero2::little-64, size_field::little-64, _table_size::little-64,
        tail_marker::little-64, _rest::binary>>
      when zero1 == 0 and zero2 == 0 and size_field == 48 and
             tail_marker == ca_format_table_tail_marker() ->
        {:ok, Enum.reverse(acc)}

      <<item_offset::little-64, chunk_id::binary-size(32), remaining_data::binary>> ->
        item = %{offset: item_offset, chunk_id: chunk_id}
        parse_table_items_binary(remaining_data, [item | acc])

      _ ->
        {:error, "Invalid table data: insufficient bytes for table item or tail"}
    end
  end

  @spec calculate_total_size([Constants.table_item()]) :: non_neg_integer()
  defp calculate_total_size(items) when is_list(items) and length(items) > 0 do
    List.last(items).offset
  end

  defp calculate_total_size(_) do
    0
  end

  @spec convert_table_to_chunks([Constants.table_item()]) :: [Constants.chunk_item()]
  defp convert_table_to_chunks(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      previous_offset =
        if index == 0 do
          0
        else
          Enum.at(items, index - 1).offset
        end

      chunk_size = item.offset - previous_offset
      %{chunk_id: item.chunk_id, offset: previous_offset, size: chunk_size, flags: 0}
    end)
  end
end
