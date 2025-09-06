defmodule Visekai.Domains.NeonFrontlines do
  @moduledoc """
  This domain defines the core capabilities and workflows for AI agents
  operating within the "Project Metropolis" simulation. It covers economic
  actions, tactical maneuvers, and squad coordination.
  """

  use AriaHybridPlanner.Domain

  # --------------------------------------------------------------------------
  # Type Specifications
  # --------------------------------------------------------------------------

  @type agent_id :: String.t()
  @type squad_id :: String.t()
  @type resource_id :: String.t()
  @type objective_id :: String.t()
  @type location_id :: String.t()

  # --------------------------------------------------------------------------
  # Setup & Entity Registration
  # --------------------------------------------------------------------------

  @doc "Initializes the Genesis Block with all required agents and resources."
  @action true
  @spec setup_genesis_block(AriaState.t()) :: {:ok, AriaState.t()}
  def setup_genesis_block(state, []) do
    state =
      state
      |> register_entity("gatherer_alpha", "agent", [:gathering])
      |> register_entity("crafter_alpha", "agent", [:crafting])
      |> register_entity("tactician_alpha", "agent", [:tactics, :command])
      |> register_entity("combatant_alpha", "agent", [:combat])
      |> register_entity("alpha_squad", "squad", [:coordinated_ops])
      |> register_entity("scrap_pile_01", "resource_node", [:scrap_metal])
      |> register_entity("market_district_route", "patrol_route", [:recon])
      |> register_entity("block_supremacy_obj", "objective", [])

    {:ok, state}
  end

  # --------------------------------------------------------------------------
  # Economic Loop: Gathering & Crafting
  # --------------------------------------------------------------------------

  @doc "A Gatherer agent extracts materials from a resource node."
  @action duration: "PT15M",
          requires_entities: [
            %{type: "agent", capabilities: [:gathering]},
            %{type: "resource_node", capabilities: [:scrap_metal]}
          ]
  @spec gather_scrap_metal(AriaState.t(), [agent_id(), resource_id()]) :: {:ok, AriaState.t()}
  def gather_scrap_metal(state, [agent_id, resource_id]) do
    state
    |> AriaState.RelationalState.increment_fact("inventory", agent_id, 1)
    |> AriaState.RelationalState.set_fact("status", agent_id, "returning")
    |> AriaState.RelationalState.decrement_fact("capacity", resource_id, 1)
    |> then(&{:ok, &1})
  end

  @doc "A Crafter agent processes raw materials into usable components."
  @action duration: "PT30M",
          requires_entities: [%{type: "agent", capabilities: [:crafting]}]
  @spec craft_armor_plating(AriaState.t(), [agent_id()]) :: {:ok, AriaState.t()}
  def craft_armor_plating(state, [agent_id]) do
    # This action assumes the agent has the required materials.
    # A task method would handle the prerequisite of getting the materials first.
    state
    |> AriaState.RelationalState.decrement_fact("inventory", agent_id, 1) # Consumes scrap
    |> AriaState.RelationalState.increment_fact("squad_storage", "alpha_squad", 1) # Adds armor
    |> AriaState.RelationalState.set_fact("status", agent_id, "available")
    |> then(&{:ok, &1})
  end

  # --------------------------------------------------------------------------
  # Tactical Loop: Patrolling & Responding
  # --------------------------------------------------------------------------

  @doc "A Tactician leads a patrol along a predefined route."
  @action duration: "PT1H",
          requires_entities: [
            %{type: "agent", capabilities: [:tactics]},
            %{type: "patrol_route", capabilities: [:recon]}
          ]
  @spec patrol_market_district(AriaState.t(), [agent_id(), location_id()]) :: {:ok, AriaState.t()}
  def patrol_market_district(state, [agent_id, route_id]) do
    state
    |> AriaState.RelationalState.set_fact("location", agent_id, route_id)
    |> AriaState.RelationalState.set_fact("intel_level", "market_district", 100)
    |> then(&{:ok, &1})
  end

  @doc "A Combatant engages a threat when detected by the Tactician."
  @command true # Use a command for unpredictable, execution-time events.
  @spec respond_to_threats(AriaState.t(), [agent_id(), squad_id()]) :: {:ok, AriaState.t()}
  def respond_to_threats(state, [agent_id, squad_id]) do
    # In a real scenario, this command would check for an active threat.
    # The outcome is uncertain and handled at execution.
    case check_for_active_threats(state, squad_id) do
      {:ok, threat_id} ->
        # Successfully neutralized threat
        state
        |> AriaState.RelationalState.set_fact("threat_neutralized", threat_id, true)
        |> AriaState.RelationalState.set_fact("status", agent_id, "returning_to_post")
        |> then(&{:ok, &1})
      {:error, :no_threat_found} ->
        # No action needed, command succeeds.
        {:ok, state}
      {:error, :combat_failed} ->
        # The agent failed to neutralize the threat, triggering replanning.
        {:error, :combat_failed}
    end
  end

  # --------------------------------------------------------------------------
  # Task & Goal Methods for Decomposition
  # --------------------------------------------------------------------------

  @doc "High-level task to achieve the 'Block Supremacy' objective."
  @task_method true
  @spec ensure_block_supremacy(AriaState.t(), [objective_id()]) :: {:ok, [AriaEngine.todo_item()]}
  def ensure_block_supremacy(_state, [_objective_id]) do
    # This task breaks down the high-level goal into concrete sub-goals and tasks.
    # It demonstrates the core gameplay loop.
    {:ok, [
      # 1. Economic Foundation: Ensure we have resources.
      {"squad_storage", "alpha_squad", {:>=, 1}}, # Goal: Have at least 1 armor plating.

      # 2. Tactical Control: Ensure the area is secure.
      {"intel_level", "market_district", {:==, 100}}, # Goal: Fully scout the market.

      # 3. Reactive Security: Be ready for anything.
      {:respond_to_threats, ["combatant_alpha", "alpha_squad"]} # Task: Handle any threats.
    ]}
  end

  @doc "Method to satisfy the goal of having items in squad storage."
  @unigoal_method predicate: "squad_storage"
  @spec acquire_squad_resources(AriaState.t(), {squad_id(), any()}) :: {:ok, [AriaEngine.todo_item()]}
  def acquire_squad_resources(_state, {_squad_id, _value}) do
    {:ok, [
      # To get storage, we must first have raw materials.
      {"inventory", "gatherer_alpha", {:>=, 1}},
      # Then, we can craft the item.
      {:craft_armor_plating, ["crafter_alpha"]}
    ]}
  end

  @doc "Method to satisfy a Gatherer's inventory goal."
  @unigoal_method predicate: "inventory"
  @spec acquire_personal_resources(AriaState.t(), {agent_id(), any()}) :: {:ok, [AriaEngine.todo_item()]}
  def acquire_personal_resources(_state, {agent_id, _value}) do
    # The only way for a gatherer to get inventory is to gather it.
    {:ok, [{:gather_scrap_metal, [agent_id, "scrap_pile_01"]}]}
  end

  @doc "Method to satisfy the intel level goal."
  @unigoal_method predicate: "intel_level"
  @spec acquire_intel(AriaState.t(), {location_id(), any()}) :: {:ok, [AriaEngine.todo_item()]}
  def acquire_intel(_state, {location_id, _value}) do
    # To get intel, the tactician must patrol.
    {:ok, [{:patrol_market_district, ["tactician_alpha", location_id]}]}
  end

  # --------------------------------------------------------------------------
  # Helper Functions
  # --------------------------------------------------------------------------

  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.RelationalState.set_fact("type", entity_id, type)
    |> AriaState.RelationalState.set_fact("capabilities", entity_id, capabilities)
    |> AriaState.RelationalState.set_fact("status", entity_id, "available")
  end

  defp check_for_active_threats(state, squad_id) do
    # Mock implementation: 50% chance to find a threat
    if :rand.uniform() > 0.5 do
      threat_id = "threat_#{:rand.uniform(1000)}"
      AriaState.RelationalState.set_fact(state, "active_threat", squad_id, threat_id)
      {:ok, threat_id}
    else
      {:error, :no_threat_found}
    end
  end
end
