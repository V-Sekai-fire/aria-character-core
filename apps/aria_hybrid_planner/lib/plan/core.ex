# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Plan.Core do
  @moduledoc "Core IPyHOP planning algorithm and decomposition loop.\n"
  require Logger
  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), State.fact_value()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}
  @type node_id :: String.t()
  @type solution_node :: %{
          id: node_id(),
          task: todo_item(),
          parent_id: node_id() | nil,
          children_ids: [node_id()],
          state: State.t() | nil,
          visited: boolean(),
          expanded: boolean(),
          method_tried: String.t() | nil,
          blacklisted_methods: [String.t()],
          is_primitive: boolean(),
          is_durative: boolean()
        }
  @type solution_tree :: %{
          root_id: node_id(),
          nodes: %{node_id() => solution_node()},
          blacklisted_commands: MapSet.t(),
          goal_network: %{node_id() => [node_id()]}
        }
  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @default_replan_depth 10
  @default_verbose 0

  @spec get_default_verbose() :: integer()
  def get_default_verbose() do
    @default_verbose
  end

  @spec get_default_replan_depth() :: integer()
  def get_default_replan_depth() do
    @default_replan_depth
  end
end
