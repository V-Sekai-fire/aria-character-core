defmodule AriaInteractivity.Demo do
  @moduledoc """
  Demo module showcasing glTF 2.0 Interactivity Extension domain usage

  This module demonstrates how to use the glTF interactivity planning domain
  to create and solve temporal planning problems with math operations, flow control,
  and temporal constraints.
  """

  alias AriaState

  @doc """
  Demo 1: Basic Math Operations Planning

  Shows how to create a simple planning problem that performs math operations
  and stores results in state variables.
  """
  def demo_math_operations do
    IO.puts("=== Demo 1: Basic Math Operations Planning ===")

    # Create initial state
    initial_state = AriaState.new()
    |> AriaState.set_fact("input_a", "current", 10)
    |> AriaState.set_fact("input_b", "current", 5)

    # Create planning problem
    problem = %{
      initial_state: initial_state,
      goal_state: %{
        "math_result" => 15,  # 10 + 5 = 15
        "comparison_result" => true  # 15 > 5
      },
      actions: [
        # Add the two inputs
        {:add, [[10, 5]]},
        # Compare result with second input
        {:greater_than, [[15, 5]]}
      ]
    }

    IO.puts("Initial state: #{inspect(initial_state.data)}")
    IO.puts("Goal: #{inspect(problem.goal_state)}")
    IO.puts("Actions: #{inspect(problem.actions)}")

    # Simulate execution (in real implementation, this would go through the planner)
    simulate_execution(problem)
  end

  @doc """
  Demo 2: Flow Control with Temporal Constraints

  Demonstrates sequence execution with temporal constraints between operations.
  """
  def demo_flow_control_temporal do
    IO.puts("\n=== Demo 2: Flow Control with Temporal Constraints ===")

    # Create a sequence of operations with temporal constraints
    sequence_plan = [
      # Step 1: Math operation (instant)
      {:add, [[3, 7]], duration: "PT0S"},

      # Step 2: Wait 2 seconds
      {:delay, [[2]], duration: "PT2S"},

      # Step 3: Animation playback (5 seconds)
      {:play_animation, [{1, true}], duration: "PT5S"},

      # Step 4: Check result
      {:greater_than, [[10, 5]], duration: "PT0S"}
    ]

    IO.puts("Sequence Plan:")
    Enum.each(sequence_plan, fn {action, args, opts} ->
      duration = Keyword.get(opts, :duration, "PT0S")
      IO.puts("  #{action}#{inspect(args)} -> #{duration}")
    end)

    # Calculate total duration
    total_duration = calculate_total_duration(sequence_plan)
    IO.puts("Total sequence duration: #{total_duration}")
  end

  @doc """
  Demo 3: Event-Driven Animation Sequence

  Shows how events can trigger animation sequences with temporal coordination.
  """
  def demo_event_driven_animation do
    IO.puts("\n=== Demo 3: Event-Driven Animation Sequence ===")

    # Event-driven workflow
    workflow = %{
      trigger_event: "user_click",
      sequence: [
        # Wait for event
        {:wait_for_custom_event, [{"user_click"}], duration: "PT0S"},

        # Start animation sequence
        {:play_animation_sequence, [{[1, 2, 3], 0.5}], duration: "PT8S"},

        # Trigger completion event
        {:trigger_event, [{"animation_complete", "sequence_finished"}], duration: "PT0S"}
      ],
      temporal_constraints: [
        {"wait_for_custom_event", "play_animation_sequence", "PT0S"},
        {"play_animation_sequence", "trigger_event", "PT8S"}
      ]
    }

    IO.puts("Event-driven workflow:")
    IO.puts("Trigger: #{workflow.trigger_event}")
    IO.puts("Sequence:")
    Enum.each(workflow.sequence, fn {action, args, duration: dur} ->
      IO.puts("  #{action}#{inspect(args)} (#{dur})")
    end)

    IO.puts("Temporal constraints:")
    Enum.each(workflow.temporal_constraints, fn {from, to, delay} ->
      IO.puts("  #{from} -> #{to} (delay: #{delay})")
    end)
  end

  @doc """
  Demo 4: Complex State Management with Invariants

  Demonstrates state variable management with validation and invariants.
  """
  def demo_state_management do
    IO.puts("\n=== Demo 4: Complex State Management ===")

    # State management workflow
    state_workflow = [
      # Initialize variables
      {:set_variable, [{"counter", 0}], duration: "PT0S"},
      {:set_variable, [{"max_value", 100}], duration: "PT0S"},
      {:set_flag, [{"processing", true}], duration: "PT0S"},

      # Increment counter with validation
      {:increment_variable, [{"counter", 25}], duration: "PT0S"},
      {:variable_less_than, [{"counter", 100}], duration: "PT0S"},

      # More increments
      {:increment_variable, [{"counter", 25}], duration: "PT0S"},
      {:increment_variable, [{"counter", 25}], duration: "PT0S"},
      {:increment_variable, [{"counter", 25}], duration: "PT0S"},

      # Check invariants
      {:check_invariants, [{"counter_invariants"}], duration: "PT0S"},
      {:variable_equals, [{"counter", 100}], duration: "PT0S"},

      # Complete processing
      {:set_flag, [{"processing", false}], duration: "PT0S"},
      {:set_flag, [{"completed", true}], duration: "PT0S"}
    ]

    IO.puts("State management workflow:")
    Enum.each(state_workflow, fn {action, args, duration: dur} ->
      IO.puts("  #{action}#{inspect(args)} (#{dur})")
    end)

    # Simulate state changes
    simulate_state_changes(state_workflow)
  end

  @doc """
  Run all demos
  """
  def run_all_demos do
    IO.puts("🎮 glTF 2.0 Interactivity Extension Domain Demos")
    IO.puts(String.duplicate("=", 50))

    demo_math_operations()
    demo_flow_control_temporal()
    demo_event_driven_animation()
    demo_state_management()

    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("✅ All demos completed successfully!")
    IO.puts("🎯 The glTF interactivity domain is ready for temporal planning!")
  end

  # Helper functions

  defp simulate_execution(problem) do
    IO.puts("\nExecuting with temporal planner:")

    # Create domain
    domain = AriaInteractivity.Domain.create_domain()

    # Convert actions to todos format for the planner
    todos = Enum.map(problem.actions, fn {action, args} ->
      {action, args}
    end)

    # Execute using the temporal planner
    case AriaHybridPlanner.run_lazy(domain, problem.initial_state, todos) do
      {:ok, {solution_tree, final_state}} ->
        IO.puts("  ✅ Execution successful!")
        IO.puts("  📊 Solution tree generated with #{length(AriaEngineCore.Plan.get_primitive_actions_dfs(solution_tree))} primitive actions")
        IO.puts("  🎯 Final state: #{inspect(final_state.data)}")

        # Check if goals were achieved
        goals_achieved = check_goals_achieved(final_state, problem.goal_state)
        IO.puts("  🏆 Goals achieved: #{goals_achieved}")

        {:ok, final_state}

      {:error, reason} ->
        IO.puts("  ❌ Execution failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp check_goals_achieved(state, goal_state) do
    Enum.all?(goal_state, fn {key, expected_value} ->
      case AriaState.get_fact(state, "math_result", key) do
        {:ok, actual_value} -> actual_value == expected_value
        {:error, _} -> false
      end
    end)
  end

  defp calculate_total_duration(sequence) do
    # Simple duration calculation (would be more sophisticated in real implementation)
    total_seconds = Enum.reduce(sequence, 0, fn {_action, _args, opts}, acc ->
      duration_str = Keyword.get(opts, :duration, "PT0S")
      seconds = parse_duration(duration_str)
      acc + seconds
    end)

    format_duration(total_seconds)
  end

  defp parse_duration(duration_str) do
    # Simple ISO 8601 duration parser (PT5S = 5 seconds)
    case Regex.run(~r/PT(\d+)S/, duration_str) do
      [_, seconds] -> String.to_integer(seconds)
      _ -> 0
    end
  end

  defp format_duration(seconds) do
    "PT#{seconds}S"
  end

  defp simulate_state_changes(workflow) do
    IO.puts("\nSimulating state changes:")

    # Track state variables
    state = %{
      "counter" => 0,
      "max_value" => 100,
      "processing" => false,
      "completed" => false
    }

    Enum.each(workflow, fn {action, args, _opts} ->
      case {action, args} do
        {:set_variable, [{var, value}]} ->
          ^state = Map.put(state, var, value)
          IO.puts("  #{var} = #{value}")
        {:set_flag, [{flag, value}]} ->
          ^state = Map.put(state, flag, value)
          IO.puts("  #{flag} = #{value}")
        {:increment_variable, [{var, amount}]} ->
          current = Map.get(state, var, 0)
          new_value = current + amount
          ^state = Map.put(state, var, new_value)
          IO.puts("  #{var} += #{amount} (now: #{new_value})")
        {:variable_equals, [{var, expected}]} ->
          actual = Map.get(state, var)
          result = actual == expected
          IO.puts("  #{var} == #{expected}? #{result}")
        _ ->
          IO.puts("  #{action}#{inspect(args)}")
      end
    end)

    IO.puts("\nFinal state: #{inspect(state)}")
  end
end
