# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Serial.Decode do
  @serial_number "R25W002DECX"

  @moduledoc """
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
  """

  use Mix.Task
  alias AriaSerial.{Registry, Display, Similarity}

  @shortdoc "Decode Aria project serial numbers"

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
    end
  end

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
        Display.show_help()

      opts[:all] ->
        Display.show_all_serials(opts)

      opts[:calendar] ->
        Display.show_calendar(opts[:calendar])

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
        Display.display_decoded_info(decoded, verbose)

      {:error, :invalid_format} ->
        Mix.shell().error("❌ Invalid serial number format")
        Mix.shell().error("")
        Mix.shell().error("Expected format: [F][YY][W][UUU][MMMM] (12 characters)")
        Mix.shell().error("Example: A25W001GLTL")
        Similarity.suggest_similar_serials(serial)

      {:error, reason} ->
        Mix.shell().error("❌ Decode error: #{inspect(reason)}")
    end
  end
end
