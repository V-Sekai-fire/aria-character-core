# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore.Examples.RestaurantDomain do
  @moduledoc """
  Example restaurant domain demonstrating ADR-181 compliant unified action specification.

  This module showcases the correct ADR-181 implementation:
  - @action attributes with ONLY temporal fields and entity requirements
  - @unigoal_method attributes for single goal achievement with prerequisites/verification
  - @task_method attributes for complex workflow decomposition (no goal patterns)
  - Integration with entity management, temporal processing, and state
  - Sociable testing approach leveraging existing AriaCore systems

  ## ADR-181 Compliance

  **Actions are simple durative actions:**
  - Only `duration`, `start`, `end` temporal fields (all optional per 9-pattern system)
  - Only `requires_entities` for resource specification
  - NO preconditions or effects in action metadata
  - Pure state transformation functions

  **Complex logic handled by proper method types:**
  - @unigoal_method with `predicate:` for single goal achievement
  - @task_method (no goal_pattern) for workflow decomposition
  - Prerequisites moved to method decomposition logic
  - Effects verification moved to method goals
  - Natural hierarchical planning approach

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

      # Define goals - use task methods for complex workflows
      goals = [{"meal_status", "soup_1", "ready"}]

      # Plan and execute - planner will use task methods for decomposition
      {:ok, plan} = AriaCore.plan(domain, state, goals)
  """

  use AriaCore.Domain
  use AriaCore.ActionAttributes

  # ============================================================================
  # SIMPLE DURATIVE ACTIONS (ADR-181 COMPLIANT)
  # ============================================================================

  # Simple cooking action - floating duration, planner schedules when convenient
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking]}
          ]
  def cook_soup(state, [soup_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", soup_id, "cooking")
    |> AriaCore.State.Relational.set_fact("chef_status", "chef_1", "busy")
  end

  # Expert-level baking (30 minutes)
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :baking]},
            %{type: "equipment", capabilities: [:heating]}
          ]
  def bake_bread_expert(state, [bread_id, chef_id, oven_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", bread_id, "ready")
    |> AriaCore.State.Relational.set_fact("chef_status", chef_id, "available")
    |> AriaCore.State.Relational.set_fact("oven_usage", oven_id, "free")
  end

  # Intermediate-level baking (45 minutes)
  @action duration: "PT45M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :baking]},
            %{type: "equipment", capabilities: [:heating]}
          ]
  def bake_bread_intermediate(state, [bread_id, chef_id, oven_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", bread_id, "ready")
    |> AriaCore.State.Relational.set_fact("chef_status", chef_id, "available")
    |> AriaCore.State.Relational.set_fact("oven_usage", oven_id, "free")
  end

  # Novice-level baking (60 minutes)
  @action duration: "PT60M",
          requires_entities: [
            %{type: "agent", capabilities: [:cooking, :baking]},
            %{type: "equipment", capabilities: [:heating]}
          ]
  def bake_bread_novice(state, [bread_id, chef_id, oven_id]) do
    state
    |> AriaCore.State.Relational.set_fact("meal_status", bread_id, "ready")
    |> AriaCore.State.Relational.set_fact("chef_status", chef_id, "available")
    |> AriaCore.State.Relational.set_fact("oven_usage", oven_id, "free")
  end

  # Preparation action with standard duration
  @action duration: "PT15M",
          requires_entities: [
            %{type: "agent", capabilities: [:food_prep]},
            %{type: "equipment", capabilities: [:cutting]}
          ]
  def prep_vegetables(state, [vegetable_type, station_id]) do
    state
    |> AriaCore.State.Relational.set_fact("ingredient_status", vegetable_type, "prepped")
    |> AriaCore.State.Relational.set_fact("prep_station_status", station_id, "clean")
  end

  # Quality control action
  @action duration: "PT5M",
          requires_entities: [
            %{type: "agent", capabilities: [:quality_control]}
          ]
  def quality_check(state, [dish_id, inspector_id]) do
    # Simulate quality assessment
    quality_score = calculate_quality_score(state, dish_id)

    state
    |> AriaCore.State.Relational.set_fact("quality_rating", dish_id, quality_score)
    |> AriaCore.State.Relational.set_fact("meal_status", dish_id, "ready")
    |> AriaCore.State.Relational.set_fact("inspector_status", inspector_id, "available")
  end

  # Professional equipment maintenance (21 minutes with professional tools)
  @action duration: "PT21M",
          requires_entities: [
            %{type: "agent", capabilities: [:maintenance]},
            %{type: "equipment", capabilities: [:maintainable]},
            %{type: "tools", capabilities: [:professional]}
          ]
  def maintain_equipment_professional(state, [equipment_id, technician_id]) do
    state
    |> AriaCore.State.Relational.set_fact("equipment_status", equipment_id, "operational")
    |> AriaCore.State.Relational.set_fact("maintenance_required", equipment_id, false)
    |> AriaCore.State.Relational.set_fact("last_maintenance", equipment_id, Date.utc_today())
    |> AriaCore.State.Relational.set_fact("technician_status", technician_id, "available")
  end

  # Standard equipment maintenance (30 minutes with standard tools)
  @action duration: "PT30M",
          requires_entities: [
            %{type: "agent", capabilities: [:maintenance]},
            %{type: "equipment", capabilities: [:maintainable]},
            %{type: "tools", capabilities: [:standard]}
          ]
  def maintain_equipment_standard(state, [equipment_id, technician_id]) do
    state
    |> AriaCore.State.Relational.set_fact("equipment_status", equipment_id, "operational")
    |> AriaCore.State.Relational.set_fact("maintenance_required", equipment_id, false)
    |> AriaCore.State.Relational.set_fact("last_maintenance", equipment_id, Date.utc_today())
    |> AriaCore.State.Relational.set_fact("technician_status", technician_id, "available")
  end

  # Basic equipment maintenance (39 minutes with basic tools)
  @action duration: "PT39M",
          requires_entities: [
            %{type: "agent", capabilities: [:maintenance]},
            %{type: "equipment", capabilities: [:maintainable]},
            %{type: "tools", capabilities: [:basic]}
          ]
  def maintain_equipment_basic(state, [equipment_id, technician_id]) do
    state
    |> AriaCore.State.Relational.set_fact("equipment_status", equipment_id, "operational")
    |> AriaCore.State.Relational.set_fact("maintenance_required", equipment_id, false)
    |> AriaCore.State.Relational.set_fact("last_maintenance", equipment_id, Date.utc_today())
    |> AriaCore.State.Relational.set_fact("technician_status", technician_id, "available")
  end

  # Instant actions (Pattern 1: No temporal specification)
  @action requires_entities: [
            %{type: "agent", capabilities: [:communication]}
          ]
  def announce_meal_ready(state, [meal_id]) do
    state
    |> AriaCore.State.Relational.set_fact("announcement", meal_id, "ready")
    |> AriaCore.State.Relational.set_fact("notification_sent", meal_id, true)
  end

  @action requires_entities: [
            %{type: "agent", capabilities: [:observation]}
          ]
  def check_ingredient_availability(state, [ingredient_list]) do
    available_count = Enum.count(ingredient_list, fn ingredient ->
      case AriaCore.State.Relational.get_fact(state, "ingredient_available", ingredient) do
        {:ok, true} -> true
        _ -> false
      end
    end)

    state
    |> AriaCore.State.Relational.set_fact("ingredients_checked", "kitchen", true)
    |> AriaCore.State.Relational.set_fact("available_ingredient_count", "kitchen", available_count)
  end

  # Fixed time actions (Pattern 8: Fixed interval)
  @action start: "2025-06-22T12:00:00-07:00",
          end: "2025-06-22T12:00:00-07:00",
          requires_entities: [
            %{type: "agent", capabilities: [:communication]},
            %{type: "bell", capabilities: [:sound]}
          ]
  def ring_lunch_bell(state, []) do
    state
    |> AriaCore.State.Relational.set_fact("bell_status", "lunch_bell", "rung")
    |> AriaCore.State.Relational.set_fact("lunch_announced", "kitchen", true)
  end

  # Additional actions referenced by new unigoal methods
  @action duration: "PT2M",
          requires_entities: [
            %{type: "agent", capabilities: [:management]}
          ]
  def mark_chef_available(state, [chef_id]) do
    state
    |> AriaCore.State.Relational.set_fact("chef_status", chef_id, "available")
    |> AriaCore.State.Relational.set_fact("current_task", chef_id, "none")
  end

  @action duration: "PT10M",
          requires_entities: [
            %{type: "equipment", capabilities: [:heating]}
          ]
  def heat_equipment(state, [equipment_id, target_temp]) do
    state
    |> AriaCore.State.Relational.set_fact("temperature", equipment_id, target_temp)
    |> AriaCore.State.Relational.set_fact("heating_status", equipment_id, "active")
  end

  @action duration: "PT5M",
          requires_entities: [
            %{type: "agent", capabilities: [:inventory]}
          ]
  def retrieve_ingredient(state, [ingredient_id]) do
    state
    |> AriaCore.State.Relational.set_fact("ingredient_available", ingredient_id, true)
    |> AriaCore.State.Relational.set_fact("ingredient_location", ingredient_id, "prep_area")
    |> AriaCore.State.Relational.set_fact("retrieval_time", ingredient_id, DateTime.utc_now())
  end

  @action duration: "PT20M",
          requires_entities: [
            %{type: "agent", capabilities: [:cleaning]}
          ]
  def clean_workspace(state, [workspace_id]) do
    state
    |> AriaCore.State.Relational.set_fact("workspace_clean", workspace_id, true)
    |> AriaCore.State.Relational.set_fact("last_cleaned", workspace_id, DateTime.utc_now())
    |> AriaCore.State.Relational.set_fact("cleaning_status", workspace_id, "completed")
  end

  @action duration: "PT3M",
          requires_entities: [
            %{type: "agent", capabilities: [:order_management]}
          ]
  def complete_order(state, [order_id]) do
    state
    |> AriaCore.State.Relational.set_fact("order_status", order_id, "completed")
    |> AriaCore.State.Relational.set_fact("completion_time", order_id, DateTime.utc_now())
    |> AriaCore.State.Relational.set_fact("payment_processed", order_id, true)
  end

  @action duration: "PT1H",
          requires_entities: [
            %{type: "agent", capabilities: [:purchasing]}
          ]
  def restock_ingredient(state, [ingredient_id, target_level]) do
    state
    |> AriaCore.State.Relational.set_fact("inventory_level", ingredient_id, target_level)
    |> AriaCore.State.Relational.set_fact("last_restocked", ingredient_id, Date.utc_today())
    |> AriaCore.State.Relational.set_fact("restock_status", ingredient_id, "completed")
  end

  @action duration: "PT10M",
          requires_entities: [
            %{type: "agent", capabilities: [:table_service]}
          ]
  def prepare_table(state, [table_id]) do
    state
    |> AriaCore.State.Relational.set_fact("table_ready", table_id, true)
    |> AriaCore.State.Relational.set_fact("table_status", table_id, "available")
    |> AriaCore.State.Relational.set_fact("setup_time", table_id, DateTime.utc_now())
  end

  @action duration: "PT15M",
          requires_entities: [
            %{type: "agent", capabilities: [:scheduling]}
          ]
  def assign_staff_to_shift(state, [shift_id]) do
    state
    |> AriaCore.State.Relational.set_fact("shift_covered", shift_id, true)
    |> AriaCore.State.Relational.set_fact("staff_assigned", shift_id, "confirmed")
    |> AriaCore.State.Relational.set_fact("assignment_time", shift_id, DateTime.utc_now())
  end

  # ============================================================================
  # UNIGOAL METHODS (SINGLE GOAL ACHIEVEMENT - ADR-181 COMPLIANT)
  # ============================================================================

  # Unigoal method for meal status achievement (soup cooking workflow)
  @unigoal_method predicate: "meal_status"
  def meal_status_goal(state, [subject, value]) when value == "ready" do
    case subject do
      "soup_" <> _id ->
        {:ok, [
          # Prerequisites (former preconditions)
          {"ingredient_available", "tomato", true},
          {"equipment_status", "stove_1", "operational"},
          {"chef_status", "chef_1", "available"},

          # Main cooking action (simple durative action)
          {:cook_soup, [subject]},

          # Verification (former effects)
          {"meal_status", subject, "cooking"}
        ]}

      "bread_" <> _id ->
        # Determine chef skill level and select appropriate action
        chef_id = "chef_1"  # Could be determined dynamically
        oven_id = "oven_1"  # Could be determined dynamically

        skill_level = case AriaCore.State.Relational.get_fact(state, "skill_level", chef_id) do
          {:ok, level} -> level
          _ -> :intermediate  # Default
        end

        action = case skill_level do
          :expert -> {:bake_bread_expert, [subject, chef_id, oven_id]}
          :intermediate -> {:bake_bread_intermediate, [subject, chef_id, oven_id]}
          :novice -> {:bake_bread_novice, [subject, chef_id, oven_id]}
        end

        {:ok, [
          # Prerequisites (former preconditions)
          {"ingredient_available", "flour", true},
          {"ingredient_available", "eggs", true},
          {"temperature", "oven", {:>=, 350}},
          {"chef_status", chef_id, "available"},

          # Skill-appropriate baking action
          action,

          # Verification (former effects)
          {"meal_status", subject, "ready"},
          {"chef_status", chef_id, "available"}
        ]}

      _other ->
        # Generic meal preparation
        {:ok, [
          {"ingredient_available", "main_ingredient", true},
          {"equipment_status", "primary_equipment", "operational"},
          {:prepare_meal, [subject]},
          {"meal_status", subject, value}
        ]}
    end
  end

  # Unigoal method for ingredient status achievement
  @unigoal_method predicate: "ingredient_status"
  def ingredient_status_goal(_state, [subject, value]) when value == "prepped" do
    station_id = "prep_station_1"  # Could be determined dynamically

    {:ok, [
      # Prerequisites (former preconditions)
      {"ingredient_available", subject, true},
      {"prep_station_status", station_id, "clean"},

      # Main preparation action
      {:prep_vegetables, [subject, station_id]},

      # Verification (former effects)
      {"ingredient_status", subject, "prepped"},
      {"prep_station_status", station_id, "clean"}
    ]}
  end

  # Unigoal method for quality rating achievement
  @unigoal_method predicate: "quality_rating"
  def quality_rating_goal(_state, [subject, value]) when is_tuple(value) and elem(value, 0) == :>= do
    {_, target_rating} = value
    inspector_id = "inspector_1"  # Could be determined dynamically

    {:ok, [
      # Prerequisites (former preconditions)
      {"meal_status", subject, "cooked"},
      {"temperature", subject, {:<, 140}},  # Food safety temperature
      {"inspector_status", inspector_id, "available"},

      # Main quality check action
      {:quality_check, [subject, inspector_id]},

      # Verification (former effects)
      {"quality_rating", subject, {:>=, target_rating}},
      {"meal_status", subject, "ready"}
    ]}
  end

  # Unigoal method for equipment status achievement
  @unigoal_method predicate: "equipment_status"
  def equipment_status_goal(state, [subject, value]) when value == "operational" do
    technician_id = "technician_1"  # Could be determined dynamically

    # Determine available tool quality and select appropriate action
    tool_quality = case AriaCore.State.Relational.get_fact(state, "available_tools", "maintenance") do
      {:ok, tools} when is_list(tools) ->
        cond do
          :professional in tools -> :professional
          :standard in tools -> :standard
          :basic in tools -> :basic
          true -> :standard  # Default
        end
      _ -> :standard  # Default
    end

    action = case tool_quality do
      :professional -> {:maintain_equipment_professional, [subject, technician_id]}
      :standard -> {:maintain_equipment_standard, [subject, technician_id]}
      :basic -> {:maintain_equipment_basic, [subject, technician_id]}
    end

    {:ok, [
      # Prerequisites
      {"maintenance_required", subject, true},
      {"technician_status", technician_id, "available"},
      {"tools_available", tool_quality, true},

      # Tool-appropriate maintenance action
      action,

      # Verification
      {"equipment_status", subject, "operational"},
      {"maintenance_required", subject, false}
    ]}
  end

  # ============================================================================
  # TASK METHODS (COMPLEX WORKFLOW DECOMPOSITION - ADR-181 COMPLIANT)
  # ============================================================================

  # Task method for complex meal preparation (true task decomposition)
  @task_method true
  def prepare_complete_meal_method(_state, [meal_id]) do
    # Decompose complex meal preparation into steps
    {:ok, [
      # Prerequisites: ensure ingredients and equipment
      {"ingredient_available", "main_ingredient", true},
      {"equipment_status", "primary_equipment", "operational"},

      # Preparation phase
      {:task_prep_ingredients, [meal_id]},

      # Cooking phase (parallel tasks)
      {:cook_main_course, [meal_id]},
      {:prepare_side_dishes, [meal_id]},

      # Quality and finishing
      {:quality_check, [meal_id, "inspector_1"]},
      {"meal_status", meal_id, "ready"}
    ]}
  end

  # Task method for handling rush orders (task decomposition)
  @task_method true
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

  # Task method for handling dietary restrictions (task decomposition)
  @task_method true
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

  # Additional unigoal methods for remaining predicates
  @unigoal_method predicate: "meal_ready"
  def meal_ready_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Use the task method for complex meal preparation
      {:prepare_complete_meal_method, [subject]}
    ]}
  end

  @unigoal_method predicate: "rush_order_ready"
  def rush_order_ready_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Use the task method for rush order handling
      {:rush_order_method, [subject]}
    ]}
  end

  @unigoal_method predicate: "special_diet_meal"
  def special_diet_meal_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Use the task method for dietary restrictions
      {:special_diet_method, [subject]}
    ]}
  end

  # Unigoal method for chef status management
  @unigoal_method predicate: "chef_status"
  def chef_status_goal(_state, [subject, value]) when value == "available" do
    {:ok, [
      # Prerequisites to make chef available
      {"current_task", subject, "none"},
      {"break_time", subject, false},

      # Action to mark chef as available
      {:mark_chef_available, [subject]},

      # Verification
      {"chef_status", subject, "available"}
    ]}
  end

  # Unigoal method for temperature control
  @unigoal_method predicate: "temperature"
  def temperature_goal(_state, [subject, value]) when is_tuple(value) and elem(value, 0) == :>= do
    {_, target_temp} = value

    {:ok, [
      # Prerequisites
      {"equipment_status", subject, "operational"},
      {"power_supply", subject, "connected"},

      # Action to heat equipment
      {:heat_equipment, [subject, target_temp]},

      # Verification
      {"temperature", subject, {:>=, target_temp}}
    ]}
  end

  # Unigoal method for ingredient availability
  @unigoal_method predicate: "ingredient_available"
  def ingredient_available_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Prerequisites
      {"storage_location", subject, "known"},
      {"expiry_date", subject, {:>, Date.utc_today()}},

      # Action to retrieve ingredient
      {:retrieve_ingredient, [subject]},

      # Verification
      {"ingredient_available", subject, true},
      {"ingredient_location", subject, "prep_area"}
    ]}
  end

  # Unigoal method for workspace cleanliness
  @unigoal_method predicate: "workspace_clean"
  def workspace_clean_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Prerequisites
      {"cleaning_supplies", "available", true},
      {"staff_member", "cleaner", "available"},

      # Action to clean workspace
      {:clean_workspace, [subject]},

      # Verification
      {"workspace_clean", subject, true},
      {"last_cleaned", subject, DateTime.utc_now()}
    ]}
  end

  # Unigoal method for order status tracking
  @unigoal_method predicate: "order_status"
  def order_status_goal(_state, [subject, value]) when value == "completed" do
    {:ok, [
      # Prerequisites
      {"payment_received", subject, true},
      {"meal_status", subject, "ready"},
      {"customer_notified", subject, true},

      # Action to complete order
      {:complete_order, [subject]},

      # Verification
      {"order_status", subject, "completed"},
      {"completion_time", subject, DateTime.utc_now()}
    ]}
  end

  # Unigoal method for inventory management
  @unigoal_method predicate: "inventory_level"
  def inventory_level_goal(_state, [subject, value]) when is_tuple(value) and elem(value, 0) == :>= do
    {_, target_level} = value

    {:ok, [
      # Prerequisites
      {"supplier_contact", subject, "available"},
      {"budget_approved", "purchasing", true},

      # Action to restock
      {:restock_ingredient, [subject, target_level]},

      # Verification
      {"inventory_level", subject, {:>=, target_level}},
      {"last_restocked", subject, Date.utc_today()}
    ]}
  end

  # Unigoal method for table readiness
  @unigoal_method predicate: "table_ready"
  def table_ready_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Prerequisites
      {"table_clean", subject, true},
      {"utensils_set", subject, true},
      {"menu_placed", subject, true},

      # Action to prepare table
      {:prepare_table, [subject]},

      # Verification
      {"table_ready", subject, true},
      {"table_status", subject, "available"}
    ]}
  end

  # Unigoal method for staff scheduling
  @unigoal_method predicate: "shift_covered"
  def shift_covered_goal(_state, [subject, value]) when value == true do
    {:ok, [
      # Prerequisites
      {"staff_available", "pool", {:>=, 1}},
      {"shift_requirements", subject, "defined"},

      # Action to assign staff
      {:assign_staff_to_shift, [subject]},

      # Verification
      {"shift_covered", subject, true},
      {"staff_assigned", subject, "confirmed"}
    ]}
  end

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================

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

  # ============================================================================
  # DOMAIN SETUP AND TESTING HELPERS
  # ============================================================================

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
    |> AriaCore.State.Relational.set_fact("available_tools", "maintenance", [:professional, :standard])
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
