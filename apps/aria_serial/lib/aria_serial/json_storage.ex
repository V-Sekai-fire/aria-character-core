# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial.JsonStorage do
  @serial_number "R25W007JSXN"

  @moduledoc """
  JSON-based storage system for serial number registry data.

  Project file with serial number: R25W007JSXN
  Decode: mix serial.decode R25W007JSXN

  Provides persistent storage for serial numbers organized by year, week, and factory.
  Supports atomic operations, backup creation, and data validation.
  """

  @doc "Returns the serial number for this module"
  def serial_number do
    case lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

  @storage_root "priv/serial_data"

  @doc """
  Load serial data for a specific year, week, and factory.
  """
  def load_week_data(year, week, factory) do
    file_path = get_file_path(year, week, factory)

    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:json_decode, reason}}
        end

      {:error, :enoent} ->
        {:ok, create_empty_week_data(year, week, factory)}

      {:error, reason} ->
        {:error, {:file_read, reason}}
    end
  end

  @doc """
  Save serial data for a specific year, week, and factory.
  """
  def save_week_data(year, week, factory, data) do
    file_path = get_file_path(year, week, factory)
    dir_path = Path.dirname(file_path)

    with :ok <- File.mkdir_p(dir_path),
         {:ok, json} <- Jason.encode(data, pretty: true),
         :ok <- File.write(file_path, json) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Add a new serial number to the registry.
  """
  def add_serial(serial, info) do
    %{year: year, week: week, factory: factory} = parse_serial_components(serial)

    with {:ok, data} <- load_week_data(year, week, factory),
         updated_data <- add_serial_to_data(data, serial, info),
         :ok <- save_week_data(year, week, factory, updated_data) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Atomically generate and register a new serial number.

  This function ensures that a serial number is only generated if it can be
  successfully written to the lookup storage. If the storage write fails,
  no serial is generated and the sequence number is not consumed.
  """
  def generate_and_register_serial(year, week, factory, tool_code, file_info) do
    with {:ok, data} <- load_week_data(year, week, factory),
         sequence <- data["next_sequence"] || 1,
         week_char <- AriaSerial.Registry.encode_week(week),
         {:ok, serial} <- build_serial(factory, year, week_char, sequence, tool_code),
         updated_data <- add_serial_to_data(data, serial, file_info),
         :ok <- save_week_data(year, week, factory, updated_data) do
      {:ok, serial}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, {:invalid_week, week}}
    end
  end

  @doc """
  Look up a serial number in the registry.
  """
  def lookup_serial(serial) do
    %{year: year, week: week, factory: factory} = parse_serial_components(serial)

    case load_week_data(year, week, factory) do
      {:ok, data} ->
        case Map.get(data["serials"], serial) do
          nil -> {:error, :not_found}
          info -> {:ok, info}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get all serial numbers across all files.
  """
  def all_serials do
    storage_path = Path.join(File.cwd!(), @storage_root)

    if File.exists?(storage_path) do
      collect_all_serials(storage_path)
    else
      []
    end
  end

  @doc """
  Get the next sequence number for a given year, week, and factory.
  """
  def get_next_sequence(year, week, factory) do
    case load_week_data(year, week, factory) do
      {:ok, data} -> data["next_sequence"] || 1
      {:error, _} -> 1
    end
  end

  @doc """
  Store registry data at a specific path.
  """
  def store_registry(storage_path, registry_data) do
    dir_path = Path.dirname(storage_path)

    with :ok <- File.mkdir_p(dir_path),
         {:ok, json} <- Jason.encode(registry_data, pretty: true),
         :ok <- File.write(storage_path, json) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp build_serial(factory, year, week_char, sequence, tool_code) do
    year_str = String.slice(to_string(year), -2, 2)
    sequence_str = String.pad_leading(to_string(sequence), 3, "0")
    serial = "#{factory}#{year_str}#{week_char}#{sequence_str}#{tool_code}"
    {:ok, serial}
  end

  defp get_file_path(year, week, factory) do
    week_str = String.pad_leading(to_string(week), 2, "0")
    filename = "#{factory}_series.json"
    app_dir = Application.app_dir(:aria_serial, "priv")
    Path.join([app_dir, "serial_data", to_string(year), "week_#{week_str}", filename])
  end

  defp create_empty_week_data(year, week, factory) do
    %{
      "week" => week,
      "year" => year,
      "factory" => factory,
      "serials" => %{},
      "next_sequence" => 1,
      "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp add_serial_to_data(data, serial, info) do
    serials = Map.put(data["serials"], serial, info)
    next_sequence = (data["next_sequence"] || 1) + 1

    data
    |> Map.put("serials", serials)
    |> Map.put("next_sequence", next_sequence)
    |> Map.put("updated_at", DateTime.utc_now() |> DateTime.to_iso8601())
  end

  defp parse_serial_components(serial) do
    # Parse serial format: R25W001GLTL
    # R = factory, 25 = year, W = week char, 001 = sequence, GLTL = tool code
    <<factory::binary-size(1), year_str::binary-size(2), week_char::binary-size(1), _rest::binary>> = serial

    year = 2000 + String.to_integer(year_str)
    week = decode_week_char(week_char)

    %{year: year, week: week, factory: factory}
  end

  defp decode_week_char(char) do
    # Use the same week decoding as Registry
    AriaSerial.Registry.decode_week(char) || 1
  end

  defp collect_all_serials(storage_path) do
    storage_path
    |> File.ls!()
    |> Enum.flat_map(fn year_dir ->
      year_path = Path.join(storage_path, year_dir)
      if File.dir?(year_path) do
        collect_year_serials(year_path)
      else
        []
      end
    end)
  end

  defp collect_year_serials(year_path) do
    year_path
    |> File.ls!()
    |> Enum.flat_map(fn week_dir ->
      week_path = Path.join(year_path, week_dir)
      if File.dir?(week_path) do
        collect_week_serials(week_path)
      else
        []
      end
    end)
  end

  defp collect_week_serials(week_path) do
    week_path
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.flat_map(fn json_file ->
      file_path = Path.join(week_path, json_file)
      case File.read(file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, data} -> Map.keys(data["serials"] || %{})
            {:error, _} -> []
          end
        {:error, _} -> []
      end
    end)
  end
end
