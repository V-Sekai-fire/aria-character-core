# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Domain.DurativeAction do
  @moduledoc """
  Represents a durative action in the Aria Engine planning domain.
  """

  alias StateV2

  @type durative_action_name :: atom()

  @type durative_action_conditions :: %{
    at_start: list(),
    over_all: list(),
    at_end: list()
  }

  @type durative_action_effects :: %{
    at_start: list(),
    at_end: list(),
    over_time: list()
  }

  @type durative_action_duration :: {:fixed, number()} | {:range, number(), number()}

  @type t :: %__MODULE__{
    name: durative_action_name(),
    duration: durative_action_duration(),
    conditions: durative_action_conditions(),
    effects: durative_action_effects(),
    action_fn: (StateV2.t(), list() -> StateV2.t() | false) # The actual function that performs the action
  }

  defstruct name: nil,
            duration: {:fixed, 0},
            conditions: %{at_start: [], over_all: [], at_end: []},
            effects: %{at_start: [], at_end: [], over_time: []},
            action_fn: nil

  @doc """
  Creates a new durative action.
  """
  @spec new(durative_action_name(), durative_action_duration(), durative_action_conditions(), durative_action_effects(), (StateV2.t(), list() -> StateV2.t() | false)) :: t()
  def new(name, duration, conditions, effects, action_fn) do
    %__MODULE__{
      name: name,
      duration: duration,
      conditions: conditions,
      effects: effects,
      action_fn: action_fn
    }
  end
end
