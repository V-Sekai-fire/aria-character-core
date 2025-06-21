# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter.GoalMethods do
  @moduledoc """
  Creates goal methods for resource constraints and optimization.

  This module handles the creation of unigoal methods that manage
  resource constraints, dependency constraints, and optimization
  goals for the scheduling domain.
  """

  require Logger
  alias AriaEngine.Scheduler.{Entity, Resource}

  @type activity :: map()
  @type goal_methods :: %{String.t() => [{String.t(), function()}]}

  @doc """
  Create goal methods for resource constraints and optimization.
  """
  @spec create_goal_methods([activity()], [Entity.t()], [Resource.t()]) :: goal_methods()
  def create_goal_methods(activities, entities, resources) do
    %{}
    |> Map.merge(create_resource_constraint_goals(resources))
    |> Map.merge(create_dependency_constraint_goals(activities))
    |> Map.merge(create_optimization_goals(activities, entities, resources))
  end

  @doc """
  Create unigoal methods for resource constraints.
  """
  @spec create_resource_constraint_goals([Resource.t()]) :: goal_methods()
  def create_resource_constraint_goals(resources) do
    resources
    |> Enum.reduce(%{}, fn resource, acc ->
      goal_type = "resource_available_#{resource.id}"
      method_name = "check_resource_capacity"

      method_fn = fn _args, state ->
        current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0
        capacity = resource.capacity

        if current_usage < capacity do
          # Goal already satisfied
          []
        else
          # Return proper task format to free up resources
          [{"wait_for_resource_#{resource.id}", []}]
        end
      end

      Map.put(acc, goal_type, [{method_name, method_fn}])
    end)
  end

  @doc """
  Create unigoal methods for dependency constraints.
  """
  @spec create_dependency_constraint_goals([activity()]) :: goal_methods()
  def create_dependency_constraint_goals(activities) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      dependencies = Map.get(activity, :dependencies, [])

      if not Enum.empty?(dependencies) do
        goal_type = "dependencies_satisfied_#{activity["id"]}"
        method_name = "ensure_dependencies"

        method_fn = fn _args, state ->
          incomplete_deps =
            Enum.filter(dependencies, fn dep_id ->
              not AriaEngine.StateV2.matches_exactly?(state, dep_id, "completed", true)
            end)

          if Enum.empty?(incomplete_deps) do
            # All dependencies satisfied
            []
          else
            # Return tasks to complete dependencies (proper task format)
            Enum.map(incomplete_deps, fn dep_id ->
              {"execute_#{dep_id}", []}
            end)
          end
        end

        Map.put(acc, goal_type, [{method_name, method_fn}])
      else
        acc
      end
    end)
  end

  @doc """
  Create optimization goal methods.
  """
  @spec create_optimization_goals([activity()], [Entity.t()], [Resource.t()]) :: goal_methods()
  def create_optimization_goals(activities, _entities, resources) do
    %{
      "minimize_makespan" => [
        {
          "optimize_execution_time",
          fn _args, state ->
            # Check if all activities are completed
            all_completed =
              Enum.all?(activities, fn activity ->
                AriaEngine.StateV2.matches_exactly?(state, activity["id"], "completed", true)
              end)

            if all_completed do
              # Optimization goal satisfied
              []
            else
              # Return proper task format for optimization
              [{"optimize_schedule", []}]
            end
          end
        }
      ],
      "maximize_resource_efficiency" => [
        {
          "balance_resource_usage",
          fn _args, state ->
            # Check resource utilization balance
            utilizations =
              resources
              |> Enum.map(fn resource ->
                current_usage =
                  AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0

                capacity = resource.capacity
                if capacity > 0, do: current_usage / capacity, else: 0
              end)

            if Enum.empty?(utilizations) do
              []
            else
              avg_utilization = Enum.sum(utilizations) / length(utilizations)

              if avg_utilization > 0.8 do
                # Return proper task format for rebalancing
                [{"rebalance_resources", []}]
              else
                []
              end
            end
          end
        }
      ]
    }
  end

  @doc """
  Create goal method for activity completion checking.
  """
  @spec create_activity_completion_goal(activity()) :: {String.t(), [{String.t(), function()}]}
  def create_activity_completion_goal(activity) do
    activity_id = activity["id"]
    goal_type = "activity_completed_#{activity_id}"
    method_name = "check_completion_status"

    method_fn = fn _args, state ->
      if AriaEngine.StateV2.matches_exactly?(state, activity_id, "completed", true) do
        # Activity already completed
        []
      else
        # Return task to complete the activity
        [{"execute_#{activity_id}", []}]
      end
    end

    {goal_type, [{method_name, method_fn}]}
  end

  @doc """
  Create goal method for resource availability checking.
  """
  @spec create_resource_availability_goal(Resource.t()) :: {String.t(), [{String.t(), function()}]}
  def create_resource_availability_goal(resource) do
    goal_type = "resource_available_#{resource.id}"
    method_name = "ensure_resource_availability"

    method_fn = fn _args, state ->
      current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0
      capacity = resource.capacity

      if current_usage < capacity do
        # Resource is available
        []
      else
        # Resource at capacity, need to wait or reallocate
        [{"wait_for_resource_#{resource.id}", []}]
      end
    end

    {goal_type, [{method_name, method_fn}]}
  end

  @doc """
  Create goal method for dependency satisfaction.
  """
  @spec create_dependency_satisfaction_goal(activity()) :: {String.t(), [{String.t(), function()}]} | nil
  def create_dependency_satisfaction_goal(activity) do
    dependencies = Map.get(activity, :dependencies, [])

    if Enum.empty?(dependencies) do
      nil
    else
      activity_id = activity["id"]
      goal_type = "dependencies_satisfied_#{activity_id}"
      method_name = "ensure_all_dependencies"

      method_fn = fn _args, state ->
        incomplete_deps =
          Enum.filter(dependencies, fn dep_id ->
            not AriaEngine.StateV2.matches_exactly?(state, dep_id, "completed", true)
          end)

        if Enum.empty?(incomplete_deps) do
          # All dependencies satisfied
          []
        else
          # Return tasks to complete dependencies
          Enum.map(incomplete_deps, fn dep_id ->
            {"complete_#{dep_id}", []}
          end)
        end
      end

      {goal_type, [{method_name, method_fn}]}
    end
  end

  @doc """
  Create goal method for schedule optimization.
  """
  @spec create_schedule_optimization_goal([activity()], [Resource.t()]) :: {String.t(), [{String.t(), function()}]}
  def create_schedule_optimization_goal(activities, resources) do
    goal_type = "optimize_schedule"
    method_name = "minimize_makespan_and_balance_resources"

    method_fn = fn _args, state ->
      # Check if all activities are completed
      all_completed =
        Enum.all?(activities, fn activity ->
          AriaEngine.StateV2.matches_exactly?(state, activity["id"], "completed", true)
        end)

      if all_completed do
        # Check resource balance
        utilizations =
          resources
          |> Enum.map(fn resource ->
            current_usage = AriaEngine.StateV2.get_fact(state, resource.id, "current_usage") || 0
            capacity = resource.capacity
            if capacity > 0, do: current_usage / capacity, else: 0
          end)

        if Enum.empty?(utilizations) do
          []
        else
          avg_utilization = Enum.sum(utilizations) / length(utilizations)
          max_utilization = Enum.max(utilizations)

          # Check if resources are well balanced (max utilization not too far from average)
          if max_utilization - avg_utilization > 0.3 do
            [{"rebalance_resource_allocation", []}]
          else
            # Schedule is optimized
            []
          end
        end
      else
        # Not all activities completed, focus on completion first
        incomplete_activities =
          activities
          |> Enum.filter(fn activity ->
            not AriaEngine.StateV2.matches_exactly?(state, activity["id"], "completed", true)
          end)

        Enum.map(incomplete_activities, fn activity ->
          {"prioritize_#{activity["id"]}", []}
        end)
      end
    end

    {goal_type, [{method_name, method_fn}]}
  end
end
