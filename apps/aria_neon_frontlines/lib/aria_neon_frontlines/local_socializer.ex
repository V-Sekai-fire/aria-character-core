defmodule AriaNeonFrontlines.LocalSocializer do
  @moduledoc """
  Local Socializer Archetype for Neon Frontlines City Block Domain.

  Handles squad command and tactical coordination within the neon-lit city block.
  Focuses on team coordination, tactical decision logging, and command authority.

  Follows ADR R25W1398085: Unified Durative Action Specification.
  """

  use AriaCore.ActionAttributes

  @type squad_member :: String.t()
  @type tactical_decision :: map()

  @doc """
  Register local socializer entity with capabilities.

  Entity registration pattern per ADR R25W1398085.
  """
  @action true
  @spec register_local_socializer(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def register_local_socializer(state, [operative_id]) do
    state
    |> AriaState.RelationalState.set_fact("type", operative_id, "operative")
    |> AriaState.RelationalState.set_fact("capabilities", operative_id, [:command, :coordination, :decision_logging, :movement_planning, :command_setup, :tactical_planning])
    |> AriaState.RelationalState.set_fact("status", operative_id, "available")
    |> AriaState.RelationalState.set_fact("archetype", operative_id, "local_socializer")
    {:ok, state}
  end

  @doc """
  Get available actions for local socializer.
  """
  @spec actions(map()) :: [{atom(), String.t()}]
  def actions(_state) do
    [
      {:command_squad, "Issue tactical commands to squad members"},
      {:log_tactical_decision, "Record important tactical decisions"},
      {:coordinate_movement, "Coordinate squad movement through the block"},
      {:establish_command_post, "Set up a new command position"}
    ]
  end

  @doc """
  Initialize local socializer state with entity registration.
  """
  @spec init_state(String.t()) :: map()
  def init_state(operative_id) do
    # Initialize with entity registration
    {:ok, initial_state} = register_local_socializer(AriaState.RelationalState.new(), [operative_id])

    initial_state
    |> Map.put(:squad_members, ["operative_1", "operative_2", "operative_3"])
    |> Map.put(:command_authority, :high)
    |> Map.put(:coordination_bonus, 0.2)
    |> Map.put(:tactical_log, [])
    |> Map.put(:current_location, "command_post")
    |> Map.put(:neon_level, 0.8)
  end

  @doc """
  Issue tactical commands to squad members.

  Requires command authority and coordination capabilities.
  """
  @action duration: "PT5M",
          requires_entities: [%{type: "operative", capabilities: [:command, :coordination]}]
  @spec command_squad(AriaState.t(), [squad_member() | String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def command_squad(state, [target_member, command]) do
    # Validate squad membership
    squad_members = AriaState.RelationalState.get_fact(state, "squad_members", "active") || []

    if target_member in squad_members do
      new_state = state
      |> AriaState.RelationalState.set_fact("last_command", target_member, command)
      |> AriaState.RelationalState.set_fact("command_timestamp", target_member, DateTime.utc_now())

      {:ok, new_state}
    else
      {:error, :not_squad_member}
    end
  end

  @doc """
  Log important tactical decisions for future reference.

  Creates permanent record of strategic choices.
  """
  @action duration: "PT2M",
          requires_entities: [%{type: "operative", capabilities: [:decision_logging]}]
  @spec log_tactical_decision(AriaState.t(), [String.t() | map()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def log_tactical_decision(state, [decision_type, decision_data]) do
    timestamp = DateTime.utc_now()

    log_entry = %{
      type: decision_type,
      data: decision_data,
      timestamp: timestamp,
      operative: AriaState.RelationalState.get_fact(state, "operative_id", "current")
    }

    new_state = AriaState.RelationalState.set_fact(state, "tactical_log_entry", timestamp, log_entry)

    {:ok, new_state}
  end

  @doc """
  Coordinate squad movement through the block.

  Requires coordination capabilities and squad command authority.
  """
  @action duration: "PT10M",
          requires_entities: [%{type: "operative", capabilities: [:coordination, :movement_planning]}]
  @spec coordinate_movement(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_movement(state, [from_location, to_location]) do
    # Check squad readiness
    squad_ready = AriaState.RelationalState.get_fact(state, "squad_status", "readiness") || 0.0

    if squad_ready >= 0.7 do
      new_state = state
      |> AriaState.RelationalState.set_fact("movement_coordinated", {from_location, to_location}, true)
      |> AriaState.RelationalState.set_fact("squad_location", "current", to_location)

      {:ok, new_state}
    else
      {:error, :squad_not_ready}
    end
  end

  @doc """
  Establish a new command position in the block.

  Sets up tactical advantage and communication hubs.
  """
  @action duration: "PT15M",
          requires_entities: [%{type: "operative", capabilities: [:command_setup, :tactical_planning]}]
  @spec establish_command_post(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def establish_command_post(state, [location]) do
    # Check location suitability
    location_security = AriaState.RelationalState.get_fact(state, "location_security", location) || 0.5

    if location_security >= 0.6 do
      new_state = state
      |> AriaState.RelationalState.set_fact("command_post", location, true)
      |> AriaState.RelationalState.set_fact("communication_hub", location, true)
      |> AriaState.RelationalState.set_fact("tactical_advantage", location, 0.8)

      {:ok, new_state}
    else
      {:error, :location_not_secure}
    end
  end

  @doc """
  Command method for squad coordination with failure handling.
  """
  @command true
  @spec coordinate_movement_command(AriaState.t(), [String.t()]) ::
          {:ok, AriaState.t()} | {:error, atom()}
  def coordinate_movement_command(state, [from, to]) do
    # Simulate coordination challenges
    case :rand.uniform() do
      x when x < 0.85 -> coordinate_movement(state, [from, to])  # 85% success
      _ -> {:error, :coordination_failed}
    end
  end

  @doc """
  Task method for complete tactical operation setup.
  """
  @task_method true
  @spec setup_tactical_operation(AriaState.t(), [String.t()]) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def setup_tactical_operation(_state, [target_location]) do
    {:ok, [
      # Establish command post first
      {:establish_command_post, [target_location]},

      # Coordinate squad movement
      {:coordinate_movement, ["current_position", target_location]},

      # Log the tactical decision
      {:log_tactical_decision, ["operation_setup", %{location: target_location}]},

      # Goal: Command post established
      {"command_post", target_location, true}
    ]}
  end

  @doc """
  Unigoal method for achieving squad coordination.
  """
  @unigoal_method predicate: "squad_coordinated"
  @spec achieve_squad_coordination(AriaState.t(), {String.t(), String.t()}) ::
          {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achieve_squad_coordination(state, {squad_id, target_state}) do
    current_coordination = AriaState.RelationalState.get_fact(state, "squad_coordination", squad_id) || "uncoordinated"

    if current_coordination == target_state do
      {:ok, []}  # Already achieved
    else
      {:ok, [
        {:command_squad, [squad_id, "coordinate_to_#{target_state}"]},
        {"squad_coordinated", squad_id, target_state}
      ]}
    end
  end
end
