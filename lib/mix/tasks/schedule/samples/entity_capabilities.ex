# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.EntityCapabilities do
  @moduledoc """
  Sample 4: Entity and Capability Management
  Demonstrates capability-based task assignment with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias AriaEngine.Scheduler.Entity
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "👥 Sample 4: Entity and Capability Management" <> IO.ANSI.reset())
    IO.puts("Demonstrates capability-based task assignment")
    
    activities = [
      # Design Phase Activities
      %{
        "id" => "research_design_trends",
        "duration" => "PT6M",
        "dependencies" => [],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "create_mood_boards",
        "duration" => "PT5M",
        "dependencies" => ["research_design_trends"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "sketch_initial_concepts",
        "duration" => "PT6M",
        "dependencies" => ["create_mood_boards"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "develop_color_palette",
        "duration" => "PT4M",
        "dependencies" => ["sketch_initial_concepts"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "create_typography_system",
        "duration" => "PT5M",
        "dependencies" => ["develop_color_palette"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "design_component_library",
        "duration" => "PT6M",
        "dependencies" => ["create_typography_system"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "create_high_fidelity_mockups",
        "duration" => "PT6M",
        "dependencies" => ["design_component_library"],
        "required_capabilities" => [:design]
      },
      %{
        "id" => "prepare_design_handoff",
        "duration" => "PT4M",
        "dependencies" => ["create_high_fidelity_mockups"],
        "required_capabilities" => [:design]
      },
      
      # Frontend Development Activities
      %{
        "id" => "setup_development_environment",
        "duration" => "PT4M",
        "dependencies" => ["prepare_design_handoff"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "configure_build_tools",
        "duration" => "PT5M",
        "dependencies" => ["setup_development_environment"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "implement_base_components",
        "duration" => "PT6M",
        "dependencies" => ["configure_build_tools"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "create_layout_structure",
        "duration" => "PT6M",
        "dependencies" => ["implement_base_components"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "implement_navigation_system",
        "duration" => "PT5M",
        "dependencies" => ["create_layout_structure"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "add_interactive_elements",
        "duration" => "PT6M",
        "dependencies" => ["implement_navigation_system"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "implement_responsive_behavior",
        "duration" => "PT6M",
        "dependencies" => ["add_interactive_elements"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "optimize_performance",
        "duration" => "PT5M",
        "dependencies" => ["implement_responsive_behavior"],
        "required_capabilities" => [:frontend_coding]
      },
      %{
        "id" => "add_accessibility_features",
        "duration" => "PT6M",
        "dependencies" => ["optimize_performance"],
        "required_capabilities" => [:frontend_coding]
      },
      
      # Testing Activities
      %{
        "id" => "setup_testing_framework",
        "duration" => "PT4M",
        "dependencies" => ["add_accessibility_features"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "write_component_unit_tests",
        "duration" => "PT6M",
        "dependencies" => ["setup_testing_framework"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "create_integration_tests",
        "duration" => "PT6M",
        "dependencies" => ["write_component_unit_tests"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "implement_visual_regression_tests",
        "duration" => "PT5M",
        "dependencies" => ["create_integration_tests"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "setup_automated_testing_pipeline",
        "duration" => "PT6M",
        "dependencies" => ["implement_visual_regression_tests"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "perform_cross_browser_testing",
        "duration" => "PT6M",
        "dependencies" => ["setup_automated_testing_pipeline"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "conduct_accessibility_testing",
        "duration" => "PT5M",
        "dependencies" => ["perform_cross_browser_testing"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "run_performance_testing",
        "duration" => "PT6M",
        "dependencies" => ["conduct_accessibility_testing"],
        "required_capabilities" => [:testing]
      },
      %{
        "id" => "generate_test_reports",
        "duration" => "PT4M",
        "dependencies" => ["run_performance_testing"],
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
        Helpers.print_schedule_result(result, "Tasks assigned based on team member capabilities")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
