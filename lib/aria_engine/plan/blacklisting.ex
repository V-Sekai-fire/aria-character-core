# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Blacklisting do
  @moduledoc """
  Functions for handling blacklisting of commands and methods.
  """

  # alias {Domain, State} # Domain and State are not directly used here, but included for type definitions
  # alias Plan.Core # For solution_tree type

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), AriaEngine.StateV2.fact_value()}
  @type todo_item :: task() | goal() | AriaEngine.Multigoal.t()
  @type plan_step :: {atom(), list()}

  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: AriaEngine.StateV2.t() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean()
        }

  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }

  @doc """
  Blacklist a command to prevent it from being tried again.
  """
  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command) do
    %{
      solution_tree
      | blacklisted_commands: MapSet.put(solution_tree.blacklisted_commands, command)
    }
  end
end
