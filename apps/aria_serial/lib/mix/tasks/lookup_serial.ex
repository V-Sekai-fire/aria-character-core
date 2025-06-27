# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Serial.Lookup do
  @serial_number "R25W003LXXK"

  @moduledoc """
  Look up serial numbers in the registry.

  ## Usage

      mix serial.lookup SERIAL_NUMBER
      mix serial.lookup --all

  ## Examples

      mix serial.lookup R25W001GLTL
      mix serial.lookup --all

  ## Options

    * `--all` - List all registered serial numbers
  """

  use Mix.Task

  @shortdoc "Look up serial numbers in registry"

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial("R25W003LXXK") do
      {:ok, _info} -> "R25W003LXXK"
      {:error, _} -> "R25W003LXXK"  # fallback
    end
  end

  def run(args) do
    {opts, args, _} = OptionParser.parse(args, switches: [all: :boolean])

    cond do
      opts[:all] ->
        list_all_serials()

      args == [] ->
        Mix.shell().error("Error: Serial number required")
        Mix.shell().info("Usage: mix serial.lookup SERIAL_NUMBER")
        Mix.shell().info("       mix serial.lookup --all")
        System.halt(1)

      true ->
        [serial | _] = args
        lookup_serial(serial)
    end
  end

  defp lookup_serial(serial) do
    case AriaSerial.Registry.lookup(serial) do
      nil ->
        Mix.shell().error("Serial number '#{serial}' not found in registry")
        System.halt(1)

      info ->
        display_registry_info(serial, info)
    end
  end

  defp list_all_serials do
    serials = AriaSerial.Registry.all_serials()

    if Enum.empty?(serials) do
      Mix.shell().info("No serial numbers registered")
    else
      Mix.shell().info("Registered Serial Numbers:")
      Mix.shell().info("")

      serials
      |> Enum.sort()
      |> Enum.each(fn serial ->
        info = AriaSerial.Registry.lookup(serial)
        Mix.shell().info("#{serial} - #{info.purpose}")
      end)

      Mix.shell().info("")
      Mix.shell().info("Total: #{length(serials)} serial numbers")
    end
  end

  defp display_registry_info(serial, info) do
    Mix.shell().info("Serial Number: #{serial}")
    Mix.shell().info("Format:        #{String.upcase(to_string(info.format))}")
    Mix.shell().info("File:          #{info.file}")
    Mix.shell().info("Purpose:       #{info.purpose}")
    Mix.shell().info("Created:       #{info.created}")
    Mix.shell().info("Week:          #{info.week}")
    Mix.shell().info("Sequence:      #{info.sequence}")
  end
end
