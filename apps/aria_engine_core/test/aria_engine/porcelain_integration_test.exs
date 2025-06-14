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

  # File management domain tests disabled - AriaFileManagement dependency removed
  # describe "AriaEngine File Management Domain" do
  #   test "backup_file task plans and executes correctly" do
  #     # Disabled - file management domain removed
  #   end
  #
  #   test "replace_file_safely task plans and executes correctly" do
  #     # Disabled - file management domain removed
  #   end
  #
  #   test "setup_workspace task plans and executes correctly" do
  #     # Disabled - file management domain removed
  #   end
  # end

  # Workflow system domain tests disabled - AriaWorkflowSystem dependency removed  
  # describe "AriaEngine Workflow System Domain" do
  #   test "setup_dev_environment task plans and executes correctly" do
  #     # Disabled - workflow system domain removed
  #   end
  #
  #   test "run_tests_with_coverage task plans and executes correctly" do
  #     # Disabled - workflow system domain removed
  #   end
  #
  #   test "build_and_package task plans and executes correctly" do
  #     # Disabled - workflow system domain removed
  #   end
  #
  #   test "monitor_system_health task plans and executes correctly" do
  #     # Disabled - workflow system domain removed
  #   end
  #
  #   test "deploy_service task plans and executes correctly" do
  #     # Disabled - workflow system domain removed
  #   end
  # end

  # Domain integration tests disabled - AriaFileManagement dependency removed
  # describe "AriaEngine Domain Integration" do
  #   test "create_complete_domain includes all actions and methods" do
  #     # Disabled - file management and workflow system domains removed
  #   end
  #
  #   test "domain can execute Porcelain actions" do
  #     # Disabled - file management domain removed  
  #   end
  # end
end
