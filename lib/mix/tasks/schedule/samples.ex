# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Schedule.Samples do
  @moduledoc """
  Demonstrates AriaEngine.Scheduler capabilities with various scheduling samples.
  All tasks are decomposed into concrete, actionable steps under 6 minutes each.
  
  Usage: mix schedule.samples
  """
  
  use Mix.Task
  require Logger
  
  alias Mix.Tasks.Schedule.Samples.{Sequential, ResourceConstraints, EntityCapabilities}

  @shortdoc "Run scheduling samples to demonstrate AriaEngine.Scheduler capabilities"

  def run(_args) do
    # Start the application to ensure all dependencies are loaded
    Mix.Task.run("app.start")
    
    IO.puts("\n" <> IO.ANSI.cyan() <> "🚀 AriaEngine.Scheduler Samples" <> IO.ANSI.reset())
    IO.puts("All tasks decomposed into concrete actions under 6 minutes each")
    IO.puts(String.duplicate("=", 50))
    
    samples = [
      &Sequential.run/0,
      &ResourceConstraints.run/0,
      &EntityCapabilities.run/0
    ]
    
    Enum.with_index(samples, 1)
    |> Enum.each(fn {sample_fn, index} ->
      try do
        sample_fn.()
      rescue
        e ->
          IO.puts(IO.ANSI.red() <> "❌ Sample #{index} failed: #{Exception.message(e)}" <> IO.ANSI.reset())
          IO.puts(Exception.format_stacktrace(__STACKTRACE__))
      end
      
      if index < length(samples) do
        IO.puts("\n" <> String.duplicate("-", 50))
      end
    end)
    
    IO.puts("\n" <> IO.ANSI.green() <> "✅ All samples completed!" <> IO.ANSI.reset())
  end
end
