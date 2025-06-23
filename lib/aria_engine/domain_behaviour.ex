# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainBehaviour do
  @moduledoc """
  Defines the behaviour for an AriaEngine planning domain.
  """

  @callback actions() :: [atom()]
  @callback methods() :: [atom()]
end
