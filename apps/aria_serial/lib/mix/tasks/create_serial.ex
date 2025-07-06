# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Serial.Create do
  @serial_number "R25W004CREA"

  @moduledoc """
  Create new serial numbers for migration tools.

  Project file with serial number: R25W004CREA
  Decode: mix serial.decode R25W004CREA

  ## Usage

      mix serial.create FILENAME PURPOSE [--factory=FACTORY] [--week=WEEK]

  ## Examples

      mix serial.create timeline_fixes.ex "Fix timeline namespace issues"
      mix serial.create timeline_fixes.ex "Fix timeline namespace issues" --factory=R --week=25

  ## Options

    * `--factory` - Factory code (default: R for Aria R-series)
    * `--week` - Week number (default: current week)
  """

  use Mix.Task

  @shortdoc "Create new serial numbers"

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: [factory: :string, week: :integer])

    case args do
      [filename, purpose | _] ->
        create_serial(filename, purpose, opts)

      [_filename] ->
        Mix.shell().error("Error: Purpose required")
        Mix.shell().info("Usage: mix serial.create FILENAME PURPOSE")
        System.halt(1)

      [] ->
        Mix.shell().error("Error: Filename and purpose required")
        Mix.shell().info("Usage: mix serial.create FILENAME PURPOSE")
        System.halt(1)
    end
  end

  defp create_serial(filename, purpose, opts) do
    factory = opts[:factory] || "R"
    week = opts[:week] || current_week()
    year = current_year()

    tool_code = AriaSerial.Registry.generate_tool_code(filename)

    # Create file info for registration
    file_info = %{
      "format" => "v1",
      "file" => filename,
      "purpose" => purpose,
      "created" => Date.to_iso8601(Date.utc_today()),
      "week" => week,
      "sequence" => nil  # Will be set by atomic generation
    }

    case AriaSerial.JsonStorage.generate_and_register_serial(year, week, factory, tool_code, file_info) do
      {:ok, serial} ->
        # Parse the generated serial to get the sequence number
        sequence = extract_sequence_from_serial(serial)

        Mix.shell().info("Generated Serial Number: #{serial}")
        Mix.shell().info("")
        Mix.shell().info("Details:")
        Mix.shell().info("  Factory:      #{factory} (#{decode_factory(factory)})")
        Mix.shell().info("  Year:         #{year}")
        Mix.shell().info("  Week:         #{week}")
        Mix.shell().info("  Sequence:     #{sequence}")
        Mix.shell().info("  Tool Code:    #{tool_code}")
        Mix.shell().info("  File:         #{filename}")
        Mix.shell().info("  Purpose:      #{purpose}")

        if week == current_week() do
          {start_date, end_date} = current_week_range()
          Mix.shell().info("  Week Range:   #{start_date} to #{end_date}")
        end

        Mix.shell().info("")
        Mix.shell().info("✅ Serial number generated and registered in lookup storage")
        Mix.shell().info("Use 'mix serial.decode #{serial}' to decode this serial number.")

      {:error, reason} ->
        Mix.shell().error("❌ Failed to generate and register serial: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp current_week do
    today = Date.utc_today()
    day_of_year = Date.day_of_year(today)
    div(day_of_year - 1, 7) + 1
  end

  defp current_year do
    Date.utc_today().year
  end

  defp current_week_range do
    today = Date.utc_today()
    days_since_monday = Date.day_of_week(today) - 1
    monday = Date.add(today, -days_since_monday)
    sunday = Date.add(monday, 6)
    {Date.to_string(monday), Date.to_string(sunday)}
  end

  defp extract_sequence_from_serial(serial) do
    # Extract sequence from serial format: R25W001GLTL
    # Sequence is characters 4-6 (positions 3-5, 0-indexed)
    <<_factory::binary-size(1), _year::binary-size(2), _week::binary-size(1),
      sequence::binary-size(3), _tool_code::binary>> = serial
    String.to_integer(sequence)
  end

  defp decode_factory("R"), do: "Aria Character Core (R-series)"
  defp decode_factory("Q"), do: "Fire's Personal Projects"
  defp decode_factory(f), do: "Unknown Factory (#{f})"
end
