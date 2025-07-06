# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincMultiply do
  @moduledoc """
  MiniZinc-based multiplication constraint solver with Fixpoint fallback.

  This application provides multiplication solving using MiniZinc constraint
  solving with automatic fallback to pure Elixir computation when MiniZinc
  is not available or fails.

  ## Dual Solver Strategy

  - **MiniZinc**: Primary solver using constraint satisfaction
  - **Fixpoint**: Fallback using direct arithmetic computation
  - **Auto**: Automatically selects the best available solver

  ## Usage

      # Basic multiplication with auto solver selection
      {:ok, result} = AriaMinizincMultiply.multiply(5, 3)
      result.result  # => 15

      # Force specific solver
      {:ok, result} = AriaMinizincMultiply.multiply(7, 2, solver: :minizinc)
      {:ok, result} = AriaMinizincMultiply.multiply(7, 2, solver: :fixpoint)

      # With default multiplier (3)
      {:ok, result} = AriaMinizincMultiply.multiply(4)
      result.result  # => 12
  """

  @type solver_type :: :auto | :minizinc | :fixpoint
  @type multiply_params :: %{input_value: integer(), multiplier: integer()}
  @type multiply_options :: keyword()
  @type multiply_result :: %{
          result: integer(),
          solving_start: String.t(),
          solving_end: String.t(),
          duration: String.t(),
          solver: solver_type()
        }
  @type error_reason :: String.t()

  @doc """
  Multiply an integer by a multiplier using the specified solver strategy.

  ## Parameters
  - `input_value` - Integer to multiply (must be non-zero)
  - `multiplier` - Integer multiplier (must be non-zero, defaults to 3)
  - `options` - Solver options including :solver, :timeout

  ## Solver Options
  - `:solver` - `:auto` (default), `:minizinc`, or `:fixpoint`
  - `:timeout` - Timeout in milliseconds (default: 30_000)

  ## Returns
  - `{:ok, result}` - Successfully computed multiplication with timing
  - `{:error, reason}` - Failed to compute multiplication

  ## Examples

      # Basic multiplication
      {:ok, result} = AriaMinizincMultiply.multiply(5, 3)
      result.result  # => 15

      # With default multiplier
      {:ok, result} = AriaMinizincMultiply.multiply(7)
      result.result  # => 21

      # Force specific solver
      {:ok, result} = AriaMinizincMultiply.multiply(4, 2, solver: :fixpoint)
  """
  @spec multiply(integer(), integer() | multiply_options(), multiply_options()) :: {:ok, multiply_result()} | {:error, error_reason()}
  def multiply(input_value, multiplier_or_options \\ 3, options \\ [])

  def multiply(input_value, multiplier_or_options, options) when is_integer(multiplier_or_options) do
    # Called with explicit multiplier
    multiplier = multiplier_or_options
    solve(%{input_value: input_value, multiplier: multiplier}, options)
  end

  def multiply(input_value, multiplier_or_options, _options) when is_list(multiplier_or_options) do
    # Called with options as second parameter, use default multiplier
    multiplier = 3
    options = multiplier_or_options
    solve(%{input_value: input_value, multiplier: multiplier}, options)
  end

  def multiply(input_value, multiplier_or_options, _options) do
    # Catch-all for invalid types
    case validate_inputs(input_value, multiplier_or_options) do
      :ok -> {:error, "Unexpected input type"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Solve multiplication using the dual solver strategy.

  ## Parameters
  - `params` - Map with :input_value and :multiplier keys
  - `options` - Solver options including :solver, :timeout

  ## Returns
  - `{:ok, result}` - Successfully computed multiplication
  - `{:error, reason}` - Failed to compute multiplication
  """
  @spec solve(multiply_params(), multiply_options()) :: {:ok, multiply_result()} | {:error, error_reason()}
  def solve(params, options \\ []) do
    %{input_value: input_value, multiplier: multiplier} = params

    with :ok <- validate_inputs(input_value, multiplier) do
      solver = Keyword.get(options, :solver, :auto)

      case solver do
        :minizinc -> solve_with_minizinc(params, options)
        :fixpoint -> solve_with_fixpoint(params, options)
        :auto -> auto_select_solver(params, options)
        _ -> {:error, "Invalid solver option: #{inspect(solver)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Auto-select the best available solver
  defp auto_select_solver(params, options) do
    case AriaMinizincExecutor.check_availability() do
      {:ok, _version} ->
        case solve_with_minizinc(params, options) do
          {:ok, result} -> {:ok, result}
          {:error, _reason} -> solve_with_fixpoint(params, options)
        end
      {:error, _reason} ->
        solve_with_fixpoint(params, options)
    end
  end

  # Solve using MiniZinc constraint solver
  defp solve_with_minizinc(params, options) do
    %{input_value: input_value, multiplier: multiplier} = params

    template_path = template_path()
    template_vars = %{input_value: input_value, multiplier: multiplier}
    exec_options = [timeout: Keyword.get(options, :timeout, 30_000)]

    solving_start = generate_timestamp()

    case AriaMinizincExecutor.exec(template_path, template_vars, exec_options) do
      {:ok, raw_output} ->
        solving_end = generate_timestamp()
        duration = calculate_duration(solving_start, solving_end)

        case parse_minizinc_output(raw_output) do
          {:ok, result_value} ->
            {:ok, %{
              result: result_value,
              solving_start: solving_start,
              solving_end: solving_end,
              duration: duration,
              solver: :minizinc
            }}
          {:error, reason} ->
            {:error, "Failed to parse MiniZinc output: #{reason}"}
        end

      {:error, reason} ->
        {:error, "MiniZinc execution failed: #{inspect(reason)}"}
    end
  end

  # Solve using direct arithmetic (Fixpoint fallback)
  defp solve_with_fixpoint(params, _options) do
    %{input_value: input_value, multiplier: multiplier} = params

    solving_start = generate_timestamp()
    result = input_value * multiplier
    solving_end = generate_timestamp()
    duration = calculate_duration(solving_start, solving_end)

    {:ok, %{
      result: result,
      solving_start: solving_start,
      solving_end: solving_end,
      duration: duration,
      solver: :fixpoint
    }}
  end

  # Validate multiplication inputs
  defp validate_inputs(input_value, multiplier) do
    cond do
      not is_integer(input_value) ->
        {:error, "input_value must be an integer"}
      input_value == 0 ->
        {:error, "input_value must be non-zero"}
      not is_integer(multiplier) ->
        {:error, "multiplier must be an integer"}
      multiplier == 0 ->
        {:error, "multiplier must be non-zero"}
      true ->
        :ok
    end
  end

  # Parse MiniZinc JSON output
  defp parse_minizinc_output(output) when is_binary(output) do
    case Jason.decode(output) do
      {:ok, %{"result" => result}} when is_integer(result) ->
        {:ok, result}
      {:ok, parsed} ->
        {:error, "Invalid result format: #{inspect(parsed)}"}
      {:error, reason} ->
        {:error, "JSON decode failed: #{inspect(reason)}"}
    end
  end

  defp parse_minizinc_output(output) do
    {:error, "Expected string output, got: #{inspect(output)}"}
  end

  # Get template path
  defp template_path do
    Path.join([Application.app_dir(:aria_minizinc_multiply), "priv", "templates", "multiply.mzn.eex"])
  end

  # Generate ISO8601 timestamp
  defp generate_timestamp do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end

  # Calculate duration between timestamps
  defp calculate_duration(start_time, end_time) do
    case {DateTime.from_iso8601(start_time), DateTime.from_iso8601(end_time)} do
      {{:ok, start_dt, _}, {:ok, end_dt, _}} ->
        diff_ms = DateTime.diff(end_dt, start_dt, :millisecond)
        "PT#{diff_ms / 1000}S"
      _ ->
        "PT0.001S"
    end
  end
end
