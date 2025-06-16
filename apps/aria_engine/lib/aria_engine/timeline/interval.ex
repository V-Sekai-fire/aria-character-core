# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.Interval do
  @moduledoc """
  Represents a temporal interval with start and end points using DateTime with timezone information.

  Intervals are the fundamental building blocks of the Timeline system,
  representing periods of time during which events, actions, or states occur.
  
  Only DateTime structs with explicit timezone information are supported
  to ensure temporal consistency and proper timezone handling across the system.
  This enforces clarity about when events occur in global context.
  
  ## Timezone Enforcement
  
  - All temporal data uses DateTime.t() with timezone information
  - NaiveDateTime is not supported to prevent ambiguity
  - Integer timestamps are not supported to enforce explicit timezone handling
  - All time comparisons account for timezone differences automatically
  """

  alias AriaEngine.Timeline.AgentEntity

  @type id :: String.t()
  @type t :: %__MODULE__{
          id: id(),
          start_time: DateTime.t(),
          end_time: DateTime.t(),
          agent: AgentEntity.agent() | nil,
          entity: AgentEntity.entity() | nil,
          metadata: map()
        }

  defstruct id: nil,
            start_time: nil,
            end_time: nil,
            agent: nil,
            entity: nil,
            metadata: %{}

  @doc """
  Creates a new interval with DateTime values.
  
  Both start_time and end_time must be DateTime structs with timezone information.
  This ensures all temporal data has explicit timezone context.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt)
      iex> interval.start_time
      ~U[2023-01-01 00:00:00Z]

  """
  @spec new(DateTime.t(), DateTime.t()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time) do
    validate_time_ordering!(start_time, end_time)
    
    %__MODULE__{
      id: generate_id(),
      start_time: start_time,
      end_time: end_time,
      metadata: %{}
    }
  end

  @doc """
  Creates a new interval with DateTime values and options.
  
  Both start_time and end_time must be DateTime structs with timezone information.

  ## Options

  - `:agent` - The agent associated with this interval
  - `:entity` - The entity associated with this interval  
  - `:metadata` - Additional metadata for the interval

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt, metadata: %{type: :action})
      iex> interval.metadata
      %{type: :action}

  """
  @spec new(DateTime.t(), DateTime.t(), keyword()) :: t()
  def new(%DateTime{} = start_time, %DateTime{} = end_time, opts) when is_list(opts) do
    validate_time_ordering!(start_time, end_time)
    
    %__MODULE__{
      id: generate_id(),
      start_time: start_time,
      end_time: end_time,
      agent: Keyword.get(opts, :agent),
      entity: Keyword.get(opts, :entity),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Gets the duration of the interval in milliseconds.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt)
      iex> AriaEngine.Timeline.Interval.duration_ms(interval)
      330000

  """
  @spec duration_ms(t()) :: integer()
  def duration_ms(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :millisecond)
  end

  @doc """
  Gets the duration of the interval in seconds.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2023-01-01 00:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2023-01-01 00:05:30], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt)
      iex> AriaEngine.Timeline.Interval.duration_seconds(interval)
      330.0

  """
  @spec duration_seconds(t()) :: float()
  def duration_seconds(%__MODULE__{start_time: start_time, end_time: end_time}) do
    DateTime.diff(end_time, start_time, :microsecond) / 1_000_000.0
  end

  @doc """
  Checks if a DateTime point is contained within the interval.

  Only DateTime values are supported for time points to maintain timezone consistency.

  ## Examples

      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt)
      iex> check_time = DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC")
      iex> AriaEngine.Timeline.Interval.contains?(interval, check_time)
      true

  """
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_time: start_time, end_time: end_time}, %DateTime{} = time_point) do
    DateTime.compare(start_time, time_point) in [:lt, :eq] and 
    DateTime.compare(time_point, end_time) == :lt
  end

  @doc """
  Checks if the interval is associated with an agent.

  ## Examples

      iex> agent = %{type: :agent, id: "agent1", name: "Alice"}
      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt, agent: agent)
      iex> AriaEngine.Timeline.Interval.agent?(interval)
      true

  """
  @spec agent?(t()) :: boolean()
  def agent?(%__MODULE__{agent: agent}), do: not is_nil(agent)

  @doc """
  Checks if the interval is associated with an entity.

  ## Examples

      iex> entity = %{type: :entity, id: "entity1", name: "Conference Room"}
      iex> start_dt = DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
      iex> end_dt = DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC")
      iex> interval = AriaEngine.Timeline.Interval.new(start_dt, end_dt, entity: entity)
      iex> AriaEngine.Timeline.Interval.entity?(interval)
      true

  """
  @spec entity?(t()) :: boolean()
  def entity?(%__MODULE__{entity: entity}), do: not is_nil(entity)

  @doc """
  Alias for duration_ms/1 for backward compatibility.
  """
  @spec duration(t()) :: integer()
  def duration(interval), do: duration_ms(interval)

  # Private helper functions
  
  defp validate_time_ordering!(start_time, end_time) do
    case DateTime.compare(start_time, end_time) do
      :gt -> raise ArgumentError, "start_time must be before end_time"
      :eq -> raise ArgumentError, "start_time must be before end_time"
      :lt -> :ok
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
