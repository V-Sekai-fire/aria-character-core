# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.Sequential do
  @moduledoc """
  Sample 1: Simple Sequential Activities
  Demonstrates basic dependency handling and timing calculations with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "📋 Sample 1: Simple Sequential Activities" <> IO.ANSI.reset())
    IO.puts("Demonstrates basic dependency handling and timing calculations")
    
    activities = [
      %{
        "id" => "sketch_initial_layout",
        "duration" => "PT5M",
        "dependencies" => []
      },
      %{
        "id" => "define_navigation_structure",
        "duration" => "PT4M",
        "dependencies" => ["sketch_initial_layout"]
      },
      %{
        "id" => "create_component_wireframes",
        "duration" => "PT6M",
        "dependencies" => ["define_navigation_structure"]
      },
      %{
        "id" => "review_wireframe_flow",
        "duration" => "PT3M",
        "dependencies" => ["create_component_wireframes"]
      },
      %{
        "id" => "initialize_project_folders", 
        "duration" => "PT3M",
        "dependencies" => ["review_wireframe_flow"]
      },
      %{
        "id" => "setup_build_configuration", 
        "duration" => "PT4M",
        "dependencies" => ["initialize_project_folders"]
      },
      %{
        "id" => "install_dependencies", 
        "duration" => "PT5M",
        "dependencies" => ["setup_build_configuration"]
      },
      %{
        "id" => "configure_development_environment", 
        "duration" => "PT3M",
        "dependencies" => ["install_dependencies"]
      },
      %{
        "id" => "setup_auth_dependencies", 
        "duration" => "PT3M",
        "dependencies" => ["configure_development_environment"]
      },
      %{
        "id" => "create_login_form", 
        "duration" => "PT6M",
        "dependencies" => ["setup_auth_dependencies"]
      },
      %{
        "id" => "implement_password_validation", 
        "duration" => "PT5M",
        "dependencies" => ["create_login_form"]
      },
      %{
        "id" => "add_session_management", 
        "duration" => "PT6M",
        "dependencies" => ["implement_password_validation"]
      },
      %{
        "id" => "design_database_tables", 
        "duration" => "PT6M",
        "dependencies" => ["configure_development_environment"]
      },
      %{
        "id" => "write_migration_scripts", 
        "duration" => "PT5M",
        "dependencies" => ["design_database_tables"]
      },
      %{
        "id" => "setup_database_connections", 
        "duration" => "PT4M",
        "dependencies" => ["write_migration_scripts"]
      },
      %{
        "id" => "test_database_connectivity", 
        "duration" => "PT3M",
        "dependencies" => ["setup_database_connections"]
      },
      %{
        "id" => "create_main_layout_component", 
        "duration" => "PT6M",
        "dependencies" => ["add_session_management", "test_database_connectivity"]
      },
      %{
        "id" => "implement_navigation_menu", 
        "duration" => "PT5M",
        "dependencies" => ["create_main_layout_component"]
      },
      %{
        "id" => "add_responsive_styling", 
        "duration" => "PT6M",
        "dependencies" => ["implement_navigation_menu"]
      },
      %{
        "id" => "connect_frontend_to_backend", 
        "duration" => "PT3M",
        "dependencies" => ["add_responsive_styling"]
      },
      %{
        "id" => "implement_user_dashboard", 
        "duration" => "PT6M",
        "dependencies" => ["connect_frontend_to_backend"]
      },
      %{
        "id" => "add_data_validation", 
        "duration" => "PT5M",
        "dependencies" => ["implement_user_dashboard"]
      },
      %{
        "id" => "implement_search_functionality", 
        "duration" => "PT6M",
        "dependencies" => ["add_data_validation"]
      },
      %{
        "id" => "add_user_preferences", 
        "duration" => "PT3M",
        "dependencies" => ["implement_search_functionality"]
      },
      %{
        "id" => "implement_try_catch_blocks", 
        "duration" => "PT4M",
        "dependencies" => ["add_user_preferences"]
      },
      %{
        "id" => "add_input_sanitization", 
        "duration" => "PT5M",
        "dependencies" => ["implement_try_catch_blocks"]
      },
      %{
        "id" => "setup_error_logging", 
        "duration" => "PT3M",
        "dependencies" => ["add_input_sanitization"]
      },
      %{
        "id" => "create_user_friendly_error_messages", 
        "duration" => "PT3M",
        "dependencies" => ["setup_error_logging"]
      },
      %{
        "id" => "write_authentication_tests",
        "duration" => "PT6M",
        "dependencies" => ["create_user_friendly_error_messages"]
      },
      %{
        "id" => "write_database_tests",
        "duration" => "PT5M",
        "dependencies" => ["write_authentication_tests"]
      },
      %{
        "id" => "write_ui_component_tests",
        "duration" => "PT6M",
        "dependencies" => ["write_database_tests"]
      },
      %{
        "id" => "write_api_endpoint_tests",
        "duration" => "PT3M",
        "dependencies" => ["write_ui_component_tests"]
      },
      %{
        "id" => "setup_test_database",
        "duration" => "PT4M",
        "dependencies" => ["write_api_endpoint_tests"]
      },
      %{
        "id" => "run_automated_test_suite",
        "duration" => "PT6M",
        "dependencies" => ["setup_test_database"]
      },
      %{
        "id" => "verify_test_coverage",
        "duration" => "PT5M",
        "dependencies" => ["run_automated_test_suite"]
      },
      %{
        "id" => "prepare_test_scenarios",
        "duration" => "PT3M",
        "dependencies" => ["verify_test_coverage"]
      },
      %{
        "id" => "execute_user_acceptance_tests",
        "duration" => "PT4M",
        "dependencies" => ["prepare_test_scenarios"]
      },
      %{
        "id" => "document_test_results",
        "duration" => "PT3M",
        "dependencies" => ["execute_user_acceptance_tests"]
      },
      %{
        "id" => "prepare_production_environment",
        "duration" => "PT5M",
        "dependencies" => ["document_test_results"]
      },
      %{
        "id" => "run_deployment_scripts",
        "duration" => "PT6M",
        "dependencies" => ["prepare_production_environment"]
      },
      %{
        "id" => "verify_deployment_success",
        "duration" => "PT4M",
        "dependencies" => ["run_deployment_scripts"]
      }
    ]
    
    base_datetime = DateTime.utc_now()
    
    case Scheduler.schedule_activities("Website Launch", activities, base_datetime: base_datetime) do
      {:ok, result} ->
        Helpers.print_schedule_result(result, "Sequential project workflow")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
