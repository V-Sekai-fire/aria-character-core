# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domain.BehaviourImpl do
  @moduledoc """
  Contains the implementation of `AriaEngine.DomainBehaviour` callbacks.
  """

  @behaviour AriaEngine.DomainBehaviour
  alias AriaEngine.Domain.Core

  @impl true
  @spec actions(Core.t()) :: map()
  def actions(_domain), do: %{}

  @impl true
  @spec task_methods(Core.t()) :: map()
  def task_methods(_domain), do: %{}

  @impl true
  @spec unigoal_methods(Core.t()) :: map()
  def unigoal_methods(_domain), do: %{}

  @impl true
  @spec multigoal_methods(Core.t()) :: list()
  def multigoal_methods(_domain), do: []

  @impl true
  @spec durative_actions(Core.t()) :: map()
  def durative_actions(_domain), do: %{}

  @impl true
  @spec durative_task_methods(Core.t()) :: map()
  def durative_task_methods(_domain), do: %{}

  @impl true
  @spec durative_unigoal_methods(Core.t()) :: map()
  def durative_unigoal_methods(_domain), do: %{}

  @impl true
  @spec durative_multigoal_methods(Core.t()) :: list()
  def durative_multigoal_methods(_domain), do: []
end
