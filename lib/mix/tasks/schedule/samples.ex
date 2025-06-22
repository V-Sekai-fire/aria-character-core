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

  alias Mix.Tasks.Schedule.Samples.Sequential
  alias Mix.Tasks.Schedule.Samples.ResourceConstraints
  alias Mix.Tasks.Schedule.Samples.EntityCapabilities

  @shortdoc "Run scheduling samples to demonstrate AriaEngine.Scheduler capabilities"

  def run(_args) do
    Mix.Task.run("app.start")
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
          IO.puts(
            IO.ANSI.red() <>
              "❌ Sample #{index} failed: #{Exception.message(e)}" <> IO.ANSI.reset()
          )

          IO.puts(Exception.format_stacktrace(__STACKTRACE__))
      end

      if index < length(samples) do
        IO.puts("\n" <> String.duplicate("-", 50))
      end
    end)

    IO.puts("\n" <> IO.ANSI.green() <> "✅ All samples completed!" <> IO.ANSI.reset())
  end

  # Public helper: Print a solution tree as an ASCII diagram
  def print_solution_tree_ascii(solution_tree) do
    nodes = solution_tree.nodes
    root_id = solution_tree.root_id
    do_print_node(root_id, nodes, "", true)
  end

  defp do_print_node(node_id, nodes, prefix, is_last) do
    node = Map.get(nodes, node_id)

    label =
      cond do
        Map.has_key?(node, :task) and not is_nil(node.task) ->
          case node.task do
            {name, _args} when is_binary(name) -> name
            name when is_binary(name) -> name
            other -> inspect(other)
          end

        true ->
          to_string(node_id)
      end

    connector = if is_last, do: "└── ", else: "├── "
    IO.puts(prefix <> connector <> label)

    children = Map.get(node, :children_ids, [])
    count = length(children)

    Enum.with_index(children)
    |> Enum.each(fn {child_id, idx} ->
      is_last_child = idx == count - 1
      new_prefix = prefix <> if is_last, do: "    ", else: "│   "
      do_print_node(child_id, nodes, new_prefix, is_last_child)
    end)
  end
end
