# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.TownSimulation do
  @moduledoc """
  Sample 6: Smallville Community Simulation (Emergent Behavior)
  Demonstrates emergent autonomous behavior, opportunistic decision-making, and organic coordination with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias AriaEngine.Scheduler.{Entity, Resource}
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🏘️ Sample 6: Smallville Community Simulation (Emergent Behavior)" <> IO.ANSI.reset())
    IO.puts("Demonstrates emergent autonomous behavior, opportunistic decision-making, and organic coordination")
    
    # Configurable town scale (direct resident count, capped between 1 and 1000)
    town_scale = System.get_env("TOWN_SCALE", "6") 
                 |> String.to_integer() 
                 |> max(1) 
                 |> min(1000)
    
    # Measure planning time
    start_time = System.monotonic_time(:millisecond)
    
    # Generate town residents and opportunity-based activities
    entities = generate_town_residents(town_scale)
    resources = generate_town_resources(town_scale)
    activities = generate_emergent_opportunities(town_scale)
    
    base_datetime = DateTime.utc_now()
    
    IO.puts("📊 Scale: #{length(activities)} opportunities, #{length(entities)} residents, #{length(resources)} locations")
    IO.puts("🎯 Simulating: Emergent behavior, opportunistic decision-making, and organic coordination")
    
    case Scheduler.schedule_activities(
      "Smallville Community - Emergent Behavior Simulation",
      activities,
      base_datetime: base_datetime,
      entities: entities,
      resources: resources
    ) do
      {:ok, result} ->
        end_time = System.monotonic_time(:millisecond)
        planning_time_ms = end_time - start_time
        
        print_schedule_result_with_timing(result, "Community emergent behavior simulation", planning_time_ms)
        print_town_analysis(result, entities, activities)
      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        planning_time_ms = end_time - start_time
        IO.puts(IO.ANSI.red() <> "❌ Community simulation failed after #{planning_time_ms}ms: #{reason}" <> IO.ANSI.reset())
    end
  end

  # Generate town residents with diverse interests and capabilities
  defp generate_town_residents(resident_count \\ 6) do
    base_residents = [
      %Entity{
        id: "isabella_rodriguez",
        type: :resident,
        capabilities: [:hospitality, :event_planning, :social_coordination, :community_networking],
        availability: nil,
        metadata: %{
          occupation: "Cafe Owner", 
          personality: "Outgoing, community-focused",
          interests: [:local_politics, :community_events, :meeting_people],
          social_magnetism: :high
        }
      },
      %Entity{
        id: "john_lin",
        type: :resident,
        capabilities: [:customer_service, :health_advice, :community_support, :practical_wisdom],
        availability: nil,
        metadata: %{
          occupation: "Pharmacy Shopkeeper", 
          personality: "Helpful, caring, family-oriented",
          interests: [:community_health, :local_politics, :helping_neighbors],
          social_magnetism: :medium
        }
      },
      %Entity{
        id: "klaus_mueller",
        type: :resident,
        capabilities: [:research, :writing, :academic_work, :critical_thinking],
        availability: nil,
        metadata: %{
          occupation: "College Student", 
          personality: "Intellectual, curious, socially engaged",
          interests: [:research, :politics, :social_issues, :coffee_discussions],
          social_magnetism: :medium
        }
      },
      %Entity{
        id: "maria_lopez",
        type: :resident,
        capabilities: [:art, :creativity, :cultural_events, :aesthetic_appreciation],
        availability: nil,
        metadata: %{
          occupation: "Artist", 
          personality: "Creative, expressive, community-minded",
          interests: [:art, :cultural_events, :community_beautification, :creative_collaboration],
          social_magnetism: :medium
        }
      },
      %Entity{
        id: "sam_moore",
        type: :resident,
        capabilities: [:leadership, :public_speaking, :community_organizing, :persuasion],
        availability: nil,
        metadata: %{
          occupation: "Mayoral Candidate", 
          personality: "Charismatic, ambitious, community-focused",
          interests: [:politics, :community_improvement, :public_speaking, :networking],
          social_magnetism: :high
        }
      },
      %Entity{
        id: "eddy_lin",
        type: :resident,
        capabilities: [:music, :research_assistance, :education, :creative_performance],
        availability: nil,
        metadata: %{
          occupation: "Student/Composer", 
          personality: "Studious, creative, collaborative",
          interests: [:music, :learning, :performance, :academic_research],
          social_magnetism: :low
        }
      }
    ]
    
    # Generate exactly resident_count number of residents
    if resident_count <= length(base_residents) do
      Enum.take(base_residents, resident_count)
    else
      additional_needed = resident_count - length(base_residents)
      additional_residents = generate_additional_residents(additional_needed)
      base_residents ++ additional_residents
    end
  end

  defp generate_town_resources(resident_count \\ 6) do
    base_resources = [
      %Resource{id: "hobbs_cafe", type: :physical, capacity: 20, current_usage: 0},
      %Resource{id: "willow_pharmacy", type: :physical, capacity: 5, current_usage: 0},
      %Resource{id: "oak_hill_college", type: :physical, capacity: 100, current_usage: 0},
      %Resource{id: "town_hall", type: :physical, capacity: 50, current_usage: 0},
      %Resource{id: "art_studio", type: :physical, capacity: 10, current_usage: 0},
      %Resource{id: "library", type: :physical, capacity: 30, current_usage: 0}
    ]
    
    # Scale resources intelligently based on resident count
    resource_count = cond do
      resident_count <= 10 -> max(1, min(resident_count * 2, length(base_resources)))
      resident_count <= 100 -> max(length(base_resources), round(resident_count * 0.7))
      true -> max(length(base_resources), round(resident_count * 0.3))
    end
    
    if resource_count <= length(base_resources) do
      Enum.take(base_resources, resource_count)
    else
      additional_needed = resource_count - length(base_resources)
      additional_resources = generate_additional_resources(additional_needed)
      base_resources ++ additional_resources
    end
  end

  # Generate emergent opportunities that residents can choose from based on interests and circumstances
  defp generate_emergent_opportunities(resident_count \\ 6) do
    base_opportunities = [
      # Essential Business Operations (residents must maintain their livelihoods) - Updated to 6 minutes max
      %{"id" => "operate_cafe", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:hospitality, :event_planning], "required_resources" => ["hobbs_cafe"],
        "assigned_entity" => "isabella_rodriguez", "opportunity_type" => "essential", "priority" => "high"},
      %{"id" => "operate_pharmacy", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:customer_service, :health_advice], "required_resources" => ["willow_pharmacy"],
        "assigned_entity" => "john_lin", "opportunity_type" => "essential", "priority" => "high"},
      
      # Social Gathering Opportunities (emerge when people are in same location)
      %{"id" => "impromptu_cafe_discussion", "duration" => "PT5M", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "social", "trigger_condition" => "multiple_people_present"},
      %{"id" => "political_conversation", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:public_speaking], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "social", "trigger_condition" => "political_interest_overlap"},
      %{"id" => "art_appreciation_moment", "duration" => "PT4M", "dependencies" => [], 
        "required_capabilities" => [:aesthetic_appreciation], "required_resources" => ["art_studio"],
        "opportunity_type" => "cultural", "trigger_condition" => "creative_work_visible"},
      
      # Information Sharing Opportunities (spread based on who knows what)
      %{"id" => "share_local_news", "duration" => "PT3M", "dependencies" => [], 
        "required_capabilities" => [:community_networking], 
        "opportunity_type" => "information", "trigger_condition" => "news_to_share"},
      %{"id" => "discuss_community_needs", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:community_support], 
        "opportunity_type" => "coordination", "trigger_condition" => "community_concern_identified"},
      
      # Creative Collaboration Opportunities (emerge when artists meet others)
      %{"id" => "collaborative_art_project", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:creativity, :aesthetic_appreciation], "required_resources" => ["art_studio"],
        "opportunity_type" => "creative", "trigger_condition" => "creative_synergy"},
      %{"id" => "musical_performance_planning", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:music, :event_planning], 
        "opportunity_type" => "creative", "trigger_condition" => "performance_opportunity"},
      
      # Learning and Research Opportunities (driven by curiosity and interests)
      %{"id" => "research_local_history", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:research], "required_resources" => ["library"],
        "opportunity_type" => "intellectual", "trigger_condition" => "curiosity_sparked"},
      %{"id" => "study_community_dynamics", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:academic_work], "required_resources" => ["library"],
        "opportunity_type" => "intellectual", "trigger_condition" => "academic_interest"},
      
      # Community Organization Opportunities (emerge from identified needs)
      %{"id" => "organize_community_event", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:event_planning], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "organizing", "trigger_condition" => "community_event_needed"},
      %{"id" => "coordinate_volunteer_effort", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:community_organizing], 
        "opportunity_type" => "organizing", "trigger_condition" => "volunteer_opportunity"},
      
      # Political Engagement Opportunities (driven by civic interests)
      %{"id" => "campaign_outreach", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:persuasion], "required_resources" => ["willow_pharmacy"],
        "opportunity_type" => "political", "trigger_condition" => "campaign_opportunity"},
      %{"id" => "civic_discussion", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:critical_thinking], "required_resources" => ["town_hall"],
        "opportunity_type" => "political", "trigger_condition" => "civic_issue_raised"},
      
      # Spontaneous Social Events (emerge from successful smaller interactions)
      %{"id" => "impromptu_community_gathering", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "emergent_event", "trigger_condition" => "social_momentum_builds"},
      %{"id" => "informal_music_session", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:creative_performance], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "emergent_event", "trigger_condition" => "musical_interest_expressed"},
      
      # Knowledge Exchange Opportunities (when experts meet learners)
      %{"id" => "health_advice_sharing", "duration" => "PT4M", "dependencies" => [], 
        "required_capabilities" => [:health_advice], "required_resources" => ["willow_pharmacy"],
        "opportunity_type" => "knowledge_exchange", "trigger_condition" => "health_question_asked"},
      %{"id" => "academic_mentoring", "duration" => "PT6M", "dependencies" => [], 
        "required_capabilities" => [:education], "required_resources" => ["library"],
        "opportunity_type" => "knowledge_exchange", "trigger_condition" => "learning_opportunity"},
      
      # Serendipitous Encounters (chance meetings that lead to new connections)
      %{"id" => "chance_encounter_conversation", "duration" => "PT3M", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], 
        "opportunity_type" => "serendipitous", "trigger_condition" => "unexpected_meeting"},
      %{"id" => "discover_shared_interest", "duration" => "PT5M", "dependencies" => [], 
        "required_capabilities" => [:community_networking], 
        "opportunity_type" => "serendipitous", "trigger_condition" => "interest_alignment_discovered"}
    ]
    
    # Scale opportunities intelligently based on resident count
    opportunity_count = cond do
      resident_count <= 5 -> max(1, min(resident_count * 4, length(base_opportunities)))
      resident_count <= 50 -> max(length(base_opportunities), round(resident_count * 2.5))
      true -> max(length(base_opportunities), round(resident_count * 1.5))
    end
    
    if opportunity_count <= length(base_opportunities) do
      Enum.take(base_opportunities, opportunity_count)
    else
      additional_needed = opportunity_count - length(base_opportunities)
      additional_opportunities = generate_additional_opportunities(additional_needed)
      base_opportunities ++ additional_opportunities
    end
  end

  # Generate additional residents for scaling up
  defp generate_additional_residents(count) do
    first_names = ["alex", "taylor", "jordan", "casey", "riley", "morgan", "avery", "quinn", "sage", "river"]
    last_names = ["smith", "johnson", "williams", "brown", "jones", "garcia", "miller", "davis", "rodriguez", "martinez"]
    occupations = ["Teacher", "Engineer", "Writer", "Chef", "Musician", "Nurse", "Mechanic", "Designer"]
    personalities = ["Friendly and outgoing", "Quiet and thoughtful", "Energetic and enthusiastic", "Calm and steady"]
    
    all_capabilities = [:hospitality, :customer_service, :research, :art, :leadership, :music, :writing, :teaching]
    all_interests = [:local_politics, :community_events, :art, :music, :research, :sports, :cooking, :gardening]
    
    1..count
    |> Enum.map(fn i ->
      first_name = Enum.at(first_names, rem(i - 1, length(first_names)))
      last_name = Enum.at(last_names, rem(div(i - 1, length(first_names)), length(last_names)))
      occupation = Enum.at(occupations, rem(i - 1, length(occupations)))
      personality = Enum.at(personalities, rem(i - 1, length(personalities)))
      
      unique_id = "#{first_name}_#{last_name}_#{i}"
      
      %Entity{
        id: unique_id,
        type: :resident,
        capabilities: Enum.take_random(all_capabilities, Enum.random(3..5)),
        availability: nil,
        metadata: %{
          occupation: occupation,
          personality: personality,
          interests: Enum.take_random(all_interests, Enum.random(2..4)),
          social_magnetism: Enum.random([:low, :medium, :high])
        }
      }
    end)
  end

  # Generate additional resources for scaling up
  defp generate_additional_resources(count) do
    resource_types = ["community_center", "park", "market", "workshop", "gallery", "theater", "gym", "clinic"]
    
    1..count
    |> Enum.map(fn i ->
      resource_type = Enum.at(resource_types, rem(i - 1, length(resource_types)))
      
      %Resource{
        id: "#{resource_type}_#{i}",
        type: :physical,
        capacity: Enum.random(10..50),
        current_usage: 0
      }
    end)
  end

  # Generate additional opportunities for scaling up
  defp generate_additional_opportunities(count) do
    opportunity_templates = [
      %{"id" => "community_workshop", "duration" => "PT6M", "opportunity_type" => "learning"},
      %{"id" => "neighborhood_meeting", "duration" => "PT6M", "opportunity_type" => "organizing"},
      %{"id" => "cultural_exchange", "duration" => "PT6M", "opportunity_type" => "cultural"},
      %{"id" => "skill_sharing", "duration" => "PT6M", "opportunity_type" => "knowledge_exchange"},
      %{"id" => "social_gathering", "duration" => "PT6M", "opportunity_type" => "social"}
    ]
    
    1..count
    |> Enum.map(fn i ->
      template = Enum.at(opportunity_templates, rem(i - 1, length(opportunity_templates)))
      
      %{
        "id" => "#{template["id"]}_#{i}",
        "duration" => template["duration"],
        "dependencies" => [],
        "required_capabilities" => [:social_coordination],
        "opportunity_type" => template["opportunity_type"],
        "trigger_condition" => "community_interest"
      }
    end)
  end

  defp print_schedule_result_with_timing(result, description, planning_time_ms) do
    IO.puts("\n" <> IO.ANSI.green() <> "✅ #{description}" <> IO.ANSI.reset())
    IO.puts("Status: #{result.status}")
    IO.puts("Reason: #{result.reason}")
    IO.puts(IO.ANSI.cyan() <> "⏱️  Planning Time: #{planning_time_ms}ms" <> IO.ANSI.reset())
    
    if result.analysis do
      IO.puts("\n📊 Analysis:")
      IO.puts("  • Activities analyzed: #{result.analysis.activities_analyzed}")
      IO.puts("  • Dependencies found: #{result.analysis.dependencies_found}")
      IO.puts("  • Resource conflicts: #{result.analysis.resource_conflicts}")
      IO.puts("  • Critical path length: #{result.analysis.critical_path_length}")
      IO.puts("  • Method: #{result.analysis.method}")
    end
    
    if result.schedule && length(result.schedule) > 0 do
      IO.puts("\n📅 Potential Daily Schedule:")
      
      result.schedule
      |> Enum.sort_by(fn activity -> 
        case activity do
          %{start_time: start_time} when is_binary(start_time) -> start_time
          %{"start_time" => start_time} when is_binary(start_time) -> start_time
          _ -> "1970-01-01T00:00:00Z"
        end
      end)
      |> Enum.take(10)
      |> Enum.each(fn activity ->
        id = get_activity_field(activity, "id")
        start_time = get_activity_field(activity, "start_time")
        end_time = get_activity_field(activity, "end_time")
        duration = get_activity_field(activity, "duration")
        
        start_formatted = format_time(start_time)
        end_formatted = format_time(end_time)
        
        IO.puts("   #{start_formatted}-#{end_formatted} | #{String.pad_trailing(id, 30)} | #{duration}")
      end)
      
      if length(result.schedule) > 10 do
        IO.puts("   ... and #{length(result.schedule) - 10} more activities")
      end
    end
  end

  defp print_town_analysis(result, entities, activities) do
    IO.puts("\n🏘️ Community Simulation Analysis:")
    IO.puts("  • Residents simulated: #{length(entities)}")
    IO.puts("  • Opportunity types: #{length(activities)}")
    IO.puts("  • Emergent behavior patterns demonstrated:")
    IO.puts("    - Opportunistic decision-making based on interests")
    IO.puts("    - Organic social coordination and event emergence")
    IO.puts("    - Capability-driven opportunity selection")
    IO.puts("    - Location-based social magnetism effects")
    IO.puts("    - Serendipitous encounters and relationship formation")
    IO.puts("    - Information sharing through natural interactions")
    IO.puts("    - Creative collaboration emerging from shared spaces")
    
    # Analyze opportunity types
    opportunity_types = activities
    |> Enum.map(fn activity -> Map.get(activity, "opportunity_type", "unknown") end)
    |> Enum.frequencies()
    
    IO.puts("\n📊 Opportunity Distribution:")
    opportunity_types
    |> Enum.sort_by(fn {_type, count} -> count end, :desc)
    |> Enum.each(fn {type, count} ->
      IO.puts("    - #{type}: #{count} opportunities")
    end)
  end
  
  defp get_activity_field(activity, field) when is_map(activity) do
    atom_field = if is_atom(field), do: field, else: String.to_atom(field)
    string_field = to_string(field)
    
    case activity do
      %{^atom_field => value} -> value
      %{^string_field => value} -> value
      _ -> Map.get(activity, atom_field, Map.get(activity, string_field, "N/A"))
    end
  end

  defp format_time(nil), do: "N/A"
  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M:%S")
  defp format_time(time_string) when is_binary(time_string) do
    case DateTime.from_iso8601(time_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> time_string
    end
  end
  defp format_time(_), do: "N/A"
end
