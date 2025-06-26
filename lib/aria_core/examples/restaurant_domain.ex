defmodule AriaCore.Examples.RestaurantDomain do
  @moduledoc """
  Example restaurant domain demonstrating the unified action specification system.

  This module showcases all features of the ADR-181 implementation:
  - @action attributes with duration, entity requirements, and conditions
  - @task_method attributes for complex goal decomposition
  - Integration with entity management, temporal processing, and state
  - Sociable testing approach leveraging existing AriaCore systems

  ## Domain Overview

  Models a restaurant kitchen with:
  - **Chefs**: Agents with cooking capabilities and skill levels
  - **Equipment**: Ovens, stoves, prep stations with operational states
  - **Ingredients**: Items with availability and quality properties
  - **Meals**: Products with preparation requirements and quality goals

  ## Example Usage

      # Create domain
      domain = AriaCore.UnifiedDomain.create_from_module(RestaurantDomain)

      # Set up initial state
      state = AriaCore.State.Relational.new()
      |> AriaCore.State.Relational.set_fact("status", "chef_1", "available")
      |> AriaCore.State.Relational.set_fact("temperature", "oven_1", 350)
      |> AriaCore.State.Relational.set_fact("ingredient_available", "tomato", true)

      # Define goals
      goals = [{"meal_status", "soup_1", "ready"}]

      # Plan and execute
      {:ok, plan} = AriaCore.plan(domain, state, goals)
  """

  use AriaCore.Domain

  # Simple cooking action with basic requirements
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking], properties: %{skill_level: :intermediate}}
          ],
          preconditions: [
            {"ingredient_available", "tomato", true},
            {"equipment_status", "stove_1", "operational"}
          ],
          effects: [
            {"meal_status", "soup", "cooking"}
          ]
  def cook_soup(state, [soup_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", soup_id, "cooking")
    |> AriaCore.State.Relational.set_fact("chef_status", "chef_1", "busy")
  end

  # Complex cooking action with variable duration based on skill
  @action duration: {:conditional, %{
            {"skill_level", "chef", :expert} => 1800,    # 30 minutes for expert
            {"skill_level", "chef", :intermediate} => 2700, # 45 minutes for intermediate
            {"skill_level", "chef", :novice} => 3600     # 60 minutes for novice
          }},
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :baking]},
            %{type: "equipment", capabilities: [:heating], properties: %{type: "oven"}}
          ],
          preconditions: [
            {"ingredient_available", "flour", true},
            {"ingredient_available", "eggs", true},
            {"temperature", "oven", {:>=, 350}}
          ],
          effects: [
            {"meal_status", "bread", "ready"},
            {"chef_status", "chef", "available"}
          ]
  def bake_bread(state, [bread_id, chef_id, oven_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", bread_id, "ready")
    |> AriaCore.State.Relational.set_fact("chef_status", chef_id, "available")
    |> AriaCore.State.Relational.set_fact("oven_usage", oven_id, "free")
  end

  # Preparation action with parallel execution capability
  @action duration: "PT15M",
          requires_entities: [
            %{type: "agent", capabilities: [:food_prep]},
            %{type: "equipment", capabilities: [:cutting], properties: %{type: "prep_station"}}
          ],
          preconditions: [
            {"ingredient_available", "vegetables", true}
          ],
          effects: [
            {"ingredient_status", "vegetables", "prepped"},
            {"prep_station_status", "station", "clean"}
          ]
  def prep_vegetables(state, [vegetable_type, station_id]) do
    state
    |> AriaCore.State.Relational.set_fact("ingredient_status", vegetable_type, "prepped")
    |> AriaCore.State.Relational.set_fact("prep_station_status", station_id, "clean")
  end

  # Quality control action with comparison conditions
  @action duration: "PT5M",
          requires_entities: [
            %{type: "agent", capabilities: [:quality_control]}
          ],
          preconditions: [
            {"meal_status", "dish", "cooked"},
            {"temperature", "dish", {:<, 140}}  # Food safety temperature
          ],
          effects: [
            {"quality_rating", "dish", {:>=, 8}},
            {"meal_status", "dish", "ready"}
          ]
  def quality_check(state, [dish_id, inspector_id]) do
    # Simulate quality assessment
    quality_score = calculate_quality_score(state, dish_id)

    state
    |> AriaCore.State.Relational.set_fact("quality_rating", dish_id, quality_score)
    |> AriaCore.State.Relational.set_fact("meal_status", dish_id, "ready")
    |> AriaCore.State.Relational.set_fact("inspector_status", inspector_id, "available")
  end

  # Equipment maintenance action with resource dependencies
  @action duration: {:resource_dependent, %{
            resource_type: "maintenance_tools",
            base_duration: 1800,  # 30 minutes base
            efficiency_map: %{
              :professional => 0.7,  # 30% faster with professional tools
              :standard => 1.0,      # Normal speed with standard tools
              :basic => 1.3          # 30% slower with basic tools
            }
          }},
          requires_entities: [
            %{type: "agent", capabilities: [:maintenance]},
            %{type: "equipment", properties: %{maintenance_required: true}}
          ],
          effects: [
            {"equipment_status", "equipment", "operational"},
            {"maintenance_required", "equipment", false},
            {"last_maintenance", "equipment", "today"}
          ]
  def maintain_equipment(state, [equipment_id, technician_id]) do
    state
    |> AriaCore.State.Relational.set_fact("equipment_status", equipment_id, "operational")
    |> AriaCore.State.Relational.set_fact("maintenance_required", equipment_id, false)
    |> AriaCore.State.Relational.set_fact("last_maintenance", equipment_id, Date.utc_today())
    |> AriaCore.State.Relational.set_fact("technician_status", technician_id, "available")
  end

  # Task method for complex meal preparation
  @task_method goal_pattern: {"meal_ready", :meal_id, true},
               priority: 1
  def prepare_complete_meal_method(_state, [meal_id]) do
    # Decompose complex meal preparation into steps
    {:ok, [
      # Prerequisites: ensure ingredients and equipment
      {"ingredient_available", "main_ingredient", true},
      {"equipment_status", "primary_equipment", "operational"},

      # Preparation phase
      {:prep_ingredients, [meal_id]},

      # Cooking phase (parallel tasks)
      {:cook_main_course, [meal_id]},
      {:prepare_side_dishes, [meal_id]},

      # Quality and finishing
      {:quality_check, [meal_id]},
      {"meal_status", meal_id, "ready"}
    ]}
  end

  # Task method for handling rush orders (high priority)
  @task_method goal_pattern: {"rush_order_ready", :order_id, true},
               priority: 10  # High priority for rush orders
  def rush_order_method(_state, [order_id]) do
    # Optimized decomposition for rush orders
    {:ok, [
      # Skip some prep steps, use pre-prepped ingredients
      {"ingredient_status", "pre_prepped", true},

      # Use fastest cooking methods
      {:quick_cook, [order_id]},

      # Minimal quality check
      {:basic_quality_check, [order_id]},

      {"rush_order_status", order_id, "ready"}
    ]}
  end

  # Task method for handling dietary restrictions
  @task_method goal_pattern: {"special_diet_meal", :meal_id, true},
               priority: 5
  def special_diet_method(state, [meal_id]) do
    # Check dietary requirements and adapt preparation
    dietary_requirements = get_dietary_requirements(state, meal_id)

    base_steps = [
      {"dietary_requirements_checked", meal_id, true},
      {:verify_ingredients, [meal_id, dietary_requirements]},
      {:prepare_special_meal, [meal_id, dietary_requirements]},
      {:allergen_check, [meal_id]},
      {"special_diet_meal", meal_id, "ready"}
    ]

    {:ok, base_steps}
  end

  # Helper functions for action implementations

  defp calculate_quality_score(state, dish_id) do
    # Simulate quality calculation based on state factors
    base_score = 7

    # Check cooking time adherence
    cooking_time_bonus = case AriaCore.State.Relational.get_fact(state, "cooking_time", dish_id) do
      {:ok, time} when time <= 30 -> 1  # Perfect timing
      {:ok, time} when time <= 35 -> 0  # Acceptable
      _ -> -1  # Overcooked
    end

    # Check ingredient quality
    ingredient_bonus = case AriaCore.State.Relational.get_fact(state, "ingredient_quality", dish_id) do
      {:ok, "premium"} -> 2
      {:ok, "standard"} -> 0
      _ -> -1
    end

    max(1, min(10, base_score + cooking_time_bonus + ingredient_bonus))
  end

  defp get_dietary_requirements(state, meal_id) do
    # Extract dietary requirements from state
    case AriaCore.State.Relational.get_fact(state, "dietary_requirements", meal_id) do
      {:ok, requirements} -> requirements
      _ -> []
    end
  end

  # Domain-specific helper functions

  @doc """
  Sets up a typical restaurant initial state for testing.
  """
  def create_test_state() do
    AriaCore.State.Relational.new()
    |> AriaCore.State.Relational.set_fact("status", "chef_1", "available")
    |> AriaCore.State.Relational.set_fact("skill_level", "chef_1", :intermediate)
    |> AriaCore.State.Relational.set_fact("status", "chef_2", "available")
    |> AriaCore.State.Relational.set_fact("skill_level", "chef_2", :expert)
    |> AriaCore.State.Relational.set_fact("equipment_status", "oven_1", "operational")
    |> AriaCore.State.Relational.set_fact("temperature", "oven_1", 350)
    |> AriaCore.State.Relational.set_fact("equipment_status", "stove_1", "operational")
    |> AriaCore.State.Relational.set_fact("equipment_status", "prep_station_1", "clean")
    |> AriaCore.State.Relational.set_fact("ingredient_available", "tomato", true)
    |> AriaCore.State.Relational.set_fact("ingredient_available", "flour", true)
    |> AriaCore.State.Relational.set_fact("ingredient_available", "eggs", true)
    |> AriaCore.State.Relational.set_fact("ingredient_available", "vegetables", true)
    |> AriaCore.State.Relational.set_fact("ingredient_quality", "tomato", "premium")
  end

  @doc """
  Creates typical restaurant goals for testing.
  """
  def create_test_goals() do
    [
      {"meal_status", "soup_1", "ready"},
      {"meal_status", "bread_1", "ready"},
      {"quality_rating", "soup_1", {:>=, 8}}
    ]
  end

  @doc """
  Creates a domain from this module's @action and @task_method attributes.

  This function is required by the ActionAttributes system.
  """
  def create_domain() do
    AriaCore.UnifiedDomain.create_from_module(__MODULE__)
  end

  @doc """
  Demonstrates the complete workflow from domain creation to execution.
  """
  def demo_workflow() do
    # Create domain using unified system
    domain = AriaCore.UnifiedDomain.create_from_module(__MODULE__)

    # Set up state and goals
    initial_state = create_test_state()
    goals = create_test_goals()

    # This would integrate with existing planning system
    %{
      domain: domain,
      initial_state: initial_state,
      goals: goals,
      actions_available: AriaCore.Domain.list_actions(domain),
      methods_available: AriaCore.Domain.list_methods(domain)
    }
  end
end
