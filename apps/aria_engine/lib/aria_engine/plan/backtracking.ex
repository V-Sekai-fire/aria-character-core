# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan.Backtracking do
  @moduledoc """
  Functions for handling backtracking and replanning in the solution tree.
  """
  alias AriaEngine.{Domain, State}
  alias AriaEngine.Plan.{Core, Utils} # Assuming Core will have ipyhop, Utils will have update_cached_states, generate_node_id, get_all_descendants

  @type node_id :: String.t()
  @type solution_node :: %{
    id: node_id(),
    task: term(), # Using term() as task type is defined in Core
    parent_id: node_id() | nil,
    children_ids: [node_id()],
    state: State.t() | nil,
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

  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure

  # @default_replan_depth 10 # Removed this module attribute

  @doc """
  Replan from a specific failure node in the solution tree.
  """
  @spec replan(Domain.t(), State.t(), solution_tree(), node_id(), keyword()) :: replan_result()
  def replan(%Domain{} = domain, %State{} = state, solution_tree, fail_node_id, opts \\ []) do
    # Decrement replan_depth for recursive calls
    replan_depth = Keyword.get(opts, :replan_depth, Core.get_default_replan_depth()) # Get from Core
    if replan_depth <= 0 do
      IO.puts("REPLAN: Maximum replanning depth exceeded.")
      {:error, "Maximum replanning depth exceeded"}
    else
      opts = Keyword.put(opts, :replan_depth, replan_depth - 1)
      verbose = Keyword.get(opts, :verbose, Core.get_default_verbose()) # Assuming Core has default_verbose

      if verbose > 2 do
        IO.puts("Replanning from failure node: #{fail_node_id}")
      end

      # Find the task node that produced this action (walk up the tree)
      case find_responsible_task_node(solution_tree, fail_node_id, verbose) do
        nil ->
          {:error, "Could not find responsible task node for failed action"}

        task_node_id ->
          if verbose > 2 do
            IO.puts("Found responsible task node: #{task_node_id}")
          end

          # Update cached states to current execution state
          updated_tree = Utils.update_cached_states(solution_tree, state)

          # Try alternative method for the responsible task
          case try_alternative_method_for_task(domain, updated_tree, task_node_id, verbose) do # Pass domain
            {:ok, new_tree} ->
              # Resume planning from the updated tree
              Core.ipyhop(domain, state, new_tree, opts)

            {:error, reason} ->
              {:error, reason}
            :no_alternatives -> # Added this clause
              :no_alternatives # Propagate no_alternatives
          end
      end
    end # This 'end' closes the 'else' block
  end

  # Find the task node responsible for producing a failed action
  @spec find_responsible_task_node(solution_tree(), node_id(), integer()) :: node_id() | nil
  def find_responsible_task_node(solution_tree, fail_node_id, verbose) do
    case solution_tree.nodes[fail_node_id] do
      nil ->
        nil

      node ->
        # Walk up the tree to find a task node (not a primitive action)
        find_parent_task_node(solution_tree, node.parent_id, verbose)
    end
  end

  # Recursively find the first parent that is a task node (not primitive)
  @spec find_parent_task_node(solution_tree(), node_id() | nil, integer()) :: node_id() | nil
  def find_parent_task_node(_solution_tree, nil, _verbose), do: nil

  def find_parent_task_node(solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil -> nil

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # This is a task node - this is what we're looking for
            if verbose > 2 do
              IO.puts("Found task node: #{node_id} with task: #{task_name}")
            end
            node_id

          {:root, _} ->
            # Skip root node, continue searching
            find_parent_task_node(solution_tree, node.parent_id, verbose)

          _ ->
            # Goal or other node type, continue searching
            find_parent_task_node(solution_tree, node.parent_id, verbose)
        end
    end
  end

  # Try alternative method for a specific task node
  @spec try_alternative_method_for_task(Domain.t(), solution_tree(), node_id(), integer()) :: # Added Domain.t()
    {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  def try_alternative_method_for_task(domain, solution_tree, task_node_id, verbose) do # Added domain
    case solution_tree.nodes[task_node_id] do
      nil ->
        {:error, "Task node not found: #{task_node_id}"}

      node ->
        if verbose > 2 do
          IO.puts("DEBUG: try_alternative_method_for_task - node.method_tried: #{inspect(node.method_tried)}")
        end
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # Add current method to blacklist and reset node
            current_method = node.method_tried
            blacklisted_methods = if current_method do
              [current_method | node.blacklisted_methods]
            else
              node.blacklisted_methods
            end

            # Check if there are any non-blacklisted methods left
            all_methods = Domain.get_task_methods(domain, task_name)
            remaining_methods = Enum.reject(all_methods, fn {method_name, _method_fn} ->
              method_name in blacklisted_methods
            end)

            if Enum.empty?(remaining_methods) do
              if verbose > 2 do
                IO.puts("No alternative methods left for task: #{task_name}")
              end
              :no_alternatives # Return no_alternatives if no methods left
            else
              if verbose > 2 do
                IO.puts("Blacklisting method for task #{task_name}: #{inspect(current_method)}")
                IO.puts("Total blacklisted methods: #{inspect(blacklisted_methods)}")
              end

              # Reset the node for retrying with alternative methods
              reset_node = %{node |
                children_ids: [],
                expanded: false,
                method_tried: nil,
                blacklisted_methods: blacklisted_methods
              }

              # Remove all descendant nodes
              descendant_ids = Utils.get_all_descendants(solution_tree, task_node_id)
              remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)

              # Update the tree
              updated_tree = %{solution_tree |
                nodes: Map.put(remaining_nodes, task_node_id, reset_node)
              }

              {:ok, updated_tree}
            end

          {predicate, _subject, _fact_value} -> # For goal nodes
            # Add current method to blacklist and reset node
            current_method = node.method_tried
            blacklisted_methods = if current_method do
              [current_method | node.blacklisted_methods]
            else
              node.blacklisted_methods
            end

            # Check if there are any non-blacklisted methods left
            all_methods = Domain.get_unigoal_methods(domain, predicate)
            remaining_methods = Enum.reject(all_methods, fn {method_name, _method_fn} ->
              method_name in blacklisted_methods
            end)

            if Enum.empty?(remaining_methods) do
              if verbose > 2 do
                IO.puts("No alternative methods left for goal: #{predicate}")
              end
              :no_alternatives # Return no_alternatives if no methods left
            else
              if verbose > 2 do
                IO.puts("Blacklisting method for goal #{predicate}: #{inspect(current_method)}")
                IO.puts("Total blacklisted methods: #{inspect(blacklisted_methods)}")
              end

              # Reset the node for retrying with alternative methods
              reset_node = %{node |
                children_ids: [],
                expanded: false,
                method_tried: nil,
                blacklisted_methods: blacklisted_methods
              }

              # Remove all descendant nodes
              descendant_ids = Utils.get_all_descendants(solution_tree, task_node_id)
              remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)

              # Update the tree
              updated_tree = %{solution_tree |
                nodes: Map.put(remaining_nodes, task_node_id, reset_node)
              }

              {:ok, updated_tree}
            end

          _ ->
            {:error, "Node is not a task or goal node: #{inspect(node.task)}"}
        end
    end
  end

  # Backtrack and retry from a failed node
  @spec backtrack_and_retry(Domain.t(), State.t(), solution_tree(), node_id(), integer(), integer(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def backtrack_and_retry(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose) do
    if verbose > 2 do
      IO.puts("Backtracking from failed node: #{failed_node_id}")
    end

    case solution_tree.nodes[failed_node_id] do
      nil ->
        {:error, "Failed node not found: #{failed_node_id}"}

      failed_node ->
        # Find the parent node to backtrack to
        case failed_node.parent_id do
          nil ->
            # Root node failed - no solution possible
            {:error, "Root node failed - no complete solution found"}

          _parent_id -> # We will handle backtracking to parent explicitly if needed
            # First, try alternative method for the failed node itself
            case solution_tree.nodes[failed_node_id].task do
              {task_name, _args} when is_binary(task_name) ->
                # This is a task node - try next available method for this node
                case try_alternative_method_for_task(domain, solution_tree, failed_node_id, verbose) do # Pass domain
                  {:ok, new_tree} ->
                    {:ok, new_tree}
                  :no_alternatives ->
                    # If no alternatives for this node, then backtrack to parent
                    backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)
                  {:error, reason} ->
                    {:error, reason}
                end
              {_predicate, _subject, _fact_value} -> # Fixed unused variables here
                # This is a goal node - try next available method for this node
                case try_alternative_method_for_task(domain, solution_tree, failed_node_id, verbose) do # Pass domain
                  {:ok, new_tree} ->
                    {:ok, new_tree}
                  :no_alternatives ->
                    # If no alternatives for this node, then backtrack to parent
                    backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)
                  {:error, reason} ->
                    {:error, reason}
                end
              _ ->
                # If it's not a task or goal node, then no alternatives for it, backtrack to parent
                backtrack_up_tree(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose)
            end
        end
    end
  end

  # Helper to backtrack up the tree
  @spec backtrack_up_tree(Domain.t(), State.t(), solution_tree(), node_id(), integer(), integer(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  def backtrack_up_tree(domain, state, solution_tree, current_node_id, depth, max_depth, verbose) do
    case solution_tree.nodes[current_node_id].parent_id do
      nil ->
        {:error, "No alternative methods available - no complete solution found"}
      parent_id ->
        backtrack_and_retry(domain, state, solution_tree, parent_id, depth, max_depth, verbose)
    end
  end
end
