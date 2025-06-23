defmodule Domain.DurativeAction do
  @moduledoc "Represents a durative action in the Aria Engine planning domain.\n"
  @type durative_action_name :: atom()
  @type durative_action_conditions :: %{at_start: list(), over_all: list(), at_end: list()}
  @type durative_action_effects :: %{at_start: list(), at_end: list(), over_time: list()}
  @type durative_action_duration ::
          {:fixed, number()} | {:range, number(), number()} | {:open_ended, map()}
  @type t :: %__MODULE__{
          name: durative_action_name(),
          duration: durative_action_duration(),
          conditions: durative_action_conditions(),
          effects: durative_action_effects(),
          action_fn: (AriaEngine.State.t(), list() -> AriaEngine.State.t() | false)
        }
  defstruct name: nil,
            duration: {:fixed, 0},
            conditions: %{at_start: [], over_all: [], at_end: []},
            effects: %{at_start: [], at_end: [], over_time: []},
            action_fn: nil

  @doc "Creates a new durative action.\n"
  @spec new(
          durative_action_name(),
          durative_action_duration(),
          durative_action_conditions(),
          durative_action_effects(),
          (AriaEngine.State.t(), list() -> AriaEngine.State.t() | false)
        ) :: t()
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