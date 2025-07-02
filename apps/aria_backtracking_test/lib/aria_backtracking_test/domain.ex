# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaBacktrackingTest.Domain do
  @moduledoc """
  HTN domain for backtracking tests based on GTPyhop's backtracking_htn.py example.

  This domain provides simple flag manipulation actions and methods designed to trigger
  backtracking behavior for testing the planning system's failure recovery mechanisms.
  """

  # Actions (matching Python implementation)

  @doc """
  Sets the flag to the specified value.
  Always succeeds and returns the updated state.
  """
  @spec putv(AriaState.t(), [integer()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def putv(state, [flag_val]) when is_integer(flag_val) do
    updated_state = AriaState.RelationalState.set_fact(state, "system", "flag", flag_val)
    {:ok, updated_state}
  end

  @doc """
  Checks if the flag matches the expected value.
  Succeeds only if the current flag value equals the expected value.
  """
  @spec getv(AriaState.t(), [integer()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def getv(state, [flag_val]) when is_integer(flag_val) do
    current_flag = AriaState.RelationalState.get_fact(state, "system", "flag") || -1
    if current_flag == flag_val do
      {:ok, state}
    else
      {:error, "Flag value #{current_flag} does not match expected #{flag_val}"}
    end
  end

  # Methods for task decomposition (matching Python implementation)

  @doc """
  Deliberately broken method for 'put_it' task.
  Sets flag to 0, then tries to get 1 - this will always fail on the getv step.
  """
  @spec m_err(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def m_err(_state, _args) do
    {:ok, [{:putv, [0]}, {:getv, [1]}]}
  end

  @doc """
  Working method for 'put_it' task that sets and gets flag value 0.
  """
  @spec m0(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def m0(_state, _args) do
    {:ok, [{:putv, [0]}, {:getv, [0]}]}
  end

  @doc """
  Working method for 'put_it' task that sets and gets flag value 1.
  """
  @spec m1(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def m1(_state, _args) do
    {:ok, [{:putv, [1]}, {:getv, [1]}]}
  end

  @doc """
  Method for 'need0' task - checks that flag is 0.
  """
  @spec m_need0(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def m_need0(_state, _args) do
    {:ok, [{:getv, [0]}]}
  end

  @doc """
  Method for 'need1' task - checks that flag is 1.
  """
  @spec m_need1(AriaState.t(), [any()]) :: {:ok, [tuple()]} | {:error, atom()}
  def m_need1(_state, _args) do
    {:ok, [{:getv, [1]}]}
  end

  @doc """
  Create the backtracking test domain.
  """
  @spec create() :: AriaCore.Domain.t()
  def create(_opts \\ %{}) do
    AriaCore.Domain.new(:backtracking_test)
  end

  @doc """
  Get domain information.
  """
  @spec info() :: map()
  def info do
    %{
      name: "Backtracking Test Domain",
      description: "Simple flag-based domain for testing HTN backtracking behavior",
      actions: [:putv, :getv],
      tasks: [:put_it, :need0, :need1, :need01, :need10],
      methods: [:m_err, :m0, :m1, :m_need0, :m_need1],
      predicates: ["system"]
    }
  end
end
