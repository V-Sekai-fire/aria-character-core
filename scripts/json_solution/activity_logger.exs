defmodule JsonSolution.ActivityLogger do
  @moduledoc """
  Activity Logger
  
  Tracks step-by-step execution of the scheduling process
  for detailed activity log generation.
  """
  
  use GenServer
  
  def start_logging do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def log_phase(phase_name, duration_ms \\ nil) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:log_phase, phase_name, duration_ms, System.monotonic_time(:millisecond)})
    end
  end
  
  def log_step(step_description, status \\ :info) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:log_step, step_description, status, System.monotonic_time(:millisecond)})
    end
  end
  
  def log_capability_check(worker_id, task_id, result) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:log_capability_check, worker_id, task_id, result, System.monotonic_time(:millisecond)})
    end
  end
  
  def log_resource_allocation(task_id, resource_id, result) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:log_resource_allocation, task_id, resource_id, result, System.monotonic_time(:millisecond)})
    end
  end
  
  def log_assignment(worker_id, task_id, start_time, duration, resources) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:log_assignment, worker_id, task_id, start_time, duration, resources, System.monotonic_time(:millisecond)})
    end
  end
  
  def get_activity_log do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :get_log)
    else
      []
    end
  end
  
  def get_performance_breakdown do
    if Process.whereis(__MODULE__) do
      GenServer.call(__MODULE__, :get_performance_breakdown)
    else
      %{}
    end
  end
  
  # GenServer callbacks
  
  def init([]) do
    {:ok, %{
      activities: [],
      phases: [],
      start_time: System.monotonic_time(:millisecond)
    }}
  end
  
  def handle_cast({:log_phase, phase_name, duration_ms, timestamp}, state) do
    phase_entry = %{
      type: :phase,
      name: phase_name,
      duration_ms: duration_ms,
      timestamp: timestamp,
      relative_time: timestamp - state.start_time
    }
    
    new_state = %{state | 
      phases: [phase_entry | state.phases],
      activities: [phase_entry | state.activities]
    }
    
    {:noreply, new_state}
  end
  
  def handle_cast({:log_step, step_description, status, timestamp}, state) do
    step_entry = %{
      type: :step,
      description: step_description,
      status: status,
      timestamp: timestamp,
      relative_time: timestamp - state.start_time
    }
    
    new_state = %{state | activities: [step_entry | state.activities]}
    {:noreply, new_state}
  end
  
  def handle_cast({:log_capability_check, worker_id, task_id, result, timestamp}, state) do
    check_entry = %{
      type: :capability_check,
      worker_id: worker_id,
      task_id: task_id,
      result: result,
      timestamp: timestamp,
      relative_time: timestamp - state.start_time
    }
    
    new_state = %{state | activities: [check_entry | state.activities]}
    {:noreply, new_state}
  end
  
  def handle_cast({:log_resource_allocation, task_id, resource_id, result, timestamp}, state) do
    allocation_entry = %{
      type: :resource_allocation,
      task_id: task_id,
      resource_id: resource_id,
      result: result,
      timestamp: timestamp,
      relative_time: timestamp - state.start_time
    }
    
    new_state = %{state | activities: [allocation_entry | state.activities]}
    {:noreply, new_state}
  end
  
  def handle_cast({:log_assignment, worker_id, task_id, start_time, duration, resources, timestamp}, state) do
    assignment_entry = %{
      type: :assignment,
      worker_id: worker_id,
      task_id: task_id,
      start_time: start_time,
      duration: duration,
      resources: resources,
      timestamp: timestamp,
      relative_time: timestamp - state.start_time
    }
    
    new_state = %{state | activities: [assignment_entry | state.activities]}
    {:noreply, new_state}
  end
  
  def handle_call(:get_log, _from, state) do
    # Return activities in chronological order
    activities = Enum.reverse(state.activities)
    {:reply, activities, state}
  end
  
  def handle_call(:get_performance_breakdown, _from, state) do
    phases = Enum.reverse(state.phases)
    
    breakdown = phases
    |> Enum.map(fn phase -> {phase.name, phase.duration_ms || 0} end)
    |> Enum.into(%{})
    
    {:reply, breakdown, state}
  end
end
