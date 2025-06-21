# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.PlanningRequest do
  @moduledoc """
  Membrane format for converted planning requests.

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
  Validates a planning request format structure.

  ## Examples

      iex> request = %AriaEngine.Membrane.Format.PlanningRequest{
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [],
      ...>   options: [],
      ...>   request_id: "req_123",
      ...>   conversion_metadata: %{}
      ...> }
      iex> AriaEngine.Membrane.Format.PlanningRequest.valid?(request)
      true
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    is_list(request.goals) and
      is_list(request.options) and
      is_binary(request.request_id) and
      is_map(request.conversion_metadata)
  end

  def valid?(_), do: false

  @doc """
  Creates planning request from converted domain, state, and goals.

  ## Examples

      iex> metadata = %{converted_at: DateTime.utc_now()}
      iex> request = AriaEngine.Membrane.Format.PlanningRequest.create(
      ...>   nil, nil, [], [], "req_123", metadata
      ...> )
      iex> request.request_id
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
  Creates error planning request when conversion fails.

  ## Examples

      iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(
      ...>   "req_123", "Invalid input format"
      ...> )
      iex> request.options[:error]
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
  Checks if the planning request represents an error state.

  ## Examples

      iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(
      ...>   "req_123", "test error"
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningRequest.error?(request)
      true
  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{options: options}) do
    Keyword.get(options, :error, false)
  end

  @doc """
  Gets the error reason from error planning request.

  ## Examples

      iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(
      ...>   "req_123", "test error"
      ...> )
      iex> AriaEngine.Membrane.Format.PlanningRequest.error_reason(request)
      "test error"
  """
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{conversion_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc """
  Converts planning request to a map for serialization.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    %{
      "domain" => if(request.domain, do: inspect(request.domain), else: nil),
      "state" => if(request.state, do: inspect(request.state), else: nil),
      "goals" => request.goals,
      "options" => request.options,
      "request_id" => request.request_id,
      "conversion_metadata" => request.conversion_metadata
    }
  end
end
