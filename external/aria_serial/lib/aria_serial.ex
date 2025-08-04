# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial do
  @serial_number "R25W001ARXA"

  @moduledoc """
  External API for AriaSerial - Serial number generation and registry management.

  This module provides the public interface for AriaSerial functionality, including:
  - Serial number generation and registration
  - Registry lookup and management
  - Storage operations for serial data
  - Week encoding/decoding utilities

  All cross-app communication should use this external API rather than importing
  internal AriaSerial modules directly.

  ## Serial Number Management

      # Generate and register a new serial
      {:ok, serial} = AriaSerial.generate_serial(2025, 25, "R", "GLTL", file_info)

      # Look up existing serial
      {:ok, info} = AriaSerial.lookup_serial("R25W001GLTL")

      # Get all registered serials
      serials = AriaSerial.all_serials()

  ## Registry Operations

      # Decode serial to readable format
      decoded = AriaSerial.decode_serial("R25W001GLTL")

      # Generate tool code from filename
      tool_code = AriaSerial.generate_tool_code("my_tool.ex")

  ## Week Utilities

      # Encode/decode week numbers
      week_char = AriaSerial.encode_week(25)
      week_num = AriaSerial.decode_week("W")
  """

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

  # Registry Management API
  defdelegate lookup_serial(serial), to: AriaSerial.JsonStorage
  defdelegate all_serials(), to: AriaSerial.JsonStorage
  defdelegate add_serial(serial, info), to: AriaSerial.JsonStorage
  defdelegate generate_and_register_serial(year, week, factory, tool_code, file_info), to: AriaSerial.JsonStorage

  # Registry Utilities API
  defdelegate decode_serial(serial), to: AriaSerial.Registry, as: :decode
  defdelegate detect_version(serial), to: AriaSerial.Registry
  defdelegate generate_tool_code(filename), to: AriaSerial.Registry
  defdelegate lookup_registry(serial), to: AriaSerial.Registry, as: :lookup
  defdelegate next_sequence(week), to: AriaSerial.Registry

  # Week Encoding API
  defdelegate encode_week(week_number), to: AriaSerial.Registry
  defdelegate decode_week(week_char), to: AriaSerial.Registry
  defdelegate valid_char?(char), to: AriaSerial.Registry

  # Storage Management API
  defdelegate load_week_data(year, week, factory), to: AriaSerial.JsonStorage
  defdelegate save_week_data(year, week, factory, data), to: AriaSerial.JsonStorage
  defdelegate get_next_sequence(year, week, factory), to: AriaSerial.JsonStorage
  defdelegate store_registry(storage_path, registry_data), to: AriaSerial.JsonStorage

  @doc """
  Generate a serial number for a specific year and week.

  ## Parameters

  - `year`: Year (e.g., 2025)
  - `week`: Week number (1-53)
  - `factory`: Factory code (e.g., "R" for Aria)
  - `tool_code`: 4-character tool identifier
  - `file_info`: Metadata about the associated file

  ## Examples

      iex> file_info = %{file: "my_tool.ex", purpose: "Code generation"}
      iex> {:ok, serial} = AriaSerial.generate_serial(2025, 25, "R", "MYTL", file_info)
      iex> String.starts_with?(serial, "R25")
      true
  """
  def generate_serial(year, week, factory, tool_code, file_info) do
    generate_and_register_serial(year, week, factory, tool_code, file_info)
  end

  @doc """
  Convenience function to generate a serial number for current year and week.

  ## Parameters

  - `factory`: Factory code (e.g., "R" for Aria)
  - `tool_code`: 4-character tool identifier
  - `file_info`: Metadata about the associated file

  ## Examples

      iex> file_info = %{file: "my_tool.ex", purpose: "Code generation"}
      iex> {:ok, serial} = AriaSerial.generate_serial("R", "MYTL", file_info)
      iex> String.starts_with?(serial, "R25")
      true
  """
  def generate_serial(factory, tool_code, file_info) do
    current_date = Date.utc_today()
    year = current_date.year
    week = (Date.day_of_year(current_date) |> div(7)) + 1

    generate_and_register_serial(year, week, factory, tool_code, file_info)
  end

  @doc """
  Validate that a serial number follows the correct format.

  ## Examples

      iex> AriaSerial.validate_serial("R25W001GLTL")
      :ok

      iex> AriaSerial.validate_serial("invalid")
      {:error, :invalid_format}
  """
  def validate_serial(serial) do
    case detect_version(serial) do
      :unknown -> {:error, :invalid_format}
      _version -> :ok
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> AriaSerial.hello()
      :world

  """
  def hello do
    :world
  end
end
