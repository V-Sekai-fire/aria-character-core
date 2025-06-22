defmodule AriaEngine.DomainBehaviour do
  @moduledoc """
  Defines the behaviour for an AriaEngine planning domain.
  """

  @callback actions() :: [atom()]
  @callback methods() :: [atom()]
end
