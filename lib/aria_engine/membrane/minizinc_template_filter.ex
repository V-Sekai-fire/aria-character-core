defmodule AriaEngine.Membrane.MiniZincTemplateFilter do
  @moduledoc """
  Migration tool with serial number: A25W010TMPL

  Decode: mix migrate.decode_serial A25W010TMPL
  """

  @serial_number "A25W010TMPL"

  @moduledoc """
  Membrane filter that processes MiniZinc problems using EEx templates and Porcelain execution.

  This filter:
  1. Takes structured problem data as input
  2. Renders appropriate MiniZinc template with problem variables
  3. Executes MiniZinc using Porcelain for robust process management
  4. Parses and formats the solution output
  5. Handles errors and timeouts gracefully
  """

  use Membrane.Filter

  require Logger

  alias AriaEngine.MiniZinc.Executor

  def_input_pad(:input, accepted_format: %Membrane.RemoteStream{})
  def_output_pad(:output, accepted_format: %Membrane.RemoteStream{})

  def_options(
    timeout: [
      spec: pos_integer(),
      default: 30_000,
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

    # Check if MiniZinc is available
    minizinc_available = Executor.check_availability()
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

      error_buffer =
        create_error_buffer(
          buffer,
          "MiniZinc not available on system",
          :unavailable
        )

      {[buffer: {:output, error_buffer}], state}
    else
      try do
        # Parse the incoming problem data
        problem_data = parse_problem_data(buffer.payload)
        Logger.info("🔧 Processing MiniZinc template problem")

        # Determine template and prepare variables
        {template_name, template_vars} = prepare_template_data(problem_data, state)

        # Execute MiniZinc with template
        result = execute_minizinc_template(template_name, template_vars, state)

        # Create response buffer
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

  # Private functions

  defp parse_problem_data(payload) do
    case Jason.decode(payload) do
      {:ok, data} -> data
      {:error, _} -> %{"raw_payload" => payload}
    end
  end

  defp prepare_template_data(problem_data, state) do
    # Extract template name from problem data or use default
    template_name =
      problem_data
      |> get_in(["template_name"])
      |> case do
        nil -> state.template_name
        name -> name
      end

    # Prepare template variables based on problem type
    template_vars =
      case template_name do
        "stn_temporal" ->
          prepare_stn_template_vars(problem_data)

        "widget_assembly" ->
          prepare_widget_template_vars(problem_data)

        _ ->
          # Generic template variables
          Map.get(problem_data, "template_vars", %{})
      end

    {template_name, template_vars}
  end

  defp prepare_stn_template_vars(problem_data) do
    # Extract STN problem parameters
    activities = Map.get(problem_data, "activities", [])
    constraints = Map.get(problem_data, "constraints", [])

    # Prepare durations array
    durations =
      activities
      |> Enum.map(fn activity ->
        Map.get(activity, "duration", 1)
      end)

    # Prepare constraints array with proper indexing
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
    # For widget assembly, extract relevant parameters
    %{
      num_tasks: Map.get(problem_data, "num_tasks", 2),
      task_durations: Map.get(problem_data, "durations", [30, 45]),
      precedence_constraints: Map.get(problem_data, "precedences", [[1, 2]])
    }
  end

  defp execute_minizinc_template(template_name, template_vars, state) do
    Logger.info("🔧 Executing template: #{template_name}")

    opts = [
      template_vars: template_vars,
      solver: state.solver,
      timeout: state.timeout
    ]

    case Executor.exec(template_name, opts) do
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
