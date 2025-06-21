# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.ComplexDependencies do
  @moduledoc """
  Sample 3: Complex Dependencies
  Demonstrates parallel execution and critical path analysis with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔗 Sample 3: Complex Dependencies" <> IO.ANSI.reset())
    IO.puts("Demonstrates parallel execution and critical path analysis")
    
    activities = [
      # Requirements Analysis Phase
      %{
        "id" => "gather_stakeholder_input",
        "duration" => "PT6M",
        "dependencies" => []
      },
      %{
        "id" => "document_functional_requirements",
        "duration" => "PT6M",
        "dependencies" => ["gather_stakeholder_input"]
      },
      %{
        "id" => "define_non_functional_requirements",
        "duration" => "PT5M",
        "dependencies" => ["gather_stakeholder_input"]
      },
      %{
        "id" => "create_requirements_matrix",
        "duration" => "PT4M",
        "dependencies" => ["document_functional_requirements", "define_non_functional_requirements"]
      },
      
      # UI Design Track (Parallel)
      %{
        "id" => "create_user_personas",
        "duration" => "PT6M",
        "dependencies" => ["create_requirements_matrix"]
      },
      %{
        "id" => "design_user_journey_maps",
        "duration" => "PT6M",
        "dependencies" => ["create_user_personas"]
      },
      %{
        "id" => "create_wireframe_sketches",
        "duration" => "PT5M",
        "dependencies" => ["design_user_journey_maps"]
      },
      %{
        "id" => "develop_interactive_prototypes",
        "duration" => "PT6M",
        "dependencies" => ["create_wireframe_sketches"]
      },
      %{
        "id" => "conduct_usability_testing",
        "duration" => "PT6M",
        "dependencies" => ["develop_interactive_prototypes"]
      },
      %{
        "id" => "refine_ui_based_on_feedback",
        "duration" => "PT5M",
        "dependencies" => ["conduct_usability_testing"]
      },
      %{
        "id" => "create_final_ui_specifications",
        "duration" => "PT4M",
        "dependencies" => ["refine_ui_based_on_feedback"]
      },
      
      # API Design Track (Parallel)
      %{
        "id" => "identify_data_entities",
        "duration" => "PT5M",
        "dependencies" => ["create_requirements_matrix"]
      },
      %{
        "id" => "design_database_schema",
        "duration" => "PT6M",
        "dependencies" => ["identify_data_entities"]
      },
      %{
        "id" => "define_api_endpoints",
        "duration" => "PT6M",
        "dependencies" => ["design_database_schema"]
      },
      %{
        "id" => "create_api_documentation",
        "duration" => "PT5M",
        "dependencies" => ["define_api_endpoints"]
      },
      %{
        "id" => "design_authentication_flow",
        "duration" => "PT6M",
        "dependencies" => ["define_api_endpoints"]
      },
      %{
        "id" => "plan_error_handling_strategy",
        "duration" => "PT4M",
        "dependencies" => ["create_api_documentation", "design_authentication_flow"]
      },
      
      # Frontend Development Track
      %{
        "id" => "setup_frontend_build_system",
        "duration" => "PT4M",
        "dependencies" => ["create_final_ui_specifications"]
      },
      %{
        "id" => "create_component_library",
        "duration" => "PT6M",
        "dependencies" => ["setup_frontend_build_system"]
      },
      %{
        "id" => "implement_main_layout",
        "duration" => "PT6M",
        "dependencies" => ["create_component_library"]
      },
      %{
        "id" => "build_user_authentication_ui",
        "duration" => "PT6M",
        "dependencies" => ["implement_main_layout"]
      },
      %{
        "id" => "implement_data_display_components",
        "duration" => "PT6M",
        "dependencies" => ["build_user_authentication_ui"]
      },
      %{
        "id" => "add_form_validation",
        "duration" => "PT5M",
        "dependencies" => ["implement_data_display_components"]
      },
      %{
        "id" => "implement_responsive_design",
        "duration" => "PT6M",
        "dependencies" => ["add_form_validation"]
      },
      
      # Backend Development Track
      %{
        "id" => "setup_backend_framework",
        "duration" => "PT4M",
        "dependencies" => ["plan_error_handling_strategy"]
      },
      %{
        "id" => "implement_database_models",
        "duration" => "PT6M",
        "dependencies" => ["setup_backend_framework"]
      },
      %{
        "id" => "create_authentication_middleware",
        "duration" => "PT6M",
        "dependencies" => ["implement_database_models"]
      },
      %{
        "id" => "implement_user_management_endpoints",
        "duration" => "PT6M",
        "dependencies" => ["create_authentication_middleware"]
      },
      %{
        "id" => "build_data_crud_operations",
        "duration" => "PT6M",
        "dependencies" => ["implement_user_management_endpoints"]
      },
      %{
        "id" => "add_input_validation",
        "duration" => "PT5M",
        "dependencies" => ["build_data_crud_operations"]
      },
      %{
        "id" => "implement_error_handling",
        "duration" => "PT5M",
        "dependencies" => ["add_input_validation"]
      },
      %{
        "id" => "add_logging_and_monitoring",
        "duration" => "PT4M",
        "dependencies" => ["implement_error_handling"]
      },
      
      # Integration Phase (Convergence Point)
      %{
        "id" => "connect_frontend_to_backend",
        "duration" => "PT5M",
        "dependencies" => ["implement_responsive_design", "add_logging_and_monitoring"]
      },
      %{
        "id" => "test_api_integration",
        "duration" => "PT6M",
        "dependencies" => ["connect_frontend_to_backend"]
      },
      %{
        "id" => "fix_integration_issues",
        "duration" => "PT5M",
        "dependencies" => ["test_api_integration"]
      },
      %{
        "id" => "optimize_data_flow",
        "duration" => "PT4M",
        "dependencies" => ["fix_integration_issues"]
      },
      
      # Testing Phase
      %{
        "id" => "write_unit_tests_frontend",
        "duration" => "PT6M",
        "dependencies" => ["optimize_data_flow"]
      },
      %{
        "id" => "write_unit_tests_backend",
        "duration" => "PT6M",
        "dependencies" => ["optimize_data_flow"]
      },
      %{
        "id" => "create_integration_test_suite",
        "duration" => "PT6M",
        "dependencies" => ["write_unit_tests_frontend", "write_unit_tests_backend"]
      },
      %{
        "id" => "run_performance_tests",
        "duration" => "PT5M",
        "dependencies" => ["create_integration_test_suite"]
      },
      %{
        "id" => "conduct_security_testing",
        "duration" => "PT6M",
        "dependencies" => ["create_integration_test_suite"]
      },
      %{
        "id" => "perform_user_acceptance_testing",
        "duration" => "PT6M",
        "dependencies" => ["run_performance_tests", "conduct_security_testing"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities(
      "Complex Project",
      activities,
      base_datetime: base_datetime
    ) do
      {:ok, result} ->
        Helpers.print_schedule_result(result, "Project with parallel tracks and convergence")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
