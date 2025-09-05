defmodule AriaNeonFrontlines.BlockExplorer do
  @moduledoc """
  Block Explorer Archetype for Neon Frontlines City Block Domain.

  Handles supply transfer and logistics routing within the neon-lit city block.
  Focuses on efficient resource movement, route optimization, and block knowledge.

  Follows ADR R25W1398085: Unified Durative Action Specification.
  """

  use AriaCore.ActionAttributes

  @type supply_route :: {String.t(), String.t(), non_neg_integer()}
  @type block_location :: String.t()

  @doc """
  Register block explorer entity with capabilities.

  Entity registration pattern per ADR R25W1398085.
  """
  @action true
  @spec register_block_explorer(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def register_block_explorer(state, [operative_id]) do
    state
    |> AriaState.RelationalState.set_fact("type", operative_id, "operative")
    |> AriaState.RelationalState.set_fact("capabilities", operative_id, [:supply_transfer, :route_planning, :scouting, :logistics_optimization])
    |> AriaState.RelationalState.set_fact("status", operative_id, "available")
    |> AriaState.RelationalState.set_fact("archetype", operative_id, "block_explorer")
    {:ok, state}
  end

  @doc """
  Get available actions for block explorer.
  """
  @spec actions(map()) :: [{atom(), String.t()}]
  def actions(_state) do
    [
      {:transfer_supplies, "Transfer supplies between block locations"},
      {:map_block_route, "Map an efficient supply route"},
      {:scout_location, "Scout a new block location for supplies"},
      {:optimize_route, "Optimize existing supply routes"}
    ]
  end

  @doc """
  Initialize block explorer state with entity registration.
  """
  @spec init_state(String.t()) :: map()
  def init_state(operative_id) do
    # Initialize with entity registration
    {:ok, initial_state} = register_block_explorer(%AriaState{}, [operative_id])

    initial_state
    |> Map.put(:supply_routes, [])
    |> Map.put(:transfer_efficiency, 1.0)
    |> Map.put(:block_knowledge, [:alleyways, :rooftops, :subway_access])
    |> Map.put(:current_location, "supply_depot")
    |> Map.put(:neon_level, 0.8)
  end

  @doc """
  Transfer supplies between block locations.

  Requires entity with supply transfer capabilities.
  Takes variable time based on distance and efficiency.
  """
  @action duration: "PT15M",
          requires_entities: [%{type: "operative", capabilities: [:supply_transfer]}]
  @spec transfer_supplies(AriaState.t(), [block_location() | block_location() | non_neg_integer()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def transfer_supplies(state, [from, to, amount]) do
    # Validate supply availability
    available_supplies = AriaState.RelationalState.get_fact(state, "supplies", from) || 0

    if available_supplies >= amount do
      new_state = state
      |> AriaState.RelationalState.set_fact("supplies", from, available_supplies - amount)
      |> AriaState.RelationalState.set_fact("supplies", to, (AriaState.RelationalState.get_fact(state, "supplies", to) || 0) + amount)
      |> AriaState.RelationalState.set_fact("last_transfer", {from, to}, amount)

      {:ok, new_state}
    else
      {:error, :insufficient_supplies}
    end
  end

  @doc """
  Map an efficient supply route through the block.

  Uses block knowledge to find optimal paths.
  """
  @action duration: "PT10M",
          requires_entities: [%{type: "operative", capabilities: [:route_planning]}]
  @spec map_block_route(AriaState.t(), [block_location()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def map_block_route(state, [from, to]) do
    # Calculate route efficiency based on block knowledge
    efficiency = calculate_route_efficiency(state, from, to)

    route = {from, to, efficiency}

    new_state = AriaState.RelationalState.set_fact(state, "mapped_route", {from, to}, route)

    {:ok, new_state}
  end

  @doc """
  Scout a new block location for supplies.

  Reveals hidden supply caches and updates block knowledge.
  """
  @action duration: "PT20M",
          requires_entities: [%{type: "operative", capabilities: [:scouting]}]
  @spec scout_location(AriaState.t(), [block_location()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def scout_location(state, [location]) do
    # Simulate scouting discovery
    discovered_supplies = :rand.uniform(50) + 10

    new_state = state
    |> AriaState.RelationalState.set_fact("supplies", location, discovered_supplies)
    |> AriaState.RelationalState.set_fact("scouted", location, true)
    |> AriaState.RelationalState.set_fact("neon_level", location, 0.8)

    {:ok, new_state}
  end

  @doc """
  Optimize existing supply routes for better efficiency.

  Uses transfer history to improve routing algorithms.
  """
  @action duration: "PT30M",
          requires_entities: [%{type: "operative", capabilities: [:logistics_optimization]}]
  @spec optimize_route(AriaState.t(), [block_location()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def optimize_route(state, [from, to]) do
    # Analyze transfer history and optimize
    current_efficiency = AriaState.RelationalState.get_fact(state, "route_efficiency", {from, to}) || 1.0
    optimized_efficiency = min(current_efficiency * 1.2, 2.0)

    new_state = AriaState.RelationalState.set_fact(state, "route_efficiency", {from, to}, optimized_efficiency)

    {:ok, new_state}
  end

  @doc """
  Command method for supply transfer with failure handling.
  """
  @command true
  @spec transfer_supplies_command(AriaState.t(), [block_location() | block_location() | non_neg_integer()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def transfer_supplies_command(state, [from, to, amount]) do
    # Simulate real-world transfer risks
    case :rand.uniform() do
      x when x < 0.9 -> transfer_supplies(state, [from, to, amount])  # 90% success
      _ -> {:error, :transfer_intercepted}
    end
  end

  @doc """
  Task method for complete supply chain optimization.
  """
  @task_method true
  @spec optimize_supply_chain(AriaState.t(), [block_location()]) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def optimize_supply_chain(_state, [target_location]) do
    {:ok, [
      # Scout for supplies first
      {:scout_location, [target_location]},

      # Map efficient routes
      {:map_block_route, ["supply_depot", target_location]},

      # Optimize the route
      {:optimize_route, ["supply_depot", target_location]},

      # Goal: Have supplies available
      {"supplies", target_location, {:>=, 25}}
    ]}
  end

  @doc """
  Unigoal method for achieving supply availability.
  """
  @unigoal_method predicate: "supplies"
  @spec achieve_supply_level(AriaState.t(), {String.t(), non_neg_integer()}) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_supply_level(state, {location, target_amount}) do
    current_supplies = AriaState.RelationalState.get_fact(state, "supplies", location) || 0

    if current_supplies >= target_amount do
      {:ok, []}  # Already achieved
    else
      deficit = target_amount - current_supplies
      {:ok, [
        {:transfer_supplies, ["supply_depot", location, deficit]},
        {"supplies", location, target_amount}
      ]}
    end
  end

  # Helper functions
  defp calculate_route_efficiency(state, from, to) do
    # Base efficiency
    base_efficiency = 1.0

    # Bonus for known routes
    route_known = AriaState.RelationalState.get_fact(state, "mapped_route", {from, to}) != nil
    known_bonus = if route_known, do: 0.2, else: 0.0

    # Neon level affects visibility/efficiency
    neon_level = AriaState.RelationalState.get_fact(state, "neon_level", from) || 0.5
    neon_bonus = neon_level * 0.3

    base_efficiency + known_bonus + neon_bonus
  end
end
