defmodule AriaNeonFrontlines.GameDomain do
  @moduledoc """
  Neon Frontlines City Block Domain for cyberpunk logistics warfare.

  This domain implements 4 operative archetypes within a single neon-lit city block:
  - Local Socializer: Squad command and tactical coordination
  - Block Explorer: Supply transfer and logistics routing
  - Local Achiever: Resource allocation and optimization
  - Block Competitor: Firefight coordination and tactical advantage

  Refactored to use separate archetype modules following ADR R25W1398085.
  """

  use AriaCore.ActionAttributes

  # Import archetype modules
  alias AriaNeonFrontlines.BlockExplorer
  alias AriaNeonFrontlines.LocalSocializer
  alias AriaNeonFrontlines.LocalAchiever
  alias AriaNeonFrontlines.BlockCompetitor

  # Operative Archetypes for Cyberpunk Logistics Warfare
  @archetypes [
    :local_socializer,    # Squad command and coordination
    :block_explorer,      # Supply transfer and routing
    :local_achiever,      # Resource optimization
    :block_competitor     # Tactical firefight coordination
  ]

  @doc """
  Get all available operative archetypes.
  """
  def archetypes, do: @archetypes

  @doc """
  Get the domain name.
  """
  def name, do: "neon_frontlines_city_block"

  @doc """
  Get domain description.
  """
  def description, do: "Cyberpunk logistics warfare in a neon-lit city block"

  @doc """
  Initialize domain state for a new operative.
  Delegates to appropriate archetype module.
  """
  def init_state(operative_id, archetype) do
    case archetype do
      :block_explorer -> BlockExplorer.init_state(operative_id)
      :local_socializer -> LocalSocializer.init_state(operative_id)
      :local_achiever -> LocalAchiever.init_state(operative_id)
      :block_competitor -> BlockCompetitor.init_state(operative_id)
      _ -> raise "Unknown archetype: #{archetype}"
    end
  end

  @doc """
  Get available actions for the current state.
  Delegates to archetype-specific modules.
  """
  def actions(state) do
    case state.archetype do
      :block_explorer -> BlockExplorer.actions(state)
      :local_socializer -> LocalSocializer.actions(state)
      :local_achiever -> LocalAchiever.actions(state)
      :block_competitor -> BlockCompetitor.actions(state)
      _ -> []
    end
  end

  # Archetype-specific action lists (for backward compatibility)
  @doc """
  Get actions for block explorer archetype.
  """
  def explorer_actions(_state) do
    [
      {:transfer_supplies, "Transfer supplies between block locations"},
      {:map_block_route, "Map an efficient supply route"},
      {:scout_location, "Scout a new block location for supplies"},
      {:optimize_route, "Optimize existing supply routes"}
    ]
  end

  @doc """
  Get actions for local socializer archetype.
  """
  def socializer_actions(_state) do
    [
      {:command_squad, "Issue tactical commands to squad members"},
      {:log_tactical_decision, "Record important tactical decisions"},
      {:coordinate_movement, "Coordinate squad movement through the block"},
      {:establish_command_post, "Set up a new command position"}
    ]
  end

  @doc """
  Get actions for local achiever archetype.
  """
  def achiever_actions(_state) do
    [
      {:allocate_resources, "Allocate resources for maximum efficiency"},
      {:optimize_supply_chain, "Optimize the supply chain logistics"},
      {:calculate_efficiency, "Calculate current operational efficiency"},
      {:refine_allocation, "Refine resource allocation based on metrics"}
    ]
  end

  @doc """
  Get actions for block competitor archetype.
  """
  def competitor_actions(_state) do
    [
      {:coordinate_firefight, "Coordinate squad in firefight"},
      {:gain_tactical_advantage, "Position for tactical advantage"},
      {:disrupt_enemy_supplies, "Disrupt enemy supply lines"},
      {:secure_position, "Secure a strategic block position"}
    ]
  end

  @doc """
  Check if a goal is satisfied in the current state.
  """
  def goal_satisfied?(state, goal) do
    case goal do
      {:command_squad, target_squad} ->
        target_squad in state.squad_members

      {:transfer_supplies, {_from, _to, amount}} ->
        # Check if transfer is possible
        state.supplies >= amount

      {:allocate_resources, target_efficiency} ->
        # Check efficiency metrics
        get_efficiency_score(state) >= target_efficiency

      {:coordinate_firefight, enemy_position} ->
        # Check if position is secured
        enemy_position in state.enemy_positions

      _ ->
        false
    end
  end

  @doc """
  Apply an action to the current state.
  """
  def apply_action(state, action) do
    case action do
      {:command_squad, squad_command} ->
        update_in(state.tactical_log, &[{:command, squad_command} | &1])

      {:transfer_supplies, {from, to, amount}} ->
        state
        |> update_in([:supplies], &(&1 - amount))
        |> update_in([:supply_routes], &[{from, to, amount} | &1])

      {:allocate_resources, allocation} ->
        state
        |> update_in([:resource_allocation], &Map.merge(&1, allocation))
        |> update_in([:allocation_history], &[allocation | &1])

      {:coordinate_firefight, coordination} ->
        update_in(state.firefight_coordination, &[coordination | &1])

      _ ->
        state
    end
  end

  @doc """
  Get the cost of applying an action.
  """
  def action_cost(_state, action) do
    case action do
      {:transfer_supplies, {_, _, amount}} -> amount * 0.1
      {:coordinate_firefight, _} -> 5
      {:allocate_resources, _} -> 2
      _ -> 1
    end
  end

  @doc """
  Check if an action is applicable in the current state.
  """
  def applicable?(state, action) do
    case action do
      {:transfer_supplies, {_, _, amount}} ->
        state.supplies >= amount

      {:command_squad, target} ->
        target in state.squad_members

      {:allocate_resources, _} ->
        state.archetype == :local_achiever

      {:coordinate_firefight, _} ->
        state.archetype == :block_competitor

      _ ->
        true
    end
  end

  # Helper functions
  defp get_efficiency_score(state) do
    # Calculate efficiency based on resource allocation
    allocation_count = map_size(state.resource_allocation)
    history_count = length(state.allocation_history)

    if allocation_count > 0 do
      (allocation_count + history_count) / 10.0
    else
      0.0
    end
  end
end
