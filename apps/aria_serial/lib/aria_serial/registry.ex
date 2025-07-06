# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial.Registry do
  @serial_number "R25W006REGX"

  @moduledoc """
  Serial number registry for Aria migration tools.

  ## Serial Number Format

  V1 Format: [F][YY][W][UUU][MMMM] (12 characters)
  - F: Factory/Organization code (A=Aria, V=V-Sekai, etc.)
  - YY: Year (25=2025)
  - W: Week (1-9, C-Y for weeks 10-52, Z for week 53)
  - UUU: Unit sequence (001-999)
  - MMMM: Tool code (4 characters)

  Character Rules:
  - Allowed: 0-9, A-H, J-N, P-T, V-Y
  - Forbidden: I, O, U, Z (except Z for week 53)

  Example: A25W001GLTL
  - A: Aria organization
  - 25: Year 2025
  - W: Week 25 (June 17-23, 2025)
  - 001: First tool that week
  - GLTL: Goal tuples tool
  """

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

  @allowed_chars "0123456789ABCDEFGHJKLMNPQRSTVWXY"
  @week_encoding %{
    1 => "1", 2 => "2", 3 => "3", 4 => "4", 5 => "5", 6 => "6", 7 => "7", 8 => "8", 9 => "9",
    10 => "A", 11 => "B", 12 => "C", 13 => "D", 14 => "E", 15 => "F", 16 => "G", 17 => "H",
    18 => "J", 19 => "K", 20 => "L", 21 => "M", 22 => "N", 23 => "P", 24 => "Q", 25 => "R",
    26 => "W", 27 => "S", 28 => "T", 29 => "V", 30 => "X", 31 => "Y", 32 => "2", 33 => "3",
    34 => "4", 35 => "5", 36 => "6", 37 => "7", 38 => "8", 39 => "9", 40 => "A", 41 => "B",
    42 => "C", 43 => "D", 44 => "E", 45 => "F", 46 => "G", 47 => "H", 48 => "J", 49 => "K",
    50 => "L", 51 => "M", 52 => "N", 53 => "Z"
  }

  @week_decoding Map.new(@week_encoding, fn {k, v} -> {v, k} end)

  @doc "Look up serial number information"
  def lookup(serial) do
    # Use JsonStorage for all serial lookups
    case AriaSerial.JsonStorage.lookup_serial(serial) do
      {:ok, info} -> convert_json_info_to_registry_format(info)
      {:error, _} -> nil
    end
  end

  @doc "Get all registered serial numbers"
  def all_serials do
    AriaSerial.JsonStorage.all_serials()
  end

  @doc "Get next sequence number for a given week"
  def next_sequence(week) do
    # Get current year
    current_year = Date.utc_today().year

    # Use JsonStorage to get next sequence
    AriaSerial.JsonStorage.get_next_sequence(current_year, week, "R")
  end

  @doc "Detect serial number format version"
  def detect_version(serial) do
    case String.length(serial) do
      11 -> :v1  # Handle legacy 11-character serials
      12 -> :v1
      13 -> :v2
      14 -> :v3
      _ -> :unknown
    end
  end

  @doc "Decode serial number to human-readable information"
  def decode(serial) do
    case detect_version(serial) do
      :v1 -> decode_v1(serial)
      :v2 -> decode_v2(serial)
      :v3 -> decode_v3(serial)
      :unknown -> {:error, :invalid_format}
    end
  end

  @doc "Encode week number to character"
  def encode_week(week) when week in 1..53 do
    Map.get(@week_encoding, week)
  end

  @doc "Decode week character to number"
  def decode_week(char) do
    Map.get(@week_decoding, char)
  end

  @doc "Validate character is allowed in serial numbers"
  def valid_char?(char) do
    String.contains?(@allowed_chars, char)
  end

  @doc "Generate tool code from filename"
  def generate_tool_code(filename) do
    filename
    |> String.replace(".ex", "")
    |> String.replace("_", "")
    |> String.upcase()
    |> String.slice(0, 4)
    |> String.pad_trailing(4, "X")
    |> ensure_valid_chars()
  end

  defp ensure_valid_chars(code) do
    code
    |> String.graphemes()
    |> Enum.map(fn char ->
      if valid_char?(char), do: char, else: "X"
    end)
    |> Enum.join()
  end

  defp decode_v1(serial) when byte_size(serial) == 11 do
    <<factory::binary-size(1), year::binary-size(2), week_char::binary-size(1),
      unit::binary-size(3), tool_code::binary-size(4)>> = serial

    with {:ok, week} <- decode_week_safe(week_char),
         {:ok, year_int} <- parse_year(year),
         {:ok, unit_int} <- parse_unit(unit) do

      registry_info = lookup(factory <> year <> week_char <> unit <> tool_code)

      %{
        format: :v1,
        factory: decode_factory(factory),
        year: 2000 + year_int,
        week: week,
        unit: unit_int,
        tool_code: tool_code,
        registry_info: registry_info,
        date_range: calculate_week_range(2000 + year_int, week)
      }
    else
      error -> error
    end
  end

  defp decode_v1(serial) when byte_size(serial) == 12 do
    <<factory::binary-size(1), year::binary-size(2), week_char::binary-size(1),
      unit::binary-size(3), tool_code::binary-size(5)>> = serial

    with {:ok, week} <- decode_week_safe(week_char),
         {:ok, year_int} <- parse_year(year),
         {:ok, unit_int} <- parse_unit(unit) do

      registry_info = lookup(factory <> year <> week_char <> unit <> tool_code)

      %{
        format: :v1,
        factory: decode_factory(factory),
        year: 2000 + year_int,
        week: week,
        unit: unit_int,
        tool_code: tool_code,
        registry_info: registry_info,
        date_range: calculate_week_range(2000 + year_int, week)
      }
    else
      error -> error
    end
  end

  defp decode_v1(_serial), do: {:error, :invalid_v1_format}

  defp decode_v2(_serial), do: {:error, :v2_not_implemented}
  defp decode_v3(_serial), do: {:error, :v3_not_implemented}

  defp decode_week_safe(char) do
    case decode_week(char) do
      nil -> {:error, {:invalid_week_char, char}}
      week -> {:ok, week}
    end
  end

  defp parse_year(year_str) do
    case Integer.parse(year_str) do
      {year, ""} -> {:ok, year}
      _ -> {:error, {:invalid_year, year_str}}
    end
  end

  defp parse_unit(unit_str) do
    case Integer.parse(unit_str) do
      {unit, ""} -> {:ok, unit}
      _ -> {:error, {:invalid_unit, unit_str}}
    end
  end

  defp decode_factory("R"), do: "Aria Character Core"
  defp decode_factory("Q"), do: "Fire's Personal Projects"
  defp decode_factory(f), do: "Unknown Factory (#{f})"

  defp calculate_week_range(year, week) do
    try do
      # Use Timex if available, fallback to basic calculation
      if Code.ensure_loaded?(Timex) do
        # Create a date for the first day of the year, then find the week
        jan_first = Date.new!(year, 1, 1)
        start_date = Timex.beginning_of_week(Timex.shift(jan_first, weeks: week - 1))
        end_date = Timex.end_of_week(start_date)
        {Date.to_string(start_date), Date.to_string(end_date)}
      else
        basic_week_calculation(year, week)
      end
    rescue
      _ -> basic_week_calculation(year, week)
    end
  end

  defp basic_week_calculation(year, week) do
    # Basic approximation: Jan 1 + (week - 1) * 7 days
    start_day = (week - 1) * 7 + 1
    start_date = Date.new!(year, 1, 1) |> Date.add(start_day - 1)
    end_date = Date.add(start_date, 6)
    {Date.to_string(start_date), Date.to_string(end_date)}
  end

  defp convert_json_info_to_registry_format(json_info) do
    # Convert JsonStorage format to Registry format
    created_date = case json_info["created"] do
      date_string when is_binary(date_string) ->
        case Date.from_iso8601(date_string) do
          {:ok, date} -> date
          {:error, _} -> Date.utc_today()
        end
      _ -> Date.utc_today()
    end

    %{
      format: String.to_atom(json_info["format"] || "v1"),
      file: json_info["file"],
      purpose: json_info["purpose"],
      created: created_date,
      week: json_info["week"],
      sequence: json_info["sequence"]
    }
  end
end
