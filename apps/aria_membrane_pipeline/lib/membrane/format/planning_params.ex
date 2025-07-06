# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Membrane.Format.PlanningParams do
  @moduledoc """
  Format for planning parameters in Membrane pipelines.
  """

  @type t :: %__MODULE__{
    status: :request | :error,
    params: map(),
    request_id: String.t(),
    error_reason: String.t() | nil,
    conversion_metadata: map(),
    context: map(),
    goal: any()
  }

  defstruct [
    :status,
    :params,
    :request_id,
    :error_reason,
    :conversion_metadata,
    :context,
    :goal
  ]

  @doc """
  Creates a new planning params structure.
  """
  def new(status, params, request_id, opts \\ %{}) do
    %__MODULE__{
      status: status,
      params: params,
      request_id: request_id,
      error_reason: Map.get(opts, :error_reason),
      conversion_metadata: Map.get(opts, :conversion_metadata, %{}),
      context: Map.get(opts, :context, %{}),
      goal: Map.get(opts, :goal)
    }
  end

  @doc """
  Creates a planning params request.
  """
  def request(params, request_id) do
    %__MODULE__{
      status: :request,
      params: params,
      request_id: request_id,
      error_reason: nil,
      conversion_metadata: %{},
      context: %{},
      goal: nil
    }
  end

  @doc """
  Creates an error planning params.
  """
  def error(reason, request_id) do
    %__MODULE__{
      status: :error,
      params: %{},
      request_id: request_id,
      error_reason: reason,
      conversion_metadata: %{},
      context: %{},
      goal: nil
    }
  end
end
