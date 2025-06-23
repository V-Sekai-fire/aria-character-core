# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Serial.Decode do
  @moduledoc """
  Decode Aria project serial numbers.

  ## Usage

      mix serial.decode A25W001GLTL
      mix serial.decode --all
      mix serial.decode --calendar 2025

  ## Serial Number Format

  Decodes industrial-grade serial numbers: `[F][YY][W][UUU][MMMM]`

  - F: Factory/Organization code
  - YY: Year (25=2025)
  - W: Week (encoded using standard system)
  - UUU: Sequential unit number
  - MMMM: Tool code

  ## Features

  - Decodes individual serial numbers to human-readable information
  - Shows all registered serial numbers with --all
  - Displays week calendar with --calendar
  - Validates serial number format
  - Shows tool details from registry
  - Supports format versioning (V1, V2, V3)

  ## Examples

      # Decode a specific serial number
      mix serial.decode A25W001GLTL

      # Show all registered serial numbers
      mix serial.decode --all

      # Show week calendar for 2025
      mix serial.decode --calendar 2025

      # Validate serial format
      mix serial.decode INVALID123
  """

  use Mix.Task
  alias Mix.Tasks.Serial.Registry

  @shortdoc "Decode Aria project serial numbers"

  @switches [
    all: :boolean,
    calendar: :integer,
    help: :boolean,
    verbose: :boolean
  ]

  @aliases [
    a: :all,
    c: :calendar,
    h: :help,
    v: :verbose
  ]

  def run(args) do
    {opts, args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    cond do
      opts[:help] ->
        show_help()

      opts[:all] ->
        show_all_serials(opts)

      opts[:calendar] ->
        show_calendar(opts[:calendar])

      length(args) == 1 ->
        decode_serial(hd(args), opts)

      true ->
        Mix.shell().error("Usage: mix serial.decode <serial_number>")
        Mix.shell().error("       mix serial.decode --all")
        Mix.shell().error("       mix serial.decode --calendar <year>")
        Mix.shell().error("       mix serial.decode --help")
    end
  end

  defp decode_serial(serial, opts) do
    verbose = opts[:verbose] || false

    Mix.shell().info("Aria Project Serial Number Decoder")
    Mix.shell().info("===================================")
    Mix.shell().info("")
    Mix.shell().info("Serial Number: #{serial}")
    Mix.shell().info("")

    case Registry.decode(serial) do
      %{} = decoded ->
        display_decoded_info(decoded, verbose)

      {:error, :invalid_format} ->
        Mix.shell().error("❌ Invalid serial number format")
        Mix.shell().error("")
        Mix.shell().error("Expected format: [F][YY][W][UUU][MMMM] (12 characters)")
        Mix.shell().error("Example: A25W001GLTL")
        suggest_similar_serials(serial)

      {:error, reason} ->
        Mix.shell().error("❌ Decode error: #{inspect(reason)}")
    end
  end

  defp display_decoded_info(decoded, verbose) do
    Mix.shell().info("Format Version: #{String.upcase(to_string(decoded.format))}")
    Mix.shell().info("Factory:        #{decoded.factory}")
    Mix.shell().info("Year:           #{decoded.year}")
    Mix.shell().info("Week:           #{decoded.week}")

    Mix.shell().info(
      "Unit Number:    #{String.pad_leading(to_string(decoded.unit), 3, "0")} (#{ordinal(decoded.unit)} tool created that week)"
    )

    Mix.shell().info("Tool Code:      #{decoded.tool_code}")

    if decoded.date_range do
      {start_date, end_date} = decoded.date_range
      Mix.shell().info("Week Dates:     #{start_date} to #{end_date}")
    end

    Mix.shell().info("")

    case decoded.registry_info do
      %{} = info ->
        Mix.shell().info("Tool Details:")
        Mix.shell().info("- File: #{info.file}")
        Mix.shell().info("- Purpose: #{info.purpose}")
        Mix.shell().info("- Created: #{info.created}")

        if verbose do
          Mix.shell().info("- Registry Format: #{info.format}")
          Mix.shell().info("- Week: #{info.week}")
          Mix.shell().info("- Sequence: #{info.sequence}")
        end

      nil ->
        Mix.shell().info("⚠️  Tool not found in registry")
        Mix.shell().info("This serial number is valid but not registered.")
    end

    if verbose do
      Mix.shell().info("")
      Mix.shell().info("Technical Details:")
      Mix.shell().info("- Character Rules: 0-9, A-H, J-N, P-T, V-Y (no I, O, U, Z)")
      Mix.shell().info("- Week Encoding: Standard system (1-9, C-Y, Z for week 53)")
      Mix.shell().info("- Format: #{inspect(decoded.format)}")
    end
  end

  defp show_all_serials(opts) do
    verbose = opts[:verbose] || false
    serials = Registry.all_serials()

    Mix.shell().info("All Registered Aria Project Serial Numbers")
    Mix.shell().info("==========================================")
    Mix.shell().info("")
    Mix.shell().info("Total: #{length(serials)} tools")
    Mix.shell().info("")

    serials
    |> Enum.sort()
    |> Enum.each(fn serial ->
      case Registry.lookup(serial) do
        %{} = info ->
          Mix.shell().info("#{serial} - #{info.file}")

          if verbose do
            Mix.shell().info("  Purpose: #{info.purpose}")
            Mix.shell().info("  Created: #{info.created}")
            Mix.shell().info("")
          end

        nil ->
          Mix.shell().info("#{serial} - [Registry info missing]")
      end
    end)

    if not verbose do
      Mix.shell().info("")
      Mix.shell().info("Use --verbose for detailed information")
    end
  end

  defp show_calendar(year) do
    Mix.shell().info("Week Calendar for #{year}")
    Mix.shell().info("========================")
    Mix.shell().info("")
    Mix.shell().info("Week Encoding System:")
    Mix.shell().info("")

    # Show weeks 1-9
    Mix.shell().info("Weeks 1-9:")

    for week <- 1..9 do
      char = Registry.encode_week(week)
      {start_date, end_date} = calculate_week_dates(year, week)

      Mix.shell().info(
        "  Week #{String.pad_leading(to_string(week), 2)} (#{char}): #{start_date} to #{end_date}"
      )
    end

    Mix.shell().info("")
    Mix.shell().info("Weeks 10-28:")

    for week <- 10..28 do
      char = Registry.encode_week(week)
      {start_date, end_date} = calculate_week_dates(year, week)
      Mix.shell().info("  Week #{week} (#{char}): #{start_date} to #{end_date}")
    end

    Mix.shell().info("")
    Mix.shell().info("Weeks 29-52:")

    for week <- 29..52 do
      char = Registry.encode_week(week)
      {start_date, end_date} = calculate_week_dates(year, week)
      Mix.shell().info("  Week #{week} (#{char}): #{start_date} to #{end_date}")
    end

    # Check for week 53
    if has_week_53?(year) do
      Mix.shell().info("")
      Mix.shell().info("Week 53 (Z): #{year} is a leap week year")
      {start_date, end_date} = calculate_week_dates(year, 53)
      Mix.shell().info("  Week 53 (Z): #{start_date} to #{end_date}")
    end

    Mix.shell().info("")
    Mix.shell().info("Character Rules:")
    Mix.shell().info("- Allowed: 0-9, A-H, J-N, P-T, V-Y")
    Mix.shell().info("- Forbidden: I, O, U, Z (except Z for week 53)")
  end

  defp suggest_similar_serials(invalid_serial) do
    all_serials = Registry.all_serials()

    if not Enum.empty?(all_serials) do
      Mix.shell().info("")
      Mix.shell().info("Did you mean one of these?")

      all_serials
      |> Enum.take(3)
      |> Enum.each(fn serial ->
        Mix.shell().info("  #{serial}")
      end)

      if length(all_serials) > 3 do
        Mix.shell().info("  ... and #{length(all_serials) - 3} more")
        Mix.shell().info("")
        Mix.shell().info("Use 'mix serial.decode --all' to see all serial numbers")
      end
    end
  end

  defp calculate_week_dates(year, week) do
    try do
      if Code.ensure_loaded?(Timex) do
        start_date = Timex.beginning_of_week(Timex.from_iso_week(year, week))
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
    start_day = (week - 1) * 7 + 1
    start_date = Date.new!(year, 1, 1) |> Date.add(start_day - 1)
    end_date = Date.add(start_date, 6)
    {Date.to_string(start_date), Date.to_string(end_date)}
  end

  defp has_week_53?(year) do
    if Code.ensure_loaded?(Timex) do
      Timex.weeks_in_year(year) == 53
    else
      # Basic check: years starting on Thursday or leap years starting on Wednesday
      jan_1 = Date.new!(year, 1, 1)
      day_of_week = Date.day_of_week(jan_1)
      leap_year = Date.leap_year?(year)

      day_of_week == 4 or (leap_year and day_of_week == 3)
    end
  end

  defp ordinal(1), do: "1st"
  defp ordinal(2), do: "2nd"
  defp ordinal(3), do: "3rd"
  defp ordinal(n), do: "#{n}th"

  defp show_help do
    Mix.shell().info(@moduledoc)
  end
end
