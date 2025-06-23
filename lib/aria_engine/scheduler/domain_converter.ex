# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter do
  @moduledoc "Converts activities and resources into domain format for the hybrid planner.\n\nUses two-phase approach:\n1. HTN decomposition with KHR primitives for feasibility\n2. Goal-based optimization for optimality\n\nThis module has been split into focused sub-modules for better maintainability:\n- ActivityActions: Basic activity action creation\n- DurativeActions: Durative action structs and temporal constraints\n- HTNMethods: HTN task methods and dependency handling\n- GoalMethods: Resource constraints and optimization goals\n- KHRPrimitives: KHR primitive sequences for activities\n"
  require Logger
  alias Domain
  alias AriaEngine.Scheduler.{Entity, Resource}

  alias AriaEngine.Scheduler.DomainConverter.{
    ActivityActions,
    DurativeActions,
    HTNMethods,
    GoalMethods,
    KHRPrimitives
  }

  @type activity :: map()
  @type task_methods :: %{String.t() => [{String.t(), function()}]}
  @type goal_methods :: %{String.t() => [{String.t(), function()}]}
  @type optimization_goal :: {String.t(), function()}
  @type khr_primitive :: {String.t(), list()}
  @doc "Convert activities to KHR-primitive-based domain with two-phase planning.\n"
  @spec convert_activities_to_khr_domain([activity()], [Entity.t()], [Resource.t()], map()) ::
          {:ok, Domain.t()} | {:error, String.t()}
  def convert_activities_to_khr_domain(activities, entities, resources, _constraints) do
    try do
      basic_actions =
        ActivityActions.create_basic_activity_actions(activities, entities, resources)

      durative_actions = DurativeActions.create_durative_actions(activities, entities, resources)
      task_methods = HTNMethods.create_htn_scheduling_methods(activities, entities, resources)
      goal_methods = GoalMethods.create_goal_methods(activities, entities, resources)

      domain =
        Domain.new("scheduler_domain")
        |> Domain.add_actions(basic_actions)
        |> add_durative_actions_to_domain(durative_actions)
        |> add_task_methods_to_domain(task_methods)
        |> add_goal_methods_to_domain(goal_methods)

      {:ok, domain}
    rescue
      e -> {:error, "Domain creation failed: #{Exception.message(e)}"}
    end
  end

  @doc "Create basic activity actions for the domain.\nDelegates to ActivityActions module.\n"
  @spec create_basic_activity_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => function()
        }
  def create_basic_activity_actions(activities, entities, resources) do
    ActivityActions.create_basic_activity_actions(activities, entities, resources)
  end

  @doc "Create durative actions for activities.\nDelegates to DurativeActions module.\n"
  @spec create_durative_actions([activity()], [Entity.t()], [Resource.t()]) :: %{
          atom() => Domain.DurativeAction.t()
        }
  def create_durative_actions(activities, entities, resources) do
    DurativeActions.create_durative_actions(activities, entities, resources)
  end

  @doc "Create HTN scheduling methods for Phase 1 (feasibility).\nDelegates to HTNMethods module.\n"
  @spec create_htn_scheduling_methods([activity()], [Entity.t()], [Resource.t()]) ::
          task_methods()
  def create_htn_scheduling_methods(activities, entities, resources) do
    HTNMethods.create_htn_scheduling_methods(activities, entities, resources)
  end

  @doc "Create goal methods for resource constraints and optimization.\nDelegates to GoalMethods module.\n"
  @spec create_goal_methods([activity()], [Entity.t()], [Resource.t()]) :: goal_methods()
  def create_goal_methods(activities, entities, resources) do
    GoalMethods.create_goal_methods(activities, entities, resources)
  end

  @doc "Create sequence of KHR primitive actions to complete an activity.\nDelegates to KHRPrimitives module.\n"
  @spec create_khr_primitive_sequence(activity(), [Entity.t()], [Resource.t()]) :: [
          khr_primitive()
        ]
  def create_khr_primitive_sequence(activity, entities, resources) do
    primitive_sequence =
      KHRPrimitives.create_activity_primitive_sequence(activity, entities, resources)

    Enum.map(primitive_sequence, fn primitive ->
      action = Map.get(primitive, :action, "unknown")
      parameters = Map.get(primitive, :parameters, %{})

      case Map.get(primitive, :type) do
        "resource_operation" ->
          resource_id = Map.get(parameters, :resource_id)
          operation = Map.get(parameters, :operation)

          case operation do
            "increment_usage" -> {"math/add", [0, resource_id, "current_usage", 1]}
            "decrement_usage" -> {"math/sub", [0, resource_id, "current_usage", 1]}
            _ -> {action, []}
          end

        "state_update" ->
          activity_id = Map.get(parameters, :activity_id)
          {"variable/set", [0, activity_id, "status", "completed"]}

        "durative_action" ->
          _activity_id = Map.get(parameters, :activity_id)
          {"flow/setDelay", [0, 1]}

        _ ->
          {action, []}
      end
    end)
  end

  @spec add_task_methods_to_domain(Domain.t(), task_methods()) :: Domain.t()
  defp add_task_methods_to_domain(domain, task_methods) do
    Enum.reduce(task_methods, domain, fn {task_name, methods}, acc_domain ->
      task_name_str = to_string(task_name)

      Logger.debug(
        "Adding task methods for task: #{inspect(task_name_str)}, methods: #{inspect(methods)}"
      )

      Domain.add_task_methods(acc_domain, task_name_str, methods)
    end)
  end

  @spec add_goal_methods_to_domain(Domain.t(), goal_methods()) :: Domain.t()
  defp add_goal_methods_to_domain(domain, goal_methods) do
    Enum.reduce(goal_methods, domain, fn {goal_type, methods}, acc_domain ->
      Domain.add_unigoal_methods(acc_domain, goal_type, methods)
    end)
  end

  @spec add_durative_actions_to_domain(Domain.t(), %{atom() => Domain.DurativeAction.t()}) ::
          Domain.t()
  defp add_durative_actions_to_domain(domain, durative_actions) do
    Enum.reduce(durative_actions, domain, fn {name, durative_action}, acc_domain ->
      Domain.add_action(acc_domain, name, durative_action)
    end)
  end

  @doc "Create durative action function for a specific activity.\nDelegates to ActivityActions module.\n"
  @spec create_durative_activity_action(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_durative_activity_action(activity, entities, resources) do
    ActivityActions.create_durative_activity_action(activity, entities, resources)
  end

  @doc "Create durative action struct for a specific activity.\nDelegates to DurativeActions module.\n"
  @spec create_durative_action_struct(activity(), [Entity.t()], [Resource.t()]) ::
          Domain.DurativeAction.t()
  def create_durative_action_struct(activity, entities, resources) do
    DurativeActions.create_durative_action_struct(activity, entities, resources)
  end

  @doc "Create individual activity task methods using KHR primitives.\nDelegates to HTNMethods module.\n"
  @spec create_activity_task_methods([activity()], [Entity.t()], [Resource.t()]) :: task_methods()
  def create_activity_task_methods(activities, entities, resources) do
    HTNMethods.create_activity_task_methods(activities, entities, resources)
  end

  @doc "Create activity scheduling method that returns proper todo list for hybrid planner.\nDelegates to HTNMethods module.\n"
  @spec create_activity_scheduling_method(activity(), [Entity.t()], [Resource.t()]) :: function()
  def create_activity_scheduling_method(activity, entities, resources) do
    HTNMethods.create_activity_scheduling_method(activity, entities, resources)
  end

  @doc "Create unigoal methods for resource constraints.\nDelegates to GoalMethods module.\n"
  @spec create_resource_constraint_goals([Resource.t()]) :: goal_methods()
  def create_resource_constraint_goals(resources) do
    GoalMethods.create_resource_constraint_goals(resources)
  end

  @doc "Create unigoal methods for dependency constraints.\nDelegates to GoalMethods module.\n"
  @spec create_dependency_constraint_goals([activity()]) :: goal_methods()
  def create_dependency_constraint_goals(activities) do
    GoalMethods.create_dependency_constraint_goals(activities)
  end

  @doc "Create optimization goal methods.\nDelegates to GoalMethods module.\n"
  @spec create_optimization_goals([activity()], [Entity.t()], [Resource.t()]) :: goal_methods()
  def create_optimization_goals(activities, entities, resources) do
    GoalMethods.create_optimization_goals(activities, entities, resources)
  end

  @doc "Create timing constraint fixing durative action.\nDelegates to DurativeActions module.\n"
  @spec create_timing_constraint_durative_action([activity()]) :: Domain.DurativeAction.t()
  def create_timing_constraint_durative_action(activities) do
    DurativeActions.create_timing_constraint_durative_action(activities)
  end

  @doc "Create action function for timing constraint fixing using durative actions.\nDelegates to DurativeActions module.\n"
  @spec create_timing_constraint_action_function([activity()]) :: function()
  def create_timing_constraint_action_function(activities) do
    DurativeActions.create_timing_constraint_action_function(activities)
  end

  @doc "Detects circular dependencies in activities using depth-first search.\nDelegates to HTNMethods module.\n"
  @spec detect_circular_dependencies([activity()]) :: :ok | {:error, [String.t()]}
  def detect_circular_dependencies(activities) do
    HTNMethods.detect_circular_dependencies(activities)
  end
end