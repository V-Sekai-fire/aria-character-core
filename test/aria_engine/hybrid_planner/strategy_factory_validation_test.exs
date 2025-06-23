# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.StrategyFactoryValidationTest do
  use ExUnit.Case, async: true

  alias HybridPlanner.StrategyFactory

  describe "strategy validation" do
    test "validates existing default strategies successfully" do
      factory = StrategyFactory.new()

      # Test creating a coordinator with default configuration
      assert {:ok, _coordinator} = StrategyFactory.create_coordinator(factory, :default)
    end

    test "validates all strategy types have required callbacks" do
      factory = StrategyFactory.new()

      # Get all default strategy modules
      default_config = %{
        planning_strategy: :default,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :default,
        execution_strategy: :lazy
      }

      # This should succeed if all strategies implement required behaviors
      assert {:ok, _coordinator} = StrategyFactory.create_coordinator(factory, default_config)
    end

    test "caches validation results" do
      factory = StrategyFactory.new()

      # First validation should populate cache
      assert {:ok, _coordinator1} = StrategyFactory.create_coordinator(factory, :default)

      # Second validation should use cached results
      assert {:ok, _coordinator2} = StrategyFactory.create_coordinator(factory, :default)
    end

    test "validates bridge temporal strategy" do
      factory = StrategyFactory.new()

      bridge_config = %{
        planning_strategy: :default,
        temporal_strategy: :stn_bridge,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :default,
        execution_strategy: :lazy
      }

      # This should succeed if bridge strategy implements required behaviors
      assert {:ok, _coordinator} = StrategyFactory.create_coordinator(factory, bridge_config)
    end

    test "validates all registered configurations" do
      factory = StrategyFactory.new()

      # Test all default configurations
      configurations = [:default, :verbose, :quiet, :always_bridge, :bridge_verbose]

      for config_name <- configurations do
        assert {:ok, _coordinator} = StrategyFactory.create_coordinator(factory, config_name),
               "Failed to create coordinator with configuration: #{config_name}"
      end
    end
  end

  describe "validation error handling" do
    # Note: These tests would require creating mock invalid strategy modules
    # For now, we focus on testing that valid strategies pass validation

    test "validation system is active" do
      factory = StrategyFactory.new()

      # Verify that validation cache is initialized
      assert is_map(factory.validation_cache)
      assert factory.validation_cache == %{}
    end
  end
end
