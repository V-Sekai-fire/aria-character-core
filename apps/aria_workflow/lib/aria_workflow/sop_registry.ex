# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.SOPRegistry do
  @moduledoc """
  Registry for managing SOP definitions.

  This GenServer maintains a registry of all available SOPs and provides
  functions for registration, retrieval, and management.
  
  Currently provides two core SOPs:
  1. basic_timing - UTC/local timezone capture and command timing
  2. command_tracing - Local command execution with error handling
  
  Uses in-memory storage until aria_data and aria_storage services come online.
  """

  use GenServer
  require Logger

  alias AriaWorkflow.SOPDefinition

  # Core SOPs for basic operations (simplified implementation)
  @hardcoded_sops %{
    "basic_timing" => %{
      goals: [
        {"timing_system", "commands", "enabled"},
        {"timezone_info", "system", "captured"},
        {"execution_log", "operations", "created"}
      ],
      tasks: [
        {"get_current_time", &AriaWorkflow.Tasks.BasicTiming.get_current_time/2},
        {"get_timezone_info", &AriaWorkflow.Tasks.BasicTiming.get_timezone_info/2},
        {"start_timer", &AriaWorkflow.Tasks.BasicTiming.start_timer/2},
        {"stop_timer", &AriaWorkflow.Tasks.BasicTiming.stop_timer/2},
        {"log_execution", &AriaWorkflow.Tasks.BasicTiming.log_execution/2}
      ],
      methods: [
        {"time_command_execution", &AriaWorkflow.Methods.BasicTiming.time_command_execution/2},
        {"generate_timing_report", &AriaWorkflow.Methods.BasicTiming.generate_timing_report/2}
      ],
      documentation: %{
        overview: ~s"""
        Basic Timing Standard Operating Procedure

        Provides core timing functionality for command execution and system operations.
        Captures UTC and local timezone information with millisecond precision timing.

        Designed for use without external service dependencies - operates independently
        using Elixir standard library functions only.
        """,
        
        timing_procedures: ~s"""
        Basic Timing Procedures
        
        1. Current Time Capture
        - UTC time: DateTime.utc_now() with microsecond precision
        - Local timezone: System timezone detection via OS commands
        - Millisecond timing: System.os_time(:millisecond) for performance measurement
        
        2. Command Execution Timing
        - Record start time before command execution
        - Execute command with timeout support
        - Record end time after completion
        - Calculate duration with sub-second precision
        - Log results with both UTC and local timestamps
        """,
        
        timezone_handling: ~s"""
        Timezone Information Capture
        
        Core timezone operations:
        1. Detect system timezone using `date +%Z` command
        2. Calculate UTC offset using system time functions
        3. Format timestamps in both UTC and local time
        4. Include timezone abbreviation for readability
        
        Example output:
        UTC: 2025-06-11T08:30:45.123Z
        Local: 2025-06-11T01:30:45.123 PST (UTC-7)
        Duration: 1.234 seconds
        Command: mix test --cover
        """,
        
        execution_logging: ~s"""
        Execution Logging
        
        In-memory logging with console output:
        1. Structured log format with timestamps
        2. Include command details, duration, and exit codes
        3. Error capture with stderr output
        4. Optional file logging to local filesystem
        
        Log format:
        [2025-06-11T08:30:45.123Z] [LOCAL:01:30:45 PST] EXEC: command_name (1.234s) - SUCCESS
        """
      },
      metadata: %{
        version: "1.0", 
        last_updated: ~D[2025-06-11],
        next_review: ~D[2025-07-11],
        approved_by: "Aria AI Assistant - Technical Lead",
        contact: %{
          primary_engineer: "Aria AI Assistant (GitHub Copilot)",
          backup_engineer: "Aria Character Core Development Team"
        },
        dependencies: [
          "Elixir standard library (DateTime, System)",
          "macOS system commands for timezone detection",
          "Local filesystem access for optional logging"
        ]
      }
    },
    
    "command_tracing" => %{
      goals: [
        {"command_execution", "local_commands", "traced"},
        {"execution_time", "commands", "measured"},
        {"error_handling", "failures", "captured"}
      ],
      tasks: [
        {"trace_command_start", &AriaWorkflow.Tasks.CommandTracing.trace_command_start/2},
        {"trace_command_end", &AriaWorkflow.Tasks.CommandTracing.trace_command_end/2},
        {"capture_command_output", &AriaWorkflow.Tasks.CommandTracing.capture_command_output/2},
        {"handle_command_error", &AriaWorkflow.Tasks.CommandTracing.handle_command_error/2}
      ],
      methods: [
        {"execute_with_tracing", &AriaWorkflow.Methods.CommandTracing.execute_with_tracing/2},
        {"generate_execution_summary", &AriaWorkflow.Methods.CommandTracing.generate_execution_summary/2}
      ],
      documentation: %{
        overview: ~s"""
        Command Tracing Standard Operating Procedure

        Provides command execution tracing for local operations with comprehensive
        timing, output capture, and error handling. Focuses on macOS command
        execution with detailed logging and performance metrics.
        """,
        
        tracing_procedures: ~s"""
        Command Tracing Procedures
        
        1. Pre-execution Setup
        - Generate unique trace ID
        - Record start time (UTC + local timezone)
        - Capture command and arguments
        - Set up stdout/stderr capture
        
        2. During Execution  
        - Monitor execution progress
        - Stream stdout/stderr in real-time
        - Track resource usage when available
        - Handle timeout conditions
        
        3. Post-execution Analysis
        - Record end time and calculate duration
        - Analyze exit codes (0=success, 1-255=error)
        - Generate execution summary
        - Store trace data for reporting
        """,
        
        error_handling: ~s"""
        Error Handling Procedures
        
        1. Exit Code Analysis
        - 0: Success (command completed normally)
        - 1-125: General errors (application-specific)
        - 126: Command not executable
        - 127: Command not found
        - 128+n: Fatal error signal 'n'
        - Timeout: Special handling with SIGTERM/SIGKILL
        
        2. Error Capture and Logging
        - Capture stderr output with timestamps
        - Log exception messages and stack traces
        - Record system error codes and signals
        - Include environment context for debugging
        
        3. Recovery and Reporting
        - Log comprehensive error details
        - Determine retry feasibility
        - Generate failure reports with context
        - Update trace status appropriately
        """
      },
      metadata: %{
        version: "1.0",
        last_updated: ~D[2025-06-11], 
        next_review: ~D[2025-07-11],
        approved_by: "Aria AI Assistant - Technical Lead",
        dependencies: [
          "Elixir Port module for command execution",
          "macOS system commands and utilities",
          "Local filesystem for output capture"
        ]
      }
    }
  }

  @type registry_entry :: %{
    sop: SOPDefinition.t(),
    registered_at: DateTime.t(),
    version: String.t()
  }

  defstruct sops: %{}, name: __MODULE__, started_at: nil

  # Public API

  @doc """
  Starts the SOP registry.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{name: name}, name: name)
  end

  @doc """
  Registers an SOP in the registry.
  Note: Currently stores in memory until aria_data service comes online.
  """
  @spec register(SOPDefinition.t(), keyword()) :: :ok | {:error, term()}
  def register(%SOPDefinition{} = sop, opts \\ []) do
    name = Keyword.get(opts, :registry, __MODULE__)
    version = Keyword.get(opts, :version, "1.0.0")
    
    case SOPDefinition.validate(sop) do
      :ok ->
        GenServer.call(name, {:register, sop, version})
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets an SOP by ID.
  Returns built-in SOPs when available, falls back to registry.
  """
  @spec get(String.t(), keyword()) :: {:ok, SOPDefinition.t()} | {:error, :not_found}
  def get(sop_id, opts \\ []) do      case Map.get(@hardcoded_sops, sop_id) do
      nil ->
        # Fall back to registry lookup
        name = Keyword.get(opts, :registry, __MODULE__)
        GenServer.call(name, {:get, sop_id})
      
      builtin_def ->
        # Create SOPDefinition from built-in data
        sop = SOPDefinition.new(sop_id, builtin_def)
        {:ok, sop}
    end
  end

  @doc """
  Lists all registered SOPs (includes built-in ones).
  """
  @spec list_all(keyword()) :: [SOPDefinition.t()]
  def list_all(opts \\ []) do
    # Get built-in SOPs
    builtin_sops = 
      @hardcoded_sops
      |> Enum.map(fn {id, definition} -> SOPDefinition.new(id, definition) end)
    
    # Get registry SOPs
    name = Keyword.get(opts, :registry, __MODULE__)
    registry_sops = GenServer.call(name, :list_all)
    
    # Combine (registry takes precedence over built-in for same ID)
    all_sops = builtin_sops ++ registry_sops
    Enum.uniq_by(all_sops, & &1.id)
  end

  @doc """
  Gets current time information in both UTC and local timezone.
  """
  @spec get_current_time_info() :: %{
    utc: DateTime.t(),
    local: DateTime.t(), 
    timezone: String.t(),
    offset_seconds: integer()
  }
  def get_current_time_info do
    utc_now = DateTime.utc_now()
    
    # Get local timezone (simplified since we don't have full timezone DB)
    local_now = DateTime.shift_zone(utc_now, get_system_timezone())
    
    case local_now do
      {:ok, local_dt} ->
        %{
          utc: utc_now,
          local: local_dt,
          timezone: local_dt.time_zone,
          offset_seconds: local_dt.utc_offset + local_dt.std_offset
        }
      
      {:error, _} ->
        # Fallback to UTC only
        %{
          utc: utc_now,
          local: utc_now,
          timezone: "UTC",
          offset_seconds: 0
        }
    end
  end

  # GenServer Callbacks

  @impl GenServer
  def init(state) do
    started_at = DateTime.utc_now()
    Logger.info("Starting SOP Registry: #{state.name}")
    Logger.info("Loaded #{map_size(@hardcoded_sops)} built-in SOPs")
    Logger.info("Registry started at: #{DateTime.to_iso8601(started_at)}")
    
    {:ok, %__MODULE__{name: state.name, started_at: started_at}}
  end

  @impl GenServer
  def handle_call({:register, sop, version}, _from, state) do
    entry = %{
      sop: sop,
      registered_at: DateTime.utc_now(),
      version: version
    }
    
    new_sops = Map.put(state.sops, sop.id, entry)
    new_state = %{state | sops: new_sops}
    
    Logger.info("Registered SOP: #{sop.id} (version: #{version})")
    {:reply, :ok, new_state}
  end

  @impl GenServer
  def handle_call({:get, sop_id}, _from, state) do
    case Map.get(state.sops, sop_id) do
      nil -> 
        {:reply, {:error, :not_found}, state}
      %{sop: sop} -> 
        {:reply, {:ok, sop}, state}
    end
  end

  @impl GenServer
  def handle_call(:list_all, _from, state) do
    sops = 
      state.sops
      |> Map.values()
      |> Enum.map(& &1.sop)
    
    {:reply, sops, state}
  end

  @impl GenServer
  def handle_call(:stats, _from, state) do
    current_time = DateTime.utc_now()
    uptime_seconds = DateTime.diff(current_time, state.started_at)
    
    stats = %{
      total_sops: map_size(state.sops),
      builtin_sops: map_size(@hardcoded_sops),
      registry_name: state.name,
      started_at: state.started_at,
      current_time: current_time,
      uptime_seconds: uptime_seconds,
      uptime_human: format_uptime(uptime_seconds)
    }
    
    {:reply, stats, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unexpected message in SOP Registry: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private helpers

  defp get_system_timezone do
    # Try to get system timezone, fallback to UTC
    case System.cmd("date", ["+%Z"], stderr_to_stdout: true) do
      {timezone, 0} -> String.trim(timezone)
      _ -> "UTC"
    end
  rescue
    _ -> "UTC"
  end

  defp format_uptime(seconds) when seconds < 60, do: "#{seconds}s"
  defp format_uptime(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    remaining_seconds = rem(seconds, 60)
    "#{minutes}m #{remaining_seconds}s"
  end
  defp format_uptime(seconds) do
    hours = div(seconds, 3600)
    remaining_seconds = rem(seconds, 3600)
    minutes = div(remaining_seconds, 60)
    final_seconds = rem(remaining_seconds, 60)
    "#{hours}h #{minutes}m #{final_seconds}s"
  end
end