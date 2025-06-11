# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainDefinition do
  @moduledoc """
  A domain definition combines domain capabilities with a todo plan and execution state.

  This unifies the concept of AriaEngine.Domain (capabilities) with workflow execution
  (plan + state). A DomainDefinition is a complete executable unit that contains:

  1. Domain Capabilities: actions, task_methods, unigoal_methods, multigoal_methods
  2. Todo Plan: specific sequence of goals, tasks, and actions to execute
  3. Execution State: current state, progress, completed/failed items
  4. Span-based Tracing: Todo execution IS tracing - each todo becomes a span

  ## Key Insight: Todo Execution = Span Tracing

  Rather than having separate span-based tracing infrastructure, this module treats
  todo execution as the trace itself:

  - **Spans** = Individual todo items being executed
  - **Span hierarchy** = Todo dependencies and nesting
  - **Span start/end times** = Todo execution lifecycle
  - **Span context** = State passing between todos
  - **Trace** = Complete execution path through todos

  This eliminates the need for redundant WorkflowExecution span tracking - the domain
  execution state IS the trace. Each todo item becomes a span with timing, status,
  and context information.

  This replaces the separate WorkflowDefinition/WorkflowExecution concepts - a workflow
  IS a domain with a plan and state, and execution tracing is just todo state tracking.
  """

  alias AriaEngine.{State, Domain}

  @type status :: :pending | :planning | :executing | :completed | :failed | :cancelled
  @type todo_item :: goal_spec() | task_spec() | action_spec()
  @type goal_spec :: {String.t(), String.t(), String.t()}
  @type task_spec :: {String.t(), list()}
  @type action_spec :: {atom(), list()}
  @type action_fn :: (State.t(), list() -> State.t() | false)
  @type task_method_fn :: (State.t(), list() -> list() | false)
  @type goal_method_fn :: (State.t(), list() -> list() | false)
  @type execution_step :: {:todo, todo_item()} | {:action, atom(), list()} | {:task, String.t(), list()} | {:goal, String.t(), String.t(), String.t()}
  @type span_context :: %{
    span_id: String.t(),
    trace_id: String.t(),
    parent_span_id: String.t() | nil,
    start_time: DateTime.t(),
    end_time: DateTime.t() | nil,
    duration_ms: non_neg_integer() | nil,
    status: :pending | :active | :completed | :failed,
    attributes: %{String.t() => term()}
  }

  @type t :: %__MODULE__{
    # Identity
    id: String.t(),
    name: String.t(),
    execution_id: reference() | nil,

    # Domain Capabilities (same as AriaEngine.Domain)
    actions: %{atom() => action_fn()},
    task_methods: %{String.t() => [task_method_fn()]},
    unigoal_methods: %{String.t() => [goal_method_fn()]},
    multigoal_methods: [goal_method_fn()],

    # Todo Plan (flexible AriaEngine planning)
    todos: [todo_item()],

    # Execution State (Todo execution IS span tracing)
    current_state: State.t(),
    initial_state: State.t(),
    status: status(),
    completed_todos: [todo_item()],
    failed_todos: [todo_item()],
    current_todo_index: non_neg_integer(),

    # Span-based Tracing (Todo execution context)
    trace_id: String.t() | nil,
    todo_spans: %{non_neg_integer() => span_context()},
    current_span: span_context() | nil,

    # Execution Progress
    plan: map() | nil,
    steps: [execution_step()],
    progress: %{
      total_steps: non_neg_integer(),
      completed_steps: non_neg_integer(),
      current_step: String.t() | nil
    },
    error: term() | nil,

    # Metadata
    documentation: %{atom() => String.t()},
    metadata: %{atom() => term()},
    created_at: DateTime.t(),
    started_at: DateTime.t() | nil,
    completed_at: DateTime.t() | nil
  }

  defstruct [
    # Identity
    :id,
    :name,
    execution_id: nil,

    # Domain Capabilities
    actions: %{},
    task_methods: %{},
    unigoal_methods: %{},
    multigoal_methods: [],

    # Todo Plan
    todos: [],

    # Execution State
    current_state: nil,
    initial_state: nil,
    status: :pending,
    completed_todos: [],
    failed_todos: [],
    current_todo_index: 0,

    # Span-based Tracing (Todo execution IS tracing)
    trace_id: nil,
    todo_spans: %{},
    current_span: nil,

    # Execution Progress
    plan: nil,
    steps: [],
    progress: %{total_steps: 0, completed_steps: 0, current_step: nil},
    error: nil,

    # Metadata
    documentation: %{},
    metadata: %{},
    created_at: nil,
    started_at: nil,
    completed_at: nil
  ]

  @doc """
  Creates a new domain definition with capabilities, plan, and initial state.
  """
  @spec new(String.t(), map()) :: t()
  def new(id, definition \\ %{}) do
    now = DateTime.utc_now()
    initial_state = Map.get(definition, :initial_state, State.new())

    %__MODULE__{
      id: id,
      name: Map.get(definition, :name, id),
      actions: Map.get(definition, :actions, %{}),
      task_methods: Map.get(definition, :task_methods, %{}),
      unigoal_methods: Map.get(definition, :unigoal_methods, %{}),
      multigoal_methods: Map.get(definition, :multigoal_methods, []),
      todos: Map.get(definition, :todos, []),
      current_state: initial_state,
      initial_state: initial_state,
      documentation: Map.get(definition, :documentation, %{}),
      metadata: Map.get(definition, :metadata, %{}),
      created_at: now
    }
  end

  @doc """
  Creates a domain definition from an existing AriaEngine.Domain.
  """
  @spec from_domain(Domain.t(), [todo_item()], State.t()) :: t()
  def from_domain(%Domain{} = domain, todos, initial_state \\ nil) do
    initial_state = initial_state || State.new()

    new(domain.name, %{
      name: domain.name,
      actions: domain.actions,
      task_methods: domain.task_methods,
      unigoal_methods: domain.unigoal_methods,
      multigoal_methods: domain.multigoal_methods,
      todos: todos,
      initial_state: initial_state
    })
  end

  @doc """
  Converts a domain definition to an AriaEngine.Domain (capabilities only).
  """
  @spec to_domain(t()) :: Domain.t()
  def to_domain(%__MODULE__{} = domain_def) do
    %Domain{
      name: domain_def.name,
      actions: domain_def.actions,
      task_methods: domain_def.task_methods,
      unigoal_methods: domain_def.unigoal_methods,
      multigoal_methods: domain_def.multigoal_methods
    }
  end

  @doc """
  Starts execution of the domain definition.
  """
  @spec start(t()) :: t()
  def start(%__MODULE__{status: :pending} = domain_def) do
    trace_id = generate_trace_id()

    started_domain = %{domain_def |
      status: :executing,
      started_at: DateTime.utc_now(),
      current_todo_index: 0,
      trace_id: trace_id,
      progress: %{domain_def.progress | total_steps: length(domain_def.todos)}
    }

    # Start span for the first todo
    if length(domain_def.todos) > 0 do
      start_todo_span(started_domain)
    else
      started_domain
    end
  end

  @doc """
  Starts a span for the current todo item.
  """
  @spec start_todo_span(t()) :: t()
  def start_todo_span(%__MODULE__{trace_id: trace_id} = domain_def) when not is_nil(trace_id) do
    current_todo = get_current_todo(domain_def)

    if current_todo do
      span = %{
        span_id: generate_span_id(),
        trace_id: trace_id,
        parent_span_id: nil,
        start_time: DateTime.utc_now(),
        end_time: nil,
        duration_ms: nil,
        status: :active,
        attributes: %{
          "todo.type" => get_todo_type(current_todo),
          "todo.index" => domain_def.current_todo_index,
          "todo.content" => inspect(current_todo)
        }
      }

      %{domain_def |
        current_span: span,
        todo_spans: Map.put(domain_def.todo_spans, domain_def.current_todo_index, span)
      }
    else
      domain_def
    end
  end

  @doc """
  Finishes the current todo span.
  """
  @spec finish_todo_span(t(), :completed | :failed, term() | nil) :: t()
  def finish_todo_span(%__MODULE__{current_span: span} = domain_def, status, error \\ nil) when not is_nil(span) do
    end_time = DateTime.utc_now()
    duration_ms = DateTime.diff(end_time, span.start_time, :millisecond)

    finished_span = %{span |
      end_time: end_time,
      duration_ms: duration_ms,
      status: status,
      attributes: if(error, do: Map.put(span.attributes, "error", inspect(error)), else: span.attributes)
    }

    %{domain_def |
      current_span: nil,
      todo_spans: Map.put(domain_def.todo_spans, domain_def.current_todo_index, finished_span)
    }
  end

  @doc """
  Advances to the next todo item and starts its span.
  """
  @spec next_todo(t()) :: t()
  def next_todo(%__MODULE__{} = domain_def) do
    next_index = domain_def.current_todo_index + 1

    updated_domain = %{domain_def | current_todo_index: next_index}

    # Start span for the next todo if it exists
    if next_index < length(domain_def.todos) do
      start_todo_span(updated_domain)
    else
      updated_domain
    end
  end

  @doc """
  Marks the current todo as completed.
  """
  @spec complete_current_todo(t()) :: t()
  def complete_current_todo(%__MODULE__{} = domain_def) do
    current_todo = get_current_todo(domain_def)

    domain_def
    |> finish_todo_span(:completed)
    |> then(fn dd ->
      %{dd |
        completed_todos: [current_todo | dd.completed_todos],
        progress: %{dd.progress | completed_steps: dd.progress.completed_steps + 1}
      }
    end)
    |> next_todo()
  end

  @doc """
  Marks the current todo as failed.
  """
  @spec fail_current_todo(t(), term()) :: t()
  def fail_current_todo(%__MODULE__{} = domain_def, reason) do
    current_todo = get_current_todo(domain_def)

    domain_def
    |> finish_todo_span(:failed, reason)
    |> then(fn dd ->
      %{dd |
        failed_todos: [current_todo | dd.failed_todos],
        status: :failed,
        completed_at: DateTime.utc_now(),
        error: reason,
        metadata: Map.put(dd.metadata, :failure_reason, reason)
      }
    end)
  end

  @doc """
  Completes the entire domain execution.
  """
  @spec complete(t()) :: t()
  def complete(%__MODULE__{} = domain_def) do
    %{domain_def |
      status: :completed,
      completed_at: DateTime.utc_now()
    }
  end

  @doc """
  Updates the current state.
  """
  @spec update_state(t(), State.t()) :: t()
  def update_state(%__MODULE__{} = domain_def, new_state) do
    %{domain_def | current_state: new_state}
  end

  @doc """
  Gets the current todo item being executed.
  """
  @spec get_current_todo(t()) :: todo_item() | nil
  def get_current_todo(%__MODULE__{todos: todos, current_todo_index: index}) do
    Enum.at(todos, index)
  end

  @doc """
  Gets the next todo item to be executed.
  """
  @spec get_next_todo(t()) :: todo_item() | nil
  def get_next_todo(%__MODULE__{todos: todos, current_todo_index: index}) do
    Enum.at(todos, index + 1)
  end

  @doc """
  Checks if all todos are completed.
  """
  @spec todos_completed?(t()) :: boolean()
  def todos_completed?(%__MODULE__{todos: todos, current_todo_index: index}) do
    index >= length(todos)
  end

  @doc """
  Gets execution progress as a percentage.
  """
  @spec progress(t()) :: float()
  def progress(%__MODULE__{todos: todos, current_todo_index: index}) do
    case length(todos) do
      0 -> 100.0
      total -> min(100.0, (index / total) * 100.0)
    end
  end

  @doc """
  Gets execution summary.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%__MODULE__{} = domain_def) do
    total_duration = case {domain_def.started_at, domain_def.completed_at} do
      {%DateTime{} = start_time, %DateTime{} = end_time} ->
        DateTime.diff(end_time, start_time, :millisecond)
      _ -> nil
    end

    completed_spans = domain_def.todo_spans
    |> Map.values()
    |> Enum.filter(&(&1.status in [:completed, :failed]))

    %{
      id: domain_def.id,
      name: domain_def.name,
      status: domain_def.status,
      progress: progress(domain_def),
      total_todos: length(domain_def.todos),
      completed_todos: length(domain_def.completed_todos),
      failed_todos: length(domain_def.failed_todos),
      current_todo_index: domain_def.current_todo_index,
      created_at: domain_def.created_at,
      started_at: domain_def.started_at,
      completed_at: domain_def.completed_at,
      duration_ms: total_duration,
      # Span-based tracing summary
      trace_id: domain_def.trace_id,
      total_spans: map_size(domain_def.todo_spans),
      completed_spans: length(completed_spans),
      average_span_duration: calculate_average_span_duration(completed_spans)
    }
  end

  @doc """
  Gets execution trace as formatted string.
  """
  @spec get_trace_log(t()) :: String.t()
  def get_trace_log(%__MODULE__{} = domain_def) do
    domain_def.todo_spans
    |> Enum.sort_by(fn {index, _span} -> index end)
    |> Enum.map(fn {index, span} ->
      format_span_log(index, span)
    end)
    |> Enum.join("\n")
  end

  @doc """
  Gets all completed spans.
  """
  @spec get_completed_spans(t()) :: [span_context()]
  def get_completed_spans(%__MODULE__{} = domain_def) do
    domain_def.todo_spans
    |> Map.values()
    |> Enum.filter(&(&1.status in [:completed, :failed]))
  end

  @doc """
  Validates the domain definition.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(%__MODULE__{} = domain_def) do
    errors = []

    errors = if String.trim(domain_def.id) == "", do: ["Domain ID cannot be empty" | errors], else: errors
    errors = if Enum.empty?(domain_def.todos), do: ["Domain must have at least one todo item" | errors], else: errors
    errors = validate_todos(domain_def.todos, errors)
    errors = validate_actions(domain_def.actions, errors)
    errors = validate_task_methods(domain_def.task_methods, errors)
    errors = validate_unigoal_methods(domain_def.unigoal_methods, errors)

    case errors do
      [] -> :ok
      _ -> {:error, Enum.reverse(errors)}
    end
  end

  # Private helpers

  defp validate_todos(todos, errors) do
    Enum.reduce(todos, errors, fn todo, acc ->
      case todo do
        {pred, subj, obj} when is_binary(pred) and is_binary(subj) and is_binary(obj) ->
          acc  # Valid goal
        {task_name, args} when is_binary(task_name) and is_list(args) ->
          acc  # Valid task
        {action_name, args} when is_atom(action_name) and is_list(args) ->
          acc  # Valid action
        _ ->
          ["Invalid todo format: #{inspect(todo)}" | acc]
      end
    end)
  end

  defp validate_actions(actions, errors) do
    Enum.reduce(actions, errors, fn {name, action_fn}, acc ->
      cond do
        not is_atom(name) -> ["Action name must be atom: #{inspect(name)}" | acc]
        not is_function(action_fn, 2) -> ["Action must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_task_methods(task_methods, errors) do
    Enum.reduce(task_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) -> ["Task method name must be string: #{inspect(name)}" | acc]
        not is_list(method_fns) -> ["Task methods must be list: #{name}" | acc]
        not Enum.all?(method_fns, &is_function(&1, 2)) -> ["All task methods must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  defp validate_unigoal_methods(unigoal_methods, errors) do
    Enum.reduce(unigoal_methods, errors, fn {name, method_fns}, acc ->
      cond do
        not is_binary(name) -> ["Unigoal method name must be string: #{inspect(name)}" | acc]
        not is_list(method_fns) -> ["Unigoal methods must be list: #{name}" | acc]
        not Enum.all?(method_fns, &is_function(&1, 2)) -> ["All unigoal methods must be function/2: #{name}" | acc]
        true -> acc
      end
    end)
  end

  # Span tracing helpers

  defp generate_trace_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp generate_span_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp get_todo_type({pred, subj, obj}) when is_binary(pred) and is_binary(subj) and is_binary(obj), do: "goal"
  defp get_todo_type({task_name, _args}) when is_binary(task_name), do: "task"
  defp get_todo_type({action_name, _args}) when is_atom(action_name), do: "action"
  defp get_todo_type(_), do: "unknown"

  defp calculate_average_span_duration([]), do: 0.0
  defp calculate_average_span_duration(spans) do
    durations = spans
    |> Enum.map(&(&1.duration_ms))
    |> Enum.filter(&is_integer/1)

    case durations do
      [] -> 0.0
      _ -> Enum.sum(durations) / length(durations)
    end
  end

  defp format_span_log(index, span) do
    duration_str = case span.duration_ms do
      nil -> "active"
      ms when ms < 1000 -> "#{ms}ms"
      ms -> "#{Float.round(ms / 1000, 3)}s"
    end

    todo_type = Map.get(span.attributes, "todo.type", "unknown")
    status_str = case span.status do
      :completed -> "✓"
      :failed -> "✗"
      :active -> "⧗"
      _ -> "?"
    end

    "[#{span.trace_id}:#{span.span_id}] Todo #{index} (#{todo_type}) #{status_str} (#{duration_str})"
  end
end
