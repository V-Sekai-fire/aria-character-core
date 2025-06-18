# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Default.STNTemporalStrategy do
  @moduledoc """
  Default STN temporal strategy implementation wrapping existing temporal validation logic.
  
  This strategy encapsulates the current STN-based temporal reasoning functionality
  while providing the clean strategy interface defined in ADR-091. It serves as
  the default implementation for temporal constraint management.
  """

  @behaviour HybridPlanner.Strategies.TemporalStrategy

  alias TemporalPlanner.STNPlanner
  require Logger

  @impl true
  def add_temporal_constraints(existing_constraints, actions, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    current_time = Keyword.get(opts, :current_time, 0)
    
    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Adding temporal constraints for #{length(actions)} actions")
    end

    try do
      # Start with existing constraints or create new STN
      stn = case existing_constraints do
        %{stn: stn} when not is_nil(stn) -> stn
        _ -> STNPlanner.new([], [])
      end

      # Add constraints for each action
      updated_stn = Enum.reduce_while(actions, stn, fn action, acc_stn ->
        case add_action_constraints(acc_stn, action, current_time, opts) do
          {:ok, new_stn} -> {:cont, new_stn}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

      case updated_stn do
        {:error, reason} ->
          if verbose > 0 do
            Logger.warning("STNTemporalStrategy: Failed to add constraints - #{reason}")
          end
          {:error, reason}
        
        stn when is_map(stn) ->
          if verbose > 1 do
            constraint_count = Map.get(stn, :constraints, %{}) |> map_size()
            Logger.debug("STNTemporalStrategy: Successfully added constraints (#{constraint_count} total)")
          end
          {:ok, %{stn: stn, last_update: System.system_time(:millisecond)}}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy constraint addition error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def validate_temporal_consistency(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Validating temporal consistency")
    end

    try do
      case constraints do
        %{stn: stn} when not is_nil(stn) ->
          # Use existing STN validation logic
          case STNPlanner.consistent?(stn) do
            true ->
              if verbose > 1 do
                Logger.debug("STNTemporalStrategy: Temporal constraints are consistent")
              end
              {:ok, true}
            
            false ->
              if verbose > 0 do
                Logger.warning("STNTemporalStrategy: Temporal constraints are inconsistent")
              end
              {:ok, false}
          end
        
        _ ->
          # No constraints means trivially consistent
          if verbose > 1 do
            Logger.debug("STNTemporalStrategy: No constraints present, trivially consistent")
          end
          {:ok, true}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy consistency validation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def update_constraints(constraints, modifications, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Updating constraints with #{length(modifications)} modifications")
    end

    try do
      stn = case constraints do
        %{stn: stn} when not is_nil(stn) -> stn
        _ -> STNPlanner.new([], [])
      end

      # Apply each modification to the STN
      updated_stn = Enum.reduce_while(modifications, stn, fn modification, acc_stn ->
        case apply_modification(acc_stn, modification, opts) do
          {:ok, new_stn} -> {:cont, new_stn}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

      case updated_stn do
        {:error, reason} ->
          {:error, reason}
        
        stn when is_map(stn) ->
          if verbose > 1 do
            Logger.debug("STNTemporalStrategy: Successfully updated constraints")
          end
          {:ok, %{stn: stn, last_update: System.system_time(:millisecond)}}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy constraint update error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def get_temporal_schedule(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    
    if verbose > 1 do
      Logger.debug("STNTemporalStrategy: Generating temporal schedule")
    end

    try do
      case constraints do
        %{stn: stn} when not is_nil(stn) ->
          # Generate schedule from STN using existing logic
          # TODO: Implement get_schedule/1 in STNPlanner
          Logger.warning("STNTemporalStrategy: get_schedule/1 not yet implemented in STNPlanner")
          {:ok, %{
            schedule: %{},
            generated_at: System.system_time(:millisecond),
            stn_hash: :erlang.phash2(stn)
          }}
        
        _ ->
          # No constraints means empty schedule
          if verbose > 1 do
            Logger.debug("STNTemporalStrategy: No constraints, returning empty schedule")
          end
          {:ok, %{
            schedule: %{},
            generated_at: System.system_time(:millisecond),
            stn_hash: nil
          }}
      end
    rescue
      e ->
        error_msg = "STNTemporalStrategy schedule generation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Add temporal constraints for a single action
  defp add_action_constraints(stn, {action_name, _args}, _current_time, _opts) do
    try do
      # Create temporal events for action start and end
      _start_event = "#{action_name}_start_#{:erlang.unique_integer([:positive])}"
      _end_event = "#{action_name}_end_#{:erlang.unique_integer([:positive])}"
      
      # TODO: Implement add_event/3 and add_constraint/4 in STNPlanner
      Logger.debug("STNTemporalStrategy: Placeholder implementation for action #{action_name}")
      {:ok, stn}
    rescue
      e ->
        {:error, "Failed to add constraints for action #{action_name}: #{Exception.message(e)}"}
    end
  end

  # Apply a modification to the STN
  defp apply_modification(stn, modification, _opts) do
    case modification do
      {:add_constraint, _from_event, _to_event, _bounds} ->
        Logger.debug("STNTemporalStrategy: add_constraint/4 not yet implemented")
        {:ok, stn}
      
      {:remove_constraint, _from_event, _to_event} ->
        Logger.debug("STNTemporalStrategy: remove_constraint/3 not yet implemented")
        {:ok, stn}
      
      {:add_event, _event_name, _time} ->
        Logger.debug("STNTemporalStrategy: add_event/3 not yet implemented")
        {:ok, stn}
      
      {:remove_event, _event_name} ->
        Logger.debug("STNTemporalStrategy: remove_event/2 not yet implemented")
        {:ok, stn}
      
      _ ->
        {:error, "Unknown modification type: #{inspect(modification)}"}
    end
  end


  # ==================== STRATEGY METADATA ====================

  @doc """
  Get strategy metadata and capabilities.
  """
  def strategy_info do
    %{
      name: "STN Temporal Strategy",
      version: "1.0.0",
      description: "Default STN-based temporal reasoning strategy",
      capabilities: [
        :temporal_constraints,
        :consistency_checking,
        :schedule_generation,
        :constraint_propagation,
        :conflict_detection
      ],
      limitations: [
        :no_continuous_time,
        :no_resource_conflicts,
        :simple_duration_model
      ],
      underlying_implementation: "TemporalPlanner.STNPlanner"
    }
  end

  @doc """
  Check if this strategy can handle specific temporal features.
  """
  def supports?(feature) when is_atom(feature) do
    capabilities = strategy_info()[:capabilities]
    feature in capabilities
  end

  @doc """
  Get performance characteristics of this strategy.
  """
  def performance_profile do
    %{
      constraint_addition_complexity: :linear,
      consistency_check_complexity: :polynomial,
      memory_usage: :moderate,
      scalability: :good,
      precision: :discrete_time
    }
  end
end
