# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Plan do
  @moduledoc """
  IPyHOP-style reentrant HTN planning implementation with Run-Lazy-Refineahead.

  This module implements the Run-Lazy-Refineahead algorithm from the paper
  "HTN Replanning from the Middle" with solution trees, state caching,
  and reentrant planning capabilities.

  Features:
  - Solution tree (task decomposition network) with preserved hierarchy
  - Reentrant planning from any failure point
  - State caching at each node for efficient replanning
  - Blacklisting of failed commands
  - Lazy action execution checking
  - Goal-task-network planning

  Example:
  ```elixir
  # Create domain with actions and methods
  domain = AriaEngine.Domain.new("example")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)

  # Create initial state
  initial_state = AriaEngine.State.new()
  |> AriaEngine.State.set_object("location", "robot", "room1")

  # Create goals
  goals = [{"location", "robot", "room2"}]

  # Initial planning
  case AriaEngine.Plan.plan(domain, initial_state, goals) do
    {:ok, solution_tree} ->
      # Execute plan with replanning on failure
      AriaEngine.Plan.run_lazy_refineahead(domain, initial_state, solution_tree)
    {:error, reason} ->
      IO.puts("Planning failed: \#{reason}")
  end
  ```
  """

  alias AriaEngine.{Domain, State, Multigoal}

  @type task :: {String.t(), list()}
  @type goal :: {String.t(), String.t(), any()}
  @type todo_item :: task() | goal() | Multigoal.t()
  @type plan_step :: {atom(), list()}

  # Solution tree node structure (IPyHOP-style)
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
    is_primitive: boolean()
  }

  @type solution_tree :: %{
    root_id: node_id(),
    nodes: %{node_id() => solution_node()},
    blacklisted_commands: MapSet.t(),
    goal_network: %{node_id() => [node_id()]}  # Goal-task network dependencies
  }

  @type plan_result :: {:ok, solution_tree()} | {:error, String.t()}
  @type replan_result :: {:ok, solution_tree()} | {:error, String.t()} | :failure

  @default_max_depth 100
  @default_verbose 0

  @doc """
  Main IPyHOP planning function that creates a solution tree to achieve the given todos.

  ## Parameters
  - `domain`: The planning domain containing actions and methods
  - `state`: The initial world state
  - `todos`: List of goals, tasks, or multigoals to achieve
  - `options`: Planning options (max_depth, verbose, etc.)

  ## Returns
  - `{:ok, solution_tree}`: A solution tree that achieves the goals
  - `{:error, reason}`: Planning failure reason
  """
  @spec plan(Domain.t(), State.t(), [todo_item()], keyword()) :: plan_result()
  def plan(%Domain{} = domain, %State{} = state, todos, opts \\ []) do
    # IO.puts("Starting IPyHOP planning for ", length(todos), " todos")
    # Commented out to reduce test output noise

    # Create initial solution tree with goal-task network
    solution_tree = create_initial_solution_tree(todos, state)

    # Run IPyHOP algorithm
    ipyhop(domain, state, solution_tree, opts)
  end

  @doc """
  Replan from a specific failure node in the solution tree.

  ## Parameters
  - `domain`: The planning domain
  - `state`: Current state of the world
  - `solution_tree`: Existing solution tree
  - `fail_node_id`: ID of the node that failed
  - `options`: Planning options

  ## Returns
  - `{:ok, solution_tree}`: Updated solution tree with new plan
  - `{:error, reason}`: Replanning failure reason
  - `:failure`: No solution possible
  """
  @spec replan(Domain.t(), State.t(), solution_tree(), node_id(), keyword()) :: replan_result()
  def replan(%Domain{} = domain, %State{} = state, solution_tree, fail_node_id, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    if verbose > 0 do
      IO.puts("Replanning from failure node: #{fail_node_id}")
    end

    # Find the task node that produced this action (walk up the tree)
    case find_responsible_task_node(solution_tree, fail_node_id, verbose) do
      nil ->
        {:error, "Could not find responsible task node for failed action"}

      task_node_id ->
        if verbose > 0 do
          IO.puts("Found responsible task node: #{task_node_id}")
        end

        # Update cached states to current execution state
        updated_tree = update_cached_states(solution_tree, state)

        # Try alternative method for the responsible task
        case try_alternative_method_for_task(updated_tree, task_node_id, verbose) do
          {:ok, new_tree} ->
            # Resume planning from the updated tree
            ipyhop(domain, state, new_tree, opts)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Blacklist a command to prevent it from being tried again.

  ## Parameters
  - `solution_tree`: Current solution tree
  - `command`: The command (task/action) to blacklist

  ## Returns
  Updated solution tree with the command blacklisted
  """
  @spec blacklist_command(solution_tree(), todo_item()) :: solution_tree()
  def blacklist_command(solution_tree, command) do
    %{solution_tree |
      blacklisted_commands: MapSet.put(solution_tree.blacklisted_commands, command)
    }
  end

  @doc """
  Run-Lazy-Refineahead: Execute plan with replanning on failure.

  This implements Algorithm 3 from the IPyHOP paper.

  ## Parameters
  - `domain`: The planning domain
  - `initial_state`: Starting state
  - `solution_tree`: Initial solution tree

  ## Returns
  - `{:ok, final_state}`: Successful execution
  - `{:error, reason}`: Execution failed
  """
  @spec run_lazy_refineahead(Domain.t(), State.t(), solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  def run_lazy_refineahead(%Domain{} = domain, %State{} = initial_state, solution_tree, opts \\ []) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    if verbose > 0 do
      IO.puts("Starting Run-Lazy-Refineahead execution")
    end

    # Initialize execution state
    current_state = initial_state
    current_tree = solution_tree

    # Main execution loop
    run_execution_loop(domain, current_state, current_tree, opts)
  end

  # Core IPyHOP Algorithm (Algorithm 2 from the paper)
  @spec ipyhop(Domain.t(), State.t(), solution_tree(), keyword()) :: plan_result()
  defp ipyhop(%Domain{} = domain, %State{} = current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)
    max_depth = Keyword.get(opts, :max_depth, @default_max_depth)

    # IPyHOP main loop
    ipyhop_loop(domain, current_state, solution_tree, 0, max_depth, verbose)
  end

  # IPyHOP main loop implementation
  @spec ipyhop_loop(Domain.t(), State.t(), solution_tree(), integer(), integer(), integer()) :: plan_result()
  defp ipyhop_loop(%Domain{} = domain, current_state, solution_tree, depth, max_depth, verbose) do
    if depth >= max_depth do
      {:error, "Maximum planning depth exceeded"}
    else
      # Find next unexpanded node
      case find_next_node(solution_tree) do
        nil ->
          # All nodes expanded - check if solution is complete
          if solution_complete?(solution_tree) do
            {:ok, solution_tree}
          else
            {:error, "No complete solution found"}
          end

        node_id ->
          # Try to expand this node
          case try_expand_node(domain, current_state, solution_tree, node_id, verbose) do
            {:ok, new_tree} ->
              ipyhop_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

            {:error, reason} ->
              {:error, reason}

            :failure ->
              # Backtrack and try alternatives
              case backtrack_and_retry(domain, current_state, solution_tree, node_id, depth, max_depth, verbose) do
                {:ok, new_tree} ->
                  ipyhop_loop(domain, current_state, new_tree, depth + 1, max_depth, verbose)

                {:error, reason} ->
                  {:error, reason}
              end
          end
      end
    end
  end

  # Find the task node responsible for producing a failed action
  @spec find_responsible_task_node(solution_tree(), node_id(), integer()) :: node_id() | nil
  defp find_responsible_task_node(solution_tree, fail_node_id, verbose) do
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
  defp find_parent_task_node(_solution_tree, nil, _verbose), do: nil

  defp find_parent_task_node(solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil -> nil

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # This is a task node - this is what we're looking for
            if verbose > 1 do
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
  @spec try_alternative_method_for_task(solution_tree(), node_id(), integer()) ::
    {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  defp try_alternative_method_for_task(solution_tree, task_node_id, verbose) do
    case solution_tree.nodes[task_node_id] do
      nil ->
        {:error, "Task node not found: #{task_node_id}"}

      node ->
        case node.task do
          {task_name, _args} when is_binary(task_name) ->
            # Add current method to blacklist and reset node
            current_method = node.method_tried
            blacklisted_methods = if current_method do
              [current_method | node.blacklisted_methods]
            else
              node.blacklisted_methods
            end

            if verbose > 1 do
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
            descendant_ids = get_all_descendants(solution_tree, task_node_id)
            remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)

            # Update the tree
            updated_tree = %{solution_tree |
              nodes: Map.put(remaining_nodes, task_node_id, reset_node)
            }

            {:ok, updated_tree}

          _ ->
            {:error, "Node is not a task node: #{inspect(node.task)}"}
        end
    end
  end

  # Create initial solution tree with goal-task network
  @spec create_initial_solution_tree([todo_item()], State.t()) :: solution_tree()
  defp create_initial_solution_tree(todos, initial_state) do
    root_id = generate_node_id()

    # Create root node containing all initial todos
    root_node = %{
      id: root_id,
      task: {:root, todos},
      parent_id: nil,
      children_ids: [],
      state: initial_state,
      visited: false,
      expanded: false,
      method_tried: nil,
      blacklisted_methods: [],
      is_primitive: false
    }

    %{
      root_id: root_id,
      nodes: %{root_id => root_node},
      blacklisted_commands: MapSet.new(),
      goal_network: %{}
    }
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
  @spec try_expand_node(Domain.t(), State.t(), solution_tree(), node_id(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp try_expand_node(domain, state, solution_tree, node_id, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        if verbose > 1 do
          IO.puts("Expanding node #{node_id}: #{inspect(node.task)}")
        end

        case node.task do
          {:root, todos} ->
            # Expand root node with initial todos
            expand_root_node(solution_tree, node_id, todos, state)

          {task_name, args} when is_binary(task_name) ->
            # Check if it's a primitive action first
            action_atom = String.to_atom(task_name)
            if Domain.has_action?(domain, action_atom) do
              # Mark as primitive action
              mark_as_primitive(solution_tree, node_id)
            else
              # Expand task using methods
              expand_task_node(domain, state, solution_tree, node_id, task_name, args, verbose)
            end

          {action_name, _args} when is_atom(action_name) ->
            # Check if it's a primitive action
            if Domain.has_action?(domain, action_name) do
              mark_as_primitive(solution_tree, node_id)
            else
              {:error, "Unknown action: #{action_name}"}
            end

          {predicate, subject, object} ->
            # Expand goal
            expand_goal_node(domain, state, solution_tree, node_id, predicate, subject, object, verbose)

          %Multigoal{} = multigoal ->
            # Expand multigoal
            expand_multigoal_node(domain, state, solution_tree, node_id, multigoal, verbose)

          _ ->
            {:error, "Unknown task type: #{inspect(node.task)}"}
        end
    end
  end

  # Expand root node with initial todos
  @spec expand_root_node(solution_tree(), node_id(), [todo_item()], State.t()) :: {:ok, solution_tree()}
  defp expand_root_node(solution_tree, root_id, todos, state) do
    # Create child nodes for each todo
    {new_tree, child_ids} = Enum.reduce(todos, {solution_tree, []}, fn todo, {tree, ids} ->
      child_id = generate_node_id()
      child_node = %{
        id: child_id,
        task: todo,
        parent_id: root_id,
        children_ids: [],
        state: state,
        visited: false,
        expanded: false,
        method_tried: nil,
        blacklisted_methods: [],
        is_primitive: is_primitive_task?(todo)
      }

      new_tree = put_in(tree.nodes[child_id], child_node)
      {new_tree, [child_id | ids]}
    end)

    # Update root node
    updated_root = %{solution_tree.nodes[root_id] |
      children_ids: Enum.reverse(child_ids),
      expanded: true
    }

    final_tree = put_in(new_tree.nodes[root_id], updated_root)
    {:ok, final_tree}
  end

  # Expand task node using methods
  @spec expand_task_node(Domain.t(), State.t(), solution_tree(), node_id(), String.t(), list(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp expand_task_node(domain, _state, solution_tree, node_id, task_name, args, verbose) do
    node = solution_tree.nodes[node_id]
    methods = Domain.get_task_methods(domain, task_name)

    # Filter out blacklisted methods
    available_methods = Enum.reject(methods, fn method ->
      method_id = "method_#{:erlang.phash2(method)}"
      method_id in node.blacklisted_methods
    end)

    if Enum.empty?(available_methods) do
      if verbose > 1 do
        IO.puts("No methods available for task: #{task_name}")
      end
      {:error, "No methods found for task: #{task_name}"}
    else
      # Try the first available method
      [method | _] = available_methods
      method_id = "method_#{:erlang.phash2(method)}"

      case method.(node.state, args) do
        false ->
          if verbose > 1 do
            IO.puts("Method failed preconditions for task: #{task_name}")
          end
          {:error, "Method preconditions failed for task: #{task_name}"}

        subtasks when is_list(subtasks) ->
          if verbose > 1 do
            IO.puts("Method succeeded, created #{length(subtasks)} subtasks")
          end

          # Create child nodes for subtasks and execute primitive actions immediately
          {new_tree, child_ids, _final_state} = Enum.reduce(subtasks, {solution_tree, [], node.state}, fn subtask, {tree, ids, current_state} ->
            child_id = generate_node_id()
            is_primitive = is_primitive_task?(subtask)

            # If this is a primitive action, execute it immediately to get the new state
            child_state = if is_primitive do
              {action_name, args} = subtask
              action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

              case Domain.execute_action(domain, current_state, action_atom, args) do
                {:ok, new_state} ->
                  if verbose > 2 do
                    IO.puts("Executed primitive action #{action_name}(#{inspect(args)}) successfully")
                  end
                  new_state
                false ->
                  if verbose > 1 do
                    IO.puts("Primitive action #{action_name}(#{inspect(args)}) failed")
                  end
                  current_state  # Keep current state if action failed
              end
            else
              current_state  # Non-primitive tasks inherit current state
            end

            child_node = %{
              id: child_id,
              task: subtask,
              parent_id: node_id,
              children_ids: [],
              state: child_state,
              visited: false,
              expanded: is_primitive,  # Primitive actions are considered expanded
              method_tried: nil,
              blacklisted_methods: [],
              is_primitive: is_primitive
            }

            new_tree = put_in(tree.nodes[child_id], child_node)
            {new_tree, [child_id | ids], child_state}
          end)

          # Update parent node
          updated_node = %{node |
            children_ids: Enum.reverse(child_ids),
            expanded: true,
            method_tried: method_id
          }

          final_tree = put_in(new_tree.nodes[node_id], updated_node)
          {:ok, final_tree}

        _ ->
          {:error, "Invalid method result for task: #{task_name}"}
      end
    end
  end

  # Expand goal node
  @spec expand_goal_node(Domain.t(), State.t(), solution_tree(), node_id(), String.t(), String.t(), any(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp expand_goal_node(domain, state, solution_tree, node_id, predicate, subject, object, verbose) do
    node = solution_tree.nodes[node_id]

    # Check if goal is already satisfied
    case State.get_object(node.state, predicate, subject) do
      ^object ->
        # Goal already satisfied - mark as expanded with no children
        updated_node = %{node | expanded: true, is_primitive: true}
        final_tree = put_in(solution_tree.nodes[node_id], updated_node)
        {:ok, final_tree}

      _ ->
        # Try goal methods
        methods = Domain.get_unigoal_methods(domain, predicate)

        # Filter out blacklisted methods
        available_methods = Enum.reject(methods, fn method ->
          method_id = "goal_method_#{:erlang.phash2(method)}"
          method_id in node.blacklisted_methods
        end)

        if Enum.empty?(available_methods) do
          if verbose > 1 do
            IO.puts("No methods available for goal: #{predicate}")
          end
          {:error, "No methods found for goal: #{predicate}"}
        else
          # Try the first method
          [method | _] = available_methods
          method_id = "goal_method_#{:erlang.phash2(method)}"

          case method.(node.state, [subject, object]) do
            false ->
              if verbose > 1 do
                IO.puts("Method failed preconditions for goal: #{predicate}")
              end
              :failure

            subtasks when is_list(subtasks) ->
              if verbose > 1 do
                IO.puts("Goal method succeeded, created #{length(subtasks)} subtasks")
              end

              # Create child nodes for subtasks
              {new_tree, child_ids} = Enum.reduce(subtasks, {solution_tree, []}, fn subtask, {tree, ids} ->
                child_id = generate_node_id()
                is_primitive = is_primitive_task?(subtask)
                child_node = %{
                  id: child_id,
                  task: subtask,
                  parent_id: node_id,
                  children_ids: [],
                  state: node.state,
                  visited: false,
                  expanded: is_primitive,  # Primitive actions are considered expanded
                  method_tried: nil,
                  blacklisted_methods: [],
                  is_primitive: is_primitive
                }

                new_tree = put_in(tree.nodes[child_id], child_node)
                {new_tree, [child_id | ids]}
              end)

              # Update parent node
              updated_node = %{node |
                children_ids: Enum.reverse(child_ids),
                expanded: true,
                method_tried: method_id
              }

              final_tree = put_in(new_tree.nodes[node_id], updated_node)
              {:ok, final_tree}

            {:multigoal, goals} ->
              if verbose > 1 do
                IO.puts("Goal method returned multigoal with #{length(goals)} goals")
              end

              # Create a multigoal struct and use multigoal expansion
              multigoal = Multigoal.new(goals)
              expand_multigoal_node(domain, state, solution_tree, node_id, multigoal, verbose)

            _ ->
              {:error, "Invalid goal method result for: #{predicate}"}
          end
        end
    end
  end

  # Expand multigoal node
  @spec expand_multigoal_node(Domain.t(), State.t(), solution_tree(), node_id(), Multigoal.t(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()} | :failure
  defp expand_multigoal_node(_domain, _state, solution_tree, node_id, multigoal, verbose) do
    node = solution_tree.nodes[node_id]

    # Check if multigoal is already satisfied
    if Multigoal.satisfied?(multigoal, node.state) do
      # Already satisfied - mark as expanded with no children
      updated_node = %{node | expanded: true, is_primitive: true}
      final_tree = put_in(solution_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    else
      # Get unsatisfied goals and create subtasks
      unsatisfied = Multigoal.unsatisfied_goals(multigoal, node.state)

      if verbose > 1 do
        IO.puts("Multigoal has #{length(unsatisfied)} unsatisfied goals")
      end

      # Create child nodes for unsatisfied goals
      {new_tree, child_ids} = Enum.reduce(unsatisfied, {solution_tree, []}, fn goal, {tree, ids} ->
        child_id = generate_node_id()
        is_primitive = is_primitive_task?(goal)
        child_node = %{
          id: child_id,
          task: goal,
          parent_id: node_id,
          children_ids: [],
          state: node.state,
          visited: false,
          expanded: is_primitive,  # Primitive actions are considered expanded
          method_tried: nil,
          blacklisted_methods: [],
          is_primitive: is_primitive
        }

        new_tree = put_in(tree.nodes[child_id], child_node)
        {new_tree, [child_id | ids]}
      end)

      # Update parent node
      updated_node = %{node |
        children_ids: Enum.reverse(child_ids),
        expanded: true
      }

      final_tree = put_in(new_tree.nodes[node_id], updated_node)
      {:ok, final_tree}
    end
  end

  # Mark a node as primitive (action)
  @spec mark_as_primitive(solution_tree(), node_id()) :: {:ok, solution_tree()}
  defp mark_as_primitive(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        updated_node = %{node | is_primitive: true, expanded: true}
        final_tree = put_in(solution_tree.nodes[node_id], updated_node)
        {:ok, final_tree}
    end
  end

  # Check if a task is primitive (an action)
  @spec is_primitive_task?(todo_item()) :: boolean()
  defp is_primitive_task?({name, _args}) when is_atom(name), do: true
  defp is_primitive_task?({name, _args}) when is_binary(name), do: false  # Could be action or task
  defp is_primitive_task?(_), do: false

  # Check if solution tree is complete
  @spec solution_complete?(solution_tree()) :: boolean()
  defp solution_complete?(solution_tree) do
    # All nodes should be expanded and all leaves should be primitive actions
    # Root node is complete if expanded (even with no children for empty goals)
    Enum.all?(solution_tree.nodes, fn {id, node} ->
      is_root = (id == solution_tree.root_id)
      node.expanded and (node.is_primitive or not Enum.empty?(node.children_ids) or is_root)
    end)
  end

  # Backtrack and retry from a failed node
  @spec backtrack_and_retry(Domain.t(), State.t(), solution_tree(), node_id(), integer(), integer(), integer()) ::
    {:ok, solution_tree()} | {:error, String.t()}
  defp backtrack_and_retry(domain, state, solution_tree, failed_node_id, depth, max_depth, verbose) do
    if verbose > 1 do
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

          parent_id ->
            # Perform backtracking by finding an alternative method
            case backtrack_to_alternative_method(solution_tree, parent_id, failed_node_id, verbose) do
              {:ok, new_tree} ->
                # Successfully found alternative, continue planning
                {:ok, new_tree}

              :no_alternatives ->
                # No alternatives at this level, backtrack further up
                case solution_tree.nodes[parent_id].parent_id do
                  nil ->
                    {:error, "No alternative methods available - no complete solution found"}

                  _grandparent_id ->
                    # Try backtracking to grandparent
                    backtrack_and_retry(domain, state, solution_tree, parent_id, depth, max_depth, verbose)
                end

              {:error, reason} ->
                {:error, reason}
            end
        end
    end
  end

  # Backtrack to try alternative method at a node
  @spec backtrack_to_alternative_method(solution_tree(), node_id(), node_id(), integer()) ::
    {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  defp backtrack_to_alternative_method(solution_tree, parent_id, _failed_child_id, verbose) do
    case solution_tree.nodes[parent_id] do
      nil ->
        {:error, "Parent node not found: #{parent_id}"}

      parent_node ->
        case parent_node.task do
          {task_name, args} when is_binary(task_name) ->
            # This is a task node - try next available method
            try_next_task_method(solution_tree, parent_id, task_name, args, verbose)

          {predicate, subject, object} ->
            # This is a goal node - try next available method
            try_next_goal_method(solution_tree, parent_id, predicate, subject, object, verbose)

          _ ->
            # Other node types don't have alternative methods
            :no_alternatives
        end
    end
  end

  # Try the next available method for a task node
  @spec try_next_task_method(solution_tree(), node_id(), String.t(), list(), integer()) ::
    {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  defp try_next_task_method(solution_tree, node_id, _task_name, _args, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        # Add the failed method to blacklisted methods
        current_method = node.method_tried
        blacklisted_methods = if current_method do
          [current_method | node.blacklisted_methods]
        else
          node.blacklisted_methods
        end

        # Reset the node for retrying
        reset_node = %{node |
          children_ids: [],
          expanded: false,
          method_tried: nil,
          blacklisted_methods: blacklisted_methods
        }

        # Remove all descendant nodes
        descendant_ids = get_all_descendants(solution_tree, node_id)
        remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)

        # Update the tree
        updated_tree = %{solution_tree |
          nodes: Map.put(remaining_nodes, node_id, reset_node)
        }

        if verbose > 1 do
          IO.puts("Reset node #{node_id} for alternative method, blacklisted: #{inspect(blacklisted_methods)}")
        end

        {:ok, updated_tree}
    end
  end

  # Try the next available method for a goal node
  @spec try_next_goal_method(solution_tree(), node_id(), String.t(), String.t(), any(), integer()) ::
    {:ok, solution_tree()} | :no_alternatives | {:error, String.t()}
  defp try_next_goal_method(solution_tree, node_id, _predicate, _subject, _object, verbose) do
    case solution_tree.nodes[node_id] do
      nil ->
        {:error, "Node not found: #{node_id}"}

      node ->
        # Add the failed method to blacklisted methods
        current_method = node.method_tried
        blacklisted_methods = if current_method do
          [current_method | node.blacklisted_methods]
        else
          node.blacklisted_methods
        end

        # Reset the node for retrying
        reset_node = %{node |
          children_ids: [],
          expanded: false,
          method_tried: nil,
          blacklisted_methods: blacklisted_methods
        }

        # Remove all descendant nodes
        descendant_ids = get_all_descendants(solution_tree, node_id)
        remaining_nodes = Map.drop(solution_tree.nodes, descendant_ids)

        # Update the tree
        updated_tree = %{solution_tree |
          nodes: Map.put(remaining_nodes, node_id, reset_node)
        }

        if verbose > 1 do
          IO.puts("Reset goal node #{node_id} for alternative method, blacklisted: #{inspect(blacklisted_methods)}")
        end

        {:ok, updated_tree}
    end
  end

  # Update cached states in the solution tree
  @spec update_cached_states(solution_tree(), State.t()) :: solution_tree()
  defp update_cached_states(solution_tree, new_state) do
    # Update all node states to the current state
    # This is a simplified implementation - a full implementation would
    # propagate state changes appropriately through the tree
    updated_nodes = Map.new(solution_tree.nodes, fn {id, node} ->
      {id, %{node | state: new_state}}
    end)

    %{solution_tree | nodes: updated_nodes}
  end

  # Get all descendant node IDs
  @spec get_all_descendants(solution_tree(), node_id()) :: [node_id()]
  defp get_all_descendants(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> []
      node ->
        direct_children = node.children_ids
        all_descendants = Enum.flat_map(direct_children, fn child_id ->
          [child_id | get_all_descendants(solution_tree, child_id)]
        end)
        all_descendants
    end
  end

  # Run execution loop for Run-Lazy-Refineahead
  @spec run_execution_loop(Domain.t(), State.t(), solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  defp run_execution_loop(domain, current_state, solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    # Get primitive actions from the solution tree
    actions = get_primitive_actions_dfs(solution_tree)

    if verbose > 0 do
      IO.puts("Executing #{length(actions)} primitive actions")
    end

    # Execute actions one by one with lazy checking
    execute_actions_lazily(domain, current_state, actions, solution_tree, opts)
  end

  # Execute actions with lazy failure checking and replanning
  @spec execute_actions_lazily(Domain.t(), State.t(), [plan_step()], solution_tree(), keyword()) ::
    {:ok, State.t()} | {:error, String.t()}
  defp execute_actions_lazily(_domain, state, [], _solution_tree, _opts) do
    {:ok, state}
  end

  defp execute_actions_lazily(domain, state, [action | remaining_actions], solution_tree, opts) do
    verbose = Keyword.get(opts, :verbose, @default_verbose)

    {action_name, args} = action
    action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

    if verbose > 1 do
      IO.puts("Executing action: #{action_name}(#{inspect(args)})")
    end

    case Domain.execute_action(domain, state, action_atom, args) do
      {:ok, new_state} ->
        # Action succeeded, continue with remaining actions
        execute_actions_lazily(domain, new_state, remaining_actions, solution_tree, opts)

      false ->
        # Action failed - trigger replanning (Run-Lazy-Refineahead core feature)
        if verbose > 0 do
          IO.puts("Action failed: #{action_name}, attempting replanning...")
        end

        # Find the failing node in the solution tree
        case find_action_node(solution_tree, action) do
          nil ->
            {:error, "Action execution failed: #{action_name} (node not found for replanning)"}

          fail_node_id ->
            # Blacklist the failed command to prevent trying it again
            updated_tree = blacklist_command(solution_tree, {action_name, args})

            # Attempt replanning from the failure point
            case replan(domain, state, updated_tree, fail_node_id, opts) do
              {:ok, new_solution_tree} ->
                # Get new action sequence from replanned tree
                new_actions = get_primitive_actions_dfs(new_solution_tree)

                if verbose > 0 do
                  IO.puts("Replanning succeeded, executing #{length(new_actions)} new actions")
                end

                # Execute the new plan
                execute_actions_lazily(domain, state, new_actions, new_solution_tree, opts)

              {:error, reason} ->
                {:error, "Replanning failed: #{reason}"}
            end
        end
    end
  end

  # Find the node ID corresponding to a specific action in the solution tree
  @spec find_action_node(solution_tree(), plan_step()) :: node_id() | nil
  defp find_action_node(solution_tree, target_action) do
    Enum.find_value(solution_tree.nodes, fn {node_id, node} ->
      if node.is_primitive and node.expanded and node.task == target_action do
        node_id
      else
        nil
      end
    end)
  end

  # Get primitive actions from solution tree in depth-first order
  @spec get_primitive_actions_dfs(solution_tree()) :: [plan_step()]
  def get_primitive_actions_dfs(solution_tree) do
    get_actions_from_node(solution_tree, solution_tree.root_id)
  end

  @spec get_actions_from_node(solution_tree(), node_id()) :: [plan_step()]
  defp get_actions_from_node(solution_tree, node_id) do
    case solution_tree.nodes[node_id] do
      nil -> []
      node ->
        if node.is_primitive and node.expanded do
          # This is a primitive action
          case node.task do
            {action_name, args} -> [{action_name, args}]
            _ -> []
          end
        else
          # Recursively get actions from children
          Enum.flat_map(node.children_ids, fn child_id ->
            get_actions_from_node(solution_tree, child_id)
          end)
        end
    end
  end

  # Generate unique node ID
  @spec generate_node_id() :: String.t()
  defp generate_node_id do
    "node_#{:erlang.unique_integer([:positive])}"
  end

  # Compatibility functions for existing AriaEngine API

  @doc """
  Validates a plan by executing it step by step.

  For compatibility with existing AriaEngine usage.
  """
  @spec validate_plan(Domain.t(), State.t(), [plan_step()] | solution_tree()) :: {:ok, State.t()} | {:error, String.t()}
  def validate_plan(%Domain{} = domain, %State{} = initial_state, %{root_id: _} = solution_tree) do
    # Extract primitive actions from solution tree
    actions = get_primitive_actions_dfs(solution_tree)
    validate_plan(domain, initial_state, actions)
  end

  def validate_plan(%Domain{} = domain, %State{} = initial_state, plan) when is_list(plan) do
    Enum.reduce_while(plan, {:ok, initial_state}, fn {action_name, args}, {:ok, state} ->
      action_atom = if is_binary(action_name), do: String.to_atom(action_name), else: action_name

      case Domain.execute_action(domain, state, action_atom, args) do
        false ->
          {:halt, {:error, "Action #{action_name} failed during validation"}}

        {:ok, %State{} = new_state} ->
          {:cont, {:ok, new_state}}
      end
    end)
  end

  @doc """
  Estimates the cost of a plan (simple step count for now).

  For compatibility with existing AriaEngine usage.
  """
  @spec plan_cost([plan_step()] | solution_tree()) :: non_neg_integer()
  def plan_cost(%{root_id: _} = solution_tree) do
    actions = get_primitive_actions_dfs(solution_tree)
    length(actions)
  end

  def plan_cost(plan) when is_list(plan) do
    length(plan)
  end

  @doc """
  Get statistics about the solution tree.

  ## Parameters
  - `solution_tree`: The solution tree to analyze

  ## Returns
  A map with statistics about the tree.
  """
  @spec tree_stats(solution_tree()) :: %{
    total_nodes: integer(),
    expanded_nodes: integer(),
    primitive_actions: integer(),
    max_depth: integer()
  }
  def tree_stats(solution_tree) do
    nodes = Map.values(solution_tree.nodes)

    %{
      total_nodes: length(nodes),
      expanded_nodes: Enum.count(nodes, & &1.expanded),
      primitive_actions: length(get_primitive_actions_dfs(solution_tree)),
      max_depth: calculate_max_depth(solution_tree, solution_tree.root_id, 0)
    }
  end

  @spec calculate_max_depth(solution_tree(), node_id(), integer()) :: integer()
  defp calculate_max_depth(solution_tree, node_id, current_depth) do
    case solution_tree.nodes[node_id] do
      nil -> current_depth
      node ->
        if Enum.empty?(node.children_ids) do
          current_depth
        else
          Enum.map(node.children_ids, fn child_id ->
            calculate_max_depth(solution_tree, child_id, current_depth + 1)
          end)
          |> Enum.max()
        end
    end
  end
end
