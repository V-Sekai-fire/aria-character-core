# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain.Core do
  @moduledoc "Represents a planning domain in the GTPhop planner (Elixir port of GTPyhop).\n\nA domain contains:\n- Actions: Named functions that modify the world state\n- Task methods: Named functions that decompose tasks into subtasks\n- Unigoal methods: Named functions that achieve single goals\n- Multigoal methods: Named functions that achieve multiple goals simultaneously\n\nThis implementation aligns with GTPyhop's approach where:\n- Actions are stored as name -> function mappings\n- Methods are stored as task_name -> list of {name, function} tuples\n- Method names are preserved for logging, blacklisting, and error reporting\n\nExample:\n```elixir\ndomain = AriaEngineCore.Domain.new(\"logistics\")\n|> AriaEngineCore.Domain.add_action(:move, &move_action/2)\n|> AriaEngineCore.Domain.add_task_methods(\"transport\", [\n     {\"transport\", &transport_by_truck/2},\n     {\"transport\", &transport_by_plane/2}\n   ])\n```\n"
  require Logger
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: (AriaEngineCore.State.t(), list() -> AriaEngineCore.State.t() | false)
  @type task_method_fn :: (AriaEngineCore.State.t(), list() -> list() | false)
  @type goal_method_fn :: (AriaEngineCore.State.t(), list() -> list() | false)
  @type named_method :: {method_name(), task_method_fn() | goal_method_fn()}
  alias AriaEngineCore.Domain.DurativeAction, as: DurativeAction
  @type durative_action_name :: DurativeAction.durative_action_name()
  @type durative_action :: DurativeAction.t()
  @type t :: %__MODULE__{
          name: String.t(),
          actions: %{action_name() => action_fn()},
          action_metadata: %{action_name() => map()},
          task_methods: %{task_name() => [named_method()]},
          unigoal_methods: %{String.t() => [named_method()]},
          multigoal_methods: [named_method()],
          multitodo_methods: [named_method()],
          durative_actions: %{durative_action_name() => durative_action()}
        }
  defstruct name: "",
            actions: %{},
            action_metadata: %{},
            task_methods: %{},
            unigoal_methods: %{},
            multigoal_methods: [],
            multitodo_methods: [],
            durative_actions: %{}

  @doc "Creates a new planning domain.\n"
  @spec new(String.t()) :: t()
  def new(name \\ "default") do
    %__MODULE__{name: name}
  end

  @doc "Validates a domain structure.\n\n## Parameters\n- `domain`: Domain to validate\n\n## Returns\n- `{:ok, domain}`: Valid domain\n- `{:error, reason}`: Invalid domain with reason\n"
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{} = domain) do
    cond do
      domain.name == "" or domain.name == nil -> {:error, "Domain name cannot be empty"}
      not is_map(domain.actions) -> {:error, "Actions must be a map"}
      not is_map(domain.action_metadata) -> {:error, "Action metadata must be a map"}
      not is_map(domain.task_methods) -> {:error, "Task methods must be a map"}
      not is_map(domain.unigoal_methods) -> {:error, "Unigoal methods must be a map"}
      not is_list(domain.multigoal_methods) -> {:error, "Multigoal methods must be a list"}
      not is_list(domain.multitodo_methods) -> {:error, "Multitodo methods must be a list"}
      not is_map(domain.durative_actions) -> {:error, "Durative actions must be a map"}
      true -> {:ok, domain}
    end
  end

  def validate(_) do
    {:error, "Not a valid domain struct"}
  end

  @doc "Adds an action (function or struct) to the domain.\n"
  @spec add_action(t(), action_name(), any()) :: t()
  def add_action(
        %__MODULE__{actions: actions, action_metadata: action_metadata} = domain,
        name,
        action
      ) do
    cond do
      is_function(action, 2) ->
        %{domain | actions: Map.put(actions, name, action)}

      is_map(action) and Map.has_key?(action, :metadata) ->
        metadata = Map.get(action, :metadata, %{})

        normalized_metadata =
          if Map.has_key?(metadata, :duration) do
            duration = metadata[:duration]
            Map.put(metadata, :duration, AriaEngineCore.Utils.normalize_duration(duration))
          else
            metadata
          end

        updated_action_metadata = Map.put(action_metadata, name, normalized_metadata)

        %{
          domain
          | actions: Map.put(actions, name, action),
            action_metadata: updated_action_metadata
        }

      true ->
        %{domain | actions: Map.put(actions, name, action)}
    end
  end

  @doc "Retrieves a durative action from the domain by name.\n"
  @spec get_durative_action(t(), durative_action_name()) :: durative_action() | nil
  def get_durative_action(%__MODULE__{durative_actions: durative_actions}, name) do
    Map.get(durative_actions, name)
  end

  # These functions should delegate to AriaCore.Domain
  @doc "Sets the entity registry for the domain.\n"
  @spec set_entity_registry(t(), map()) :: t()
  def set_entity_registry(%__MODULE__{} = domain, registry) do
    # This function should ideally be handled by AriaCore.Domain
    # For now, we'll keep it as a no-op or raise an error if it's not meant to be here.
    # Given the current structure, it's likely that AriaEngineCore.Domain.Core
    # should not be directly managing the entity registry.
    Logger.warning("AriaEngineCore.Domain.Core.set_entity_registry called. This should be handled by AriaCore.Domain.")
    domain
  end

  @doc "Retrieves the entity registry from the domain.\n"
  @spec get_entity_registry(t()) :: map()
  def get_entity_registry(%__MODULE__{} = _domain) do
    # This function should ideally be handled by AriaCore.Domain
    # For now, return an empty map or raise an error.
    Logger.warning("AriaEngineCore.Domain.Core.get_entity_registry called. This should be handled by AriaCore.Domain.")
    %{}
  end

  @doc "Sets the temporal specifications for the domain.\n"
  @spec set_temporal_specifications(t(), map()) :: t()
  def set_temporal_specifications(%__MODULE__{} = domain, specs) do
    # This function should ideally be handled by AriaCore.Domain
    Logger.warning("AriaEngineCore.Domain.Core.set_temporal_specifications called. This should be handled by AriaCore.Domain.")
    domain
  end

  @doc "Retrieves the temporal specifications from the domain.\n"
  @spec get_temporal_specifications(t()) :: map()
  def get_temporal_specifications(%__MODULE__{} = _domain) do
    # This function should ideally be handled by AriaCore.Domain
    Logger.warning("AriaEngineCore.Domain.Core.get_temporal_specifications called. This should be handled by AriaCore.Domain.")
    %{}
  end
end
