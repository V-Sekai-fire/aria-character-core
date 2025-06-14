# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrike.DomainProvider do
  @moduledoc """
  Domain provider for TimeStrike game domain functionality.
  """

  @behaviour AriaEngine.DomainProvider

  @impl true
  def domain_type, do: "timestrike"

  @impl true
  def create_domain do
    AriaTimestrike.create_domain()
  end
end
