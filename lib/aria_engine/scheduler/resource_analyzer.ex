# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Scheduler.ResourceAnalyzer do
  @moduledoc """
  Analyzes resource utilization and provides optimization recommendations.
  
  Calculates metrics like peak usage, efficiency scores, and identifies
  bottlenecks in resource allocation across scheduled activities.
  """
  
  require Logger
  
  @doc """
  Calculate resource utilization metrics.
  """
  def calculate_resource_utilization(schedule, resources) do
    resource_usage = resources
    |> Enum.map(fn resource ->
      # Calculate utilization metrics for each resource
      total_capacity = resource.capacity
      usage_timeline = calculate_usage_timeline(schedule, resource.id)
      peak_usage = calculate_peak_usage(schedule, resource.id)
      average_usage = calculate_average_usage(schedule, resource.id)
      utilization_percentage = calculate_utilization_percentage(schedule, resource.id, total_capacity)
      
      {resource.id, %{
        total_capacity: total_capacity,
        peak_usage: peak_usage,
        average_usage: average_usage,
        utilization_percentage: utilization_percentage,
        usage_timeline: usage_timeline,
        efficiency_score: calculate_efficiency_score(peak_usage, average_usage, total_capacity)
      }}
    end)
    |> Enum.into(%{})
    
    %{
      resource_usage: resource_usage,
      overall_efficiency: calculate_overall_efficiency(resource_usage),
      bottlenecks: identify_bottlenecks(resource_usage),
      recommendations: generate_optimization_recommendations(resource_usage)
    }
  end
  
  @doc """
  Calculate peak concurrent usage of a resource.
  """
  def calculate_peak_usage(schedule, resource_id) do
    # Calculate peak concurrent usage of a resource
    schedule
    |> Enum.filter(fn activity ->
      required_resources = get_in(activity, [:resource_requirements, :resources]) || []
      Enum.member?(required_resources, resource_id)
    end)
    |> length()
  end
  
  @doc """
  Calculate average usage over time.
  """
  def calculate_average_usage(schedule, resource_id) do
    # Calculate average usage over time
    total_activities = length(schedule)
    activities_using_resource = schedule
    |> Enum.filter(fn activity ->
      required_resources = get_in(activity, [:resource_requirements, :resources]) || []
      Enum.member?(required_resources, resource_id)
    end)
    |> length()
    
    if total_activities > 0 do
      activities_using_resource / total_activities
    else
      0
    end
  end
  
  @doc """
  Calculate efficiency score for a resource.
  """
  def calculate_efficiency_score(peak_usage, average_usage, total_capacity) do
    if total_capacity > 0 do
      # Efficiency score based on how well capacity is utilized
      utilization_ratio = average_usage / total_capacity
      peak_ratio = peak_usage / total_capacity
      
      # Balance between high utilization and avoiding overload
      cond do
        peak_ratio > 1.0 -> 0.5  # Overloaded
        utilization_ratio > 0.8 -> 0.9  # High efficiency
        utilization_ratio > 0.6 -> 0.8  # Good efficiency
        utilization_ratio > 0.4 -> 0.6  # Moderate efficiency
        true -> 0.3  # Low efficiency
      end
    else
      0
    end
  end
  
  @doc """
  Calculate overall efficiency across all resources.
  """
  def calculate_overall_efficiency(resource_usage) do
    if map_size(resource_usage) > 0 do
      total_efficiency = resource_usage
      |> Enum.map(fn {_id, metrics} -> metrics.efficiency_score end)
      |> Enum.sum()
      
      total_efficiency / map_size(resource_usage)
    else
      0
    end
  end
  
  @doc """
  Identify resource bottlenecks.
  """
  def identify_bottlenecks(resource_usage) do
    resource_usage
    |> Enum.filter(fn {_id, metrics} ->
      metrics.utilization_percentage > 90
    end)
    |> Enum.map(fn {id, _metrics} -> id end)
  end
  
  @doc """
  Generate optimization recommendations.
  """
  def generate_optimization_recommendations(resource_usage) do
    recommendations = []
    
    # Check for overutilized resources
    overutilized = resource_usage
    |> Enum.filter(fn {_id, metrics} -> metrics.utilization_percentage > 90 end)
    
    recommendations = if not Enum.empty?(overutilized) do
      ["Consider increasing capacity for overutilized resources: #{Enum.map(overutilized, fn {id, _} -> id end) |> Enum.join(", ")}" | recommendations]
    else
      recommendations
    end
    
    # Check for underutilized resources
    underutilized = resource_usage
    |> Enum.filter(fn {_id, metrics} -> metrics.utilization_percentage < 30 end)
    
    recommendations = if not Enum.empty?(underutilized) do
      ["Consider reducing capacity or reassigning underutilized resources: #{Enum.map(underutilized, fn {id, _} -> id end) |> Enum.join(", ")}" | recommendations]
    else
      recommendations
    end
    
    recommendations
  end
  
  @doc """
  Calculate usage timeline for a resource.
  """
  def calculate_usage_timeline(schedule, resource_id) do
    # Find all activities that use this resource
    activities_using_resource = schedule
    |> Enum.filter(fn activity ->
      required_resources = get_in(activity, [:resource_requirements, :resources]) || []
      Enum.member?(required_resources, resource_id)
    end)
    
    # Create timeline entries
    activities_using_resource
    |> Enum.map(fn activity ->
      %{
        task_id: activity.id,
        start_time: activity.start_time,
        end_time: activity.end_time,
        duration: activity.end_time - activity.start_time
      }
    end)
    |> Enum.sort_by(& &1.start_time)
  end
  
  @doc """
  Calculate utilization percentage for a resource.
  """
  def calculate_utilization_percentage(schedule, resource_id, total_capacity) do
    if total_capacity == 0 do
      0
    else
      # Calculate total time the resource is used
      usage_timeline = calculate_usage_timeline(schedule, resource_id)
      
      if Enum.empty?(usage_timeline) do
        0
      else
        # Calculate total usage time
        total_usage_time = usage_timeline
        |> Enum.map(& &1.duration)
        |> Enum.sum()
        
        # Calculate total schedule time span
        max_end_time = schedule
        |> Enum.map(& &1.end_time)
        |> Enum.max(fn -> 0 end)
        
        if max_end_time > 0 do
          # Utilization as percentage of total time
          (total_usage_time / max_end_time) * 100
        else
          0
        end
      end
    end
  end
end
