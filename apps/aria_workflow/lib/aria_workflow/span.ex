defmodule AriaWorkflow.Span do
  @moduledoc """
  OpenTelemetry-inspired spans for workflow execution tracking.

  A span represents a unit of work or operation within a workflow execution.
  Spans can be nested to form traces that show the complete execution path.
  """

  defstruct [
    :span_id,
    :trace_id,
    :parent_span_id,
    :name,
    :kind,
    :start_time,
    :end_time,
    :duration_us,
    :status,
    :attributes,
    :events,
    :links,
    :resource
  ]

  @type span_id :: String.t()
  @type trace_id :: String.t()
  @type span_kind :: :internal | :server | :client | :producer | :consumer
  @type span_status :: :unset | :ok | :error
  @type attribute_value :: String.t() | integer() | float() | boolean()
  @type attributes :: %{String.t() => attribute_value()}

  @type event :: %{
    name: String.t(),
    timestamp: DateTime.t(),
    attributes: attributes()
  }

  @type link :: %{
    trace_id: trace_id(),
    span_id: span_id(),
    attributes: attributes()
  }

  @type t :: %__MODULE__{
    span_id: span_id(),
    trace_id: trace_id(),
    parent_span_id: span_id() | nil,
    name: String.t(),
    kind: span_kind(),
    start_time: DateTime.t(),
    end_time: DateTime.t() | nil,
    duration_us: integer() | nil,
    status: span_status(),
    attributes: attributes(),
    events: [event()],
    links: [link()],
    resource: map()
  }

  @doc """
  Creates a new span.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(name, opts \\ []) do
    trace_id = Keyword.get(opts, :trace_id, generate_trace_id())
    parent_span_id = Keyword.get(opts, :parent_span_id)
    kind = Keyword.get(opts, :kind, :internal)
    attributes = Keyword.get(opts, :attributes, %{})
    resource = Keyword.get(opts, :resource, %{})

    %__MODULE__{
      span_id: generate_span_id(),
      trace_id: trace_id,
      parent_span_id: parent_span_id,
      name: name,
      kind: kind,
      start_time: DateTime.utc_now(),
      end_time: nil,
      duration_us: nil,
      status: :unset,
      attributes: attributes,
      events: [],
      links: [],
      resource: resource
    }
  end

  @doc """
  Ends a span and calculates its duration.
  """
  @spec finish(t(), keyword()) :: t()
  def finish(%__MODULE__{start_time: start_time} = span, opts \\ []) do
    end_time = Keyword.get(opts, :end_time, DateTime.utc_now())
    status = Keyword.get(opts, :status, :ok)
    
    duration_us = DateTime.diff(end_time, start_time, :microsecond)

    %{span |
      end_time: end_time,
      duration_us: duration_us,
      status: status
    }
  end

  @doc """
  Adds an attribute to the span.
  """
  @spec set_attribute(t(), String.t(), attribute_value()) :: t()
  def set_attribute(%__MODULE__{attributes: attributes} = span, key, value) do
    %{span | attributes: Map.put(attributes, key, value)}
  end

  @doc """
  Adds multiple attributes to the span.
  """
  @spec set_attributes(t(), attributes()) :: t()
  def set_attributes(%__MODULE__{attributes: current_attrs} = span, new_attrs) do
    %{span | attributes: Map.merge(current_attrs, new_attrs)}
  end

  @doc """
  Adds an event to the span.
  """
  @spec add_event(t(), String.t(), attributes()) :: t()
  def add_event(%__MODULE__{events: events} = span, name, attributes \\ %{}) do
    event = %{
      name: name,
      timestamp: DateTime.utc_now(),
      attributes: attributes
    }

    %{span | events: [event | events]}
  end

  @doc """
  Records an exception in the span.
  """
  @spec record_exception(t(), Exception.t()) :: t()
  def record_exception(span, exception) do
    span
    |> set_attribute("error", true)
    |> set_attribute("exception.type", exception.__struct__ |> to_string())
    |> set_attribute("exception.message", Exception.message(exception))
    |> add_event("exception", %{
      "exception.type" => exception.__struct__ |> to_string(),
      "exception.message" => Exception.message(exception)
    })
  end

  @doc """
  Creates a child span from the current span.
  """
  @spec create_child(t(), String.t(), keyword()) :: t()
  def create_child(%__MODULE__{span_id: parent_id, trace_id: trace_id}, name, opts \\ []) do
    opts = Keyword.merge(opts, trace_id: trace_id, parent_span_id: parent_id)
    new(name, opts)
  end

  @doc """
  Converts span to a readable format for logging.
  """
  @spec to_log_format(t()) :: String.t()
  def to_log_format(%__MODULE__{} = span) do
    duration_str = case span.duration_us do
      nil -> "active"
      us when us < 1_000 -> "#{us}μs"
      us when us < 1_000_000 -> "#{Float.round(us / 1_000, 2)}ms"
      us -> "#{Float.round(us / 1_000_000, 3)}s"
    end

    "[#{span.trace_id}:#{span.span_id}] #{span.name} (#{duration_str}) - #{span.status}"
  end

  # Private functions

  defp generate_trace_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp generate_span_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
