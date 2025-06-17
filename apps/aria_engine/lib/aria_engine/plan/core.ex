# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Core do
  @moduledoc """
  Core IPyHOP planning algorithm and decomposition loop.
  """
  alias AriaEngine.{Domain, State, Multigoal}
  alias AriaEngine.Plan.{NodeExpansion, Backtracking, Utils}
  # alias AriaEngine.DomainBehaviour # Removed unused alias

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
    is_durative: boolean() # New field to indicate if the action is durative
  }

  @type solution_tree :: %{
    root_id: node_id(),
    nodes: %{node_id() => solution_node()},
    blacklisted_commands: MapSet.t(),
    goal_network: %{node_id() => [node_id()]}
  }

  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}

  @default_max_depth 100
  @default_replan_depth 10 # New default replanning depth
  @default_verbose 0

  @doc """
  Main IPyHOP planning function that creates a solution tree to achieve the given todos.
  """
  @spec plan(AriaEngine.Domain.Core.t(), State.t(), [todo_item()], keyword()) :: plan_result()
  def plan(domain, %State{} = state, todos, opts \\ []) do
    # Add replan_depth to opts with a default value
    opts = Keyword.put_new(opts, :replan_depth, @default_replan_depth)
    # IO.puts("Starting IPyHOP planning for ", length(todos), " todos")
    # Commented out to reduce test output noise

    # Create initial solution tree with goal-task network
    solution_tree = Utils.create_initial_solution_tree(todos, state)

    # Run IPyHOP algorithm
    ipyhop(domain, state, solution_tree, opts)
  end

  # Core IPyHOP Algorithm (Algorithm 2 from the paper)
  @spec ipyhop(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), keyword()) :: plan_result()
  def ipyhop(domain, %State{} = current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)

    # IPyHOP main loop
    plan_decomposition_loop(domain, current_state, solution_tree, 0, max_depth, verbose)
  end

  @spec plan_decomposition_loop(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), integer(), integer(), integer()) :: plan_result()
  defp plan_decomposition_loop(domain, current_state, solution_tree, depth, max_depth, verbose) do
    if verbose > 3 do
      IO.puts("PLAN_DECOMPOSITION_LOOP: Depth #{depth}, Nodes: #{Kernel.map_size(solution_tree.nodes)}")
    end

    if depth >= max_depth do
      if verbose > 0 do
        IO.puts("PLAN_DECOMPOSITION_LOOP: Maximum planning depth exceeded at depth #{depth}")
      end
      {:error, "Maximum planning depth exceeded"}
    else
      # Find next unexpanded node
      case find_next_node(solution_tree) do
        nil ->
          # All nodes expanded - check if solution is complete
          if solution_complete?(solution_tree) do
            if verbose > 0 do
              IO.puts("PLAN_DECOMPOSITION_LOOP: Solution complete.")
            end
            {:ok, solution_tree}
          else
            if verbose > 0 do
              IO.puts("PLAN_DECOMPOSITION_LOOP: No complete solution found after all nodes expanded.")
            end
            {:error, "No complete solution found"}
          end

        node_id ->
          if verbose > 3 do
            IO.puts("PLAN_DECOMPOSITION_LOOP: Expanding node #{node_id} (Task: #{inspect(solution_tree.nodes[node_id].task)})")
          end
          # Try to expand this node
          case try_expand_node(domain, current_state, solution_tree, node_id, verbose) do
            {:ok, new_tree} ->
              if verbose > 3 do
                IO.puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expanded successfully.")
              end
              plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

            {:error, reason} ->
              if verbose > 0 do
                IO.puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion failed: #{reason}")
              end
              {:error, reason}

            {:failure, failed_tree} -> # Capture the tree with the failed method info
              if verbose > 0 do
                IO.puts("PLAN_DECOMPOSITION_LOOP: Node #{node_id} expansion returned :failure, attempting backtrack.")
              end
              # Backtrack and try alternatives
              case Backtracking.backtrack_and_retry(domain, current_state, failed_tree, node_id, depth, max_depth, verbose) do # Pass failed_tree
                {:ok, new_tree} ->
                  if verbose > 0 do
                    IO.puts("PLAN_DECOMPOSITION_LOOP: Backtrack succeeded, continuing planning.")
                  end
                  plan_decomposition_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

                {:error, reason} ->
                  if verbose > 0 do
                    IO.puts("PLAN_DECOMPOSITION_LOOP: Backtrack failed: #{reason}")
                  end
                  {:error, reason}
              end
          end
      end
    end
  end

  # Find the next node to expand (depth-first search)
  @spec find_next_node(solution_tree()) :: node_id() | nil
  defp find_next_node(solution_tree) do
    find_next_node_dfs(solution_tree, solution_tree.root_id)
  end

  @spec find_next_node_dfs(solution_tree(), node_id()) :: node_id() | nil
  defp find_next_node_dfs(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> nil
      node ->
        cond do
          not node.expanded and not node.is_primitive ->
            # This node needs expansion
            node_id

          Enum.empty?(node.children_ids) ->
            # Leaf node, check if it's primitive or already expanded
            if node.is_primitive or node.expanded do
              nil  # Primitive action or already expanded leaf, no expansion needed
            else
              node_id  # Non-primitive, non-expanded leaf needs expansion
            end

          true ->
            # Check children
            Enum.find_value(node.children_ids, fn child_id ->
              find_next_node_dfs(solution_tree, child_id)
            end)
        end
    end
  end

  # Try to expand a node
  @spec try_expand_node(AriaEngine.Domain.Core.t(), State.t(), solution_tree(), node_id(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()} | {:failure, solution_tree()}
  defp try_expand_node(domain, state, solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        if verbose > 2 do
          IO.puts("Expanding node #{node_id}: #{inspect(node.task)}")
        end

        case node.task do
          {:root, todos} ->
            NodeExpansion.expand_root_node(solution_tree, node_id, todos, state)

          {task_name, args} when is_binary(task_name) ->
            action_atom = String.to_atom(task_name) # Define action_atom here
            if Domain.has_action?(domain, action_atom) do # Use Domain.has_action?
              NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)
            else if Domain.get_durative_action(domain, action_atom) do # Check for durative action
              NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)
            else
              NodeExpansion.expand_task_node(domain, state, solution_tree, node_id, task_name, args, verbose)
            end
            end

          {action_name, _args} when is_atom(action_name) ->
            # action_atom is already action_name here
            if Domain.has_action?(domain, action_name) do # Use Domain.has_action?
              NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: false)
            else if Domain.get_durative_action(domain, action_name) do # Check for durative action
              NodeExpansion.mark_as_primitive(solution_tree, node_id, is_durative: true)
            else
              {:error, "Unknown action: #{action_name}"}
            end
            end

          {predicate, subject, fact_value} ->
            NodeExpansion.expand_goal_node(domain, state, solution_tree, node_id, predicate, subject, fact_value, verbose)

          %Multigoal{} = multigoal ->
            NodeExpansion.expand_multigoal_node(domain, state, solution_tree, node_id, multigoal, verbose)

          _ ->
            {:error, "Unknown task type: #{inspect(node.task)}"}
        end
    end
  end

  @spec solution_complete?(solution_tree()) :: boolean()
  defp solution_complete?(solution_tree) do
    # All nodes should be expanded and all leaves should be primitive actions
    # Root node is complete if expanded (even with no children for empty goals)
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = (id == solution_tree.root_id)
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  # Helper to get default verbose level
  @spec get_default_verbose() :: integer()
  def get_default_verbose(), do: @default_verbose

  # Helper to get default replan depth
  @spec get_default_replan_depth() :: integer()
  def get_default_replan_depth(), do: @default_replan_depth
end
