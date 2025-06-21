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
      # Research Phase Activities
      %{
        "id" => "define_research_questions",
        "duration" => "PT6M",
        "dependencies" => []
      },
      %{
        "id" => "conduct_literature_review_phase1",
        "duration" => "PT6M",
        "dependencies" => ["define_research_questions"]
      },
      %{
        "id" => "conduct_literature_review_phase2",
        "duration" => "PT6M",
        "dependencies" => ["conduct_literature_review_phase1"]
      },
      %{
        "id" => "identify_research_gaps",
        "duration" => "PT5M",
        "dependencies" => ["conduct_literature_review_phase2"]
      },
      %{
        "id" => "analyze_existing_solutions",
        "duration" => "PT6M",
        "dependencies" => ["identify_research_gaps"]
      },
      %{
        "id" => "evaluate_methodologies",
        "duration" => "PT5M",
        "dependencies" => ["analyze_existing_solutions"]
      },
      %{
        "id" => "document_research_findings",
        "duration" => "PT6M",
        "dependencies" => ["evaluate_methodologies"]
      },
      %{
        "id" => "create_research_summary",
        "duration" => "PT4M",
        "dependencies" => ["document_research_findings"]
      },
      %{
        "id" => "identify_key_requirements",
        "duration" => "PT5M",
        "dependencies" => ["create_research_summary"]
      },
      %{
        "id" => "define_success_criteria",
        "duration" => "PT4M",
        "dependencies" => ["identify_key_requirements"]
      },
      %{
        "id" => "establish_research_constraints",
        "duration" => "PT3M",
        "dependencies" => ["define_success_criteria"]
      },
      %{
        "id" => "finalize_research_scope",
        "duration" => "PT4M",
        "dependencies" => ["establish_research_constraints"]
      },
      
      # Prototype Development Activities
      %{
        "id" => "design_prototype_architecture",
        "duration" => "PT6M",
        "dependencies" => ["finalize_research_scope"]
      },
      %{
        "id" => "select_development_tools",
        "duration" => "PT4M",
        "dependencies" => ["design_prototype_architecture"]
      },
      %{
        "id" => "setup_development_environment",
        "duration" => "PT5M",
        "dependencies" => ["select_development_tools"]
      },
      %{
        "id" => "implement_core_functionality",
        "duration" => "PT6M",
        "dependencies" => ["setup_development_environment"]
      },
      %{
        "id" => "create_user_interface_mockup",
        "duration" => "PT6M",
        "dependencies" => ["implement_core_functionality"]
      },
      %{
        "id" => "implement_basic_interactions",
        "duration" => "PT6M",
        "dependencies" => ["create_user_interface_mockup"]
      },
      %{
        "id" => "add_data_processing_logic",
        "duration" => "PT6M",
        "dependencies" => ["implement_basic_interactions"]
      },
      %{
        "id" => "implement_algorithm_prototype",
        "duration" => "PT6M",
        "dependencies" => ["add_data_processing_logic"]
      },
      %{
        "id" => "create_test_data_sets",
        "duration" => "PT5M",
        "dependencies" => ["implement_algorithm_prototype"]
      },
      %{
        "id" => "integrate_components",
        "duration" => "PT6M",
        "dependencies" => ["create_test_data_sets"]
      },
      %{
        "id" => "perform_initial_testing",
        "duration" => "PT5M",
        "dependencies" => ["integrate_components"]
      },
      %{
        "id" => "debug_critical_issues",
        "duration" => "PT6M",
        "dependencies" => ["perform_initial_testing"]
      },
      %{
        "id" => "optimize_performance_bottlenecks",
        "duration" => "PT6M",
        "dependencies" => ["debug_critical_issues"]
      },
      %{
        "id" => "document_prototype_features",
        "duration" => "PT4M",
        "dependencies" => ["optimize_performance_bottlenecks"]
      },
      %{
        "id" => "prepare_demonstration_scenarios",
        "duration" => "PT5M",
        "dependencies" => ["document_prototype_features"]
      },
      %{
        "id" => "create_prototype_documentation",
        "duration" => "PT6M",
        "dependencies" => ["prepare_demonstration_scenarios"]
      },
      
      # Evaluation Activities
      %{
        "id" => "design_evaluation_framework",
        "duration" => "PT6M",
        "dependencies" => ["create_prototype_documentation"]
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
      %{
        "id" => "run_performance_benchmarks",
        "duration" => "PT6M",
        "dependencies" => ["create_benchmark_tests"]
      },
      %{
        "id" => "conduct_usability_evaluation",
        "duration" => "PT6M",
        "dependencies" => ["run_performance_benchmarks"]
      },
      %{
        "id" => "analyze_accuracy_metrics",
        "duration" => "PT5M",
        "dependencies" => ["conduct_usability_evaluation"]
      },
      %{
        "id" => "compare_with_existing_solutions",
        "duration" => "PT6M",
        "dependencies" => ["analyze_accuracy_metrics"]
      },
      %{
        "id" => "identify_improvement_areas",
        "duration" => "PT5M",
        "dependencies" => ["compare_with_existing_solutions"]
      },
      %{
        "id" => "document_evaluation_results",
        "duration" => "PT6M",
        "dependencies" => ["identify_improvement_areas"]
      },
      %{
        "id" => "create_findings_summary",
        "duration" => "PT4M",
        "dependencies" => ["document_evaluation_results"]
      },
      %{
        "id" => "prepare_recommendations",
        "duration" => "PT5M",
        "dependencies" => ["create_findings_summary"]
      },
      %{
        "id" => "finalize_evaluation_report",
        "duration" => "PT6M",
        "dependencies" => ["prepare_recommendations"]
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
        Helpers.print_schedule_result(result, "Simulation run - no actual execution")
        IO.puts(IO.ANSI.blue() <> "💡 This was a simulation - no actual work was performed" <> IO.ANSI.reset())
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Simulation failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
