# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.Executor do
  @moduledoc """
  Porcelain-based MiniZinc executor for pure execution infrastructure.

  Provides clean API for executing raw MiniZinc content with automatic
  temporary file management and result parsing.
  """

  @behaviour AriaMinizincExecutor.ExecutorBehaviour
  require Logger

  @type execution_options :: keyword()
  @type execution_result :: map()
  @type error_reason :: atom() | String.t() | map()


  @doc """
  Execute raw MiniZinc content synchronously using Porcelain.

  ## Options

  - `:solver` - MiniZinc solver to use (default: "org.minizinc.mip.coin-bc")
  - `:timeout` - Execution timeout in milliseconds (default: 30_000)
  - `:temp_dir` - Temporary directory for files (default: system temp)
  - `:output_mode` - Output mode (default: "json")

  ## Examples

      # Execute raw MiniZinc content
      content = "int: x = 5; solve satisfy; output [result];"
      {:ok, result} = Executor.exec_raw(content)
  """
  @spec exec_raw(String.t(), execution_options()) :: {:ok, execution_result()} | {:error, error_reason()}
  def exec_raw(minizinc_content, opts \\ []) do
    opts = Keyword.merge(default_options(), opts)

    with {:ok, model_file} <- write_temp_file(minizinc_content, opts),
         {:ok, result} <- execute_minizinc(model_file, opts),
         :ok <- cleanup_temp_file(model_file, opts) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Check if MiniZinc is available on the system.
  Returns {:ok, version} if available, {:error, reason} if not.
  """
  @spec check_availability() :: {:ok, String.t()} | {:error, String.t()}
  def check_availability do
    case Porcelain.exec("minizinc", ["--version"]) do
      %{status: 0, out: output} ->
        version = extract_version(output)
        {:ok, version}
      %{status: status, err: error} ->
        {:error, "MiniZinc not available (exit code: #{status}): #{error}"}
      _ ->
        {:error, "MiniZinc not available"}
    end
  rescue
    error ->
      {:error, "MiniZinc check failed: #{Exception.message(error)}"}
  end

  # Extract version from MiniZinc --version output
  defp extract_version(output) do
    case Regex.run(~r/MiniZinc\s+(\d+\.\d+\.\d+)/, output) do
      [_, version] -> version
      _ -> "unknown version"
    end
  end

  defp default_options do
    [
      solver: "org.minizinc.mip.coin-bc",
      timeout: 30000,
      temp_dir: System.tmp_dir!(),
      output_mode: "json",
      cleanup: true
    ]
  end

  defp write_temp_file(content, opts) do
    try do
      temp_file = Path.join(opts[:temp_dir], "minizinc_#{:rand.uniform(10000)}.mzn")

      Logger.debug("MiniZinc script content:\n#{content}")

      File.write!(temp_file, content)
      {:ok, temp_file}
    rescue
      error -> {:error, "Failed to write temp file: #{Exception.message(error)}"}
    end
  end

  defp execute_minizinc(model_file, opts) do
    args = build_minizinc_args(model_file, opts)
    start_time = System.monotonic_time(:millisecond)
    solving_start = DateTime.utc_now() |> DateTime.to_iso8601()

    Logger.debug("MiniZinc command line: minizinc #{Enum.join(args, " ")}")

    result = Porcelain.exec("minizinc", args, out: :string, err: :string)

    end_time = System.monotonic_time(:millisecond)
    solving_end = DateTime.utc_now() |> DateTime.to_iso8601()
    solve_time = end_time - start_time
    duration = format_duration(solve_time)

    case result do
      %{status: 0, out: output} ->
        Logger.debug("MiniZinc stdout:\n#{output}")
        parsed_solution = parse_minizinc_output(output)

        {:ok,
         %{
           status: :success,
           solution: parsed_solution,
           solving_start: solving_start,
           solving_end: solving_end,
           duration: duration,
           solve_time_ms: solve_time,
           raw_output: output
         }}

      %{status: exit_code, out: output, err: error} ->
        Logger.debug("MiniZinc failed with exit code #{exit_code}")
        Logger.debug("MiniZinc stdout:\n#{output}")
        Logger.debug("MiniZinc stderr:\n#{error}")

        {:error,
         %{
           status: :error,
           exit_code: exit_code,
           output: output,
           error: error,
           solving_start: solving_start,
           solving_end: solving_end,
           duration: duration,
           solve_time_ms: solve_time
         }}

      %{status: :timeout} ->
        Logger.debug("MiniZinc execution timed out after #{opts[:timeout]}ms")

        {:error, %{
          status: :timeout,
          timeout_ms: opts[:timeout],
          solving_start: solving_start,
          solving_end: solving_end,
          duration: duration,
          solve_time_ms: solve_time
        }}
    end
  end

  defp build_minizinc_args(model_file, opts) do
    base_args = ["--canonicalize", "--no-output-comments", "--solver", opts[:solver], "--output-mode", opts[:output_mode]]

    objective_args =
      if opts[:output_mode] == "json" do
        ["--output-objective"]
      else
        []
      end

    base_args ++ objective_args ++ [model_file]
  end

  defp parse_minizinc_output(output) do
    try do
      json_part = output |> String.split("----------") |> List.first() |> String.trim()

      case Jason.decode(json_part) do
        {:ok, json_data} ->
          parse_json_solution(json_data)

        {:error, _error} ->
          parse_text_solution(output)
      end
    rescue
      _error -> %{raw: output}
    end
  end

  defp parse_json_solution(json_data) when is_map(json_data) do
    %{
      start_times: Map.get(json_data, "start_times", []),
      end_times: Map.get(json_data, "end_times", []),
      makespan: Map.get(json_data, "makespan"),
      objective: Map.get(json_data, "_objective") || Map.get(json_data, "objective"),
      result: Map.get(json_data, "result"),
      status: Map.get(json_data, "status", "SATISFIED")
    }
  end

  defp parse_text_solution(output) do
    lines = String.split(output, "\n")
    start_times = extract_array_values(lines, "start_times")
    end_times = extract_array_values(lines, "end_times")
    makespan = extract_single_value(lines, "makespan")
    result = extract_single_value(lines, "result")

    %{
      start_times: start_times,
      end_times: end_times,
      makespan: makespan,
      result: result
    }
  end

  defp extract_array_values(lines, variable_name) do
    pattern = ~r/#{variable_name}\s*=\s*\[([^\]]+)\]/

    Enum.find_value(lines, [], fn line ->
      case Regex.run(pattern, line) do
        [_, values_str] ->
          values_str
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.to_integer/1)

        _ ->
          nil
      end
    end)
  end

  defp extract_single_value(lines, variable_name) do
    pattern = ~r/#{variable_name}\s*=\s*(\d+)/

    Enum.find_value(lines, nil, fn line ->
      case Regex.run(pattern, line) do
        [_, value_str] -> String.to_integer(value_str)
        _ -> nil
      end
    end)
  end

  defp format_duration(milliseconds) do
    seconds = milliseconds / 1000
    "PT#{:erlang.float_to_binary(seconds, decimals: 3)}S"
  end

  defp cleanup_temp_file(file_path, opts) do
    if opts[:cleanup] && String.contains?(file_path, opts[:temp_dir]) do
      File.rm(file_path)
    end

    :ok
  end
end
