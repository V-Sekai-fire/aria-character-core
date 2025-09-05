defmodule AriaNeonFrontlines.LocalAchiever do
  @moduledoc """
  Local Achiever Archetype for Neon Frontlines City Block Domain.

  Handles resource allocation and optimization within the neon-lit city block.
  Focuses on efficiency metrics, resource optimization, and allocation strategies.

  Follows ADR R25W1398085: Unified Durative Action Specification.
  """

  use AriaCore.ActionAttributes

  @type resource_allocation :: map()
  @type efficiency_metric :: float()

  @doc """
  Register local achiever entity with capabilities.

  Entity registration pattern per ADR R25W1398085.
  """
  @action true
  @spec register_local_achiever(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def register_local_achiever(state, [operative_id]) do
    state
    |> AriaState.RelationalState.set_fact("type", operative_id, "operative")
    |> AriaState.RelationalState.set_fact("capabilities", operative_id, [:resource_analysis, :optimization, :supply_chain_optimization, :metric_calculation, :allocation_refinement])
    |> AriaState.RelationalState.set_fact("status", operative_id, "available")
    |> AriaState.RelationalState.set_fact("archetype", operative_id, "local_achiever")
    {:ok, state}
  end

  @doc """
  Get available actions for local achiever.
  """
  @spec actions(map()) :: [{atom(), String.t()}]
  def actions(_state) do
    [
      {:allocate_resources, "Allocate resources for maximum efficiency"},
      {:optimize_supply_chain, "Optimize the supply chain logistics"},
      {:calculate_efficiency, "Calculate current operational efficiency"},
      {:refine_allocation, "Refine resource allocation based on metrics"}
    ]
  end

  @doc """
  Initialize local achiever state with entity registration.
  """
  @spec init_state(String.t()) :: map()
  def init_state(operative_id) do
    # Initialize with entity registration
    {:ok, initial_state} = register_local_achiever(%AriaState{}, [operative_id])

    initial_state
    |> Map.put(:resource_allocation, %{})
    |> Map.put(:optimization_score, 0)
    |> Map.put(:efficiency_metrics, %{})
    |> Map.put(:allocation_history, [])
    |> Map.put(:current_location, "resource_center")
    |> Map.put(:neon_level, 0.8)
  end

  @doc """
  Allocate resources for maximum efficiency.

  Analyzes current allocation and optimizes resource distribution.
  """
  @action duration: "PT8M",
          requires_entities: [%{type: "operative", capabilities: [:resource_analysis, :optimization]}]
  @spec allocate_resources(AriaState.t(), [resource_allocation()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def allocate_resources(state, [allocation]) do
    # Validate allocation feasibility
    total_allocated = Enum.sum(Map.values(allocation))
    available_resources = AriaState.RelationalState.get_fact(state, "available_resources", "total") || 100

    if total_allocated <= available_resources do
      timestamp = DateTime.utc_now()

      new_state = state
      |> AriaState.RelationalState.set_fact("resource_allocation", "current", allocation)
      |> AriaState.RelationalState.set_fact("allocation_timestamp", "current", timestamp)
      |> AriaState.RelationalState.set_fact("allocation_history", timestamp, allocation)

      {:ok, new_state}
    else
      {:error, :insufficient_resources}
    end
  end

  @doc """
  Optimize the supply chain logistics.

  Uses efficiency metrics to improve resource flow.
  """
  @action duration: "PT12M",
          requires_entities: [%{type: "operative", capabilities: [:supply_chain_optimization]}]
  @spec optimize_supply_chain(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def optimize_supply_chain(state, [chain_id]) do
    # Calculate current efficiency
    current_efficiency = calculate_chain_efficiency(state, chain_id)
    optimized_efficiency = min(current_efficiency * 1.15, 1.0)

    new_state = state
    |> AriaState.RelationalState.set_fact("supply_chain_efficiency", chain_id, optimized_efficiency)
    |> AriaState.RelationalState.set_fact("optimization_applied", chain_id, true)

    {:ok, new_state}
  end

  @doc """
  Calculate current operational efficiency.

  Computes metrics based on resource utilization and allocation effectiveness.
  """
  @action duration: "PT3M",
          requires_entities: [%{type: "operative", capabilities: [:metric_calculation]}]
  @spec calculate_efficiency(AriaState.t(), []) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def calculate_efficiency(state, []) do
    # Calculate comprehensive efficiency score
    efficiency_score = calculate_overall_efficiency(state)

    metrics = %{
      resource_utilization: calculate_resource_utilization(state),
      allocation_effectiveness: calculate_allocation_effectiveness(state),
      overall_efficiency: efficiency_score
    }

    new_state = state
    |> AriaState.RelationalState.set_fact("efficiency_score", "current", efficiency_score)
    |> AriaState.RelationalState.set_fact("efficiency_metrics", "current", metrics)

    {:ok, new_state}
  end

  @doc """
  Refine resource allocation based on metrics.

  Uses efficiency data to improve future allocations.
  """
  @action duration: "PT6M",
          requires_entities: [%{type: "operative", capabilities: [:allocation_refinement]}]
  @spec refine_allocation(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def refine_allocation(state, [allocation_id]) do
    # Get current metrics
    current_metrics = AriaState.RelationalState.get_fact(state, "efficiency_metrics", "current") || %{}

    # Calculate refinement factor
    refinement_factor = calculate_refinement_factor(current_metrics)

    new_state = AriaState.RelationalState.set_fact(state, "allocation_refinement", allocation_id, refinement_factor)

    {:ok, new_state}
  end

  @doc """
  Command method for resource allocation with validation.
  """
  @command true
  @spec allocate_resources_command(AriaState.t(), [resource_allocation()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def allocate_resources_command(state, [allocation]) do
    # Additional validation for allocation conflicts
    conflicts = check_allocation_conflicts(state, allocation)

    if Enum.empty?(conflicts) do
      allocate_resources(state, [allocation])
    else
      {:error, {:allocation_conflicts, conflicts}}
    end
  end

  @doc """
  Task method for complete resource optimization cycle.
  """
  @task_method true
  @spec optimize_resource_cycle(AriaState.t(), [String.t()]) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def optimize_resource_cycle(_state, [cycle_id]) do
    {:ok, [
      # Calculate current efficiency first
      {:calculate_efficiency, []},

      # Allocate resources based on metrics
      {:allocate_resources, [%{cycle_id => 50}]},

      # Optimize supply chain
      {:optimize_supply_chain, [cycle_id]},

      # Refine allocation for next cycle
      {:refine_allocation, [cycle_id]},

      # Goal: Efficiency above threshold
      {"efficiency_score", "current", {:>=, 0.8}}
    ]}
  end

  @doc """
  Unigoal method for achieving efficiency targets.
  """
  @unigoal_method predicate: "efficiency_score"
  @spec achieve_efficiency_target(AriaState.t(), {String.t(), float()}) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_efficiency_target(state, {target_id, target_score}) do
    current_score = AriaState.RelationalState.get_fact(state, "efficiency_score", "current") || 0.0

    if current_score >= target_score do
      {:ok, []}  # Already achieved
    else
      _improvement_needed = target_score - current_score
      {:ok, [
        {:optimize_supply_chain, [target_id]},
        {:refine_allocation, [target_id]},
        {"efficiency_score", "current", {:>=, target_score}}
      ]}
    end
  end

  # Helper functions
  defp calculate_overall_efficiency(state) do
    utilization = calculate_resource_utilization(state)
    effectiveness = calculate_allocation_effectiveness(state)

    (utilization + effectiveness) / 2.0
  end

  defp calculate_resource_utilization(state) do
    allocated = AriaState.RelationalState.get_fact(state, "resource_allocation", "current") || %{}
    total_allocated = Enum.sum(Map.values(allocated))
    available = AriaState.RelationalState.get_fact(state, "available_resources", "total") || 100

    if available > 0 do
      min(total_allocated / available, 1.0)
    else
      0.0
    end
  end

  defp calculate_allocation_effectiveness(state) do
    # Simplified effectiveness calculation
    history_count = length(AriaState.RelationalState.get_fact(state, "allocation_history", "all") || [])
    base_effectiveness = 0.5

    min(base_effectiveness + (history_count * 0.05), 1.0)
  end

  defp calculate_chain_efficiency(state, chain_id) do
    base_efficiency = 0.7
    optimization_applied = AriaState.RelationalState.get_fact(state, "optimization_applied", chain_id) || false

    if optimization_applied, do: base_efficiency * 1.2, else: base_efficiency
  end

  defp calculate_refinement_factor(metrics) do
    overall_efficiency = Map.get(metrics, :overall_efficiency, 0.5)
    max(0.1, 1.0 - overall_efficiency)  # More refinement needed when efficiency is lower
  end

  defp check_allocation_conflicts(state, allocation) do
    # Check for resource conflicts
    current_allocation = AriaState.RelationalState.get_fact(state, "resource_allocation", "current") || %{}

    Enum.filter(allocation, fn {resource, amount} ->
      current_amount = Map.get(current_allocation, resource, 0)
      current_amount + amount > 100  # Arbitrary conflict threshold
    end)
    |> Enum.map(fn {resource, _} -> resource end)
  end
end
