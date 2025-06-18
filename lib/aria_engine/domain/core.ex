# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.Core do
  @moduledoc """
  Represents a planning domain in the GTPhop planner (Elixir port of GTPyhop).

  A domain contains:
  - Actions: Named functions that modify the world state
  - Task methods: Named functions that decompose tasks into subtasks
  - Unigoal methods: Named functions that achieve single goals
  - Multigoal methods: Named functions that achieve multiple goals simultaneously

  This implementation aligns with GTPyhop's approach where:
  - Actions are stored as name -> function mappings
  - Methods are stored as task_name -> list of {name, function} tuples
  - Method names are preserved for logging, blacklisting, and error reporting

  Example:
  ```elixir
  domain = AriaEngine.Domain.new("logistics")
  |> AriaEngine.Domain.add_action(:move, &move_action/2)
  |> AriaEngine.Domain.add_task_methods("transport", [
       {"transport", &transport_by_truck/2},
       {"transport", &transport_by_plane/2}
     ])
  ```
  """

  require Logger
  alias AriaEngine.StateV2

  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: (StateV2.t(), list() -> StateV2.t() | false)
  @type task_method_fn :: (StateV2.t(), list() -> list() | false)
  @type goal_method_fn :: (StateV2.t(), list() -> list() | false)
  @type named_method :: {method_name(), task_method_fn() | goal_method_fn()}

  alias AriaEngine.Domain.DurativeAction, as: DurativeAction

  @type durative_action_name :: DurativeAction.durative_action_name()
  @type durative_action :: DurativeAction.t()

  @type t :: %__MODULE__{
    name: String.t(),
    actions: %{action_name() => action_fn()},
    action_metadata: %{action_name() => map()}, # New field for action metadata
    task_methods: %{task_name() => [named_method()]},
    unigoal_methods: %{String.t() => [named_method()]},
    multigoal_methods: [named_method()],
    durative_actions: %{durative_action_name() => durative_action()} # New field for durative actions
  }

  defstruct name: "",
            actions: %{},
            action_metadata: %{}, # Initialize new field
            task_methods: %{},
            unigoal_methods: %{},
            multigoal_methods: [],
            durative_actions: %{} # Initialize new field

  @doc """
  Creates a new planning domain.
  """
  @spec new(String.t()) :: t()
  def new(name \\ "default") do
    %__MODULE__{name: name}
  end

  @doc """
  Validates a domain structure.

  ## Parameters
  - `domain`: Domain to validate

  ## Returns
  - `{:ok, domain}`: Valid domain
  - `{:error, reason}`: Invalid domain with reason
  """
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{} = domain) do
    cond do
      domain.name == "" or domain.name == nil ->
        {:error, "Domain name cannot be empty"}
      not is_map(domain.actions) ->
        {:error, "Actions must be a map"}
      not is_map(domain.action_metadata) -> # Validate new field
        {:error, "Action metadata must be a map"}
      not is_map(domain.task_methods) ->
        {:error, "Task methods must be a map"}
      not is_map(domain.unigoal_methods) ->
        {:error, "Unigoal methods must be a map"}
      not is_list(domain.multigoal_methods) ->
        {:error, "Multigoal methods must be a list"}
      not is_map(domain.durative_actions) ->
        {:error, "Durative actions must be a map"}
      true ->
        {:ok, domain}
    end
  end

  def validate(_), do: {:error, "Not a valid domain struct"}

  @doc """
  Adds a durative action to the domain.
  """
  @spec add_durative_action(t(), durative_action_name(), durative_action()) :: t()
  def add_durative_action(%__MODULE__{} = domain, name, durative_action) do
    %{domain | durative_actions: Map.put(domain.durative_actions, name, durative_action)}
  end

  @doc """
  Retrieves a durative action from the domain by name.
  """
  @spec get_durative_action(t(), durative_action_name()) :: durative_action() | nil
  def get_durative_action(%__MODULE__{durative_actions: durative_actions}, name) do
    Map.get(durative_actions, name)
  end
end
