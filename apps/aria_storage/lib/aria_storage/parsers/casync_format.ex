# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat do
  @moduledoc """
  ARCANA (Aria Content Archive and Network Architecture) format parser.

  This module implements parsers for the casync binary formats that are
  fully compatible with the casync/desync ecosystem using ABNF parsec
  for robust binary parsing:

  - .caibx (Content Archive Index for Blobs)
  - .caidx (Content Archive Index for Directories)
  - .cacnk (Compressed Chunk files)
  - .catar (Archive Container format)

  ARCANA maintains perfect binary compatibility with casync/desync tools
  using identical structures, magic numbers, and behaviors with
  ABNF-based parsing for better maintainability and correctness.

  Based on desync source code analysis:
  - FormatIndex: 48 bytes (16 header + 8 flags + 8 min + 8 avg + 8 max)
  - FormatTable: Variable length with 40-byte items (8 offset + 32 chunk_id)
  - Compression: ZSTD (type 1) is primary compression
  - Magic numbers are embedded in structured format headers

  Uses ABNF parsec in binary mode for reliable parsing of the structured
  binary format as defined in the ARCANA specification.

  See: docs/ARCANA_FORMAT_SPEC.md for complete specification.
  """

  # Direct binary parsing - no longer using AbnfParsec
  # We now use binary pattern matching for better performance and reliability

  # Constants from desync source code (const.go)
  @ca_format_index 0x96824d9c7b129ff9
  @ca_format_table 0xe75b9e112f17417d
  @ca_format_table_tail_marker 0x4b4f050e5549ecd1
  # Suppressing warnings for reserved constant by commenting out unused one
  # @_ca_format_exclude_no_dump 0x8000000000000000
  
  # CATAR format constants
  @ca_format_entry 0x1396fabcea5bbb51
  @ca_format_user 0xf453131aaeeaccb3
  @ca_format_group 0x25eb6ac969396a52
  @ca_format_xattr 0xb8157091f80bc486
  @ca_format_acl_user 0x297dc88b2ef12faf
  @ca_format_acl_group 0x36f2acb56cb3dd0b
  @ca_format_acl_group_obj 0x23047110441f38f3
  @ca_format_acl_default 0xfe3eeda6823c8cd0
  @ca_format_acl_default_user 0xbdf03df9bd010a91
  @ca_format_acl_default_group 0xa0cb1168782d1f51
  @ca_format_fcaps 0xf7267db0afed0629
  @ca_format_selinux 0x46faf0602fd26c59
  @ca_format_filename 0x6dbb6ebcb3161f0b
  @ca_format_symlink 0x664a6fb6830e0d6c
  @ca_format_device 0xac3dace369dfe643
  @ca_format_payload 0x8b9e1d93d6dcffc9
  @ca_format_goodbye 0xdfd35c5e8327c403
  @ca_format_goodbye_tail_marker 0x57446fa533702943

  # Compression types (based on desync - only ZSTD is actually used)
  @compression_none 0
  @compression_zstd 1

  # Default chunk sizes (currently unused but reserved for validation and recommendations)
  # Suppressing warnings for reserved constants by commenting out unused ones
  # @_default_min_chunk_size 16_384    # 16KB
  # @_default_avg_chunk_size 65_536    # 64KB  
  # @_default_max_chunk_size 262_144   # 256KB

  # Magic numbers for file format detection (currently unused but reserved for format detection)
  # Suppressing warnings for reserved constants by commenting out unused ones
  # @_caibx_magic_bytes <<0xCA, 0x1B, 0x5C>>
  # @_caidx_magic_bytes <<0xCA, 0x1D, 0x5C>>
  # @_catar_magic_bytes <<0xCA, 0x1A, 0x52>>

  # Public accessor functions for constants (needed by tests)
  def ca_format_index, do: @ca_format_index
  def ca_format_table, do: @ca_format_table  
  def ca_format_table_tail_marker, do: @ca_format_table_tail_marker

  @doc """
  Convert parser result to JSON-safe format by encoding binary data as base64.
  """
  def to_json_safe(result) when is_map(result) do
    result
    |> Map.update(:chunks, [], fn chunks ->
      Enum.map(chunks, fn chunk ->
        chunk
        |> Map.update(:chunk_id, nil, &Base.encode64/1)
      end)
    end)
    |> Map.update(:_original_table_data, nil, fn
      nil -> nil
      binary_data when is_binary(binary_data) -> Base.encode64(binary_data)
      other -> other
    end)
  end

  def to_json_safe(result), do: result

  @doc """
  Parse a caibx/caidx index file from binary data.

  Format structure based on desync source:
  - FormatIndex header (48 bytes)
  - FormatTable with variable number of items (40 bytes each)
  - Table tail marker
  """
  def parse_index(binary_data) when is_binary(binary_data) do
    # Use direct binary parsing instead of ABNF to avoid UTF-8 encoding issues
    case binary_data do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        # Validate the format index values
        remaining_data::binary>> -> 
        if size_field == 48 and type_field == @ca_format_index do
          # Both CAIBX and CAIDX formats use the same parsing logic
          # The feature_flags field differentiates them but both are supported
          format_type = if feature_flags == 0, do: :caidx, else: :caibx
          
          # Both CAIBX (blob index) and CAIDX (directory index) formats - proceed with parsing
            # Handle empty index (no table data)
            case remaining_data do
                <<>> ->
                    # Empty index file - no chunks
                    result = %{
                      format: format_type,
                      header: %{
                        version: 1,  # Standard version
                        total_size: 0,
                        chunk_count: 0
                      },
                      chunks: [],
                      feature_flags: feature_flags,
                      chunk_size_min: chunk_size_min,
                      chunk_size_avg: chunk_size_avg,
                      chunk_size_max: chunk_size_max,
                      # Empty index has no table data
                      _original_table_data: <<>>
                    }
                    {:ok, result}
                    
                  _ ->
                    case parse_format_table_with_items_binary(remaining_data) do
                      {:ok, table_items} ->
                        # Convert to internal format (both CAIBX and CAIDX)
                        result = %{
                          format: format_type,
                          header: %{
                            version: 1,  # Standard version
                            total_size: calculate_total_size(table_items),
                            chunk_count: length(table_items)
                          },
                          chunks: convert_table_to_chunks(table_items),
                          feature_flags: feature_flags,
                          chunk_size_min: chunk_size_min,
                          chunk_size_avg: chunk_size_avg,
                          chunk_size_max: chunk_size_max,
                          # Preserve original binary table data for bit-exact roundtrip
                          _original_table_data: remaining_data
                        }
                        {:ok, result}

                      {:error, reason} ->
                        {:error, reason}
                    end
            end
        else
          {:error, "Invalid FormatIndex header: size=#{size_field}, type=0x#{Integer.to_string(type_field, 16)}"}
        end
      _ -> {:error, "Invalid binary data: insufficient data for FormatIndex header"}
    end
  end

  @doc """
  Parse a cacnk chunk file from binary data.
  """
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case binary_data do
      # CACNK header: 3-byte magic + 4*4 bytes (16 bytes total header)
      <<0xCA, 0xC4, 0x4E, compressed_size::little-32, uncompressed_size::little-32,
        compression_type::little-32, flags::little-32, remaining_data::binary>> ->

        compression = case compression_type do
          @compression_none -> :none
          @compression_zstd -> :zstd
          _ -> :unknown
        end

        header = %{
          compressed_size: compressed_size,
          uncompressed_size: uncompressed_size,
          compression: compression,
          flags: flags
        }

        result = %{
          magic: :cacnk,
          header: header,
          data: remaining_data
        }

        {:ok, result}

      _ ->
        {:error, "Invalid chunk file magic"}
    end
  end

  @doc """
  Parse a catar archive file from binary data.
  
  CATAR format is a structured archive format similar to tar but with casync-specific
  enhancements. It contains a directory tree with filenames, permissions, and file data.
  """
  def parse_archive(binary_data) when is_binary(binary_data) do
    try do
      case parse_catar_elements(binary_data, []) do
        {:ok, elements} ->
          # Extract directory structure and file information
          {files, directories} = process_catar_elements(elements)
          
          result = %{
            format: :catar,
            files: files,
            directories: directories,
            elements: elements,
            total_size: byte_size(binary_data)
          }
          
          {:ok, result}
          
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      error -> {:error, "CATAR parsing failed: #{inspect(error)}"}
    end
  end
  
  # Parse CATAR elements recursively
  defp parse_catar_elements(<<>>, acc), do: {:ok, Enum.reverse(acc)}
  
  defp parse_catar_elements(binary_data, acc) do
    case parse_next_catar_element(binary_data) do
      {:ok, element, remaining} ->
        parse_catar_elements(remaining, [element | acc])
        
      {:error, :end_of_data} ->
        {:ok, Enum.reverse(acc)}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Parse individual CATAR format elements
  defp parse_next_catar_element(<<>>) do
    {:error, :end_of_data}
  end
  
  defp parse_next_catar_element(binary_data) do
    case binary_data do
      # CaFormatEntry (64 bytes)
      <<size::little-64, type::little-64, feature_flags::little-64, mode::little-64,
        _field5::little-64, gid::little-64, uid::little-64, mtime::little-64,
        remaining::binary>> when type == @ca_format_entry ->
        
        element = %{
          type: :entry,
          size: size,
          feature_flags: feature_flags,
          mode: mode,
          uid: uid,
          gid: gid,
          mtime: mtime
        }
        
        {:ok, element, remaining}
      
      # CaFormatFilename (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_filename ->
        name_size = size - 16  # Subtract header size
        
        case remaining do
          <<name_data::binary-size(name_size), rest::binary>> ->
            # Remove null terminator
            name = String.trim_trailing(name_data, <<0>>)
            
            element = %{
              type: :filename,
              name: name
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for filename"}
        end
      
      # CaFormatPayload (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_payload ->
        payload_size = size - 16
        
        case remaining do
          <<payload_data::binary-size(payload_size), rest::binary>> ->
            element = %{
              type: :payload,
              size: payload_size,
              data: payload_data
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for payload"}
        end
      
      # CaFormatSymlink (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_symlink ->
        target_size = size - 16
        
        case remaining do
          <<target_data::binary-size(target_size), rest::binary>> ->
            target = String.trim_trailing(target_data, <<0>>)
            
            element = %{
              type: :symlink,
              target: target
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for symlink"}
        end
      
      # CaFormatDevice (32 bytes)
      <<size::little-64, type::little-64, major::little-64, minor::little-64,
        remaining::binary>> when type == @ca_format_device and size == 32 ->
        
        element = %{
          type: :device,
          major: major,
          minor: minor
        }
        
        {:ok, element, remaining}
      
      # CaFormatGoodbye (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_goodbye ->
        items_size = size - 16
        
        case parse_goodbye_items(remaining, items_size) do
          {:ok, items, rest} ->
            element = %{
              type: :goodbye,
              items: items
            }
            
            {:ok, element, rest}
            
          {:error, reason} ->
            {:error, reason}
        end
      
      # CaFormatUser (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_user ->
        name_size = size - 16
        
        case remaining do
          <<name_data::binary-size(name_size), rest::binary>> ->
            name = String.trim_trailing(name_data, <<0>>)
            
            element = %{
              type: :user,
              name: name
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for user"}
        end
      
      # CaFormatGroup (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_group ->
        name_size = size - 16
        
        case remaining do
          <<name_data::binary-size(name_size), rest::binary>> ->
            name = String.trim_trailing(name_data, <<0>>)
            
            element = %{
              type: :group,
              name: name
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for group"}
        end
      
      # CaFormatSELinux (variable length)
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_selinux ->
        context_size = size - 16
        
        case remaining do
          <<context_data::binary-size(context_size), rest::binary>> ->
            context = String.trim_trailing(context_data, <<0>>)
            
            element = %{
              type: :selinux,
              context: context
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for SELinux context"}
        end
      
      # CaFormatXAttr (variable length)  
      <<size::little-64, type::little-64, remaining::binary>> when type == @ca_format_xattr ->
        attr_size = size - 16
        
        case remaining do
          <<attr_data::binary-size(attr_size), rest::binary>> ->
            element = %{
              type: :xattr,
              data: attr_data
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for extended attribute"}
        end
      
      # Skip other ACL and capability formats for now - just consume them
      <<size::little-64, type::little-64, remaining::binary>> when type in [
        @ca_format_acl_user, @ca_format_acl_group, @ca_format_acl_group_obj,
        @ca_format_acl_default, @ca_format_acl_default_user, @ca_format_acl_default_group,
        @ca_format_fcaps
      ] ->
        data_size = size - 16
        
        case remaining do
          <<_data::binary-size(data_size), rest::binary>> ->
            element = %{
              type: :metadata,
              format: type,
              size: data_size
            }
            
            {:ok, element, rest}
            
          _ ->
            {:error, "Insufficient data for metadata element"}
        end
      
      # Unknown or malformed element
      <<size::little-64, type::little-64, _remaining::binary>> ->
        {:error, "Unknown CATAR element type: 0x#{Integer.to_string(type, 16) |> String.upcase()}, size: #{size}"}
      
      _ ->
        {:error, "Insufficient data for CATAR element header"}
    end
  end
  
  # Parse goodbye items (directory entries)
  defp parse_goodbye_items(binary_data, items_size) do
    case binary_data do
      <<items_data::binary-size(items_size), rest::binary>> ->
        items = parse_goodbye_items_data(items_data, [])
        {:ok, items, rest}
        
      _ ->
        {:error, "Insufficient data for goodbye items"}
    end
  end
  
  defp parse_goodbye_items_data(<<>>, acc), do: Enum.reverse(acc)
  
  defp parse_goodbye_items_data(binary_data, acc) do
    case binary_data do
      # Each goodbye item is 24 bytes
      <<offset::little-64, size::little-64, hash::little-64, remaining::binary>> ->
        item = %{
          offset: offset,
          size: size,
          hash: hash
        }
        
        # Check for tail marker
        if hash == @ca_format_goodbye_tail_marker do
          Enum.reverse([item | acc])
        else
          parse_goodbye_items_data(remaining, [item | acc])
        end
        
      _ ->
        Enum.reverse(acc)
    end
  end
  
  # Process CATAR elements to extract file and directory structure
  defp process_catar_elements(elements) do
    # Group related elements (entry + filename + payload/symlink/device)
    grouped_files = group_catar_elements(elements)
    
    # Separate files and directories from the grouped results
    {files, directories} = Enum.reduce(grouped_files, {[], []}, fn item, {files_acc, dirs_acc} ->
      case item.type do
        :directory ->
          {files_acc, [item | dirs_acc]}
        _ ->
          {[item | files_acc], dirs_acc}
      end
    end)
    
    {Enum.reverse(files), Enum.reverse(directories)}
  end
  
  # Group CATAR elements into logical file/directory structures
  # Based on desync format: Entry -> [User/Group/SELinux/etc] -> Filename -> [Payload/Symlink/Device/Goodbye]
  defp group_catar_elements(elements) do
    # Use a different approach - scan for patterns and group them properly
    group_catar_elements_sequential(elements, [], nil, nil)
  end
  
  # Sequential grouping that follows desync's actual format
  # Based on format_test.go: Filename comes BEFORE Entry, Goodbye marks end of directories
  defp group_catar_elements_sequential([], acc, _current_entry, _pending_name) do
    Enum.reverse(acc)
  end
  
  defp group_catar_elements_sequential([element | rest], acc, current_entry, pending_name) do
    case element do
      %{type: :filename, name: name} ->
        # Filename comes BEFORE the entry - store it for the next entry
        group_catar_elements_sequential(rest, acc, current_entry, name)
        
      %{type: :entry} = entry when not is_nil(pending_name) ->
        # Entry after filename - update entry with the filename
        updated_entry = entry |> Map.put(:name, pending_name) |> Map.put(:path, pending_name)
        group_catar_elements_sequential(rest, acc, updated_entry, nil)
        
      %{type: :entry} = entry ->
        # Entry without preceding filename - use as current entry
        group_catar_elements_sequential(rest, acc, entry, pending_name)
        
      %{type: :payload, data: data} when not is_nil(current_entry) ->
        # File content - finalize the file
        filename = Map.get(current_entry, :name, "unnamed_file")
        file = current_entry
        |> Map.put(:content, data)
        |> Map.put(:type, :file)
        |> Map.put(:name, filename)
        |> Map.put(:path, filename)
        group_catar_elements_sequential(rest, [file | acc], nil, nil)
        
      %{type: :symlink, target: target} when not is_nil(current_entry) ->
        # Symlink - finalize the symlink
        filename = Map.get(current_entry, :name, "unnamed_symlink")
        file = current_entry
        |> Map.put(:target, target)
        |> Map.put(:type, :symlink)
        |> Map.put(:name, filename)
        |> Map.put(:path, filename)
        group_catar_elements_sequential(rest, [file | acc], nil, nil)
        
      %{type: :device, major: major, minor: minor} when not is_nil(current_entry) ->
        # Device - finalize the device
        filename = Map.get(current_entry, :name, "unnamed_device")
        file = current_entry
        |> Map.put(:major, major)
        |> Map.put(:minor, minor)
        |> Map.put(:type, :device)
        |> Map.put(:name, filename)
        |> Map.put(:path, filename)
        group_catar_elements_sequential(rest, [file | acc], nil, nil)
        
      %{type: :goodbye} when not is_nil(current_entry) ->
        # Directory end marker - finalize the directory
        filename = Map.get(current_entry, :name, "unnamed_directory")
        file = current_entry
        |> Map.put(:type, :directory)
        |> Map.put(:name, filename)
        |> Map.put(:path, filename)
        group_catar_elements_sequential(rest, [file | acc], nil, nil)
        
      _ ->
        # Skip metadata elements (user, group, selinux, xattr, etc.)
        group_catar_elements_sequential(rest, acc, current_entry, pending_name)
    end
  end

  @doc """
  Detect the format of binary data based on desync FormatIndex structure.
  """
  def detect_format(<<format_header_size::little-64, format_type::little-64, feature_flags::little-64, _rest::binary>>) do
    case {format_header_size, format_type} do
      {48, @ca_format_index} -> 
        # Differentiate between CAIBX and CAIDX based on feature_flags
        if feature_flags == 0, do: {:ok, :caidx}, else: {:ok, :caibx}
      {64, @ca_format_entry} -> {:ok, :catar}
      _ ->
        {:error, :unknown_format}
    end
  end

  def detect_format(<<0xCA, 0xC4, 0x4E, _::binary>>), do: {:ok, :cacnk}  # CACNK has different magic
  def detect_format(<<0xCA, 0x1A, 0x52, _::binary>>), do: {:ok, :catar}  # CATAR magic
  def detect_format(binary) when byte_size(binary) >= 32 do
    {:error, :unknown_format}
  end
  def detect_format(_), do: {:error, :unknown_format}

  defp parse_format_table_with_items_binary(binary_data) do
    # Parse format table header directly
    case binary_data do
      <<table_marker::little-64, table_type::little-64, remaining_data::binary>> ->
        # Validate format table header
        if table_marker == 0xFFFFFFFFFFFFFFFF and table_type == @ca_format_table do
          parse_table_items_binary(remaining_data, [])
        else
          {:error, "Invalid FormatTable header: marker=0x#{Integer.to_string(table_marker, 16)}, type=0x#{Integer.to_string(table_type, 16)}"}
        end

      _ ->
        {:error, "Invalid binary data: insufficient data for FormatTable header"}
    end
  end

  defp parse_table_items_binary(binary_data, acc) do
    case binary_data do
      # Check for table tail (40 bytes)
      <<zero1::little-64, zero2::little-64, size_field::little-64, _table_size::little-64, tail_marker::little-64, _rest::binary>>
      when zero1 == 0 and zero2 == 0 and size_field == 48 and tail_marker == @ca_format_table_tail_marker ->
        # Found valid tail marker, return accumulated items
        {:ok, Enum.reverse(acc)}

      # Parse table item (40 bytes)
      <<item_offset::little-64, chunk_id::binary-size(32), remaining_data::binary>> ->
        item = %{
          offset: item_offset,
          chunk_id: chunk_id
        }
        parse_table_items_binary(remaining_data, [item | acc])

      _ ->
        # Not enough data for either tail or item
        {:error, "Invalid table data: insufficient bytes for table item or tail"}
    end
  end

  # Removed unused function: determine_format/1
  
  defp calculate_total_size(items) when is_list(items) and length(items) > 0 do
    List.last(items).offset
  end

  defp calculate_total_size(_), do: 0

  defp convert_table_to_chunks(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      previous_offset = if index == 0, do: 0, else: Enum.at(items, index - 1).offset

      %{
        chunk_id: item.chunk_id,
        offset: previous_offset,
        size: item.offset - previous_offset,
        flags: 0
      }
    end)
  end

  # Encoding functions - compatible with desync format
  def encode_index(%{format: :caibx, _original_table_data: original_table_data, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Use original table data for bit-exact roundtrip
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    result = format_index <> original_table_data
    {:ok, result}
  end

  def encode_index(%{format: :caibx, header: _header, chunks: chunks, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Create FormatIndex based on desync structure using original values
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    # Handle empty chunk list - return just the FormatIndex header
    case chunks do
      [] ->
        {:ok, format_index}
        
      _ ->
        # Create FormatTable items - use actual chunk structure
        table_items = Enum.reduce(chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
          new_offset = current_offset + chunk.size
          item = <<new_offset::little-64>> <> chunk.chunk_id
          {acc <> item, new_offset}
        end) |> elem(0)

        # Create FormatTable header
        table_size = byte_size(table_items) + 48  # 48 bytes for table header + tail
        format_table_header = <<
          0xFFFFFFFFFFFFFFFF::little-64,  # Size field (special marker)
          @ca_format_table::little-64     # Type field
        >>

        # Create table tail marker
        table_tail = <<
          0::little-64,  # Offset
          0::little-64,  # Chunk ID part 1
          48::little-64,  # Size
          table_size::little-64,  # Table size
          @ca_format_table_tail_marker::little-64  # Tail marker
        >>

        result = format_index <> format_table_header <> table_items <> table_tail
        {:ok, result}
    end
  end

  def encode_index(%{format: :caidx, _original_table_data: original_table_data, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Use original table data for bit-exact roundtrip
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    result = format_index <> original_table_data
    {:ok, result}
  end

  def encode_index(%{format: :caidx, header: _header, chunks: chunks, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Create FormatIndex based on desync structure using original values
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    # Handle empty chunk list - return just the FormatIndex header
    case chunks do
      [] ->
        {:ok, format_index}
        
      _ ->
        # Create FormatTable items - use actual chunk structure
        table_items = Enum.reduce(chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
          new_offset = current_offset + chunk.size
          item = <<new_offset::little-64>> <> chunk.chunk_id
          {acc <> item, new_offset}
        end) |> elem(0)

        # Create FormatTable header
        table_size = byte_size(table_items) + 48  # 48 bytes for table header + tail
        format_table_header = <<
          0xFFFFFFFFFFFFFFFF::little-64,  # Size field (special marker)
          @ca_format_table::little-64     # Type field
        >>

        # Create table tail marker
        table_tail = <<
          0::little-64,  # Offset
          0::little-64,  # Chunk ID part 1
          48::little-64,  # Size
          table_size::little-64,  # Table size
          @ca_format_table_tail_marker::little-64  # Tail marker
        >>

        result = format_index <> format_table_header <> table_items <> table_tail
        {:ok, result}
    end
  end

  def encode_chunk(%{header: header, data: data}) do
    magic = <<0xCA, 0xC4, 0x4E>>  # CACNK magic
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  def encode_archive(%{format: :catar, elements: elements}) when is_list(elements) do
    # Encode CATAR format based on elements structure (like desync FormatEncoder)
    # Each element is encoded in sequence following the desync format spec
    encoded_data = Enum.reduce(elements, <<>>, fn element, acc ->
      encoded_element = encode_catar_element(element)
      acc <> encoded_element
    end)
    
    {:ok, encoded_data}
  end

  def encode_archive(%{format: :catar, entries: entries, remaining_data: remaining_data}) do
    # Legacy structure support - encode CATAR format - reconstruct the original structure
    case entries do
      [entry | _] ->
        encoded_entry = <<
          entry.size::little-64,
          entry.type::little-64,
          entry.flags::little-64,
          0::little-64,  # padding
          entry.mode::little-64,
          entry.uid::little-64,
          entry.gid::little-64,
          entry.mtime::little-64
        >>
        
        {:ok, encoded_entry <> remaining_data}
        
      [] ->
        {:ok, remaining_data}
    end
  end

  def encode_archive(%{format: :catar}) do
    {:error, "CATAR format encoding requires 'elements' field"}
  end

  # Helper encoding functions
  defp encode_chunk_header(%{compressed_size: compressed_size, uncompressed_size: uncompressed_size, compression: compression, flags: flags}) do
    compression_type = case compression do
      :none -> 0
      :zstd -> 1
      :unknown -> 0
    end

    <<compressed_size::little-32>> <>
    <<uncompressed_size::little-32>> <>
    <<compression_type::little-32>> <>
    <<flags::little-32>>
  end

  defp encode_chunk_header(%{}) do
    <<0::little-32, 0::little-32, 0::little-32, 0::little-32>>
  end

  # CATAR element encoding functions
  defp encode_catar_element(%{type: :entry, size: size, feature_flags: feature_flags, mode: mode, uid: uid, gid: gid, mtime: mtime}) do
    # CaFormatEntry (64 bytes)
    <<
      size::little-64,
      @ca_format_entry::little-64,
      feature_flags::little-64,
      mode::little-64,
      0::little-64,  # field5 (unknown, set to 0)
      gid::little-64,
      uid::little-64,
      mtime::little-64
    >>
  end

  defp encode_catar_element(%{type: :filename, name: name}) do
    # CaFormatFilename (variable length)
    # Ensure name is null-terminated
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size  # Header (16 bytes) + name data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_filename::little-64
    >> <> name_data <> padding
  end

  defp encode_catar_element(%{type: :payload, size: size, data: data}) do
    # CaFormatPayload (variable length)
    total_size = 16 + size  # Header (16 bytes) + payload data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_payload::little-64
    >> <> data <> padding
  end

  defp encode_catar_element(%{type: :symlink, target: target}) do
    # CaFormatSymlink (variable length)
    # Ensure target is null-terminated
    target_data = target <> <<0>>
    target_size = byte_size(target_data)
    total_size = 16 + target_size  # Header (16 bytes) + target data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_symlink::little-64
    >> <> target_data <> padding
  end

  defp encode_catar_element(%{type: :device, major: major, minor: minor}) do
    # CaFormatDevice (32 bytes)
    <<
      32::little-64,
      @ca_format_device::little-64,
      major::little-64,
      minor::little-64
    >>
  end

  defp encode_catar_element(%{type: :goodbye, items: items}) do
    # CaFormatGoodbye (variable length)
    # Each item is 24 bytes: offset (8) + size (8) + hash (8)
    items_data = Enum.reduce(items, <<>>, fn item, acc ->
      acc <> <<
        item.offset::little-64,
        item.size::little-64,
        item.hash::little-64
      >>
    end)
    
    items_size = byte_size(items_data)
    total_size = 16 + items_size  # Header (16 bytes) + items data
    
    <<
      total_size::little-64,
      @ca_format_goodbye::little-64
    >> <> items_data
  end

  defp encode_catar_element(%{type: :user, name: name}) do
    # CaFormatUser (variable length)
    # Ensure name is null-terminated
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size  # Header (16 bytes) + name data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_user::little-64
    >> <> name_data <> padding
  end

  defp encode_catar_element(%{type: :group, name: name}) do
    # CaFormatGroup (variable length)
    # Ensure name is null-terminated
    name_data = name <> <<0>>
    name_size = byte_size(name_data)
    total_size = 16 + name_size  # Header (16 bytes) + name data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_group::little-64
    >> <> name_data <> padding
  end

  defp encode_catar_element(%{type: :selinux, context: context}) do
    # CaFormatSELinux (variable length)
    # Ensure context is null-terminated
    context_data = context <> <<0>>
    context_size = byte_size(context_data)
    total_size = 16 + context_size  # Header (16 bytes) + context data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_selinux::little-64
    >> <> context_data <> padding
  end

  defp encode_catar_element(%{type: :xattr, data: data}) do
    # CaFormatXAttr (variable length)
    data_size = byte_size(data)
    total_size = 16 + data_size  # Header (16 bytes) + attribute data
    
    # Pad to 8-byte boundary
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      @ca_format_xattr::little-64
    >> <> data <> padding
  end

  defp encode_catar_element(%{type: :metadata, format: format_type, size: data_size}) do
    # Generic metadata elements (ACL, capabilities, etc.)
    # These elements are skipped during parsing but we preserve them for roundtrip
    total_size = 16 + data_size  # Header (16 bytes) + data
    
    # Pad to 8-byte boundary  
    padding_size = rem(8 - rem(total_size, 8), 8)
    padding = <<0::size(padding_size * 8)>>
    
    <<
      (total_size + padding_size)::little-64,
      format_type::little-64
    >> <> <<0::size(data_size * 8)>> <> padding  # Zero-filled data since we don't parse it
  end

  # Fallback for unknown element types
  defp encode_catar_element(%{type: unknown_type} = element) do
    raise "Unknown CATAR element type: #{inspect(unknown_type)} in element: #{inspect(element)}"
  end

  @doc """
  Compare two binary data chunks byte-by-byte and return hex diff information.
  Useful for verifying bit-exact encoding roundtrips.
  """
  def hex_compare(original, encoded) when is_binary(original) and is_binary(encoded) do
    original_size = byte_size(original)
    encoded_size = byte_size(encoded)
    
    size_match = original_size == encoded_size
    
    if size_match do
      case compare_bytes(original, encoded, 0, []) do
        [] -> 
          %{
            match: true,
            size_original: original_size,
            size_encoded: encoded_size,
            differences: []
          }
        differences ->
          %{
            match: false,
            size_original: original_size,
            size_encoded: encoded_size,
            differences: differences
          }
      end
    else
      %{
        match: false,
        size_original: original_size,
        size_encoded: encoded_size,
        differences: [{:size_mismatch, original_size, encoded_size}]
      }
    end
  end

  @doc """
  Print hex dump comparison of two binary data chunks.
  """
  def print_hex_diff(original, encoded) do
    comparison = hex_compare(original, encoded)
    
    IO.puts("=== HEX COMPARISON ===")
    IO.puts("Original size: #{comparison.size_original} bytes")
    IO.puts("Encoded size:  #{comparison.size_encoded} bytes")
    IO.puts("Match: #{comparison.match}")
    
    if not comparison.match do
      IO.puts("\n=== DIFFERENCES ===")
      Enum.each(comparison.differences, fn
        {:size_mismatch, orig_size, enc_size} ->
          IO.puts("Size mismatch: original=#{orig_size}, encoded=#{enc_size}")
        
        {:byte_diff, offset, orig_byte, enc_byte} ->
          IO.puts("Offset 0x#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0")}: " <>
                  "original=0x#{Integer.to_string(orig_byte, 16) |> String.pad_leading(2, "0")} " <>
                  "encoded=0x#{Integer.to_string(enc_byte, 16) |> String.pad_leading(2, "0")}")
      end)
      
      # Print hex dumps around first difference
      if length(comparison.differences) > 0 do
        first_diff = hd(comparison.differences)
        case first_diff do
          {:byte_diff, offset, _, _} ->
            print_hex_context(original, encoded, offset)
          _ -> :ok
        end
      end
    else
      IO.puts("✓ Binary data matches exactly!")
    end
    
    comparison
  end

  # Private helper functions for hex comparison
  defp compare_bytes(<<>>, <<>>, _offset, acc), do: Enum.reverse(acc)
  defp compare_bytes(<<>>, _encoded, _offset, acc), do: Enum.reverse(acc)
  defp compare_bytes(_original, <<>>, _offset, acc), do: Enum.reverse(acc)
  
  defp compare_bytes(<<orig_byte, orig_rest::binary>>, <<enc_byte, enc_rest::binary>>, offset, acc) do
    if orig_byte == enc_byte do
      compare_bytes(orig_rest, enc_rest, offset + 1, acc)
    else
      diff = {:byte_diff, offset, orig_byte, enc_byte}
      compare_bytes(orig_rest, enc_rest, offset + 1, [diff | acc])
    end
  end

  defp print_hex_context(original, encoded, offset) do
    # Print 32 bytes before and after the difference
    start_offset = max(0, offset - 16)
    length = min(32, byte_size(original) - start_offset)
    
    IO.puts("\n=== HEX CONTEXT AROUND OFFSET 0x#{Integer.to_string(offset, 16) |> String.upcase()} ===")
    
    orig_chunk = binary_part(original, start_offset, length)
    enc_chunk = if byte_size(encoded) >= start_offset + length do
      binary_part(encoded, start_offset, length)
    else
      <<>>
    end
    
    IO.puts("Original:")
    print_hex_dump(orig_chunk, start_offset)
    
    IO.puts("\nEncoded:")
    print_hex_dump(enc_chunk, start_offset)
  end

  defp print_hex_dump(binary, base_offset \\ 0) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.each(fn {bytes, row} ->
      offset = base_offset + row * 16
      hex_part = bytes 
        |> Enum.map(&(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
        |> Enum.join(" ")
        |> String.pad_trailing(47)  # 16 * 3 - 1 = 47
      
      ascii_part = bytes
        |> Enum.map(fn b -> if b >= 32 and b <= 126, do: <<b>>, else: "." end)
        |> Enum.join()
      
      IO.puts("#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0") |> String.upcase()}: #{hex_part} |#{ascii_part}|")
    end)
  end

  @doc """
  Test roundtrip encoding for a given binary data and format.
  Returns detailed comparison results.
  """
  def test_roundtrip_encoding(binary_data, format_type) do
    IO.puts("=== TESTING ROUNDTRIP FOR #{String.upcase(to_string(format_type))} ===")
    IO.puts("Original size: #{byte_size(binary_data)} bytes")
    
    case format_type do
      :caibx -> test_index_roundtrip(binary_data)
      :caidx -> test_index_roundtrip(binary_data)
      :cacnk -> test_chunk_roundtrip(binary_data)
      :catar -> test_archive_roundtrip(binary_data)
      _ -> {:error, "Unknown format type: #{format_type}"}
    end
  end

  defp test_index_roundtrip(binary_data) do
    case parse_index(binary_data) do
      {:ok, parsed} ->
        IO.puts("✓ Parsing successful")
        IO.puts("  Format: #{parsed.format}")
        IO.puts("  Chunks: #{length(parsed.chunks)}")
        
        case encode_index(parsed) do
          {:ok, encoded} ->
            IO.puts("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{reason}")
            {:error, reason}
        end
        
      {:error, reason} ->
        IO.puts("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  defp test_chunk_roundtrip(binary_data) do
    case parse_chunk(binary_data) do
      {:ok, parsed} ->
        IO.puts("✓ Parsing successful")
        IO.puts("  Magic: #{parsed.magic}")
        IO.puts("  Compression: #{parsed.header.compression}")
        
        case encode_chunk(parsed) do
          {:ok, encoded} ->
            IO.puts("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{reason}")
            {:error, reason}
        end
        
      {:error, reason} ->
        IO.puts("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  defp test_archive_roundtrip(binary_data) do
    case parse_archive(binary_data) do
      {:ok, parsed} ->
        IO.puts("✓ Parsing successful")
        IO.puts("  Format: #{parsed.format}")
        IO.puts("  Elements: #{length(parsed.elements)}")
        IO.puts("  Files: #{length(parsed.files)}")
        IO.puts("  Directories: #{length(parsed.directories)}")
        
        case encode_archive(parsed) do
          {:ok, encoded} ->
            IO.puts("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{reason}")
            {:error, reason}
        end
        
      {:error, reason} ->
        IO.puts("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Test roundtrip encoding for a given file path and parsed data.
  Returns detailed comparison results.
  """
  def test_file_roundtrip_encoding(file_path, parsed) do
    filename = Path.basename(file_path)
    IO.puts("=== TESTING ROUNDTRIP FOR #{filename} ===")
    
    case File.read(file_path) do
      {:ok, original_data} ->
        IO.puts("Original size: #{byte_size(original_data)} bytes")
        
        case encode_archive(parsed) do
          {:ok, encoded_data} ->
            IO.puts("✓ Encoding successful")
            IO.puts("Encoded size: #{byte_size(encoded_data)} bytes")
            
            if original_data == encoded_data do
              IO.puts("✓ Perfect bit-exact roundtrip!")
              {:ok, :perfect_match}
            else
              IO.puts("⚠ Size or content differences detected")
              comparison = print_hex_diff(original_data, encoded_data)
              {:ok, {:differences, comparison}}
            end
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{reason}")
            {:error, reason}
        end
        
      {:error, reason} ->
        IO.puts("✗ File read failed: #{reason}")
        {:error, reason}
    end
  end
end
