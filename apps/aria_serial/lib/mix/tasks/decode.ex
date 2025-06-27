# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Serial.Decode do
  @serial_number "R25W002DECX"

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
  alias AriaSerial.Registry

  @shortdoc "Decode Aria project serial numbers"

  @doc "Returns the serial number for this module"
  def serial_number, do: @serial_number

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

      suggestions = find_similar_serials(invalid_serial, all_serials)

      if Enum.empty?(suggestions) do
        Mix.shell().info("  No similar serial numbers found")
        Mix.shell().info("")
        Mix.shell().info("Recent serial numbers:")

        all_serials
        |> Enum.take(3)
        |> Enum.each(fn serial ->
          Mix.shell().info("  #{serial}")
        end)
      else
        suggestions
        |> Enum.take(5)
        |> Enum.each(fn {serial, similarity} ->
          percentage = Float.round(similarity * 100, 1)
          Mix.shell().info("  #{serial} (#{percentage}% match)")
        end)
      end

      if length(all_serials) > 5 do
        Mix.shell().info("")
        Mix.shell().info("Use 'mix serial.decode --all' to see all #{length(all_serials)} serial numbers")
      end
    end
  end

  @doc """
  Find similar serial numbers using multiple similarity algorithms.

  Returns a list of {serial, similarity_score} tuples sorted by similarity.
  """
  def find_similar_serials(target, serials) do
    serials
    |> Enum.map(fn serial ->
      similarity = calculate_similarity(target, serial)
      {serial, similarity}
    end)
    |> Enum.filter(fn {_serial, similarity} -> similarity > 0.3 end)
    |> Enum.sort_by(fn {_serial, similarity} -> similarity end, :desc)
  end

  defp calculate_similarity(str1, str2) do
    # Use multiple similarity metrics and take the best score
    jaro_sim = jaro_similarity(str1, str2)
    levenshtein_sim = levenshtein_similarity(str1, str2)
    prefix_sim = prefix_similarity(str1, str2)

    # Weight the different similarities
    weighted_score =
      jaro_sim * 0.4 +
      levenshtein_sim * 0.4 +
      prefix_sim * 0.2

    weighted_score
  end

  defp jaro_similarity(str1, str2) do
    # Simple Jaro similarity implementation
    len1 = String.length(str1)
    len2 = String.length(str2)

    if len1 == 0 and len2 == 0, do: 1.0
    if len1 == 0 or len2 == 0, do: 0.0

    match_window = max(div(max(len1, len2), 2) - 1, 0)

    chars1 = String.graphemes(str1)
    chars2 = String.graphemes(str2)

    {matches1, matches2} = find_matches(chars1, chars2, match_window)

    matches = Enum.count(matches1, & &1)

    if matches == 0 do
      0.0
    else
      transpositions = count_transpositions(matches1, matches2, chars1, chars2)

      (matches / len1 + matches / len2 + (matches - transpositions) / matches) / 3.0
    end
  end

  defp find_matches(chars1, chars2, match_window) do
    len1 = length(chars1)
    len2 = length(chars2)

    matches1 = List.duplicate(false, len1)
    matches2 = List.duplicate(false, len2)

    {matches1, matches2} =
      Enum.with_index(chars1)
      |> Enum.reduce({matches1, matches2}, fn {char1, i}, {m1, m2} ->
        start = max(0, i - match_window)
        stop = min(i + match_window + 1, len2)

        case find_char_match(char1, chars2, m2, start, stop) do
          nil -> {m1, m2}
          j ->
            {List.replace_at(m1, i, true), List.replace_at(m2, j, true)}
        end
      end)

    {matches1, matches2}
  end

  defp find_char_match(char, chars2, matches2, start, stop) do
    Enum.find(start..(stop-1), fn j ->
      not Enum.at(matches2, j) and Enum.at(chars2, j) == char
    end)
  end

  defp count_transpositions(matches1, matches2, chars1, chars2) do
    matched_chars1 =
      Enum.with_index(matches1)
      |> Enum.filter(fn {match, _} -> match end)
      |> Enum.map(fn {_, i} -> Enum.at(chars1, i) end)

    matched_chars2 =
      Enum.with_index(matches2)
      |> Enum.filter(fn {match, _} -> match end)
      |> Enum.map(fn {_, i} -> Enum.at(chars2, i) end)

    Enum.zip(matched_chars1, matched_chars2)
    |> Enum.count(fn {c1, c2} -> c1 != c2 end)
    |> div(2)
  end

  defp levenshtein_similarity(str1, str2) do
    distance = levenshtein_distance(str1, str2)
    max_len = max(String.length(str1), String.length(str2))

    if max_len == 0, do: 1.0, else: 1.0 - distance / max_len
  end

  defp levenshtein_distance(str1, str2) do
    chars1 = String.graphemes(str1)
    chars2 = String.graphemes(str2)

    len1 = length(chars1)
    len2 = length(chars2)

    # Initialize distance matrix
    matrix =
      for i <- 0..len1 do
        for j <- 0..len2 do
          cond do
            i == 0 -> j
            j == 0 -> i
            true -> 0
          end
        end
      end

    # Fill the matrix
    matrix =
      Enum.reduce(1..len1, matrix, fn i, acc_matrix ->
        Enum.reduce(1..len2, acc_matrix, fn j, inner_matrix ->
          char1 = Enum.at(chars1, i - 1)
          char2 = Enum.at(chars2, j - 1)

          cost = if char1 == char2, do: 0, else: 1

          deletion = get_matrix_value(inner_matrix, i - 1, j) + 1
          insertion = get_matrix_value(inner_matrix, i, j - 1) + 1
          substitution = get_matrix_value(inner_matrix, i - 1, j - 1) + cost

          min_cost = min(deletion, min(insertion, substitution))
          set_matrix_value(inner_matrix, i, j, min_cost)
        end)
      end)

    get_matrix_value(matrix, len1, len2)
  end

  defp get_matrix_value(matrix, i, j) do
    matrix |> Enum.at(i) |> Enum.at(j)
  end

  defp set_matrix_value(matrix, i, j, value) do
    row = Enum.at(matrix, i)
    new_row = List.replace_at(row, j, value)
    List.replace_at(matrix, i, new_row)
  end

  defp prefix_similarity(str1, str2) do
    chars1 = String.graphemes(str1)
    chars2 = String.graphemes(str2)

    common_prefix_length =
      Enum.zip(chars1, chars2)
      |> Enum.take_while(fn {c1, c2} -> c1 == c2 end)
      |> length()

    max_len = max(length(chars1), length(chars2))

    if max_len == 0, do: 1.0, else: common_prefix_length / max_len
  end

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

  defp show_help do
    Mix.shell().info(@moduledoc)
  end
end
