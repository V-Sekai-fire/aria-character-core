defmodule Mix.Tasks.App do
  use Mix.Task

  @shortdoc "Starts and stops the Elixir application"

  def run(args) do
    case args do
      ["start"] -> start_app()
      ["stop"] -> stop_app()
      ["status"] -> status_app()
      ["logs"] -> logs_app()
      _ -> Mix.raise "Invalid arguments. Use mix app.start, mix app.stop, mix app.status, or mix app.logs"
    end
  end

  defp start_app() do
    Mix.shell.info "🚀 Starting Elixir application..."
    # Check if Phoenix server is already running
    if System.cmd("pgrep", ["-f", "phoenix.server"]) |> elem(0) |> String.trim() != "" do
      Mix.shell.info "✅ Elixir application is already running."
      exit(0)
    end

    # Start Phoenix server in the background
    # Using nohup to detach from the terminal, and redirecting output to a log file
    log_file = "aria_app.log"
    pid_file = "aria_app.pid"

    Mix.shell.info "Starting Phoenix server..."
    System.cmd("nohup", ["mix", "phx.server", ">", log_file, "2>&1", "&"])
    # Get the PID of the last background process
    pid = System.cmd("pgrep", ["-f", "phoenix.server"]) |> elem(0) |> String.trim()
    File.write!(pid_file, pid)

    Mix.shell.info "⏳ Waiting for Elixir application to be ready..."
    # You might need a more sophisticated health check here, e.g., checking a specific port or API endpoint
    :timer.sleep(5000) # Give it a few seconds to start

    if File.exists?(pid_file) and System.cmd("pgrep", ["-F", pid_file]) |> elem(0) |> String.trim() != "" do
      Mix.shell.info "✅ Elixir application started successfully!"
    else
      Mix.shell.error "❌ Elixir application failed to start."
      if File.exists?(log_file) do
        Mix.shell.info "Last 30 lines of log file:"
        System.cmd("tail", ["-n", "30", log_file]) |> elem(0) |> Mix.shell.info()
      end
      exit(1)
    end
  end

  defp stop_app() do
    Mix.shell.info "🛑 Stopping Elixir application..."
    pid_file = "aria_app.pid"

    if File.exists?(pid_file) do
      pid = File.read!(pid_file) |> String.trim()
      if System.cmd("pgrep", ["-F", pid]) |> elem(0) |> String.trim() != "" do
        System.cmd("kill", [pid])
        Mix.shell.info "✅ Elixir application stopped."
      else
        Mix.shell.info "⚠️  Elixir application process not found, PID file exists. Cleaning up PID file."
      end
      File.rm!(pid_file)
    else
      Mix.shell.info "⚠️  Elixir application PID file not found. Attempting to kill any running phoenix.server processes..."
      System.cmd("pkill", ["-f", "phoenix.server"]) |> elem(0) |> Mix.shell.info()
      Mix.shell.info "✅ Attempted to stop Elixir application."
    end
  end

  defp status_app() do
    Mix.shell.info "📊 Elixir Application Status:"
    pid_file = "aria_app.pid"

    if File.exists?(pid_file) do
      pid = File.read!(pid_file) |> String.trim()
      if System.cmd("pgrep", ["-F", pid]) |> elem(0) |> String.trim() != "" do
        Mix.shell.info "✅ Elixir application is RUNNING (PID: #{pid})"
      else
        Mix.shell.info "❌ Elixir application is STOPPED (PID file found but process not running). Cleaning up PID file."
        File.rm!(pid_file)
      end
    else
      Mix.shell.info "❌ Elixir application is STOPPED (PID file not found)"
    end
  end

  defp logs_app() do
    Mix.shell.info "📋 Elixir Application Logs (last 30 lines):"
    log_file = "aria_app.log"

    if File.exists?(log_file) do
      System.cmd("tail", ["-n", "30", log_file]) |> elem(0) |> Mix.shell.info()
    else
      Mix.shell.info "No Elixir application log file found at #{log_file}."
    end
  end
end
