# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike do
  @moduledoc """
  TimeStrike temporal planning game domain for AriaEngine.

  This module implements the four core action types used in TimeStrike:
  - move_to: Move an agent to a target position
  - attack: Attack an enemy or destructible object
  - skill_cast: Cast a special skill or spell
  - interact: Interact with world objects (pillars, hostages, etc.)
  """

  alias AriaEngine.{Domain, State}

  @doc """
  Creates a TimeStrike domain with game-specific actions.
  """
  @spec create_domain() :: Domain.t()
  def create_domain do
    Domain.new("timestrike")
    |> Domain.add_actions(%{
      move_to: &move_to/2,
      attack: &attack/2,
      skill_cast: &skill_cast/2,
      interact: &interact/2
    })
  end

  @doc """
  Move an agent to a target position.

  Preconditions:
  - Agent exists and is alive
  - Target position is valid and walkable

  Effects:
  - Agent position is updated to target position
  - Movement duration is calculated based on distance and agent speed
  """
  @spec move_to(State.t(), [String.t() | tuple()]) :: State.t() | false
  def move_to(state, [agent_id, target_pos]) do
    current_pos = State.get_object(state, "position", agent_id)
    agent_speed = State.get_object(state, "move_speed", agent_id) || 3.0

    if current_pos && target_pos && valid_position?(target_pos) do
      distance = calculate_distance(current_pos, target_pos)
      duration = distance / agent_speed

      state
      |> State.set_object("position", agent_id, target_pos)
      |> State.set_object("last_action", agent_id, :move_to)
      |> State.set_object("action_duration", agent_id, duration)
    else
      false
    end
  end

  @doc """
  Attack a target (enemy or destructible object).

  Preconditions:
  - Agent exists and is alive
  - Target exists and is in range
  - Agent has attack capability

  Effects:
  - Target HP is reduced by damage amount
  - Agent cooldowns may be applied
  """
  @spec attack(State.t(), [String.t()]) :: State.t() | false
  def attack(state, [agent_id, target_id]) do
    agent_attack = State.get_object(state, "attack", agent_id) || 10
    agent_pos = State.get_object(state, "position", agent_id)
    target_pos = State.get_object(state, "position", target_id)
    target_hp = State.get_object(state, "hp", target_id) || 0
    target_defense = State.get_object(state, "defense", target_id) || 0

    if agent_pos && target_pos && target_hp > 0 && in_attack_range?(agent_pos, target_pos) do
      damage = max(1, agent_attack - target_defense)
      new_hp = max(0, target_hp - damage)

      state
      |> State.set_object("hp", target_id, new_hp)
      |> State.set_object("last_action", agent_id, :attack)
      |> State.set_object("action_duration", agent_id, 1.5)  # 1.5 second attack duration
      |> State.set_object("last_damage_dealt", agent_id, damage)
    else
      false
    end
  end

  @doc """
  Cast a skill or spell.

  Preconditions:
  - Agent exists and has the skill
  - Agent has sufficient mana/energy
  - Skill is not on cooldown

  Effects:
  - Skill effects are applied (damage, healing, buffs, etc.)
  - Mana/energy is consumed
  - Cooldown is applied
  """
  @spec skill_cast(State.t(), [String.t() | tuple()]) :: State.t() | false
  def skill_cast(state, [agent_id, skill_name, target_pos]) do
    agent_mana = State.get_object(state, "mana", agent_id) || 50
    skill_cost = get_skill_cost(skill_name)
    skill_cooldown = get_skill_cooldown(skill_name)

    if agent_mana >= skill_cost && skill_available?(state, agent_id, skill_name) do
      state
      |> State.set_object("mana", agent_id, agent_mana - skill_cost)
      |> State.set_object("last_action", agent_id, :skill_cast)
      |> State.set_object("action_duration", agent_id, get_skill_cast_time(skill_name))
      |> State.set_object("skill_cooldown_#{skill_name}", agent_id, skill_cooldown)
      |> apply_skill_effects(agent_id, skill_name, target_pos)
    else
      false
    end
  end

  @doc """
  Interact with a world object.

  Preconditions:
  - Agent exists and is alive
  - Object exists and is interactable
  - Agent is in interaction range

  Effects:
  - Object state is modified based on interaction type
  - Agent may gain items or trigger events
  """
  @spec interact(State.t(), [String.t()]) :: State.t() | false
  def interact(state, [agent_id, object_id, interaction_type]) do
    agent_pos = State.get_object(state, "position", agent_id)
    object_pos = State.get_object(state, "position", object_id)
    object_hp = State.get_object(state, "hp", object_id)

    if agent_pos && object_pos && in_interaction_range?(agent_pos, object_pos) do
      state
      |> State.set_object("last_action", agent_id, :interact)
      |> State.set_object("action_duration", agent_id, 2.0)  # 2 second interaction
      |> apply_interaction_effects(agent_id, object_id, interaction_type, object_hp)
    else
      false
    end
  end

  # Helper functions

  @spec valid_position?(tuple()) :: boolean()
  defp valid_position?({x, y, z}) when is_number(x) and is_number(y) and is_number(z), do: true
  defp valid_position?(_), do: false

  @spec calculate_distance(tuple(), tuple()) :: float()
  defp calculate_distance({x1, y1, z1}, {x2, y2, z2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2) + :math.pow(z2 - z1, 2))
  end

  @spec in_attack_range?(tuple(), tuple()) :: boolean()
  defp in_attack_range?(pos1, pos2) do
    calculate_distance(pos1, pos2) <= 2.0  # 2 unit attack range
  end

  @spec in_interaction_range?(tuple(), tuple()) :: boolean()
  defp in_interaction_range?(pos1, pos2) do
    calculate_distance(pos1, pos2) <= 1.5  # 1.5 unit interaction range
  end

  @spec skill_available?(State.t(), String.t(), String.t()) :: boolean()
  defp skill_available?(state, agent_id, skill_name) do
    cooldown_key = "skill_cooldown_#{skill_name}"
    cooldown = State.get_object(state, cooldown_key, agent_id) || 0
    cooldown <= 0
  end

  @spec get_skill_cost(String.t()) :: integer()
  defp get_skill_cost("fireball"), do: 25
  defp get_skill_cost("heal"), do: 20
  defp get_skill_cost("shield"), do: 15
  defp get_skill_cost("lightning"), do: 30
  defp get_skill_cost("scorch"), do: 35
  defp get_skill_cost(_), do: 20

  @spec get_skill_cooldown(String.t()) :: float()
  defp get_skill_cooldown("fireball"), do: 5.0
  defp get_skill_cooldown("heal"), do: 3.0
  defp get_skill_cooldown("shield"), do: 8.0
  defp get_skill_cooldown("lightning"), do: 6.0
  defp get_skill_cooldown("scorch"), do: 8.0
  defp get_skill_cooldown(_), do: 5.0

  @spec get_skill_cast_time(String.t()) :: float()
  defp get_skill_cast_time("fireball"), do: 1.5
  defp get_skill_cast_time("heal"), do: 2.0
  defp get_skill_cast_time("shield"), do: 1.0
  defp get_skill_cast_time("lightning"), do: 2.5
  defp get_skill_cast_time("scorch"), do: 2.0
  defp get_skill_cast_time(_), do: 1.5

  @spec apply_skill_effects(State.t(), String.t(), String.t(), tuple()) :: State.t()
  defp apply_skill_effects(state, agent_id, skill_name, target_pos) do
    case skill_name do
      "fireball" ->
        # AoE damage at target position
        state
        |> State.set_object("last_skill_target", agent_id, target_pos)
        |> State.set_object("last_skill_damage", agent_id, 45)

      "heal" ->
        # Heal the agent
        current_hp = State.get_object(state, "hp", agent_id) || 100
        max_hp = State.get_object(state, "max_hp", agent_id) || 100
        new_hp = min(max_hp, current_hp + 30)
        State.set_object(state, "hp", agent_id, new_hp)

      "shield" ->
        # Apply damage reduction buff
        state
        |> State.set_object("shield_active", agent_id, true)
        |> State.set_object("shield_duration", agent_id, 10.0)

      "lightning" ->
        # Chain lightning damage
        state
        |> State.set_object("last_skill_target", agent_id, target_pos)
        |> State.set_object("last_skill_damage", agent_id, 35)

      "scorch" ->
        # Maya's signature AoE spell
        state
        |> State.set_object("last_skill_target", agent_id, target_pos)
        |> State.set_object("last_skill_damage", agent_id, 50)

      _ ->
        state
    end
  end

  @spec apply_interaction_effects(State.t(), String.t(), String.t(), String.t(), integer() | nil) :: State.t()
  defp apply_interaction_effects(state, agent_id, object_id, interaction_type, object_hp) do
    case interaction_type do
      "activate" ->
        # Activate/toggle object
        State.set_object(state, "activated", object_id, true)

      "collect" ->
        # Add item to agent inventory
        state
        |> State.set_object("inventory_#{object_id}", agent_id, true)
        |> State.set_object("collected", object_id, true)

      "repair" ->
        # Repair damaged object
        max_hp = State.get_object(state, "max_hp", object_id) || 100
        new_hp = min(max_hp, (object_hp || 0) + 25)
        State.set_object(state, "hp", object_id, new_hp)

      "examine" ->
        # Examine object for information
        State.set_object(state, "examined", object_id, true)

      "attack" ->
        # Attack the object (for destructible objects like pillars)
        agent_attack = State.get_object(state, "attack", agent_id) || 15
        new_hp = max(0, (object_hp || 0) - agent_attack)
        State.set_object(state, "hp", object_id, new_hp)

      _ ->
        state
    end
  end
end
