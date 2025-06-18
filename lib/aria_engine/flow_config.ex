# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule FlowConfig do
  @moduledoc """
  Configuration module for determining which flow implementation to use.
  
  This allows switching between AriaFlow (production) and MockFlow (testing)
  based on application configuration or environment.
  """

  @doc """
  Get the configured flow implementation module.
  
  Returns the module that implements AriaFlow.Behaviour.
  Defaults to MockFlow for development/testing, can be configured to use AriaFlow.
  """
  def flow_impl do
    Application.get_env(:aria_engine, :flow_impl, MockFlow)
  end

  @doc """
  Use AriaFlow as the flow implementation (production mode).
  """
  def use_aria_flow do
    Application.put_env(:aria_engine, :flow_impl, AriaFlow)
  end

  @doc """
  Use MockFlow as the flow implementation (testing mode).
  """
  def use_mock_flow do
    Application.put_env(:aria_engine, :flow_impl, MockFlow)
  end
end
