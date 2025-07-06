# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTown do
  @moduledoc """
  External API for AriaTown - NPC and town management system.

  This module provides the public interface for AriaTown functionality, including:
  - NPC lifecycle management (spawn, despawn, persistence)
  - Time management and scheduling
  - Semantic web context and RDF schema definitions
  - Persistence management for town state
  - JSON-LD encoding for semantic compatibility

  All cross-app communication should use this external API rather than importing
  internal AriaTown modules directly.

  ## NPC Management

      # Spawn a new NPC
      {:ok, npc} = AriaTown.spawn_npc(%{name: "Alice", position: {10, 0, 5}})

      # Get all NPCs
      npcs = AriaTown.list_npcs()

      # Update NPC state
      {:ok, updated_npc} = AriaTown.update_npc("npc_1", %{state: :walking})

      # Remove NPC
      :ok = AriaTown.despawn_npc("npc_1")

  ## Time Management

      # Get current game time
      current_time = AriaTown.current_time()

      # Advance time by 3600 seconds (1 hour)
      new_time = AriaTown.advance_time(3600)

  ## Semantic Web Integration

      # Get JSON-LD context for semantic compatibility
      context = AriaTown.get_semantic_context()

      # Get specific RDF schema elements
      person_iri = AriaTown.person_schema()
      location_iri = AriaTown.location_schema()

  ## Persistence

      # Trigger immediate save of town state
      AriaTown.save_town_state()

  ## Future Integration

  AriaTown is designed to integrate with AriaEngine's hybrid planner for:
  - Goal-oriented NPC behavior planning
  - Temporal scheduling of activities
  - Social interaction planning
  - Resource and spatial reasoning
  """

  # NPC Management API
  defdelegate list_npcs(), to: AriaTown.NPCManager
  defdelegate get_npc(npc_id), to: AriaTown.NPCManager
  defdelegate spawn_npc(npc_config), to: AriaTown.NPCManager
  defdelegate update_npc(npc_id, updates), to: AriaTown.NPCManager
  defdelegate despawn_npc(npc_id), to: AriaTown.NPCManager

  # Time Management API
  defdelegate current_time(), to: AriaTown.TimeManager
  defdelegate advance_time(delta), to: AriaTown.TimeManager

  # Persistence API
  defdelegate save_town_state(), to: AriaTown.PersistenceManager, as: :trigger_save

  # Semantic Web Context API
  defdelegate get_semantic_context(), to: AriaTown.ContextSchema, as: :get_context
  defdelegate person_schema(), to: AriaTown.ContextSchema, as: :person
  defdelegate location_schema(), to: AriaTown.ContextSchema, as: :location
  defdelegate activity_schema(), to: AriaTown.ContextSchema, as: :activity
  defdelegate conversation_schema(), to: AriaTown.ContextSchema, as: :conversation
  defdelegate knows_property(), to: AriaTown.ContextSchema, as: :knows
  defdelegate located_at_property(), to: AriaTown.ContextSchema, as: :located_at
  defdelegate engaged_in_property(), to: AriaTown.ContextSchema, as: :engaged_in
  defdelegate spoke_with_property(), to: AriaTown.ContextSchema, as: :spoke_with
  defdelegate heard_about_property(), to: AriaTown.ContextSchema, as: :heard_about
  defdelegate plans_to_property(), to: AriaTown.ContextSchema, as: :plans_to
  defdelegate remembers_property(), to: AriaTown.ContextSchema, as: :remembers
  defdelegate time_of_day_property(), to: AriaTown.ContextSchema, as: :time_of_day
  defdelegate scheduled_at_property(), to: AriaTown.ContextSchema, as: :scheduled_at
  defdelegate timestamp_property(), to: AriaTown.ContextSchema, as: :timestamp
  defdelegate personality_property(), to: AriaTown.ContextSchema, as: :personality
  defdelegate mood_property(), to: AriaTown.ContextSchema, as: :mood
  defdelegate priority_property(), to: AriaTown.ContextSchema, as: :priority
  defdelegate conflicts_with_property(), to: AriaTown.ContextSchema, as: :conflicts_with
  defdelegate participants_property(), to: AriaTown.ContextSchema, as: :participants
  defdelegate about_property(), to: AriaTown.ContextSchema, as: :about
  defdelegate content_property(), to: AriaTown.ContextSchema, as: :content
  defdelegate source_property(), to: AriaTown.ContextSchema, as: :source

  @doc """
  Initializes a new town with default NPCs and settings.

  This convenience function sets up a basic town environment with
  initial NPCs and time configuration.

  ## Parameters

  - `options`: Configuration options
    - `:initial_npcs`: List of NPC configurations to spawn
    - `:start_time`: Initial game time (defaults to current UTC time)
    - `:time_scale`: Time progression multiplier (defaults to 1.0)

  ## Examples

      iex> town_config = AriaTown.initialize_town(
      ...>   initial_npcs: [
      ...>     %{name: "Alice", position: {0, 0, 0}},
      ...>     %{name: "Bob", position: {10, 0, 0}}
      ...>   ],
      ...>   start_time: ~U[2025-01-01 08:00:00Z],
      ...>   time_scale: 2.0
      ...> )
      iex> {:ok, %{npcs: npcs, time: time}} = town_config
  """
  def initialize_town(options \\ []) do
    initial_npcs = Keyword.get(options, :initial_npcs, [])
    start_time = Keyword.get(options, :start_time, DateTime.utc_now())
    time_scale = Keyword.get(options, :time_scale, 1.0)

    # Spawn initial NPCs
    spawned_npcs = Enum.map(initial_npcs, fn npc_config ->
      case spawn_npc(npc_config) do
        {:ok, npc} -> npc
        {:error, reason} -> {:error, {:npc_spawn_failed, npc_config, reason}}
      end
    end)

    # Check for any spawn failures
    case Enum.find(spawned_npcs, &match?({:error, _}, &1)) do
      nil ->
        {:ok, %{
          npcs: spawned_npcs,
          time: start_time,
          time_scale: time_scale,
          status: :initialized
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets comprehensive town status including all NPCs and current time.

  This convenience function provides a complete overview of the town state.

  ## Examples

      iex> status = AriaTown.get_town_status()
      iex> {:ok, %{npcs: npcs, time: time, npc_count: count}} = status
  """
  def get_town_status do
    npcs = list_npcs()
    time = current_time()

    {:ok, %{
      npcs: npcs,
      time: time,
      npc_count: length(npcs),
      status: :active
    }}
  end

  @doc """
  Finds NPCs based on specified criteria.

  This convenience function allows filtering NPCs by various attributes.

  ## Parameters

  - `criteria`: Map of filtering criteria
    - `:name`: Filter by NPC name (exact match or regex)
    - `:state`: Filter by NPC state
    - `:position_near`: Filter by proximity to a position
    - `:created_after`: Filter by creation time

  ## Examples

      iex> npcs = AriaTown.find_npcs(%{state: :idle})
      iex> npcs = AriaTown.find_npcs(%{name: ~r/Alice/})
      iex> npcs = AriaTown.find_npcs(%{position_near: {{0, 0, 0}, 10.0}})
  """
  def find_npcs(criteria) do
    npcs = list_npcs()

    filtered_npcs = Enum.filter(npcs, fn npc ->
      matches_criteria?(npc, criteria)
    end)

    filtered_npcs
  end

  @doc """
  Schedules an activity for an NPC at a specific time.

  This convenience function combines NPC updates with time-based scheduling.

  ## Parameters

  - `npc_id`: ID of the NPC to schedule activity for
  - `activity`: Activity description or configuration
  - `scheduled_time`: When the activity should occur

  ## Examples

      iex> result = AriaTown.schedule_npc_activity("npc_1",
      ...>   %{type: :work, location: "market"},
      ...>   ~U[2025-01-01 09:00:00Z]
      ...> )
      iex> {:ok, updated_npc} = result
  """
  def schedule_npc_activity(npc_id, activity, scheduled_time) do
    case get_npc(npc_id) do
      nil ->
        {:error, :npc_not_found}

      npc ->
        scheduled_activities = Map.get(npc, :scheduled_activities, [])
        new_activity = Map.merge(activity, %{scheduled_at: scheduled_time})
        updated_activities = [new_activity | scheduled_activities]

        update_npc(npc_id, %{scheduled_activities: updated_activities})
    end
  end

  @doc """
  Creates a semantic web representation of the town state.

  This function generates a JSON-LD representation of the current town
  state using the defined RDF schema.

  ## Parameters

  - `options`: Configuration options
    - `:include_npcs`: Include NPC data (default: true)
    - `:include_time`: Include time information (default: true)
    - `:format`: Output format (:json_ld, :turtle, :ntriples)

  ## Examples

      iex> semantic_data = AriaTown.export_semantic_data()
      iex> {:ok, json_ld} = semantic_data
  """
  def export_semantic_data(options \\ []) do
    include_npcs = Keyword.get(options, :include_npcs, true)
    include_time = Keyword.get(options, :include_time, true)
    format = Keyword.get(options, :format, :json_ld)

    context = get_semantic_context()

    data = %{
      "@context" => context["@context"],
      "@type" => "Town",
      "@id" => "https://chibifire.com/towns/aria_town"
    }

    data = if include_npcs do
      npcs = list_npcs()
      semantic_npcs = Enum.map(npcs, &npc_to_semantic/1)
      Map.put(data, "residents", semantic_npcs)
    else
      data
    end

    data = if include_time do
      time = current_time()
      Map.put(data, "currentTime", DateTime.to_iso8601(time))
    else
      data
    end

    case format do
      :json_ld -> {:ok, data}
      _ -> {:error, {:unsupported_format, format}}
    end
  end

  @doc """
  Simulates town activity for a specified duration.

  This convenience function advances time and triggers NPC activities
  for testing and simulation purposes.

  ## Parameters

  - `duration_seconds`: How long to simulate (in seconds)
  - `options`: Simulation options
    - `:step_size`: Time step size for simulation (default: 60 seconds)
    - `:trigger_activities`: Whether to trigger scheduled activities (default: true)

  ## Examples

      iex> result = AriaTown.simulate_town(3600, step_size: 300)
      iex> {:ok, %{final_time: time, activities_triggered: count}} = result
  """
  def simulate_town(duration_seconds, options \\ []) do
    step_size = Keyword.get(options, :step_size, 60)
    trigger_activities = Keyword.get(options, :trigger_activities, true)

    start_time = current_time()
    steps = div(duration_seconds, step_size)

    activities_triggered = if trigger_activities do
      Enum.reduce(1..steps, 0, fn _step, acc ->
        advance_time(step_size)
        # In future implementation, check for scheduled activities
        # and trigger them based on current time
        acc
      end)
    else
      advance_time(duration_seconds)
      0
    end

    final_time = current_time()

    {:ok, %{
      start_time: start_time,
      final_time: final_time,
      duration: duration_seconds,
      activities_triggered: activities_triggered
    }}
  end

  # Private helper functions

  defp matches_criteria?(npc, criteria) do
    Enum.all?(criteria, fn {key, value} ->
      case key do
        :name ->
          case value do
            %Regex{} = regex -> Regex.match?(regex, npc.name)
            name when is_binary(name) -> npc.name == name
            _ -> false
          end

        :state ->
          Map.get(npc, :state) == value

        :position_near ->
          case value do
            {target_pos, max_distance} ->
              distance = calculate_distance(npc.position, target_pos)
              distance <= max_distance
            _ -> false
          end

        :created_after ->
          case Map.get(npc, :created_at) do
            nil -> false
            created_at -> DateTime.compare(created_at, value) in [:gt, :eq]
          end

        _ ->
          Map.get(npc, key) == value
      end
    end)
  end

  defp calculate_distance({x1, y1, z1}, {x2, y2, z2}) do
    dx = x2 - x1
    dy = y2 - y1
    dz = z2 - z1
    :math.sqrt(dx * dx + dy * dy + dz * dz)
  end

  defp npc_to_semantic(npc) do
    %{
      "@type" => "Person",
      "@id" => "https://chibifire.com/npcs/#{npc.id}",
      "name" => npc.name,
      "locatedAt" => position_to_semantic(npc.position),
      "state" => Map.get(npc, :state, :unknown),
      "timestamp" => case Map.get(npc, :created_at) do
        nil -> nil
        datetime -> DateTime.to_iso8601(datetime)
      end
    }
  end

  defp position_to_semantic({x, y, z}) do
    %{
      "@type" => "Location",
      "coordinates" => %{
        "x" => x,
        "y" => y,
        "z" => z
      }
    }
  end
end
