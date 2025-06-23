defmodule Actions do
  @moduledoc "A library of actions that can execute external processes via Porcelain.\n\nThese actions represent atomic operations that modify the world state\nand can interact with external systems through command execution.\n"
  require Logger
  @type state :: AriaEngine.State.t()
  @type command :: String.t()
  @type args :: [String.t()]
  @type execution_opts :: %{
          optional(:timeout) => non_neg_integer(),
          optional(:working_dir) => String.t(),
          optional(:env) => %{String.t() => String.t()},
          optional(:capture_output) => boolean()
        }
  @type execution_result :: %{
          exit_code: non_neg_integer(),
          stdout: String.t(),
          stderr: String.t(),
          duration_ms: non_neg_integer()
        }
  @type file_path :: String.t()
  @type permissions :: String.t()
  @type url :: String.t()
  @doc "Execute a shell command using Porcelain.\n\nUpdates state with execution results including exit code, output, and timing.\n"
  @spec execute_command(state(), [command() | args() | execution_opts()]) :: state() | false
  def execute_command(state, [command, args_list, opts]) when is_list(args_list) do
    execute_command_with_opts(state, command, args_list, opts)
  end

  def execute_command(state, [command | args]) do
    execute_command_with_opts(state, command, args, %{})
  end

  @spec execute_command_with_opts(state(), command(), args(), execution_opts()) :: state() | false
  defp execute_command_with_opts(state, command, args, opts) do
    fail_on_error = Map.get(opts, :fail_on_error, true)
    Logger.debug("Executing command: #{command} #{Enum.join(args, " ")}")
    start_time = System.monotonic_time(:millisecond)

    try do
      result =
        case args do
          [] -> Porcelain.shell(command, out: :string, err: :string)
          _ -> Porcelain.exec(command, args, out: :string, err: :string)
        end

      end_time = System.monotonic_time(:millisecond)
      duration_ms = end_time - start_time

      new_state =
        state
        |> AriaEngine.State.set_fact("last_command", "command", command)
        |> AriaEngine.State.set_fact("last_command", "args", args)
        |> AriaEngine.State.set_fact("last_command", "exit_code", result.status)
        |> AriaEngine.State.set_fact("last_command", "stdout", result.out || "")
        |> AriaEngine.State.set_fact("last_command", "stderr", result.err || "")
        |> AriaEngine.State.set_fact("last_command", "duration_ms", duration_ms)
        |> AriaEngine.State.set_fact("last_command", "success", result.status == 0)

      if result.status == 0 do
        Logger.debug("Command succeeded (#{duration_ms}ms)")
        new_state
      else
        Logger.debug("Command failed with exit code #{result.status}")

        if fail_on_error do
          false
        else
          new_state
          |> AriaEngine.State.set_fact("command_result", "last_exit_code", result.status)
          |> AriaEngine.State.set_fact("command_result", "last_success", false)
        end
      end
    rescue
      error ->
        Logger.debug("Command execution failed: #{inspect(error)}")

        error_state =
          state
          |> AriaEngine.State.set_fact("last_command", "command", command)
          |> AriaEngine.State.set_fact("last_command", "error", inspect(error))
          |> AriaEngine.State.set_fact("last_command", "success", false)

        if fail_on_error do
          false
        else
          error_state
        end
    end
  end

  @doc "Copy a file from source to destination.\n"
  @spec copy_file(state(), {file_path(), file_path()}) :: state() | false
  def copy_file(state, [source, destination]) do
    case execute_command(state, ["cp", source, destination]) do
      false ->
        false

      new_state ->
        new_state
        |> AriaEngine.State.set_fact("file_exists", destination, true)
        |> AriaEngine.State.set_fact("file_copied_from", destination, source)
        |> AriaEngine.State.set_fact("last_copy", "source", source)
        |> AriaEngine.State.set_fact("last_copy", "destination", destination)
    end
  end

  @spec copy_file(state(), [file_path() | any()]) :: state() | false
  def copy_file(state, [source, destination, _opts]) do
    copy_file(state, [source, destination])
  end

  @doc "Move a file from source to destination.\n"
  @spec move_file(state(), {file_path(), file_path()}) :: state() | false
  def move_file(state, [source, destination]) do
    execute_command(state, ["mv", source, destination])
  end

  @doc "Delete a file.\n"
  @spec delete_file(state(), [file_path()]) :: state() | false
  def delete_file(state, [file_path]) do
    execute_command(state, ["rm", file_path])
  end

  @doc "Create a directory using external mkdir command.\n"
  @spec create_directory(state(), [file_path()]) :: state() | false
  def create_directory(state, [dir_path]) do
    case execute_command(state, ["mkdir", "-p", dir_path]) do
      false ->
        false

      new_state ->
        new_state
        |> AriaEngine.State.set_fact("directory_exists", dir_path, true)
        |> AriaEngine.State.set_fact("last_mkdir", "path", dir_path)
    end
  end

  @spec create_directory(state(), [file_path() | any()]) :: state() | false
  def create_directory(state, [dir_path, _opts]) do
    create_directory(state, [dir_path])
  end

  @doc "List directory contents using external ls command.\n"
  @spec list_directory(state(), [file_path()]) :: state() | false
  def list_directory(state, [dir_path]) do
    execute_command(state, ["ls", "-la", dir_path])
  end

  @doc "Check if a file exists using external ls command.\n"
  @spec file_exists(state(), [file_path()]) :: state()
  def file_exists(state, [file_path]) do
    case execute_command(state, ["ls", file_path]) do
      false -> state |> AriaEngine.State.set_fact("file_exists", file_path, false)
      new_state -> new_state |> AriaEngine.State.set_fact("file_exists", file_path, true)
    end
  end

  @doc "Download a file from a URL.\n"
  @spec download_file(state(), {url(), file_path()}) :: state() | false
  def download_file(state, [url, destination]) do
    case execute_command(state, ["curl", "-o", destination, url]) do
      false ->
        false

      new_state ->
        new_state
        |> AriaEngine.State.set_fact("file_exists", destination, true)
        |> AriaEngine.State.set_fact("file_downloaded_from", destination, url)
        |> AriaEngine.State.set_fact("last_download", "url", url)
        |> AriaEngine.State.set_fact("last_download", "destination", destination)
    end
  end

  @spec download_file(state(), [url() | file_path() | any()]) :: state() | false
  def download_file(state, [url, destination, _options]) do
    case execute_command(state, ["curl", "-o", destination, url]) do
      false ->
        false

      new_state ->
        new_state
        |> AriaEngine.State.set_fact("file_exists", destination, true)
        |> AriaEngine.State.set_fact("file_downloaded_from", destination, url)
        |> AriaEngine.State.set_fact("last_download", "url", url)
        |> AriaEngine.State.set_fact("last_download", "destination", destination)
    end
  end

  @doc "Archive files using tar.\n"
  @spec create_archive(state(), [String.t()]) :: state() | false
  def create_archive(state, [archive_name, source_path]) do
    execute_command(state, ["tar", "-czf", archive_name, source_path])
  end

  @doc "Extract an archive using tar.\n"
  @spec extract_archive(state(), [String.t()]) :: state() | false
  def extract_archive(state, [archive_path, destination]) do
    execute_command(state, ["tar", "-xzf", archive_path, "-C", destination])
  end

  @doc "Run a git command in a repository.\n"
  @spec git_command(state(), [String.t()]) :: state() | false
  def git_command(state, [repo_path | git_args]) do
    execute_command(state, ["git", "-C", repo_path] ++ git_args)
  end

  @doc "Send an HTTP request using curl.\n"
  @spec http_request(state(), [String.t()]) :: state() | false
  def http_request(state, [method, url | curl_args]) do
    case String.upcase(method) do
      "GET" ->
        execute_command(state, ["curl", "-X", "GET", url] ++ curl_args)

      "POST" ->
        execute_command(state, ["curl", "-X", "POST", url] ++ curl_args)

      "PUT" ->
        execute_command(state, ["curl", "-X", "PUT", url] ++ curl_args)

      "DELETE" ->
        execute_command(state, ["curl", "-X", "DELETE", url] ++ curl_args)

      _ ->
        Logger.error("Unsupported HTTP method: #{method}")
        false
    end
  end

  @doc "Execute a custom script or program.\n"
  @spec run_script(state(), [String.t()]) :: state() | false
  def run_script(state, [script_path | script_args]) do
    execute_command(state, [script_path] ++ script_args)
  end

  @doc "Wait for a specified number of seconds.\n"
  @spec wait(state(), [integer() | String.t()]) :: state() | false
  def wait(state, [seconds]) when is_integer(seconds) do
    execute_command(state, ["sleep", Integer.to_string(seconds)])
  end

  @spec wait(state(), [String.t()]) :: state() | false
  def wait(state, [seconds]) when is_binary(seconds) do
    execute_command(state, ["sleep", seconds])
  end

  @doc "Echo a message and update state.\n"
  @spec echo(state(), [String.t()]) :: state()
  def echo(state, [message]) do
    execute_command(state, ["echo", message])
  end

  @doc "Set an environment variable in the state (simulated).\n"
  @spec set_env_var(state(), [String.t()]) :: state()
  def set_env_var(state, [var_name, var_value]) do
    state |> AriaEngine.State.set_fact("env", var_name, var_value)
  end

  @doc "Get an environment variable from the system.\n"
  @spec get_env_var(state(), [String.t()]) :: state() | false
  def get_env_var(state, [var_name]) do
    case System.get_env(var_name) do
      nil ->
        Logger.warning("Environment variable #{var_name} not found")
        false

      value ->
        state |> AriaEngine.State.set_fact("env", var_name, value)
    end
  end

  @doc "Remove a file or directory path using external rm command.\n"
  @spec remove_path(state(), [String.t()]) :: state() | false
  def remove_path(state, [path]) do
    execute_command(state, ["rm", "-rf", path])
  end

  @doc "Change permissions of a file or directory using external chmod command.\n"
  @spec change_permissions(state(), [String.t()]) :: state() | false
  def change_permissions(state, [mode, path]) do
    execute_command(state, ["chmod", mode, path])
  end
end