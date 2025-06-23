# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.Strategies.Default.STNBridgeTemporalStrategy do
  @moduledoc """
  Bridge-enabled STN temporal strategy implementation.

  This strategy extends the standard STN temporal strategy with automatic bridge
  insertion and segmentation capabilities. It provides "always bridge" functionality
  where temporal planning automatically segments at logical decision points.

  ## Features

  - Automatic bridge insertion at action transitions
  - Bridge-based timeline segmentation
  - Configurable bridge insertion rules
  - Integration with Timeline bridge system
  - Backward compatibility with standard STN strategy

  ## Usage

      # Configure strategy factory with bridge-enabled strategy
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:temporal_strategy, :stn_bridge, 
           STNBridgeTemporalStrategy)
      
      # Create coordinator with always-bridge configuration
      config = %{
        temporal_strategy: :stn_bridge,
        # ... other strategies
      }
      
      coordinator = StrategyFactory.create_coordinator(factory, config)
  """

  @behaviour HybridPlanner.Strategies.TemporalStrategy

  alias HybridPlanner.Strategies.Default.STNTemporalStrategy
  alias AriaEngine.Timeline

  require Logger

  @impl true
  def add_temporal_constraints(existing_constraints, actions, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)
    bridge_mode = Keyword.get(opts, :bridge_mode, :auto)

    if verbose > 1 do
      Logger.debug(
        "STNBridgeTemporalStrategy: Adding temporal constraints with bridge mode: #{bridge_mode}"
      )
    end

    try do
      # First, use the standard STN strategy to add constraints
      case STNTemporalStrategy.add_temporal_constraints(existing_constraints, actions, opts) do
        {:ok, updated_constraints} ->
          # Then add bridge-based enhancements
          case add_bridge_constraints(updated_constraints, actions, opts) do
            {:ok, bridge_enhanced_constraints} ->
              if verbose > 1 do
                Logger.debug("STNBridgeTemporalStrategy: Successfully added bridge constraints")
              end

              {:ok, bridge_enhanced_constraints}

            {:error, reason} ->
              Logger.warning(
                "STNBridgeTemporalStrategy: Bridge constraint addition failed: #{reason}"
              )

              # Fall back to standard constraints if bridge enhancement fails
              {:ok, updated_constraints}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "STNBridgeTemporalStrategy constraint addition error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def validate_temporal_consistency(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("STNBridgeTemporalStrategy: Validating temporal consistency with bridges")
    end

    try do
      # Use standard STN validation but with bridge-aware enhancements
      case STNTemporalStrategy.validate_temporal_consistency(constraints, opts) do
        {:ok, is_consistent} ->
          # Additional bridge-specific consistency checks
          case validate_bridge_consistency(constraints, opts) do
            {:ok, bridge_consistent} ->
              final_consistency = is_consistent and bridge_consistent

              if verbose > 1 do
                Logger.debug(
                  "STNBridgeTemporalStrategy: Consistency check complete (STN: #{is_consistent}, Bridges: #{bridge_consistent})"
                )
              end

              {:ok, final_consistency}

            {:error, reason} ->
              {:error, "Bridge consistency validation failed: #{reason}"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg =
          "STNBridgeTemporalStrategy consistency validation error: #{Exception.message(e)}"

        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def update_constraints(constraints, modifications, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("STNBridgeTemporalStrategy: Updating constraints with bridge awareness")
    end

    try do
      # Use standard STN update with bridge-aware modifications
      bridge_aware_modifications = enhance_modifications_with_bridges(modifications, opts)

      case STNTemporalStrategy.update_constraints(constraints, bridge_aware_modifications, opts) do
        {:ok, updated_constraints} ->
          # Update bridge-specific data
          case update_bridge_constraints(updated_constraints, modifications, opts) do
            {:ok, bridge_updated_constraints} ->
              if verbose > 1 do
                Logger.debug("STNBridgeTemporalStrategy: Successfully updated bridge constraints")
              end

              {:ok, bridge_updated_constraints}

            {:error, reason} ->
              Logger.warning(
                "STNBridgeTemporalStrategy: Bridge constraint update failed: #{reason}"
              )

              # Fall back to standard update if bridge enhancement fails
              {:ok, updated_constraints}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "STNBridgeTemporalStrategy constraint update error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  @impl true
  def get_temporal_schedule(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    if verbose > 1 do
      Logger.debug("STNBridgeTemporalStrategy: Generating bridge-aware temporal schedule")
    end

    try do
      # Generate standard schedule first
      case STNTemporalStrategy.get_temporal_schedule(constraints, opts) do
        {:ok, schedule_result} ->
          # Enhance schedule with bridge information
          case enhance_schedule_with_bridges(schedule_result, constraints, opts) do
            {:ok, bridge_enhanced_schedule} ->
              if verbose > 1 do
                Logger.debug("STNBridgeTemporalStrategy: Generated bridge-enhanced schedule")
              end

              {:ok, bridge_enhanced_schedule}

            {:error, reason} ->
              Logger.warning(
                "STNBridgeTemporalStrategy: Bridge schedule enhancement failed: #{reason}"
              )

              # Fall back to standard schedule if bridge enhancement fails
              {:ok, schedule_result}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        error_msg = "STNBridgeTemporalStrategy schedule generation error: #{Exception.message(e)}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  # ==================== BRIDGE-SPECIFIC FUNCTIONS ====================

  @doc """
  Add bridge constraints to temporal problem.
  """
  def add_bridge_constraints(constraints, actions, opts \\ []) do
    bridge_mode = Keyword.get(opts, :bridge_mode, :auto)
    verbose = Keyword.get(opts, :verbose, 0)

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # Create timeline from actions for bridge analysis
          timeline = create_timeline_from_actions(actions)

          # Apply bridge insertion based on mode
          bridge_enhanced_timeline =
            case bridge_mode do
              :auto -> Timeline.auto_insert_bridges(timeline, get_bridge_insertion_rules(opts))
              :manual -> timeline
              :always -> Timeline.with_bridge_segmentation(timeline)
              _ -> timeline
            end

          # Extract bridge information and add to temporal problem
          bridges = Timeline.get_bridges(bridge_enhanced_timeline)
          bridge_constraints = convert_bridges_to_constraints(bridges, actions)

          updated_problem = %{
            problem
            | constraints: problem.constraints ++ bridge_constraints,
              bridges: bridges,
              timeline: bridge_enhanced_timeline
          }

          if verbose > 1 do
            Logger.debug(
              "STNBridgeTemporalStrategy: Added #{length(bridge_constraints)} bridge constraints"
            )
          end

          {:ok, %{constraints | temporal_problem: updated_problem}}

        _ ->
          # No existing problem, create new one with bridges
          timeline = create_timeline_from_actions(actions)

          bridge_enhanced_timeline =
            Timeline.auto_insert_bridges(timeline, get_bridge_insertion_rules(opts))

          bridges = Timeline.get_bridges(bridge_enhanced_timeline)
          bridge_constraints = convert_bridges_to_constraints(bridges, actions)

          new_problem = %{
            actions: actions,
            constraints: bridge_constraints,
            bridges: bridges,
            timeline: bridge_enhanced_timeline,
            current_time: Keyword.get(opts, :current_time, 0)
          }

          {:ok, %{temporal_problem: new_problem, last_update: System.system_time(:millisecond)}}
      end
    rescue
      e ->
        {:error, "Bridge constraint addition failed: #{Exception.message(e)}"}
    end
  end

  @doc """
  Validate bridge-specific consistency requirements.
  """
  def validate_bridge_consistency(constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    try do
      case constraints do
        %{temporal_problem: %{bridges: bridges, timeline: timeline}} when not is_nil(bridges) ->
          # Validate bridge placement consistency
          case Timeline.validate_all_bridge_placements(timeline) do
            :ok ->
              if verbose > 1 do
                Logger.debug("STNBridgeTemporalStrategy: Bridge placement validation passed")
              end

              {:ok, true}

            {:error, reason} ->
              if verbose > 0 do
                Logger.warning(
                  "STNBridgeTemporalStrategy: Bridge placement validation failed: #{reason}"
                )
              end

              {:ok, false}
          end

        _ ->
          # No bridges means trivially consistent
          if verbose > 1 do
            Logger.debug("STNBridgeTemporalStrategy: No bridges present, trivially consistent")
          end

          {:ok, true}
      end
    rescue
      e ->
        {:error, "Bridge consistency validation failed: #{Exception.message(e)}"}
    end
  end

  @doc """
  Update bridge constraints based on modifications.
  """
  def update_bridge_constraints(constraints, modifications, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    try do
      case constraints do
        %{temporal_problem: problem} when not is_nil(problem) ->
          # Apply bridge-aware modifications
          updated_problem =
            Enum.reduce(modifications, problem, fn modification, acc_problem ->
              apply_bridge_modification(acc_problem, modification, opts)
            end)

          if verbose > 1 do
            Logger.debug("STNBridgeTemporalStrategy: Successfully updated bridge constraints")
          end

          {:ok, %{constraints | temporal_problem: updated_problem}}

        _ ->
          # No existing problem, return as-is
          {:ok, constraints}
      end
    rescue
      e ->
        {:error, "Bridge constraint update failed: #{Exception.message(e)}"}
    end
  end

  @doc """
  Enhance schedule with bridge information.
  """
  def enhance_schedule_with_bridges(schedule_result, constraints, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, 0)

    try do
      case constraints do
        %{temporal_problem: %{bridges: bridges, timeline: timeline}} when not is_nil(bridges) ->
          # Add bridge information to schedule
          bridge_schedule = create_bridge_schedule(bridges, timeline)

          enhanced_schedule = %{
            schedule_result
            | bridge_schedule: bridge_schedule,
              segmentation_info: create_segmentation_info(timeline),
              bridge_count: length(bridges)
          }

          if verbose > 1 do
            Logger.debug(
              "STNBridgeTemporalStrategy: Enhanced schedule with #{length(bridges)} bridges"
            )
          end

          {:ok, enhanced_schedule}

        _ ->
          # No bridges, return original schedule
          {:ok, schedule_result}
      end
    rescue
      e ->
        {:error, "Bridge schedule enhancement failed: #{Exception.message(e)}"}
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Create timeline from actions for bridge analysis
  defp create_timeline_from_actions(actions) do
    timeline = Timeline.new()

    Enum.reduce(actions, timeline, fn {action_name, action_data}, acc_timeline ->
      # Convert action to interval
      start_time = Map.get(action_data, :start_time, 0)
      duration = Map.get(action_data, :duration, 1)
      end_time = start_time + duration

      interval = %{
        id: action_name,
        start_time: start_time,
        end_time: end_time,
        metadata: Map.get(action_data, :metadata, %{})
      }

      Timeline.add_interval(acc_timeline, interval)
    end)
  end

  # Get bridge insertion rules based on options
  defp get_bridge_insertion_rules(opts) do
    default_rules = [
      :action_type_transitions,
      :resource_changes,
      :phase_boundaries,
      :decision_points
    ]

    Keyword.get(opts, :bridge_insertion_rules, default_rules)
  end

  # Convert bridges to temporal constraints
  defp convert_bridges_to_constraints(bridges, actions) do
    action_names = Enum.map(actions, fn {name, _} -> name end)

    Enum.flat_map(bridges, fn bridge ->
      # Create constraints based on bridge type and position
      case bridge.type do
        :decision ->
          create_decision_constraints(bridge, action_names)

        :synchronization ->
          create_synchronization_constraints(bridge, action_names)

        :condition ->
          create_condition_constraints(bridge, action_names)

        :resource_check ->
          create_resource_constraints(bridge, action_names)

        _ ->
          []
      end
    end)
  end

  # Create decision point constraints
  defp create_decision_constraints(bridge, action_names) do
    # Find actions before and after bridge position
    before_actions = find_actions_before_position(action_names, bridge.position)
    after_actions = find_actions_after_position(action_names, bridge.position)

    # Create precedence constraints
    for before_action <- before_actions,
        after_action <- after_actions do
      {:before, before_action, after_action}
    end
  end

  # Create synchronization constraints
  defp create_synchronization_constraints(bridge, action_names) do
    # Find actions at bridge position for synchronization
    sync_actions = find_actions_at_position(action_names, bridge.position)

    # Create synchronization constraints between actions
    case sync_actions do
      [action1, action2 | _] ->
        [{:meets, action1, action2}]

      _ ->
        []
    end
  end

  # Create condition constraints
  defp create_condition_constraints(bridge, action_names) do
    # Similar to decision constraints but with conditional logic
    before_actions = find_actions_before_position(action_names, bridge.position)
    after_actions = find_actions_after_position(action_names, bridge.position)

    for before_action <- before_actions,
        after_action <- after_actions do
      {:conditional_before, before_action, after_action, bridge.metadata}
    end
  end

  # Create resource check constraints
  defp create_resource_constraints(bridge, action_names) do
    # Find actions that use resources around bridge position
    resource_actions = find_resource_actions_near_position(action_names, bridge.position)

    Enum.map(resource_actions, fn action ->
      {:resource_check, action, bridge.metadata}
    end)
  end

  # Helper functions for finding actions relative to bridge positions
  defp find_actions_before_position(action_names, position) do
    # Filter actions that occur before the bridge position
    # For now, use position as an index into the action list
    position_index = max(0, min(position, length(action_names) - 1))
    Enum.take(action_names, position_index)
  end

  defp find_actions_after_position(action_names, position) do
    # Filter actions that occur after the bridge position
    # For now, use position as an index into the action list
    position_index = max(0, min(position, length(action_names) - 1))
    Enum.drop(action_names, position_index + 1)
  end

  defp find_actions_at_position(action_names, _position) do
    # Simplified implementation - would find actions that overlap with bridge position
    Enum.take(action_names, 2)
  end

  defp find_resource_actions_near_position(action_names, _position) do
    # Simplified implementation - would find actions with resource requirements
    Enum.filter(action_names, fn _name -> :rand.uniform() > 0.5 end)
  end

  # Enhance modifications with bridge awareness
  defp enhance_modifications_with_bridges(modifications, _opts) do
    # Add bridge-specific modifications to standard modifications
    bridge_modifications = [
      {:update_bridge_metadata, System.system_time(:millisecond)}
    ]

    modifications ++ bridge_modifications
  end

  # Apply bridge-aware modification to problem
  defp apply_bridge_modification(problem, modification, _opts) do
    case modification do
      {:add_bridge, bridge} ->
        bridges = Map.get(problem, :bridges, [])
        timeline = Map.get(problem, :timeline, Timeline.new())
        updated_timeline = Timeline.add_bridge(timeline, bridge)

        %{problem | bridges: [bridge | bridges], timeline: updated_timeline}

      {:remove_bridge, bridge_id} ->
        bridges = Map.get(problem, :bridges, [])
        timeline = Map.get(problem, :timeline, Timeline.new())
        updated_bridges = Enum.reject(bridges, fn bridge -> bridge.id == bridge_id end)
        updated_timeline = Timeline.remove_bridge(timeline, bridge_id)

        %{problem | bridges: updated_bridges, timeline: updated_timeline}

      {:update_bridge_metadata, _timestamp} ->
        # Update bridge metadata timestamp
        Map.put(problem, :bridge_last_update, System.system_time(:millisecond))

      _ ->
        # Pass through non-bridge modifications
        problem
    end
  end

  # Create bridge schedule information
  defp create_bridge_schedule(bridges, timeline) do
    segments = Timeline.segment_by_bridges(timeline)

    %{
      bridges: bridges,
      segments: segments,
      segment_count: length(segments),
      bridge_positions: Timeline.bridge_positions(timeline)
    }
  end

  # Create segmentation information
  defp create_segmentation_info(timeline) do
    segments = Timeline.segment_by_bridges(timeline)

    %{
      total_segments: length(segments),
      segment_details:
        Enum.map(segments, fn segment ->
          %{
            number: segment.number,
            interval_count: length(segment.intervals),
            time_range: {
              segment.start_time,
              segment.end_time
            },
            preceding_bridge: segment.preceding_bridge
          }
        end)
    }
  end

  # ==================== STRATEGY METADATA ====================

  @doc """
  Get strategy metadata and capabilities.
  """
  def strategy_info do
    base_info = STNTemporalStrategy.strategy_info()

    %{
      base_info
      | name: "STN Bridge Temporal Strategy",
        version: "1.0.0",
        description: "Bridge-enabled STN temporal strategy with automatic segmentation",
        capabilities:
          base_info.capabilities ++
            [
              :automatic_bridge_insertion,
              :bridge_based_segmentation,
              :decision_point_detection,
              :phase_boundary_management,
              :resource_transition_handling
            ],
        configuration_options:
          base_info.configuration_options ++
            [
              :bridge_mode,
              :bridge_insertion_rules,
              :auto_segmentation,
              :bridge_validation_level
            ],
        underlying_implementation: "STNTemporalStrategy + Timeline.Bridge"
    }
  end

  @doc """
  Check if this strategy can handle specific temporal features.
  """
  def supports?(feature) when is_atom(feature) do
    bridge_features = [
      :automatic_bridge_insertion,
      :bridge_based_segmentation,
      :decision_point_detection,
      :phase_boundary_management,
      :resource_transition_handling
    ]

    feature in bridge_features or STNTemporalStrategy.supports?(feature)
  end

  @doc """
  Get performance characteristics of this strategy.
  """
  def performance_profile do
    base_profile = STNTemporalStrategy.performance_profile()

    Map.merge(base_profile, %{
      constraint_addition_complexity: :linear_with_bridge_overhead,
      memory_usage: :moderate_plus_bridges,
      scalability: :good_with_segmentation,
      additional_features: [:bridge_segmentation, :automatic_decision_points]
    })
  end
end
