# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Serial.Registry do
  @moduledoc """
  Embedded serial number registry for Aria project files.

  ## Serial Number Format

  **V1 Format**: `[F][YY][W][UUU][MMMM]` (12 characters)
  - F: Factory/Organization code (A=Aria, V=V-Sekai, etc.)
  - YY: Year (25=2025)
  - W: Week (1-9, C-Y for weeks 10-52, Z for week 53)
  - UUU: Unit sequence (001-999)
  - MMMM: Tool code (4 characters)

  **Character Rules**:
  - Allowed: 0-9, A-H, J-N, P-T, V-Y
  - Forbidden: I, O, U, Z (except Z for week 53)

  **Example**: `A25W001GLTL`
  - A: Aria organization
  - 25: Year 2025
  - W: Week 25 (June 17-23, 2025)
  - 001: First tool that week
  - GLTL: Goal tuples tool
  """

  @registry %{
    "R25W001STAT" => %{
      format: :v1,
      file: "state_parameter_order.ex",
      purpose: "Fix parameter order in State function calls",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 1
    },
    "R25W002GXAL" => %{
      format: :v1,
      file: "goal_tuples.ex",
      purpose: "Fix goal tuple parameter order",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 2
    },
    "R25W003LXGG" => %{
      format: :v1,
      file: "logger_conversion.ex",
      purpose: "Convert IO.puts to Logger calls",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 3
    },
    "R25W004STAT" => %{
      format: :v1,
      file: "statev2_api.ex",
      purpose: "Update StateV2 API calls",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 4
    },
    "R25W005STAT" => %{
      format: :v1,
      file: "state_parameters.ex",
      purpose: "Update State function parameters",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 5
    },
    "R25W006STAT" => %{
      format: :v1,
      file: "state_v2.ex",
      purpose: "Migrate StateV2 to State",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 6
    },
    "R25W016RESP" => %{
      format: :v1,
      file: "planning_response.ex",
      purpose: "Membrane planning response data structure",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 16
    },
    "R25W017PRMS" => %{
      format: :v1,
      file: "planning_params.ex",
      purpose: "Membrane planning parameters data structure",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 17
    },
    "R25W018RQST" => %{
      format: :v1,
      file: "planning_request.ex",
      purpose: "Membrane planning request data structure",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 18
    },
    "R25W019TMPL" => %{
      format: :v1,
      file: "minizinc_template_filter.ex",
      purpose: "Membrane MiniZinc template processing filter",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 19
    },
    "R25W020PXPE" => %{
      format: :v1,
      file: "pipeline_manager.ex",
      purpose: "Membrane pipeline coordination and management",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 20
    },
    "R25W021FMTR" => %{
      format: :v1,
      file: "format_transformer_filter.ex",
      purpose: "Membrane data format transformation filter",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 21
    },
    "R25W022PLNR" => %{
      format: :v1,
      file: "planner_filter.ex",
      purpose: "Membrane planning logic processing filter",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 22
    },
    "R25W023TEST" => %{
      format: :v1,
      file: "testing_filter.ex",
      purpose: "Membrane testing utilities and validation filter",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 23
    },
    "R25W024SLVR" => %{
      format: :v1,
      file: "minizinc_solver_filter.ex",
      purpose: "Membrane MiniZinc solver integration filter",
      created: ~D[2025-06-22],
      week: 26,
      sequence: 24
    }
  }

  @allowed_chars "0123456789ABCDEFGHJKLMNPQRSTVWXY"
  @week_encoding %{
    1 => "1",
    2 => "2",
    3 => "3",
    4 => "4",
    5 => "5",
    6 => "6",
    7 => "7",
    8 => "8",
    9 => "9",
    10 => "C",
    11 => "D",
    12 => "F",
    13 => "G",
    14 => "H",
    15 => "J",
    16 => "K",
    17 => "L",
    18 => "M",
    19 => "N",
    20 => "P",
    21 => "Q",
    22 => "R",
    23 => "S",
    24 => "T",
    25 => "V",
    26 => "W",
    27 => "X",
    28 => "Y",
    29 => "C",
    30 => "D",
    31 => "F",
    32 => "G",
    33 => "H",
    34 => "J",
    35 => "K",
    36 => "L",
    37 => "M",
    38 => "N",
    39 => "P",
    40 => "Q",
    41 => "R",
    42 => "S",
    43 => "T",
    44 => "V",
    45 => "W",
    46 => "X",
    47 => "Y",
    48 => "C",
    49 => "D",
    50 => "F",
    51 => "G",
    52 => "H",
    53 => "Z"
  }

  @week_decoding Map.new(@week_encoding, fn {k, v} -> {v, k} end)

  @doc "Look up serial number information"
  def lookup(serial), do: Map.get(@registry, serial)

  @doc "Get all registered serial numbers"
  def all_serials, do: Map.keys(@registry)

  @doc "Get next sequence number for a given week"
  def next_sequence(week) do
    @registry
    |> Enum.filter(fn {_serial, info} -> info.week == week end)
    |> Enum.map(fn {_serial, info} -> info.sequence end)
    |> case do
      [] -> 1
      sequences -> Enum.max(sequences) + 1
    end
  end

  @doc "Detect serial number format version"
  def detect_version(serial) do
    case String.length(serial) do
      # Allow 11 characters for shorter tool codes
      11 -> :v1
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
    base_name = String.replace(filename, ".ex", "")

    # Handle specific component patterns
    code =
      case base_name do
        "pipeline_manager" ->
          "PXPE"

        "format_transformer_filter" ->
          "FMTR"

        "minizinc_solver_filter" ->
          "SLVR"

        "minizinc_template_filter" ->
          "TMPL"

        "planner_filter" ->
          "PLNR"

        "testing_filter" ->
          "TEST"

        "planning_params" ->
          "PRMS"

        "planning_request" ->
          "RQST"

        "planning_response" ->
          "RESP"

        _ ->
          # Fallback to original algorithm for other files
          base_name
          |> String.replace("_", "")
          |> String.upcase()
          |> String.slice(0, 4)
          |> String.pad_trailing(4, "X")
      end

    ensure_valid_chars(code)
  end

  defp ensure_valid_chars(code) do
    code
    |> String.graphemes()
    |> Enum.map(fn char ->
      if valid_char?(char), do: char, else: "X"
    end)
    |> Enum.join()
  end

  defp decode_v1(serial) when byte_size(serial) >= 7 do
    <<factory::binary-size(1), year::binary-size(2), week_char::binary-size(1),
      unit::binary-size(3), tool_code::binary>> = serial

    with {:ok, week} <- decode_week_safe(week_char),
         {:ok, year_int} <- parse_year(year),
         {:ok, unit_int} <- parse_unit(unit) do
      registry_info = lookup(serial)

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

  defp decode_v1(_serial), do: {:error, :invalid_format}

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

  defp decode_factory("R"), do: "aRia Character Core"
  defp decode_factory(f), do: "Unknown Factory (#{f})"

  defp calculate_week_range(year, week) do
    try do
      # Use Timex if available, fallback to basic calculation
      if Code.ensure_loaded?(Timex) do
        start_date = Timex.from_iso_triplet({year, week, 1})
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
end
