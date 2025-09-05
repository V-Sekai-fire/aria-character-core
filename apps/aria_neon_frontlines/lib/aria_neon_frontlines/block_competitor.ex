defmodule AriaNeonFrontlines.BlockCompetitor do
  @moduledoc """
  Block Competitor Archetype for Neon Frontlines City Block Domain.

  Handles firefight coordination and tactical advantage within the neon-lit city block.
  Focuses on combat readiness, enemy disruption, and strategic positioning.

  Follows ADR R25W1398085: Unified Durative Action Specification.
  """

  use AriaCore.ActionAttributes

  @type enemy_position :: String.t()
  @type tactical_advantage :: float()

  @doc """
  Register block competitor entity with capabilities.

  Entity registration pattern per ADR R25W1398085.
  """
  @action true
  @spec register_block_competitor(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def register_block_competitor(state, [operative_id]) do
    state
    |> AriaState.RelationalState.set_fact("type", operative_id, "operative")
    |> AriaState.RelationalState.set_fact("capabilities", operative_id, [:combat_coordination, :tactical_awareness, :tactical_positioning, :disruption, :supply_interdiction, :position_securing, :tactical_control])
    |> AriaState.RelationalState.set_fact("status", operative_id, "available")
    |> AriaState.RelationalState.set_fact("archetype", operative_id, "block_competitor")
    {:ok, state}
  end

  @doc """
  Get available actions for block competitor.
  """
  @spec actions(map()) :: [{atom(), String.t()}]
  def actions(_state) do
    [
      {:coordinate_firefight, "Coordinate squad in firefight"},
      {:gain_tactical_advantage, "Position for tactical advantage"},
      {:disrupt_enemy_supplies, "Disrupt enemy supply lines"},
      {:secure_position, "Secure a strategic block position"}
    ]
  end

  @doc """
  Initialize block competitor state with entity registration.
  """
  @spec init_state(String.t()) :: map()
  def init_state(operative_id) do
    # Initialize with entity registration
    {:ok, initial_state} = register_block_competitor(%AriaState{}, [operative_id])

    initial_state
    |> Map.put(:combat_readiness, 0.9)
    |> Map.put(:tactical_advantage, 0)
    |> Map.put(:firefight_coordination, [])
    |> Map.put(:enemy_positions, [])
    |> Map.put(:current_location, "combat_post")
    |> Map.put(:neon_level, 0.8)
  end

  @doc """
  Coordinate squad in firefight.

  Requires combat coordination capabilities and tactical awareness.
  """
  @action duration: "PT5M",
          requires_entities: [%{type: "operative", capabilities: [:combat_coordination, :tactical_awareness]}]
  @spec coordinate_firefight(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_firefight(state, [firefight_id]) do
    # Check combat readiness
    readiness = AriaState.RelationalState.get_fact(state, "combat_readiness", "current") || 0.0

    if readiness >= 0.7 do
      timestamp = DateTime.utc_now()

      coordination_data = %{
        firefight_id: firefight_id,
        timestamp: timestamp,
        readiness: readiness
      }

      new_state = state
      |> AriaState.RelationalState.set_fact("firefight_coordination", firefight_id, coordination_data)
      |> AriaState.RelationalState.set_fact("coordination_timestamp", firefight_id, timestamp)

      {:ok, new_state}
    else
      {:error, :combat_readiness_insufficient}
    end
  end

  @doc """
  Position for tactical advantage.

  Analyzes battlefield and positions for optimal advantage.
  """
  @action duration: "PT8M",
          requires_entities: [%{type: "operative", capabilities: [:tactical_positioning]}]
  @spec gain_tactical_advantage(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def gain_tactical_advantage(state, [position_id]) do
    # Calculate tactical advantage based on position
    advantage_score = calculate_tactical_advantage(state, position_id)

    if advantage_score >= 0.5 do
      new_state = state
      |> AriaState.RelationalState.set_fact("tactical_advantage", position_id, advantage_score)
      |> AriaState.RelationalState.set_fact("position_secured", position_id, true)

      {:ok, new_state}
    else
      {:error, :position_not_advantageous}
    end
  end

  @doc """
  Disrupt enemy supply lines.

  Targets and disrupts enemy logistics and supply chains.
  """
  @action duration: "PT12M",
          requires_entities: [%{type: "operative", capabilities: [:disruption, :supply_interdiction]}]
  @spec disrupt_enemy_supplies(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def disrupt_enemy_supplies(state, [supply_line_id]) do
    # Check if supply line exists and is vulnerable
    supply_line_active = AriaState.RelationalState.get_fact(state, "enemy_supply_line", supply_line_id) || false

    if supply_line_active do
      disruption_success = :rand.uniform() > 0.3  # 70% success rate

      if disruption_success do
        new_state = state
        |> AriaState.RelationalState.set_fact("supply_line_disrupted", supply_line_id, true)
        |> AriaState.RelationalState.set_fact("disruption_timestamp", supply_line_id, DateTime.utc_now())

        {:ok, new_state}
      else
        {:error, :disruption_failed}
      end
    else
      {:error, :supply_line_not_found}
    end
  end

  @doc """
  Secure a strategic block position.

  Establishes control over key tactical locations.
  """
  @action duration: "PT10M",
          requires_entities: [%{type: "operative", capabilities: [:position_securing, :tactical_control]}]
  @spec secure_position(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def secure_position(state, [position_id]) do
    # Check position vulnerability
    position_controlled = AriaState.RelationalState.get_fact(state, "position_controlled", position_id) || false

    if not position_controlled do
      security_score = calculate_position_security(state, position_id)

      if security_score >= 0.6 do
        new_state = state
        |> AriaState.RelationalState.set_fact("position_controlled", position_id, true)
        |> AriaState.RelationalState.set_fact("position_security", position_id, security_score)
        |> AriaState.RelationalState.set_fact("control_timestamp", position_id, DateTime.utc_now())

        {:ok, new_state}
      else
        {:error, :position_not_secure}
      end
    else
      {:error, :position_already_controlled}
    end
  end

  @doc """
  Command method for firefight coordination with risk assessment.
  """
  @command true
  @spec coordinate_firefight_command(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_firefight_command(state, [firefight_id]) do
    # Assess risk before coordination
    risk_level = assess_firefight_risk(state, firefight_id)

    if risk_level <= 0.7 do  # Acceptable risk
      coordinate_firefight(state, [firefight_id])
    else
      {:error, {:risk_too_high, risk_level}}
    end
  end

  @doc """
  Task method for complete tactical operation.
  """
  @task_method true
  @spec execute_tactical_operation(AriaState.t(), [String.t()]) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def execute_tactical_operation(_state, [operation_id]) do
    {:ok, [
      # Secure position first
      {:secure_position, [operation_id]},

      # Gain tactical advantage
      {:gain_tactical_advantage, [operation_id]},

      # Coordinate firefight if needed
      {:coordinate_firefight, [operation_id]},

      # Disrupt enemy supplies
      {:disrupt_enemy_supplies, ["enemy_supply_#{operation_id}"]},

      # Goal: Position secured and advantageous
      {"position_controlled", operation_id, true}
    ]}
  end

  @doc """
  Unigoal method for achieving tactical control.
  """
  @unigoal_method predicate: "position_controlled"
  @spec achieve_tactical_control(AriaState.t(), {String.t(), boolean()}) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_tactical_control(state, {position_id, target_controlled}) do
    current_control = AriaState.RelationalState.get_fact(state, "position_controlled", position_id) || false

    if current_control == target_controlled do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:secure_position, [position_id]},
        {:gain_tactical_advantage, [position_id]},
        {"position_controlled", position_id, target_controlled}
      ]}
    end
  end

  # Helper functions
  defp calculate_tactical_advantage(state, position_id) do
    # Base advantage calculation
    base_advantage = 0.5

    # Factors affecting advantage
    enemy_nearby = AriaState.RelationalState.get_fact(state, "enemy_nearby", position_id) || false
    cover_available = AriaState.RelationalState.get_fact(state, "cover_available", position_id) || false
    high_ground = AriaState.RelationalState.get_fact(state, "high_ground", position_id) || false

    advantage_modifiers = %{
      enemy_nearby: if(enemy_nearby, do: -0.2, else: 0.1),
      cover_available: if(cover_available, do: 0.15, else: -0.1),
      high_ground: if(high_ground, do: 0.2, else: 0.0)
    }

    total_modifier = Enum.sum(Map.values(advantage_modifiers))
    max(0.0, min(1.0, base_advantage + total_modifier))
  end

  defp calculate_position_security(state, position_id) do
    # Security calculation based on various factors
    base_security = 0.5

    # Security factors
    reinforcements_available = AriaState.RelationalState.get_fact(state, "reinforcements_available", position_id) || false
    enemy_pressure = AriaState.RelationalState.get_fact(state, "enemy_pressure", position_id) || 0.5
    defensive_position = AriaState.RelationalState.get_fact(state, "defensive_position", position_id) || false

    security_modifiers = %{
      reinforcements: if(reinforcements_available, do: 0.2, else: 0.0),
      enemy_pressure: -enemy_pressure * 0.3,
      defensive: if(defensive_position, do: 0.15, else: 0.0)
    }

    total_modifier = Enum.sum(Map.values(security_modifiers))
    max(0.0, min(1.0, base_security + total_modifier))
  end

  defp assess_firefight_risk(state, firefight_id) do
    # Risk assessment for firefight coordination
    enemy_strength = AriaState.RelationalState.get_fact(state, "enemy_strength", firefight_id) || 0.5
    friendly_support = AriaState.RelationalState.get_fact(state, "friendly_support", firefight_id) || 0.5
    terrain_advantage = AriaState.RelationalState.get_fact(state, "terrain_advantage", firefight_id) || 0.5

    # Risk formula: higher enemy strength and lower support increases risk
    risk = (enemy_strength * 0.4) + ((1 - friendly_support) * 0.3) + ((1 - terrain_advantage) * 0.3)
    min(1.0, risk)
  end
end
