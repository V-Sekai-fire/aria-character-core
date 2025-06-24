defmodule Mix.Tasks.Serial.Create do
  @moduledoc """
  Create new serial numbers for migration tools.

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

    sequence = AriaSerial.Registry.next_sequence(week)
    tool_code = AriaSerial.Registry.generate_tool_code(filename)
    week_char = AriaSerial.Registry.encode_week(week)

    if week_char == nil do
      Mix.shell().error("Error: Invalid week number #{week}")
      System.halt(1)
    end

    serial = "#{factory}#{String.slice(to_string(year), -2, 2)}#{week_char}#{String.pad_leading(to_string(sequence), 3, "0")}#{tool_code}"

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
    Mix.shell().info("Registry Entry (for manual addition):")
    Mix.shell().info("\"#{serial}\" => %{")
    Mix.shell().info("  format: :v1,")
    Mix.shell().info("  file: \"#{filename}\",")
    Mix.shell().info("  purpose: \"#{purpose}\",")
    Mix.shell().info("  created: ~D[#{Date.to_string(Date.utc_today())}],")
    Mix.shell().info("  week: #{week},")
    Mix.shell().info("  sequence: #{sequence}")
    Mix.shell().info("}")
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

  defp decode_factory("R"), do: "Aria Character Core (R-series)"
  defp decode_factory("Q"), do: "Fire's Personal Projects"
  defp decode_factory(f), do: "Unknown Factory (#{f})"
end
