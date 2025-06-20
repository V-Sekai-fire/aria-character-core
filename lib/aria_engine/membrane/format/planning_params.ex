# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.PlanningParams do
  @moduledoc """
  Membrane format for converted planning parameters.
  
  This format represents the converted planning parameters that are ready
  for execution by the HybridCoordinator. It contains the domain, state,
  goals, and options needed for planning execution.
  """

  defstruct [
    :domain,
    :state,
    :goals,
    :options,
    :request_id,
    :conversion_metadata
  ]

  @type t :: %__MODULE__{
    domain: AriaEngine.Domain.Core.t() | nil,
    state: AriaEngine.StateV2.t() | nil,
    goals: [term()],
    options: keyword(),
    request_id: String.t(),
    conversion_metadata: map()
  }

  @doc """
  Validates a planning parameters format structure.
  
  ## Examples
  
      iex> params = %AriaEngine.Membrane.Format.PlanningParams{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.PlanningParams.valid?(params)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = params) do
    is_list(params.goals) and
    is_list(params.options) and
    is_binary(params.request_id) and
    is_map(params.conversion_metadata)
  end

  def valid?(_), do: false

  @doc """
  Creates planning parameters from converted domain, state, and goals.
  
  ## Examples
  
      iex> metadata = %{converted_at: DateTime.utc_now()}
      iex> params = AriaEngine.Membrane.Format.PlanningParams.create(
      ...>   nil, nil, [], [], "req_123", metadata
      ...> )
      iex> params.request_id
      "req_123"
  """
  @spec create(
    AriaEngine.Domain.Core.t() | nil,
    AriaEngine.StateV2.t() | nil,
    [term()],
    keyword(),
    String.t(),
    map()
  ) :: t()
  def create(domain, state, goals, options, request_id, conversion_metadata) do
    %__MODULE__{
      domain: domain,
      state: state,
      goals: goals,
      options: options,
      request_id: request_id,
      conversion_metadata: conversion_metadata
    }
  end

  @doc """
  Creates error planning parameters when conversion fails.
  
  ## Examples
  
      iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(
      ...>   "req_123", "Invalid input format"
      ...> )
      iex> params.options[:error]
      true
  """
  @spec create_error(String.t(), String.t()) :: t()
  def create_error(request_id, error_reason) do
    %__MODULE__{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true],
      request_id: request_id,
      conversion_metadata: %{
        error: true,
        error_reason: error_reason,
        converted_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Checks if the planning parameters represent an error state.
  
  ## Examples
  
      iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(
      ...>   "req_123", "test error"
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningParams.error?(params)
      true
  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{options: options}) do
    Keyword.get(options, :error, false)
  end

  @doc """
  Gets the error reason from error planning parameters.
  
  ## Examples
  
      iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(
      ...>   "req_123", "test error"
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningParams.error_reason(params)
      "test error"
  """
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{conversion_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc """
  Converts planning parameters to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = params) do
    %{
      "domain" => if(params.domain, do: inspect(params.domain), else: nil),
      "state" => if(params.state, do: inspect(params.state), else: nil),
      "goals" => params.goals,
      "options" => params.options,
      "request_id" => params.request_id,
      "conversion_metadata" => params.conversion_metadata
    }
  end
end
