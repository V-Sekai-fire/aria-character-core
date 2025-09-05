defmodule Vsekai.Domains.GameDomain do
  use AriaHybridPlanner.Domain
  require Logger

  # --- TYPE DEFINITIONS ---
  @type agent_id :: String.t()
  @type world_id :: String.t()
  @type resource_id :: String.t()
  @type capability :: atom()
  @type entity_type :: atom()
  @type timestamp_iso8601 :: String.t()

  # --- GOAL-TASK CHAINS FOR PLAYER ARCHETYPES ---

  # 1. The Social Explorer
  # The goal is to join a popular world and engage in social interaction.
  @task_method true
  @spec social_explorer_loop(AriaState.t(), [agent_id()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def social_explorer_loop(_state, [agent_id]) do
    {:ok, [
      # Task 1: Find a social world
      {"has_world_type", "public_world_1", "social"},

      # Task 2: Join the world
      {:join_world, ["public_world_1", agent_id]},

      # Task 3: Socialize for a set duration
      {:socialize, [agent_id]},

      # Task 4: Log social event (Analytics)
      {:log_social_event, [agent_id]}
    ]}
  end

  # The actual task of joining a world.
  # This uses a command because it interacts with external systems (API Layer).
  @command true
  @spec join_world_command(AriaState.t(), [world_id(), agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def join_world_command(state, [world_id, agent_id]) do
    Logger.info("Agent #{agent_id} is joining world #{world_id}.")
    # Simulate API call and state change. This would be where a call to the
    # API Layer is made to get the world state for the agent.
    new_state = state
    |> AriaState.RelationalState.set_fact("current_world", agent_id, world_id)
    |> AriaState.RelationalState.set_fact("status", agent_id, "active")
    {:ok, new_state}
  end

  # The durative action for socializing.
  @action duration: "PT1H",
          requires_entities: [
            %{type: "agent", capabilities: [:socializer]},
            %{type: "world", capabilities: [:social]}
          ]
  @spec socialize(AriaState.t(), [agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def socialize(state, [agent_id]) do
    Logger.info("Agent #{agent_id} is socializing.")
    new_state = state |> AriaState.RelationalState.set_fact("last_social_activity", agent_id, DateTime.utc_now())
    {:ok, new_state}
  end

  # The command for logging analytics, non-blocking and asynchronous.
  @command true
  @spec log_social_event(AriaState.t(), [agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def log_social_event(state, [agent_id]) do
    Logger.info("Logging social event for #{agent_id} for analytics.")
    # This would simulate an async call to the API Layer for TimescaleDB ingestion.
    {:ok, state}
  end

  # 2. The World Hopper
  # The goal is to explore a number of different worlds.
  @task_method true
  @spec world_hopper_loop(AriaState.t(), [agent_id(), number()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def world_hopper_loop(_state, [agent_id, count]) do
    {:ok,
      Enum.map(1..count, fn _ ->
        # The agent's goal is to visit a new world each time
        {"world_visited", agent_id, UUID.uuid4()}
      end)
    }
  end

  # Unigoal method to fulfill the "world_visited" goal.
  @unigoal_method predicate: "world_visited"
  @spec visit_new_world(AriaState.t(), {subject(), value()}) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def visit_new_world(state, {agent_id, world_id}) do
    {:ok, [
      {:create_world_instance, [world_id]},
      {:transfer_to_world, [agent_id, world_id]}
    ]}
  end

  # Action to simulate a fast, in-memory transfer.
  @action true
  @spec transfer_to_world(AriaState.t(), [agent_id(), world_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def transfer_to_world(state, [agent_id, world_id]) do
    Logger.info("Agent #{agent_id} is transferring to #{world_id} in-memory.")
    new_state = state |> AriaState.RelationalState.set_fact("current_world", agent_id, world_id)
    {:ok, new_state}
  end

  # 3. The Achiever
  # The goal is to acquire a large quantity of a refined resource.
  @task_method true
  @spec achiever_loop(AriaState.t(), [agent_id(), resource_id(), number()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def achiever_loop(_state, [agent_id, resource_id, quantity]) do
    {:ok, [
      # Goal to have the desired quantity of the refined resource
      {"has_quantity", {agent_id, resource_id}, {quantity, :>=}},
      # Primary task to refine the resource
      {:refine_resource, [agent_id, resource_id, quantity]}
    ]}
  end

  # Task to break down the refinement process.
  @task_method true
  @spec refine_resource(AriaState.t(), [agent_id(), resource_id(), number()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def refine_resource(state, [agent_id, resource_id, quantity]) do
    raw_resource_id = get_raw_resource(resource_id)
    Logger.info("Agent #{agent_id} needs to refine #{quantity} of #{resource_id} from raw #{raw_resource_id}.")
    {:ok, [
      {"has_quantity", {agent_id, raw_resource_id}, {quantity, :>=}},
      {:process_item, [agent_id, raw_resource_id, resource_id, quantity]}
    ]}
  end

  # Action for the actual processing.
  # This uses a command because it represents a real, transactional event.
  @command true
  @spec process_item(AriaState.t(), [agent_id(), resource_id(), resource_id(), number()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def process_item(state, [agent_id, raw_id, refined_id, quantity]) do
    Logger.info("Agent #{agent_id} is processing #{quantity} of #{raw_id} into #{refined_id}.")
    # Simulate an atomic transaction with the Persistence Layer.
    # The actual implementation would involve a call to the API layer.
    new_state = state
    |> AriaState.RelationalState.set_fact("inventory_change", agent_id, -quantity, raw_id)
    |> AriaState.RelationalState.set_fact("inventory_change", agent_id, +quantity, refined_id)
    {:ok, new_state}
  end

  defp get_raw_resource("iron_ingot"), do: "iron_ore"
  defp get_raw_resource("steel_plate"), do: "iron_ingot"
  defp get_raw_resource(_), do: nil

  # 4. The Competitor
  # The goal is to engage in combat and improve a ranking.
  @task_method true
  @spec competitor_loop(AriaState.t(), [agent_id()]) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def competitor_loop(_state, [agent_id]) do
    {:ok, [
      # Task 1: Find a match
      {"has_match", agent_id, true},

      # Task 2: Engage in combat
      {:engage_in_combat, [agent_id]},

      # Task 3: Record outcome and update rank
      {:record_match_outcome, [agent_id]}
    ]}
  end

  # The action for combat. This is where high-frequency events happen.
  @action true
  @spec engage_in_combat(AriaState.t(), [agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def engage_in_combat(state, [agent_id]) do
    Logger.info("Agent #{agent_id} is engaging in combat.")
    # Simulate in-memory combat, which doesn't directly hit the DB
    {:ok, state}
  end

  # The command to record a match outcome. This is a high-stakes transaction.
  @command true
  @spec record_match_outcome(AriaState.t(), [agent_id()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def record_match_outcome(state, [agent_id]) do
    Logger.info("Agent #{agent_id} is recording match outcome.")
    # Simulate an atomic transaction to update the global leaderboard.
    new_state = state
    |> AriaState.RelationalState.set_fact("rank", agent_id, 1, "update") # Example update
    |> AriaState.RelationalState.set_fact("last_match_result", agent_id, "win")
    {:ok, new_state}
  end
end
