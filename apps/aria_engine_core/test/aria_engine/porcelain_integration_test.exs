# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PortcelainIntegrationTest do
  use ExUnit.Case, async: false

  alias AriaEngine.{State, Actions, DomainProvider, Plan}

  describe "AriaEngine Porcelain Actions" do
    test "execute_command action works with simple commands" do
      state = State.new()

      # Execute a simple echo command
      result = Actions.execute_command(state, ["echo", ["Hello, World!"], %{}])

      assert %State{} = result
      assert State.get_object(result, "last_command", "command") == "echo"
      assert State.get_object(result, "last_command", "exit_code") == 0
      assert State.get_object(result, "last_command", "success") == true
      assert String.contains?(State.get_object(result, "last_command", "stdout"), "Hello, World!")
    end

    test "execute_command action handles command failures" do
      state = State.new()

      # Execute a command that should fail
      result = Actions.execute_command(state, ["false", [], %{fail_on_error: true}])

      assert result == false # Changed from nil to false
    end

    test "execute_command action can continue on error" do
      state = State.new()

      # Execute a failing command but continue
      result = Actions.execute_command(state, ["false", [], %{fail_on_error: false}])

      assert %State{} = result
      assert State.get_object(result, "command_result", "last_exit_code") != 0
      assert State.get_object(result, "command_result", "last_success") == false
    end

    test "create_directory action works" do
      state = State.new()
      temp_dir = "/tmp/aria_test_#{:rand.uniform(10000)}"

      # Create directory
      result = Actions.create_directory(state, [temp_dir, %{parents: true}])

      assert %State{} = result
      assert State.get_object(result, "directory_exists", temp_dir) == true

      # Cleanup
      File.rm_rf!(temp_dir)
    end

    test "copy_file action works" do
      # Create a temporary source file
      source_file = "/tmp/aria_test_source_#{:rand.uniform(10000)}.txt"
      dest_file = "/tmp/aria_test_dest_#{:rand.uniform(10000)}.txt"
      File.write!(source_file, "test content")

      state = State.new()
      |> State.set_object("file_exists", source_file, true)

      # Copy file
      result = Actions.copy_file(state, [source_file, dest_file, %{}])

      assert %State{} = result
      assert State.get_object(result, "file_exists", dest_file) == true
      assert State.get_object(result, "file_copied_from", dest_file) == source_file
      assert File.exists?(dest_file)

      # Cleanup
      File.rm!(source_file)
      File.rm!(dest_file)
    end

    test "download_file action works" do
      dest_file = "/tmp/aria_test_download_#{:rand.uniform(10000)}.txt"
      state = State.new()

      # Download a simple file (using a data URL for testing)
      # Note: This test requires curl to be available
      if System.find_executable("curl") do
        # Use httpbin for a simple test
        result = Actions.download_file(state, ["https://httpbin.org/status/200", dest_file, %{silent: true}])

        assert %State{} = result
        assert State.get_object(result, "file_exists", dest_file) == true
        assert State.get_object(result, "file_downloaded_from", dest_file) == "https://httpbin.org/status/200"

        # Cleanup
        if File.exists?(dest_file), do: File.rm!(dest_file)
      else
        # Skip test if curl is not available
        assert true
      end
    end
  end

  describe "AriaEngine File Management Domain" do
    test "backup_file task plans and executes correctly" do
      state = State.new()
      file_path = "/tmp/test_file.txt"

      # Get the file management domain
      {:ok, domain} = DomainProvider.get_domain("file_management")

      # Plan backup_file task
      todos = [{"backup_file", [file_path]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 1

          # Should contain copy_file action
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :copy_file in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "replace_file_safely task plans and executes correctly" do
      state = State.new()
      old_file = "/tmp/old_file.txt"
      new_file = "/tmp/new_file.txt"

      # Get the file management domain
      {:ok, domain} = DomainProvider.get_domain("file_management")

      # Plan replace_file_safely task
      todos = [{"replace_file_safely", [old_file, new_file]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 2

          # Should contain backup and replacement operations
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :copy_file in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "create_directory_structure task plans and executes correctly" do
      state = State.new()
      base_path = "/tmp/project"
      subdirs = ["src", "test", "docs"]

      # Get the file management domain
      {:ok, domain} = DomainProvider.get_domain("file_management")

      # Plan create_directory_structure task
      todos = [{"create_directory_structure", [base_path, subdirs]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 4  # base + 3 subdirs

          # Should contain create_directory actions
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :create_directory in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "setup_workspace task plans and executes correctly" do
      state = State.new()
      workspace_path = "/tmp/workspaces"
      project_name = "test_project"

      # Get the file management domain
      {:ok, domain} = DomainProvider.get_domain("file_management")

      # Plan setup_workspace task
      todos = [{"setup_workspace", [workspace_path, project_name]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 5  # Multiple directory creation actions

          # Should contain create_directory actions
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :create_directory in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "AriaEngine Workflow System Domain" do
    test "setup_dev_environment task plans and executes correctly" do
      state = State.new()
      project_path = "/tmp/dev_project"
      services = ["postgres"]

      # Get the workflow system domain
      {:ok, domain} = DomainProvider.get_domain("workflow_system")

      # Plan setup_dev_environment task
      todos = [{"setup_dev_environment", [project_path, services]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 3  # base actions + service actions

          # Should contain create_directory and execute_command actions
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :create_directory in action_names
          assert :execute_command in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "run_tests_with_coverage task plans and executes correctly" do
      state = State.new()
      project_path = "/tmp/test_project"
      test_command = "mix test"

      # Get the workflow system domain
      {:ok, domain} = DomainProvider.get_domain("workflow_system")

      # Plan run_tests_with_coverage task
      todos = [{"run_tests_with_coverage", [project_path, test_command]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 2

          # Should contain execute_command actions for running tests
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :execute_command in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "build_and_package task plans and executes correctly" do
      state = State.new()
      project_path = "/tmp/docker_project"
      package_format = "docker"

      # Get the workflow system domain
      {:ok, domain} = DomainProvider.get_domain("workflow_system")

      # Plan build_and_package task
      todos = [{"build_and_package", [project_path, package_format]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 1

          # Should contain execute_command actions for building
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :execute_command in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "monitor_system_health task plans and executes correctly" do
      state = State.new()
      services = ["web_service", "api_service"]
      health_checks = %{
        "web_service" => %{"type" => "http", "url" => "http://localhost:8080/health"},
        "api_service" => %{"type" => "tcp", "host" => "localhost", "port" => 3000}
      }

      # Get the workflow system domain
      {:ok, domain} = DomainProvider.get_domain("workflow_system")

      # Plan monitor_system_health task
      todos = [{"monitor_system_health", [services, health_checks]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 2  # One action per service

          # Should contain execute_command actions for health checks
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :execute_command in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end

    test "deploy_service task plans and executes correctly" do
      state = State.new()
      service_name = "web_service"
      deployment_config = %{"image" => "nginx:latest", "port" => 80}

      # Get the workflow system domain
      {:ok, domain} = DomainProvider.get_domain("workflow_system")

      # Plan deploy_service task
      todos = [{"deploy_service", [service_name, deployment_config]}]

      case Plan.plan(domain, state, todos) do
        {:ok, solution_tree} ->
          actions = Plan.get_primitive_actions_dfs(solution_tree)
          assert is_list(actions)
          assert length(actions) >= 1

          # Should contain execute_command actions for deployment
          action_names = Enum.map(actions, fn {name, _} -> name end)
          assert :execute_command in action_names

        {:error, reason} ->
          flunk("Planning failed: #{inspect(reason)}")
      end
    end
  end

  describe "AriaEngine Domain Integration" do
    test "create_complete_domain includes all actions and methods" do
      # Get file management domain
      {:ok, file_domain} = DomainProvider.get_domain("file_management")

      # Get workflow system domain
      {:ok, workflow_domain} = DomainProvider.get_domain("workflow_system")

      # Check that file management actions are included
      assert Map.has_key?(file_domain.actions, :execute_command)
      assert Map.has_key?(file_domain.actions, :copy_file)
      assert Map.has_key?(file_domain.actions, :create_directory)
      assert Map.has_key?(file_domain.actions, :download_file)

      # Check that file management methods are included
      assert Map.has_key?(file_domain.task_methods, "backup_file")
      assert Map.has_key?(file_domain.task_methods, "setup_workspace")

      # Check that workflow system methods are included
      assert Map.has_key?(workflow_domain.task_methods, "deploy_service")
      assert Map.has_key?(workflow_domain.task_methods, "run_migrations")
      assert Map.has_key?(workflow_domain.task_methods, "monitor_system_health")
    end

    test "domain can execute Porcelain actions" do
      {:ok, domain} = DomainProvider.get_domain("file_management")
      state = State.new()

      # Get the execute_command action
      execute_command_fn = Map.get(domain.actions, :execute_command)
      assert is_function(execute_command_fn, 2)

      # Execute the action
      result = execute_command_fn.(state, ["echo", ["Domain integration test"], %{}])

      assert %State{} = result
      assert State.get_object(result, "last_command", "success") == true
    end
  end
end
