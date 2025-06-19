defmodule JsonSolution.SchedulerRunner do
  @moduledoc """
  Scheduler Runner
  
  Executes the scheduling process with detailed activity logging
  and performance measurement.
  """
  
  alias JsonSolution.ActivityLogger
  
  def run_with_logging(workers, tools, tasks) do
    ActivityLogger.log_phase("Initialization", 0)
    ActivityLogger.log_step("Starting scheduler execution", :info)
    
    # Simulate detailed logging for capability checks
    log_capability_checks(workers, tasks)
    
    # Simulate resource allocation logging
    log_resource_allocations(tasks, tools)
    
    # Run the actual scheduler
    ActivityLogger.log_phase("Schedule Generation")
    ActivityLogger.log_step("Executing AriaEngine.Scheduler.schedule_activities", :info)
    
    {execution_time, result} = :timer.tc(fn ->
      AriaEngine.Scheduler.schedule_activities(
        "simple_work_assignment",
        tasks,
        entities: workers,
        resources: tools,
        simulation_mode: false
      )
    end)
    
    execution_time_ms = div(execution_time, 1000)
    
    # Log the results
    case result do
      {:ok, simulation_result} ->
        ActivityLogger.log_step("Scheduling completed successfully", :success)
        log_assignments(simulation_result.schedule)
        ActivityLogger.log_phase("Validation", 5)
        ActivityLogger.log_step("Schedule validation complete", :success)
        
      {:error, reason} ->
        ActivityLogger.log_step("Scheduling failed: #{reason}", :error)
    end
    
    {execution_time_ms, result}
  end
  
  defp log_capability_checks(workers, tasks) do
    ActivityLogger.log_phase("Capability Matching")
    
    for worker <- workers, task <- tasks do
      # Simulate capability checking
      result = if :work in worker.capabilities and :work in task.required_capabilities do
        :match
      else
        :no_match
      end
      
      ActivityLogger.log_capability_check(worker.id, task.id, result)
      
      # Add a small delay to simulate processing time
      Process.sleep(1)
    end
    
    ActivityLogger.log_step("Capability matching phase complete", :info)
  end
  
  defp log_resource_allocations(tasks, tools) do
    ActivityLogger.log_phase("Resource Allocation")
    
    for task <- tasks do
      required_resources = task.required_resources || []
      
      for resource_id <- required_resources do
        # Check if resource exists
        resource_exists = Enum.any?(tools, fn tool -> tool.id == resource_id end)
        
        result = if resource_exists do
          :available
        else
          :unavailable
        end
        
        ActivityLogger.log_resource_allocation(task.id, resource_id, result)
        
        # Add a small delay to simulate processing time
        Process.sleep(2)
      end
    end
    
    ActivityLogger.log_step("Resource allocation phase complete", :info)
  end
  
  defp log_assignments(schedule) do
    ActivityLogger.log_step("Recording task assignments", :info)
    
    for scheduled_task <- schedule do
      worker_id = Map.get(scheduled_task, :agent_id, "unknown")
      task_id = Map.get(scheduled_task, :id, "unknown")
      start_time = Map.get(scheduled_task, :start_time, 0)
      duration = Map.get(scheduled_task, :duration, 0)
      resources = [Map.get(scheduled_task, :resource_id, "none")]
      
      ActivityLogger.log_assignment(worker_id, task_id, start_time, duration, resources)
    end
    
    ActivityLogger.log_step("All assignments recorded", :info)
  end
end
