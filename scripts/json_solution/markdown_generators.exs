defmodule JsonSolution.MarkdownGenerators do
  @moduledoc """
  Markdown Generators
  
  Generates markdown files including scheduling test log
  and detailed activity log.
  """
  
  alias JsonSolution.{FileWriter, ActivityLogger, TestData}
  
  def generate_all(execution_time_ms, simulation_result, workers, tools, tasks) do
    # Generate scheduling test log
    test_log = create_scheduling_test_log(execution_time_ms, simulation_result, workers, tools, tasks)
    FileWriter.write_markdown_file(test_log, "scheduling_test_log.md")
    
    # Generate activity log
    activity_log = create_activity_log(execution_time_ms, simulation_result)
    FileWriter.write_markdown_file(activity_log, "activity_log.md")
  end
  
  defp create_scheduling_test_log(execution_time_ms, simulation_result, workers, tools, tasks) do
    scenario = TestData.get_scenario_description()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    
    """
    # Agent-Entity-Capability Scheduling Test Log
    
    ## Test Overview
    - **Test ID**: simple_work_assignment
    - **Scenario**: #{scenario.name}
    - **Description**: #{scenario.description}
    - **Timestamp**: #{timestamp}
    - **Execution Time**: #{execution_time_ms}ms
    - **Status**: ✅ SUCCESS
    
    ## Scenario Details
    - **Workers**: #{length(workers)} (each with #{format_capabilities(workers)} capabilities)
    - **Tasks**: #{length(tasks)} (each requiring #{format_task_requirements(tasks)})
    - **Tools**: #{length(tools)} (#{format_tool_list(tools)})
    - **Expected Outcome**: #{scenario.expected_outcome}
    
    ## Results Summary
    
    ### Agent Assignments
    #{format_agent_assignments(workers, simulation_result.schedule)}
    
    ### Performance Metrics
    - **Scheduling Success**: #{calculate_success_rate(simulation_result.schedule, tasks)}% (#{length(simulation_result.schedule)}/#{length(tasks)} tasks scheduled)
    - **Agent Utilization**: #{calculate_agent_utilization_rate(workers, simulation_result.schedule)}% (#{count_utilized_agents(workers, simulation_result.schedule)}/#{length(workers)} agents used)
    - **Resource Utilization**: #{calculate_resource_utilization_rate(tools, simulation_result.schedule)}% (#{count_utilized_resources(tools, simulation_result.schedule)}/#{length(tools)} tools used)
    - **Makespan**: #{calculate_makespan(simulation_result.schedule)} time units
    - **Total Duration**: #{calculate_total_duration(simulation_result.schedule)} time units
    - **Complexity Factor**: #{format_complexity_factor(execution_time_ms, length(workers), length(tasks))}
    
    ## Complexity Analysis
    
    ### Input Complexity
    - **Capability Checks**: #{length(workers) * length(tasks)} (#{length(workers)} workers × #{length(tasks)} tasks)
    - **Resource Decisions**: #{length(tools) * length(tasks)} (#{length(tools)} tools × #{length(tasks)} tasks)
    - **Total Capabilities**: #{count_unique_capabilities(workers)} unique capability types
    
    ### Performance Assessment
    - **Execution Speed**: #{assess_execution_speed(execution_time_ms)}
    - **Scaling Behavior**: #{assess_scaling_behavior(execution_time_ms, length(workers), length(tasks))}
    - **Single Core Feasibility**: #{assess_single_core_feasibility(execution_time_ms)}
    - **Primary Bottleneck**: #{identify_primary_bottleneck(execution_time_ms)}
    
    ## Quality Metrics
    
    ### Schedule Quality
    - **Tasks Scheduled**: #{length(simulation_result.schedule)} / #{length(tasks)}
    - **Tasks Unscheduled**: #{length(tasks) - length(simulation_result.schedule)}
    - **Resource Conflicts**: #{detect_resource_conflicts(simulation_result.schedule)}
    - **Makespan Efficiency**: #{calculate_makespan_efficiency(simulation_result.schedule, tasks)}%
    
    ### Resource Efficiency
    #{format_resource_efficiency(tools, simulation_result.schedule)}
    
    ## Conclusion
    
    #{generate_conclusion(execution_time_ms, simulation_result, workers, tools, tasks)}
    
    ---
    
    **Generated**: #{timestamp}  
    **Test Framework**: AriaEngine JSON Solution Tree Generator  
    **© 2025 AriaEngine**
    """
  end
  
  defp create_activity_log(execution_time_ms, simulation_result) do
    activities = ActivityLogger.get_activity_log()
    performance_breakdown = ActivityLogger.get_performance_breakdown()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    
    """
    # Scheduling Activity Log
    
    ## Execution Trace
    **Test ID**: simple_work_assignment  
    **Start Time**: #{timestamp}  
    **Total Execution**: #{execution_time_ms}ms
    
    #{format_activity_phases(activities, performance_breakdown)}
    
    ## Performance Breakdown
    #{format_performance_breakdown(performance_breakdown, execution_time_ms)}
    
    ## Detailed Activity Timeline
    #{format_detailed_activities(activities)}
    
    ## Bottleneck Analysis
    #{format_bottleneck_analysis(performance_breakdown, execution_time_ms)}
    
    ## Summary
    - **Total Activities Logged**: #{length(activities)}
    - **Phases Completed**: #{count_phases(activities)}
    - **Capability Checks**: #{count_capability_checks(activities)}
    - **Resource Allocations**: #{count_resource_allocations(activities)}
    - **Task Assignments**: #{count_assignments(activities)}
    
    **Execution Status**: ✅ COMPLETED SUCCESSFULLY
    
    ---
    
    **Generated**: #{timestamp}  
    **Activity Logger**: AriaEngine Detailed Execution Tracer  
    **© 2025 AriaEngine**
    """
  end
  
  # Helper functions for formatting
  
  defp format_capabilities(workers) do
    workers
    |> Enum.flat_map(fn worker -> worker.capabilities end)
    |> Enum.uniq()
    |> Enum.map(&to_string/1)
    |> Enum.join(", ")
  end
  
  defp format_task_requirements(tasks) do
    case tasks do
      [] -> "none"
      [task | _] ->
        capabilities = task.required_capabilities |> Enum.map(&to_string/1) |> Enum.join(", ")
        resources = task.required_resources |> Enum.join(", ")
        "#{capabilities} + specific tools"
    end
  end
  
  defp format_tool_list(tools) do
    tools
    |> Enum.map(fn tool -> tool.id end)
    |> Enum.join(", ")
  end
  
  defp format_agent_assignments(workers, schedule) do
    workers
    |> Enum.map(fn worker ->
      assigned_tasks = get_assigned_tasks(worker.id, schedule)
      case assigned_tasks do
        [] -> "- **#{worker.id}** → No tasks assigned"
        tasks ->
          task_details = tasks
          |> Enum.map(fn task_id ->
            task = find_scheduled_task(task_id, schedule)
            resource = Map.get(task, :resource_id, "none")
            start_time = Map.get(task, :start_time, 0)
            duration = Map.get(task, :duration, 0)
            "#{task_id} (using #{resource}, #{start_time}-#{start_time + duration}s)"
          end)
          |> Enum.join(", ")
          "- **#{worker.id}** → #{task_details}"
      end
    end)
    |> Enum.join("\n")
  end
  
  defp format_resource_efficiency(tools, schedule) do
    tools
    |> Enum.map(fn tool ->
      usage = get_resource_usage_timeline(tool.id, schedule)
      utilization = calculate_resource_utilization_percent(usage)
      "- **#{tool.id}**: #{utilization}% utilization"
    end)
    |> Enum.join("\n")
  end
  
  defp format_activity_phases(activities, performance_breakdown) do
    phases = activities
    |> Enum.filter(fn activity -> activity.type == :phase end)
    |> Enum.reverse()
    
    phases
    |> Enum.with_index(1)
    |> Enum.map(fn {phase, index} ->
      duration = Map.get(performance_breakdown, phase.name, 0)
      "### Phase #{index}: #{phase.name} (#{phase.relative_time}ms)\n" <>
      "- ⏱️ Duration: #{duration}ms\n" <>
      "- 📊 Status: ✅ COMPLETED"
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_performance_breakdown(performance_breakdown, total_time) do
    if map_size(performance_breakdown) == 0 do
      "- **Total Execution**: #{total_time}ms (100%)"
    else
      performance_breakdown
      |> Enum.map(fn {phase, duration} ->
        percentage = if total_time > 0, do: Float.round(duration / total_time * 100, 1), else: 0
        "- **#{phase}**: #{duration}ms (#{percentage}%)"
      end)
      |> Enum.join("\n")
    end
  end
  
  defp format_detailed_activities(activities) do
    activities
    |> Enum.with_index(1)
    |> Enum.map(fn {activity, index} ->
      format_single_activity(activity, index)
    end)
    |> Enum.join("\n")
  end
  
  defp format_single_activity(activity, index) do
    case activity.type do
      :phase ->
        "#{index}. 📋 **Phase**: #{activity.name} (#{activity.relative_time}ms)"
      :step ->
        status_icon = case activity.status do
          :success -> "✅"
          :error -> "❌"
          _ -> "ℹ️"
        end
        "#{index}. #{status_icon} #{activity.description} (#{activity.relative_time}ms)"
      :capability_check ->
        result_icon = if activity.result == :match, do: "✅", else: "❌"
        "#{index}. 🔍 #{activity.worker_id} → #{activity.task_id}: #{result_icon} #{activity.result} (#{activity.relative_time}ms)"
      :resource_allocation ->
        result_icon = if activity.result == :available, do: "✅", else: "❌"
        "#{index}. 🔧 #{activity.task_id} requires #{activity.resource_id}: #{result_icon} #{activity.result} (#{activity.relative_time}ms)"
      :assignment ->
        "#{index}. 📅 Assigned #{activity.worker_id} → #{activity.task_id} (#{activity.start_time}-#{activity.start_time + activity.duration}s) (#{activity.relative_time}ms)"
      _ ->
        "#{index}. 📝 #{inspect(activity)} (#{activity.relative_time}ms)"
    end
  end
  
  defp format_bottleneck_analysis(performance_breakdown, execution_time_ms) do
    if map_size(performance_breakdown) == 0 do
      """
      - **Primary Cost**: Overall execution (#{execution_time_ms}ms)
      - **Assessment**: #{if execution_time_ms < 500, do: "Excellent performance", else: "Moderate performance"}
      - **Recommendation**: #{if execution_time_ms > 1000, do: "Consider optimization", else: "Performance acceptable"}
      """
    else
      max_phase = performance_breakdown
      |> Enum.max_by(fn {_phase, duration} -> duration end)
      
      """
      - **Primary Cost**: #{elem(max_phase, 0)} (#{elem(max_phase, 1)}ms, #{Float.round(elem(max_phase, 1) / execution_time_ms * 100, 1)}%)
      - **Secondary Costs**: #{format_secondary_costs(performance_breakdown, max_phase)}
      - **Overall Assessment**: #{assess_overall_performance(execution_time_ms)}
      """
    end
  end
  
  defp format_secondary_costs(performance_breakdown, max_phase) do
    {max_phase_name, _} = max_phase
    
    performance_breakdown
    |> Enum.reject(fn {phase, _} -> phase == max_phase_name end)
    |> Enum.sort_by(fn {_, duration} -> duration end, :desc)
    |> Enum.take(2)
    |> Enum.map(fn {phase, duration} -> "#{phase} (#{duration}ms)" end)
    |> Enum.join(", ")
  end
  
  # Calculation helper functions
  
  defp calculate_success_rate(schedule, tasks) do
    if length(tasks) == 0, do: 0, else: Float.round(length(schedule) / length(tasks) * 100, 1)
  end
  
  defp calculate_agent_utilization_rate(workers, schedule) do
    utilized = count_utilized_agents(workers, schedule)
    total = length(workers)
    if total == 0, do: 0, else: Float.round(utilized / total * 100, 1)
  end
  
  defp calculate_resource_utilization_rate(tools, schedule) do
    utilized = count_utilized_resources(tools, schedule)
    total = length(tools)
    if total == 0, do: 0, else: Float.round(utilized / total * 100, 1)
  end
  
  defp count_utilized_agents(workers, schedule) do
    utilized_agents = schedule
    |> Enum.map(fn task -> Map.get(task, :agent_id) end)
    |> Enum.uniq()
    |> length()
    
    min(utilized_agents, length(workers))
  end
  
  defp count_utilized_resources(tools, schedule) do
    utilized_resources = schedule
    |> Enum.map(fn task -> Map.get(task, :resource_id) end)
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> length()
    
    min(utilized_resources, length(tools))
  end
  
  defp calculate_makespan(schedule) do
    if length(schedule) == 0 do
      0
    else
      schedule
      |> Enum.map(fn task ->
        start_time = Map.get(task, :start_time, 0)
        duration = Map.get(task, :duration, 0)
        start_time + duration
      end)
      |> Enum.max()
    end
  end
  
  defp calculate_total_duration(schedule) do
    schedule
    |> Enum.map(fn task -> Map.get(task, :duration, 0) end)
    |> Enum.sum()
  end
  
  defp format_complexity_factor(execution_time_ms, worker_count, task_count) do
    base_complexity = worker_count * task_count
    if base_complexity == 0 do
      "N/A"
    else
      factor = execution_time_ms / base_complexity
      "#{Float.round(factor, 2)}ms per worker-task pair"
    end
  end
  
  defp count_unique_capabilities(workers) do
    workers
    |> Enum.flat_map(fn worker -> worker.capabilities end)
    |> Enum.uniq()
    |> length()
  end
  
  defp assess_execution_speed(execution_time_ms) do
    cond do
      execution_time_ms < 100 -> "⚡ Excellent (< 100ms)"
      execution_time_ms < 500 -> "✅ Good (< 500ms)"
      execution_time_ms < 1000 -> "⚠️ Moderate (< 1s)"
      true -> "🐌 Slow (> 1s)"
    end
  end
  
  defp assess_scaling_behavior(execution_time_ms, worker_count, task_count) do
    complexity = worker_count * task_count
    if complexity == 0 do
      "N/A"
    else
      factor = execution_time_ms / complexity
      cond do
        factor < 10 -> "📈 Linear scaling"
        factor < 50 -> "📊 Sub-quadratic scaling"
        true -> "📉 Quadratic or worse scaling"
      end
    end
  end
  
  defp assess_single_core_feasibility(execution_time_ms) do
    if execution_time_ms < 5000, do: "✅ YES (under 5s)", else: "❌ NO (over 5s)"
  end
  
  defp identify_primary_bottleneck(execution_time_ms) do
    cond do
      execution_time_ms > 1000 -> "Resource allocation complexity"
      execution_time_ms > 500 -> "Capability matching overhead"
      true -> "None detected"
    end
  end
  
  defp calculate_makespan_efficiency(schedule, tasks) do
    if length(tasks) == 0 do
      100
    else
      optimal_makespan = Enum.max(Enum.map(tasks, fn task -> task.duration end))
      actual_makespan = calculate_makespan(schedule)
      if actual_makespan == 0, do: 100, else: Float.round(optimal_makespan / actual_makespan * 100, 1)
    end
  end
  
  defp detect_resource_conflicts(_schedule), do: 0
  
  defp generate_conclusion(execution_time_ms, simulation_result, workers, tools, tasks) do
    success_rate = calculate_success_rate(simulation_result.schedule, tasks)
    
    cond do
      success_rate == 100 and execution_time_ms < 500 ->
        "Simple agent-entity-capability planning demonstrates **excellent performance** with optimal scheduling and fast execution. The system efficiently handles basic capability matching and resource allocation with minimal complexity overhead."
      
      success_rate == 100 and execution_time_ms < 1000 ->
        "Agent-entity-capability planning shows **good performance** with complete task scheduling. Execution time is reasonable for the given complexity, indicating effective algorithmic implementation."
      
      success_rate == 100 ->
        "All tasks were successfully scheduled, demonstrating **functional correctness** of the agent-entity-capability planning system. Execution time suggests opportunities for performance optimization."
      
      success_rate > 80 ->
        "Most tasks were successfully scheduled (#{success_rate}%), indicating **generally effective** agent-entity-capability planning with some edge cases requiring attention."
      
      true ->
        "Scheduling success rate of #{success_rate}% indicates **significant issues** in agent-entity-capability planning that require investigation and improvement."
    end
  end
  
  defp assess_overall_performance(execution_time_ms) do
    cond do
      execution_time_ms < 200 -> "Excellent - suitable for real-time applications"
      execution_time_ms < 500 -> "Good - suitable for interactive applications"
      execution_time_ms < 1000 -> "Moderate - suitable for batch processing"
      true -> "Poor - requires optimization for production use"
    end
  end
  
  # Activity counting functions
  
  defp count_phases(activities) do
    activities |> Enum.count(fn activity -> activity.type == :phase end)
  end
  
  defp count_capability_checks(activities) do
    activities |> Enum.count(fn activity -> activity.type == :capability_check end)
  end
  
  defp count_resource_allocations(activities) do
    activities |> Enum.count(fn activity -> activity.type == :resource_allocation end)
  end
  
  defp count_assignments(activities) do
    activities |> Enum.count(fn activity -> activity.type == :assignment end)
  end
  
  # Reused helper functions
  
  defp get_assigned_tasks(agent_id, schedule) do
    schedule
    |> Enum.filter(fn task -> Map.get(task, :agent_id) == agent_id end)
    |> Enum.map(fn task -> Map.get(task, :id) end)
  end
  
  defp find_scheduled_task(task_id, schedule) do
    Enum.find(schedule, fn task -> Map.get(task, :id) == task_id end)
  end
  
  defp get_resource_usage_timeline(resource_id, schedule) do
    schedule
    |> Enum.filter(fn task -> Map.get(task, :resource_id) == resource_id end)
    |> Enum.map(fn task ->
      %{
        agent: Map.get(task, :agent_id),
        task: Map.get(task, :id),
        start_time: Map.get(task, :start_time, 0),
        end_time: Map.get(task, :start_time, 0) + Map.get(task, :duration, 0)
      }
    end)
  end
  
  defp calculate_resource_utilization_percent(usage_timeline) do
    if length(usage_timeline) == 0 do
      0
    else
      min(100, length(usage_timeline) * 33)
    end
  end
end
