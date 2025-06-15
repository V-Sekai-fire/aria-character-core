# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BasicActionsDomainProvider do
  @moduledoc """
  Built-in domain provider for basic actions in AriaEngine.
  """

  @behaviour AriaEngine.DomainProvider

  alias AriaEngine.{Domain, Actions}

  @impl true
  def domain_type, do: "basic_actions"

  @impl true
  def create_domain do
    Domain.new("basic_actions")
    |> Domain.add_actions(%{
      execute_command: &Actions.execute_command/2,
      echo: &Actions.echo/2,
      wait: &Actions.wait/2,
      set_env_var: &Actions.set_env_var/2
    })
  end
end
