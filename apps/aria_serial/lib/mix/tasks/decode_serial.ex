# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Serial.Decode do
  @moduledoc """
  Decode serial numbers to human-readable information.

  ## Usage

      mix serial.decode SERIAL_NUMBER [--verbose]

  ## Examples

      mix serial.decode R25W001GLTL
      mix serial.decode R25W001GLTL --verbose

  ## Options

    * `--verbose` - Show detailed information including registry data
  """

  use Mix.Task

  @shortdoc "Decode serial numbers"

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: [verbose: :boolean])

    case args do
      [] ->
        Mix.shell().error("Error: Serial number required")
        Mix.shell().info("Usage: mix serial.decode SERIAL_NUMBER [--verbose]")
        System.halt(1)

      [serial | _] ->
        decode_serial(serial, opts[:verbose] || false)
    end
  end

  defp decode_serial(serial, verbose) do
    case AriaSerial.Registry.decode(serial) do
      {:error, reason} ->
        Mix.shell().error("Error decoding serial '#{serial}': #{format_error(reason)}")
        System.halt(1)

      decoded ->
        display_decoded_info(decoded, verbose)
    end
  end

  defp format_error(:invalid_format), do: "Invalid serial number format"
  defp format_error({:invalid_week_char, char}), do: "Invalid week character: #{char}"
  defp format_error({:invalid_year, year}), do: "Invalid year: #{year}"
  defp format_error({:invalid_unit, unit}), do: "Invalid unit: #{unit}"
  defp format_error(:v2_not_implemented), do: "V2 format not yet implemented"
  defp format_error(:v3_not_implemented), do: "V3 format not yet implemented"
  defp format_error(other), do: inspect(other)

  defp display_decoded_info(decoded, verbose) do
    Mix.shell().info("Format Version: #{String.upcase(to_string(decoded.format))}")
    Mix.shell().info("Factory:        #{decoded.factory}")
    Mix.shell().info("Year:           #{decoded.year}")
    Mix.shell().info("Week:           #{decoded.week}")
    Mix.shell().info("Unit:           #{decoded.unit}")
    Mix.shell().info("Tool Code:      #{decoded.tool_code}")

    if decoded.date_range do
      {start_date, end_date} = decoded.date_range
      Mix.shell().info("Week Range:     #{start_date} to #{end_date}")
    end

    if verbose && decoded.registry_info do
      Mix.shell().info("")
      Mix.shell().info("Registry Information:")
      Mix.shell().info("  File:         #{decoded.registry_info.file}")
      Mix.shell().info("  Purpose:      #{decoded.registry_info.purpose}")
      Mix.shell().info("  Created:      #{decoded.registry_info.created}")
      Mix.shell().info("  Sequence:     #{decoded.registry_info.sequence}")
    end
  end
end
