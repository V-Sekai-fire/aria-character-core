# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples.ResourceConstraints do
  @moduledoc """
  Sample 2: Resource-Constrained Scheduling
  Demonstrates resource allocation and capacity management with concrete tasks under 6 minutes.
  """

  alias AriaEngine.Scheduler
  alias AriaEngine.Scheduler.Resource
  alias Mix.Tasks.Schedule.Samples.Helpers

  def run do
    IO.puts("\n" <> IO.ANSI.yellow() <> "🔧 Sample 2: Resource-Constrained Scheduling" <> IO.ANSI.reset())
    IO.puts("Demonstrates resource allocation and capacity management")
    
    activities = [
      %{
        "id" => "install_frontend_tools",
        "duration" => "PT4M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "configure_build_system",
        "duration" => "PT5M",
        "dependencies" => ["install_frontend_tools"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "setup_linting_rules",
        "duration" => "PT3M",
        "dependencies" => ["configure_build_system"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "initialize_css_framework",
        "duration" => "PT3M",
        "dependencies" => ["setup_linting_rules"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_base_components",
        "duration" => "PT6M",
        "dependencies" => ["initialize_css_framework"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_routing_structure",
        "duration" => "PT5M",
        "dependencies" => ["create_base_components"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_state_management",
        "duration" => "PT6M",
        "dependencies" => ["implement_routing_structure"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_header_component",
        "duration" => "PT6M",
        "dependencies" => ["add_state_management"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_navigation_menu",
        "duration" => "PT5M",
        "dependencies" => ["create_header_component"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_responsive_layout",
        "duration" => "PT4M",
        "dependencies" => ["implement_navigation_menu"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "setup_backend_framework",
        "duration" => "PT4M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "configure_server_middleware",
        "duration" => "PT5M",
        "dependencies" => ["setup_backend_framework"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "setup_cors_configuration",
        "duration" => "PT3M",
        "dependencies" => ["configure_server_middleware"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "initialize_logging_system",
        "duration" => "PT3M",
        "dependencies" => ["setup_cors_configuration"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_user_endpoints",
        "duration" => "PT6M",
        "dependencies" => ["initialize_logging_system"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_auth_endpoints",
        "duration" => "PT6M",
        "dependencies" => ["create_user_endpoints"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_data_endpoints",
        "duration" => "PT5M",
        "dependencies" => ["implement_auth_endpoints"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_error_handlers",
        "duration" => "PT3M",
        "dependencies" => ["add_data_endpoints"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_user_registration",
        "duration" => "PT6M",
        "dependencies" => ["create_error_handlers"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_password_hashing",
        "duration" => "PT4M",
        "dependencies" => ["implement_user_registration"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_session_handling",
        "duration" => "PT5M",
        "dependencies" => ["add_password_hashing"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_role_permissions",
        "duration" => "PT6M",
        "dependencies" => ["create_session_handling"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_jwt_token_validation",
        "duration" => "PT5M",
        "dependencies" => ["implement_role_permissions"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_user_table_schema",
        "duration" => "PT6M",
        "dependencies" => [],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "design_product_table_schema",
        "duration" => "PT5M",
        "dependencies" => ["create_user_table_schema"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_relationship_mappings",
        "duration" => "PT4M",
        "dependencies" => ["design_product_table_schema"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "add_database_indexes",
        "duration" => "PT5M",
        "dependencies" => ["create_relationship_mappings"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "write_initial_migration",
        "duration" => "PT4M",
        "dependencies" => ["add_database_indexes"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_seed_data_scripts",
        "duration" => "PT6M",
        "dependencies" => ["write_initial_migration"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "test_migration_rollback",
        "duration" => "PT5M",
        "dependencies" => ["create_seed_data_scripts"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "create_database_models",
        "duration" => "PT6M",
        "dependencies" => ["test_migration_rollback"],
        "required_resources" => ["developer"]
      },
      %{
        "id" => "implement_query_methods",
        "duration" => "PT4M",
        "dependencies" => ["create_database_models"],
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
        Helpers.print_schedule_result(result, "Tasks competing for limited developer resource")
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ Scheduling failed: #{reason}" <> IO.ANSI.reset())
    end
  end
end
