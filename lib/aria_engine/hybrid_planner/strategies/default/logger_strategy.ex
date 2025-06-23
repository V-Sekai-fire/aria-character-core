defmodule HybridPlanner.Strategies.Default.LoggerStrategy do
  @moduledoc "Default logging strategy implementation using Elixir's Logger.\n\nThis strategy encapsulates logging operations while providing the clean\nstrategy interface defined in ADR-091.\n"
  @behaviour HybridPlanner.Strategies.LoggingStrategy
  require Logger
  @impl true
  def log(level, message, metadata \\ %{}, opts \\ []) do
    try do
      logger_level =
        case level do
          :debug -> :debug
          :info -> :info
          :warning -> :warning
          :error -> :error
          _ -> :info
        end

      enhanced_metadata =
        metadata
        |> Map.put(:timestamp, System.system_time(:millisecond))
        |> Map.put(:strategy_source, "HybridPlanner")

      verbose = Keyword.get(opts, :verbose, 0)

      formatted_message =
        if verbose > 2 and map_size(enhanced_metadata) > 0 do
          "#{message} | Metadata: #{inspect(enhanced_metadata)}"
        else
          message
        end

      Logger.log(logger_level, formatted_message)
      :ok
    rescue
      _ ->
        Logger.debug("LoggerStrategy: #{level} - #{message}")
        :ok
    end
  end

  @impl true
  def log_progress(phase, progress, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 0 do
      progress_info = Map.merge(progress, %{phase: phase, type: :progress})

      case phase do
        "planning" ->
          message = "Planning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, progress_info, opts)

        "temporal_validation" ->
          message = "Temporal validation: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, progress_info, opts)

        "execution" ->
          message = "Execution phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, progress_info, opts)

        "replanning" ->
          message = "Replanning phase: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, progress_info, opts)

        _ ->
          message = "#{phase}: #{Map.get(progress, :status, "unknown")}"
          log(:info, message, progress_info, opts)
      end
    else
      :ok
    end
  end

  @impl true
  def log_error(error, context \\ %{}, opts \\ []) do
    error_message =
      case error do
        %{__exception__: true} = exception -> "Exception: #{Exception.message(exception)}"
        error_string when is_binary(error_string) -> error_string
        other -> "Error: #{inspect(other)}"
      end

    error_metadata =
      Map.merge(context, %{type: :error, timestamp: System.system_time(:millisecond)})

    verbose = Keyword.get(opts, :verbose, 0)

    enhanced_message =
      if verbose > 1 and is_exception_value(error) do
        stacktrace = Process.info(self(), :current_stacktrace) |> elem(1)
        "#{error_message}
Stacktrace: #{Exception.format_stacktrace(stacktrace)}"
      else
        error_message
      end

    log(:error, enhanced_message, error_metadata, opts)
  end

  @impl true
  def configure(config, opts \\ []) do
    try do
      case config do
        %{level: level} when level in [:debug, :info, :warning, :error] ->
          log(:info, "LoggerStrategy configured with level: #{level}", %{config: config}, opts)

        %{format: format} when is_binary(format) ->
          log(:info, "LoggerStrategy configured with format: #{format}", %{config: config}, opts)

        _ ->
          log(:warning, "LoggerStrategy: Unknown configuration options", %{config: config}, opts)
      end

      :ok
    rescue
      e ->
        log(
          :error,
          "LoggerStrategy configuration error: #{Exception.message(e)}",
          %{config: config},
          opts
        )

        :ok
    end
  end

  defp is_exception_value(value) do
    case value do
      %{__exception__: true} -> true
      _ -> false
    end
  end

  @doc "Get strategy metadata and capabilities.\n"
  def strategy_info do
    %{
      name: "Logger Strategy",
      version: "1.0.0",
      description: "Default logging strategy using Elixir Logger",
      capabilities: [:structured_logging, :progress_tracking, :error_logging, :configuration],
      limitations: [:no_log_rotation, :no_custom_backends],
      underlying_implementation: "Elixir Logger"
    }
  end

  @doc "Check if this strategy can handle specific logging features.\n"
  def supports?(feature) when is_atom(feature) do
    capabilities = strategy_info()[:capabilities]
    feature in capabilities
  end

  @doc "Get performance characteristics of this strategy.\n"
  def performance_profile do
    %{logging_overhead: :low, memory_usage: :low, scalability: :excellent, async_support: :yes}
  end

  @doc "Create a scoped logger for a specific component.\n\nThis allows different parts of the hybrid planner to have\ncontextualized logging while using the same strategy.\n"
  def create_scoped_logger(scope, base_metadata \\ %{}) do
    fn level, message, metadata, opts ->
      scoped_metadata = Map.merge(base_metadata, Map.put(metadata, :scope, scope))
      log(level, "[#{scope}] #{message}", scoped_metadata, opts)
    end
  end
end