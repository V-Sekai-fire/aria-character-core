# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSerial.Similarity do
  @moduledoc """
  String similarity algorithms for Aria Serial tools.

  Provides various string matching algorithms for suggesting
  similar serial numbers when invalid input is provided.
  """

  alias AriaSerial.Registry

  @doc """
  Suggest similar serial numbers for an invalid input.

  Shows suggestions based on similarity algorithms and falls back
  to recent serial numbers if no good matches are found.
  """
  def suggest_similar_serials(invalid_serial) do
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

  @doc """
  Calculate similarity between two strings using weighted combination of algorithms.
  """
  def calculate_similarity(str1, str2) do
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

  @doc """
  Calculate Jaro similarity between two strings.
  """
  def jaro_similarity(str1, str2) do
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

  @doc """
  Calculate Levenshtein similarity between two strings.
  """
  def levenshtein_similarity(str1, str2) do
    distance = levenshtein_distance(str1, str2)
    max_len = max(String.length(str1), String.length(str2))

    if max_len == 0, do: 1.0, else: 1.0 - distance / max_len
  end

  @doc """
  Calculate prefix similarity between two strings.
  """
  def prefix_similarity(str1, str2) do
    chars1 = String.graphemes(str1)
    chars2 = String.graphemes(str2)

    common_prefix_length =
      Enum.zip(chars1, chars2)
      |> Enum.take_while(fn {c1, c2} -> c1 == c2 end)
      |> length()

    max_len = max(length(chars1), length(chars2))

    if max_len == 0, do: 1.0, else: common_prefix_length / max_len
  end

  # Private helper functions for Jaro similarity

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

  # Private helper functions for Levenshtein distance

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
end
