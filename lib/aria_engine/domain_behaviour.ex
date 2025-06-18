# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule DomainBehaviour do
  @moduledoc """
  Behaviour for modules that define a planning domain for Plan.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  @callback actions(domain :: term()) :: map()
  @callback task_methods(domain :: term()) :: map()
  @callback unigoal_methods(domain :: term()) :: map()
  @callback multigoal_methods(domain :: term()) :: list()

  # Callbacks for durative actions
  @callback durative_actions(domain :: term()) :: map()
  @callback get_durative_action(domain :: term(), name :: atom()) :: Domain.DurativeAction.t() | nil
end
