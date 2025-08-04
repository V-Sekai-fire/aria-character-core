# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial.Display do
  @moduledoc """
  Display and formatting functions for Aria Serial tools.

  Handles all console output, formatting, and visual presentation
  for serial number decoding and registry information.
  """

  alias AriaSerial.Registry

  @doc """
  Display decoded serial number information with optional verbose details.
  """
  def display_decoded_info(decoded, verbose \\ false) do
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

  @doc """
  Show all registered serial numbers with optional verbose details.
  """
  def show_all_serials(opts) do
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

  @doc """
  Show week calendar for the specified year.
  """
  def show_calendar(year) do
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

  @doc """
  Show help information.
  """
  def show_help do
    Mix.shell().info("""
    Decode Aria project serial numbers.

    Project file with serial number: R25W002DECX

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
    """)
  end

  # Private helper functions

  defp calculate_week_dates(year, week) do
    try do
      if Code.ensure_loaded?(Timex) do
        # Use Timex.from_iso_triplet to create a date from ISO week
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
    start_day = (week - 1) * 7 + 1
    start_date = Date.new!(year, 1, 1) |> Date.add(start_day - 1)
    end_date = Date.add(start_date, 6)
    {Date.to_string(start_date), Date.to_string(end_date)}
  end

  defp has_week_53?(year) do
    if Code.ensure_loaded?(Timex) do
      # Check if week 53 exists by trying to create a date for it
      try do
        Timex.from_iso_triplet({year, 53, 1})
        true
      rescue
        _ -> false
      end
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
end
