# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.MiniZincTemplateFilter do
  @moduledoc "Membrane filter that processes MiniZinc problems using EEx templates and Porcelain execution.\n\nThis filter:\n1. Takes structured problem data as input\n2. Renders appropriate MiniZinc template with problem variables\n3. Executes MiniZinc using Porcelain for robust process management\n4. Parses and formats the solution output\n5. Handles errors and timeouts gracefully\n"
  use Membrane.Filter
  require Logger
  # Use AriaMinizincExecutor external API instead of internal modules
  def_input_pad(:input, accepted_format: %Membrane.RemoteStream{})
  def_output_pad(:output, accepted_format: %Membrane.RemoteStream{})

  def_options(
    timeout: [
      spec: pos_integer(),
      default: 30000,
      description: "MiniZinc solver timeout in milliseconds"
    ],
    solver: [
      spec: String.t(),
      default: "org.minizinc.mip.coin-bc",
      description: "MiniZinc solver to use"
    ],
    template_name: [
      spec: String.t(),
      default: "stn_temporal",
      description: "Default template name to use"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    Logger.info("🔧 Initializing MiniZinc Template Filter")
    minizinc_available = AriaMinizincExecutor.check_availability()
    Logger.info("🔧 MiniZinc available: #{minizinc_available}")

    state = %{
      timeout: opts.timeout,
      solver: opts.solver,
      template_name: opts.template_name,
      minizinc_available: minizinc_available,
      execution_count: 0
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    Logger.info("🔧 MiniZinc Template Filter received buffer")

    if not state.minizinc_available do
      Logger.error("❌ MiniZinc not available")
      error_buffer = create_error_buffer(buffer, "MiniZinc not available on system", :unavailable)
      {[buffer: {:output, error_buffer}], state}
    else
      try do
        problem_data = parse_problem_data(buffer.payload)
        Logger.info("🔧 Processing MiniZinc template problem")
        {template_name, template_vars} = prepare_template_data(problem_data, state)
        result = execute_minizinc_template(template_name, template_vars, state)
        response_buffer = create_response_buffer(buffer, result, problem_data)
        new_state = %{state | execution_count: state.execution_count + 1}
        {[buffer: {:output, response_buffer}], new_state}
      rescue
        error ->
          Logger.error("❌ MiniZinc Template Filter error: #{inspect(error)}")

          error_buffer =
            create_error_buffer(
              buffer,
              "Template processing failed: #{Exception.message(error)}",
              :processing_error
            )

          {[buffer: {:output, error_buffer}], state}
      end
    end
  end

  defp parse_problem_data(payload) do
    case Jason.decode(payload) do
      {:ok, data} -> data
      {:error, _} -> %{"raw_payload" => payload}
    end
  end

  defp prepare_template_data(problem_data, state) do
    template_name =
      problem_data
      |> get_in(["template_name"])
      |> case do
        nil -> state.template_name
        name -> name
      end

    template_vars =
      case template_name do
        "stn_temporal" -> prepare_stn_template_vars(problem_data)
        "widget_assembly" -> prepare_widget_template_vars(problem_data)
        _ -> Map.get(problem_data, "template_vars", %{})
      end

    {template_name, template_vars}
  end

  defp prepare_stn_template_vars(problem_data) do
    activities = Map.get(problem_data, "activities", [])
    constraints = Map.get(problem_data, "constraints", [])
    durations = activities |> Enum.map(fn activity -> Map.get(activity, "duration", 1) end)

    formatted_constraints =
      constraints
      |> Enum.map(fn constraint ->
        %{
          from_activity: Map.get(constraint, "from", 1),
          to_activity: Map.get(constraint, "to", 2),
          min_distance: Map.get(constraint, "min_distance", 0),
          max_distance: Map.get(constraint, "max_distance", 1000)
        }
      end)

    %{
      num_activities: length(activities),
      num_constraints: length(constraints),
      durations: durations,
      constraints: formatted_constraints
    }
  end

  defp prepare_widget_template_vars(problem_data) do
    %{
      num_tasks: Map.get(problem_data, "num_tasks", 2),
      task_durations: Map.get(problem_data, "durations", [30, 45]),
      precedence_constraints: Map.get(problem_data, "precedences", [[1, 2]])
    }
  end

  defp execute_minizinc_template(template_name, template_vars, state) do
    Logger.info("🔧 Executing template: #{template_name}")
    opts = [solver: state.solver, timeout: state.timeout]

    case AriaMinizincExecutor.exec(template_name, template_vars, opts) do
      {:ok, result} ->
        Logger.info("✅ MiniZinc template execution successful")
        result

      {:error, error} ->
        Logger.error("❌ MiniZinc template execution failed: #{inspect(error)}")

        %{
          status: :error,
          error: error,
          template_name: template_name,
          template_vars: template_vars
        }
    end
  end

  defp create_response_buffer(original_buffer, result, problem_data) do
    response_data = %{
      "minizinc_result" => result,
      "problem_data" => problem_data,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "filter" => "minizinc_template"
    }

    response_payload = Jason.encode!(response_data)

    %Membrane.Buffer{
      payload: response_payload,
      metadata:
        Map.merge(original_buffer.metadata || %{}, %{
          minizinc_status: result.status,
          timestamp: DateTime.utc_now(),
          template_execution: true
        })
    }
  end

  defp create_error_buffer(original_buffer, error_message, error_type) do
    error_data = %{
      "status" => "error",
      "error" => error_message,
      "error_type" => error_type,
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "filter" => "minizinc_template"
    }

    error_payload = Jason.encode!(error_data)

    %Membrane.Buffer{
      payload: error_payload,
      metadata:
        Map.merge(original_buffer.metadata || %{}, %{
          error: true,
          error_type: error_type,
          timestamp: DateTime.utc_now()
        })
    }
  end
end
