defmodule AriaEngine.MiniZinc.Executor do
  @moduledoc """
  Porcelain-based MiniZinc executor with EEx templating support.
  
  Provides clean API for executing MiniZinc models with automatic
  temporary file management and template rendering.
  """

  require Logger

  @doc """
  Execute a MiniZinc model synchronously using Porcelain.
  
  ## Options
  
  - `:solver` - MiniZinc solver to use (default: "org.minizinc.mip.coin-bc")
  - `:timeout` - Execution timeout in milliseconds (default: 30_000)
  - `:temp_dir` - Temporary directory for files (default: system temp)
  - `:output_mode` - Output mode (default: "json")
  - `:template_vars` - Variables for EEx template rendering
  
  ## Examples
  
      # Execute with template variables
      {:ok, result} = Executor.exec("stn_temporal", 
        template_vars: %{
          num_activities: 3,
          durations: [10, 20, 15],
          constraints: [...]
        }
      )
      
      # Execute existing .mzn file
      {:ok, result} = Executor.exec("widget_assembly.mzn")
  """
  def exec(model_name, opts \\ []) do
    opts = Keyword.merge(default_options(), opts)
    
    with {:ok, model_file} <- prepare_model_file(model_name, opts),
         {:ok, result} <- execute_minizinc(model_file, opts),
         :ok <- cleanup_temp_file(model_file, opts) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Spawn MiniZinc execution asynchronously using Porcelain.
  
  Returns a Porcelain process that can be monitored for completion.
  """
  def spawn(model_name, opts \\ []) do
    opts = Keyword.merge(default_options(), opts)
    
    with {:ok, model_file} <- prepare_model_file(model_name, opts) do
      args = build_minizinc_args(model_file, opts)
      
      Logger.info("🔧 Spawning MiniZinc: minizinc #{Enum.join(args, " ")}")
      
      proc = Porcelain.spawn("minizinc", args, opts[:porcelain_opts] || [])
      
      # Schedule cleanup after process completion
      Task.start(fn ->
        Porcelain.Process.await(proc)
        cleanup_temp_file(model_file, opts)
      end)
      
      {:ok, proc}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Check if MiniZinc is available on the system.
  """
  def check_availability do
    case Porcelain.exec("minizinc", ["--version"]) do
      %{status: 0} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  # Private functions

  defp default_options do
    [
      solver: "org.minizinc.mip.coin-bc",
      timeout: 30_000,
      temp_dir: System.tmp_dir!(),
      output_mode: "json",
      template_vars: %{},
      cleanup: true
    ]
  end

  defp prepare_model_file(model_name, opts) do
    cond do
      String.ends_with?(model_name, ".mzn") ->
        # Direct .mzn file - check if it exists
        if File.exists?(model_name) do
          {:ok, model_name}
        else
          {:error, "MiniZinc file not found: #{model_name}"}
        end
        
      opts[:template_vars] != %{} ->
        # Template rendering required
        render_template(model_name, opts[:template_vars], opts)
        
      true ->
        {:error, "No template variables provided for template: #{model_name}"}
    end
  end

  defp render_template(template_name, vars, opts) do
    template_path = Path.join(["priv", "templates", "minizinc", "#{template_name}.mzn.eex"])
    
    if File.exists?(template_path) do
      try do
        # Read template
        template_content = File.read!(template_path)
        
        # Prepare template variables (convert to atoms for EEx)
        template_vars = prepare_eex_vars(vars)
        
        # Debug: Log template variables
        Logger.debug("🔍 Template variables: #{inspect(template_vars, pretty: true)}")
        
        # Render with EEx
        rendered_content = EEx.eval_string(template_content, assigns: template_vars)
        
        # Debug: Log rendered content
        Logger.debug("🔍 Rendered content:\n#{rendered_content}")
        
        # Write to temporary file
        temp_file = Path.join(opts[:temp_dir], "#{template_name}_#{:rand.uniform(10000)}.mzn")
        File.write!(temp_file, rendered_content)
        
        Logger.info("🔧 Rendered template #{template_name} to #{temp_file}")
        {:ok, temp_file}
        
      rescue
        error ->
          Logger.error("❌ Template rendering failed: #{inspect(error)}")
          {:error, "Template rendering failed: #{Exception.message(error)}"}
      end
    else
      {:error, "Template not found: #{template_path}"}
    end
  end

  defp prepare_eex_vars(vars) do
    # Convert keys to atoms for EEx template access
    vars
    |> convert_keys_to_atoms()
  end

  defp convert_keys_to_atoms(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {String.to_atom(to_string(k)), convert_keys_to_atoms(v)} end)
    |> Map.new()
  end

  defp convert_keys_to_atoms(data) when is_list(data) do
    Enum.map(data, &convert_keys_to_atoms/1)
  end

  defp convert_keys_to_atoms(data), do: data

  defp execute_minizinc(model_file, opts) do
    args = build_minizinc_args(model_file, opts)
    
    Logger.info("🔧 Executing MiniZinc: minizinc #{Enum.join(args, " ")}")
    
    start_time = System.monotonic_time(:millisecond)
    
    result = Porcelain.exec("minizinc", args, out: :string, err: :string)
    
    end_time = System.monotonic_time(:millisecond)
    solve_time = end_time - start_time
    
    case result do
      %{status: 0, out: output} ->
        Logger.info("✅ MiniZinc completed in #{solve_time}ms")
        
        parsed_solution = parse_minizinc_output(output)
        
        {:ok, %{
          status: :success,
          solution: parsed_solution,
          solve_time_ms: solve_time,
          raw_output: output
        }}
        
      %{status: exit_code, out: output, err: error} ->
        Logger.error("❌ MiniZinc failed with exit code #{exit_code}")
        
        {:error, %{
          status: :error,
          exit_code: exit_code,
          output: output,
          error: error,
          solve_time_ms: solve_time
        }}
        
      %{status: :timeout} ->
        Logger.error("❌ MiniZinc execution timed out after #{opts[:timeout]}ms")
        
        {:error, %{
          status: :timeout,
          timeout_ms: opts[:timeout],
          solve_time_ms: solve_time
        }}
    end
  end

  defp build_minizinc_args(model_file, opts) do
    base_args = [
      "--solver", opts[:solver],
      "--output-mode", opts[:output_mode]
    ]
    
    # Add output-objective for optimization problems
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
      # Try to parse as JSON first
      case Jason.decode(output) do
        {:ok, json_data} ->
          parse_json_solution(json_data)
          
        {:error, _} ->
          # Fall back to text parsing
          parse_text_solution(output)
      end
    rescue
      _ ->
        # If all parsing fails, return raw output
        %{raw: output}
    end
  end

  defp parse_json_solution(json_data) when is_map(json_data) do
    # Extract solution from MiniZinc JSON output
    solution = Map.get(json_data, "solution", %{})
    
    %{
      start_times: Map.get(solution, "start_times", []),
      end_times: Map.get(solution, "end_times", []),
      makespan: Map.get(solution, "makespan"),
      objective: Map.get(json_data, "objective"),
      status: Map.get(json_data, "status", "SATISFIED")
    }
  end

  defp parse_text_solution(output) do
    lines = String.split(output, "\n")
    
    # Extract values using regex patterns
    start_times = extract_array_values(lines, "start_times")
    end_times = extract_array_values(lines, "end_times")
    makespan = extract_single_value(lines, "makespan")
    
    %{
      start_times: start_times,
      end_times: end_times,
      makespan: makespan
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
          
        _ -> nil
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

  defp cleanup_temp_file(file_path, opts) do
    if opts[:cleanup] && String.contains?(file_path, opts[:temp_dir]) do
      File.rm(file_path)
      Logger.debug("🧹 Cleaned up temporary file: #{file_path}")
    end
    :ok
  end
end
