defmodule AriaEngine.Membrane.ValidationPipelineFilter do
  @moduledoc "Membrane filter that validates scheduling problems by:\n1. Taking MCP schedule_activities format as input\n2. Converting to both Hybrid solver and MiniZinc formats\n3. Solving with both approaches\n4. Comparing results and returning validation status:\n   - success: both solve and solutions match\n   - inconsistent: both solve but solutions don't match\n   - infeasible: neither can solve\n   - unknown: MiniZinc not available or other issues\n5. Providing solution trees for both approaches\n"
  use Membrane.Filter
  require Logger

  alias AriaEngine.Membrane.ValidationPipeline.{
    HybridSolver,
    MiniZincSolver,
    SolutionComparator,
    ResponseFormatter
  }

  def_input_pad(:input, accepted_format: %Membrane.RemoteStream{})
  def_output_pad(:output, accepted_format: %Membrane.RemoteStream{})

  def_options(
    timeout: [spec: pos_integer(), default: 30000, description: "Solver timeout in milliseconds"]
  )

  @impl true
  def handle_init(_ctx, opts) do
    minizinc_available = MiniZincSolver.check_availability()
    state = %{timeout: opts.timeout, minizinc_available: minizinc_available, validation_count: 0}
    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    try do
      mcp_request = Jason.decode!(buffer.payload)
      params = mcp_request["params"]["arguments"]

      hybrid_result =
        try do
          HybridSolver.solve(params, state)
        rescue
          error ->
            Logger.error("Hybrid solver failed with exception: #{Exception.message(error)}")
            %{status: :error, error: Exception.message(error)}
        end

      minizinc_result =
        if state.minizinc_available do
          try do
            MiniZincSolver.solve(params, state)
          rescue
            error ->
              Logger.error("MiniZinc solver failed with exception: #{Exception.message(error)}")
              %{status: :error, error: Exception.message(error)}
          end
        else
          %{status: :unavailable, reason: "MiniZinc not installed"}
        end

      validation_result =
        SolutionComparator.validate_and_compare(
          hybrid_result,
          minizinc_result,
          params,
          state
        )

      response =
        ResponseFormatter.create_validation_response(
          validation_result,
          hybrid_result,
          minizinc_result,
          mcp_request,
          state
        )

      response_payload = Jason.encode!(response)

      response_buffer = %Membrane.Buffer{
        payload: response_payload,
        metadata: %{
          validation: true,
          timestamp: DateTime.utc_now(),
          overall_status: validation_result.overall_status
        }
      }

      new_state = %{state | validation_count: state.validation_count + 1}
      {[buffer: {:output, response_buffer}], new_state}
    rescue
      error ->
        error_response = %{
          "id" => get_request_id(buffer.payload),
          "jsonrpc" => "2.0",
          "result" => %{
            "status" => "error",
            "error" => "Validation pipeline failed: #{Exception.message(error)}",
            "validation_type" => "pipeline_error"
          }
        }

        error_buffer = %Membrane.Buffer{
          payload: Jason.encode!(error_response),
          metadata: %{error: true, timestamp: DateTime.utc_now()}
        }

        {[buffer: {:output, error_buffer}], state}
    end
  end

  defp get_request_id(payload) do
    case Jason.decode(payload) do
      {:ok, %{"id" => id}} -> id
      _ -> "unknown"
    end
  rescue
    _ -> "unknown"
  end
end