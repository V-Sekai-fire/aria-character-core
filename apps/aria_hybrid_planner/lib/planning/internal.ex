# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Planning.Internal do
  @moduledoc "Provides internal helper functions for the Aria Engine planning modules.\n"
  alias AriaEngine.Core
  alias AriaEngine.DomainBehaviour
  alias AriaEngine.Domain.Core, as: DomainCore
  @doc "Converts an engine struct into a planner interface compatible domain.\n"
  @spec to_planner_interface(Core.t()) :: DomainBehaviour.t()
  def to_planner_interface(%Core{
        actions: actions,
        task_methods: task_methods,
        unigoal_methods: unigoal_methods,
        multigoal_methods: multigoal_methods
      }) do
    %DomainCore{
      name: "dynamic_engine_domain",
      actions: actions,
      task_methods: task_methods,
      unigoal_methods: unigoal_methods,
      multigoal_methods: multigoal_methods
    }
  end
end