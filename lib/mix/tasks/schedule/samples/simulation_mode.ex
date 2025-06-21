# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.SimulationMode do
  @moduledoc """
  Sample 5: Simulation Mode
  Demonstrates predictive scheduling without execution with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🎯 Sample 5: Simulation Mode" <> IO.ANSI.reset())
    IO.puts("Demonstrates predictive scheduling without execution")
    
    activities = [
      # Independent Setup Activities (can run in parallel)
      %{
        "id" => "setup_development_environment",
        "duration" => "PT5M",
        "dependencies" => []
      },
      %{
        "id" => "configure_project_tools",
        "duration" => "PT4M",
        "dependencies" => []
      },
      %{
        "id" => "setup_version_control",
        "duration" => "PT3M",
        "dependencies" => []
      },
      %{
        "id" => "install_dependencies",
        "duration" => "PT4M",
        "dependencies" => []
      },
      
      # Research Track (parallel to other tracks)
      %{
        "id" => "define_research_questions",
        "duration" => "PT6M",
        "dependencies" => []
      },
      %{
        "id" => "conduct_literature_review",
        "duration" => "PT6M",
        "dependencies" => ["define_research_questions"]
      },
      %{
        "id" => "analyze_existing_solutions",
        "duration" => "PT6M",
        "dependencies" => ["conduct_literature_review"]
      },
      %{
        "id" => "document_research_findings",
        "duration" => "PT5M",
        "dependencies" => ["analyze_existing_solutions"]
      },
      
      # Architecture Track (parallel to research)
      %{
        "id" => "design_system_architecture",
        "duration" => "PT6M",
        "dependencies" => ["setup_development_environment"]
      },
      %{
        "id" => "define_component_interfaces",
        "duration" => "PT5M",
        "dependencies" => ["design_system_architecture"]
      },
      %{
        "id" => "create_data_models",
        "duration" => "PT6M",
        "dependencies" => ["define_component_interfaces"]
      },
      %{
        "id" => "design_api_specifications",
        "duration" => "PT5M",
        "dependencies" => ["create_data_models"]
      },
      
      # Core Development Track
      %{
        "id" => "implement_core_functionality",
        "duration" => "PT6M",
        "dependencies" => ["design_api_specifications", "install_dependencies"]
      },
      %{
        "id" => "add_data_processing_logic",
        "duration" => "PT6M",
        "dependencies" => ["implement_core_functionality"]
      },
      %{
        "id" => "implement_algorithm_prototype",
        "duration" => "PT6M",
        "dependencies" => ["add_data_processing_logic"]
      },
      %{
        "id" => "optimize_performance",
        "duration" => "PT5M",
        "dependencies" => ["implement_algorithm_prototype"]
      },
      
      # UI Development Track (parallel to core development)
      %{
        "id" => "create_ui_mockups",
        "duration" => "PT6M",
        "dependencies" => ["configure_project_tools"]
      },
      %{
        "id" => "implement_user_interface",
        "duration" => "PT6M",
        "dependencies" => ["create_ui_mockups"]
      },
      %{
        "id" => "add_interactive_elements",
        "duration" => "PT6M",
        "dependencies" => ["implement_user_interface"]
      },
      %{
        "id" => "implement_responsive_design",
        "duration" => "PT5M",
        "dependencies" => ["add_interactive_elements"]
      },
      
      # Testing Track (can start early and run parallel)
      %{
        "id" => "setup_testing_framework",
        "duration" => "PT4M",
        "dependencies" => ["setup_version_control"]
      },
      %{
        "id" => "create_test_data_sets",
        "duration" => "PT5M",
        "dependencies" => ["setup_testing_framework"]
      },
      %{
        "id" => "write_unit_tests",
        "duration" => "PT6M",
        "dependencies" => ["create_test_data_sets"]
      },
      %{
        "id" => "write_integration_tests",
        "duration" => "PT6M",
        "dependencies" => ["write_unit_tests"]
      },
      
      # Integration Phase (convergence point)
      %{
        "id" => "integrate_ui_with_backend",
        "duration" => "PT6M",
        "dependencies" => ["optimize_performance", "implement_responsive_design"]
      },
      %{
        "id" => "run_integration_tests",
        "duration" => "PT5M",
        "dependencies" => ["integrate_ui_with_backend", "write_integration_tests"]
      },
      %{
        "id" => "debug_integration_issues",
        "duration" => "PT6M",
        "dependencies" => ["run_integration_tests"]
      },
      
      # Evaluation Track (parallel to integration)
      %{
        "id" => "design_evaluation_framework",
        "duration" => "PT6M",
        "dependencies" => ["document_research_findings"]
      },
      %{
        "id" => "define_evaluation_metrics",
        "duration" => "PT5M",
        "dependencies" => ["design_evaluation_framework"]
      },
      %{
        "id" => "create_benchmark_tests",
        "duration" => "PT6M",
        "dependencies" => ["define_evaluation_metrics"]
      },
      
      # Final Evaluation Phase (convergence point)
      %{
        "id" => "run_performance_benchmarks",
        "duration" => "PT6M",
        "dependencies" => ["debug_integration_issues", "create_benchmark_tests"]
      },
      %{
        "id" => "conduct_usability_evaluation",
        "duration" => "PT6M",
        "dependencies" => ["run_performance_benchmarks"]
      },
      %{
        "id" => "analyze_results",
        "duration" => "PT5M",
        "dependencies" => ["conduct_usability_evaluation"]
      },
      
      # Documentation Track (can run parallel to development)
      %{
        "id" => "write_technical_documentation",
        "duration" => "PT6M",
        "dependencies" => ["design_api_specifications"]
      },
      %{
        "id" => "create_user_documentation",
        "duration" => "PT5M",
        "dependencies" => ["implement_responsive_design"]
      },
      %{
        "id" => "prepare_demonstration_materials",
        "duration" => "PT5M",
        "dependencies" => ["write_technical_documentation", "create_user_documentation"]
      },
      
      # Final Deliverables
      %{
        "id" => "compile_final_report",
        "duration" => "PT6M",
        "dependencies" => ["analyze_results", "prepare_demonstration_materials"]
      },
      %{
        "id" => "prepare_presentation",
        "duration" => "PT5M",
        "dependencies" => ["compile_final_report"]
      },
      
      # Independent Maintenance Activities (time fillers)
      %{
        "id" => "code_review_session",
        "duration" => "PT4M",
        "dependencies" => []
      },
      %{
        "id" => "update_project_dependencies",
        "duration" => "PT3M",
        "dependencies" => []
      },
      %{
        "id" => "refactor_code_structure",
        "duration" => "PT5M",
        "dependencies" => []
      },
      %{
        "id" => "optimize_build_process",
        "duration" => "PT4M",
        "dependencies" => []
      },
      %{
        "id" => "security_audit",
        "duration" => "PT5M",
        "dependencies" => []
      },
      %{
        "id" => "performance_profiling",
        "duration" => "PT4M",
        "dependencies" => []
      },
      %{
        "id" => "backup_project_data",
        "duration" => "PT3M",
        "dependencies" => []
      },
      %{
        "id" => "update_documentation_links",
        "duration" => "PT3M",
        "dependencies" => []
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Research Project",
      activities,
      base_datetime: base_datetime
    ) do
      {:ok, result} ->
        Helpers.print_schedule_result(result, "Simulation run - no actual execution")
        IO.puts(IO.ANSI.blue() <> "💡 This was a simulation - no actual work was performed" <> IO.ANSI.reset())
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Simulation failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
