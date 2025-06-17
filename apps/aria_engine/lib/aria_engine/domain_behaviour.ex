defmodule AriaEngine.DomainBehaviour do
  @moduledoc """
  Behaviour for modules that define a planning domain for AriaEngine.Plan.
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

  # Placeholder callbacks for durative versions
  @callback durative_actions(domain :: term()) :: map()
  @callback durative_task_methods(domain :: term()) :: map()
  @callback durative_unigoal_methods(domain :: term()) :: map()
  @callback durative_multigoal_methods(domain :: term()) :: list()
end
