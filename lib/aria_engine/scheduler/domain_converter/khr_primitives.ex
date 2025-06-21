# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.DomainConverter.KHRPrimitives do
  @moduledoc """
  Creates KHR (Khronos Interactivity) primitive sequences for activities.

  This module handles the creation of KHR primitive action sequences
  that represent the low-level execution steps for activities,
  providing detailed temporal and resource management primitives.
  """

  require Logger
  alias AriaEngine.Scheduler.{Entity, Resource}

  @type activity :: map()
  @type khr_primitive :: %{
          type: String.t(),
          action: String.t(),
          parameters: map(),
          timing: map()
        }

  @doc """
  Create KHR primitive sequences for activities.
  """
  @spec create_khr_primitive_sequences([activity()], [Entity.t()], [Resource.t()]) :: %{
          String.t() => [khr_primitive()]
        }
  def create_khr_primitive_sequences(activities, entities, resources) do
    activities
    |> Enum.reduce(%{}, fn activity, acc ->
      activity_id = activity["id"]
      primitive_sequence = create_activity_primitive_sequence(activity, entities, resources)
      Map.put(acc, activity_id, primitive_sequence)
    end)
  end

  @doc """
  Create KHR primitive sequence for a specific activity.
  """
  @spec create_activity_primitive_sequence(activity(), [Entity.t()], [Resource.t()]) :: [
          khr_primitive()
        ]
  def create_activity_primitive_sequence(activity, _entities, _resources) do
    activity_id = activity["id"]
    duration_val = Map.get(activity, :duration)
    required_resources = Map.get(activity, :required_resources, [])
    dependencies = Map.get(activity, :dependencies, [])

    # Create primitive sequence following KHR interactivity patterns
    primitives = []

    # 1. Dependency check primitives
    primitives =
      primitives ++
        Enum.map(dependencies, fn dep_id ->
          create_dependency_check_primitive(activity_id, dep_id)
        end)

    # 2. Resource allocation primitives
    primitives =
      primitives ++
        Enum.map(required_resources, fn resource_id ->
          create_resource_allocation_primitive(activity_id, resource_id)
        end)

    # 3. Activity execution primitive
    execution_primitive = create_activity_execution_primitive(activity_id, duration_val)
    primitives = primitives ++ [execution_primitive]

    # 4. Resource deallocation primitives
    primitives =
      primitives ++
        Enum.map(required_resources, fn resource_id ->
          create_resource_deallocation_primitive(activity_id, resource_id)
        end)

    # 5. Completion marking primitive
    completion_primitive = create_completion_primitive(activity_id)
    primitives ++ [completion_primitive]
  end

  @doc """
  Create dependency check primitive.
  """
  @spec create_dependency_check_primitive(String.t(), String.t()) :: khr_primitive()
  def create_dependency_check_primitive(activity_id, dependency_id) do
    %{
      type: "condition_check",
      action: "verify_dependency_completion",
      parameters: %{
        activity_id: activity_id,
        dependency_id: dependency_id,
        condition: "#{dependency_id}.completed == true"
      },
      timing: %{
        when: "at_start",
        duration: 0,
        priority: "high"
      }
    }
  end

  @doc """
  Create resource allocation primitive.
  """
  @spec create_resource_allocation_primitive(String.t(), String.t()) :: khr_primitive()
  def create_resource_allocation_primitive(activity_id, resource_id) do
    %{
      type: "resource_operation",
      action: "allocate_resource",
      parameters: %{
        activity_id: activity_id,
        resource_id: resource_id,
        operation: "increment_usage",
        target: "#{resource_id}.current_usage"
      },
      timing: %{
        when: "at_start",
        duration: 0,
        priority: "high"
      }
    }
  end

  @doc """
  Create activity execution primitive.
  """
  @spec create_activity_execution_primitive(String.t(), any()) :: khr_primitive()
  def create_activity_execution_primitive(activity_id, duration_val) do
    # Parse duration for KHR timing
    timing_info = parse_duration_for_khr(duration_val)

    %{
      type: "durative_action",
      action: "execute_activity",
      parameters: %{
        activity_id: activity_id,
        status_updates: %{
          at_start: "#{activity_id}.status = 'in_progress'",
          at_end: "#{activity_id}.status = 'completed'"
        }
      },
      timing: timing_info
    }
  end

  @doc """
  Create resource deallocation primitive.
  """
  @spec create_resource_deallocation_primitive(String.t(), String.t()) :: khr_primitive()
  def create_resource_deallocation_primitive(activity_id, resource_id) do
    %{
      type: "resource_operation",
      action: "deallocate_resource",
      parameters: %{
        activity_id: activity_id,
        resource_id: resource_id,
        operation: "decrement_usage",
        target: "#{resource_id}.current_usage"
      },
      timing: %{
        when: "at_end",
        duration: 0,
        priority: "high"
      }
    }
  end

  @doc """
  Create completion marking primitive.
  """
  @spec create_completion_primitive(String.t()) :: khr_primitive()
  def create_completion_primitive(activity_id) do
    %{
      type: "state_update",
      action: "mark_completed",
      parameters: %{
        activity_id: activity_id,
        updates: %{
          "#{activity_id}.completed" => true,
          "#{activity_id}.end_time" => "current_time()"
        }
      },
      timing: %{
        when: "at_end",
        duration: 0,
        priority: "high"
      }
    }
  end

  @doc """
  Parse duration value for KHR timing format.
  """
  @spec parse_duration_for_khr(any()) :: map()
  def parse_duration_for_khr(duration_val) do
    cond do
      # Handle open-ended intervals
      is_map(duration_val) and
          (Map.has_key?(duration_val, "start") or Map.has_key?(duration_val, "end")) ->
        %{
          when: "over_all",
          duration: "variable",
          start_time: Map.get(duration_val, "start"),
          end_time: Map.get(duration_val, "end"),
          priority: "medium"
        }

      is_map(duration_val) and
          (Map.has_key?(duration_val, :start) or Map.has_key?(duration_val, :end)) ->
        %{
          when: "over_all",
          duration: "variable",
          start_time: Map.get(duration_val, :start),
          end_time: Map.get(duration_val, :end),
          priority: "medium"
        }

      # Handle regular duration maps
      is_map(duration_val) ->
        seconds = convert_duration_to_seconds(duration_val)

        %{
          when: "over_all",
          duration: seconds,
          priority: "medium"
        }

      # Handle ISO8601 duration strings
      is_binary(duration_val) ->
        case :iso8601.parse_duration(String.to_charlist(duration_val)) do
          parsed when is_list(parsed) ->
            duration_map = Enum.into(parsed, %{})
            seconds = convert_duration_to_seconds(duration_map)

            %{
              when: "over_all",
              duration: seconds,
              priority: "medium"
            }

          _ ->
            %{
              when: "over_all",
              duration: 1,
              priority: "medium"
            }
        end

      # Handle numeric durations
      is_number(duration_val) ->
        %{
          when: "over_all",
          duration: duration_val,
          priority: "medium"
        }

      true ->
        %{
          when: "over_all",
          duration: 1,
          priority: "medium"
        }
    end
  end

  @doc """
  Create KHR primitive for temporal constraint solving.
  """
  @spec create_temporal_constraint_primitive([activity()]) :: khr_primitive()
  def create_temporal_constraint_primitive(activities) do
    %{
      type: "temporal_solver",
      action: "solve_temporal_constraints",
      parameters: %{
        activities: Enum.map(activities, & &1["id"]),
        solver_type: "durative_actions",
        constraints: "dependency_ordering"
      },
      timing: %{
        when: "before_execution",
        duration: "variable",
        priority: "critical"
      }
    }
  end

  @doc """
  Create KHR primitive for resource optimization.
  """
  @spec create_resource_optimization_primitive([Resource.t()]) :: khr_primitive()
  def create_resource_optimization_primitive(resources) do
    %{
      type: "optimization",
      action: "optimize_resource_allocation",
      parameters: %{
        resources: Enum.map(resources, & &1.id),
        optimization_goal: "minimize_makespan",
        constraints: "capacity_limits"
      },
      timing: %{
        when: "during_execution",
        duration: "continuous",
        priority: "low"
      }
    }
  end

  @doc """
  Convert duration map to seconds for KHR timing.
  """
  @spec convert_duration_to_seconds(map()) :: number()
  def convert_duration_to_seconds(duration_map) do
    years = Map.get(duration_map, :years, 0)
    months = Map.get(duration_map, :months, 0)
    days = Map.get(duration_map, :days, 0)
    hours = Map.get(duration_map, :hours, 0)
    minutes = Map.get(duration_map, :minutes, 0)
    seconds = Map.get(duration_map, :seconds, 0)

    # Convert to total seconds (approximate for years/months)
    total_seconds =
      years * 365 * 24 * 3600 +
        months * 30 * 24 * 3600 +
        days * 24 * 3600 +
        hours * 3600 +
        minutes * 60 +
        seconds

    # Ensure at least 1 second
    max(total_seconds, 1)
  end

  @doc """
  Validate KHR primitive sequence for consistency.
  """
  @spec validate_primitive_sequence([khr_primitive()]) :: {:ok, [khr_primitive()]} | {:error, String.t()}
  def validate_primitive_sequence(primitives) do
    # Check for proper ordering of primitives
    timing_order = ["at_start", "over_all", "at_end"]

    ordered_primitives =
      primitives
      |> Enum.sort_by(fn primitive ->
        timing = Map.get(primitive, :timing, %{})
        when_clause = Map.get(timing, :when, "over_all")
        Enum.find_index(timing_order, &(&1 == when_clause)) || 1
      end)

    # Validate that all required primitive types are present
    types = Enum.map(ordered_primitives, & &1.type)

    required_types = ["durative_action", "state_update"]
    missing_types = required_types -- types

    if Enum.empty?(missing_types) do
      {:ok, ordered_primitives}
    else
      {:error, "Missing required primitive types: #{Enum.join(missing_types, ", ")}"}
    end
  end
end
