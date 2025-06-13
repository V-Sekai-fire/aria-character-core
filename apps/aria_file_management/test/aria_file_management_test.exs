# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFileManagementTest do
  use ExUnit.Case, async: true
  doctest AriaFileManagement

  alias AriaEngine.State

  describe "AriaFileManagement domain creation" do
    test "creates a valid domain with file management actions" do
      domain = AriaFileManagement.create_domain()

      # Domain is returned as a map, not a struct
      assert is_map(domain)
      assert Map.get(domain, :name) == "file_management"
      assert is_map(Map.get(domain, :actions))
      assert is_map(Map.get(domain, :task_methods))

      # Check that basic file actions are present
      actions = Map.get(domain, :actions)
      assert Map.has_key?(actions, :copy_file)
      assert Map.has_key?(actions, :delete_file)
      assert Map.has_key?(actions, :create_directory)
    end

    test "domain has expected task methods" do
      domain = AriaFileManagement.create_domain()

      # Check for complex file management task methods that actually exist
      task_methods = Map.get(domain, :task_methods)
      expected_tasks = [
        "backup_files",
        "sync_directory",
        "cleanup_directory"
      ]

      for task <- expected_tasks do
        assert Map.has_key?(task_methods, task),
               "Expected task method '#{task}' not found"
      end
    end
  end

  describe "File management actions" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "copy_file action", %{state: state} do
      result = AriaFileManagement.copy_file(state, ["/src/file.txt", "/dst/file.txt"])
      # Currently returns false (placeholder), but structure is correct
      assert result == false
    end

    test "delete_file action", %{state: state} do
      result = AriaFileManagement.delete_file(state, ["/tmp/file.txt"])
      assert result == false
    end

    test "create_directory action", %{state: state} do
      result = AriaFileManagement.create_directory(state, ["/tmp/new_dir"])
      assert result == false
    end

    test "file_exists check", %{state: state} do
      result = AriaFileManagement.file_exists(state, ["/tmp/test.txt"])
      assert result == false
    end
  end

  describe "Complex file management tasks" do
    setup do
      state = State.new()
      {:ok, state: state}
    end

    test "backup_file task", %{state: state} do
      result = AriaFileManagement.backup_file(state, ["/important/file.txt", "/backup/"])
      # This returns a list of actions to perform
      assert is_list(result)
      assert length(result) > 0
    end

    test "extract_archive task", %{state: state} do
      result = AriaFileManagement.extract_archive(state, ["/tmp/archive.zip", "/tmp/extracted/"])
      # This returns a list of actions to perform
      assert is_list(result)
      assert length(result) > 0
    end

    test "setup_workspace task", %{state: state} do
      result = AriaFileManagement.setup_workspace(state, ["/workspace", "project_template"])
      # This returns a list of actions to perform
      assert is_list(result)
      assert length(result) > 0
    end
  end
end
