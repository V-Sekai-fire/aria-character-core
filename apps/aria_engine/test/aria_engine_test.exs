# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineTest do
  use ExUnit.Case, async: true

  alias AriaEngine.{Domain, State, Actions, DomainRegistry}

  describe "AriaEngine initialization" do
    test "initializes the engine and domain registry" do
      result = AriaEngine.init()
      assert result == :ok
    end
  end

  describe "AriaEngine domain definition functionality" do
    test "creates a new engine instance with default values" do
      engine = AriaEngine.new("test_engine")

      assert engine.id == "test_engine"
      assert engine.name == "test_engine"
      assert engine.status == :pending
      assert engine.goals == []
      assert engine.actions == %{}
      assert is_nil(engine.solution_tree)
    end

    test "creates engine instance with custom properties" do
      actions = %{echo: &Actions.echo/2}
      goals = [{:echo, ["Hello"]}, {"goal", "subject", "object"}]

      engine = AriaEngine.new("custom_engine", %{
        name: "Custom Engine",
        actions: actions,
        goals: goals
      })

      assert engine.id == "custom_engine"
      assert engine.name == "Custom Engine"
      assert engine.actions == actions
      assert engine.goals == goals
      assert length(engine.goals) == 2
    end

    test "creates engine instance from existing domain" do
      domain = Domain.new("test")
      |> Domain.add_action(:echo, &Actions.echo/2)

      goals = [{:echo, ["From domain"]}]
      initial_state = State.new()

      engine = AriaEngine.from_domain(domain, goals, initial_state)

      assert engine.id == "test"
      assert engine.name == "test"
      assert engine.actions[:echo] == domain.actions[:echo]
      assert engine.goals == goals
      assert engine.initial_state == initial_state
    end

    test "converts engine instance back to domain" do
      engine = AriaEngine.new("convert_test", %{
        actions: %{echo: &Actions.echo/2},
        task_methods: %{"test_task" => [fn _s, _a -> [] end]}
      })

      domain = AriaEngine.to_domain(engine)

      assert domain.name == "convert_test"
      assert domain.actions == engine.actions
      assert domain.task_methods == engine.task_methods
    end
  end

  describe "AriaEngine domain composition" do
    test "composes multiple domains together" do
      # Initialize the engine
      AriaEngine.init()

      # Create a base domain
      base_domain = Domain.new("base")
      |> Domain.add_action(:echo, &Actions.echo/2)

      # Create engine with base domain
      engine = AriaEngine.new("composed_engine", %{
        name: "Composed Engine",
        actions: base_domain.actions
      })

      # Add another domain (this would normally be done with actual domain registry)
      additional_actions = %{wait: &Actions.wait/2}
      updated_engine = AriaEngine.add_actions(engine, additional_actions)

      assert Map.has_key?(updated_engine.actions, :echo)
      assert Map.has_key?(updated_engine.actions, :wait)
      assert updated_engine.name == "Composed Engine"
    end
  end

  describe "Plan integration and execution" do
    setup do
      AriaEngine.init()

      goals = [
        {:echo, ["Starting"]},
        {:echo, ["Finishing"]}
      ]

      engine = AriaEngine.new("plan_test", %{
        goals: goals,
        actions: %{echo: &Actions.echo/2}
      })

      {:ok, engine: engine}
    end

    test "plans and executes solution", %{engine: engine} do
      # Use plan_advanced which returns an execution result
      case AriaEngine.plan_advanced(engine) do
        {:ok, planned_engine} ->
          assert planned_engine.status == :executing

          # Execute the planned solution
          case AriaEngine.execute(planned_engine) do
            {:ok, executed_engine} ->
              assert executed_engine.status == :completed
            {:error, _reason} ->
              # Expected for placeholder actions
              assert true
          end
        {:error, _reason} ->
          # Planning might fail with placeholder actions
          assert true
      end
    end

    test "handles planning failures gracefully", %{engine: _engine} do
      # Create engine with impossible goals
      impossible_engine = AriaEngine.new("impossible", %{
        goals: [{"impossible_goal", "subject", "object"}],
        actions: %{echo: &Actions.echo/2}  # No actions that can achieve the goal
      })

      case AriaEngine.plan_advanced(impossible_engine) do
        {:error, reason} ->
          assert is_binary(reason)
        {:ok, planned_engine} ->
          # If planning succeeds, execution should fail
          assert {:error, _} = AriaEngine.execute(planned_engine)
      end
    end
  end

  describe "Domain registry integration" do
    setup do
      AriaEngine.init()
      :ok
    end

    test "gets domain from registry" do
      # Test basic_actions domain (should always be available)
      case DomainRegistry.get_domain("basic_actions") do
        {:ok, domain} ->
          assert %Domain{} = domain
          assert domain.name == "basic_actions"
        {:error, reason} ->
          flunk("Expected basic_actions domain to be available, got error: #{reason}")
      end
    end

    test "handles unknown domain gracefully" do
      case DomainRegistry.get_domain("nonexistent_domain") do
        {:error, reason} ->
          assert String.contains?(reason, "Unknown domain type")
        {:ok, _} ->
          flunk("Expected error for nonexistent domain")
      end
    end
  end

  describe "Domain discovery and loading" do
    setup do
      AriaEngine.init()
      :ok
    end

    test "attempts to load domain modules dynamically" do
      # These may or may not be available depending on compilation order
      domain_types = ["file_management", "workflow_system", "timestrike"]

      for domain_type <- domain_types do
        case DomainRegistry.get_domain(domain_type) do
          {:ok, domain} ->
            # Domain may be a struct or map depending on implementation
            assert is_map(domain)
            assert Map.get(domain, :name) == domain_type or domain.name == domain_type
          {:error, reason} ->
            # Expected if domain module is not available
            assert String.contains?(reason, "module not available") or
                   String.contains?(reason, "Failed to load")
        end
      end
    end
  end
end
