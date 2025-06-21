# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TimelineGraph.LODManager do
  @moduledoc """
  Manages Level of Detail (LOD) for entity timelines.

  This module handles the promotion and management of timeline detail levels
  based on entity activity, agent status, and system performance requirements.
  """

  @type entity_id :: String.t()
  @type lod_level :: :very_low | :low | :medium | :high | :ultra_high

  @doc """
  Gets the current LOD level for an entity's timeline.
  """
  @spec get_lod(map(), entity_id()) :: {:ok, lod_level()} | {:error, :not_found}
  def get_lod(timeline_graph, entity_id) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil -> {:error, :not_found}
      entity_timeline -> {:ok, entity_timeline.lod}
    end
  end

  @doc """
  Promotes an LOD level to the next higher level.

  LOD progression: very_low -> low -> medium -> high -> ultra_high
  """
  @spec promote_lod(lod_level()) :: lod_level()
  def promote_lod(current_lod) do
    case current_lod do
      :very_low -> :low
      :low -> :medium
      :medium -> :high
      :high -> :ultra_high
      # Already at max
      :ultra_high -> :ultra_high
    end
  end

  @doc """
  Demotes an LOD level to the next lower level.

  LOD regression: ultra_high -> high -> medium -> low -> very_low
  """
  @spec demote_lod(lod_level()) :: lod_level()
  def demote_lod(current_lod) do
    case current_lod do
      :ultra_high -> :high
      :high -> :medium
      :medium -> :low
      :low -> :very_low
      # Already at minimum
      :very_low -> :very_low
    end
  end

  @doc """
  Processes the LOD promotion queue, upgrading timeline detail for active agents.

  This function iterates through entities queued for LOD promotion and upgrades
  their timeline detail levels, then clears the promotion queue.
  """
  @spec process_lod_promotions(map()) :: map()
  def process_lod_promotions(timeline_graph) do
    Enum.reduce(timeline_graph.lod_promotion_queue, timeline_graph, fn entity_id, graph ->
      case Map.get(graph.entities, entity_id) do
        nil ->
          graph

        entity_timeline ->
          promoted_lod = promote_lod(entity_timeline.lod)
          updated_entity_timeline = %{entity_timeline | lod: promoted_lod}

          %{graph | entities: Map.put(graph.entities, entity_id, updated_entity_timeline)}
      end
    end)
    |> Map.put(:lod_promotion_queue, [])
  end

  @doc """
  Sets the LOD level for a specific entity.

  This allows manual control over timeline detail levels when automatic
  promotion/demotion is not sufficient.
  """
  @spec set_lod(map(), entity_id(), lod_level()) :: {:ok, map()} | {:error, term()}
  def set_lod(timeline_graph, entity_id, new_lod) do
    case Map.get(timeline_graph.entities, entity_id) do
      nil ->
        {:error, :entity_not_found}

      entity_timeline ->
        updated_entity_timeline = %{entity_timeline | lod: new_lod}

        updated_timeline_graph = %{
          timeline_graph
          | entities: Map.put(timeline_graph.entities, entity_id, updated_entity_timeline)
        }

        {:ok, updated_timeline_graph}
    end
  end

  @doc """
  Adds an entity to the LOD promotion queue.

  Entities in the promotion queue will have their LOD levels upgraded
  during the next call to `process_lod_promotions/1`.
  """
  @spec queue_for_promotion(map(), entity_id()) :: map()
  def queue_for_promotion(timeline_graph, entity_id) do
    if entity_id in timeline_graph.lod_promotion_queue do
      timeline_graph
    else
      %{
        timeline_graph
        | lod_promotion_queue: [entity_id | timeline_graph.lod_promotion_queue]
      }
    end
  end

  @doc """
  Gets all entities at a specific LOD level.
  """
  @spec get_entities_at_lod(map(), lod_level()) :: [entity_id()]
  def get_entities_at_lod(timeline_graph, target_lod) do
    timeline_graph.entities
    |> Enum.filter(fn {_id, entity_timeline} ->
      entity_timeline.lod == target_lod
    end)
    |> Enum.map(fn {id, _timeline} -> id end)
  end

  @doc """
  Gets LOD statistics for the timeline graph.

  Returns a map with counts of entities at each LOD level.
  """
  @spec get_lod_statistics(map()) :: %{lod_level() => non_neg_integer()}
  def get_lod_statistics(timeline_graph) do
    timeline_graph.entities
    |> Enum.reduce(%{}, fn {_id, entity_timeline}, acc ->
      Map.update(acc, entity_timeline.lod, 1, &(&1 + 1))
    end)
  end

  @doc """
  Automatically adjusts LOD levels based on entity activity and system performance.

  This function implements intelligent LOD management by:
  - Promoting active agents to higher detail levels
  - Demoting inactive entities to lower detail levels
  - Balancing system performance with timeline accuracy
  """
  @spec auto_adjust_lod(map(), keyword()) :: map()
  def auto_adjust_lod(timeline_graph, opts \\ []) do
    max_high_lod = Keyword.get(opts, :max_high_lod, 10)
    max_ultra_high_lod = Keyword.get(opts, :max_ultra_high_lod, 3)
    activity_threshold = Keyword.get(opts, :activity_threshold_minutes, 30)

    now = DateTime.utc_now()

    # Get current LOD distribution
    lod_stats = get_lod_statistics(timeline_graph)
    current_high = Map.get(lod_stats, :high, 0)
    current_ultra_high = Map.get(lod_stats, :ultra_high, 0)

    # Process each entity for LOD adjustment
    Enum.reduce(timeline_graph.entities, timeline_graph, fn {entity_id, entity_timeline}, graph ->
      # Calculate time since last activity
      minutes_since_activity = DateTime.diff(now, entity_timeline.last_growth, :second) / 60

      # Determine if entity should be promoted or demoted
      cond do
        # Promote active agents if under limits
        should_promote_entity?(entity_timeline, minutes_since_activity, activity_threshold) and
          can_promote_to_level?(entity_timeline.lod, current_high, current_ultra_high, max_high_lod, max_ultra_high_lod) ->
          promoted_lod = promote_lod(entity_timeline.lod)
          updated_entity_timeline = %{entity_timeline | lod: promoted_lod}
          %{graph | entities: Map.put(graph.entities, entity_id, updated_entity_timeline)}

        # Demote inactive entities
        should_demote_entity?(entity_timeline, minutes_since_activity, activity_threshold) ->
          demoted_lod = demote_lod(entity_timeline.lod)
          updated_entity_timeline = %{entity_timeline | lod: demoted_lod}
          %{graph | entities: Map.put(graph.entities, entity_id, updated_entity_timeline)}

        true ->
          graph
      end
    end)
  end

  # Private helper functions

  defp should_promote_entity?(entity_timeline, minutes_since_activity, activity_threshold) do
    # Promote if entity is an agent and has been active recently
    Timeline.AgentEntity.is_currently_agent?(entity_timeline.entity) and
      minutes_since_activity < activity_threshold and
      entity_timeline.lod != :ultra_high
  end

  defp should_demote_entity?(entity_timeline, minutes_since_activity, activity_threshold) do
    # Demote if entity has been inactive for a while
    minutes_since_activity > activity_threshold * 2 and
      entity_timeline.lod != :very_low
  end

  defp can_promote_to_level?(current_lod, current_high, current_ultra_high, max_high, max_ultra_high) do
    case promote_lod(current_lod) do
      :high -> current_high < max_high
      :ultra_high -> current_ultra_high < max_ultra_high
      _ -> true
    end
  end
end
