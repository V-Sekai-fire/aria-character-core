defmodule AriaEngine.Domain do
  @moduledoc """
  Mock implementation of AriaEngine.Domain for compilation.

  This module provides the domain management API as specified in ADR R25W1398085.
  Currently mocked with basic functionality to enable compilation.
  """

  @type t :: map()

  @doc """
  Create a new domain with the given name.
  """
  @spec new(String.t()) :: t()
  def new(name) do
    %{
      name: name,
      actions: %{},
      task_methods: %{},
      unigoal_methods: %{},
      multigoal_methods: %{},
      multitodo_methods: %{}
    }
  end
end
