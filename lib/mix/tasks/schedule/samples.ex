# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples do
  @moduledoc """
  Demonstrates AriaEngine.Scheduler capabilities with various scheduling samples.
  
  Usage: mix schedule.samples
  """
  
  use Mix.Task
  require Logger
  
  alias AriaEngine.Scheduler
  alias AriaEngine.Scheduler.{Entity, Resource}

  @shortdoc "Run scheduling samples to demonstrate AriaEngine.Scheduler capabilities"

  def run(_args) do
    # Start the application to ensure all dependencies are loaded
    Mix.Task.run("app.start")
    
    IO.puts("\n" <> IO.ANSI.cyan() <> "🚀 AriaEngine.Scheduler Samples" <> IO.ANSI.reset())
    IO.puts(String.duplicate("=", 50))
    
    samples = [
      &sample_1_simple_sequential/0,
      &sample_2_resource_constraints/0,
      &sample_3_complex_dependencies/0,
      &sample_4_entity_capabilities/0,
      &sample_5_simulation_mode/0,
      &sample_6_npc_town_simulation/0
    ]
    
    Enum.with_index(samples, 1)
    |> Enum.each(fn {sample_fn, index} ->
      try do
        sample_fn.()
      rescue
        e ->
          IO.puts(IO.ANSI.red() <> "❌ Sample #{index} failed: #{Exception.message(e)}" <> IO.ANSI.reset())
          IO.puts(Exception.format_stacktrace(__STACKTRACE__))
      end
      
      if index < length(samples) do
        IO.puts("\n" <> String.duplicate("-", 50))
      end
    end)
    
    IO.puts("\n" <> IO.ANSI.green() <> "✅ All samples completed!" <> IO.ANSI.reset())
  end

  defp sample_1_simple_sequential do
    IO.puts("\n" <> IO.ANSI.yellow() <> "📋 Sample 1: Simple Sequential Activities" <> IO.ANSI.reset())
    IO.puts("Demonstrates basic dependency handling and timing calculations")
    
    activities = [
      %{
        "id" => "design",
        "duration" => "PT30M",  # 30 minutes
        "dependencies" => []
      },
      %{
        "id" => "develop", 
        "duration" => "PT2H",   # 2 hours
        "dependencies" => ["design"]
      },
      %{
        "id" => "test",
        "duration" => "PT45M",  # 45 minutes
        "dependencies" => ["develop"]
      },
      %{
        "id" => "deploy",
        "duration" => "PT15M",  # 15 minutes
        "dependencies" => ["test"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities("Website Launch", activities, base_datetime: base_datetime) do
      {:ok, result} ->
        print_schedule_result(result, "Sequential project workflow")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_2_resource_constraints do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔧 Sample 2: Resource-Constrained Scheduling" <> IO.ANSI.reset())
    IO.puts("Demonstrates resource allocation and capacity management")
    
    activities = [
      %{
        "id" => "frontend_task",
        "duration" => "PT1H",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "backend_task",
        "duration" => "PT1H30M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "database_task",
        "duration" => "PT45M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      }
    ]
    
    resources = [
      %Resource{
        id: "developer",
        type: :human,
        capacity: 1,  # Only one developer available
        current_usage: 0
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Resource Constrained Project",
      activities,
      base_datetime: base_datetime,
      resources: resources
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Tasks competing for limited developer resource")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_3_complex_dependencies do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔗 Sample 3: Complex Dependencies" <> IO.ANSI.reset())
    IO.puts("Demonstrates parallel execution and critical path analysis")
    
    activities = [
      %{
        "id" => "requirements",
        "duration" => "PT1H",
        "dependencies" => []
      },
      %{
        "id" => "ui_design",
        "duration" => "PT2H",
        "dependencies" => ["requirements"]
      },
      %{
        "id" => "api_design",
        "duration" => "PT1H30M",
        "dependencies" => ["requirements"]
      },
      %{
        "id" => "frontend_dev",
        "duration" => "PT3H",
        "dependencies" => ["ui_design"]
      },
      %{
        "id" => "backend_dev",
        "duration" => "PT4H",
        "dependencies" => ["api_design"]
      },
      %{
        "id" => "integration",
        "duration" => "PT1H",
        "dependencies" => ["frontend_dev", "backend_dev"]
      },
      %{
        "id" => "testing",
        "duration" => "PT2H",
        "dependencies" => ["integration"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Complex Project",
      activities,
      base_datetime: base_datetime
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Project with parallel tracks and convergence")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_4_entity_capabilities do
    IO.puts("\n" <> IO.ANSI.yellow() <> "👥 Sample 4: Entity and Capability Management" <> IO.ANSI.reset())
    IO.puts("Demonstrates capability-based task assignment")
    
    activities = [
      %{
        "id" => "design_mockups",
        "duration" => "PT2H",
        "dependencies" => [],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "implement_ui",
        "duration" => "PT3H",
        "dependencies" => ["design_mockups"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "write_tests",
        "duration" => "PT1H30M",
        "dependencies" => ["implement_ui"],
        "required_capabilities" => [:testing]
      }
    ]
    
    entities = [
      %Entity{
        id: "alice",
        type: :agent,
        capabilities: [:design, :frontend_coding],
        availability: nil
      },
      %Entity{
        id: "bob",
        type: :agent,
        capabilities: [:frontend_coding, :testing],
        availability: nil
      },
      %Entity{
        id: "charlie",
        type: :agent,
        capabilities: [:testing, :backend_coding],
        availability: nil
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Team Project",
      activities,
      base_datetime: base_datetime,
      entities: entities
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Tasks assigned based on team member capabilities")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_5_simulation_mode do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🎯 Sample 5: Simulation Mode" <> IO.ANSI.reset())
    IO.puts("Demonstrates predictive scheduling without execution")
    
    activities = [
      %{
        "id" => "research",
        "duration" => "PT4H",
        "dependencies" => []
      },
      %{
        "id" => "prototype",
        "duration" => "PT6H",
        "dependencies" => ["research"]
      },
      %{
        "id" => "evaluate",
        "duration" => "PT2H",
        "dependencies" => ["prototype"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.simulate_schedule(
      "Research Project",
      activities,
      base_datetime: base_datetime,
      verbose: 1
    ) do
      {:ok, result} ->
        print_schedule_result(result, "Simulation run - no actual execution")
        IO.puts(IO.ANSI.blue() <> "💡 This was a simulation - no actual work was performed" <> IO.ANSI.reset())
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Simulation failed: #{reason}" <> IO.ANSI.reset())
    end
  end

  defp sample_6_npc_town_simulation do
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
    base_residents =
    [
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
      # For small counts, take a subset of base residents
      Enum.take(base_residents, resident_count)
    else
      # For larger counts, use base residents + generate additional ones
      additional_needed = resident_count - length(base_residents)
      additional_residents = generate_additional_residents(additional_needed)
      base_residents ++ additional_residents
    end
  end

  defp generate_town_resources(resident_count \\ 6) do
    base_resources =
    [
      %Resource{id: "hobbs_cafe", type: :physical, capacity: 20, current_usage: 0},
      %Resource{id: "willow_pharmacy", type: :physical, capacity: 5, current_usage: 0},
      %Resource{id: "oak_hill_college", type: :physical, capacity: 100, current_usage: 0},
      %Resource{id: "town_hall", type: :physical, capacity: 50, current_usage: 0},
      %Resource{id: "art_studio", type: :physical, capacity: 10, current_usage: 0},
      %Resource{id: "library", type: :physical, capacity: 30, current_usage: 0}
    ]
    
    # Scale resources intelligently based on resident count
    resource_count = cond do
      resident_count <= 10 -> max(1, min(resident_count * 2, length(base_resources)))  # Small towns: 1-2 resources per resident
      resident_count <= 100 -> max(length(base_resources), round(resident_count * 0.7))  # Medium towns: 0.5-1 resource per resident
      true -> max(length(base_resources), round(resident_count * 0.3))  # Large cities: 0.2-0.5 resources per resident
    end
    
    if resource_count <= length(base_resources) do
      # For small counts, take a subset of base resources
      Enum.take(base_resources, resource_count)
    else
      # For larger counts, use base resources + generate additional ones
      additional_needed = resource_count - length(base_resources)
      additional_resources = generate_additional_resources(additional_needed)
      base_resources ++ additional_resources
    end
  end

  # Generate emergent opportunities that residents can choose from based on interests and circumstances
  defp generate_emergent_opportunities(resident_count \\ 6) do
    base_opportunities =
    [
      # Essential Business Operations (residents must maintain their livelihoods)
      %{"id" => "operate_cafe", "duration" => "PT8H", "dependencies" => [], 
        "required_capabilities" => [:hospitality], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "essential", "priority" => "high"},
      %{"id" => "operate_pharmacy", "duration" => "PT8H", "dependencies" => [], 
        "required_capabilities" => [:customer_service], "required_resources" => ["willow_pharmacy"],
        "opportunity_type" => "essential", "priority" => "high"},
      
      # Social Gathering Opportunities (emerge when people are in same location)
      %{"id" => "impromptu_cafe_discussion", "duration" => "PT45M", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "social", "trigger_condition" => "multiple_people_present"},
      %{"id" => "political_conversation", "duration" => "PT30M", "dependencies" => [], 
        "required_capabilities" => [:public_speaking], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "social", "trigger_condition" => "political_interest_overlap"},
      %{"id" => "art_appreciation_moment", "duration" => "PT20M", "dependencies" => [], 
        "required_capabilities" => [:aesthetic_appreciation], "required_resources" => ["art_studio"],
        "opportunity_type" => "cultural", "trigger_condition" => "creative_work_visible"},
      
      # Information Sharing Opportunities (spread based on who knows what)
      %{"id" => "share_local_news", "duration" => "PT15M", "dependencies" => [], 
        "required_capabilities" => [:community_networking], 
        "opportunity_type" => "information", "trigger_condition" => "news_to_share"},
      %{"id" => "discuss_community_needs", "duration" => "PT25M", "dependencies" => [], 
        "required_capabilities" => [:community_support], 
        "opportunity_type" => "coordination", "trigger_condition" => "community_concern_identified"},
      
      # Creative Collaboration Opportunities (emerge when artists meet others)
      %{"id" => "collaborative_art_project", "duration" => "PT2H", "dependencies" => [], 
        "required_capabilities" => [:creativity, :aesthetic_appreciation], "required_resources" => ["art_studio"],
        "opportunity_type" => "creative", "trigger_condition" => "creative_synergy"},
      %{"id" => "musical_performance_planning", "duration" => "PT1H", "dependencies" => [], 
        "required_capabilities" => [:music, :event_planning], 
        "opportunity_type" => "creative", "trigger_condition" => "performance_opportunity"},
      
      # Learning and Research Opportunities (driven by curiosity and interests)
      %{"id" => "research_local_history", "duration" => "PT1H30M", "dependencies" => [], 
        "required_capabilities" => [:research], "required_resources" => ["library"],
        "opportunity_type" => "intellectual", "trigger_condition" => "curiosity_sparked"},
      %{"id" => "study_community_dynamics", "duration" => "PT2H", "dependencies" => [], 
        "required_capabilities" => [:academic_work], "required_resources" => ["library"],
        "opportunity_type" => "intellectual", "trigger_condition" => "academic_interest"},
      
      # Community Organization Opportunities (emerge from identified needs)
      %{"id" => "organize_community_event", "duration" => "PT1H", "dependencies" => [], 
        "required_capabilities" => [:event_planning], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "organizing", "trigger_condition" => "community_event_needed"},
      %{"id" => "coordinate_volunteer_effort", "duration" => "PT45M", "dependencies" => [], 
        "required_capabilities" => [:community_organizing], 
        "opportunity_type" => "organizing", "trigger_condition" => "volunteer_opportunity"},
      
      # Political Engagement Opportunities (driven by civic interests)
      %{"id" => "campaign_outreach", "duration" => "PT1H", "dependencies" => [], 
        "required_capabilities" => [:persuasion], "required_resources" => ["willow_pharmacy"],
        "opportunity_type" => "political", "trigger_condition" => "campaign_opportunity"},
      %{"id" => "civic_discussion", "duration" => "PT40M", "dependencies" => [], 
        "required_capabilities" => [:critical_thinking], "required_resources" => ["town_hall"],
        "opportunity_type" => "political", "trigger_condition" => "civic_issue_raised"},
      
      # Spontaneous Social Events (emerge from successful smaller interactions)
      %{"id" => "impromptu_community_gathering", "duration" => "PT2H", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "emergent_event", "trigger_condition" => "social_momentum_builds"},
      %{"id" => "informal_music_session", "duration" => "PT1H", "dependencies" => [], 
        "required_capabilities" => [:creative_performance], "required_resources" => ["hobbs_cafe"],
        "opportunity_type" => "emergent_event", "trigger_condition" => "musical_interest_expressed"},
      
      # Knowledge Exchange Opportunities (when experts meet learners)
      %{"id" => "health_advice_sharing", "duration" => "PT20M", "dependencies" => [], 
        "required_capabilities" => [:health_advice], "required_resources" => ["willow_pharmacy"],
        "opportunity_type" => "knowledge_exchange", "trigger_condition" => "health_question_asked"},
      %{"id" => "academic_mentoring", "duration" => "PT30M", "dependencies" => [], 
        "required_capabilities" => [:education], "required_resources" => ["library"],
        "opportunity_type" => "knowledge_exchange", "trigger_condition" => "learning_opportunity"},
      
      # Serendipitous Encounters (chance meetings that lead to new connections)
      %{"id" => "chance_encounter_conversation", "duration" => "PT15M", "dependencies" => [], 
        "required_capabilities" => [:social_coordination], 
        "opportunity_type" => "serendipitous", "trigger_condition" => "unexpected_meeting"},
      %{"id" => "discover_shared_interest", "duration" => "PT25M", "dependencies" => [], 
        "required_capabilities" => [:community_networking], 
        "opportunity_type" => "serendipitous", "trigger_condition" => "interest_alignment_discovered"}
    ]
    
    # Scale opportunities intelligently based on resident count
    opportunity_count = cond do
      resident_count <= 5 -> max(1, min(resident_count * 4, length(base_opportunities)))  # Small towns: 3-4 opportunities per resident
      resident_count <= 50 -> max(length(base_opportunities), round(resident_count * 2.5))  # Medium towns: 2-3 opportunities per resident
      true -> max(length(base_opportunities), round(resident_count * 1.5))  # Large cities: 1-2 opportunities per resident
    end
    
    if opportunity_count <= length(base_opportunities) do
      # For small counts, take a subset of base opportunities
      Enum.take(base_opportunities, opportunity_count)
    else
      # For larger counts, use base opportunities + generate additional ones
      additional_needed = opportunity_count - length(base_opportunities)
      additional_opportunities = generate_additional_opportunities(additional_needed)
      base_opportunities ++ additional_opportunities
    end
  end

  # Generate additional residents for scaling up
  defp generate_additional_residents(count) do
    base_names = ["alex", "taylor", "jordan", "casey", "riley", "morgan", "avery", "quinn", "sage", "river"]
    occupations = ["Teacher", "Engineer", "Writer", "Chef", "Musician", "Nurse", "Mechanic", "Designer"]
    
    1..count
    |> Enum.map(fn i ->
      name = Enum.at(base_names, rem(i - 1, length(base_names)))
      occupation = Enum.at(occupations, rem(i - 1, length(occupations)))
      
      %Entity{
        id: "#{name}_#{i}",
        type: :resident,
        capabilities: Enum.take_random([:hospitality, :customer_service, :research, :art, :leadership, :music], 3),
        availability: nil,
        metadata: %{
          occupation: occupation,
          personality: "Community member",
          interests: Enum.take_random([:local_politics, :community_events, :art, :music, :research], 2),
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
      %{"id" => "community_workshop", "duration" => "PT2H", "opportunity_type" => "learning"},
      %{"id" => "neighborhood_meeting", "duration" => "PT1H", "opportunity_type" => "organizing"},
      %{"id" => "cultural_exchange", "duration" => "PT1H30M", "opportunity_type" => "cultural"},
      %{"id" => "skill_sharing", "duration" => "PT45M", "opportunity_type" => "knowledge_exchange"},
      %{"id" => "social_gathering", "duration" => "PT2H", "opportunity_type" => "social"}
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
      IO.puts("\n📅 Schedule (First 10 activities):")
      
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
        
        IO.puts("  • #{id}: #{start_formatted} → #{end_formatted} (#{duration})")
      end)
      
      if length(result.schedule) > 10 do
        IO.puts("  • ... and #{length(result.schedule) - 10} more activities")
      end
    end
    
    if result.simulation_metadata do
      IO.puts("\n🔍 Simulation Metadata:")
      IO.puts("  • Generated at: #{format_time(result.simulation_metadata.generated_at)}")
      IO.puts("  • Entities count: #{result.simulation_metadata.entities_count}")
      IO.puts("  • Resources count: #{result.simulation_metadata.resources_count}")
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
    
    # Trace one person's schedule through the day
    print_individual_schedule_trace(result, entities)
  end
  
  defp print_individual_schedule_trace(result, entities) do
    # Randomly select a resident to trace (but keep the schedule generation deterministic)
    target_resident = entities |> Enum.random()
    
    if target_resident && result.schedule do
      IO.puts("\n👤 Individual Schedule Trace: #{target_resident.id}")
      IO.puts("   Occupation: #{target_resident.metadata.occupation}")
      IO.puts("   Personality: #{target_resident.metadata.personality}")
      IO.puts("   Social Magnetism: #{target_resident.metadata.social_magnetism}")
      IO.puts("   Interests: #{Enum.join(target_resident.metadata.interests, ", ")}")
      
      # Find activities that this resident could participate in based on capabilities
      resident_activities = result.schedule
      |> Enum.filter(fn activity ->
        required_caps = get_activity_field(activity, "required_capabilities") || []
        resident_caps = target_resident.capabilities
        
        # Check if resident has any of the required capabilities
        case required_caps do
          [] -> true  # No specific capabilities required
          caps when is_list(caps) -> 
            Enum.any?(caps, fn cap -> 
              cap_atom = if is_atom(cap), do: cap, else: String.to_atom(to_string(cap))
              cap_atom in resident_caps
            end)
          _ -> false
        end
      end)
      |> Enum.sort_by(fn activity -> 
        get_activity_field(activity, "start_time") || "1970-01-01T00:00:00Z"
      end)
      
      IO.puts("\n📅 Potential Daily Schedule:")
      if length(resident_activities) > 0 do
        resident_activities
        |> Enum.each(fn activity ->
          id = get_activity_field(activity, "id")
          start_time = get_activity_field(activity, "start_time")
          end_time = get_activity_field(activity, "end_time")
          duration = get_activity_field(activity, "duration")
          opportunity_type = get_activity_field(activity, "opportunity_type") || "general"
          
          start_formatted = format_time(start_time)
          end_formatted = format_time(end_time)
          
          # Add context about why this activity fits the resident
          context = get_activity_context(id, opportunity_type, target_resident)
          
          IO.puts("   #{start_formatted}-#{end_formatted} | #{String.pad_trailing(id, 30)} | #{duration}")
          IO.puts("      └─ #{context}")
        end)
        
        IO.puts("\n🎭 Behavioral Analysis:")
        analyze_resident_behavior(resident_activities, target_resident)
      else
        IO.puts("   No activities found matching resident's capabilities")
      end
    end
  end
  
  defp get_activity_context(activity_id, opportunity_type, _resident) do
    case {activity_id, opportunity_type} do
      {"operate_cafe", "essential"} -> 
        "Essential work - running Hobbs Cafe (matches hospitality capability)"
      {"impromptu_cafe_discussion", "social"} -> 
        "Social coordination opportunity (high social magnetism + community focus)"
      {"political_conversation", "social"} -> 
        "Political discussion (matches local politics interest)"
      {"organize_community_event", "organizing"} -> 
        "Event planning opportunity (matches event_planning capability + community focus)"
      {"impromptu_community_gathering", "emergent_event"} -> 
        "Emergent social event (high social magnetism draws people together)"
      {"share_local_news", "information"} -> 
        "Information sharing (community networking capability)"
      {_, "creative"} -> 
        "Creative opportunity (community-minded personality)"
      {_, "political"} -> 
        "Political engagement (local politics interest)"
      {_, "social"} -> 
        "Social interaction (outgoing personality + high social magnetism)"
      {_, "organizing"} -> 
        "Community organizing (event planning + social coordination capabilities)"
      _ -> 
        "General community activity (#{opportunity_type})"
    end
  end
  
  defp analyze_resident_behavior(activities, resident) do
    # Analyze activity patterns
    activity_types = activities
    |> Enum.map(fn activity -> get_activity_field(activity, "opportunity_type") || "general" end)
    |> Enum.frequencies()
    
    total_activities = length(activities)
    
    IO.puts("   • Total potential activities: #{total_activities}")
    IO.puts("   • Activity type distribution:")
    
    activity_types
    |> Enum.sort_by(fn {_type, count} -> count end, :desc)
    |> Enum.each(fn {type, count} ->
      percentage = round(count / total_activities * 100)
      IO.puts("     - #{type}: #{count} activities (#{percentage}%)")
    end)
    
    # Analyze time distribution
    work_activities = Enum.count(activities, fn activity -> 
      get_activity_field(activity, "opportunity_type") == "essential"
    end)
    
    social_activities = Enum.count(activities, fn activity -> 
      type = get_activity_field(activity, "opportunity_type")
      type in ["social", "emergent_event", "organizing"]
    end)
    
    IO.puts("\n   🎯 Behavioral Insights:")
    IO.puts("     - Work/Essential activities: #{work_activities}")
    IO.puts("     - Social/Community activities: #{social_activities}")
    
    if social_activities > work_activities do
      IO.puts("     - Profile: Community-focused social coordinator")
    else
      IO.puts("     - Profile: Balanced work-life integration")
    end
    
    if resident.metadata.social_magnetism == :high do
      IO.puts("     - Social role: Natural gathering point for community interactions")
    end
  end

  defp print_schedule_result(result, description) do
    IO.puts("\n" <> IO.ANSI.green() <> "✅ #{description}" <> IO.ANSI.reset())
    IO.puts("Status: #{result.status}")
    IO.puts("Reason: #{result.reason}")
    
    if result.analysis do
      IO.puts("\n📊 Analysis:")
      IO.puts("  • Activities analyzed: #{result.analysis.activities_analyzed}")
      IO.puts("  • Dependencies found: #{result.analysis.dependencies_found}")
      IO.puts("  • Resource conflicts: #{result.analysis.resource_conflicts}")
      IO.puts("  • Critical path length: #{result.analysis.critical_path_length}")
      IO.puts("  • Method: #{result.analysis.method}")
    end
    
    if result.schedule && length(result.schedule) > 0 do
      IO.puts("\n📅 Schedule:")
      
      result.schedule
      |> Enum.sort_by(fn activity -> 
        case activity do
          %{start_time: start_time} when is_binary(start_time) -> start_time
          %{"start_time" => start_time} when is_binary(start_time) -> start_time
          _ -> "1970-01-01T00:00:00Z"
        end
      end)
      |> Enum.each(fn activity ->
        id = get_activity_field(activity, "id")
        start_time = get_activity_field(activity, "start_time")
        end_time = get_activity_field(activity, "end_time")
        duration = get_activity_field(activity, "duration")
        
        start_formatted = format_time(start_time)
        end_formatted = format_time(end_time)
        
        IO.puts("  • #{id}: #{start_formatted} → #{end_formatted} (#{duration})")
      end)
    else
      IO.puts("\n📅 Schedule: Empty (no activities to schedule)")
    end
    
    if result.simulation_metadata do
      IO.puts("\n🔍 Simulation Metadata:")
      IO.puts("  • Generated at: #{format_time(result.simulation_metadata.generated_at)}")
      IO.puts("  • Entities count: #{result.simulation_metadata.entities_count}")
      IO.puts("  • Resources count: #{result.simulation_metadata.resources_count}")
    end
  end

  defp get_activity_field(activity, field) when is_map(activity) do
    # Handle both atom and string keys
    atom_field = if is_atom(field), do: field, else: String.to_atom(field)
    string_field = to_string(field)
    
    case activity do
      %{^atom_field => value} -> value
      %{^string_field => value} -> value
      _ -> 
        # Try accessing with both atom and string keys
        Map.get(activity, atom_field, Map.get(activity, string_field, "N/A"))
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
