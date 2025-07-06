# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSimpleTravel.Domain do
  @moduledoc """
  Simple Travel planning domain for AriaEngine with durative actions.

  This domain demonstrates the unified durative action specification from R25W1398085,
  implementing a travel planning scenario where people can move between locations
  using different transportation methods with temporal constraints.

  ## Entity Model

  - **People**: Entities with movement and payment capabilities
  - **Taxis**: Entities with transportation capabilities
  - **Locations**: Spatial entities that serve as destinations

  ## Temporal Patterns

  - **Instant actions**: call_taxi, pay_driver (Pattern 1)
  - **Durative actions**: walk, ride_taxi (Pattern 6 - calculated end)

  ## Example Usage

      # Create domain and state
      domain = AriaSimpleTravel.Domain.create_domain()
      state = AriaSimpleTravel.Domain.setup_scenario(AriaState.new(), [])

      # Plan travel
      goals = [{"location", "alice", "park"}]
      {:ok, solution_tree} = AriaEngineCore.plan(domain, state, goals)

      # Execute plan
      {:ok, {final_state, _}} = AriaEngineCore.run_lazy_tree(domain, state, solution_tree)
  """

  use AriaCore.ActionAttributes

  @type person_id :: String.t()
  @type location_id :: String.t()
  @type taxi_id :: String.t()
  @type distance :: number()
  @type cash_amount :: number()

  # ============================================================================
  # Entity Setup and Registration
  # ============================================================================

  @doc """
  Set up the simple travel scenario with entities and initial state.
  """
  @action true
  @spec setup_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_scenario(state, []) do
    state
    |> register_people()
    |> register_taxis()
    |> register_locations()
    |> setup_distances()
    |> setup_initial_conditions()
    |> then(&{:ok, &1})
  end

  # ============================================================================
  # Instant Actions (Pattern 1: Instant action, anytime)
  # ============================================================================

  @doc """
  Walk one step (10 minutes of walking).

  This is an atomic action that represents a single unit of walking movement.
  Task methods will decompose longer walks into multiple walk_step actions.
  """
  @spec walk_step(AriaState.t(), list()) :: {:ok, AriaState.t()} | {:error, atom()}
  @action duration: "PT10M",
          requires_entities: [
            %{type: "person", capabilities: [:walking]}
          ]
  def walk_step(state, [person, from, to]) do
    if from != to do
      state
      |> AriaState.set_fact("location", person, to)
      |> then(&{:ok, &1})
    else
      {:error, :same_location}
    end
  end

  @doc """
  Walk from one location to another.

  This is a composite action that gets decomposed into multiple walk_step actions based on distance.
  """
  @spec walk(AriaState.t(), list()) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  @task_method true
  def walk(state, [person, from, to]) do
    if from != to do
      distance = get_distance(state, from, to)
      walk_steps = for _step <- 1..distance do
        {:walk_step, [person, from, to]}
      end
      {:ok, walk_steps}
    else
      {:error, :same_location}
    end
  end

  @doc """
  Call a taxi to the person's current location.

  This is an instant action that immediately brings a taxi to the caller's location
  and places the person inside the taxi.
  """
  @action duration: "PT0S",
          requires_entities: [
            %{type: "person", capabilities: [:taxi_calling]},
            %{type: "taxi", capabilities: [:transportation]}
          ]
  @spec call_taxi(AriaState.t(), list()) :: {:ok, AriaState.t()} | {:error, atom()}
  def call_taxi(state, [person, taxi]) do
    person_location = AriaState.get_fact(state, "location", person)

    state
    |> AriaState.set_fact("location", taxi, person_location)
    |> AriaState.set_fact("location", person, taxi)
    |> then(&{:ok, &1})
  end

  @doc """
  Pay the taxi driver and exit the taxi.

  This is an instant action that processes payment and moves the person
  from the taxi to their destination.
  """
  @action duration: "PT0S",
          requires_entities: [
            %{type: "person", capabilities: [:payment]}
          ]
  @spec pay_driver(AriaState.t(), list()) :: {:ok, AriaState.t()} | {:error, atom()}
  def pay_driver(state, [person, destination]) do
    current_cash = AriaState.get_fact(state, "cash", person) || 0
    owed_amount = AriaState.get_fact(state, "owe", person) || 0

    if current_cash >= owed_amount do
      state
      |> AriaState.set_fact("cash", person, current_cash - owed_amount)
      |> AriaState.set_fact("owe", person, 0)
      |> AriaState.set_fact("location", person, destination)
      |> then(&{:ok, &1})
    else
      {:error, :insufficient_funds}
    end
  end

  # ============================================================================
  # Durative Actions (Pattern 6: Calculated end = start + duration)
  # ============================================================================

  @doc """
  Ride taxi one step (5 minutes of taxi travel).

  This is an atomic action that represents a single unit of taxi movement.
  Task methods will decompose longer rides into multiple ride_step actions.
  """
  @spec ride_step(AriaState.t(), list()) :: {:ok, AriaState.t()} | {:error, atom()}
  @action duration: "PT5M",
          requires_entities: [
            %{type: "person", capabilities: [:taxi_riding]},
            %{type: "taxi", capabilities: [:transportation]}
          ]
  def ride_step(state, [person, destination]) do
    # Person should be in a taxi
    current_location = AriaState.get_fact(state, "location", person)

    if is_taxi?(state, current_location) do
      taxi = current_location
      taxi_location = AriaState.get_fact(state, "location", taxi)
      distance = get_distance(state, taxi_location, destination)
      fare = calculate_taxi_fare(distance)

      state
      |> AriaState.set_fact("location", taxi, destination)
      |> AriaState.set_fact("owe", person, fare)
      |> then(&{:ok, &1})
    else
      {:error, :not_in_taxi}
    end
  end

  @doc """
  Ride taxi to destination.

  This is a composite action that gets decomposed by the travel task method
  into multiple ride_step actions based on distance.
  """
  @task_method true
  @spec ride_taxi(AriaState.t(), list()) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def ride_taxi(state, [person, destination]) do
    # Person should be in a taxi
    current_location = AriaState.get_fact(state, "location", person)

    if is_taxi?(state, current_location) do
      taxi_location = AriaState.get_fact(state, "location", current_location)
      distance = get_distance(state, taxi_location, destination)

      ride_steps = for _step <- 1..distance do
        {:ride_step, [person, destination]}
      end

      {:ok, ride_steps}
    else
      {:error, :not_in_taxi}
    end
  end

  # ============================================================================
  # Task Methods (Complex workflow decomposition)
  # ============================================================================

  @doc """
  High-level travel task that chooses the best transportation method.

  Decomposes travel into appropriate sub-tasks based on distance and resources.
  """
  @task_method true
  @spec travel(AriaState.t(), list()) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def travel(state, [person, destination]) do
    current_location = AriaState.get_fact(state, "location", person)

    cond do
      current_location == destination ->
        # Already at destination
        {:ok, []}

      can_walk?(state, current_location, destination) ->
        # Walk if distance is reasonable (≤ 2 units)
        # Decompose into multiple walk_step actions based on distance
        distance = get_distance(state, current_location, destination)
        walk_steps = for _step <- 1..distance do
          {:walk_step, [person, current_location, destination]}
        end
        {:ok, walk_steps}

      can_afford_taxi?(state, person, current_location, destination) ->
        # Take taxi if affordable
        # Decompose into call, multiple ride steps, and payment
        distance = get_distance(state, current_location, destination)
        ride_steps = for _step <- 1..distance do
          {:ride_step, [person, destination]}
        end

        taxi_actions = [
          {:call_taxi, [person, "taxi1"]}
        ] ++ ride_steps ++ [
          {:pay_driver, [person, destination]}
        ]

        {:ok, taxi_actions}

      true ->
        {:error, :no_viable_transportation}
    end
  end

  # ============================================================================
  # Unigoal Methods (Handle single predicate goals)
  # ============================================================================

  @doc """
  Achieve a specific location goal for a person.
  """
  @unigoal_method predicate: "location"
  @spec achieve_location(AriaState.t(), {person_id(), location_id()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_location(_state, {person, target_location}) do
    {:ok, [{:travel, [person, target_location]}]}
  end

  # ============================================================================
  # Domain Creation and Configuration
  # ============================================================================

  @doc """
  Create the Simple Travel domain with AriaCore integration.
  """
  @spec create_domain(map()) :: AriaCore.Domain.t()
  def create_domain(_opts \\ %{}) do
    require Logger
    # Create a proper AriaCore.Domain struct
    domain = AriaCore.new_domain(:simple_travel)

    Logger.debug("Domain before attribute registration: actions = #{inspect(Map.keys(domain.actions))}")

    # Register all attribute-defined actions and methods
    AriaCore.register_attribute_specs(domain, __MODULE__)
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================

  defp register_people(state) do
    state
    |> register_entity("alice", "person", [:walking, :taxi_calling, :taxi_riding, :payment])
    |> register_entity("bob", "person", [:walking, :taxi_calling, :taxi_riding, :payment])
    |> AriaState.set_fact("cash", "alice", 20.0)
    |> AriaState.set_fact("cash", "bob", 15.0)
    |> AriaState.set_fact("owe", "alice", 0.0)
    |> AriaState.set_fact("owe", "bob", 0.0)
  end

  defp register_taxis(state) do
    state
    |> register_entity("taxi1", "taxi", [:transportation, :route_planning])
    |> AriaState.set_fact("status", "taxi1", "available")
  end

  defp register_locations(state) do
    state
    |> register_entity("home_a", "location", [:destination, :waypoint])
    |> register_entity("home_b", "location", [:destination, :waypoint])
    |> register_entity("park", "location", [:destination, :waypoint])
    |> register_entity("downtown", "location", [:destination, :waypoint])
  end

  defp setup_distances(state) do
    distances = %{
      {"home_a", "park"} => 8,
      {"home_b", "park"} => 2,
      {"home_a", "downtown"} => 7,
      {"home_b", "downtown"} => 8,
      {"park", "downtown"} => 9
    }

    Enum.reduce(distances, state, fn {{loc1, loc2}, dist}, acc ->
      acc
      |> AriaState.set_fact("distance", {loc1, loc2}, dist)
      |> AriaState.set_fact("distance", {loc2, loc1}, dist)
    end)
  end

  defp setup_initial_conditions(state) do
    state
    |> AriaState.set_fact("location", "alice", "home_a")
    |> AriaState.set_fact("location", "bob", "home_b")
    |> AriaState.set_fact("location", "taxi1", "downtown")
  end

  defp register_entity(state, entity_id, type, capabilities) do
    state
    |> AriaState.set_fact("type", entity_id, type)
    |> AriaState.set_fact("capabilities", entity_id, capabilities)
    |> AriaState.set_fact("status", entity_id, "available")
  end


  defp get_distance(state, loc1, loc2) do
    AriaState.get_fact(state, "distance", {loc1, loc2}) ||
    AriaState.get_fact(state, "distance", {loc2, loc1}) ||
    0
  end

  defp calculate_taxi_fare(distance) do
    1.5 + 0.5 * distance
  end

  defp can_walk?(state, from, to) do
    distance = get_distance(state, from, to)
    distance > 0 && distance <= 2
  end

  defp can_afford_taxi?(state, person, from, to) do
    cash = AriaState.get_fact(state, "cash", person) || 0
    distance = get_distance(state, from, to)
    fare = calculate_taxi_fare(distance)
    cash >= fare
  end

  defp is_taxi?(state, entity) do
    AriaState.get_fact(state, "type", entity) == "taxi"
  end
end
