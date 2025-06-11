# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Actions do
  @moduledoc """
  AriaEngine actions that can execute external processes via Porcelain.

  These actions represent atomic operations that modify the world state
  and can interact with external systems through command execution.
  """

  alias AriaEngine.State
  require Logger

  @doc """
  Execute a shell command using Porcelain.

  Updates state with execution results including exit code, output, and timing.
  """
  def execute_command(state, [command | args]) do
    Logger.info("Executing command: #{command} #{Enum.join(args, " ")}")

    start_time = System.monotonic_time(:millisecond)

    try do
      result = case args do
        [] ->
          # Single command string
          Porcelain.shell(command, out: :string, err: :string)
        _ ->
          # Command with args
          Porcelain.exec(command, args, out: :string, err: :string)
      end

      end_time = System.monotonic_time(:millisecond)
      duration_ms = end_time - start_time

      # Update state with execution results
      new_state = state
      |> State.set_object("last_command", "command", command)
      |> State.set_object("last_command", "args", args)
      |> State.set_object("last_command", "exit_code", result.status)
      |> State.set_object("last_command", "stdout", result.out || "")
      |> State.set_object("last_command", "stderr", result.err || "")
      |> State.set_object("last_command", "duration_ms", duration_ms)
      |> State.set_object("last_command", "success", result.status == 0)

      if result.status == 0 do
        Logger.info("Command succeeded (#{duration_ms}ms)")
        new_state
      else
        Logger.warning("Command failed with exit code #{result.status}")
        false
      end

    rescue
      error ->
        Logger.error("Command execution failed: #{inspect(error)}")

        # Update state with error information
        state
        |> State.set_object("last_command", "command", command)
        |> State.set_object("last_command", "error", inspect(error))
        |> State.set_object("last_command", "success", false)
        |> then(fn _ -> false end)
    end
  end

  @doc """
  Copy a file from source to destination using external cp command.
  """
  def copy_file(state, [source, destination]) do
    execute_command(state, ["cp", source, destination])
  end

  @doc """
  Move/rename a file using external mv command.
  """
  def move_file(state, [source, destination]) do
    execute_command(state, ["mv", source, destination])
  end

  @doc """
  Delete a file using external rm command.
  """
  def delete_file(state, [file_path]) do
    execute_command(state, ["rm", file_path])
  end

  @doc """
  Create a directory using external mkdir command.
  """
  def create_directory(state, [dir_path]) do
    execute_command(state, ["mkdir", "-p", dir_path])
  end

  @doc """
  List directory contents using external ls command.
  """
  def list_directory(state, [dir_path]) do
    execute_command(state, ["ls", "-la", dir_path])
  end

  @doc """
  Check if a file exists using external test command.
  """
  def file_exists(state, [file_path]) do
    case execute_command(state, ["test", "-f", file_path]) do
      false -> false  # Command failed, file doesn't exist
      new_state ->
        # Update state to record file existence
        new_state
        |> State.set_object("file_exists", file_path, true)
    end
  end

  @doc """
  Download a file using curl.
  """
  def download_file(state, [url, destination]) do
    execute_command(state, ["curl", "-o", destination, url])
  end

  @doc """
  Archive files using tar.
  """
  def create_archive(state, [archive_name, source_path]) do
    execute_command(state, ["tar", "-czf", archive_name, source_path])
  end

  @doc """
  Extract an archive using tar.
  """
  def extract_archive(state, [archive_path, destination]) do
    execute_command(state, ["tar", "-xzf", archive_path, "-C", destination])
  end

  @doc """
  Run a git command in a repository.
  """
  def git_command(state, [repo_path | git_args]) do
    execute_command(state, ["git", "-C", repo_path] ++ git_args)
  end

  @doc """
  Send an HTTP request using curl.
  """
  def http_request(state, [method, url | curl_args]) do
    case String.upcase(method) do
      "GET" -> execute_command(state, ["curl", "-X", "GET", url] ++ curl_args)
      "POST" -> execute_command(state, ["curl", "-X", "POST", url] ++ curl_args)
      "PUT" -> execute_command(state, ["curl", "-X", "PUT", url] ++ curl_args)
      "DELETE" -> execute_command(state, ["curl", "-X", "DELETE", url] ++ curl_args)
      _ ->
        Logger.error("Unsupported HTTP method: #{method}")
        false
    end
  end

  @doc """
  Execute a custom script or program.
  """
  def run_script(state, [script_path | script_args]) do
    execute_command(state, [script_path] ++ script_args)
  end

  @doc """
  Wait for a specified number of seconds.
  """
  def wait(state, [seconds]) when is_integer(seconds) do
    execute_command(state, ["sleep", Integer.to_string(seconds)])
  end
  def wait(state, [seconds]) when is_binary(seconds) do
    execute_command(state, ["sleep", seconds])
  end

  @doc """
  Echo a message (useful for testing and logging).
  """
  def echo(state, [message]) do
    execute_command(state, ["echo", message])
  end

  @doc """
  Set an environment variable in the state (simulated).
  """
  def set_env_var(state, [var_name, var_value]) do
    state
    |> State.set_object("env", var_name, var_value)
  end

  @doc """
  Get an environment variable from the system.
  """
  def get_env_var(state, [var_name]) do
    case System.get_env(var_name) do
      nil ->
        Logger.warning("Environment variable #{var_name} not found")
        false
      value ->
        state
        |> State.set_object("env", var_name, value)
    end
  end
end
