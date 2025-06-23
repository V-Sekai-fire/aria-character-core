defmodule AriaEngine.Membrane.Format.PlanningParams do
  @moduledoc "Membrane format for converted planning parameters.\n\nThis format represents the converted planning parameters that are ready\nfor execution by the HybridCoordinator. It contains the domain, state,\ngoals, and options needed for planning execution.\n"
  defstruct [:domain, :state, :goals, :options, :request_id, :conversion_metadata]

  @type t :: %__MODULE__{
          domain: AriaEngine.Domain.Core.t() | nil,
          state: AriaEngine.State.t() | nil,
          goals: [term()],
          options: keyword(),
          request_id: String.t(),
          conversion_metadata: map()
        }
  @doc "Validates a planning params format structure.\n\n## Examples\n\n    iex> params = %AriaEngine.Membrane.Format.PlanningParams{\n    ...>   domain: nil,\n    ...>   state: nil,\n    ...>   goals: [],\n    ...>   options: [],\n    ...>   request_id: \"req_123\",\n    ...>   conversion_metadata: %{}\n    ...> }\n    iex> AriaEngine.Membrane.Format.PlanningParams.valid?(params)\n    true\n"
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = params) do
    is_list(params.goals) and is_list(params.options) and is_binary(params.request_id) and
      is_map(params.conversion_metadata)
  end

  def valid?(_) do
    false
  end

  @doc "Creates planning params from converted domain, state, and goals.\n\n## Examples\n\n    iex> metadata = %{converted_at: DateTime.utc_now()}\n    iex> params = AriaEngine.Membrane.Format.PlanningParams.create(\n    ...>   nil, nil, [], [], \"req_123\", metadata\n    ...> )\n    iex> params.request_id\n    \"req_123\"\n"
  @spec create(
          AriaEngine.Domain.Core.t() | nil,
          AriaEngine.State.t() | nil,
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

  @doc "Creates error planning params when conversion fails.\n\n## Examples\n\n    iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(\n    ...>   \"req_123\", \"Invalid input format\"\n    ...> )\n    iex> params.options[:error]\n    true\n"
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

  @doc "Checks if the planning params represents an error state.\n\n## Examples\n\n    iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(\n    ...>   \"req_123\", \"test error\"\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningParams.error?(params)\n    true\n"
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{options: options}) do
    Keyword.get(options, :error, false)
  end

  @doc "Gets the error reason from error planning params.\n\n## Examples\n\n    iex> params = AriaEngine.Membrane.Format.PlanningParams.create_error(\n    ...>   \"req_123\", \"test error\"\n    ...> )\n    iex> AriaEngine.Membrane.Format.PlanningParams.error_reason(params)\n    \"test error\"\n"
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{conversion_metadata: metadata}) do
    Map.get(metadata, :error_reason)
  end

  @doc "Converts planning params to a map for serialization.\n"
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = params) do
    %{
      "domain" =>
        if params.domain do
          inspect(params.domain)
        else
          nil
        end,
      "state" =>
        if params.state do
          inspect(params.state)
        else
          nil
        end,
      "goals" => params.goals,
      "options" => params.options,
      "request_id" => params.request_id,
      "conversion_metadata" => params.conversion_metadata
    }
  end
end