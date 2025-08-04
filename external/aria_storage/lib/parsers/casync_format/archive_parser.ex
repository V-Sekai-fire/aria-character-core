# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.ArchiveParser do
  @moduledoc "Parser for CATAR archive files in the ARCANA format.\n\nCATAR format is a structured archive format similar to tar but with casync-specific\nenhancements. It contains a directory tree with filenames, permissions, and file data.\n"
  require AriaStorage.Parsers.CasyncFormat.Constants
  import AriaStorage.Parsers.CasyncFormat.Constants
  alias AriaStorage.Parsers.CasyncFormat.Constants
  @type parse_result :: {:ok, map()} | {:error, String.t()}
  @doc "Parse a catar archive file from binary data.\n\nCATAR format contains a sequence of elements representing files, directories,\nand metadata in a structured format compatible with casync/desync tools.\n"
  @spec parse_archive(binary()) :: parse_result()
  def parse_archive(binary_data) when is_binary(binary_data) do
    try do
      case parse_catar_elements(binary_data, []) do
        {:ok, elements} ->
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

  @spec parse_catar_elements(binary(), [Constants.catar_element()]) ::
          {:ok, [Constants.catar_element()]} | {:error, String.t()}
  defp parse_catar_elements(<<>>, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp parse_catar_elements(binary_data, acc) do
    case parse_next_catar_element(binary_data) do
      {:ok, element, remaining} -> parse_catar_elements(remaining, [element | acc])
      {:error, :end_of_data} -> {:ok, Enum.reverse(acc)}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec parse_next_catar_element(binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, atom() | String.t()}
  defp parse_next_catar_element(<<>>) do
    {:error, :end_of_data}
  end

  defp parse_next_catar_element(binary_data) do
    case binary_data do
      <<size::little-64, type::little-64, feature_flags::little-64, mode::little-64,
        _field5::little-64, rest::binary>>
      when type == ca_format_entry() ->
        parse_entry_element(size, feature_flags, mode, rest)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_filename() ->
        parse_filename_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_payload() ->
        parse_payload_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_symlink() ->
        parse_symlink_element(size, remaining)

      <<size::little-64, type::little-64, major::little-64, minor::little-64, remaining::binary>>
      when type == ca_format_device() and size == 32 ->
        element = %{type: :device, major: major, minor: minor}
        {:ok, element, remaining}

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_goodbye() ->
        parse_goodbye_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_user() ->
        parse_user_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_group() ->
        parse_group_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_selinux() ->
        parse_selinux_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>> when type == ca_format_xattr() ->
        parse_xattr_element(size, remaining)

      <<size::little-64, type::little-64, remaining::binary>>
      when type in [
             ca_format_acl_user(),
             ca_format_acl_group(),
             ca_format_acl_group_obj(),
             ca_format_acl_default(),
             ca_format_acl_default_user(),
             ca_format_acl_default_group(),
             ca_format_fcaps()
           ] ->
        parse_metadata_element(size, type, remaining)

      <<size::little-64, type::little-64, _remaining::binary>> ->
        {:error,
         "Unknown CATAR element type: 0x#{Integer.to_string(type, 16) |> String.upcase()}, size: #{size}"}

      _ ->
        {:error, "Insufficient data for CATAR element header"}
    end
  end

  @spec parse_entry_element(non_neg_integer(), non_neg_integer(), non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_entry_element(size, feature_flags, mode, rest) do
    uid_gid_data_size = size - 16 - 8 - 8 - 8 - 8

    case uid_gid_data_size do
      4 ->
        <<gid::little-16, uid::little-16, mtime::little-64, remaining::binary>> = rest

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

      8 ->
        <<gid::little-32, uid::little-32, mtime::little-64, remaining::binary>> = rest

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

      16 ->
        <<gid::little-64, uid::little-64, mtime::little-64, remaining::binary>> = rest

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

      _ ->
        {:error, "Invalid entry size: #{size}, UID/GID data size: #{uid_gid_data_size}"}
    end
  end

  @spec parse_filename_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_filename_element(size, remaining) do
    name_size = size - 16

    case remaining do
      <<name_data::binary-size(name_size), rest::binary>> ->
        name = String.trim_trailing(name_data, <<0>>)
        element = %{type: :filename, name: name}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for filename"}
    end
  end

  @spec parse_payload_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_payload_element(size, remaining) do
    payload_size = size - 16

    case remaining do
      <<payload_data::binary-size(payload_size), rest::binary>> ->
        element = %{type: :payload, size: payload_size, data: payload_data}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for payload"}
    end
  end

  @spec parse_symlink_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_symlink_element(size, remaining) do
    target_size = size - 16

    case remaining do
      <<target_data::binary-size(target_size), rest::binary>> ->
        target = String.trim_trailing(target_data, <<0>>)
        element = %{type: :symlink, target: target}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for symlink"}
    end
  end

  @spec parse_goodbye_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_goodbye_element(size, remaining) do
    items_size = size - 16

    case parse_goodbye_items(remaining, items_size) do
      {:ok, items, rest} ->
        element = %{type: :goodbye, items: items}
        {:ok, element, rest}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_user_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_user_element(size, remaining) do
    name_size = size - 16

    case remaining do
      <<name_data::binary-size(name_size), rest::binary>> ->
        name = String.trim_trailing(name_data, <<0>>)
        element = %{type: :user, name: name}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for user"}
    end
  end

  @spec parse_group_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_group_element(size, remaining) do
    name_size = size - 16

    case remaining do
      <<name_data::binary-size(name_size), rest::binary>> ->
        name = String.trim_trailing(name_data, <<0>>)
        element = %{type: :group, name: name}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for group"}
    end
  end

  @spec parse_selinux_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_selinux_element(size, remaining) do
    context_size = size - 16

    case remaining do
      <<context_data::binary-size(context_size), rest::binary>> ->
        context = String.trim_trailing(context_data, <<0>>)
        element = %{type: :selinux, context: context}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for SELinux context"}
    end
  end

  @spec parse_xattr_element(non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_xattr_element(size, remaining) do
    attr_size = size - 16

    case remaining do
      <<attr_data::binary-size(attr_size), rest::binary>> ->
        element = %{type: :xattr, data: attr_data}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for extended attribute"}
    end
  end

  @spec parse_metadata_element(non_neg_integer(), non_neg_integer(), binary()) ::
          {:ok, Constants.catar_element(), binary()} | {:error, String.t()}
  defp parse_metadata_element(size, format_type, remaining) do
    data_size = size - 16

    case remaining do
      <<data::binary-size(data_size), rest::binary>> ->
        element = %{type: :metadata, format: format_type, size: data_size, data: data}
        {:ok, element, rest}

      _ ->
        {:error, "Insufficient data for metadata element"}
    end
  end

  @spec parse_goodbye_items(binary(), non_neg_integer()) ::
          {:ok, [map()], binary()} | {:error, String.t()}
  defp parse_goodbye_items(binary_data, items_size) do
    case binary_data do
      <<items_data::binary-size(items_size), rest::binary>> ->
        items = parse_goodbye_items_data(items_data, [])
        {:ok, items, rest}

      _ ->
        {:error, "Insufficient data for goodbye items"}
    end
  end

  @spec parse_goodbye_items_data(binary(), [map()]) :: [map()]
  defp parse_goodbye_items_data(<<>>, acc) do
    Enum.reverse(acc)
  end

  defp parse_goodbye_items_data(binary_data, acc) do
    case binary_data do
      <<offset::little-64, size::little-64, hash::little-64, remaining::binary>> ->
        item = %{offset: offset, size: size, hash: hash}

        if hash == ca_format_goodbye_tail_marker() do
          Enum.reverse([item | acc])
        else
          parse_goodbye_items_data(remaining, [item | acc])
        end

      _ ->
        Enum.reverse(acc)
    end
  end

  @spec process_catar_elements([Constants.catar_element()]) :: {[map()], [map()]}
  defp process_catar_elements(elements) do
    grouped_files = group_catar_elements(elements)

    {files, directories} =
      Enum.reduce(grouped_files, {[], []}, fn item, {files_acc, dirs_acc} ->
        case item.type do
          :directory -> {files_acc, [item | dirs_acc]}
          _ -> {[item | files_acc], dirs_acc}
        end
      end)

    {Enum.reverse(files), Enum.reverse(directories)}
  end

  @spec group_catar_elements([Constants.catar_element()]) :: [map()]
  defp group_catar_elements(elements) do
    group_catar_elements_sequential(elements, [], nil, nil)
  end

  @spec group_catar_elements_sequential(
          [Constants.catar_element()],
          [map()],
          map() | nil,
          String.t() | nil
        ) :: [map()]
  defp group_catar_elements_sequential([], acc, _current_entry, _pending_name) do
    Enum.reverse(acc)
  end

  defp group_catar_elements_sequential([element | rest], acc, current_entry, pending_name) do
    case element do
      %{type: :filename, name: name} ->
        group_catar_elements_sequential(rest, acc, current_entry, name)

      %{type: :entry} = entry when not is_nil(pending_name) ->
        updated_entry = entry |> Map.put(:name, pending_name) |> Map.put(:path, pending_name)
        group_catar_elements_sequential(rest, acc, updated_entry, nil)

      %{type: :entry} = entry ->
        group_catar_elements_sequential(rest, acc, entry, pending_name)

      %{type: :payload, data: data} when not is_nil(current_entry) ->
        filename = Map.get(current_entry, :name, "unnamed_file")

        file =
          current_entry
          |> Map.put(:content, data)
          |> Map.put(:type, :file)
          |> Map.put(:name, filename)
          |> Map.put(:path, filename)

        group_catar_elements_sequential(rest, [file | acc], nil, nil)

      %{type: :symlink, target: target} when not is_nil(current_entry) ->
        filename = Map.get(current_entry, :name, "unnamed_symlink")

        file =
          current_entry
          |> Map.put(:target, target)
          |> Map.put(:type, :symlink)
          |> Map.put(:name, filename)
          |> Map.put(:path, filename)

        group_catar_elements_sequential(rest, [file | acc], nil, nil)

      %{type: :device, major: major, minor: minor} when not is_nil(current_entry) ->
        filename = Map.get(current_entry, :name, "unnamed_device")

        file =
          current_entry
          |> Map.put(:major, major)
          |> Map.put(:minor, minor)
          |> Map.put(:type, :device)
          |> Map.put(:name, filename)
          |> Map.put(:path, filename)

        group_catar_elements_sequential(rest, [file | acc], nil, nil)

      %{type: :goodbye} when not is_nil(current_entry) ->
        filename = Map.get(current_entry, :name, "unnamed_directory")

        file =
          current_entry
          |> Map.put(:type, :directory)
          |> Map.put(:name, filename)
          |> Map.put(:path, filename)

        group_catar_elements_sequential(rest, [file | acc], nil, nil)

      _ ->
        group_catar_elements_sequential(rest, acc, current_entry, pending_name)
    end
  end
end
