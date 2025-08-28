# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.UnifexExecutor do
  @moduledoc """
  Unifex-based MiniZinc executor that provides high-performance
  constraint solving via embedded libminizinc.

  This module wraps the C++ NIF implementation and provides
  the same API as the original Porcelain-based executor.
  """

  # use AriaMinizincExecutor.Native  # Temporarily commented out for generation
  @behaviour AriaMinizincExecutor.ExecutorBehaviour

  require Logger

  @type execution_options :: keyword()
  @type execution_result :: map()
  @type error_reason :: atom() | String.t() | map()

  @doc """
  Execute raw MiniZinc content using the embedded libminizinc.

  ## Parameters
  - `minizinc_content` - Raw MiniZinc model content as string
  - `opts` - Execution options (solver, timeout, output_mode, etc.)

  ## Returns
  - `{:ok, result}` - Successfully executed with solution
  - `{:error, reason}` - Failed to execute or solve
  """
  @spec exec_raw(String.t(), execution_options()) ::
          {:ok, execution_result()} | {:error, error_reason()}
  def exec_raw(minizinc_content, opts \\ []) do
    try do
      options_payload = build_options_payload(opts)

      case __MODULE__.solve_raw(minizinc_content, options_payload) do
        {:ok, {status, solution, metadata}} ->
          {:ok, format_solution_result(status, solution, metadata)}
        {:error, {error_type, details}} ->
          {:error, format_error_result(error_type, details, opts)}
      end
    catch
      :exit, reason ->
        Logger.error("NIF crashed: #{inspect(reason)}")
        {:error, %{status: :nif_crash, reason: reason}}
      error ->
        Logger.error("NIF error: #{inspect(error)}")
        {:error, %{status: :nif_error, reason: error}}
    end
  end

  @doc """
  Check if MiniZinc is available via the NIF.

  ## Returns
  - `{:ok, version}` - MiniZinc is available with version info
  - `{:error, reason}` - MiniZinc is not available or accessible
  """
  @spec check_availability() :: {:ok, String.t()} | {:error, String.t()}
  def check_availability do
    try do
      __MODULE__.check_availability()
    catch
      :exit, reason ->
        Logger.error("NIF crashed during availability check: #{inspect(reason)}")
        {:error, "NIF crashed: #{inspect(reason)}"}
      error ->
        Logger.error("NIF error during availability check: #{inspect(error)}")
        {:error, "NIF error: #{inspect(error)}"}
    end
  end

  @doc """
  List available solvers via the NIF.

  ## Returns
  - `{:ok, solvers}` - List of available solver names
  - `{:error, reason}` - Failed to query solvers
  """
  @spec list_solvers() :: {:ok, [String.t()]} | {:error, String.t()}
  def list_solvers do
    try do
      __MODULE__.list_solvers()
    catch
      :exit, reason ->
        Logger.error("NIF crashed during solver listing: #{inspect(reason)}")
        {:error, "NIF crashed: #{inspect(reason)}"}
      error ->
        Logger.error("NIF error during solver listing: #{inspect(error)}")
        {:error, "NIF error: #{inspect(error)}"}
    end
  end

  # Private helper functions

  defp build_options_payload(opts) do
    default_options = %{
      "solver" => "org.minizinc.mip.coin-bc",
      "timeout" => "30000",
      "output_mode" => "json",
      "canonicalize" => "true",
      "no_output_comments" => "true",
      "output_objective" => "true"
    }

    # Convert keyword list to string map for C++ consumption
    options_map = opts
    |> Enum.reduce(default_options, fn {key, value}, acc ->
      Map.put(acc, to_string(key), to_string(value))
    end)

    # TODO: Convert to proper Unifex payload
    # For now, return the map (will be handled in C++)
    options_map
  end

  defp format_solution_result(status, solution, metadata) do
    # Convert the NIF result to match the exact current API format
    %{
      status: status,
      solution: parse_solution_data(solution),
      solving_start: get_metadata_field(metadata, "solving_start"),
      solving_end: get_metadata_field(metadata, "solving_end"),
      duration: get_metadata_field(metadata, "duration"),
      solve_time_ms: get_metadata_field(metadata, "solve_time_ms"),
      raw_output: get_metadata_field(metadata, "raw_output")
    }
  end

  defp format_error_result(error_type, details, opts) do
    start_time = DateTime.utc_now() |> DateTime.to_iso8601()
    end_time = DateTime.utc_now() |> DateTime.to_iso8601()

    %{
      status: :error,
      error_type: error_type,
      details: details,
      solving_start: start_time,
      solving_end: end_time,
      duration: "PT0.000S",
      solve_time_ms: 0,
      timeout_ms: opts[:timeout] || 30_000
    }
  end

  defp parse_solution_data(solution) do
    # TODO: Parse the solution payload from C++
    # For now, return a placeholder that matches expected format
    case solution do
      nil -> %{}
      data when is_map(data) -> parse_solution_map(data)
      _ -> %{raw: solution}
    end
  end

  defp parse_solution_map(data) do
    # Convert solution data to match current API format
    %{
      start_times: parse_array_field(data, "start_times"),
      end_times: parse_array_field(data, "end_times"),
      makespan: parse_integer_field(data, "makespan"),
      objective: parse_integer_field(data, "objective"),
      result: parse_integer_field(data, "result"),
      status: Map.get(data, "status", "SATISFIED")
    }
  end

  defp parse_array_field(data, field_name) do
    case Map.get(data, field_name) do
      nil -> []
      str when is_binary(str) ->
        str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
      list when is_list(list) -> list
      _ -> []
    end
  end

  defp parse_integer_field(data, field_name) do
    case Map.get(data, field_name) do
      nil -> nil
      str when is_binary(str) ->
        case Integer.parse(str) do
          {int, _} -> int
          :error -> nil
        end
      int when is_integer(int) -> int
      _ -> nil
    end
  end

  defp get_metadata_field(metadata, field_name) do
    case metadata do
      nil -> nil
      data when is_map(data) -> Map.get(data, field_name)
      _ -> nil
    end
  end
end
