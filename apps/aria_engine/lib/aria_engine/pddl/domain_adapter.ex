# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Pddl.DomainAdapter do
  @moduledoc """
  Adapts an AriaEngine.Pddl.Domain to conform to the AriaEngine.DomainBehaviour.
  """

  @behaviour AriaEngine.DomainBehaviour

  alias AriaEngine.Pddl.Domain, as: PddlDomain
  alias AriaEngine.Domain, as: AriaDomain
  # alias AriaEngine.State # Removed unused alias
  require Logger

  @type t :: %__MODULE__{
          pddl_domain: PddlDomain.t()
        }

  defstruct pddl_domain: nil

  def new(pddl_domain) do # Removed @impl true
    %__MODULE__{pddl_domain: pddl_domain}
  end

  def get_name(%__MODULE__{pddl_domain: %PddlDomain{name: name}}) do # Removed @impl true
    name
  end

  @impl true # This is a behaviour callback
  def actions(%__MODULE__{pddl_domain: %PddlDomain{actions: actions}}) do
    # PDDL actions are functions, not maps. This needs to be adapted.
    # For now, return a map of action_name to action_struct
    Map.new(actions, fn action_struct -> {action_struct.name, action_struct} end)
  end

  def get_action_metadata(%__MODULE__{pddl_domain: %PddlDomain{actions: actions}}, action_name) do # Removed @impl true
    # PDDL actions don't have metadata in the same way.
    # Return the action struct itself if found, or empty map.
    Map.get(Map.new(actions, fn a -> {a.name, a} end), action_name, %{})
  end

  def has_action?(%__MODULE__{pddl_domain: %PddlDomain{actions: actions}}, action_name) do # Removed @impl true
    Enum.any?(actions, fn action_struct -> action_struct.name == action_name end)
  end

  def execute_action(%__MODULE__{pddl_domain: _pddl_domain}, state, action_name, args) do # Removed @impl true
    # This would involve converting AriaEngine.State to PDDL state,
    # executing the action in PDDL, and converting back.
    # For now, this is a placeholder.
    IO.puts("PDDL DomainAdapter: execute_action called for #{action_name}(#{inspect(args)})")
    # Placeholder: always succeed for now
    {:ok, state}
  end

  @impl true # This is a behaviour callback
  def task_methods(%__MODULE__{pddl_domain: %PddlDomain{tasks: tasks}}) do
    # PDDL tasks are functions, not maps. This needs to be adapted.
    # For now, return a map of task_name to task_struct
    Map.new(tasks, fn task_struct -> {task_struct.name, task_struct} end)
  end

  def get_task_methods(%__MODULE__{}, _task_name) do # Removed @impl true
    # PDDL typically doesn't have explicit task methods like HTN.
    # This would be a placeholder or require a mapping from PDDL tasks/predicates.
    []
  end

  @impl true # This is a behaviour callback
  def unigoal_methods(%__MODULE__{pddl_domain: %PddlDomain{predicates: predicates}}) do
    # PDDL predicates are used for goals. This needs to be adapted.
    # For now, return a map of predicate_name to predicate_struct
    Map.new(predicates, fn {predicate_name, _args} -> {predicate_name, %{}} end) # Placeholder
  end

  def get_unigoal_methods(%__MODULE__{}, _goal_type) do # Removed @impl true
    # PDDL goals are usually predicates. This would involve mapping PDDL predicates to methods.
    []
  end

  @impl true # This is a behaviour callback
  def multigoal_methods(%__MODULE__{pddl_domain: %PddlDomain{methods: methods}}) do
    # PDDL methods are functions, not lists. This needs to be adapted.
    # For now, return a list of method_structs
    methods
  end

  def get_multigoal_methods(%__MODULE__{}) do # Removed @impl true
    # PDDL multigoals are conjunctions of predicates.
    []
  end

  # Placeholder for durative actions - PDDL does not have a direct equivalent in the PddlDomain struct
  @impl true # This is a behaviour callback
  def durative_actions(%__MODULE__{pddl_domain: _pddl_domain}) do
    Logger.warning("PDDL DomainAdapter: durative_actions called, but PDDL Domain does not explicitly define durative actions.", [])
    %{}
  end

  @impl true
  def get_durative_action(%__MODULE__{pddl_domain: _pddl_domain}, name) do
    Logger.warning("PDDL DomainAdapter: get_durative_action called for #{name}, but PDDL Domain does not explicitly define durative actions.", [])
    nil
  end

  # Helper to convert AriaEngine.Domain to PddlDomain (if needed for export)
  @spec to_pddl_domain(AriaEngine.Domain.Core.t()) :: PddlDomain.t()
  def to_pddl_domain(%AriaDomain.Core{} = aria_domain) do
    # This is a complex conversion that would involve mapping AriaEngine actions/methods
    # to PDDL syntax. For now, return a placeholder PddlDomain.
    %PddlDomain{
      name: aria_domain.name,
      requirements: [],
      types: [],
      predicates: [],
      functions: [],
      actions: [],
      tasks: [],
      methods: []
    }
  end
end
