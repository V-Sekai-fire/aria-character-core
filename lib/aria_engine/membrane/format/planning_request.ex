# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Format.PlanningRequest do
  @moduledoc "Membrane format for converted planning requests.\n\nThis format represents the converted planning parameters that are ready\nfor execution by the HybridCoordinator. It contains the domain, state,\ngoals, and options needed for planning execution.\n"
  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W018RQST"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  defstruct [:domain, :state, :goals, :options, :request_id, :conversion_metadata]

  @type t :: %__MODULE__{
          domain: AriaEngine.Domain.Core.t() | nil,
          state: State.t() | nil,
          goals: [term()],
          options: keyword(),
          request_id: String.t(),
          conversion_metadata: map()
        }
  @doc "Validates a planning request format structure.\n\n## Examples\n\n    iex> request = %AriaEngine.Membrane.Format.PlanningRequest{\n    ...>   domain: nil,\n    ...>   state: nil,\n    ...>   goals: [],\n    ...>   options: [],\n    ...>   request_id: \"req_123\",\n    ...>   conversion_metadata: %{}\n    ...> }\n    iex> AriaEngine.Membrane.Format.PlanningRequest.valid?(request)\n    true\n"
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    is_list(request.goals) and is_list(request.options) and is_binary(request.request_id) and
      is_map(request.conversion_metadata)
  end

  def valid?(_) do
    false
  end

  @doc "Creates planning request from converted domain, state, and goals.\n\n## Examples\n\n    iex> metadata = %{converted_at: DateTime.utc_now()}\n    iex> request = AriaEngine.Membrane.Format.PlanningRequest.create(\n    ...>   nil, nil, [], [], \"req_123\", metadata\n    ...> )\n    iex> request.request_id\n    \"req_123\"\n"
  @spec create(
          AriaEngine.Domain.Core.t() | nil,
          State.t() | nil,
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

  @doc "Creates error planning request when conversion fails.\n\n## Examples\n\n    iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(\n    ...>   \"req_123\", \"Invalid input format\"\n    ...> )\n    iex> request.options[:error]\n    true\n"
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

  @doc "Checks if the planning request represents an error state.\n\n## Examples\n\n    iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(\n    ...>   \"req_123\", \"test error\"\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningRequest.error?(request)\n    true\n"
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{options: options}) do
    Keyword.get(options, :error, false)
  end

  @doc "Gets the error reason from error planning request.\n\n## Examples\n\n    iex> request = AriaEngine.Membrane.Format.PlanningRequest.create_error(\n    ...>   \"req_123\", \"test error\"\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningRequest.error_reason(request)\n    \"test error\"\n"
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{conversion_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc "Converts planning request to a map for serialization.\n"
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = request) do
    %{
      "domain" =>
        if request.domain do
          inspect(request.domain)
        else
          nil
        end,
      "state" =>
        if request.state do
          inspect(request.state)
        else
          nil
        end,
      "goals" => request.goals,
      "options" => request.options,
      "request_id" => request.request_id,
      "conversion_metadata" => request.conversion_metadata
    }
  end
end
