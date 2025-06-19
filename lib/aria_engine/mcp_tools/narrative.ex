defmodule AriaEngine.MCPTools.Narrative do
  @moduledoc """
  Provides helper functions for generating narrative elements
  based on entity capabilities and simulation results.
  """

  require Logger

  # Entity-capability-driven narrative generation helpers

  def build_entity_lookup(entities) when is_list(entities) do
    Enum.reduce(entities, %{}, fn entity, acc ->
      Map.put(acc, entity["id"], entity)
    end)
  end

  def build_activity_lookup(activities) when is_list(activities) do
    Enum.reduce(activities, %{}, fn activity, acc ->
      Map.put(acc, activity["id"], activity)
    end)
  end

  def detect_story_phases_from_capabilities(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Group activities by dominant entity type capabilities
        activities
        |> Enum.group_by(&detect_phase_from_activity(&1, entity_lookup, activity_lookup))
        |> Enum.map(fn {phase, phase_activities} ->
          %{
            phase: phase,
            description: get_phase_description(phase),
            activities: phase_activities,
            dominant_entities: get_dominant_entities(phase_activities, entity_lookup)
          }
        end)
      _ -> []
    end
  end

  def detect_phase_from_activity(activity, entity_lookup, activity_lookup) do
    activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id"))
    entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id"))

    # Get activity requirements
    activity_data = Map.get(activity_lookup, activity_id, %{})
    required_capabilities = Map.get(activity_data, "required_capabilities", [])

    # Get entity type and capabilities
    entity_data = Map.get(entity_lookup, entity_id, %{})
    entity_type = Map.get(entity_data, "type", "unknown")
    entity_capabilities = Map.get(entity_data, "capabilities", [])

    # Determine phase based on capability patterns
    cond do
      entity_type == "conceptual" -> :conceptual_evolution
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "bio")) -> :bio_integration
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "network")) ||
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "security")) -> :cyber_operations
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "community")) ||
      Enum.any?(required_capabilities, &String.contains?(to_string(&1), "coordination")) -> :community_synthesis
      Enum.any?(entity_capabilities, &String.contains?(to_string(&1), "crisis")) -> :crisis_management
      true -> :operational_coordination
    end
  end

  def get_phase_description(phase) do
    case phase do
      :bio_integration -> "Living systems integration and biological interface establishment"
      :cyber_operations -> "Information network infiltration and digital security operations"
      :community_synthesis -> "Stakeholder coordination and collaborative framework development"
      :crisis_management -> "Rapid assessment and emergency coordination protocols"
      :conceptual_evolution -> "Abstract state transitions and emergent property development"
      :operational_coordination -> "Cross-functional coordination and system integration"
      _ -> "Complex multi-domain operations"
    end
  end

  def get_dominant_entities(phase_activities, entity_lookup) do
    phase_activities
    |> Enum.map(fn activity -> Map.get(activity, :entity_id, Map.get(activity, "entity_id")) end)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_entity, count} -> count end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {entity_id, _count} ->
      entity_data = Map.get(entity_lookup, entity_id, %{})
      Map.get(entity_data, "name", entity_id)
    end)
  end

  def count_entity_types(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.map(fn entity -> Map.get(entity, "type", "unknown") end)
    |> Enum.uniq()
    |> length()
  end

  def list_entity_types(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.map(fn entity -> Map.get(entity, "type", "unknown") end)
    |> Enum.uniq()
    |> Enum.map(&humanize_entity_type/1)
    |> Enum.join(", ")
  end

  def humanize_entity_type(type) do
    type
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def count_unique_capabilities(entity_lookup) do
    entity_lookup
    |> Map.values()
    |> Enum.flat_map(fn entity -> Map.get(entity, "capabilities", []) end)
    |> Enum.uniq()
    |> length()
  end

  def generate_capability_based_achievements(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        # Group by capability types used
        capability_usage = activities
        |> Enum.flat_map(&extract_capabilities_from_activity(&1, entity_lookup, activity_lookup))
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_cap, count} -> count end, :desc)
        |> Enum.take(8)

        capability_usage
        |> Enum.map(fn {capability, usage_count} ->
          entities_with_cap = find_entities_with_capability(capability, entity_lookup)
          "- **#{humanize_capability(capability)}**: Used #{usage_count} times by #{Enum.join(entities_with_cap, ", ")}"
        end)
        |> Enum.join("\n")
      _ -> "Capability analysis not available - no activity execution data."
    end
  end

  def extract_capabilities_from_activity(activity, entity_lookup, activity_lookup) do
    activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id"))
    entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id"))

    # Get activity requirements
    activity_data = Map.get(activity_lookup, activity_id, %{})
    required_capabilities = Map.get(activity_data, "required_capabilities", [])

    # Get entity capabilities
    entity_data = Map.get(entity_lookup, entity_id, %{})
    entity_capabilities = Map.get(entity_data, "capabilities", [])

    # Return intersection of required and available capabilities
    required_capabilities
    |> Enum.filter(fn req_cap ->
      Enum.any?(entity_capabilities, fn entity_cap ->
        to_string(entity_cap) == to_string(req_cap)
      end)
    end)
  end

  def find_entities_with_capability(capability, entity_lookup) do
    entity_lookup
    |> Enum.filter(fn {_id, entity} ->
      capabilities = Map.get(entity, "capabilities", [])
      Enum.any?(capabilities, fn cap -> to_string(cap) == to_string(capability) end)
    end)
    |> Enum.map(fn {_id, entity} ->
      Map.get(entity, "name", Map.get(entity, "id", "Unknown"))
    end)
    |> Enum.take(3)  # Limit to top 3 for readability
  end

  def humanize_capability(capability) do
    capability
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  def generate_story_phase_narrative(story_phases, _entity_lookup) do
    if length(story_phases) > 0 do
      story_phases
      |> Enum.map(fn phase ->
        activity_count = length(phase.activities)
        entity_list = Enum.join(phase.dominant_entities, ", ")

        "**#{humanize_capability(to_string(phase.phase))} Phase**: #{phase.description}  \n" <>
        "#{activity_count} activities coordinated by #{entity_list}"
      end)
      |> Enum.join("\n\n")
    else
      "Story phase analysis not available - insufficient activity execution data."
    end
  end

  def generate_capability_timeline(simulation_result, entity_lookup, activity_lookup) do
    case simulation_result.activity_log do
      activities when is_list(activities) and length(activities) > 0 ->
        activities
        |> Enum.take(10)  # Show first 10 activities
        |> Enum.map(fn activity ->
          timestamp = Map.get(activity, :mission_duration,
                              Map.get(activity, "mission_duration",
                              Map.get(activity, :timestamp,
                              Map.get(activity, "timestamp", "Unknown"))))

          activity_id = Map.get(activity, :activity_id, Map.get(activity, "activity_id", "unknown"))
          entity_id = Map.get(activity, :entity_id, Map.get(activity, "entity_id", "unknown"))

          # Get primary capability used
          capabilities = extract_capabilities_from_activity(activity, entity_lookup, activity_lookup)
          primary_capability = case capabilities do
            [cap | _] -> humanize_capability(cap)
            [] -> "General coordination"
          end

          # Enhanced entity name resolution with debugging
          entity_name = resolve_entity_name(entity_id, entity_lookup)

          "- **#{format_timestamp(timestamp)}**: #{humanize_activity_id(activity_id)} (#{primary_capability} by #{entity_name})"
        end)
        |> Enum.join("\n")
      _ -> "Capability timeline not available - no detailed execution logs."
    end
  end

  # Enhanced entity name resolution with multiple fallback strategies
  def resolve_entity_name(entity_id, entity_lookup) do
    cond do
      # If entity_id is nil or empty, return generic name
      is_nil(entity_id) or entity_id == "" or entity_id == "unknown" ->
        "Unassigned Entity"

      # Try direct lookup by entity_id
      Map.has_key?(entity_lookup, entity_id) ->
        entity_data = Map.get(entity_lookup, entity_id)
        extract_entity_display_name(entity_data, entity_id)

      # If direct lookup fails, try to find by partial match or similar keys
      true ->
        case find_entity_by_fuzzy_match(entity_id, entity_lookup) do
          {_key, entity_data} -> extract_entity_display_name(entity_data, entity_id)
          nil -> humanize_entity_id(entity_id)  # Use formatted entity_id as fallback
        end
    end
  end

  # Extract display name from entity data with multiple strategies
  def extract_entity_display_name(entity_data, fallback_id) when is_map(entity_data) do
    cond do
      # Try "name" field first
      Map.has_key?(entity_data, "name") and is_binary(entity_data["name"]) ->
        entity_data["name"] |> String.split(",") |> hd() |> String.trim()

      # Try "display_name" field
      Map.has_key?(entity_data, "display_name") and is_binary(entity_data["display_name"]) ->
        entity_data["display_name"] |> String.trim()

      # Try "id" field and humanize it
      Map.has_key?(entity_data, "id") and is_binary(entity_data["id"]) ->
        humanize_entity_id(entity_data["id"])

      # Use fallback_id and humanize it
      true ->
        humanize_entity_id(fallback_id)
    end
  end
  def extract_entity_display_name(_, fallback_id), do: humanize_entity_id(fallback_id)

  # Find entity by fuzzy matching (useful for slight mismatches in entity IDs)
  def find_entity_by_fuzzy_match(target_id, entity_lookup) do
    target_id_lower = String.downcase(target_id)

    entity_lookup
    |> Enum.find(fn {entity_key, _entity_data} ->
      entity_key_lower = String.downcase(to_string(entity_key))

      # Try exact match first
      entity_key_lower == target_id_lower or
      # Try partial matches
      String.contains?(entity_key_lower, target_id_lower) or
      String.contains?(target_id_lower, entity_key_lower)
    end)
  end

  # Convert entity_id to human-readable format
  def humanize_entity_id(entity_id) when is_binary(entity_id) do
    entity_id
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  def humanize_entity_id(entity_id), do: to_string(entity_id) |> humanize_entity_id()

  def generate_conceptual_entity_outcomes(simulation_result, entity_lookup) do
    # Find conceptual entities
    conceptual_entities = entity_lookup
    |> Enum.filter(fn {_id, entity} -> Map.get(entity, "type") == "conceptual" end)

    if length(conceptual_entities) > 0 do
      "\n## Conceptual Entity State Changes\n\n" <>
      (conceptual_entities
      |> Enum.map(fn {entity_id, entity} ->
        entity_name = Map.get(entity, "id", entity_id)
        current_state = Map.get(entity, "current_state", "unknown")
        capabilities = Map.get(entity, "capabilities", [])

        # Determine likely outcome based on mission success
        predicted_outcome = case simulation_result.status do
          :success -> predict_positive_outcome(current_state, capabilities)
          _ -> predict_neutral_outcome(current_state, capabilities)
        end

        "- **#{humanize_capability(entity_name)}**: #{current_state} → #{predicted_outcome}"
      end)
      |> Enum.join("\n"))
    else
      ""
    end
  end

  def predict_positive_outcome(current_state, capabilities) do
    case current_state do
      "fragmented" -> "unified"
      "deteriorating" -> "stabilized"
      "escalating" -> "resolved"
      "blocked" -> "flowing"
      "nascent" -> "established"
      _ ->
        # Infer from capabilities
        if Enum.any?(capabilities, &String.contains?(to_string(&1), "bridge")) do
          "bridged"
        else
          "improved"
        end
    end
  end

  def predict_neutral_outcome(current_state, _capabilities) do
    case current_state do
      "fragmented" -> "partially connected"
      "deteriorating" -> "maintained"
      "escalating" -> "managed"
      "blocked" -> "partially opened"
      "nascent" -> "developing"
      _ -> "unchanged"
    end
  end

  def create_basic_success_result(_mission_data) do
    # Create a minimal SimulationResult struct for consistent processing
    minimal_simulation_result = %AriaEngine.Scheduler.SimulationResult{
      status: :success,
      reason: "Mission planning completed successfully",
      schedule: [],
      analysis: %{},
      activity_log: %{},
      resource_utilization: %{},
      timeline: %{},
      simulation_metadata: %{}
    }

    # Process through the normal path - raw result only
    AriaEngine.MCPTools.Converter.convert_simulation_result_to_map(minimal_simulation_result)
  end

  # Safe helper functions for defensive narrative generation

  def safe_get_map(data, key, default) when is_map(data) do
    case Map.get(data, key, default) do
      result when is_map(result) -> result
      _ -> default
    end
  end
  def safe_get_map(_, _, default), do: default

  def safe_build_entity_lookup(entities) when is_list(entities) do
    try do
      build_entity_lookup(entities)
    rescue
      _ -> %{}
    end
  end
  def safe_build_entity_lookup(_), do: %{}

  def safe_build_activity_lookup(activities) when is_list(activities) do
    try do
      build_activity_lookup(activities)
    rescue
      _ -> %{}
    end
  end
  def safe_build_activity_lookup(_), do: %{}

  def safe_detect_story_phases(simulation_result, entity_lookup, activity_lookup) do
    try do
      detect_story_phases_from_capabilities(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error detecting story phases: #{Exception.message(e)}")
        []
    end
  end

  def safe_generate_capability_achievements(simulation_result, entity_lookup, activity_lookup) do
    try do
      generate_capability_based_achievements(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error generating capability achievements: #{Exception.message(e)}")
        "Entity capability analysis not available due to data processing issues."
    end
  end

  def safe_generate_story_phase_narrative(story_phases, entity_lookup) do
    try do
      generate_story_phase_narrative(story_phases, entity_lookup)
    rescue
      e ->
        Logger.warning("Error generating story phase narrative: #{Exception.message(e)}")
        "Story phase analysis not available due to processing constraints."
    end
  end

  def safe_generate_capability_timeline(simulation_result, entity_lookup, activity_lookup) do
    try do
      generate_capability_timeline(simulation_result, entity_lookup, activity_lookup)
    rescue
      e ->
        Logger.warning("Error generating capability timeline: #{Exception.message(e)}")
        "Entity-driven timeline not available due to data processing issues."
    end
  end

  def safe_generate_entity_outcomes(simulation_result, entity_lookup) do
    try do
      generate_conceptual_entity_outcomes(simulation_result, entity_lookup)
    rescue
      e ->
        Logger.warning("Error generating entity outcomes: #{Exception.message(e)}")
        ""
    end
  end

  def safe_count_entity_types(entity_lookup) do
    try do
      count_entity_types(entity_lookup)
    rescue
      _ -> 0
    end
  end

  def safe_list_entity_types(entity_lookup) do
    try do
      list_entity_types(entity_lookup)
    rescue
      _ -> "various specialized entities"
    end
  end

  def safe_count_unique_capabilities(entity_lookup) do
    try do
      count_unique_capabilities(entity_lookup)
    rescue
      _ -> 0
    end
  end

  def safe_get_total_duration(simulation_result) do
    try do
      get_total_duration(simulation_result)
    rescue
      _ -> "Duration calculation unavailable"
    end
  end

  def safe_calculate_resource_efficiency(simulation_result) do
    try do
      calculate_resource_efficiency(simulation_result)
    rescue
      _ -> "Resource efficiency calculation unavailable"
    end
  end

  def format_timestamp(timestamp) do
    timestamp
  end

  def humanize_activity_id(activity_id) do
    activity_id
  end

  def get_total_duration(simulation_result) do
    simulation_result
  end

  def calculate_resource_efficiency(simulation_result) do
    simulation_result
  end
end