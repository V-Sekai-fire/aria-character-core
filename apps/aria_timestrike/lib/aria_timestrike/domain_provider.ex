# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.Core.DomainProvider do
  @moduledoc """
  Domain provider for TimeStrike core (non-temporal) game domain functionality.
  """

  @behaviour AriaEngine.DomainProvider

  @impl true
  def domain_type, do: "timestrike_core"

  @impl true
  def create_domain do
    AriaTimestrike.Core.create_domain()
  end
end
