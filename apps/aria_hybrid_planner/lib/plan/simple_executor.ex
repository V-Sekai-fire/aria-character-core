# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.SimpleExecutor do
  @moduledoc """
  Simple IPyHOP-style executor following the MonteCarloExecutor pattern.

  This executor implements the IPyHOP execution pattern:
  - Linear execution through plan steps
  - Fail-fast on action failures
  - Return execution trace for debugging
  - No internal backtracking or replanning

  Based on IPyHOP's MonteCarloExecutor from thirdparty/IPyHOP/ipyhop/mc_executor.py
  """

  require Logger
  alias AriaEngineCore.State, as: State
  alias AriaEngineCore.Domain
  alias Timex

  @type plan_step :: {atom() | String.t(), list()}
  @type execution_trace_entry :: {plan_step() | nil, State.t() | nil}
  @type execution_trace :: [execution_trace_entry()]
  @type execution_result :: {:ok, State.t(), execution_trace()} | {:error, String.t(), execution_trace()}

  @doc """
  Execute a plan using simple linear execution with fail-fast behavior.

  This follows the IPyHOP MonteCarloExecutor pattern:
  1. Start with initial state in execution trace
  2. Execute each action in sequence
  3. Check for blacklisted commands (IPyHOP pattern)
  4. If action succeeds, add result to trace and continue
  5. If action fails, add failure to trace and return immediately
  6. Return final state and complete execution trace

  ## Parameters

  - `domain`: The domain containing action definitions
  - `initial_state`: Starting state for execution
  - `plan`: List of plan steps to execute
  - `opts`: Execution options (verbose, blacklist_state, etc.)

  ## Options

  - `:verbose` - Verbosity level (0-3)
  - `:blacklist_state` - Current blacklist state for command checking

  ## Returns

  - `{:ok, final_state, execution_trace}` on successful completion
  - `{:error, reason, execution_trace}` on failure (with trace up to failure point)

  """
  @spec execute(Domain.Core.t(), State.t(), [plan_step()], keyword()) :: execution_result()
  def execute(domain, initial_state, plan, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("SimpleExecutor: Starting execution of #{length(plan)} actions")
    end

    # Initialize execution trace with initial state (following IPyHOP pattern)
    initial_trace = [{nil, initial_state}]

    # Execute plan steps linearly with blacklist checking
    execute_steps(domain, initial_state, plan, initial_trace, opts)
  end

  @doc """
  Extract primitive actions from a solution tree for execution.

  This is a utility function to convert solution trees to the simple
  plan format expected by the executor.
  """
  @spec extract_primitive_actions(map()) :: [plan_step()]
  def extract_primitive_actions(solution_tree) do
    Plan.Utils.get_primitive_actions_dfs(solution_tree)
  end

  # Private implementation functions

  @spec execute_steps(Domain.Core.t(), State.t(), [plan_step()], execution_trace(), keyword()) :: execution_result()
  defp execute_steps(_domain, current_state, [], execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("SimpleExecutor: Execution completed successfully")
    end

    {:ok, current_state, Enum.reverse(execution_trace)}
  end

  defp execute_steps(domain, current_state, [action | remaining_actions], execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    {action_name, args} = action

    # Convert action name to atom if needed
    action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

    if verbose > 2 do
      Logger.debug("SimpleExecutor: Executing action #{action_name}(#{inspect(args)})")
    end

    # Check if command is blacklisted (IPyHOP pattern)
    case check_command_blacklist(action, opts) do
      :ok ->
        # Command not blacklisted, proceed with execution
        execute_non_blacklisted_command(domain, current_state, action, action_atom, args, remaining_actions, execution_trace, opts)

      {:blacklisted, reason} ->
        # Command is blacklisted - fail immediately (IPyHOP pattern)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Command #{action_name} is blacklisted: #{reason}")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Command blacklisted: #{action_name} - #{reason}"
        {:error, error_message, Enum.reverse(failure_trace)}
    end
  end

  # Execute a command that is not blacklisted
  defp execute_non_blacklisted_command(domain, current_state, action, action_atom, args, remaining_actions, execution_trace, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    {action_name, _args} = action

    # Execute the action using domain's command execution
    case execute_action_command(domain, current_state, action_atom, args, opts) do
      {:ok, new_state} ->
        # Action succeeded - add to trace and continue
        new_trace = [{action, new_state} | execution_trace]
        execute_steps(domain, new_state, remaining_actions, new_trace, opts)

      {:error, reason} ->
        # Action failed - add failure to trace and return immediately (fail-fast)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Action #{action_name} failed: #{reason}")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Action execution failed: #{action_name} - #{reason}"
        {:error, error_message, Enum.reverse(failure_trace)}

      false ->
        # Action returned false (IPyHOP-style failure)
        if verbose > 1 do
          Logger.debug("SimpleExecutor: Action #{action_name} returned false")
        end

        failure_trace = [{action, nil} | execution_trace]
        error_message = "Action execution failed: #{action_name} - returned false"
        {:error, error_message, Enum.reverse(failure_trace)}
    end
  end

  # Check if a command is blacklisted following IPyHOP pattern
  defp check_command_blacklist(command, opts) do
    case Keyword.get(opts, :blacklist_state) do
      nil ->
        # No blacklist state provided, allow execution
        :ok

      blacklist_state ->
        # Check if command is blacklisted
        if Plan.Blacklisting.command_blacklisted?(blacklist_state, command) do
          {:blacklisted, "command previously failed during execution"}
        else
          :ok
        end
    end
  end

  @spec execute_action_command(Domain.Core.t(), State.t(), atom(), list(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_action_command(domain, state, action_atom, args, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Step 1: Validate entity requirements (ADR-181 compliance)
    case validate_entity_requirements(domain, state, action_atom, args, opts) do
      :ok ->
        # Get action metadata to determine method type
        metadata = get_action_metadata(domain, action_atom)
        method_type = get_method_type_from_metadata(metadata)

        # Step 2: Validate temporal constraints
        case validate_temporal_constraints(metadata, opts) do
          :ok ->
            if verbose > 2 do
              Logger.debug("SimpleExecutor: Dispatching execution for #{action_atom} as #{method_type}")
            end

            # Dispatch based on method type
            dispatch_method_execution(domain, state, action_atom, args, method_type, metadata, opts)

          {:error, reason} ->
            {:error, "Temporal validation failed: #{reason}"}
        end

      {:error, reason} ->
        # Entity validation failed
        {:error, "Entity validation failed: #{reason}"}
    end
  end

  # Dispatches execution based on the method type
  @spec dispatch_method_execution(Domain.Core.t(), State.t(), atom(), list(), atom(), map(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp dispatch_method_execution(domain, state, action_atom, args, method_type, metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    case method_type do
      :action ->
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as action: #{action_atom}")
        end
        Domain.execute_action(domain, state, action_atom, args)

      :command ->
        command_name = String.to_atom("#{action_atom}_command")
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as command: #{command_name}")
        end
        Domain.execute_action(domain, state, command_name, args)

      :task_method ->
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as task method: #{action_atom}")
        end
        execute_task_method(domain, state, action_atom, args, metadata, opts)

      :unigoal_method ->
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as unigoal method: #{action_atom}")
        end
        execute_unigoal_method(domain, state, action_atom, args, metadata, opts)

      :multigoal_method ->
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as multigoal method: #{action_atom}")
        end
        execute_multigoal_method(domain, state, action_atom, args, metadata, opts)

      :multitodo_method ->
        if verbose > 2 do
          Logger.debug("SimpleExecutor: Executing as multitodo method: #{action_atom}")
        end
        execute_multitodo_method(domain, state, action_atom, args, metadata, opts)

      _ ->
        {:error, "Unsupported method type: #{inspect(method_type)} for action: #{action_atom}"}
    end
  end

  # Determines the method type from action metadata
  @spec get_method_type_from_metadata(map()) :: atom()
  defp get_method_type_from_metadata(metadata) do
    cond do
      Map.get(metadata, :action) -> :action
      Map.get(metadata, :command) -> :command
      Map.get(metadata, :task_method) -> :task_method
      Map.get(metadata, :unigoal_method) -> :unigoal_method
      Map.get(metadata, :multigoal_method) -> :multigoal_method
      Map.get(metadata, :multitodo_method) -> :multitodo_method
      true -> :unknown # Default or error case
    end
  end

  # Validate entity requirements for an action according to ADR-181
  @spec validate_entity_requirements(Domain.Core.t(), State.t(), atom(), list(), keyword()) ::
    :ok | {:error, String.t()}
  defp validate_entity_requirements(domain, state, action_atom, _args, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Get action metadata from domain
    metadata = get_action_metadata(domain, action_atom)

    # Extract required entities from metadata
    required_entities = Map.get(metadata, :requires_entities, [])

    # Get entity registry from domain
    entity_registry = Domain.get_entity_registry(domain)

    if verbose > 2 do
      Logger.debug("SimpleExecutor: Validating entity requirements for #{action_atom}: #{inspect(required_entities)}")
    end

    # Validate required entities using the entity registry
    validate_required_entities(state, entity_registry, required_entities, opts)
  end

  # Get action metadata from domain
  @spec get_action_metadata(Domain.Core.t(), atom()) :: map()
  defp get_action_metadata(domain, action_atom) do
    AriaEngineCore.Domain.get_action_metadata(domain, Atom.to_string(action_atom))
  end

  # Validate that required entities are available and have necessary capabilities
  @spec validate_required_entities(State.t(), map(), list(), keyword()) :: :ok | {:error, String.t()}
  defp validate_required_entities(_state, _entity_registry, [], _opts) do
    # No entity requirements, validation passes
    :ok
  end

  defp validate_required_entities(state, entity_registry, entity_requirements, opts) do
    verbose = Keyword.get(opts, :verbose, 0)

    # Validate each entity requirement
    Enum.reduce_while(entity_requirements, :ok, fn requirement, _acc ->
      case validate_single_entity_requirement(state, entity_registry, requirement, opts) do
        :ok ->
          {:cont, :ok}
        {:error, reason} ->
          if verbose > 1 do
            Logger.debug("SimpleExecutor: Entity validation failed: #{reason}")
          end
          {:halt, {:error, reason}}
      end
    end)
  end

  # Validate a single entity requirement
  @spec validate_single_entity_requirement(State.t(), map(), map(), keyword()) :: :ok | {:error, String.t()}
  defp validate_single_entity_requirement(state, entity_registry, requirement, _opts) do
    entity_type = requirement[:type]
    required_capabilities = requirement[:capabilities] || []

    # Validate entity type against registry
    unless Map.has_key?(entity_registry, entity_type) do
      {:error, "Unknown entity type: #{entity_type}"}
    end

    # Get registered capabilities for this entity type
    registered_capabilities = Map.get(entity_registry, entity_type, %{})[:capabilities] || []

    # Validate that all required capabilities are registered for this entity type
    unless Enum.all?(required_capabilities, fn cap -> cap in registered_capabilities end) do
      {:error, "Entity type #{entity_type} does not support all required capabilities: #{inspect(required_capabilities)}"}
    end

    case find_available_entity(state, entity_type, required_capabilities) do
      {:ok, _entity_id} ->
        :ok
      {:error, reason} ->
        {:error, "No available #{entity_type} with capabilities #{inspect(required_capabilities)}: #{reason}"}
    end
  end

  # Find an available entity of the specified type with required capabilities
  @spec find_available_entity(State.t(), String.t(), list()) :: {:ok, String.t()} | {:error, String.t()}
  defp find_available_entity(state, entity_type, required_capabilities) do
    # Get all entities of the specified type
    entities_of_type = get_entities_by_type(state, entity_type)

    # Find first available entity with required capabilities
    case Enum.find(entities_of_type, fn entity_id ->
      entity_available?(state, entity_id) and entity_has_capabilities?(state, entity_id, required_capabilities)
    end) do
      nil ->
        {:error, "no_suitable_entity_found"}
      entity_id ->
        {:ok, entity_id}
    end
  end

  # Get all entities of a specific type from state
  @spec get_entities_by_type(State.t(), String.t()) :: [String.t()]
  defp get_entities_by_type(state, entity_type) do
    # Retrieve all entities of the specified type from the state
    # Assuming entities are stored as facts like: {"type", entity_id, entity_type}
    # We need to query for all subjects where predicate is "type" and value is entity_type
    State.get_subjects_with_fact(state, "type", entity_type)
  end

  # Check if an entity is available (not busy)
  @spec entity_available?(State.t(), String.t()) :: boolean()
  def entity_available?(state, entity_id) do
    State.has_subject?(state, "status", entity_id) and State.get_fact(state, "status", entity_id) == "available"
  end

  # Check if an entity has all required capabilities
  @spec entity_has_capabilities?(State.t(), String.t(), list()) :: boolean()
  defp entity_has_capabilities?(state, entity_id, required_capabilities) do
    case State.get_fact(state, "capabilities", entity_id) do
      entity_capabilities when is_list(entity_capabilities) ->
        Enum.all?(required_capabilities, fn capability ->
          capability in entity_capabilities
        end)
      _ ->
        false
    end
  end

  # Validates temporal constraints based on action metadata
  @spec validate_temporal_constraints(map(), keyword()) :: :ok | {:error, String.t()}
  defp validate_temporal_constraints(metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    start_time = Map.get(metadata, :start)
    end_time = Map.get(metadata, :end)
    duration = Map.get(metadata, :duration)

    if verbose > 2 do
      Logger.debug("SimpleExecutor: Validating temporal constraints: start=#{inspect(start_time)}, end=#{inspect(end_time)}, duration=#{inspect(duration)}")
    end

    # Pattern 1: Instant action, anytime (no temporal attributes)
    if is_nil(start_time) and is_nil(end_time) and is_nil(duration) do
      :ok
    end

    parsed_start = if start_time, do: parse_datetime(start_time), else: nil
    parsed_end = if end_time, do: parse_datetime(end_time), else: nil
    parsed_duration = if duration, do: parse_duration(duration), else: nil

    # Validate ISO 8601 parsing
    if (start_time and is_nil(parsed_start)) or
       (end_time and is_nil(parsed_end)) or
       (duration and is_nil(parsed_duration)) do
      {:error, "Invalid ISO 8601 format for temporal attributes"}
    end

    # Pattern 2: Floating duration
    if is_nil(start_time) and is_nil(end_time) and parsed_duration do
      :ok
    end

    # Pattern 3: Deadline constraint (start=nil, end=present, duration=nil)
    if is_nil(start_time) and parsed_end and is_nil(duration) do
      :ok
    end

    # Pattern 4: Calculated start (start=nil, end=present, duration=present)
    if is_nil(start_time) and parsed_end and parsed_duration do
      calculated_start = Timex.shift(parsed_end, days: -parsed_duration.days, hours: -parsed_duration.hours, minutes: -parsed_duration.minutes, seconds: -parsed_duration.seconds)
      if verbose > 2 do
        Logger.debug("SimpleExecutor: Pattern 4 - Calculated start: #{inspect(calculated_start)}")
      end
      :ok
    end

    # Pattern 5: Open start (start=present, end=nil, duration=nil)
    if parsed_start and is_nil(end_time) and is_nil(duration) do
      :ok
    end

    # Pattern 6: Calculated end (start=present, end=nil, duration=present)
    if parsed_start and is_nil(end_time) and parsed_duration do
      calculated_end = Timex.shift(parsed_start, days: parsed_duration.days, hours: parsed_duration.hours, minutes: parsed_duration.minutes, seconds: parsed_duration.seconds)
      if verbose > 2 do
        Logger.debug("SimpleExecutor: Pattern 6 - Calculated end: #{inspect(calculated_end)}")
      end
      :ok
    end

    # Pattern 7: Fixed interval (start=present, end=present, duration=nil)
    if parsed_start and parsed_end and is_nil(duration) do
      if Timex.compare(parsed_start, parsed_end) == 1 do # start > end
        {:error, "Fixed interval: start time cannot be after end time"}
      else
        :ok
      end
    end

    # Pattern 8: Constraint validation (start=present, end=present, duration=present)
    if parsed_start and parsed_end and parsed_duration do
      calculated_end = Timex.shift(parsed_start, days: parsed_duration.days, hours: parsed_duration.hours, minutes: parsed_duration.minutes, seconds: parsed_duration.seconds)
      if Timex.compare(calculated_end, parsed_end) != 0 do
        {:error, "Constraint validation: start + duration != end"}
      else
        :ok
      end
    end

    {:error, "Unsupported temporal pattern"}
  end

  # Parses an ISO 8601 datetime string
  @spec parse_datetime(String.t()) :: Timex.DateTime.t() | nil
  defp parse_datetime(datetime_str) do
    case Timex.parse(datetime_str, "{ISO:Extended:Z}") do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end

  # Parses an ISO 8601 duration string (e.g., "PT2H", "P1D")
  @spec parse_duration(String.t()) :: map() | nil
  defp parse_duration(duration_str) do
    # Timex.Duration.parse/1 is not directly available for ISO 8601 durations.
    # We'll implement a simplified parser for common patterns.
    # This is a basic implementation and might need to be expanded for full ISO 8601 duration support.
    cond do
      duration_str =~ ~r/^PT(\d+)H$/ ->
        hours = String.to_integer(Regex.run(~r/^PT(\d+)H$/, duration_str)[1])
        %{days: 0, hours: hours, minutes: 0, seconds: 0}
      duration_str =~ ~r/^P(\d+)D$/ ->
        days = String.to_integer(Regex.run(~r/^P(\d+)D$/, duration_str)[1])
        %{days: days, hours: 0, minutes: 0, seconds: 0}
      duration_str =~ ~r/^PT(\d+)M$/ ->
        minutes = String.to_integer(Regex.run(~r/^PT(\d+)M$/, duration_str)[1])
        %{days: 0, hours: 0, minutes: minutes, seconds: 0}
      duration_str =~ ~r/^PT(\d+)S$/ ->
        seconds = String.to_integer(Regex.run(~r/^PT(\d+)S$/, duration_str)[1])
        %{days: 0, hours: 0, minutes: 0, seconds: seconds}
      true ->
        nil
    end
  end

  # Executes a task method
  @spec execute_task_method(Domain.Core.t(), State.t(), atom(), list(), map(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_task_method(domain, state, task_atom, args, _metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    case Domain.get_task_methods(domain, task_atom) do
      [] ->
        {:error, "Task method #{task_atom} not found"}
      methods ->
        # For simplicity, just execute the first method found.
        # In a real planner, this would involve more complex method selection.
        {_method_name, method_fn} = List.first(methods)
        case apply(method_fn, [state, args]) do
          {:ok, todo_items} when is_list(todo_items) ->
            # For now, we just return the original state.
            # In a full implementation, these todo_items would be processed by the planner.
            if verbose > 1 do
              Logger.debug("SimpleExecutor: Task method #{task_atom} returned todo items: #{inspect(todo_items)}")
            end
            {:ok, state}
          {:error, reason} ->
            {:error, "Task method #{task_atom} failed: #{reason}"}
          other ->
            {:error, "Unexpected task method result: #{inspect(other)}"}
        end
    end
  end

  # Executes a unigoal method
  @spec execute_unigoal_method(Domain.Core.t(), State.t(), atom(), list(), map(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_unigoal_method(domain, state, unigoal_atom, args, metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    predicate = Map.get(metadata, :predicate)
    if is_nil(predicate) do
      {:error, "Unigoal method #{unigoal_atom} missing predicate in metadata"}
    end

    # Assuming args is in the format [subject, value] for unigoal
    case args do
      [subject, value] ->
        case Domain.get_unigoal_methods(domain, predicate) do
          [] ->
            {:error, "Unigoal method for predicate #{predicate} not found"}
          methods ->
            # For simplicity, just execute the first method found.
            {_method_name, method_fn} = List.first(methods)
            case apply(method_fn, [state, {subject, value}]) do
              {:ok, todo_items} when is_list(todo_items) ->
                if verbose > 1 do
                  Logger.debug("SimpleExecutor: Unigoal method #{unigoal_atom} returned todo items: #{inspect(todo_items)}")
                end
                {:ok, state}
              {:error, reason} ->
                {:error, "Unigoal method #{unigoal_atom} failed: #{reason}"}
              other ->
                {:error, "Unexpected unigoal method result: #{inspect(other)}"}
            end
        end
      _ ->
        {:error, "Unigoal method #{unigoal_atom} expects args in [subject, value] format"}
    end
  end

  # Executes a multigoal method
  @spec execute_multigoal_method(Domain.Core.t(), State.t(), atom(), list(), map(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_multigoal_method(domain, state, multigoal_atom, args, _metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    case Domain.get_multigoal_methods(domain) do
      [] ->
        {:error, "Multigoal method #{multigoal_atom} not found"}
      methods ->
        # Assuming args is a single multigoal struct
        case args do
          [multigoal_struct] ->
            {_method_name, method_fn} = List.first(methods)
            case apply(method_fn, [state, multigoal_struct]) do
              {:ok, _updated_multigoal} ->
                if verbose > 1 do
                  Logger.debug("SimpleExecutor: Multigoal method #{multigoal_atom} executed successfully.")
                end
                {:ok, state}
              {:error, reason} ->
                {:error, "Multigoal method #{multigoal_atom} failed: #{reason}"}
              other ->
                {:error, "Unexpected multigoal method result: #{inspect(other)}"}
            end
          _ ->
            {:error, "Multigoal method #{multigoal_atom} expects a single multigoal struct as argument"}
        end
    end
  end

  # Executes a multitodo method
  @spec execute_multitodo_method(Domain.Core.t(), State.t(), atom(), list(), map(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()} | false
  defp execute_multitodo_method(domain, state, multitodo_atom, args, _metadata, opts) do
    verbose = Keyword.get(opts, :verbose, 0)
    case Domain.get_multitodo_methods(domain) do
      [] ->
        {:error, "Multitodo method #{multitodo_atom} not found"}
      methods ->
        # Assuming args is a list of todo_items
        case args do
          [todo_items] when is_list(todo_items) ->
            {_method_name, method_fn} = List.first(methods)
            case apply(method_fn, [state, todo_items]) do
              {:ok, _updated_todo_items} ->
                if verbose > 1 do
                  Logger.debug("SimpleExecutor: Multitodo method #{multitodo_atom} executed successfully.")
                end
                {:ok, state}
              {:error, reason} ->
                {:error, "Multitodo method #{multitodo_atom} failed: #{reason}"}
              other ->
                {:error, "Unexpected multitodo method result: #{inspect(other)}"}
            end
          _ ->
            {:error, "Multitodo method #{multitodo_atom} expects a list of todo_items as argument"}
        end
    end
  end
end
