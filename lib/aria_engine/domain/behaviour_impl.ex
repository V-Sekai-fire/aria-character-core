# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.BehaviourImpl do
  @moduledoc """
  Contains the implementation of `DomainBehaviour` callbacks.
  """

  @behaviour DomainBehaviour
  alias Domain.Core

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
  @spec get_durative_action(Core.t(), Core.durative_action_name()) ::
          Domain.DurativeAction.t() | nil
  def get_durative_action(%Core{durative_actions: durative_actions}, name),
    do: Map.get(durative_actions, name)
end
