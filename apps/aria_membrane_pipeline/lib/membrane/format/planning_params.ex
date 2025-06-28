# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Membrane.Format.PlanningParams do
  @moduledoc """
  Format definition for planning parameters flowing through the pipeline.

  This format represents the transformed MCP request data that is ready
  for processing by the hybrid planner.
  """

  @type t :: %__MODULE__{
          goal: String.t(),
          context: map(),
          constraints: list(),
          request_id: String.t(),
          timestamp: DateTime.t()
        }

  defstruct [
    :goal,
    :context,
    :constraints,
    :request_id,
    :timestamp
  ]

  @doc """
  Creates a new PlanningParams format struct.
  """
  @spec new(String.t(), map(), list(), String.t()) :: t()
  def new(goal, context, constraints, request_id) do
    %__MODULE__{
      goal: goal,
      context: context,
      constraints: constraints,
      request_id: request_id,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Validates that the PlanningParams has all required fields.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = params) do
    not is_nil(params.goal) and
      not is_nil(params.context) and
      not is_nil(params.constraints) and
      not is_nil(params.request_id) and
      not is_nil(params.timestamp)
  end
end
