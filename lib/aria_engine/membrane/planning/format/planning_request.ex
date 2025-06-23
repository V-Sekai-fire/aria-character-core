# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.Format.PlanningRequest do
  @moduledoc """
  Membrane format for planning requests in the unified planning system.

  This format represents the input to the planning bin, containing all
  necessary information for asynchronous planning execution with strategy
  selection and fallback handling.

  Follows the unified action specification from ADR-134 with standardized
  goal format (subject, predicate, value) and entity+capability model.
  """

  @compile {:no_warn_unused, [:serial_number]}
  @serial_number "R25W025PREQ"

  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  defstruct [
    :domain,
    :state,
    :goals,
    :options,
    :strategy_preferences,
    :timeout_ms,
    :callback_pid,
    :request_id,
    :priority,
    :metadata
  ]

  @type strategy_preference :: :hybrid_coordinator | :minizinc | :lazy_execution | :mock | :default

  @type unified_goal :: {String.t(), String.t(), term()}  # {subject, predicate, value}

  @type entity_requirement :: %{
    type: String.t(),
    capabilities: [atom()],
    optional?: boolean()
  }

  @type t :: %__MODULE__{
          domain: AriaEngine.Domain.Core.t() | nil,
          state: State.t() | nil,
          goals: [unified_goal()],
          options: keyword(),
          strategy_preferences: [strategy_preference()],
          timeout_ms: pos_integer(),
          callback_pid: pid() | nil,
          request_id: String.t(),
          priority: :low | :normal | :high | :critical,
          metadata: map()
        }

  @doc """
  Creates a new planning request with default values.

  Goals should follow the unified format: {subject, predicate, value}

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.Format.PlanningRequest.new(
      ...>   domain: nil,
      ...>   state: nil,
      ...>   goals: [{"player", "location", "room1"}, {"chef", "task", "cooking"}]
      ...> )
      iex> request.strategy_preferences
      [:hybrid_coordinator, :minizinc]

  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      domain: Keyword.get(opts, :domain),
      state: Keyword.get(opts, :state),
      goals: Keyword.get(opts, :goals, []),
      options: Keyword.get(opts, :options, []),
      strategy_preferences: Keyword.get(opts, :strategy_preferences, [:hybrid_coordinator, :minizinc]),
      timeout_ms: Keyword.get(opts, :timeout_ms, 30_000),
      callback_pid: Keyword.get(opts, :callback_pid),
      request_id: Keyword.get(opts, :request_id, generate_request_id()),
      priority: Keyword.get(opts, :priority, :normal),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Validates a planning request structure.

  Ensures goals follow unified format and all required fields are present.

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.Format.PlanningRequest.new(
      ...>   goals: [{"player", "location", "room1"}]
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningRequest.valid?(request)
      true

  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = request) do
    is_list(request.goals) and
      is_list(request.strategy_preferences) and
      is_list(request.options) and
      is_binary(request.request_id) and
      is_integer(request.timeout_ms) and
      request.timeout_ms > 0 and
      is_map(request.metadata) and
      request.priority in [:low, :normal, :high, :critical] and
      valid_strategies?(request.strategy_preferences) and
      valid_unified_goals?(request.goals)
  end

  def valid?(_), do: false

  @doc """
  Creates an error planning request for invalid inputs.

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.Format.PlanningRequest.create_error(
      ...>   "Invalid domain format"
      ...> )
      iex> request.metadata.error
      true

  """
  @spec create_error(String.t(), keyword()) :: t()
  def create_error(error_reason, opts \\ []) do
    %__MODULE__{
      domain: nil,
      state: nil,
      goals: [],
      options: [error: true],
      strategy_preferences: [],
      timeout_ms: 1000,
      callback_pid: nil,
      request_id: Keyword.get(opts, :request_id, generate_request_id()),
      priority: :low,
      metadata: %{
        error: true,
        error_reason: error_reason,
        created_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Checks if the planning request represents an error state.

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.Format.PlanningRequest.create_error("test")
      iex> AriaEngine.Membrane.Planning.Format.PlanningRequest.error?(request)
      true

  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{options: options, metadata: metadata}) do
    Keyword.get(options, :error, false) or Map.get(metadata, :error, false)
  end

  @doc """
  Gets the error reason from an error planning request.

  ## Examples

      iex> request = AriaEngine.Membrane.Planning.Format.PlanningRequest.create_error(
      ...>   "Invalid input"
      ...> )
      iex> AriaEngine.Membrane.Planning.Format.PlanningRequest.error_reason(request)
      "Invalid input"

  """
  @spec error_reason(t()) :: String.t() | nil
  def error_reason(%__MODULE__{metadata: metadata}) do
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
      "strategy_preferences" => request.strategy_preferences,
      "timeout_ms" => request.timeout_ms,
      "callback_pid" => if(request.callback_pid, do: inspect(request.callback_pid), else: nil),
      "request_id" => request.request_id,
      "priority" => request.priority,
      "metadata" => request.metadata
    }
  end

  # Private functions

  defp generate_request_id do
    "req_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp valid_strategies?(strategies) do
    valid_strategy_atoms = [:hybrid_coordinator, :minizinc, :lazy_execution, :mock, :default]
    Enum.all?(strategies, &(&1 in valid_strategy_atoms))
  end

  defp valid_unified_goals?(goals) do
    Enum.all?(goals, &valid_unified_goal?/1)
  end

  defp valid_unified_goal?({subject, predicate, _value})
       when is_binary(subject) and is_binary(predicate) do
    true
  end

  defp valid_unified_goal?(_), do: false
end
