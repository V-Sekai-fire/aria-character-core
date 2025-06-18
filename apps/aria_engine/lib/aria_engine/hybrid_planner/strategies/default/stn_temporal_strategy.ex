# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy do
  @moduledoc """
  Default STN temporal strategy implementation wrapping existing temporal validation logic.
  
  This strategy encapsulates the current STN-based temporal reasoning functionality
  while providing the clean strategy interface defined in ADR-091. It serves as
  the default implementation for temporal constraint management.
  """

  @behaviour AriaEngine.HybridPlanner.Strategies.TemporalStrategy

  alias AriaEngine.{Plan, Domain}
  alias AriaEngine.TemporalPlanner.{STNPlanner, STNMethod, STNAction}
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
        _ -> STNPlanner.new()
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
          case STNPlanner.is_consistent?(stn) do
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
        _ -> STNPlanner.new()
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
          case STNPlanner.get_schedule(stn) do
            {:ok, schedule} ->
              if verbose > 1 do
                event_count = Map.size(schedule)
                Logger.debug("STNTemporalStrategy: Generated schedule with #{event_count} events")
              end
              {:ok, %{
                schedule: schedule,
                generated_at: System.system_time(:millisecond),
                stn_hash: :erlang.phash2(stn)
              }}
            
            {:error, reason} ->
              if verbose > 0 do
                Logger.warning("STNTemporalStrategy: Failed to generate schedule - #{reason}")
              end
              {:error, reason}
          end
        
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
  defp add_action_constraints(stn, {action_name, args}, current_time, opts) do
    try do
      # Create temporal events for action start and end
      start_event = "#{action_name}_start_#{:erlang.unique_integer([:positive])}"
      end_event = "#{action_name}_end_#{:erlang.unique_integer([:positive])}"
      
      # Add events to STN
      stn_with_events = stn
        |> STNPlanner.add_event(start_event, current_time)
        |> STNPlanner.add_event(end_event, current_time + get_action_duration(action_name, args, opts))
      
      # Add ordering constraint (start before end)
      case STNPlanner.add_constraint(stn_with_events, start_event, end_event, {0, :infinity}) do
        {:ok, updated_stn} -> {:ok, updated_stn}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        {:error, "Failed to add constraints for action #{action_name}: #{Exception.message(e)}"}
    end
  end

  # Apply a modification to the STN
  defp apply_modification(stn, modification, _opts) do
    case modification do
      {:add_constraint, from_event, to_event, bounds} ->
        STNPlanner.add_constraint(stn, from_event, to_event, bounds)
      
      {:remove_constraint, from_event, to_event} ->
        STNPlanner.remove_constraint(stn, from_event, to_event)
      
      {:add_event, event_name, time} ->
        {:ok, STNPlanner.add_event(stn, event_name, time)}
      
      {:remove_event, event_name} ->
        STNPlanner.remove_event(stn, event_name)
      
      _ ->
        {:error, "Unknown modification type: #{inspect(modification)}"}
    end
  end

  # Get the expected duration of an action
  defp get_action_duration(action_name, _args, opts) do
    # Default duration mapping - this could be enhanced to query domain metadata
    default_duration = Keyword.get(opts, :default_action_duration, 1)
    
    # Simple duration mapping based on action name patterns
    case action_name do
      name when name in [:move, :go, :travel] -> 5
      name when name in [:pick_up, :drop, :place] -> 2
      name when name in [:wait, :delay] -> 10
      _ -> default_duration
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
      underlying_implementation: "AriaEngine.TemporalPlanner.STNPlanner"
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
