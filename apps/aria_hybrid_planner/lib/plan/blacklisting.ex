# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Blacklisting do
  @moduledoc """
  IPyHOP-aligned blacklisting for planning and execution failures.

  This module implements blacklisting following the IPyHOP pattern:
  - Method blacklisting for planning failures (at planning level)
  - Command blacklisting for execution failures (at planner level)
  - Clear separation between planning-time and execution-time concerns

  Based on IPyHOP's blacklisting approach from thirdparty/IPyHOP/ipyhop/planner.py
  """

  alias AriaEngine.State

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.State.fact_value()}
  @type todo_item :: task() | goal() | AriaEngine.Multigoal.t()
  @type plan_step :: {atom() | String.t(), list()}
  @type command :: plan_step()
  @type method_name :: String.t()
  @type node_id :: String.t()

  @type blacklist_state :: %{
    # Planning-level blacklisting (methods that failed during planning)
    blacklisted_methods: MapSet.t(method_name()),
    # Execution-level blacklisting (commands that failed during execution)
    blacklisted_commands: MapSet.t(command()),
    # Metadata for debugging and tracking
    metadata: %{
      created_at: integer(),
      last_updated: integer(),
      planning_failures: integer(),
      execution_failures: integer()
    }
  }

  @doc """
  Create a new blacklist state following IPyHOP pattern.

  Returns an empty blacklist state with separate tracking for:
  - Methods (planning-level failures)
  - Commands (execution-level failures)
  """
  @spec new() :: blacklist_state()
  def new() do
    current_time = System.system_time(:millisecond)

    %{
      blacklisted_methods: MapSet.new(),
      blacklisted_commands: MapSet.new(),
      metadata: %{
        created_at: current_time,
        last_updated: current_time,
        planning_failures: 0,
        execution_failures: 0
      }
    }
  end

  @doc """
  Blacklist a method that failed during planning.

  This follows the IPyHOP pattern where methods that fail during planning
  are blacklisted to prevent infinite loops during backtracking.

  ## Parameters

  - `blacklist_state`: Current blacklist state
  - `method_name`: Name of the method that failed

  ## Returns

  Updated blacklist state with the method added to blacklisted_methods
  """
  @spec blacklist_method(blacklist_state(), method_name()) :: blacklist_state()
  def blacklist_method(blacklist_state, method_name) when is_binary(method_name) do
    %{
      blacklist_state
      | blacklisted_methods: MapSet.put(blacklist_state.blacklisted_methods, method_name),
        metadata: %{
          blacklist_state.metadata
          | last_updated: System.system_time(:millisecond),
            planning_failures: blacklist_state.metadata.planning_failures + 1
        }
    }
  end

  @doc """
  Blacklist a command that failed during execution.

  This follows the IPyHOP pattern where commands that fail during execution
  are blacklisted at the planner level to prevent replanning with the same
  failing commands.

  ## Parameters

  - `blacklist_state`: Current blacklist state
  - `command`: The command tuple that failed during execution

  ## Returns

  Updated blacklist state with the command added to blacklisted_commands
  """
  @spec blacklist_command(blacklist_state(), command()) :: blacklist_state()
  def blacklist_command(blacklist_state, command) when is_tuple(command) do
    %{
      blacklist_state
      | blacklisted_commands: MapSet.put(blacklist_state.blacklisted_commands, command),
        metadata: %{
          blacklist_state.metadata
          | last_updated: System.system_time(:millisecond),
            execution_failures: blacklist_state.metadata.execution_failures + 1
        }
    }
  end

  @doc """
  Check if a method is blacklisted for planning.

  ## Parameters

  - `blacklist_state`: Current blacklist state
  - `method_name`: Name of the method to check

  ## Returns

  `true` if the method is blacklisted, `false` otherwise
  """
  @spec method_blacklisted?(blacklist_state(), method_name()) :: boolean()
  def method_blacklisted?(blacklist_state, method_name) when is_binary(method_name) do
    MapSet.member?(blacklist_state.blacklisted_methods, method_name)
  end

  @doc """
  Check if a command is blacklisted for execution.

  This follows the IPyHOP pattern where blacklisted commands should
  fail immediately during planning to prevent replanning with known
  failing commands.

  ## Parameters

  - `blacklist_state`: Current blacklist state
  - `command`: The command tuple to check

  ## Returns

  `true` if the command is blacklisted, `false` otherwise
  """
  @spec command_blacklisted?(blacklist_state(), command()) :: boolean()
  def command_blacklisted?(blacklist_state, command) when is_tuple(command) do
    MapSet.member?(blacklist_state.blacklisted_commands, command)
  end

  @doc """
  Get all blacklisted methods.

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  MapSet of blacklisted method names
  """
  @spec get_blacklisted_methods(blacklist_state()) :: MapSet.t(method_name())
  def get_blacklisted_methods(blacklist_state) do
    blacklist_state.blacklisted_methods
  end

  @doc """
  Get all blacklisted commands.

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  MapSet of blacklisted command tuples
  """
  @spec get_blacklisted_commands(blacklist_state()) :: MapSet.t(command())
  def get_blacklisted_commands(blacklist_state) do
    blacklist_state.blacklisted_commands
  end

  @doc """
  Clear all blacklisted methods (planning-level).

  This is useful when starting a new planning session or when
  the domain has changed significantly.

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  Updated blacklist state with methods cleared
  """
  @spec clear_methods(blacklist_state()) :: blacklist_state()
  def clear_methods(blacklist_state) do
    %{
      blacklist_state
      | blacklisted_methods: MapSet.new(),
        metadata: %{
          blacklist_state.metadata
          | last_updated: System.system_time(:millisecond)
        }
    }
  end

  @doc """
  Clear all blacklisted commands (execution-level).

  This is useful when the execution environment has changed
  or when retrying execution with different conditions.

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  Updated blacklist state with commands cleared
  """
  @spec clear_commands(blacklist_state()) :: blacklist_state()
  def clear_commands(blacklist_state) do
    %{
      blacklist_state
      | blacklisted_commands: MapSet.new(),
        metadata: %{
          blacklist_state.metadata
          | last_updated: System.system_time(:millisecond)
        }
    }
  end

  @doc """
  Clear all blacklists (both methods and commands).

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  Fresh blacklist state with all blacklists cleared
  """
  @spec clear_all(blacklist_state()) :: blacklist_state()
  def clear_all(blacklist_state) do
    %{
      blacklist_state
      | blacklisted_methods: MapSet.new(),
        blacklisted_commands: MapSet.new(),
        metadata: %{
          blacklist_state.metadata
          | last_updated: System.system_time(:millisecond)
        }
    }
  end

  @doc """
  Get blacklist statistics for debugging and monitoring.

  ## Parameters

  - `blacklist_state`: Current blacklist state

  ## Returns

  Map containing blacklist statistics
  """
  @spec get_statistics(blacklist_state()) :: map()
  def get_statistics(blacklist_state) do
    %{
      methods_blacklisted: MapSet.size(blacklist_state.blacklisted_methods),
      commands_blacklisted: MapSet.size(blacklist_state.blacklisted_commands),
      total_planning_failures: blacklist_state.metadata.planning_failures,
      total_execution_failures: blacklist_state.metadata.execution_failures,
      created_at: blacklist_state.metadata.created_at,
      last_updated: blacklist_state.metadata.last_updated
    }
  end

  # Legacy compatibility functions for existing solution tree format
  # These will be deprecated once the migration is complete

  @doc """
  Legacy function for backward compatibility with solution tree blacklisting.

  This function extracts command blacklisting from the old solution tree format
  and converts it to the new blacklist state format.

  ## Parameters

  - `solution_tree`: Legacy solution tree with blacklisted_commands field

  ## Returns

  New blacklist state with commands migrated from solution tree
  """
  @spec from_solution_tree(map()) :: blacklist_state()
  def from_solution_tree(solution_tree) when is_map(solution_tree) do
    blacklist_state = new()

    case Map.get(solution_tree, :blacklisted_commands) do
      %MapSet{} = commands ->
        %{blacklist_state | blacklisted_commands: commands}

      nil ->
        blacklist_state

      _other ->
        # Handle other formats if needed
        blacklist_state
    end
  end

  @doc """
  Legacy function to update solution tree with blacklist state.

  This function updates the old solution tree format with blacklisted commands
  from the new blacklist state format for backward compatibility.

  ## Parameters

  - `solution_tree`: Legacy solution tree to update
  - `blacklist_state`: Current blacklist state

  ## Returns

  Updated solution tree with blacklisted_commands field
  """
  @spec to_solution_tree(map(), blacklist_state()) :: map()
  def to_solution_tree(solution_tree, blacklist_state) when is_map(solution_tree) do
    Map.put(solution_tree, :blacklisted_commands, blacklist_state.blacklisted_commands)
  end
end
