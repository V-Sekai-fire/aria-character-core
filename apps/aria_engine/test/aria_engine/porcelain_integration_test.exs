# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PortcelainIntegrationTest do
  use ExUnit.Case, async: false

  alias AriaEngine.{Domain, State, Actions}
  alias AriaEngine.Domains.{FileManagement, WorkflowSystem}

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

      assert result == false
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
    test "backup_file method returns correct action sequence" do
      state = State.new()
      file_path = "/tmp/test_file.txt"

      actions = FileManagement.backup_file(state, [file_path])

      assert is_list(actions)
      assert length(actions) == 1

      [{action_name, action_args}] = actions
      assert action_name == :copy_file
      assert [^file_path, backup_path, %{force: false}] = action_args
      assert String.starts_with?(backup_path, file_path <> ".backup.")
    end

    test "replace_file_safely method returns correct action sequence" do
      state = State.new()
      old_file = "/tmp/old_file.txt"
      new_file = "/tmp/new_file.txt"

      actions = FileManagement.replace_file_safely(state, [old_file, new_file])

      assert is_list(actions)
      assert length(actions) == 3  # copy_file + copy_file + echo

      [{:copy_file, [^old_file, backup_path]},
       {:copy_file, [^new_file, ^old_file]},
       {:echo, [echo_msg]}] = actions

      assert String.starts_with?(backup_path, old_file <> ".backup")
      assert String.contains?(echo_msg, "Safely replaced")
    end

    test "create_directory_structure method returns correct action sequence" do
      state = State.new()
      base_path = "/tmp/project"
      subdirs = ["src", "test", "docs"]

      actions = FileManagement.create_directory_structure(state, [base_path, subdirs])

      assert is_list(actions)
      assert length(actions) == 4  # base + 3 subdirs

      [{:create_directory, [^base_path, %{parents: true}]} | subdir_actions] = actions

      assert length(subdir_actions) == 3
      Enum.each(subdir_actions, fn {:create_directory, [path, %{parents: true}]} ->
        assert String.starts_with?(path, base_path)
      end)
    end

    test "setup_workspace method returns correct action sequence" do
      state = State.new()
      workspace_path = "/tmp/workspaces"
      project_name = "test_project"

      actions = FileManagement.setup_workspace(state, [workspace_path, project_name])

      assert is_list(actions)
      assert length(actions) == 6  # project dir + 4 subdirs + README

      # Check that all expected directories are created
      expected_dirs = [
        "/tmp/workspaces/test_project",
        "/tmp/workspaces/test_project/src",
        "/tmp/workspaces/test_project/test",
        "/tmp/workspaces/test_project/docs",
        "/tmp/workspaces/test_project/config"
      ]

      dir_actions = Enum.take(actions, 5)
      Enum.each(dir_actions, fn {:create_directory, [path, %{parents: true}]} ->
        assert path in expected_dirs
      end)

      # Check README creation
      {:execute_command, ["touch", [readme_path], %{}]} = Enum.at(actions, 5)
      assert String.ends_with?(readme_path, "README.md")
    end
  end

  describe "AriaEngine Workflow System Domain" do
    test "execute_traced_command method returns correct action sequence" do
      state = State.new()
      command = "echo"
      args = ["traced execution"]
      workflow_id = "test_workflow_123"

      actions = WorkflowSystem.execute_traced_command(state, [command, args, workflow_id])

      assert is_list(actions)
      assert length(actions) == 1

      [{:execute_command, [^command, ^args, options]}] = actions
      assert options[:timeout] == 60_000
      assert options[:env]["WORKFLOW_ID"] == workflow_id
      assert options[:fail_on_error] == false
    end

    test "setup_dev_environment method returns correct action sequence" do
      state = State.new()
      project_path = "/tmp/dev_project"
      services = ["postgres", "redis"]

      actions = WorkflowSystem.setup_dev_environment(state, [project_path, services])

      assert is_list(actions)
      assert length(actions) >= 4  # base actions + service actions

      # Check base actions
      [{:create_directory, [^project_path, %{parents: true}]},
       {:execute_command, ["git", ["init"], %{working_dir: ^project_path}]} | service_actions] = actions

      # Check that Docker commands are generated for services
      docker_commands = Enum.filter(service_actions, fn
        {:execute_command, ["docker", _args, _opts]} -> true
        _ -> false
      end)

      assert length(docker_commands) == 2  # postgres + redis
    end

    test "run_tests_with_coverage method returns correct action sequence" do
      state = State.new()
      project_path = "/tmp/test_project"
      test_command = "mix test"

      actions = WorkflowSystem.run_tests_with_coverage(state, [project_path, test_command])

      assert is_list(actions)
      assert length(actions) == 2

      [{:execute_command, ["mix", ["test", "--cover"], opts1]},
       {:execute_command, ["mix", ["coveralls.html"], opts2]}] = actions

      assert opts1[:working_dir] == project_path
      assert opts1[:env]["MIX_ENV"] == "test"
      assert opts2[:working_dir] == project_path
      assert opts2[:fail_on_error] == false
    end

    test "build_and_package docker method returns correct action sequence" do
      state = State.new()
      project_path = "/tmp/docker_project"
      package_format = "docker"

      actions = WorkflowSystem.build_and_package(state, [project_path, package_format])

      assert is_list(actions)
      assert length(actions) == 1

      [{:execute_command, ["docker", ["build", "-t", "docker_project:latest", "."], opts]}] = actions
      assert opts[:working_dir] == project_path
    end

    test "build_and_package release method returns correct action sequence" do
      state = State.new()
      project_path = "/tmp/release_project"
      package_format = "release"

      actions = WorkflowSystem.build_and_package(state, [project_path, package_format])

      assert is_list(actions)
      assert length(actions) == 3

      [{:execute_command, ["mix", ["deps.get"], _]},
       {:execute_command, ["mix", ["compile"], _]},
       {:execute_command, ["mix", ["release"], opts]}] = actions

      assert opts[:env]["MIX_ENV"] == "prod"
    end

    test "monitor_system_health method returns correct action sequence" do
      state = State.new()
      services = ["web_service", "api_service"]
      health_checks = %{
        "web_service" => %{"type" => "http", "url" => "http://localhost:8080/health"},
        "api_service" => %{"type" => "tcp", "host" => "localhost", "port" => 3000}
      }

      actions = WorkflowSystem.monitor_system_health(state, [services, health_checks])

      assert is_list(actions)
      assert length(actions) == 2

      [{:execute_command, ["curl", ["-f", "-s", "http://localhost:8080/health"], _]},
       {:execute_command, ["nc", ["-z", "localhost", "3000"], _]}] = actions
    end
  end

  describe "AriaEngine Domain Integration" do
    test "create_complete_domain includes all actions and methods" do
      domain = Domain.create_complete_domain("test_complete")

      # Check that Porcelain actions are included
      assert Map.has_key?(domain.actions, :execute_command)
      assert Map.has_key?(domain.actions, :copy_file)
      assert Map.has_key?(domain.actions, :create_directory)
      assert Map.has_key?(domain.actions, :download_file)

      # Check that file management methods are included
      assert Map.has_key?(domain.task_methods, "backup_file")
      assert Map.has_key?(domain.task_methods, "setup_workspace")
      assert Map.has_key?(domain.task_methods, "compress_directory")

      # Check that workflow system methods are included
      assert Map.has_key?(domain.task_methods, "deploy_service")
      assert Map.has_key?(domain.task_methods, "run_migrations")
      assert Map.has_key?(domain.task_methods, "monitor_system_health")
    end

    test "domain can execute Porcelain actions" do
      domain = Domain.create_complete_domain("test_execution")
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
