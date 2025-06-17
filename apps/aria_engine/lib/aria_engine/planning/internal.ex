defmodule AriaEngine.Planning.Internal do
  @moduledoc """
  Provides internal helper functions for the Aria Engine planning modules.
  """

  alias AriaEngine.Core
  alias AriaEngine.DomainBehaviour
  alias AriaEngine.Domain.Core, as: DomainCore

  @doc """
  Converts an engine struct into a planner interface compatible domain.
  """
  @spec to_planner_interface(Core.t()) :: DomainBehaviour.t()
  def to_planner_interface(%Core{actions: actions, task_methods: task_methods, unigoal_methods: unigoal_methods, multigoal_methods: multigoal_methods}) do
    # Construct a domain interface from the engine's capabilities
    %DomainCore{
      name: "dynamic_engine_domain", # A default name for the dynamically created domain
      actions: actions,
      task_methods: task_methods,
      unigoal_methods: unigoal_methods,
      multigoal_methods: multigoal_methods
    }
  end
end
